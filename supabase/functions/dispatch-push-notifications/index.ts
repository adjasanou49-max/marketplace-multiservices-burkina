import "jsr:@supabase/functions-js@^2.116.0/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

type Json = Record<string, unknown>;

type AdminSchema = {
  Tables: Record<
    string,
    {
      Row: Record<string, unknown>;
      Insert: Record<string, unknown>;
      Update: Record<string, unknown>;
      Relationships: [];
    }
  >;
  Views: Record<
    string,
    {
      Row: Record<string, unknown>;
      Relationships: [];
    }
  >;
  Functions: Record<
    string,
    {
      Args: Record<string, unknown>;
      Returns: unknown;
    }
  >;
  Enums: Record<string, string>;
  CompositeTypes: Record<string, Record<string, unknown>>;
};

type AdminDatabase = { public: AdminSchema };
type AdminClient = SupabaseClient<AdminDatabase, "public">;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

function secretKey(): string {
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (parsed.default) return parsed.default;
    } catch (_) {
      // Ignore malformed secret container and fall back to the standard key.
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/g,
    "",
  );
}

function textBase64Url(value: string): string {
  return base64Url(new TextEncoder().encode(value));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function makeAccessToken(serviceAccount: Json): Promise<string> {
  const clientEmail = String(serviceAccount.client_email ?? "").trim();
  const privateKeyPem = String(serviceAccount.private_key ?? "").replace(
    /\\n/g,
    "\n",
  );
  if (!clientEmail || !privateKeyPem) {
    throw new Error("FCM_SERVICE_ACCOUNT_INVALID");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = textBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = textBase64Url(JSON.stringify({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = header + "." + claim;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    ),
  );
  const assertion = unsigned + "." + base64Url(signature);

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const token = await tokenResponse.json().catch(() => null);
  if (!tokenResponse.ok || !token?.access_token) {
    throw new Error("FCM_OAUTH_FAILED");
  }
  return String(token.access_token);
}

function preferenceEnabled(type: string, prefs: Json): boolean {
  const normalized = type.toLowerCase();
  if (
    normalized.includes("order") || normalized.includes("payment") ||
    normalized.includes("commande")
  ) return prefs.orders !== false;
  if (
    normalized.includes("delivery") || normalized.includes("courier") ||
    normalized.includes("livraison")
  ) return prefs.delivery !== false;
  if (normalized.includes("message") || normalized.includes("chat")) {
    return prefs.messages !== false;
  }
  if (
    normalized.includes("promotion") || normalized.includes("coupon") ||
    normalized.includes("promo")
  ) return prefs.promotions !== false;
  if (
    normalized.includes("service") || normalized.includes("mechanic") ||
    normalized.includes("transport")
  ) return prefs.services !== false;
  return true;
}

function fcmData(data: unknown): Record<string, string> {
  if (!data || typeof data !== "object") return {};
  const record = data as Record<string, unknown>;
  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(record)) {
    if (value === null || value === undefined) continue;
    result[key] = typeof value === "string" ? value : JSON.stringify(value);
  }
  return result;
}

async function sendToToken(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  const response = await fetch(
    "https://fcm.googleapis.com/v1/projects/" + encodeURIComponent(projectId) +
      "/messages:send",
    {
      method: "POST",
      headers: {
        Authorization: "Bearer " + accessToken,
        "Content-Type": "application/json; UTF-8",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "marketplace_default",
              sound: "default",
            },
          },
          apns: {
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    },
  );
  const result = await response.json().catch(() => null);
  return {
    ok: response.ok,
    status: response.status,
    body: result,
  };
}

async function processNotification(
  adminClient: AdminClient,
  accessToken: string,
  projectId: string,
  notificationId: string,
) {
  const claimed = await adminClient.rpc("claim_notification_for_push", {
    p_notification_id: notificationId,
  });

  if (claimed.error) throw claimed.error;
  const claimedRows = Array.isArray(claimed.data) ? claimed.data : [];
  if (claimedRows.length === 0) {
    return {
      id: notificationId,
      skipped: true,
      locked_or_already_processed: true,
    };
  }

  const notification = claimedRows[0] as Json;
  const userId = String(notification.user_id ?? "").trim();
  if (!userId) {
    throw new Error("NOTIFICATION_USER_INVALID");
  }

  try {
    const prefResult = await adminClient
      .from("notification_preferences")
      .select("orders,promotions,messages,delivery,services")
      .eq("user_id", userId)
      .maybeSingle();

    if (prefResult.error) throw prefResult.error;

    const prefs = (prefResult.data ?? {}) as Json;
    if (!preferenceEnabled(String(notification.type ?? ""), prefs)) {
      await adminClient
        .from("notifications")
        .update({
          push_sent_at: new Date().toISOString(),
          push_processing_at: null,
          push_error: "DISABLED_BY_PREFERENCE",
        })
        .eq("id", notificationId);

      return {
        id: notificationId,
        skipped: true,
        preference_disabled: true,
      };
    }

    const deviceResult = await adminClient
      .from("notification_devices")
      .select("id,push_token,platform")
      .eq("user_id", userId)
      .eq("active", true);

    if (deviceResult.error) throw deviceResult.error;

    const devices = (deviceResult.data ?? []) as Json[];
    if (devices.length === 0) {
      await adminClient
        .from("notifications")
        .update({
          push_processing_at: null,
          push_error: "NO_ACTIVE_DEVICE",
          push_attempts: Number(notification.push_attempts ?? 0) + 1,
        })
        .eq("id", notificationId);

      return { id: notificationId, sent: 0 };
    }

    const title = String(notification.title ?? "Marketplace Burkina");
    const body = String(notification.body ?? "Nouvelle notification");
    const data = fcmData(notification.data);
    data.notification_id = notificationId;
    data.type = String(notification.type ?? "general");

    const results = await Promise.all(
      devices.map(async (device) => {
        const token = String(device.push_token ?? "").trim();
        if (!token) return { token, ok: false, status: 0, body: null };

        const result = await sendToToken(
          accessToken,
          projectId,
          token,
          title,
          body,
          data,
        );

        const details = Array.isArray(result.body?.error?.details)
          ? result.body.error.details
          : [];
        const fcmError = details.find(
          (detail: Json) =>
            detail["@type"] ===
              "type.googleapis.com/google.firebase.fcm.v1.FcmError",
        ) as Json | undefined;
        const errorCode = fcmError?.errorCode;

        if (
          !result.ok && (errorCode === "UNREGISTERED" || result.status === 404)
        ) {
          await adminClient
            .from("notification_devices")
            .update({ active: false, last_seen_at: new Date().toISOString() })
            .eq("id", String(device.id ?? ""));
        }

        return { token, ...result };
      }),
    );

    const sent = results.filter((item) => item.ok).length;
    const errors = results
      .filter((item) => !item.ok)
      .map((item) => item.body?.error?.message ?? "FCM_SEND_FAILED")
      .slice(0, 5);

    await adminClient
      .from("notifications")
      .update({
        push_sent_at: sent > 0 ? new Date().toISOString() : null,
        push_processing_at: null,
        push_attempts: Number(notification.push_attempts ?? 0) + 1,
        push_error: sent > 0
          ? errors.length ? errors.join(" | ") : null
          : errors.join(" | ") || "FCM_SEND_FAILED",
      })
      .eq("id", notificationId);

    return {
      id: notificationId,
      sent,
      total: devices.length,
      errors,
    };
  } catch (error) {
    await adminClient
      .from("notifications")
      .update({
        push_processing_at: null,
        push_attempts: Number(notification.push_attempts ?? 0) + 1,
        push_error: error instanceof Error
          ? error.message
          : "PUSH_PROCESSING_FAILED",
      })
      .eq("id", notificationId);

    throw error;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const adminKey = secretKey();
  const dispatchSecret = req.headers.get("x-push-dispatch-secret") ?? "";
  if (!url || !adminKey || !dispatchSecret) {
    return json({ error: "not_configured" }, 503);
  }

  const adminClient: AdminClient = createClient<AdminDatabase, "public">(
    url,
    adminKey,
    {
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
  const check = await adminClient.rpc("verify_push_dispatch_secret", {
    p_candidate: dispatchSecret,
  });
  if (check.error || check.data !== true) {
    return json({ error: "unauthorized" }, 401);
  }

  const serviceAccountRaw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";
  if (!serviceAccountRaw) return json({ error: "fcm_not_configured" }, 503);
  let serviceAccount: Json;
  try {
    serviceAccount = JSON.parse(serviceAccountRaw) as Json;
  } catch (_) {
    return json({ error: "fcm_service_account_invalid" }, 503);
  }

  const projectId = String(
    serviceAccount.project_id ?? Deno.env.get("FCM_PROJECT_ID") ?? "",
  ).trim();
  if (!projectId) return json({ error: "fcm_project_id_missing" }, 503);

  let accessToken: string;
  try {
    accessToken = await makeAccessToken(serviceAccount);
  } catch (error) {
    return json({
      error: error instanceof Error ? error.message : "fcm_auth_failed",
    }, 503);
  }

  let payload: { notification_id?: string };
  try {
    payload = await req.json();
  } catch (_) {
    payload = {};
  }

  if (payload.notification_id) {
    const result = await processNotification(
      adminClient,
      accessToken,
      projectId,
      payload.notification_id,
    );
    return json(result);
  }

  const pending = await adminClient
    .from("notifications")
    .select("id")
    .is("push_sent_at", null)
    .lt("push_attempts", 20)
    .gte(
      "created_at",
      new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    )
    .order("created_at", { ascending: true })
    .limit(50);
  if (pending.error) return json({ error: pending.error.message }, 500);

  const ids = ((pending.data ?? []) as Json[]).map((row) => String(row.id));
  const results = await Promise.all(
    ids.map((id) =>
      processNotification(adminClient, accessToken, projectId, id)
    ),
  );
  return json({ processed: results.length, results });
});
