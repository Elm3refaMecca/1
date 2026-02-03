const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

// ---------------------------------------------------------
// 1️⃣ دالة إشعارات السلوك (الاسم الجديد: sendBehaviorAlert)
// ---------------------------------------------------------
exports.sendBehaviorAlert = functions.firestore
  .document("behavior_reports/{reportId}")
  .onCreate(async (snap, context) => {
    
    const data = snap.data();
    // التحقق من صحة البيانات
    if (!data || !data.studentId || !data.teacherName) return;

    // تحديد نوع الرسالة
    let message = data.type === "like" 
      ? `🌟 إشادة سلوكية (نبل) من المعلم ${data.teacherName}` 
      : `⚠️ ملاحظة سلوكية (شغب) من المعلم ${data.teacherName}`;

    try {
      // البحث عن أولياء الأمور
      const parentsSnapshot = await db.collection("users")
        .where("role", "==", "parent")
        .where("children", "array-contains", data.studentId)
        .get();

      if (parentsSnapshot.empty) {
        console.log("No parents found for student:", data.studentId);
        return;
      }

      const batch = db.batch();
      
      parentsSnapshot.docs.forEach((doc) => {
        const notificationRef = db.collection("users").doc(doc.id).collection("notifications").doc();
        batch.set(notificationRef, {
          message: message,
          studentId: data.studentId,
          reportId: context.params.reportId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
          type: "behavior"
        });
      });

      await batch.commit();
      console.log(`✅ Notification sent to ${parentsSnapshot.size} parents.`);
      
    } catch (error) {
      console.error("❌ Error sending notification:", error);
    }
  });

// ---------------------------------------------------------
// 2️⃣ دالة الباركود QR (الاسم الجديد: handleQrLogin)
// ---------------------------------------------------------
exports.handleQrLogin = functions.firestore
  .document("qr_logins/{sessionId}")
  .onUpdate(async (change, context) => {
    
    const newData = change.after.data();
    const oldData = change.before.data();

    // إذا تم تحديث teacher_uid
    if (newData.teacher_uid && !oldData.teacher_uid) {
      try {
        const token = await auth.createCustomToken(newData.teacher_uid);
        
        return change.after.ref.update({
          auth_token: token,
          status: "success",
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        
      } catch (error) {
        console.error("❌ Error creating custom token:", error);
        return change.after.ref.update({
          status: "error",
          error_message: "Failed to generate token"
        });
      }
    }
    return null;
  });