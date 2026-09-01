self.addEventListener('install', function(event) {
    self.skipWaiting();
});

self.addEventListener('activate', function(event) {
    event.waitUntil(
        caches.keys().then(function(cacheNames) {
            // 1. مسح كل كاشات التطبيق من جهاز المستخدم
            return Promise.all(
                cacheNames.map(function(cacheName) {
                    return caches.delete(cacheName);
                })
            );
        }).then(function() {
            return self.clients.claim();
        }).then(function() {
            // 2. توجيه جميع التبوبات المفتوحة لتحديث الصفحة
            return self.clients.matchAll({type: 'window'});
        }).then(function(clients) {
            clients.forEach(function(client) {
                client.navigate(client.url);
            });
        }).then(function() {
            // 3. تدمير السيرفس وركر ونفسه نهائياً من جهاز العميل
            return self.registration.unregister();
        })
    );
});