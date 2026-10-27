const http = require('http');
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==', 'base64');
function category(id) {
  return {id, game_type: 'word', slug: id, sort_order: 0, is_active: true,
    t: [{category_id: id, locale: 'vi', name: id, description: null, status: 'published'}]};
}
function word(id) {
  return {id, category_id: 'a', difficulty: 'easy', is_family_friendly: true,
    image_path: id + '/image.png',
    t: [{prompt_id: id, locale: 'vi', text: id, status: 'published'}]};
}
const counts = {};
http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const parts = url.pathname.split('/').filter(Boolean);
  const mode = parts.shift();
  const path = '/' + parts.join('/');
  const send = (code, body, type = 'application/json') => {
    res.writeHead(code, {'Content-Type': type});
    res.end(type === 'application/json' ? JSON.stringify(body) : body);
  };
  if (mode === 'timeout') await new Promise(resolve => setTimeout(resolve, 300));
  if (path.startsWith('/rest/v1/')) {
    if (mode === 'json') return send(500, {message: 'upstream unavailable'});
    if (mode === 'html') return send(502, '<html>Bad gateway</html>', 'text/html');
    if (mode === 'malformed') return send(200, {unexpected: true});
    const table = parts[2];
    const rows = table === 'game_categories' ? [category('a'), category('b'), category('c')] :
      table === 'word_prompts' ? [word('one'), word('two'), word('three')] :
      table === 'question_prompts' ? [] : null;
    if (!rows) return send(501, {message: 'Endpoint not modeled'});
    const from = Number(url.searchParams.get('offset') || 0);
    const limit = Number(url.searchParams.get('limit') || rows.length);
    if (mode === 'middle' && from > 0) return send(500, {message: 'middle page failed'});
    return send(200, rows.slice(from, from + limit));
  }
  if (req.method === 'POST' && path.startsWith('/storage/v1/object/sign/word-prompt-images/')) {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (body.expiresIn !== 300) return send(400, {message: 'Expected five minute URL'});
    const image = parts.slice(5).join('/');
    return send(200, {signedURL: '/object/sign/word-prompt-images/' + image + '?token=test'});
  }
  if (req.method === 'GET' && path.startsWith('/storage/v1/object/sign/word-prompt-images/')) {
    const key = mode + path;
    counts[key] = (counts[key] || 0) + 1;
    if (mode === 'renew' && counts[key] === 1) return send(400, {message: 'jwt expired'});
    if (mode === 'imagefail') return send(500, {message: 'storage unavailable'});
    return send(200, png, 'image/png');
  }
  send(501, {message: 'Endpoint not modeled'});
}).listen(process.env.PORT || 4500);
