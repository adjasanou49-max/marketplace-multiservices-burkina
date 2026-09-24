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

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const auth = req.headers.get("Authorization");
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = publishableKey();
  if (!auth || !url || !key) {
    return json({ error: "supabase_not_configured" }, 503);
  }

  const apiKey = Deno.env.get("CINETPAY_API_KEY") ?? "";
  const siteId = Deno.env.get("CINETPAY_SITE_ID") ?? "";
  if (!apiKey || !siteId) {
    return json({ error: "cinetpay_not_configured" }, 503);
  }

  let body: { order_id?: string; payment_id?: string; provider?: string };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  const orderId = body.order_id?.trim();
  const provider = body.provider?.trim().toUpperCase();
  let paymentId = body.payment_id?.trim();
  if (!orderId || !provider || provider !== "CINETPAY") {
    return json({ error: "provider_invalid" }, 400);
  }

  const returnUrl = Deno.env.get("CINETPAY_RETURN_URL") ||
    url + "/functions/v1/payment-return?status=success&order_id=" +
      encodeURIComponent(orderId);

  const supabase = createClient(url, key, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (!paymentId) {
    const { data, error } = await supabase.rpc("create_payment_intent", {
      p_order_id: orderId,
      p_provider: provider,
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
  if (String(payment.provider) !== provider) {
    return json({ error: "provider_mismatch" }, 409);
  }

  const paymentRecord = await supabase
    .from("payments")
    .select("status,provider_reference,metadata,amount,currency")
    .eq("id", paymentId)
    .maybeSingle();
  if (paymentRecord.error || !paymentRecord.data) {
    return json({ error: "payment_not_found" }, 404);
  }

  const existing = paymentRecord.data as Record<string, unknown>;
  const metadata = (existing.metadata ?? {}) as Record<string, unknown>;
  if (
    existing.status === "PROCESSING" &&
    typeof metadata.payment_url === "string" &&
    metadata.payment_url
  ) {
    return json({
      payment_id: paymentId,
      provider,
      gateway: "CINETPAY",
      checkout_url: metadata.payment_url,
      provider_reference: existing.provider_reference,
      reused: true,
    });
  }

  const amount = Number(existing.amount);
  const currency = String(existing.currency ?? "");
  if (
    !Number.isInteger(amount) || amount <= 0 || currency !== "XOF" ||
    amount % 5 !== 0
  ) {
    return json({
      error: "payment_amount_invalid",
      detail: "CinetPay XOF amount must be a positive multiple of 5",
    }, 409);
  }

  const transactionId = "CP" + paymentId.replaceAll("-", "");
  const notifyUrl = url + "/functions/v1/cinetpay-webhook";
  const checkout = await fetch("https://api-checkout.cinetpay.com/v2/payment", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "User-Agent": "Marketplace-Multiservices-Burkina/1.0",
    },
    body: JSON.stringify({
      amount,
      currency: "XOF",
      apikey: apiKey,
      site_id: siteId,
      transaction_id: transactionId,
      description: "Commande marketplace " + orderId.slice(0, 12),
      return_url: returnUrl,
      notify_url: notifyUrl,
      metadata: paymentId,
      channels: "MOBILE_MONEY",
      lang: "FR",
    }),
  });

  const response = await checkout.json().catch(() => null);
  const paymentUrl = String(response?.data?.payment_url ?? "").trim();
  if (!checkout.ok || String(response?.code ?? "") !== "201" || !paymentUrl) {
    return json({
      error: "cinetpay_api_error",
      provider_status: checkout.status,
      code: response?.code ?? null,
      message: "CinetPay rejected the payment", 
    }, 502);
  }

  const { error: prepareError } = await supabase.rpc(
    "prepare_payment_processing",
    {
      p_payment_id: paymentId,
      p_provider_reference: transactionId,
      p_metadata: {
        gateway: "CINETPAY",
        payment_url: paymentUrl,
        requested_provider: provider,
        notify_url: notifyUrl,
      },
    },
  );
  if (prepareError) return json({ error: "payment_processing_failed" }, 409);

  return json({
    payment_id: paymentId,
    provider,
    gateway: "CINETPAY",
    checkout_url: paymentUrl,
    provider_reference: transactionId,
    reused: false,
  });
});
