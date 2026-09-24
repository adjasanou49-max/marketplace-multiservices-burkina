import "jsr:@supabase/functions-js@^2.116.0/edge-runtime.d.ts";

Deno.serve((_req: Request) => {
  return new Response(
    JSON.stringify({ error: "legacy_endpoint_retired" }),
    { status: 410, headers: { "content-type": "application/json" } },
  );
});
