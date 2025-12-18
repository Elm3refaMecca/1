// استيراد الدوال الحديثة من الإصدار الجديد
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

// تهيئة Firebase Admin SDK
initializeApp();
const db = getFirestore();

/**
 * 🔔 Trigger: عند إنشاء تقرير سلوكي جديد في مجموعة behavior_reports
 * يقوم هذا الكود بإرسال إشعار إلى الطالب المرتبط بهذا التقرير.
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
      console.log("⚠️ البيانات المطلوبة ناقصة (studentId, teacherName, type).");
      return;
    }

    // نص الإشعار حسب نوع السلوك
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
