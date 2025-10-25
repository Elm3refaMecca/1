// في المسار: /web/firebase-messaging-sw.js

// استيراد مكتبات Firebase (متوافق مع الإصدارات الأقدم v9 compat)
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// ... (const firebaseConfig تبقى كما هي) ...
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


// تهيئة Firebase
firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// معالجة الرسائل الواردة في الخلفية
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);

  const notificationTitle = payload.notification?.title || payload.webpush?.notification?.title || "إشعار جديد";
  const notificationBody = payload.notification?.body || payload.webpush?.notification?.body || "لديك إشعار جديد.";
  
  const notificationIcon = payload.webpush?.notification?.icon || '/icons/Icon-192.png';
  const notificationBadge = payload.webpush?.notification?.badge || '/2.png';
  
  // التأكد من جلب الصوت المخصص
  const notificationSound = payload.webpush?.notification?.sound || '/1.mp3';

  // --- ✅✅✅ التعديل هنا: تطبيق خاصية "دائم" و "فريد" ---
  const notificationOptions = {
    body: notificationBody,
    icon: notificationIcon,   
    badge: notificationBadge,
    sound: notificationSound, // <-- تطبيق الصوت المخصص
    
    // يجعل الإشعار "دائم" حتى يتفاعل معه المستخدم
    requireInteraction: payload.webpush?.notification?.requireInteraction || true, 
    
    // استخدام "tag" فريد لضمان أن كل إشعار جديد ولا يستبدل القديم
    tag: 'elm3refa-' + Date.now() 
  };
  // --- نهاية التعديل ---

  // عرض الإشعار الأصلي للمستخدم
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// ... (دالة notificationclick تبقى كما هي) ...
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click Received.', event.notification);
  event.notification.close();
  // event.waitUntil(clients.openWindow('/')); 
});