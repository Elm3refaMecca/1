// main.dart (MODIFIED FOR ERROR HANDLING)

import 'dart:async';
import 'dart:js' as js; // لاستدعاء دوال JavaScript
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math; // استيراد مكتبة الرياضيات لتحديد الحجم الأقصى

// --- ✅✅✅ START OF MODIFICATION (FCM Import) ✅✅✅ ---
// يجب إضافة هذه الحزمة في pubspec.yaml لكي يعمل الكود
import 'package:firebase_messaging/firebase_messaging.dart';
// --- ✅✅✅ END OF MODIFICATION (FCM Import) ✅✅✅ ---

// --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
// تم إضافة المكتبات المطلوبة لتشغيل ميزة إعادة التحميل على الويب
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:universal_html/html.dart' as html;
// --- ✅✅✅  إضافة المكتبة المطلوبة للتكريم  ✅✅✅ ---
import 'package:animated_text_kit/animated_text_kit.dart';
// --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---

// --- ✅ MODIFIED: Using the new package ---
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:almarefamecca/add.dart';
import 'package:almarefamecca/student_view.dart';
import 'package:almarefamecca/firebase_options.dart';


Future<void> _launchUrlHelper(String url) async {
  final Uri uri = Uri.parse(url);
  // --- ✅ MODIFIED: Ensured it works well across platforms ---
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint("Could not launch $url");
    // Consider showing a SnackBar to the user here
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن فتح الرابط: $url')));
  }
}

// --- ✅✅✅ START OF MODIFICATION (FCM Background Handler) ✅✅✅ ---
// هذه الدالة ضرورية لمعالجة الإشعارات عندما يكون التطبيق يعمل في الخلفية أو مغلق
// يجب أن تكون دالة علوية (Top-Level Function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // عند العمل في الخلفية، يجب تهيئة Firebase مرة أخرى
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
  // (ملاحظة: هذا المعالج خاص بالجوالات بشكل أساسي)
  // (على الويب، ملف firebase-messaging-sw.js هو الذي يتولى إشعارات الخلفية)
  // الحمولة الحالية (notification) كافية لإظهار الإشعار في الخلفية على الويب.
}
// --- ✅✅✅ END OF MODIFICATION (FCM Background Handler setup) ✅✅✅ ---


// --- ✅✅✅ START OF MODIFICATION (دوال تشغيل الصوت والإشعار) ✅✅✅ ---
// تم نقل هذه الدوال هنا من student_view.dart لتكون متاحة بشكل فوري
void _playNotificationSound() {
  if (kIsWeb) {
    try {
      // إنشاء عنصر صوتي بشكل برمجي
      final html.AudioElement audio = html.AudioElement('1.mp3'); // يفترض وجود 1.mp3 في مجلد web
      audio.play().catchError((e) {
        // Catch potential errors from autoplay restrictions
        debugPrint("Error playing notification sound (possibly autoplay policy): $e");
      });
    } catch (e) {
      debugPrint("Error creating or playing notification sound: $e");
    }
  }
}

/// دالة عرض الإشعار في المتصفح (مثل إشعارات جوجل كروم)
void _showBrowserNotification(String title, String body) {
  if (kIsWeb && html.Notification.supported) {
    // نتأكد أن لدينا الإذن أولاً
    if (html.Notification.permission == 'granted') {
      try {
        // إنشاء الإشعار
        html.Notification(title,
            body: body,
            icon: 'icons/Icon-192.png'); // تأكد من وجود هذه الأيقونة في web/icons
      } catch (e) {
        debugPrint("Error showing browser notification: $e");
      }
    } else {
      debugPrint("Browser notification permission not granted.");
      // Consider prompting the user again or explaining why notifications aren't showing.
    }
  }
}
// --- ✅✅✅ END OF MODIFICATION (دوال تشغيل الصوت والإشعار) ✅✅✅ ---


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // --- ✅✅✅ START OF MODIFICATION (FCM Background Handler setup) ✅✅✅ ---
    // تسجيل الدالة التي تتعامل مع إشعارات الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // --- ✅✅✅ END OF MODIFICATION (FCM Background Handler setup) ✅✅✅ ---
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // Consider showing an error message to the user if Firebase fails to initialize
  }
  runApp(const TeacherLoginApp());
}

