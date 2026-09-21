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
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const webhookSecret = Deno.env.get("WAVE_WEBHOOK_SECRET") ?? "";
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const adminKey = secretKey();
  if (!webhookSecret || !url || !adminKey) {
    return json({ error: "webhook_not_configured" }, 503);
  }

  const rawBody = await req.text();
  const signatureHeader = req.headers.get("Wave-Signature") ?? "";
  const parts: Record<string, string> = {};
  for (const part of signatureHeader.split(",")) {
    const index = part.indexOf("=");
    if (index > 0) parts[part.slice(0, index)] = part.slice(index + 1);
  }

  const timestamp = Number(parts.t);
  const received = parts.v1 ?? "";
  const now = Math.floor(Date.now() / 1000);
  if (!Number.isInteger(timestamp) || Math.abs(now - timestamp) > 300 || !received) {
    return json({ error: "invalid_signature_timestamp" }, 401);
  }

  const expected = await hmacHex(String(timestamp) + rawBody, webhookSecret);
  if (!constantTimeEqual(expected, received)) {
    return json({ error: "invalid_signature" }, 401);
  }

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(rawBody);
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  const eventType = String(event.type ?? "").trim();
  const data = (event.data ?? {}) as Record<string, unknown>;
  if (!eventType) return json({ error: "invalid_event" }, 400);

  let status: "SUCCEEDED" | "FAILED" | null = null;
  if (eventType === "checkout.session.completed") status = "SUCCEEDED";
  if (eventType === "checkout.session.payment_failed") status = "PROCESSING";
  if (!status) return json({ ok: true, ignored: true, event_type: eventType });

  const supabase = createClient(url, adminKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const clientReference = String(data.client_reference ?? "").trim();
  const sessionId = String(data.id ?? "").trim();
  const transactionId = String(data.transaction_id ?? "").trim();

  let paymentId = clientReference;
  if (!paymentId && sessionId) {
    const { data: rows } = await supabase
      .from("payments")
      .select("id")
      .eq("provider", "WAVE")
      .eq("provider_reference", sessionId)
      .limit(1);
    paymentId = rows?.[0]?.id ? String(rows[0].id) : "";
  }

  if (!paymentId && transactionId) {
    const { data: rows } = await supabase
      .from("payments")
      .select("id")
      .eq("provider", "WAVE")
      .eq("provider_reference", transactionId)
      .limit(1);
    paymentId = rows?.[0]?.id ? String(rows[0].id) : "";
  }

  if (!paymentId) return json({ error: "payment_not_resolved" }, 404);

  let amount = Number(data.amount);
  if (!Number.isFinite(amount) || amount <= 0) {
    const { data: payment } = await supabase
      .from("payments")
      .select("amount")
      .eq("id", paymentId)
      .maybeSingle();
    amount = Number(payment?.amount);
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    return json({ error: "payment_amount_invalid" }, 422);
  }

  const providerReference = sessionId || transactionId || clientReference || null;
  const { data: result, error } = await supabase.rpc("process_payment_event", {
    p_payment_id: paymentId,
    p_event_type: eventType,
    p_status: status,
    p_provider_reference: providerReference,
    p_amount: amount,
    p_payload: data,
  });
  if (error) return json({ error: error.message }, 409);

  return json({ ok: true, result });
});
