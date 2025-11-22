const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * Triggers when a new behavior report is created, and sends a notification
 * to the corresponding student.
 */
exports.sendBehaviorNotification = functions.firestore
    .document("behavior_reports/{reportId}")
    .onCreate(async (snap, context) => {
      const reportData = snap.data();
      if (!reportData) {
        console.log("No data associated with the event");
        return;
      }

      const {studentId, teacherName, type, teacherId} = reportData;

      if (!studentId || !teacherName || !type) {
        console.log("Missing required data (studentId, teacherName, type).");
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
        teacherId: teacherId,
        reportId: context.params.reportId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      };

      try {
        await db
            .collection("students")
            .doc(studentId)
            .collection("notifications")
            .add(notificationPayload);

        console.log(
            "Successfully sent notification to student:",
            studentId,
        );
      } catch (error) {
        console.error(
            "Error sending notification to student:",
            studentId,
            error,
        );
      }
    });
