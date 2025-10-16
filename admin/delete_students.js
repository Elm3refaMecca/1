const admin = require('firebase-admin');

// 💡 تم تعديل هذا السطر ليحتوي على اسم ملف مفتاح الخدمة الخاص بك
const serviceAccount = require('./mostfa-said-firebase-adminsdk-fbsvc-a320b2c76b.json');

// 💡 تهيئة Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 💡 تعريف الدالة الرئيسية لحذف حسابات الطلاب
async function deleteStudentAccounts() {
  try {
    const listAllUsers = async (nextPageToken) => {
      // الحصول على قائمة المستخدمين بحد أقصى 1000 مستخدم في كل مرة
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      const studentUidsToDelete = [];

      for (const user of listUsersResult.users) {
        // التحقق مما إذا كان UID الخاص بالمستخدم موجوداً في مجموعة الطلاب (students)
        const docRef = db.collection('students').doc(user.uid);
        const doc = await docRef.get();

        if (doc.exists) {
          studentUidsToDelete.push(user.uid);
        }
      }

      if (studentUidsToDelete.length > 0) {
        // حذف حسابات الطلاب دفعة واحدة
        const deleteResult = await admin.auth().deleteUsers(studentUidsToDelete);
        console.log(`✅ تم حذف ${deleteResult.successCount} حسابًا لطالب بنجاح.`);
        if (deleteResult.failureCount > 0) {
          console.error(`❌ فشل حذف ${deleteResult.failureCount} حسابًا.`);
          deleteResult.errors.forEach((err) => {
            console.error(`خطأ في حذف المستخدم ${err.uid}: ${err.error.message}`);
          });
        }
      }

      // إذا كانت هناك صفحة تالية، استمر في الحذف
      if (listUsersResult.pageToken) {
        await listAllUsers(listUsersResult.pageToken);
      } else {
        console.log("✔️ تمت عملية حذف جميع حسابات الطلاب.");
      }
    };
    
    await listAllUsers();

  } catch (error) {
    console.error("❌ حدث خطأ أثناء عملية الحذف:", error);
  }
}

// 💡 تشغيل الدالة
deleteStudentAccounts();