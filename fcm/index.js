// C:\appweb1\fcm\index.js (النسخة المعدلة v4 - تدعم الصوت المخصص)

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

// --- (دوال مساعدة مثل getTestMaps تبقى كما هي) ---
function getTestMaps() {
    // ... (الكود الخاص بها كما في الملف الأصلي) ...
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
 */
async function sendNotification(fcmToken, studentId, title, body, actionData) {
  if (!fcmToken) {
    logger.info(`الطالب ${studentId} لا يملك FCM Token. تم تخطي الإشعار.`);
    return; // لا نرسل إذا لم يكن هناك توكن
  }

  // 1. بناء رسالة الإشعار (Payload)
  const payload = {
    // (أ) الإشعار القياسي (للتوافق مع التطبيقات الأصلية وغيرها)
    notification: {
      title: title,
      body: body,
      // يمكن تحديد صوت افتراضي هنا للتطبيقات الأصلية إذا أردت
      // sound: "default", // أو اسم ملف صوتي خاص بالتطبيق الأصلي
    },
    // (ب) بيانات إضافية (مفيدة للتطبيق عندما يكون مفتوحاً)
    data: actionData, // مثل { action: "OPEN_STUDENT_VIEW", studentId: "..." }

    // --- ✅✅✅ التعديل الأساسي: قسم webpush ---
    // هذا القسم مخصص لإشعارات الويب (PWA) ويتحكم بما يظهره المتصفح
    webpush: {
      notification: {
        title: title, // العنوان الذي سيظهر
        body: body,   // النص الرئيسي للإشعار
        // ✅ المسار إلى أيقونة الإشعار (يجب أن يكون في مجلد web/icons)
        icon: "/icons/Icon-192.png",
        // ✅ المسار إلى ملف الصوت (يجب أن يكون في مجلد web)
        sound: "/1.mp3",
        // خيارات إضافية ممكنة:
        // badge: "/icons/badge-72.png", // أيقونة صغيرة اختيارية
        // tag: `student-update-${studentId}`, // لتجميع الإشعارات
        // requireInteraction: true, // يجعل الإشعار يبقى حتى يتفاعل المستخدم (استخدم بحذر)
      },
      // يمكنك إضافة fcm_options هنا إذا أردت رابطاً مباشراً عند النقر
      // fcm_options: {
      //   link: "https://your-app-url.com/student_view" // مثال
      // }
    },
    // --- نهاية قسم webpush ---

    // يمكنك إضافة أقسام أخرى مثل apns (لـ iOS) أو android إذا لزم الأمر
  };

  // 2. إرسال الإشعار باستخدام sendToDevice
  try {
    const response = await messaging.sendToDevice(fcmToken, payload);
    logger.info(`تم إرسال الإشعار بنجاح إلى الطالب: ${studentId}`, response);

    // التحقق من وجود أخطاء في الاستجابة (مثل توكن غير صالح)
    response.results.forEach((result, index) => {
      const error = result.error;
      if (error) {
        logger.error(`فشل إرسال الإشعار إلى توكن [${index}]:`, error);
        // إذا كان الخطأ بسبب توكن غير مسجل، قم بحذفه من Firestore
        if (error.code === "messaging/registration-token-not-registered" ||
            error.code === "messaging/invalid-registration-token") {
          logger.warn(`التوكن ${fcmToken} غير صالح للطالب: ${studentId}. سيتم محاولة حذفه.`);
          // (يفضل التأكد أن fcmToken هو الـ token الفردي وليس مصفوفة هنا)
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
    // قد تحتاج لمعالجة أخطاء أخرى هنا
  }

  // 3. كتابة الإشعار في Firestore (لجرس الإشعارات داخل التطبيق)
  try {
    await db.collection("students").doc(studentId).collection("notifications").add({
      message: body, // النص الذي يظهر في الجرس
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
      // يمكنك إضافة بيانات أخرى هنا إذا احتجتها عند عرض الإشعار في التطبيق
      action: actionData.action, // مثل "OPEN_STUDENT_VIEW"
      relatedId: actionData.studentId, // أو أي ID ذو صلة
    });
    logger.info(`تم تسجيل الإشعار في Firestore للطالب: ${studentId}`);
  } catch (dbError) {
    logger.error(`فشل تسجيل الإشعار في Firestore للطالب ${studentId}:`, dbError);
  }
}

// 4. الدالة الرئيسية التي تستمع لتحديثات الطلاب
exports.sendNotificationOnStudentUpdate = onDocumentUpdated("students/{studentId}", async (event) => {
  if (!event.data) {
    logger.warn("No data in event, exiting.");
    return null; // يجب أن تعيد الدالة شيئاً أو Promise
  }

  const studentDataBefore = event.data.before.data();
  const studentDataAfter = event.data.after.data();
  const studentId = event.params.studentId;
  const fcmToken = studentDataAfter.fcmToken; // التوكن الخاص بالطالب

  // إذا لم يكن هناك توكن، لا تفعل شيئاً (تمت معالجته داخل sendNotification)
  // if (!fcmToken) {
  //   logger.info(`Student ${studentId} does not have an FCM token.`);
  //   return null;
  // }

  const { testKeyToName, testKeyToSubject } = getTestMaps();

  let notificationTitle = "";
  let notificationBody = "";
  // بيانات لفتح صفحة الطالب عند النقر (إذا كان التطبيق يدعم ذلك)
  const actionData = {
    action: "OPEN_STUDENT_VIEW", // اسم الإجراء
    studentId: studentId,        // معرف الطالب
  };
  let shouldSend = false; // متغير لتحديد ما إذا كان يجب إرسال إشعار

  // ----- التحقق من تغييرات السلوك -----
  const likesBefore = studentDataBefore.totalLikes ?? 0;
  const likesAfter = studentDataAfter.totalLikes ?? 0;
  const dislikesBefore = studentDataBefore.totalDislikes ?? 0;
  const dislikesAfter = studentDataAfter.totalDislikes ?? 0;

  if (likesAfter > likesBefore) {
    notificationTitle = "تهنئة من المعلم!";
    notificationBody = "لقد حصلت على إعجاب جديد! رائع! 🎉";
    shouldSend = true;
  } else if (dislikesAfter > dislikesBefore) {
    notificationTitle = "ملاحظة سلوكية";
    notificationBody = "تم تسجيل ملاحظة سلوك. يرجى المراجعة. ⚠️";
    shouldSend = true;
  }

  // إذا كان هناك تغيير في السلوك، أرسل الإشعار فوراً واخرج
  if (shouldSend) {
    await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
    return null; // انتهت المهمة
  }

  // ----- التحقق من تغييرات الدرجات (فقط إذا لم يتغير السلوك) -----
  for (const testKey in testKeyToName) {
    const gradeBefore = studentDataBefore[testKey];
    const gradeAfter = studentDataAfter[testKey];

    // تحقق مما إذا كانت الدرجة تغيرت (أُضيفت، عُدلت، حُذفت) ولم تكن مجرد undefined -> undefined
    if (gradeBefore !== gradeAfter && (gradeBefore !== undefined || gradeAfter !== undefined)) {
      const testName = testKeyToName[testKey] || "اختبار";
      const subjectName = testKeyToSubject[testKey] || "مادة";
      shouldSend = true; // وجدنا تغييراً في درجة

      if (gradeBefore === undefined && gradeAfter !== undefined) { // رصد جديد
        notificationTitle = `تم رصد درجة: ${subjectName}`;
        notificationBody = (gradeAfter === -1) ?
          `تم تسجيلك "غائب" في: ${testName}.` :
          `تم رصد درجتك (${gradeAfter}) في: ${testName}.`;
      } else if (gradeBefore !== undefined && gradeAfter !== undefined) { // تعديل درجة
        notificationTitle = `تم تعديل درجة: ${subjectName}`;
        notificationBody = (gradeAfter === -1) ?
          `تم تعديل حالتك إلى "غائب" في: ${testName}.` :
          `تم تعديل درجتك في ${testName} إلى (${gradeAfter}).`;
      } else if (gradeBefore !== undefined && gradeAfter === undefined) { // حذف درجة
        notificationTitle = `تم حذف درجة: ${subjectName}`;
        notificationBody = `تم حذف درجتك التي كانت مسجلة في: ${testName}.`;
      } else {
        shouldSend = false; // حالة غير متوقعة، لا ترسل
      }

      // إذا وجدنا تغيير يستدعي الإرسال، أرسل واخرج من الحلقة والدالة
      if (shouldSend) {
        await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
        return null; // يكفي إشعار واحد لكل تحديث
      }
    }
  }

  // إذا وصلنا هنا، لا يوجد تغيير يستدعي إشعاراً
  if (!shouldSend) {
    logger.info(`تحديث لا يتطلب إشعاراً للطالب ${studentId}.`);
  }
  return null; // يجب أن تعيد الدالة شيئاً
});