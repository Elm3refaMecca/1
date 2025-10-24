// في المسار: /web/firebase-messaging-sw.js

// استيراد مكتبات Firebase (متوافق مع الإصدارات الأقدم v9 compat)
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// --- 🛑🛑🛑 معلومات المشروع (تم تحديث بعضها من الصور) 🛑🛑🛑 ---
const firebaseConfig = {
  apiKey: "AIzaSyDdS923nE9iXPVVuVLXebIAFPx0gTTdl2o", // (من الصورة)
  authDomain: "YOUR_AUTH_DOMAIN", // ⚠️ (استبدل هذا - غير موجود في الصور)
  projectId: "mostfa-said", // (من الصورة)
  storageBucket: "YOUR_STORAGE_BUCKET", // ⚠️ (استبدل هذا - غير موجود في الصور)
  messagingSenderId: "773233380314", // (من رقم المشروع في الصورة)
  appId: "YOUR_APP_ID" // ⚠️ (استبدل هذا - غير موجود في الصور)
};
// --- 🛑🛑🛑 تأكد من استبدال القيم المتبقية 🛑🛑🛑 ---

// تهيئة Firebase
firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// معالجة الرسائل الواردة في الخلفية
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);

  // استخراج العنوان والنص من الحمولة (Payload)
  const notificationTitle = payload.notification?.title || "إشعار جديد";
  const notificationBody = payload.notification?.body || "لديك إشعار جديد.";

  // خيارات الإشعار (الأيقونة والصوت)
  const notificationOptions = {
    body: notificationBody,
    icon: payload.notification?.icon || '/icons/Icon-192.png', // الأيقونة الافتراضية
    sound: payload.notification?.sound || '/1.mp3', // الصوت الافتراضي
  };

  // عرض الإشعار الأصلي للمستخدم
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// التعامل مع النقر على الإشعار (اختياري)
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click Received.', event.notification);
  event.notification.close();
  // يمكنك إضافة منطق لفتح نافذة معينة هنا
  // event.waitUntil(clients.openWindow('/some-page'));
});