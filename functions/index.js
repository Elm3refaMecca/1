// استيراد الدوال من الإصدار الثاني (V2)
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth"); // ✅ ضروري لإنشاء التوكن

// تهيئة Firebase Admin SDK
initializeApp();
const db = getFirestore();
const auth = getAuth(); // ✅ تهيئة خدمة المصادقة

/**
 * 🔔 Trigger: عند إنشاء تقرير سلوكي جديد
 */
exports.sendBehaviorNotification = onDocumentCreated(
  "behavior_reports/{reportId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("❌ لا توجد بيانات في الحدث.");
      return;
    }

    const reportData = snap.data();
    const { studentId, teacherName, type, teacherId } = reportData;

    if (!studentId || !teacherName || !type) {
      console.log("⚠️ البيانات المطلوبة ناقصة.");
      return;
    }

    let message = "";
    if (type === "like") {
      message = `لديك إشادة سلوكية (نبل) من المعلم ${teacherName}.`;
    } else {
      message = `لديك ملاحظة سلوكية (شغب) من المعلم ${teacherName}.`;
    }

    const notificationPayload = {
      message: message,
      teacherId: teacherId || null,
      reportId: event.params.reportId,
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
    };

    try {
      await db
        .collection("students")
        .doc(studentId)
        .collection("notifications")
        .add(notificationPayload);
      console.log("✅ تم إرسال الإشعار للطالب:", studentId);
    } catch (error) {
      console.error("❌ خطأ أثناء إرسال الإشعار:", studentId, error);
    }
  }
);

// ==================================================================
// ✅ بداية الكود الجديد: نظام الدخول الآمن للسبورة الذكية (QR Code)
// ==================================================================

/**
 * دالة مراقبة قاعدة البيانات للدخول السريع
 * تم تحديثها لتعمل مع الإصدار الثاني (V2) مثل الدالة السابقة
 */
exports.generateTokenOnScan = onDocumentUpdated(
  "qr_logins/{sessionId}",
  async (event) => {
    const change = event.data;
    const newData = change.after.data();
    const oldData = change.before.data();

    // التحقق: هل تم إضافة teacher_uid الآن؟
    if (newData.teacher_uid && !oldData.teacher_uid) {
      const teacherUid = newData.teacher_uid;
      console.log(`Teacher scanned code. UID: ${teacherUid}`);

      try {
        // 🔥 إنشاء مفتاح دخول مخصص (Custom Token) باستخدام auth المعرف بالأعلى
        const customToken = await auth.createCustomToken(teacherUid);

        console.log("Custom token created successfully.");

        // كتابة التوكن في نفس الوثيقة
        return change.after.ref.update({
          auth_token: customToken,
          status: "success_token_generated",
          updated_at: FieldValue.serverTimestamp(),
        });
      } catch (error) {
        console.error("Error creating custom token:", error);
        return change.after.ref.update({
          status: "error",
          error_message: error.message,
        });
      }
    }
    return null;
  }
);