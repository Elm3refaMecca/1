// في المسار: /web/firebase-messaging-sw.js

// استيراد مكتبات Firebase (متوافق مع الإصدارات الأقدم v9 compat)
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// --- ✅✅✅ (هذا هو التعديل الأهم) ✅✅✅ ---
// يجب ملء جميع هذه الحقول من إعدادات مشروعك في Firebase
// تم استخدام القيم من ملف firebase_options.dart كمثال
const firebaseConfig = {
  apiKey: "AIzaSyCpRziGJhRa3r8oZYreUxffW4a630sIH7c", // من firebase_options.dart (web)
  authDomain: "mostfa-said.firebaseapp.com", // من firebase_options.dart (web)
  projectId: "mostfa-said", // من firebase_options.dart (web)
  storageBucket: "mostfa-said.firebasestorage.app", // من firebase_options.dart (web)
  messagingSenderId: "773233380314", // من firebase_options.dart (web)
  appId: "1:773233380314:web:350ad7c2565062b0d6cee3", // من firebase_options.dart (web)
  databaseURL: "https://mostfa-said-default-rtdb.firebaseio.com", // من firebase_options.dart (web) - اختياري هنا
  measurementId: "G-4MPQX98Z8Z" // من firebase_options.dart (web) - اختياري هنا
};
// --- ✅✅✅ (نهاية التعديل) ✅✅✅ ---

// تهيئة Firebase
firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// معالجة الرسائل الواردة في الخلفية
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);

  // استخراج العنوان والنص من الحمولة (Payload)
  // ملاحظة: الكود الخلفي (index.js) يرسل العنوان والنص داخل webpush.notification
  // ولكن FCM قد تضعها أيضاً في notification الرئيسي

  const notificationTitle = payload.notification?.title || payload.webpush?.notification?.title || "إشعار جديد";
  const notificationBody = payload.notification?.body || payload.webpush?.notification?.body || "لديك إشعار جديد.";

  // استخراج الأيقونة والصوت من payload.webpush الذي أرسلته من الـ Cloud Function
  const notificationIcon = payload.webpush?.notification?.icon || '/icons/Icon-192.png';
  // 🛑 ملاحظة هامة بخصوص الصوت: المتصفحات تمنع تشغيل الصوت تلقائياً في الخلفية.
  // الصوت المحدد في webpush سيتم تشغيله فقط إذا كان التطبيق مفتوحاً في الواجهة الأمامية
  // واستلمه معالج onMessage في main.dart.
  // لا يمكن ضمان تشغيل الصوت من ملف sw.js هذا.
  // const notificationSound = payload.webpush?.notification?.sound; // لا يمكن استخدامه بشكل موثوق هنا

  // خيارات الإشعار (الأيقونة والصوت)
  const notificationOptions = {
    body: notificationBody,
    icon: notificationIcon,
    // sound: notificationSound, // إزالة الصوت من هنا لأنه غير موثوق
    badge: "/icons/Icon-192.png" // (اختياري: أيقونة للشريط العلوي)
  };

  // عرض الإشعار الأصلي للمستخدم
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// التعامل مع النقر على الإشعار (اختياري)
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click Received.', event.notification);
  event.notification.close();
  // يمكنك إضافة منطق لفتح نافذة معينة هنا
  // event.waitUntil(clients.openWindow('/')); // مثال: فتح الصفحة الرئيسية
});