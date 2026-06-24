export default async function handler(req, res) {
  const target = new URL(req.url, 'https://uqaggeaiqcmsxkikyfvl.supabase.co');
  
  const headers = {};
  for (const [k, v] of Object.entries(req.headers)) {
    if (k !== 'host') headers[k] = v;
  }
  headers['host'] = 'uqaggeaiqcmsxkikyfvl.supabase.co';
  
  const response = await fetch(target.toString(), {
    method: req.method,
    headers,
    body: req.method !== 'GET' && req.method !== 'HEAD' ? JSON.stringify(req.body) : undefined,
  });
  
  const data = await response.text();
  res.status(response.status);
  response.headers.forEach((v, k) => res.setHeader(k, v));
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.send(data);
}
