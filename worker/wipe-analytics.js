// Cloudflare Worker — Wipe anonymous analytics
//
// Setup:
//   1. Create a KV namespace called WIPE_STATS
//   2. Bind it to this worker as WIPE_STATS
//   3. Deploy: wrangler deploy
//
// Endpoints:
//   POST /launch              → increment launch counter
//   POST /session              → body: { "duration": 45.2 } → add to global stats
//   GET  /stats                → returns public vanity metrics
//
// Zero personal data stored. No IP logging, no cookies, no device IDs.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          ...headers,
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    const KV = env.WIPE_STATS;

    if (request.method === "POST" && url.pathname === "/launch") {
      const count = parseInt((await KV.get("launches")) || "0") + 1;
      await KV.put("launches", count.toString());

      const today = new Date().toISOString().slice(0, 10);
      const dau = parseInt((await KV.get(`dau:${today}`)) || "0") + 1;
      await KV.put(`dau:${today}`, dau.toString(), { expirationTtl: 172800 });

      return new Response(JSON.stringify({ ok: true }), { headers });
    }

    if (request.method === "POST" && url.pathname === "/session") {
      const body = await request.json().catch(() => ({}));
      const duration = parseFloat(body.duration) || 0;
      if (duration <= 0)
        return new Response(JSON.stringify({ error: "invalid" }), {
          status: 400,
          headers,
        });

      const totalSessions =
        parseInt((await KV.get("totalSessions")) || "0") + 1;
      const totalTime =
        parseFloat((await KV.get("totalTime")) || "0") + duration;

      await KV.put("totalSessions", totalSessions.toString());
      await KV.put("totalTime", totalTime.toString());

      return new Response(JSON.stringify({ ok: true }), { headers });
    }

    if (request.method === "GET" && url.pathname === "/stats") {
      const launches = parseInt((await KV.get("launches")) || "0");
      const totalSessions = parseInt((await KV.get("totalSessions")) || "0");
      const totalTime = parseFloat((await KV.get("totalTime")) || "0");

      const today = new Date().toISOString().slice(0, 10);
      const todayActive = parseInt((await KV.get(`dau:${today}`)) || "0");

      return new Response(
        JSON.stringify({
          launches,
          totalSessions,
          totalCleaningTimeSeconds: Math.round(totalTime),
          todayActive,
        }),
        { headers }
      );
    }

    return new Response(JSON.stringify({ error: "not found" }), {
      status: 404,
      headers,
    });
  },
};
