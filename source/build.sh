#!/usr/bin/env bash
# Construit la version autonome (app d'écran d'accueil, hors ligne) depuis prompteur.html,
# la source unique partagée avec la page publiée sur claude.ai.
set -euo pipefail
cd "$(dirname "$0")"
# Dossier de sortie : `autonome` par défaut ; `..` depuis le dépôt epytome-prod/prompteur (publication à la racine).
out="${1:-autonome}"
mkdir -p "$out"

{
  cat <<'HEAD'
<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Prompteur">
<meta name="theme-color" content="#0C0E12">
<meta name="robots" content="noindex">
<link rel="manifest" href="manifest.webmanifest">
<link rel="apple-touch-icon" href="icon-180.png">
<link rel="icon" href="icon-512.png">
<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>
</head>
<body>
HEAD
  cat prompteur.html
  printf '\n</body>\n</html>\n'
} > "$out/index.html"

cat > "$out/manifest.webmanifest" <<'JSON'
{
  "name": "Prompteur Epytome",
  "short_name": "Prompteur",
  "lang": "fr",
  "start_url": "./",
  "scope": "./",
  "display": "fullscreen",
  "display_override": ["fullscreen", "standalone"],
  "orientation": "any",
  "background_color": "#000000",
  "theme_color": "#0C0E12",
  "icons": [
    { "src": "icon-180.png", "sizes": "180x180", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ]
}
JSON

# Le numéro de version du cache suit le contenu : chaque reconstruction force la mise à jour sur l'iPad.
ver=$(cat "$out/index.html" | shasum | cut -c1-10)
cat > "$out/sw.js" <<JS
const CACHE = 'prompteur-${ver}';
const CORE = ['./', 'index.html', 'manifest.webmanifest', 'icon-180.png', 'icon-512.png'];
self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
// Page : réseau d'abord (mises à jour), cache en secours. Polices et bibliothèques : cache d'abord.
self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req).then((res) => { const copy = res.clone(); caches.open(CACHE).then((c) => c.put('index.html', copy)); return res; })
      .catch(() => caches.match('index.html')));
    return;
  }
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req).then((res) => {
    if (res && (res.ok || res.type === 'opaque')) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
    return res;
  })));
});
JS

python3 - "$out" <<'PY'
import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
S = 1024
im = Image.new('RGB', (S, S), (12, 14, 18))
d = ImageDraw.Draw(im)
amber, fg, dim, red = (243, 178, 60), (232, 235, 239), (90, 97, 108), (229, 72, 77)
# Lignes de texte, la ligne lue au repère en clair, les autres atténuées.
rows = [(300, 560, dim), (420, 700, dim), (540, 640, fg), (660, 720, dim), (780, 520, dim)]
for y, w, c in rows:
    d.rounded_rectangle((250, y - 26, 250 + w, y + 26), radius=26, fill=c)
d.polygon([(110, 540 - 70), (110, 540 + 70), (205, 540)], fill=amber)
d.ellipse((150, 140, 230, 220), fill=red)
for size in (180, 512):
    im.resize((size, size), Image.LANCZOS).save(f"{out}/icon-{size}.png")
PY

echo "Version autonome construite dans $out/ (cache $ver)"
