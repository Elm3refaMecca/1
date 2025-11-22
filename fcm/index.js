// C:\appweb1\fcm\index.js (النسخة النهائية المدمجة)

// 💡 (تعديل) إضافة onDocumentCreated بجانب onDocumentUpdated
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// --- (دالة getTestMaps تبقى كما هي - لا تغيير) ---
function getTestMaps() {
  const testKeyToName = {};
  const testKeyToSubject = {};

  const standardSubjects = {
    "profession1": "رياضيات",
    "profession2": "لغتي",
    "profession3": "إسلاميات",
    "profession4": "علوم",
    "profession5": "نشاط",
    "profession6": "انجليزي",
    "profession7": "اجتماعيات",
    "profession8": "فنية",
    "profession9": "حياتية",
    "profession10": "بدنية",
    "profession11": "رقمية",
    "profession12": "تفكير",
  };

  const standardTests = {
    "e1": "الاختبار الأول (دوري)",
    "e2": "الاختبار الثاني (دوري)",
    "e3": "الاختبار الثالث (دوري)",
    "e14": "اختبار قبلي",
    "e15": "اختبار بعدي",
    "e16": "اختبار احتياطي",
  };

  for (const profKey in standardSubjects) {
    const subjName = standardSubjects[profKey];
    for (const testPrefix in standardTests) {
      const testName = standardTests[testPrefix];
      const fullKey = `${testPrefix}${profKey}`;
      testKeyToName[fullKey] = testName;
      testKeyToSubject[fullKey] = subjName;
    }
  }

  const nafesSubjects = {
    "math": "رياضيات",
    "lughati": "لغتي",
    "science": "علوم",
  };
  const nafesTests = {
    "e1": "الأول أساسي", "e2": "الثاني أساسي", "e3": "الاول ف نافس",
    "e4": "الثاني ف نافس", "e5": "الثالث ف نافس", "e6": "الرابع ف نافس",
    "e7": "الخامس ف نافس", "e8": "السادس ف نافس", "e9": "السابع ف نافس",
    "e10": "الثامن ف نافس", "e11": "التاسع ف نافس", "e12": "العاشر ف نافس",
  };
  const nafesBaseKey = "profession13";

  for (const subjCode in nafesSubjects) {
    const subjName = nafesSubjects[subjCode];
    for (const testPrefix in nafesTests) {
      const testName = nafesTests[testPrefix];
      const fullKey = `${testPrefix}${nafesBaseKey}_${subjCode}`;
      testKeyToName[fullKey] = testName;
      testKeyToSubject[fullKey] = subjName;
    }
  }

  return { testKeyToName, testKeyToSubject };
}


/**
 * دالة مساعدة موحدة لإرسال الإشعار وكتابته في قاعدة البيانات
 * (هذه الدالة موجودة لديك بالفعل)
 */
async function sendNotification(fcmToken, studentId, title, body, actionData) {
  if (!fcmToken) {
    logger.info(`الطالب ${studentId} لا يملك FCM Token. تم تخطي الإشعار.`);
    return;
  }

  const prefixedTitle = `المعرفة: ${title}`;

  const payload = {
    notification: {
      title: prefixedTitle,
      body: body,
    },
    data: actionData,
    webpush: {
      notification: {
        title: prefixedTitle,
        body: body,
        icon: "/icons/Icon-192.png",
        badge: "/2.png",
        sound: "/1.mp3",
        requireInteraction: true,
      },
    },
    apns: { // إعدادات Apple
      payload: {
        aps: {
          sound: "1.mp3",
        },
      },
    },
    android: { // إعدادات Android
      notification: {
        sound: "1.mp3",
      },
    },
  };

  try {
    const response = await messaging.sendToDevice(fcmToken, payload);
    logger.info(`تم إرسال الإشعار بنجاح إلى الطالب: ${studentId}`, response);

    response.results.forEach((result, index) => {
      const error = result.error;
      if (error) {
        logger.error(`فشل إرسال الإشعار إلى توكن [${index}]:`, error);
        if (error.code === "messaging/registration-token-not-registered" ||
            error.code === "messaging/invalid-registration-token") {
          logger.warn(`التوكن ${fcmToken} غير صالح للطالب: ${studentId}. سيتم محاولة حذفه.`);
          db.collection("students").doc(studentId).update({
            fcmToken: FieldValue.delete(),
          }).then(() => {
            logger.info(`تم حذف التوكن غير الصالح للطالب: ${studentId}`);
          }).catch((deleteError) => {
            logger.error(`فشل حذف التوكن للطالب ${studentId}:`, deleteError);
          });
        }
      }
    });

  } catch (error) {
    logger.error(`خطأ عام عند محاولة إرسال الإشعار إلى ${studentId}:`, error);
  }

  try {
    await db.collection("students").doc(studentId).collection("notifications").add({
      message: body,
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
      action: actionData.action,
      relatedId: actionData.studentId,
    });
    logger.info(`تم تسجيل الإشعار في Firestore للطالب: ${studentId}`);
  } catch (dbError) {
    logger.error(`فشل تسجيل الإشعار في Firestore للطالب ${studentId}:`, dbError);
  }
}

/**
 * دالة إشعارات الدرجات والسلوك الحالية الخاصة بك
 * (تبقى كما هي)
 */
