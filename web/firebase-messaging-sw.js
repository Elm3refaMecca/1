// في المسار: /web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyCpRziGJhRa3r8oZYreUxffW4a630sIH7c",
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

// --- ✅✅✅ التعديل هنا: فصل الصوت عن الإشعار مع تأخير ---
// نجعل الدالة async لتمكين استخدام await مع المؤقت (نوعاً ما)
messaging.onBackgroundMessage(async (payload) => {
  console.log("[SW - Modified] Background message received ", payload);

  const notificationTitle = payload.notification?.title || payload.webpush?.notification?.title || "إشعار جديد";
  const notificationBody = payload.notification?.body || payload.webpush?.notification?.body || "لديك إشعار جديد.";
  const notificationIcon = payload.webpush?.notification?.icon || '/icons/Icon-192.png';
  const notificationBadge = payload.webpush?.notification?.badge || '/2.png';
  const notificationSoundPath = payload.webpush?.notification?.sound || '/1.mp3'; // مسار الصوت فقط

  // 1. تشغيل الصوت أولاً
  console.log("[SW - Modified] Playing sound:", notificationSoundPath);
  try {
    const audio = new Audio(notificationSoundPath);
    // محاولة التشغيل، مع تجاهل الخطأ إذا فشل (مثل سياسات التشغيل التلقائي)
    audio.play().catch(err => console.warn("[SW - Modified] Audio play failed (maybe autoplay restriction):", err));
  } catch (err) {
    console.error("[SW - Modified] Error creating/playing audio:", err);
  }

  // 2. الانتظار لمدة 3 ثواني
  console.log("[SW - Modified] Waiting for 3 seconds before showing notification...");
  await new Promise(resolve => setTimeout(resolve, 3000));
  console.log("[SW - Modified] Wait finished. Attempting to show notification.");

  // 3. إعداد خيارات الإشعار المرئي (بدون الصوت هذه المرة)
  const notificationOptions = {
    body: notificationBody,
    icon: notificationIcon,
    badge: notificationBadge,
    // sound: notificationSoundPath, // <-- تم حذف الصوت من هنا
    requireInteraction: payload.webpush?.notification?.requireInteraction || true, // يبقى دائماً
    tag: 'elm3refa-' + Date.now() // يبقى فريداً
  };

  // 4. محاولة عرض الإشعار المرئي **بعد** التأخير
  // **تحذير:** قد يكون الـ Service Worker قد تم إنهاؤه هنا!
  try {
    await self.registration.showNotification(notificationTitle, notificationOptions);
    console.log("[SW - Modified] Notification shown successfully after delay!");
  } catch (err) {
    // هذا الخطأ شائع جداً في هذا السيناريو
    console.error("[SW - Modified] Error showing notification after delay (Service Worker might have been terminated):", err);
    // يمكنك محاولة إظهار إشعار بسيط جداً كـ fallback
    // self.registration.showNotification("خطأ في الإشعار", { body: "حدث خطأ أثناء عرض الإشعار التفصيلي." }).catch(()=>{});
  }

  // لا نرجع شيئاً محدداً هنا لأن العملية أصبحت أكثر تعقيداً
  return Promise.resolve(); // أو لا ترجع شيئاً
});
// --- نهاية التعديل ---

self.addEventListener('notificationclick', (event) => {
  console.log('[SW - Modified] Notification click Received.', event.notification);
  event.notification.close();
  // event.waitUntil(clients.openWindow('/'));
});

// رسائل تشخيصية إضافية للتأكد من عمل الـ SW
self.addEventListener('install', (event) => {
  console.log('[SW - Modified] Service Worker installed!');
});

self.addEventListener('activate', (event) => {
  console.log('[SW - Modified] Service Worker activated!');
});