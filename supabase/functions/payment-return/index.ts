import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve((req: Request) => {
  const url = new URL(req.url);
  const status = (url.searchParams.get("status") ?? "pending").toLowerCase();
  const orderId = url.searchParams.get("order_id") ?? "";
  const message = status === "success"
    ? "Paiement traité. Revenez dans l’application pour consulter votre commande."
    : status === "error"
      ? "Le paiement n’a pas été validé. Revenez dans l’application pour vérifier son état ou réessayer."
      : "Retour du guichet de paiement. Revenez dans l’application pour vérifier votre commande.";
  const deepLink = orderId
    ? "marketplaceburkina://orders/" + encodeURIComponent(orderId)
    : "marketplaceburkina://orders";
  const html = "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\">" +
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Paiement</title></head>" +
    "<body style=\"font-family:system-ui;max-width:560px;margin:48px auto;padding:24px\">" +
    "<h1>Paiement</h1><p>" + message + "</p><p><a href=\"" + deepLink + "\">Retourner dans l’application</a></p>" +
    "</body></html>";
  return new Response(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8" },
  });
});