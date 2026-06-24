/**
 * Supabase 反代 Worker — 大陆优化方案
 *
 * 部署步骤：
 *   1. 打开 https://dash.cloudflare.com → Workers & Pages → 创建 Worker
 *   2. 粘贴此文件内容 → 部署
 *   3. 绑定自定义域名（需 DNS 托管在 Cloudflare）
 *   4. 修改 AppConfig.supabaseUrl 指向新域名
 *
 * 效果：
 *   - 绕过 DNS 污染：自定义域名由 Cloudflare DNS 解析，大陆可达
 *   - 降低延迟：Worker 运行在 Cloudflare 香港/台北边缘
 *   - 免费额度：10 万请求/天
 */

const SUPABASE_HOST = 'uqaggeaiqcmsxkikyfvl.supabase.co';

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const targetUrl = `https://${SUPABASE_HOST}${url.pathname}${url.search}`;

    // 复制请求头，保留原始 Host 给 Supabase
    const headers = new Headers(request.headers);
    headers.set('Host', SUPABASE_HOST);

    const response = await fetch(targetUrl, {
      method: request.method,
      headers,
      body: request.method !== 'GET' && request.method !== 'HEAD'
        ? await request.arrayBuffer()
        : undefined,
    });

    // 添加 CORS 头（Supabase 已自带，此处为兜底）
    const corsHeaders = new Headers(response.headers);
    corsHeaders.set('Access-Control-Allow-Origin', '*');
    corsHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    corsHeaders.set('Access-Control-Allow-Headers', '*');

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: corsHeaders,
    });
  },
};
