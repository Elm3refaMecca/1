// في المسار: /web/firebase-messaging-sw.js
// النسخة الموثوقة التي تعرض الصوت والإشعار معاً

importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyCpRziGJhRa3r8oZYreUxffW4a630sIH7c", // تأكد أنها صحيحة لمشروعك
  authDomain: "mostfa-said.firebaseapp.com",
  projectId: "mostfa-said",
  storageBucket: "mostfa-said.firebasestorage.app",
  messagingSenderId: "773233380314",
  appId: "1:773233380314:web:350ad7c2565062b0d6cee3",
  databaseURL: "https://mostfa-said-default-rtdb.firebaseio.com",
  measurementId: "G-4MPQX98Z8Z"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// معالجة الرسائل الواردة في الخلفية (الطريقة القياسية)
messaging.onBackgroundMessage((payload) => {
  console.log("[SW - Reliable] Background message received ", payload);

  const notificationTitle = payload.notification?.title || payload.webpush?.notification?.title || "إشعار جديد";
  const notificationBody = payload.notification?.body || payload.webpush?.notification?.body || "لديك إشعار جديد.";
  const notificationIcon = payload.webpush?.notification?.icon || '/icons/Icon-192.png';
  const notificationBadge = payload.webpush?.notification?.badge || '/2.png'; // أيقونة شريط الحالة
  const notificationSound = payload.webpush?.notification?.sound || '/1.mp3'; // النغمة

  // إعدادات الإشعار (تتضمن الصوت)
  const notificationOptions = {
    body: notificationBody,
    icon: notificationIcon,   // الأيقونة الكبيرة
    badge: notificationBadge,  // الأيقونة الصغيرة (شريط الحالة)
    sound: notificationSound,  // <-- الصوت سيعمل مع الإشعار
    requireInteraction: payload.webpush?.notification?.requireInteraction || true, // يبقى دائماً
    tag: 'elm3refa-' + Date.now() // يبقى فريداً لمنع الاستبدال
  };

  console.log("[SW - Reliable] Attempting to show notification with options:", notificationOptions);

  // عرض الإشعار (النظام يتولى الصوت معه)
  return self.registration.showNotification(notificationTitle, notificationOptions)
    .then(() => {
        console.log("[SW - Reliable] Notification shown successfully!");
    })
    .catch((err) => {
        console.error("[SW - Reliable] Error showing notification:", err);
    });
});

// عند النقر على الإشعار
self.addEventListener('notificationclick', (event) => {
  console.log('[SW - Reliable] Notification click Received.', event.notification);
  event.notification.close();
  // يمكنك هنا فتح نافذة التطبيق إذا أردت
  // event.waitUntil(clients.openWindow('/'));
});

// رسائل تشخيصية للتأكد من عمل الـ SW
self.addEventListener('install', (event) => {
  console.log('[SW - Reliable] Service Worker installed!');
});

self.addEventListener('activate', (event) => {
  console.log('[SW - Reliable] Service Worker activated!');
});