exports.sendNotificationOnStudentUpdate = onDocumentUpdated("students/{studentId}", async (event) => {
  if (!event.data) {
    logger.warn("No data in event, exiting.");
    return null;
  }

  const studentDataBefore = event.data.before.data();
  const studentDataAfter = event.data.after.data();
  const studentId = event.params.studentId;
  const fcmToken = studentDataAfter.fcmToken;

  const { testKeyToName, testKeyToSubject } = getTestMaps();

  let notificationTitle = "";
  let notificationBody = "";
  const actionData = {
    action: "OPEN_STUDENT_VIEW",
    studentId: studentId,
  };
  let shouldSend = false;

  // ----- التحقق من تغييرات السلوك -----
  const likesBefore = studentDataBefore.totalLikes ?? 0;
  const likesAfter = studentDataAfter.totalLikes ?? 0;
  const dislikesBefore = studentDataBefore.totalDislikes ?? 0;
  const dislikesAfter = studentDataAfter.totalDislikes ?? 0;

  if (likesAfter > likesBefore) {
    notificationTitle = "تهنئة من المعلم!";
    notificationBody = `أهلاً ${studentDataAfter.name || 'بالطالب'}، لقد حصلت على إعجاب جديد! رائع! 🎉`;
    shouldSend = true;
  } else if (dislikesAfter > dislikesBefore) {
    notificationTitle = "ملاحظة سلوكية";
    notificationBody = `أهلاً ${studentDataAfter.name || 'بالطالب'}، تم تسجيل ملاحظة سلوك. يرجى المراجعة. ⚠️`;
    shouldSend = true;
  }

  if (shouldSend) {
    await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
    return null;
  }

  // ----- التحقق من تغييرات الدرجات (فقط إذا لم يتغير السلوك) -----
  for (const testKey in testKeyToName) {
    const gradeBefore = studentDataBefore[testKey];
    const gradeAfter = studentDataAfter[testKey];

    if (gradeBefore !== gradeAfter && (gradeBefore !== undefined || gradeAfter !== undefined)) {
      const testName = testKeyToName[testKey] || "اختبار";
      const subjectName = testKeyToSubject[testKey] || "مادة";
      shouldSend = true;
      const studentName = studentDataAfter.name || 'أيها الطالب';

      if (gradeBefore === undefined && gradeAfter !== undefined) { // رصد جديد
        notificationTitle = `تم رصد درجة: ${subjectName}`;
        notificationBody = (gradeAfter === -1) ?
          `مرحباً ${studentName}، تم تسجيلك "غائب" في: ${testName}.` :
          `مرحباً ${studentName}، تم رصد درجتك (${gradeAfter}) في: ${testName}.`;
      } else if (gradeBefore !== undefined && gradeAfter !== undefined) { // تعديل درجة
        notificationTitle = `تم تعديل درجة: ${subjectName}`;
        notificationBody = (gradeAfter === -1) ?
          `مرحباً ${studentName}، تم تعديل حالتك إلى "غائب" في: ${testName}.` :
          `مرحباً ${studentName}، تم تعديل درجتك في ${testName} إلى (${gradeAfter}).`;
      } else if (gradeBefore !== undefined && gradeAfter === undefined) { // حذف درجة
        notificationTitle = `تم حذف درجة: ${subjectName}`;
        notificationBody = `مرحباً ${studentName}، تم حذف درجتك التي كانت مسجلة في: ${testName}.`;
      } else {
        shouldSend = false;
      }

      if (shouldSend) {
        await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
        return null;
      }
    }
  }

  if (!shouldSend) {
    logger.info(`تحديث لا يتطلب إشعاراً للطالب ${studentId}.`);
  }
  return null;
});


/**
 * 📣 (إضافة جديدة)
 * Trigger: عند إنشاء مستند جديد في "broadcast_notifications"
 * يرسل إشعارًا عامًا لجميع الطلاب المشتركين في "public_announcements".
 */
exports.sendBroadcastNotification = onDocumentCreated(
  "broadcast_notifications/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("Broadcast: ❌ لا توجد بيانات.");
      return;
    }

    const notificationData = snap.data();
    const { title, body } = notificationData;

    if (!title || !body) {
      logger.warn("Broadcast: ⚠️ العنوان أو النص مفقود.");
      return;
    }

    // هذا هو الموضوع الذي يشترك فيه الطلاب في main.dart
    const topic = "public_announcements";

    // 2. تحضير حمولة الإشعار (Payload)
    const payload = {
      notification: {
        title: title,
        body: body,
        sound: "1.mp3", // استخدام ملف الصوت الافتراضي
      },
      webpush: {
        notification: {
          icon: "icons/Icon-192.png", // أيقونة الويب
          sound: "/1.mp3",
          requireInteraction: true, // جعل الإشعار "دائم"
        },
      },
      apns: { // إعدادات Apple
        payload: {
          aps: {
            sound: "1.mp3",
          },
        },
      },
      android: { // إعدادات Android
        notification: {
          sound: "1.mp3",
        },
      },
      topic: topic,
    };

    try {
      // 3. إرسال الرسالة إلى الموضوع (Topic)
      const response = await getMessaging().send(payload);
      logger.info(`Broadcast: ✅ تم إرسال الإشعار بنجاح إلى ${topic}`, response);
    } catch (error) {
      logger.error(`Broadcast: ❌ فشل إرسال الإشعار إلى ${topic}`, error);
    }
    
    // (اختياري) يمكنك إلغاء التعليق على السطر التالي لحذف الإشعار بعد إرساله
    // return snap.ref.delete();
  }
);