class TeacherLoginApp extends StatelessWidget {
  const TeacherLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1976D2);
    const Color accentColor = Color(0xFF00ACC1);
    const Color backgroundColor = Color(0xFFF5F5F5);

    return MaterialApp(
      title: 'بوابة مدرسة المعرفة الاهلية',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [ // Added const
        GlobalMaterialLocalizations.delegate, // Needed for text direction
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
      ],
      locale: const Locale('ar', ''),
      theme: ThemeData(
        fontFamily: 'Cairo',
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          secondary: accentColor,
          background: backgroundColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundColor,
        cardTheme: CardThemeData(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor, width: 2),
              foregroundColor: primaryColor,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            )),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.white,
          // --- ✅ إضافة بسيطة لتحسين العرض ---
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          // --- نهاية الإضافة ---
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall:
          TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF212121)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF424242)),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/add': (context) => const AddPage(),
        '/student_view': (context) => const StudentViewPage(),
        // --- ✅ إضافة: تعريف مسار لصفحة الدخول لتجنب مشاكل الانتقال ---
        '/login': (context) {
          // يمكنك تمرير نوع الحساب هنا إذا لزم الأمر، لكن قد يكون أبسط
          // إذا كانت صفحة الدخول نفسها تحدد النوع أو تستخدم قيمة افتراضية.
          // في حالتك الحالية، `WelcomePage` هو الذي يوجه إلى `LoginPage` مع النوع.
          // لذا، هذا المسار قد لا يكون ضرورياً إلا إذا كنت تنتقل إليه من مكان آخر.
          // سنبقي `WelcomePage` هي نقطة الدخول الرئيسية للضيوف.
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          final accountType = args?['accountType'] ?? 'student'; // Default or from args
          return LoginPage(accountType: accountType);
        }
        // --- نهاية الإضافة ---
      },
    );
  }
}

