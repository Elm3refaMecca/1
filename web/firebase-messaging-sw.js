// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// ✅ تم وضع بياناتك الحقيقية هنا
const firebaseConfig = {
  apiKey: "AIzaSyCpRziGJhRa3r8oZYreUxffW4a630sIH7c",
  authDomain: "mostfa-said.firebaseapp.com",
  projectId: "mostfa-said",
  storageBucket: "mostfa-said.firebasestorage.app",
  messagingSenderId: "773233380314",
  appId: "1:773233380314:web:b2813e48e0aa3328d6cee3",
  measurementId: "G-MY7BT0ZYLE"
};

// 1. تهيئة فايربيز
firebase.initializeApp(firebaseConfig);

// 2. إعداد استلام الرسائل
const messaging = firebase.messaging();

// 3. معالجة الرسائل في الخلفية (والتطبيق مغلق)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // ✅ الحيلة هنا: إذا لم يكن هناك عنوان، نضع اسم المدرسة
  const notificationTitle = payload.notification.title || "مدرسة المعرفة";
  
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png', // أيقونة الإشعار
    badge: '/icons/Icon-192.png', // أيقونة شريط الحالة الصغيرة
    
    data: payload.data,
    
    // خصائص مهمة للتنبيه
    requireInteraction: true, // يبقي الإشعار حتى يتفاعل المستخدم
    silent: false
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 4. التعامل مع ضغط المستخدم على الإشعار لفتح التطبيق
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close(); // إغلاق الإشعار فوراً

  // محاولة فتح التطبيق أو التركيز عليه
  event.waitUntil(
    clients.matchAll({type: 'window'}).then( windowClients => {
      // البحث عن تبويب مفتوح لنفس الموقع
      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if (client.url.indexOf('/') !== -1 && 'focus' in client) {
          return client.focus();
        }
      }
      // إذا لم يكن مفتوحاً، افتح تبويباً جديداً
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});