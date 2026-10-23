// =========================================================
// EDGE FUNCTION: gemini-proxy
// Meneruskan permintaan dari index.html ke Gemini API.
// Secret yang harus diset (Edge Functions > Secrets):
//   GEMINI_API_KEY = API key Google AI Studio
// Deploy dengan "Verify JWT" DIMATIKAN (kunci publishable bukan JWT).
// =========================================================
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!GEMINI_API_KEY) return json({ error: "Secret GEMINI_API_KEY belum diset di Edge Functions." }, 500);

  const body = await req.json().catch(() => null);
  if (!body || !Array.isArray(body.contents)) return json({ error: "Body tidak valid." }, 400);

  const model = String(body.model || "gemini-flash-latest").replace(/[^a-zA-Z0-9._-]/g, "");
  const payload: Record<string, unknown> = { contents: body.contents };
  if (body.generationConfig) payload.generationConfig = body.generationConfig;
  if (body.systemInstruction) payload.systemInstruction = body.systemInstruction;

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_API_KEY },
        body: JSON.stringify(payload),
      },
    );
    const text = await res.text();
    return new Response(text, {
      status: res.status,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (e) {
    return json({ error: "Gagal menghubungi Gemini: " + String(e) }, 502);
  }
});
