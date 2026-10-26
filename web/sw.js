// Veritas Tennis service worker: lets the installed app open offline.
//
// Strategy: stale-while-revalidate for the app's own files. The cached copy is
// served immediately (fast, works offline) and refreshed in the background, so
// a new deployment is picked up on the next launch. Requests to other origins
// (the club sync server) are never cached.
const CACHE = 'veritas-tennis-v1';
const CORE = ['./', 'index.html', 'main.dart.js', 'flutter.js', 'flutter_bootstrap.js', 'manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

// The page sends the list of files it loaded on its first visit.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type !== 'precache' || !Array.isArray(data.urls)) return;
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      Promise.all(
        data.urls
          .filter((u) => typeof u === 'string' && u.startsWith(self.location.origin))
          .map((u) => cache.match(u).then((hit) => hit || cache.add(u).catch(() => {}))),
      ),
    ),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  const key = req.mode === 'navigate' ? 'index.html' : req;
  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const cached = await cache.match(key, { ignoreSearch: req.mode === 'navigate' });
      const fresh = fetch(req)
        .then((res) => {
          if (res.ok) cache.put(key, res.clone());
          return res;
        })
        .catch(() => cached);
      if (cached) {
        event.waitUntil(fresh.catch(() => {}));
        return cached;
      }
      return fresh;
    }),
  );
});
