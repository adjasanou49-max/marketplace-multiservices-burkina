// deno-lint-ignore no-import-prefix no-unversioned-import
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

function publishableKey(): string {
  const raw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (parsed.default) return parsed.default;
    } catch (_) {
      // Ignore malformed optional configuration and use the fallback environment variable.
    }
  }
  return Deno.env.get("SUPABASE_ANON_KEY") ?? "";
}

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

async function waveRequest(
  path: string,
  body: string,
  apiKey: string,
  signingSecret: string,
) {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${apiKey}`,
    "Content-Type": "application/json",
  };
  if (signingSecret) {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signature = await hmacHex(timestamp + body, signingSecret);
    headers["Wave-Signature"] = `t=${timestamp},v1=${signature}`;
  }
  return fetch(`https://api.wave.com${path}`, {
    method: "POST",
    headers,
    body,
  });
}

async function waveGet(
  path: string,
  apiKey: string,
  signingSecret: string,
) {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${apiKey}`,
  };
  if (signingSecret) {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signature = await hmacHex(timestamp, signingSecret);
    headers["Wave-Signature"] = `t=${timestamp},v1=${signature}`;
  }
  return fetch(`https://api.wave.com${path}`, {
    method: "GET",
    headers,
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const auth = req.headers.get("Authorization");
  const url = Deno.env.get("SUPABASE_URL");
  const key = publishableKey();
  if (!auth || !url || !key) {
    return json({ error: "supabase_not_configured" }, 503);
  }

  const apiKey = Deno.env.get("WAVE_API_KEY");
  const signingSecret = Deno.env.get("WAVE_SIGNING_SECRET") ?? "";
  if (!apiKey) {
    return json({ error: "wave_not_configured" }, 503);
  }

  let body: { order_id?: string; payment_id?: string };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  const orderId = body.order_id?.trim();
  let paymentId = body.payment_id?.trim();
  if (!orderId) return json({ error: "order_required" }, 400);

  const defaultReturn = url + "/functions/v1/payment-return";
  const successUrl = Deno.env.get("WAVE_SUCCESS_URL") ||
    defaultReturn + "?status=success&order_id=" + encodeURIComponent(orderId);
  const errorUrl = Deno.env.get("WAVE_ERROR_URL") ||
    defaultReturn + "?status=error&order_id=" + encodeURIComponent(orderId);

  const supabase = createClient(url, key, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (!paymentId) {
    const { data, error } = await supabase.rpc("create_payment_intent", {
      p_order_id: orderId,
      p_provider: "WAVE",
    });
    if (error) return json({ error: "payment_operation_failed" }, 409);
    paymentId = String(data);
  }

  const { data: paymentRows, error: paymentError } = await supabase.rpc(
    "get_customer_payment_status",
    { p_order_id: orderId },
  );
  if (
    paymentError ||
    !Array.isArray(paymentRows) ||
    paymentRows.length === 0
  ) {
    return json(
      { error: "payment_not_found" },
      404,
    );
  }

  const payment = paymentRows[0] as Record<string, unknown>;
  if (String(payment.payment_id) !== paymentId) {
    return json({ error: "payment_not_owned" }, 403);
  }
  if (payment.provider !== "WAVE") {
    return json({ error: "provider_invalid" }, 409);
  }

  const amount = Number(payment.amount);
  if (!Number.isInteger(amount) || amount <= 0) {
    return json({ error: "payment_amount_invalid" }, 409);
  }

  if (payment.status === "PROCESSING" && payment.provider_reference) {
    const existing = await waveGet(
      `/v1/checkout/sessions/${payment.provider_reference}`,
      apiKey,
      signingSecret,
    );
    const existingJson = await existing.json().catch(() => null);
    if (existing.ok && existingJson?.wave_launch_url) {
      return json({
        payment_id: paymentId,
        provider: "WAVE",
        checkout_url: existingJson.wave_launch_url,
        provider_reference: existingJson.id ?? payment.provider_reference,
        checkout_status: existingJson.checkout_status ?? null,
        payment_status: existingJson.payment_status ?? null,
        expires_at: existingJson.when_expires ?? null,
        reused: true,
      });
    }
  }

  const requestBody = JSON.stringify({
    amount: String(amount),
    currency: "XOF",
    client_reference: paymentId,
    success_url: successUrl,
    error_url: errorUrl,
  });

  const response = await waveRequest(
    "/v1/checkout/sessions",
    requestBody,
    apiKey,
    signingSecret,
  );
  const wave = await response.json().catch(() => null);
  if (!response.ok) {
    return json({
      error: "wave_api_error",
      provider_status: response.status,
      message: "Wave rejected the checkout session",
    }, 502);
  }

  const providerReference = String(wave?.id ?? "").trim();
  const launchUrl = String(wave?.wave_launch_url ?? "").trim();
  if (!providerReference || !launchUrl) {
    return json({ error: "wave_response_invalid" }, 502);
  }

  const { error: prepareError } = await supabase.rpc(
    "prepare_payment_processing",
    {
      p_payment_id: paymentId,
      p_provider_reference: providerReference,
      p_metadata: {
        gateway: "WAVE",
        checkout_status: wave?.checkout_status ?? null,
        payment_status: wave?.payment_status ?? null,
        wave_launch_url: launchUrl,
        when_created: wave?.when_created ?? null,
        when_expires: wave?.when_expires ?? null,
        client_reference: paymentId,
      },
    },
  );
  if (prepareError) return json({ error: "payment_processing_failed" }, 409);

  return json({
    payment_id: paymentId,
    provider: "WAVE",
    gateway: "WAVE",
    checkout_url: launchUrl,
    provider_reference: providerReference,
    checkout_status: wave?.checkout_status ?? null,
    payment_status: wave?.payment_status ?? null,
    expires_at: wave?.when_expires ?? null,
    reused: false,
  });
});
