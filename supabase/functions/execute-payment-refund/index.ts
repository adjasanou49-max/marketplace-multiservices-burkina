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
    } catch (_) {}
  }
  return Deno.env.get("SUPABASE_ANON_KEY") ?? "";
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

  const auth = req.headers.get("Authorization");
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = publishableKey();
  const adminKey = secretKey();
  if (!auth || !url || !key || !adminKey) {
    return json({ error: "supabase_not_configured" }, 503);
  }

  let body: { refund_id?: string };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }
  const refundId = body.refund_id?.trim();
  if (!refundId) return json({ error: "refund_required" }, 400);

  const userClient = createClient(url, key, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: refundRows, error: beginError } = await userClient.rpc(
    "admin_begin_refund",
    {
      p_refund_id: refundId,
    },
  );
  if (beginError) return json({ error: beginError.message }, 409);
  if (!Array.isArray(refundRows) || refundRows.length === 0) {
    return json({ error: "refund_not_found" }, 404);
  }

  const refund = refundRows[0] as Record<string, unknown>;
  const provider = String(refund.provider ?? "");
  const providerReference = String(refund.provider_reference ?? "").trim();
  const amount = Number(refund.amount);
  if (
    !provider || !providerReference || !Number.isFinite(amount) || amount <= 0
  ) {
    return json({ error: "refund_provider_data_invalid" }, 409);
  }

  const adminClient = createClient(url, adminKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (provider !== "WAVE") {
    await adminClient
      .from("refunds")
      .update({
        status: "APPROVED",
        reason: (
          String(refund.reason ?? "") +
          " | Exécution automatique non disponible pour " +
          provider +
          "; traitement fournisseur manuel requis."
        ).slice(0, 1000),
      })
      .eq("id", refundId);

    return json({
      ok: false,
      manual_required: true,
      provider,
      refund_id: refundId,
      message: "Remboursement fournisseur manuel requis.",
    }, 409);
  }

  const waveApiKey = Deno.env.get("WAVE_API_KEY");
  if (!waveApiKey) {
    await adminClient.from("refunds").update({ status: "APPROVED" }).eq(
      "id",
      refundId,
    );
    return json({ error: "wave_not_configured", refund_id: refundId }, 503);
  }

  const waveResponse = await fetch(
    "https://api.wave.com/v1/checkout/sessions/" +
      encodeURIComponent(providerReference) +
      "/refund",
    {
      method: "POST",
      headers: { Authorization: "Bearer " + waveApiKey },
    },
  );

  const responseText = await waveResponse.text();
  if (!waveResponse.ok) {
    await adminClient
      .from("refunds")
      .update({
        status: "FAILED",
        reason: (
          String(refund.reason ?? "") +
          " | Wave refund error " +
          waveResponse.status +
          ": " +
          responseText.slice(0, 500)
        ).slice(0, 1000),
      })
      .eq("id", refundId);

    return json({
      error: "wave_refund_failed",
      provider_status: waveResponse.status,
      refund_id: refundId,
    }, 502);
  }

  const { error: completeError } = await adminClient.rpc("complete_refund", {
    p_refund_id: refundId,
    p_provider_reference: "WAVE_REFUND:" + providerReference,
  });

  if (completeError) {
    return json({
      error: completeError.message,
      refund_provider_confirmed: true,
      refund_id: refundId,
    }, 409);
  }

  return json({
    ok: true,
    refund_id: refundId,
    provider: "WAVE",
    amount,
    status: "COMPLETED",
  });
});