// --- ✅✅✅ START OF MODIFICATION (AuthWrapper to StatefulWidget + FCM Logic) ✅✅✅ ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _setupFCM(); // تهيئة إشعارات FCM عند بدء التشغيل
  }

  Future<void> _setupFCM() async {
    // --- ✅ تأكد من تشغيل هذا فقط على الويب أو الجوالات ---
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;

        // 1. طلب الأذونات (مهم لجميع المنصات ولإشعارات شريط الحالة)
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          announcement: true, // قد تكون مفيدة
          badge: true,
          carPlay: false,
          criticalAlert: true, // Consider if really needed
          provisional: false,
          sound: true,
        );

        debugPrint('User granted notification permission: ${settings.authorizationStatus}');

        // --- ⭐️⭐️⭐️  هذا هو التعديل المطلوب  ⭐️⭐️⭐️ ---
        // هذا السطر يجعل "كل" من يفتح التطبيق (ضيف أو طالب أو معلم)
        // مشتركاً في قناة الإشعارات العامة
        try {
          await messaging.subscribeToTopic('public_announcements');
          debugPrint("Subscribed to public_announcements topic");
        } catch (e) {
          debugPrint("Failed to subscribe to topic: $e");
        }
        // --- ⭐️⭐️⭐️  نهاية التعديل المطلوب  ⭐️⭐️⭐️ ---


        // 2. الحصول على رمز الجهاز (FCM Token) لـ Firebase
        // --- ✅ إضافة: تحقق من دعم المنصة قبل طلب التوكن ---
        String? token;
        try {
          token = await messaging.getToken();
          debugPrint("FCM Token: $token");
        } catch (e) {
          debugPrint("Failed to get FCM token: $e");
        }
        // --- نهاية الإضافة ---

        // (ملاحظة: الكود الخاص بك يقوم بهذا في student_view.dart وهذا جيد للطالب)
        // (تمت إضافة منطق حفظ التوكن للطالب في دالة _getUserRole أدناه أيضاً)

        // 3. معالجة الإشعارات أثناء عمل التطبيق في الواجهة الأمامية (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            final title = message.notification!.title ?? 'إشعار جديد';
            final body = message.notification!.body ?? 'لديك إشعار جديد';
            debugPrint('Message also contained a notification: $title / $body');

            // --- ✅✅✅  هذا هو التعديل المطلوب (تشغيل الصوت والإشعار فورا)  ✅✅✅ ---
            // استدعاء الدوال التي تم نقلها للأعلى
            _playNotificationSound();
            _showBrowserNotification(title, body);
            // --- ✅✅✅  نهاية التعديل  ✅✅✅ ---
          }
          // (ملاحظة: الـ StreamBuilder في student_view.dart سيتولى تحديث الجرس)
        });

        // 4. معالجة الإشعارات عند النقر عليها
        // عند النقر على إشعار والتطبيق مغلق تماماً (Terminated)
        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint("App launched from terminated state by notification: ${initialMessage.data}");
          // هنا يمكن توجيه المستخدم لصفحة معينة داخل التطبيق بناءً على بيانات الإشعار
          // مثال: _handleNotificationNavigation(initialMessage.data);
        }

        // عند النقر على إشعار والتطبيق يعمل في الخلفية (Background)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('A new onMessageOpenedApp event was published!');
          debugPrint("App resumed from background by notification: ${message.data}");
          // هنا أيضاً يمكن توجيه المستخدم
          // مثال: _handleNotificationNavigation(message.data);
        });
      } catch(e) {
        debugPrint("Error setting up FCM: $e");
      }
    } else {
      debugPrint("FCM setup skipped for this platform.");
    }
  }
  // --- ✅ إضافة: دالة مثال لتوجيه المستخدم عند النقر على إشعار ---
  // void _handleNotificationNavigation(Map<String, dynamic> data) {
  //    final action = data['action'];
  //    final studentId = data['studentId']; // Assuming you send studentId in data payload
  //    if (action == 'OPEN_STUDENT_VIEW' && studentId != null) {
  //       // Check if current user is this student or maybe a teacher allowed to view?
  //       // Navigate to StudentViewPage for the specified studentId
  //       // Make sure your routing can handle this, maybe pass studentId as argument
  //       // Example (might need adjustments based on your Navigator setup):
  //       // Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentViewPage(studentId: studentId)));
  //    }
  // }
  // --- نهاية الإضافة ---


  Future<String> _getUserRole(User user) async {
    try {
      // (ملاحظة: هذا الكود يفترض أن المعلم والطالب لهما UID مختلف)
      // (إذا كان المعلم هو نفسه الطالب، ستحتاج لمنطق مختلف)

      // 1. تحقق إذا كان UID موجود في 'users' (المعلمين)
      final teacherDoc =
      await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        debugPrint("User role determined: teacher");
        return 'teacher';
      }

      // 2. إذا لم يكن معلماً، تحقق إذا كان UID موجود في 'students' (الطلاب)
      final studentDocRef = _firestore.collection('students').doc(user.uid); // Reference
      final studentDoc = await studentDocRef.get();
      if (studentDoc.exists) {
        debugPrint("User role determined: student");

        // --- ⭐️ إضافة مقترحة لحفظ التوكن (أكثر موثوقية هنا) ⭐️ ---
        // بما أننا تأكدنا أنه طالب، نحاول حفظ/تحديث التوكن الخاص به
        // --- ✅ إضافة: تحقق من دعم المنصة قبل طلب التوكن ---
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          try {
            String? token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              // تحديث التوكن فقط إذا كان مختلفاً أو غير موجود
              final currentToken = (studentDoc.data() as Map<String, dynamic>?)?['fcmToken'];
              if (currentToken != token) {
                await studentDocRef.set({'fcmToken': token}, SetOptions(merge: true));
                debugPrint("FCM Token saved/updated for student.");
              }
            }
          } catch (e) {
            debugPrint("Error getting/saving FCM token for student in AuthWrapper: $e");
          }
        }
        // --- نهاية الإضافة المقترحة ---

        return 'student';
      }

      // 3. إذا لم يكن أياً منهما، فهو غير مصرح له
      debugPrint("User role determined: unauthorized (not found in users or students)");
      await FirebaseAuth.instance.signOut();
      return 'unauthorized';

    } catch (e, s) { // --- ✅ إضافة: طباعة الخطأ والتتبع ---
      debugPrint("Error checking user role: $e\nStacktrace: $s");
      // حاول تسجيل الخروج لضمان عدم الدخول بحالة خطأ
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        debugPrint("Error signing out after role check failure: $signOutError");
      }
      return 'unauthorized'; // Return unauthorized on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // --- ✅ حالة الانتظار ---
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint("AuthWrapper: Waiting for auth state...");
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // --- ✅ حالة وجود خطأ في الـ Stream ---
        if (authSnapshot.hasError) {
          debugPrint("AuthWrapper: Error in authStateChanges stream: ${authSnapshot.error}");
          // يمكنك عرض رسالة خطأ أو العودة لصفحة الدخول
          return const Scaffold(body: Center(child: Text("حدث خطأ في المصادقة.")));
        }

        // --- ✅ حالة وجود بيانات (مستخدم سجل دخوله) ---
        if (authSnapshot.hasData && authSnapshot.data != null) {
          debugPrint("AuthWrapper: User is logged in (UID: ${authSnapshot.data!.uid}). Checking role...");
          // المستخدم قام بتسجيل الدخول، تحقق من نوعه
          return FutureBuilder<String>(
            future: _getUserRole(authSnapshot.data!),
            builder: (context, roleSnapshot) {
              // --- ✅ حالة انتظار تحديد الدور ---
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                debugPrint("AuthWrapper: Waiting for user role...");
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              // --- ✅✅✅ إضافة: التعامل مع الأخطاء من _getUserRole ---
              if (roleSnapshot.hasError) {
                debugPrint("AuthWrapper: Error in FutureBuilder for getUserRole: ${roleSnapshot.error}");
                // اعرض صفحة الدخول مرة أخرى عند حدوث خطأ في تحديد الدور
                return const WelcomePage(); // أو صفحة خطأ مخصصة
              }
              // --- ✅✅✅ نهاية الإضافة ---

              debugPrint("AuthWrapper: Role snapshot completed. Data: ${roleSnapshot.data}");
              switch (roleSnapshot.data) {
                case 'teacher':
                  return const AddPage(); // صفحة المعلمين
                case 'student':
                  return const StudentViewPage(); // صفحة الطلاب
                case 'unauthorized': // تمت معالجته بواسطة _getUserRole
                  return const WelcomePage();
                default:
                // Handle null or unexpected data case
                  debugPrint("AuthWrapper: Unexpected role data: ${roleSnapshot.data}. Defaulting to WelcomePage.");
                  return const WelcomePage();
              }
            },
          );
        }

        // --- ✅ حالة عدم وجود بيانات (لا يوجد مستخدم مسجل دخول) ---
        debugPrint("AuthWrapper: No user logged in. Showing WelcomePage.");
        return const WelcomePage(); // اعرض صفحة الترحيب (الضيوف)
      },
    );
  }
}
// --- ✅✅✅ END OF MODIFICATION (AuthWrapper to StatefulWidget + FCM Logic) ✅✅✅ ---

