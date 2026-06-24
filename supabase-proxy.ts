/**
 * Supabase 反代 — Deno Deploy 版
 *
 * 部署到 Deno Deploy（deno.dev 大陆可达）：
 *   1. 安装 deployctl: deno install -A --global jsr:@deno/deployctl
 *   2. 部署: deployctl deploy --entrypoint supabase-proxy.ts --project order-manager-proxy
 *   3. 更新 AppConfig.supabaseUrl 为返回的 URL
 */

const SUPABASE_HOST = "uqaggeaiqcmsxkikyfvl.supabase.co";

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const targetUrl = `https://${SUPABASE_HOST}${url.pathname}${url.search}`;

  const headers = new Headers(req.headers);
  headers.set("Host", SUPABASE_HOST);

  const body = req.method !== "GET" && req.method !== "HEAD"
    ? await req.arrayBuffer()
    : undefined;

  const response = await fetch(targetUrl, {
    method: req.method,
    headers,
    body,
  });

  const corsHeaders = new Headers(response.headers);
  corsHeaders.set("Access-Control-Allow-Origin", "*");
  corsHeaders.set("Access-Control-Allow-Methods",
    "GET, POST, PUT, PATCH, DELETE, OPTIONS");
  corsHeaders.set("Access-Control-Allow-Headers", "*");

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: corsHeaders,
  });
});
