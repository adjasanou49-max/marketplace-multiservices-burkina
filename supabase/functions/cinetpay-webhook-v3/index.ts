import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json" },
});

async function hmacHex(message: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const buf = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(message),
  );
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function secretKey(): string {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (parsed.default) return parsed.default;
    } catch (_) {}
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

Deno.serve(async (req: Request) => {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const adminKey = secretKey();
  const apiKey = Deno.env.get("CINETPAY_API_KEY") ?? "";
  const siteId = Deno.env.get("CINETPAY_SITE_ID") ?? "";
  const secret = Deno.env.get("CINETPAY_SECRET_KEY") ?? "";
  if (!url || !adminKey || !apiKey || !siteId || !secret) {
    return json({ error: "cinetpay_not_configured" }, 503);
  }

  if (req.method === "GET") return new Response("ok", { status: 200 });
  if (req.method === "GET") return new Response("ok", { status: 200 });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const raw = await req.text();
  const form = new URLSearchParams(raw);
  const site = form.get("cpm_site_id") ?? "";
  const transactionId = form.get("cpm_trans_id") ?? "";
  if (!site || !transactionId || site !== siteId) {
    return json({ error: "invalid_notification" }, 400);
  }

  const received = req.headers.get("x-token") ?? "";
  const ordered = [
    "cpm_site_id",
    "cpm_trans_id",
    "cpm_trans_date",
    "cpm_amount",
    "cpm_currency",
    "signature",
    "payment_method",
    "cel_phone_num",
    "cpm_phone_prefixe",
    "cpm_language",
    "cpm_version",
    "cpm_payment_config",
    "cpm_page_action",
    "cpm_custom",
    "cpm_designation",
    "cpm_error_message",
  ].map((name) => form.get(name) ?? "").join("");
  const expected = await hmacHex(ordered, secret);
  if (!received || !constantTimeEqual(expected, received)) {
    return json({ error: "invalid_signature" }, 401);
  }

  const supabase = createClient(url, adminKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const lookup = await supabase
    .from("payments")
    .select("id,amount,currency,provider,status")
    .eq("provider_reference", transactionId)
    .limit(1)
    .maybeSingle();

  if (lookup.error || !lookup.data) return json({ error: "payment_not_found" }, 404);
  const payment = lookup.data as Record<string, unknown>;
  if (String(payment.provider) !== "CINETPAY") {
    return json({ error: "provider_invalid" }, 409);
  }

  const verify = await fetch("https://api-checkout.cinetpay.com/v2/payment/check", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "User-Agent": "Marketplace-Multiservices-Burkina/1.0",
    },
    body: JSON.stringify({
      apikey: apiKey,
      site_id: siteId,
      transaction_id: transactionId,
    }),
  });
  const checked = await verify.json().catch(() => null);
  if (!verify.ok || !checked) return json({ error: "cinetpay_verification_failed" }, 502);

  const data = (checked.data ?? {}) as Record<string, unknown>;
  const providerAmount = Number(data.amount);
  const providerCurrency = String(data.currency ?? "");
  if (
    !Number.isFinite(providerAmount) ||
    providerAmount !== Number(payment.amount) ||
    providerCurrency !== "XOF"
  ) {
    return json({ error: "payment_amount_mismatch" }, 409);
  }

  const providerStatus = String(data.status ?? "").toUpperCase();
  let internalStatus: "SUCCEEDED" | "FAILED" | "PROCESSING";
  let eventType: string;
  if (String(checked.code ?? "") === "00" && providerStatus === "ACCEPTED") {
    internalStatus = "SUCCEEDED";
    eventType = "cinetpay.accepted";
  } else if (providerStatus === "WAITING_FOR_CUSTOMER") {
    internalStatus = "PROCESSING";
    eventType = "cinetpay.waiting_for_customer";
  } else if (providerStatus === "REFUSED") {
    internalStatus = "FAILED";
    eventType = "cinetpay.refused";
  } else {
    internalStatus = "PROCESSING";
    eventType = "cinetpay." + (providerStatus || "pending").toLowerCase();
  }

  const providerReference = transactionId;
  const { error } = await supabase.rpc("process_payment_event", {
    p_payment_id: payment.id,
    p_event_type: eventType,
    p_status: internalStatus,
    p_provider_reference: providerReference,
    p_amount: providerAmount,
    p_payload: data,
  });
  if (error) return json({ error: error.message }, 409);

  return json({ ok: true, status: internalStatus }, 200);
});