// Data models for the leaderboards
class TopStudent {
  final String name;
  final int likes;
  TopStudent({required this.name, required this.likes});
}

class TopClass {
  final String name;
  final int likes;
  TopClass({required this.name, required this.likes});
}

// Converted to StatefulWidget to fetch data
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isInstallable = false;
  // --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
  bool _updateAvailable = false;
  // --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---

  // New state variables for leaderboards
  bool _isLoadingLeaderboards = true;
  List<TopStudent> _topStudents = [];
  List<TopClass> _topClasses = [];

  @override
  void initState() {
    super.initState();
    _setupPwaListeners();
    _fetchLeaderboards();
  }

  // --- ✅ فصل إعداد مستمعي PWA ---
  void _setupPwaListeners() {
    if (kIsWeb) {
      // PWA install listener
      js.context['pwa-installable-listener'] = (event) {
        try {
          final isReady = js.context['isInstallable'] ?? false; // Handle potential null
          if (mounted && _isInstallable != isReady) {
            setState(() {
              _isInstallable = isReady;
            });
          }
        } catch (e) {
          debugPrint("Error in pwa-installable-listener: $e");
        }
      };
      try {
        js.context.callMethod('addEventListener', ['pwa-installable', js.context['pwa-installable-listener']]);
        if (js.context.hasProperty('isInstallable')) {
          _isInstallable = js.context['isInstallable'] ?? false;
        }
      } catch(e) {
        debugPrint("Error setting up install listener: $e");
      }

      // --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
      // PWA Update Listener
      js.context['pwa-update-listener'] = (event) {
        try {
          final isReady = js.context['isUpdateAvailable'] ?? false;
          if (mounted && _updateAvailable != isReady) {
            setState(() {
              _updateAvailable = isReady;
            });
          }
        } catch (e) {
          debugPrint("Error in pwa-update-listener: $e");
        }
      };
      try {
        js.context.callMethod('addEventListener', ['pwa-update-available', js.context['pwa-update-listener']]);
        if (js.context.hasProperty('isUpdateAvailable')) {
          _updateAvailable = js.context['isUpdateAvailable'] ?? false;
        }
      } catch (e) {
        debugPrint("Error setting up update listener: $e");
      }
      // --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---
    }
  }

  @override
  void dispose() {
    // --- ✅ تنظيف المستمعين عند الخروج ---
    if (kIsWeb) {
      try {
        if (js.context.hasProperty('pwa-installable-listener')) {
          js.context.callMethod('removeEventListener', ['pwa-installable', js.context['pwa-installable-listener']]);
        }
        if (js.context.hasProperty('pwa-update-listener')) {
          js.context.callMethod('removeEventListener', ['pwa-update-available', js.context['pwa-update-listener']]);
        }
      } catch (e) {
        debugPrint("Error removing PWA listeners: $e");
      }
    }
    super.dispose();
  }
  // --- نهاية الفصل والتنظيف ---


  Future<void> _fetchLeaderboards() async {
    if (!mounted) return; // Ensure widget is still mounted
    setState(() => _isLoadingLeaderboards = true);
    try {
      // Fetch top 3 students
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .orderBy('totalLikes', descending: true)
          .limit(3)
          .get();

      final List<TopStudent> students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return TopStudent(
          name: data['name'] ?? 'طالب',
          likes: data['totalLikes'] ?? 0,
        );
      }).toList();

      // Fetch all students to calculate class scores
      final allStudentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('totalLikes', isGreaterThan: 0) // Optimization: only fetch students with likes
          .get();

      final Map<String, int> classLikes = {};
      for (var doc in allStudentsSnapshot.docs) {
        final data = doc.data();
        // --- ✅ إضافة: التحقق من وجود المفاتيح قبل استخدامها ---
        final String? grade = data['grades'];
        final String? className = data['classes'];
        final int likes = data['totalLikes'] ?? 0;

        if (grade != null && className != null) {
          final String classKey = '$grade / $className';
          classLikes.update(classKey, (value) => value + likes, ifAbsent: () => likes);
        }
        // --- نهاية الإضافة ---
      }

      final List<TopClass> classes = classLikes.entries.map((entry) {
        return TopClass(name: entry.key, likes: entry.value);
      }).toList();

      classes.sort((a, b) => b.likes.compareTo(a.likes));

      if (mounted) {
        setState(() {
          _topStudents = students;
          _topClasses = classes.take(5).toList(); // Take top 5 classes
          _isLoadingLeaderboards = false;
        });
      }

    } catch (e, s) { // --- ✅ إضافة: طباعة الخطأ والتتبع ---
      debugPrint("Error fetching leaderboards: $e\nStacktrace: $s");
      if(mounted) {
        setState(() {
          _isLoadingLeaderboards = false;
        });
        // Optionally show a message to the user
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء تحميل لوحة الشرف.')));
      }
    }
  }

  void _showInstallPrompt() {
    if (kIsWeb) {
      try {
        js.context.callMethod('showInstallPrompt');
      } catch (e) {
        debugPrint("Error calling showInstallPrompt: $e");
      }
    }
  }

  // --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
  void _triggerUpdate() {
    if (kIsWeb) {
      try {
        js.context.callMethod('triggerPwaUpdate');
      } catch (e) {
        debugPrint("Error calling triggerPwaUpdate: $e");
      }
    }
  }
  // --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.brown.shade600;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // --- ✅ استخدام Center و SingleChildScrollView لتبسيط التوسيط ---
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24.0), // Padding علوي وسفلي
                child: ConstrainedBox( // لتحديد أقصى عرض للمحتوى
                  constraints: const BoxConstraints(maxWidth: 600), // عرض مناسب
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي ضمن المساحة المتاحة
                    crossAxisAlignment: CrossAxisAlignment.center, // توسيط أفقي للمحتوى
                    children: [
                      // Login Section Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLoginCard(),
                      ),
                      const SizedBox(height: 24), // فاصل

                      // Leaderboards Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildTopStudentsCard(),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildTopClassesCard(),
                      ),
                      const SizedBox(height: 32), // فاصل قبل الفوتر

                      // Footer Section
                      _buildFooter(),
                      const SizedBox(height: 70), // مسافة إضافية أسفل الفوتر لتجنب تداخل الزر العائم
                    ],
                  ),
                ),
              ),
            );
            // --- نهاية التبسيط ---
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      // --- ✅✅✅  بداية التعديل (إزالة التكريم الأرجواني)  ✅✅✅ ---
      // تم إرجاع الزر العائم الأصلي الخاص بجهات الاتصال
      floatingActionButton: SpeedDial(
        heroTag: 'main-fab', // Tag أصلي
        icon: Icons.support_agent, // Main icon
        activeIcon: Icons.close,    // Icon when the menu is open
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        buttonSize: const Size(60.0, 60.0),
        childrenButtonSize: const Size(60.0, 60.0),
        spaceBetweenChildren: 8.0,
        // The list of contacts
        children: [
          SpeedDialChild(
            child: const Icon(Icons.code), // Special icon for the programmer
            label: '</> مصطفي سعيد !! ', // Special label for the programmer
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            onTap: () => _launchUrlHelper('https://wa.me/966569064173'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.school),
            label: 'مدير المدرسة',
            onTap: () => _launchUrlHelper('https://wa.me/966539547972'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.supervisor_account),
            label: 'وكيل الشئون التعليمية',
            onTap: () => _launchUrlHelper('https://wa.me/966502361091'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_pin),
            label: 'وكيل المدرسة',
            onTap: () => _launchUrlHelper('https://wa.me/966501468550'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.support),
            label: 'موجه الطلاب: أ/ عبدالرحمن عثمان',
            onTap: () => _launchUrlHelper('https://wa.me/966500971015'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.support),
            label: 'موجه الطلاب: أ/ يحيي',
            onTap: () => _launchUrlHelper('https://wa.me/966502649649'),
          ),
        ],
      ),
      // --- ✅✅✅  نهاية التعديل  ✅✅✅ ---
    );
  }

  Widget _buildTopStudentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
                const SizedBox(width: 8),
                Text("الطلاب المتميزون", style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const Divider(height: 24),
            if (_isLoadingLeaderboards)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_topStudents.isEmpty)
              const Text("لا يوجد طلاب متميزون حالياً")
            else
              Column(
                children: _topStudents.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TopStudent student = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(idx + 1).withOpacity(0.2),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getRankColor(idx + 1)),
                      ),
                    ),
                    title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(student.likes.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.thumb_up, color: Colors.blue, size: 18),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClassesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, color: Colors.teal.shade600, size: 28),
                const SizedBox(width: 8),
                Text("الفصول الأكثر انضباطاً", style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const Divider(height: 24),
            if (_isLoadingLeaderboards)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_topClasses.isEmpty)
              const Text("لا توجد بيانات لعرضها حالياً")
            else
              Column(
                children: _topClasses.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TopClass topClass = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                      ),
                    ),
                    title: Text(topClass.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(topClass.likes.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.thumb_up, color: Colors.blue, size: 18),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // --- تم إزالة هذه الدوال لأن التخطيط تغير ---
  // Widget _buildWideLayout() { ... }
  // Widget _buildMobileLayout() { ... }
  // --- نهاية الإزالة ---

  Widget _buildLoginCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    // --- ✅ تعديل: حجم اللوجو ليكون أكثر استجابة ---
    final logoSize = math.min(screenWidth * 0.4, 180.0).clamp(100.0, 180.0); // حجم أدنى وأقصى

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ليأخذ الكارت حجم المحتوى
          children: <Widget>[
            if (kIsWeb && _updateAvailable) // --- ✅ تأكد أنه ويب قبل عرض زر التحديث ---
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.system_update),
                    label: const Text('تحديث جديد متوفر! اضغط للتحديث'),
                    onPressed: _triggerUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            // --- ✅✅✅ START OF MODIFICATION #1 (Welcome Page) ✅✅✅ ---
            // --- ✅ إضافة: تحقق من وجود الملف قبل عرضه لتجنب الأخطاء ---
            // تأكد أن ملف 'assets/m1.png' موجود ومُعرف في pubspec.yaml
            Image.asset('assets/m1.png', height: logoSize, width: logoSize, errorBuilder: (context, error, stackTrace) {
              // في حالة عدم وجود الصورة، اعرض أيقونة بديلة
              return Icon(Icons.school, size: logoSize, color: Theme.of(context).primaryColor.withOpacity(0.5));
            }),
            // --- ✅✅✅ END OF MODIFICATION #1 (Welcome Page) ✅✅✅ ---

            // --- ✅✅✅ بداية التكريم (تحت اللوجو) ✅✅✅ ---
            const SizedBox(height: 16), // فاصل
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.transparent, // خلفية شفافة
                border: Border.all(
                  color: Theme.of(context).primaryColor, // حواف زرقاء
                  width: 1.5, // رفيعه
                ),
                borderRadius: BorderRadius.circular(12.0), // شكل جيد
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'مبرمج المنصة: أ/ مصطفي سعيد',
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor, // نص أزرق
                      fontFamily: 'Cairo',
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                  TypewriterAnimatedText(
                    'معلم الرقمية بمدارس المعرفة',
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontFamily: 'Cairo',
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                repeatForever: true,
                pause: const Duration(milliseconds: 2000), // مدة التوقف بعد كل نص
              ),
            ),
            // --- ✅✅✅ نهاية التكريم (تحت اللوجو) ✅✅✅ ---

            const SizedBox(height: 24),
            Text(
              'بوابة مدرسة المعرفة الاهلية',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('دخول المعلمين'),
                onPressed: () {
                  // --- ✅ تعديل: استخدام push بدلًا من MaterialPageRoute لتسهيل الرجوع ---
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginPage(accountType: 'teacher'),
                  ));
                  //Navigator.pushNamed(context, '/login', arguments: {'accountType': 'teacher'});
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.child_care),
                label: const Text('دخول الطلاب'),
                onPressed: () {
                  // --- ✅ تعديل: استخدام push بدلًا من MaterialPageRoute ---
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginPage(accountType: 'student'),
                  ));
                  //Navigator.pushNamed(context, '/login', arguments: {'accountType': 'student'});
                },
              ),
            ),
            const SizedBox(height: 20),
            if (kIsWeb && _isInstallable) // --- ✅ تأكد أنه ويب قبل عرض زر التثبيت ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined, size: 28),
                  label: const Text('ثبت التطبيق الان'),
                  onPressed: _showInstallPrompt,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00897B),
                    side: const BorderSide(color: Color(0xFF00897B), width: 2),
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // --- ✅✅✅  بداية إضافة زر تجربة الإشعارات  ✅✅✅ ---
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.orangeAccent),
              label: const Text('تجربة الإشعارات (للمطور)', style: TextStyle(color: Colors.orangeAccent)),
              onPressed: () {
                // استخدام ScaffoldMessenger لعرض SnackBar كـ "بانر"
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    // يجعله يطفو في الأعلى بدلاً من الأسفل
                    behavior: SnackBarBehavior.floating,
                    // تحديد الهوامش ليظهر في الأعلى (نطرح قيمة لرفعه عن الأسفل)
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 150, // يظهر قرب الأعلى
                      left: 16.0,
                      right: 16.0,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.blueGrey.shade800,
                    content: const Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.white),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'إشعار تجريبي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                'مرحبا بكم في بوابة مدارس المعرفة!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
                // --- ✅ إضافة: تجربة الصوت والإشعار الفعلي ---
                _playNotificationSound();
                _showBrowserNotification("إشعار تجريبي", "مرحبا بكم في بوابة مدارس المعرفة!");
                // --- نهاية الإضافة ---
              },
            ),
            // --- ✅✅✅  نهاية إضافة زر تجربة الإشعارات  ✅✅✅ ---

          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      // --- ✅ إزالة SafeArea لأنها موجودة في الأعلى ---
      // SafeArea(
      //  top: false, // Ensure it doesn't add top padding again
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 24.0, // Space between columns
        runSpacing: 16.0, // Space between rows if wrapping
        children: [
          _buildFooterColumn(
            'للشكاوي والملاحظات',
            [
              'مدير المدرسة أ: عبدالله المطرفي (966539547972+)',
              'وكيل الشئون التعليمية: أ/عماد الجندي (966502361091+)',
              'وكيل المدرسة: ا عصام المطرفي (966501468550+)',
              'موجه الطلاب: أ عبدالرحمن عثمان (966500971015+)',
              'موجه الطلاب: أ يحيي (966502649649+)',
            ],
          ),
          _buildFooterColumn(
            'الدعم الفني والتسجيل',
            [
              '</> مصطفي سعيد (966569064173+)',
            ],
          ),
        ],
      ),
      //),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Take minimum vertical space
      crossAxisAlignment: CrossAxisAlignment.center, // Center text horizontally
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding( // Added padding for better spacing on wrap
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            item,
            textDirection: TextDirection.rtl, // Ensure RTL for phone numbers etc.
            textAlign: TextAlign.center, // Center text within its line
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        )),
      ],
    );
  }
}
// --- 🛑 MODIFICATION END 🛑 ---


