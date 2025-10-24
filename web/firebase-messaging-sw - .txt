// في المسار: /web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// --- 🛑🛑🛑 هام جداً 🛑🛑🛑 ---
// --- قم بملء هذه البيانات من مشروعك على Firebase ---
const firebaseConfig = {
  apiKey: "YOUR_API_KEY", // (استبدل هذا)
  authDomain: "YOUR_AUTH_DOMAIN", // (استبدل هذا)
  projectId: "YOUR_PROJECT_ID", // (استبدل هذا)
  storageBucket: "YOUR_STORAGE_BUCKET", // (استبدل هذا)
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID", // (استبدل هذا)
  appId: "YOUR_APP_ID" // (استبدل هذا)
};
// --- 🛑🛑🛑 نهاية القسم الهام 🛑🛑🛑 ---


firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// هذا الجزء يعالج الإشعارات في الخلفية
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);

  // جلب البيانات من الحمولة (Payload) التي أرسلتها الدالة السحابية
  // (نحن نعتمد الآن على حمولة webpush التي أرسلناها من index.js)
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon || '/icons/Icon-192.png',
    
    // --- ✅✅✅ (هذا هو التعديل المطلوب) ✅✅✅ ---
    // التأكد من استخدام المسار الصحيح للنغمة كما هو في مجلد web
    // صورتك تؤكد أن الملف اسمه 1.mp3 وموجود في الجذر
    sound: payload.notification.sound || '/1.mp3', 
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});