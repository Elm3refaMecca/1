'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"main.dart.js_3.part.js": "c1b4fbb70a8b8c72b57a13611a202378",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"icons/Icon-512.png": "4369b0d9638247d2e10860d3eee05594",
"icons/Icon-maskable-512.png": "4369b0d9638247d2e10860d3eee05594",
"icons/Icon-192.png": "0c2f3c2b9b3ac1482dac54473b07901e",
"icons/Icon-maskable-192.png": "0c2f3c2b9b3ac1482dac54473b07901e",
"main.dart.js_1.part.js": "06989f36e2e477a3704639324ff6b292",
"manifest.json": "2a4fc497c7b1cfea276b9b611e19a237",
"index.html": "5d93ffdc194e7f4703f0e4302f1a12c2",
"/": "5d93ffdc194e7f4703f0e4302f1a12c2",
"main.dart.js_2.part.js": "af4c7cd5f113a2debc9cc1c4fbe5ba14",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "17e6d0621c375f4b0816ed2dfc61d543",
"assets/assets/3.png": "cc586c7979cfe2a5033f912d692773a9",
"assets/assets/1.png": "0654f125dd587844dd375151d848015a",
"assets/assets/2.png": "9b5ae3e2005e084d7a9a578332e08560",
"assets/assets/Cairo-SemiBold.ttf": "e11b6bc7a07669209243fce5de153be4",
"assets/assets/Cairo-ExtraBold.ttf": "92ae313db90f497a9b8fec09433a70de",
"assets/assets/e2.png": "e4c5a33467d21c7b6bb40eba05cf4ffb",
"assets/assets/4.png": "632181f94469c5dac9fb1b3528118656",
"assets/assets/Cairo-Regular.ttf": "5ccd08939f634db387c40d6b4b0979c3",
"assets/assets/Cairo-ExtraLight.ttf": "a699568a2cf9e5794c5eccf7909b39c5",
"assets/assets/Cairo-Light.ttf": "c4a2ada0dd57e03f921b8f7d45820268",
"assets/assets/m1.png": "bf52ce0df466a15fe5d13dddea9fbace",
"assets/assets/whatsapp-button.json": "6407595342adcfbebc7f0e92a906b23d",
"assets/assets/Cairo-Bold.ttf": "ad486798eb3ea4fda12b90464dd0cfcd",
"assets/assets/Cairo-Medium.ttf": "2b76c14c6934874d64ab85d92c4949e1",
"assets/assets/Cairo-Black.ttf": "d5cfdef0ee5e1b9765295e3b58f43233",
"assets/fonts/MaterialIcons-Regular.otf": "c28cd0b31c899b679b1991f9db197088",
"assets/NOTICES": "e535e47abe97c6a419c516400765637c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/FontManifest.json": "116a11a286753ab3cbfb548f3e76ab09",
"assets/AssetManifest.bin": "ad44bc7ecb4434686f10ffa9cc538240",
"assets/AssetManifest.json": "295084d6ac8d81d8c7d76efb8f2f11ee",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"favicon.png": "ac6f68dbb131429dba1256a802fb3407",
"main.dart.js_5.part.js": "5e1f413871703a98a1bb46c0b79d012c",
"main.dart.js_7.part.js": "4f105720807642226be0fcc4a3e9f392",
"main.dart.js_8.part.js": "719446714b5dc052e29a9ce921ac7164",
"main.dart.js_4.part.js": "bdd790285e0f0baecaa6cfba81e182ef",
"flutter_bootstrap.js": "af51d181959a8d7f73e6cd3ae52b35df",
"version.json": "d3826aa4d2b204320d5224c7d918c663",
"main.dart.js": "a972049cbe43782c1ee19c804f36372c",
"main.dart.js_6.part.js": "bf53747455a0bbc948c8b32eebd03c9a"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