class LoginPage extends StatefulWidget {
  final String accountType;
  const LoginPage({super.key, required this.accountType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  // final _firestore = FirebaseFirestore.instance; // Not used here anymore
  bool _isLoading = false;

  Future<void> _signIn() async {
    // --- ✅ التحقق من أن الواجهة لا تزال موجودة ---
    if (!mounted || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      debugPrint("Attempting sign in for type: ${widget.accountType} with email: ${_emailController.text.trim()}");
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user == null) {
        // This case should ideally be caught by FirebaseAuthException below
        debugPrint("Sign in successful but user object is null.");
        throw FirebaseAuthException(code: 'user-not-found'); // Or a custom code
      }

      debugPrint("Sign in successful for UID: ${user.uid}. Navigating back to AuthWrapper.");

      // (تم نقل منطق التحقق من الصلاحيات وحفظ التوكن إلى AuthWrapper)
      // (سيعيد التوجيه تلقائياً بعد تسجيل الدخول الناجح)

      if (mounted) {
        // العودة إلى AuthWrapper وهو سيتولى عملية التوجيه
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ ما.';
      // --- ✅✅✅ إضافة: طباعة الأخطاء لتشخيص المشكلة ---
      debugPrint("FirebaseAuthException during sign in: Code: ${e.code}, Message: ${e.message}");
      // --- نهاية الإضافة ---

      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') { // Added invalid-email check
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'network-request-failed') {
        message = 'مشكلة في الاتصال بالشبكة. يرجى المحاولة مرة أخرى.';
      } else if (e.code == 'too-many-requests') {
        message = 'تم حظر هذا الجهاز مؤقتًا بسبب كثرة محاولات الدخول الفاشلة.';
      } else {
        message = 'حدث خطأ غير متوقع (${e.code}).'; // Show code for unknown errors
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e, s) { // --- ✅ إضافة: التعامل مع الأخطاء العامة ---
      debugPrint("Generic error during sign in: $e\nStacktrace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع. حاول مرة أخرى.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // --- ✅ التحقق من أن الواجهة لا تزال موجودة قبل تحديث الحالة ---
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.accountType == 'teacher';
    final portalName = isTeacher ? 'بوابة المعلمين' : 'بوابة الطلاب';
    final screenWidth = MediaQuery.of(context).size.width;
    // --- ✅ تعديل: حجم اللوجو ليكون أكثر استجابة ---
    final logoSize = math.min(screenWidth * 0.4, 180.0).clamp(100.0, 180.0);

    return Scaffold(
      // --- ✅ تعديل: استخدام نفس خلفية WelcomePage للاتساق ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // --- نهاية التعديل ---
      body: SafeArea(
        // --- ✅ استخدام Center و SingleChildScrollView لتبسيط التوسيط ---
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // --- ✅ تعديل: إزالة Align واستخدام Row ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(), // Prevent back while loading
                              tooltip: 'الرجوع',
                            ),
                          ],
                        ),
                        // --- نهاية التعديل ---

                        // --- ✅ إضافة: تحقق من وجود الملف قبل عرضه ---
                        Image.asset('assets/m1.png', height: logoSize, width: logoSize, errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.school, size: logoSize, color: Theme.of(context).primaryColor.withOpacity(0.5));
                        }),
                        const SizedBox(height: 24),
                        Text(portalName,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined)),
                          validator: (value) => (value == null || value.isEmpty || !value.contains('@')) // Basic email check
                              ? 'الرجاء إدخال بريد إلكتروني صحيح'
                              : null,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr, // Keep LTR for email
                          textAlign: TextAlign.left, // Keep left align for email
                          enabled: !_isLoading, // Disable when loading
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(Icons.lock_outline)),
                          validator: (value) =>
                          (value == null || value.isEmpty) ? 'الرجاء إدخال كلمة المرور' : null,
                          textDirection: TextDirection.ltr, // Keep LTR for password
                          textAlign: TextAlign.left, // Keep left align for password
                          enabled: !_isLoading, // Disable when loading
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Fixed height for button/indicator consistency
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                              onPressed: _signIn,
                              child: const Text('تسجيل دخول')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // --- نهاية التبسيط ---
      ),
    );
  }
}