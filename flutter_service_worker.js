'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "888483df48293866f9f41d3d9274a779",
"icons/Icon-512.png": "4369b0d9638247d2e10860d3eee05594",
"icons/Icon-maskable-512.png": "4369b0d9638247d2e10860d3eee05594",
"icons/Icon-192.png": "0c2f3c2b9b3ac1482dac54473b07901e",
"icons/Icon-maskable-192.png": "0c2f3c2b9b3ac1482dac54473b07901e",
"3.TXR": "04ada90a05153d49149673d2955de62f",
"manifest.json": "a2568be06de01417063af4216f213eb0",
"firebase-messaging-sw%20-%20.txt": "3b7e3fe886b8c65d0400045412f8d831",
"2.png": "1a2fe23320ad71ba032fc115248648e5",
"index.html": "3cddd595e1200750ad06370ed13725c5",
"/": "3cddd595e1200750ad06370ed13725c5",
"1.mp3": "1d5dcf482263ad3a239ef769ed9d9387",
"firebase-messaging-sw.js": "45f53e3cb58c52ef02c7de429871b885",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/1.mp3": "1d5dcf482263ad3a239ef769ed9d9387",
"assets/AssetManifest.bin.json": "43f796fcf7bfd29ff402284817fad806",
"assets/assets/3.png": "cc586c7979cfe2a5033f912d692773a9",
"assets/assets/a5.png": "295fd9ba9b8025b40622fdcebe7e3ade",
"assets/assets/a2.png": "882cddb4f85b26dedfc2b9e12b1bcec3",
"assets/assets/1.png": "0654f125dd587844dd375151d848015a",
"assets/assets/a8.png": "21e3121453681f36c52855077580523d",
"assets/assets/2.png": "f02e3499243b8e265a0f308137106139",
"assets/assets/Cairo-SemiBold.ttf": "e11b6bc7a07669209243fce5de153be4",
"assets/assets/a12.png": "076e966968bb3f0ab3e9413dc7fb83ee",
"assets/assets/Cairo-ExtraBold.ttf": "92ae313db90f497a9b8fec09433a70de",
"assets/assets/a11.png": "0968cbe5913768993adfa2cfe5b39f0b",
"assets/assets/a6.png": "15a226aefb8014ee43f5656677529491",
"assets/assets/a4.png": "fcb58992e36bfd087f3d47657d9e0e6e",
"assets/assets/1.mp3": "1d5dcf482263ad3a239ef769ed9d9387",
"assets/assets/e2.png": "f02e3499243b8e265a0f308137106139",
"assets/assets/4.png": "632181f94469c5dac9fb1b3528118656",
"assets/assets/Cairo-Regular.ttf": "5ccd08939f634db387c40d6b4b0979c3",
"assets/assets/Cairo-ExtraLight.ttf": "a699568a2cf9e5794c5eccf7909b39c5",
"assets/assets/a9.png": "ad3b79f9f72bce8d6c142328bddb7e33",
"assets/assets/a10.png": "3179d96bbb7863b7484550860720d09d",
"assets/assets/a1.png": "3b3df855b905db23a90b8ffba5d8acab",
"assets/assets/a3.png": "8b354ae79b800b771fc4d0c77cd7ba7b",
"assets/assets/Cairo-Light.ttf": "c4a2ada0dd57e03f921b8f7d45820268",
"assets/assets/m1.png": "bf52ce0df466a15fe5d13dddea9fbace",
"assets/assets/whatsapp-button.json": "fcbebee868fbdc450961c5b88cc7213c",
"assets/assets/a13.png": "1f7d9a99d3558264b1f4c0ba2eeb8501",
"assets/assets/a7.png": "0a70e4026a894f61f139b7affb28f203",
"assets/assets/Cairo-Bold.ttf": "ad486798eb3ea4fda12b90464dd0cfcd",
"assets/assets/Cairo-Medium.ttf": "2b76c14c6934874d64ab85d92c4949e1",
"assets/assets/Cairo-Black.ttf": "d5cfdef0ee5e1b9765295e3b58f43233",
"assets/fonts/MaterialIcons-Regular.otf": "50bd124b3d772885403670584e763262",
"assets/NOTICES": "aab3accb9519e23fc707e1632aa3c3d9",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/FontManifest.json": "116a11a286753ab3cbfb548f3e76ab09",
"assets/AssetManifest.bin": "2e03b714613be2fc545a5aeb5560a48d",
"assets/AssetManifest.json": "e676f25403229155b3861530226d5c44",
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
"index%20-%20Copyt.txt": "32a39dcffc9f083069ef44ab8d866843",
"favicon.png": "ac6f68dbb131429dba1256a802fb3407",
"1.tesx": "ecd3a1e645078ee8ed1884a5816801db",
"firebase-messaging-sw%20-%20Copy.txt": "5ff42257bbc4783ac3a16293c7eea017",
"flutter_bootstrap.js": "23d0fdefbd307f6267f705cbd56244b0",
"firebase-messaging-sw%20-3.txr": "81a263f5ed95c3c3e1d3451181244841",
"version.json": "d3826aa4d2b204320d5224c7d918c663",
"index%20-%20.tex": "ecd3a1e645078ee8ed1884a5816801db",
"main.dart.js": "440f235acc728aa4772c7d04dc9a125e"};
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
