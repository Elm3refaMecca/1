const admin = require('firebase-admin');

// 💡 تم تعديل هذا السطر ليحتوي على اسم ملف مفتاح الخدمة الخاص بك
const serviceAccount = require('./mostfa-said-firebase-adminsdk-fbsvc-a320b2c76b.json');

// 💡 تهيئة Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 💡 تعريف الدالة الرئيسية لتغيير كلمة المرور
async function updateUserPassword(uid, newPassword) {
  try {
    await admin.auth().updateUser(uid, {
      password: newPassword
    });
    console.log(`✅ تم تحديث كلمة المرور للمستخدم ${uid} بنجاح.`);
  } catch (error) {
    console.error(`❌ فشل تحديث كلمة المرور للمستخدم ${uid}:`, error);
  }
}

// 💡 الخطوة التالية: عدّل هذين السطرين قبل التشغيل
// استبدل 'uid_للمستخدم_هنا' بالـ UID الخاص بالمستخدم
// استبدل 'كلمة_المرور_الجديدة_هنا' بكلمة المرور الجديدة التي تريد تعيينها
const userUid = 'uid_للمستخدم_هنا';
const newPass = 'كلمة_المرور_الجديدة_هنا';

updateUserPassword(userUid, newPass);