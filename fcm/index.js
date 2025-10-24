// C:\appweb1\fcm\index.js (النسخة الكاملة والصحيحة v3)

// 1. استيراد المكتبات v2
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

// 2. تهيئة التطبيق وقاعدة البيانات
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * دالة مساعدة لإنشاء خرائط بأسماء المواد والاختبارات
 * هذه الدالة ضرورية لإنشاء رسائل إشعار واضحة
 */
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

  // إنشاء مفاتيح الاختبارات العادية
  for (const profKey in standardSubjects) {
    const subjName = standardSubjects[profKey];
    for (const testPrefix in standardTests) {
      const testName = standardTests[testPrefix];
      const fullKey = `${testPrefix}${profKey}`;
      testKeyToName[fullKey] = testName;
      testKeyToSubject[fullKey] = subjName;
    }
  }

  // إنشاء مفاتيح اختبارات نافس
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
 */
async function sendNotification(fcmToken, studentId, title, body, actionData) {
  if (!fcmToken) {
    logger.info(`الطالب ${studentId} لا يملك FCM Token. تم تخطي الإشعار.`);
    return;
  }

  // 1. بناء رسالة الإشعار (Payload)
  const payload = {
    notification: {
      title: title,
      body: body,
      sound: "default",
    },
    data: actionData,
  };

  // 2. إرسال الإشعار
  try {
    await messaging.sendToDevice(fcmToken, payload);
    logger.info(`تم إرسال الإشعار بنجاح إلى الطالب: ${studentId}`);
  } catch (error) {
    logger.error(`فشل في إرسال الإشعار إلى ${studentId}:`, error);
    // إذا كان الخطأ بسبب أن التوكن لم يعد صالحاً، قم بحذفه
    if (error.code === "messaging/registration-token-not-registered") {
      try {
        await db.collection("students").doc(studentId).update({
          fcmToken: FieldValue.delete(),
        });
        logger.warn(`تم حذف التوكن غير الصالح للطالب: ${studentId}`);
      } catch (deleteError) {
        logger.error(`فشل في حذف التوكن للطالب ${studentId}:`, deleteError);
      }
    }
    // لا نوقف التنفيذ، سنستمر لكتابة الإشعار في قاعدة البيانات
  }

  // 3. كتابة الإشعار في (subcollection) ليظهر في جرس الإشعارات
  // هذا هو الجزء الذي يتوقعه student_view.dart
  try {
    await db.collection("students").doc(studentId).collection("notifications").add({
      message: body, // نستخدم نص الإشعار كرسالة
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
      action: actionData.action, // "OPEN_STUDENT_VIEW"
    });
    logger.info(`تم تسجيل الإشعار في Firestore للطالب: ${studentId}`);
  } catch (dbError) {
    logger.error(`فشل في تسجيل الإشعار في Firestore للطالب ${studentId}:`, dbError);
  }
}

/**
 * الدالة الرئيسية: ترسل إشعار عند تحديث بيانات الطالب (سلوك أو درجات)
 */
exports.sendNotificationOnStudentUpdate = onDocumentUpdated("students/{studentId}", async (event) => {
  if (!event.data) {
    logger.warn("No data in event, exiting.");
    return;
  }

  const studentDataBefore = event.data.before.data();
  const studentDataAfter = event.data.after.data();
  const studentId = event.params.studentId;
  const fcmToken = studentDataAfter.fcmToken;

  // جلب خرائط أسماء الاختبارات
  const { testKeyToName, testKeyToSubject } = getTestMaps();

  // ----- 1. التحقق من تغييرات السلوك (Likes/Dislikes) -----
  const likesBefore = studentDataBefore.totalLikes ?? 0;
  const likesAfter = studentDataAfter.totalLikes ?? 0;
  const dislikesBefore = studentDataBefore.totalDislikes ?? 0;
  const dislikesAfter = studentDataAfter.totalDislikes ?? 0;

  let notificationTitle = "";
  let notificationBody = "";
  const actionData = {
    action: "OPEN_STUDENT_VIEW",
    studentId: studentId,
  };

  if (likesAfter > likesBefore) {
    notificationBody = "لقد حصلت على إعجاب جديد! رائع! 🎉";
    notificationTitle = "تهنئة من المعلم!";
    // إرسال إشعار السلوك فوراً
    await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
    // نخرج من الدالة بعد إرسال إشعار السلوك
    return;
  }

  if (dislikesAfter > dislikesBefore) {
    notificationBody = "تم تسجيل ملاحظة سلوك. يرجى المراجعة. ⚠️";
    notificationTitle = "ملاحظة سلوكية";
    // إرسال إشعار السلوك فوراً
    await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
    // نخرج من الدالة بعد إرسال إشعار السلوك
    return;
  }

  // ----- 2. التحقق من تغييرات الدرجات -----
  // (سيتم تنفيذه فقط إذا لم يكن هناك تغيير في السلوك)

  for (const testKey in testKeyToName) {
    const gradeBefore = studentDataBefore[testKey];
    const gradeAfter = studentDataAfter[testKey];

    // التحقق إذا كانت الدرجة قد تغيرت (أضيفت، عُدلت، أو حُذفت)
    if (gradeBefore !== gradeAfter) {
      const testName = testKeyToName[testKey] || "اختبار";
      const subjectName = testKeyToSubject[testKey] || "مادة";

      // الحالة 1: تم رصد درجة جديدة (كانت غير موجودة وأصبحت موجودة)
      if (gradeBefore === undefined && gradeAfter !== undefined) {
        notificationTitle = `تم رصد درجة: ${subjectName}`;
        if (gradeAfter === -1) {
          notificationBody = `تم تسجيلك "غائب" في: ${testName}.`;
        } else {
          notificationBody = `تم رصد درجتك (${gradeAfter}) في: ${testName}.`;
        }
        // إرسال إشعار الدرجة
        await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
        // نخرج بعد إرسال أول إشعار نجده (لمنع إرسال 10 إشعارات لو المعلم رصد 10 طلاب مرة واحدة)
        return;
      }
      
      // الحالة 2: تم تعديل درجة (كانت موجودة وتغيرت)
      if (gradeBefore !== undefined && gradeAfter !== undefined) {
        notificationTitle = `تم تعديل درجة: ${subjectName}`;
        if (gradeAfter === -1) {
          notificationBody = `تم تعديل حالتك إلى "غائب" في: ${testName}.`;
        } else {
          notificationBody = `تم تعديل درجتك في ${testName} إلى (${gradeAfter}).`;
        }
        await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
        return;
      }

      // الحالة 3: تم حذف درجة (كانت موجودة واختفت)
      if (gradeBefore !== undefined && gradeAfter === undefined) {
        notificationTitle = `تم حذف درجة: ${subjectName}`;
        notificationBody = `تم حذف درجتك التي كانت مسجلة في: ${testName}.`;
        await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
        return;
      }
    }
  }

  // إذا وصلنا هنا، فالتحديث لم يكن سلوكاً ولا درجة (مثل تحديث fcmToken)
  logger.info(`تحديث لا يتطلب إشعاراً للطالب ${studentId}.`);
});