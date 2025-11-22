'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"icons/Icon-512.png": "4369b0d9638247d2e10860d3eee05594",
"icons/Icon-maskable-512.png": "4369b0d9638247d2e10860d3eee05594",
"icons/Icon-192.png": "0c2f3c2b9b3ac1482dac54473b07901e",
"icons/Icon-maskable-192.png": "0c2f3c2b9b3ac1482dac54473b07901e",
"3.TXR": "04ada90a05153d49149673d2955de62f",
"index%20-%20Copy%20(4).html": "ddbc33427e531462f0956f6df05b72ff",
"manifest.json": "a2568be06de01417063af4216f213eb0",
"firebase-messaging-sw%20-%20.txt": "3b7e3fe886b8c65d0400045412f8d831",
"2.png": "1a2fe23320ad71ba032fc115248648e5",
"index.html": "a44d2d54f236494c23bafeb82a78e86c",
"/": "a44d2d54f236494c23bafeb82a78e86c",
"1.mp3": "1d5dcf482263ad3a239ef769ed9d9387",
"firebase-messaging-sw.js": "45f53e3cb58c52ef02c7de429871b885",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/1.mp3": "1d5dcf482263ad3a239ef769ed9d9387",
"assets/AssetManifest.bin.json": "e5c6ed2f70965b228229dee17755a3e6",
"assets/assets/3.png": "cc586c7979cfe2a5033f912d692773a9",
"assets/assets/a5.png": "295fd9ba9b8025b40622fdcebe7e3ade",
"assets/assets/b11.png": "55490b0836c7ff13b7a2fd958d4c10d7",
"assets/assets/b5.png": "ed424728c627809a47e2d1d32cd9022f",
"assets/assets/a2.png": "882cddb4f85b26dedfc2b9e12b1bcec3",
"assets/assets/t8.png": "a69f41df7d5df20425552b3b29a88296",
"assets/assets/1.png": "0654f125dd587844dd375151d848015a",
"assets/assets/a8.png": "21e3121453681f36c52855077580523d",
"assets/assets/2.png": "f02e3499243b8e265a0f308137106139",
"assets/assets/Cairo-SemiBold.ttf": "e11b6bc7a07669209243fce5de153be4",
"assets/assets/b10.png": "eed97537efdf5a569e1d30d2d6f40dee",
"assets/assets/a12.png": "076e966968bb3f0ab3e9413dc7fb83ee",
"assets/assets/Cairo-ExtraBold.ttf": "92ae313db90f497a9b8fec09433a70de",
"assets/assets/t2.png": "cabd5a554ab91c3c49396903ee9ca6f6",
"assets/assets/a11.png": "0968cbe5913768993adfa2cfe5b39f0b",
"assets/assets/a6.png": "15a226aefb8014ee43f5656677529491",
"assets/assets/a4.png": "fcb58992e36bfd087f3d47657d9e0e6e",
"assets/assets/b4.png": "a9ff7644c94981378f91081586b2f493",
"assets/assets/1.mp3": "1d5dcf482263ad3a239ef769ed9d9387",
"assets/assets/b9.png": "125760e81a68744b4f38ebee38176f56",
"assets/assets/b8.png": "22956a009a6acd89ae98229be4842ee8",
"assets/assets/t4.png": "1e2f7779e9c1af1fea6ea0e8044f56ec",
"assets/assets/e2.png": "f02e3499243b8e265a0f308137106139",
"assets/assets/4.png": "632181f94469c5dac9fb1b3528118656",
"assets/assets/Cairo-Regular.ttf": "5ccd08939f634db387c40d6b4b0979c3",
"assets/assets/Cairo-ExtraLight.ttf": "a699568a2cf9e5794c5eccf7909b39c5",
"assets/assets/a9.png": "ad3b79f9f72bce8d6c142328bddb7e33",
"assets/assets/a10.png": "3179d96bbb7863b7484550860720d09d",
"assets/assets/b6.png": "3f9616eb3925a325783aa03e6956aef6",
"assets/assets/t3.png": "16db9e5e8e37d893b0acd11750a628a7",
"assets/assets/b3.png": "539a901d1e157b2aa2033cc9ea5d7d62",
"assets/assets/t9.png": "a76a147352a571f91dbe5ab025202eaa",
"assets/assets/a1.png": "3b3df855b905db23a90b8ffba5d8acab",
"assets/assets/a3.png": "8b354ae79b800b771fc4d0c77cd7ba7b",
"assets/assets/Cairo-Light.ttf": "c4a2ada0dd57e03f921b8f7d45820268",
"assets/assets/t7.png": "f9a631151724dc1edbc2a2f6b83eafda",
"assets/assets/b2.png": "13f2c5c70b93261d24f7137399d1eb6c",
"assets/assets/m1.png": "bf52ce0df466a15fe5d13dddea9fbace",
"assets/assets/whatsapp-button.json": "fcbebee868fbdc450961c5b88cc7213c",
"assets/assets/b1.png": "80c5c1576833375d17a42c1be249ccff",
"assets/assets/a13.png": "1f7d9a99d3558264b1f4c0ba2eeb8501",
"assets/assets/a7.png": "0a70e4026a894f61f139b7affb28f203",
"assets/assets/t1.png": "4c9e9aec417d926103ca0e43d8316961",
"assets/assets/Cairo-Bold.ttf": "ad486798eb3ea4fda12b90464dd0cfcd",
"assets/assets/t6.png": "72ab3c73eb47c7011a184c812fe137fe",
"assets/assets/b7.png": "07c3fbdba5b0ffc0d2f8a0bf0c657c8a",
"assets/assets/Cairo-Medium.ttf": "2b76c14c6934874d64ab85d92c4949e1",
"assets/assets/Cairo-Black.ttf": "d5cfdef0ee5e1b9765295e3b58f43233",
"assets/assets/t5.png": "d5fa8964f68c6b0cd05e030ec0f456d7",
"assets/fonts/MaterialIcons-Regular.otf": "4609f431ac9368f0de652c29d6d2e444",
"assets/NOTICES": "452e90c60d112fce9a02671ea675d3fc",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/FontManifest.json": "116a11a286753ab3cbfb548f3e76ab09",
"assets/AssetManifest.bin": "4041c5d31c2ae60c282a9679c51f8ba0",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"index%20-%20Copyt.txt": "32a39dcffc9f083069ef44ab8d866843",
"favicon.png": "ac6f68dbb131429dba1256a802fb3407",
"index%20-%20Copy.html": "32a39dcffc9f083069ef44ab8d866843",
"1.json": "7949696d8244435630a57e043185c721",
"1.tesx": "ecd3a1e645078ee8ed1884a5816801db",
"firebase-messaging-sw%20-%20Copy.txt": "5ff42257bbc4783ac3a16293c7eea017",
"flutter_bootstrap.js": "fb483b222e76fb2d467a2f699a90a690",
"firebase-messaging-sw%20-3.txr": "81a263f5ed95c3c3e1d3451181244841",
"index%20-%20Copy%20(2).html": "f5bea827d60e1dda1db5e02a96ba9188",
"version.json": "d3826aa4d2b204320d5224c7d918c663",
"index%20-%20.tex": "ecd3a1e645078ee8ed1884a5816801db",
"index%20-%20Copy%20(3).html": "ddbc33427e531462f0956f6df05b72ff",
"main.dart.js": "d78a50aa505f89eb501bbe0a4f721d51"};
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
