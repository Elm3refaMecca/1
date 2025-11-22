// C:\appweb1\fcm\index.js (النسخة النهائية المدمجة والمصححة للصوت)

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// --- (دالة الخرائط للأسماء - Helper Function) ---
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
 * دالة مساعدة موحدة لإرسال الإشعار وكتابته في قاعدة البيانات (للإشعارات الفردية)
 */
async function sendNotification(fcmToken, studentId, title, body, actionData) {
  if (!fcmToken) {
    logger.info(`الطالب ${studentId} لا يملك FCM Token. تم تخطي الإشعار.`);
    return;
  }

  const prefixedTitle = `المعرفة: ${title}`;

  // ✅ تم تصحيح هيكلية الـ Payload لضمان عمل الصوت وعدم حدوث أخطاء
  const payload = {
    notification: {
      title: prefixedTitle,
      body: body,
      // ❌ لا تضع sound هنا، يسبب خطأ Invalid JSON
    },
    data: actionData, // بيانات إضافية للتوجيه داخل التطبيق
    
    // إعدادات الويب (مهمة لتطبيقك)
    webpush: {
      headers: {
        Urgency: "high"
      },
      notification: {
        title: prefixedTitle,
        body: body,
        icon: "/icons/Icon-192.png",
        badge: "/2.png",
        requireInteraction: true, // يبقى الإشعار ظاهراً حتى يتفاعل المستخدم
        /* ملاحظة: المتصفحات قد تتجاهل خاصية sound هنا، 
           لكننا نضعها كاحتياط للمتصفحات التي تدعمها */
        data: {
            sound: "1.mp3" 
        }
      },
    },
    
    // إعدادات أندرويد (في حال تم تثبيت التطبيق كـ PWA أو Native)
    android: {
      priority: "high",
      notification: {
        sound: "1.mp3", 
        channelId: "high_importance_channel", // قناة الإشعارات الهامة
        icon: "stock_ticker_update"
      },
    },
    
    // إعدادات Apple
    apns: {
      payload: {
        aps: {
          sound: "1.mp3",
          contentAvailable: true,
        },
      },
    },
  };

  // محاولة الإرسال باستخدام send بدلاً من sendToDevice (أحدث)
  try {
    // ملاحظة: sendToDevice قديمة، لكن إذا كانت تعمل معك اتركها. 
    // الكود أدناه يستخدم sendToDevice بناء على طلبك للكود السابق
    const response = await messaging.sendToDevice(fcmToken, payload);
    logger.info(`تم إرسال الإشعار بنجاح إلى الطالب: ${studentId}`, response);

    response.results.forEach((result, index) => {
      const error = result.error;
      if (error) {
        logger.error(`فشل إرسال الإشعار:`, error);
        if (error.code === "messaging/registration-token-not-registered" ||
            error.code === "messaging/invalid-registration-token") {
          logger.warn(`التوكن ${fcmToken} غير صالح. سيتم حذفه.`);
          db.collection("students").doc(studentId).update({
            fcmToken: FieldValue.delete(),
          }).catch(e => logger.error("فشل حذف التوكن", e));
        }
      }
    });

  } catch (error) {
    logger.error(`خطأ عام عند محاولة إرسال الإشعار إلى ${studentId}:`, error);
  }

  // تسجيل الإشعار في قاعدة البيانات ليظهر داخل التطبيق
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
 * دالة مراقبة تحديثات الطالب (درجات وسلوك)
 */
exports.sendNotificationOnStudentUpdate = onDocumentUpdated("students/{studentId}", async (event) => {
  if (!event.data) return null;

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

  // 1. السلوك (نبل / شغب)
  const likesBefore = studentDataBefore.totalLikes ?? 0;
  const likesAfter = studentDataAfter.totalLikes ?? 0;
  const dislikesBefore = studentDataBefore.totalDislikes ?? 0;
  const dislikesAfter = studentDataAfter.totalDislikes ?? 0;

  if (likesAfter > likesBefore) {
    notificationTitle = "تهنئة من المعلم! 🌟";
    notificationBody = `أهلاً ${studentDataAfter.name || 'يا بطل'}، حصلت على إعجاب جديد لسلوكك النبيل!`;
    shouldSend = true;
  } else if (dislikesAfter > dislikesBefore) {
    notificationTitle = "تنبيه سلوكي ⚠️";
    notificationBody = `أهلاً ${studentDataAfter.name || 'بالطالب'}، تم تسجيل ملاحظة عليك. يرجى الانتباه.`;
    shouldSend = true;
  }

  if (shouldSend) {
    await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
    return null;
  }

  // 2. الدرجات
  for (const testKey in testKeyToName) {
    const gradeBefore = studentDataBefore[testKey];
    const gradeAfter = studentDataAfter[testKey];

    if (gradeBefore !== gradeAfter && (gradeBefore !== undefined || gradeAfter !== undefined)) {
      const testName = testKeyToName[testKey] || "اختبار";
      const subjectName = testKeyToSubject[testKey] || "مادة";
      shouldSend = true;
      const studentName = studentDataAfter.name || 'الطالب';

      if (gradeBefore === undefined && gradeAfter !== undefined) {
        notificationTitle = `رصد درجة: ${subjectName}`;
        notificationBody = (gradeAfter === -1) ?
          `تم تسجيل الغياب في ${testName}.` :
          `تم رصد درجة ${gradeAfter} في ${testName}.`;
      } else if (gradeBefore !== undefined && gradeAfter !== undefined) {
        notificationTitle = `تعديل درجة: ${subjectName}`;
        notificationBody = `تم تعديل درجة ${testName} إلى ${gradeAfter === -1 ? 'غائب' : gradeAfter}.`;
      } else if (gradeBefore !== undefined && gradeAfter === undefined) {
        notificationTitle = `حذف درجة: ${subjectName}`;
        notificationBody = `تم حذف الدرجة المسجلة في ${testName}.`;
      } else {
        shouldSend = false;
      }

      if (shouldSend) {
        await sendNotification(fcmToken, studentId, notificationTitle, notificationBody, actionData);
        return null;
      }
    }
  }

  return null;
});


/**
 * 📣 دالة الإشعار العام (Broadcast) المعدلة والمصححة
 * يتم تفعيلها عند إنشاء مستند في "broadcast_notifications"
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

    const topic = "public_announcements";

    // ✅ هيكلية Payload الصحيحة لتجنب خطأ Invalid JSON وتشغيل الصوت
    const payload = {
      notification: {
        title: title,
        body: body,
        // ❌ لا يوجد sound هنا
      },
      // بيانات إضافية
      data: {
        type: "broadcast",
        sound: "1.mp3" // نرسل اسم الملف كبيانات ليتمكن التطبيق من التعامل معه
      },
      webpush: {
        headers: {
          Urgency: "high"
        },
        notification: {
          icon: "/icons/Icon-192.png",
          badge: "/2.png",
          requireInteraction: true, // يجعل الإشعار ثابتاً حتى يغلقه المستخدم
          // محاولة لتشغيل الصوت في المتصفحات التي تدعمه عبر الـ Payload
          data: {
             url: "https://elma3refa.site", // رابط عند الضغط
             sound: "1.mp3"
          }
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "1.mp3", // الصوت للآيفون
            contentAvailable: true,
          },
        },
      },
      android: {
        priority: "high",
        notification: {
          sound: "1.mp3", // الصوت للأندرويد
          channelId: "high_importance_channel", // القناة ذات الأولوية العالية
          defaultSound: false
        },
      },
      topic: topic,
    };

    try {
      // استخدام messaging.send() لأنها تدعم الـ Topics بشكل أفضل في الإصدارات الحديثة
      const response = await messaging.send(payload);
      logger.info(`Broadcast: ✅ تم إرسال الإشعار العام بنجاح إلى ${topic}`, response);
    } catch (error) {
      logger.error(`Broadcast: ❌ فشل إرسال الإشعار العام إلى ${topic}`, error);
    }
  }
);