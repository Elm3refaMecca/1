const admin = require('firebase-admin');
const readline = require('readline');

// 💡 تم تعديل هذا السطر ليحتوي على اسم ملف مفتاح الخدمة الخاص بك
const serviceAccount = require('./mostfa-said-firebase-adminsdk-fbsvc-a320b2c76b.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// دالة لتغيير كلمة مرور المستخدم
async function updateUserPassword(uid, newPassword) {
  try {
    await admin.auth().updateUser(uid, {
      password: newPassword
    });
    console.log(`✅ تم تحديث كلمة المرور للمستخدم ${uid} بنجاح.`);
  } catch (error) {
    console.error(`❌ فشل تحديث كلمة المرور للمستخدم ${uid}:`, error);
  } finally {
    rl.close();
  }
}

// البدء بطلب الـ UID وكلمة المرور من المستخدم
rl.question('الرجاء إدخال UID الخاص بالمستخدم: ', (uid) => {
  rl.question('الرجاء إدخال كلمة المرور الجديدة: ', (newPassword) => {
    // استدعاء الدالة بعد الحصول على المعلومات
    updateUserPassword(uid, newPassword);
  });
});