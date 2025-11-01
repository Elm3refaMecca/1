// main.dart (MODIFIED FOR "KHURAAFI" UI/UX, SHIMMER, AND NOTIFICATIONS)
// ✅✅✅ (FIXED) تم إصلاح مشكلة البطء عند أول تشغيل ✅✅✅
// ✅ (MODIFIED) تمت إضافة تحديث "آخر ظهور" للطالب عند تسجيل الدخول

import 'dart:async';
import 'dart:js' as js; // لاستدعاء دوال JavaScript
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math; // استيراد مكتبة الرياضيات لتحديد الحجم الأقصى

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:universal_html/html.dart' as html;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:url_launcher/url_launcher.dart';

// --- ✅✅✅ إضافة مكتبة الشيمر الاحترافية ✅✅✅ ---
import 'package:shimmer/shimmer.dart';

import 'package:almarefamecca/add.dart';
import 'package:almarefamecca/student_view.dart';
import 'package:almarefamecca/firebase_options.dart';


Future<void> _launchUrlHelper(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint("Could not launch $url");
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

void _playNotificationSound() {
  if (kIsWeb) {
    try {
      final html.AudioElement audio = html.AudioElement('1.mp3');
      audio.play().catchError((e) {
        debugPrint("Error playing notification sound (possibly autoplay policy): $e");
      });
    } catch (e) {
      debugPrint("Error creating or playing notification sound: $e");
    }
  }
}

void _showBrowserNotification(String title, String body) {
  if (kIsWeb && html.Notification.supported) {
    if (html.Notification.permission == 'granted') {
      try {
        html.Notification(title,
            body: body,
            icon: 'icons/Icon-192.png');
      } catch (e) {
        debugPrint("Error showing browser notification: $e");
      }
    } else {
      debugPrint("Browser notification permission not granted.");
    }
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(const TeacherLoginApp());
}

class TeacherLoginApp extends StatelessWidget {
  const TeacherLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1976D2);
    const Color accentColor = Color(0xFF00ACC1);
    const Color backgroundColor = Color(0xFFF0F4F8); // لون أفتح وأكثر احترافية

    return MaterialApp(
      title: 'بوابة مدرسة المعرفة الاهلية',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
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
          background: backgroundColor, // استخدام اللون الجديد
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundColor, // استخدام اللون الجديد
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
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
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
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          final accountType = args?['accountType'] ?? 'student'; // Default or from args
          return LoginPage(accountType: accountType);
        }
      },
    );
  }
}

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
    _setupFCM();
  }

  // --- ✅✅✅ START OF PERFORMANCE FIX (1) ✅✅✅ ---
  // تم تعديل هذه الدالة لتكون خفيفة جداً عند بدء التشغيل
  // هي الآن تقوم فقط بـ "الاستماع" للإشعارات القادمة والاشتراك في المواضيع
  // (تم حذف طلب الأذونات وطلب التوكن من هنا، لأنها كانت تسبب البطء)
  Future<void> _setupFCM() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;

        // 1. اشترك في المواضيع العامة (سريع)
        try {
          await messaging.subscribeToTopic('public_announcements');
          debugPrint("Subscribed to public_announcements topic");
        } catch (e) {
          debugPrint("Failed to subscribe to topic: $e");
        }

        // 2. جهز المستمعات (سريع)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          if (message.notification != null) {
            final title = message.notification!.title ?? 'إشعار جديد';
            final body = message.notification!.body ?? 'لديك إشعار جديد';
            debugPrint('Message also contained a notification: $title / $body');
            _playNotificationSound();
            _showBrowserNotification(title, body);
          }
        });

        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint("App launched from terminated state by notification: ${initialMessage.data}");
        }

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('A new onMessageOpenedApp event was published!');
          debugPrint("App resumed from background by notification: ${message.data}");
        });

        // --- 🛑 تم حذف طلب الأذونات والتوكن من هنا (كان يسبب البطء) ---

        debugPrint("FCM Listeners setup complete.");

      } catch(e) {
        debugPrint("Error setting up FCM listeners: $e");
      }
    } else {
      debugPrint("FCM setup skipped for this platform.");
    }
  }

  /// --- ✅✅✅ START OF PERFORMANCE FIX (2) ✅✅✅ ---
  /// دالة مخصصة لطلب إذن الإشعارات وحفظ التوكن للطالب
  /// سيتم استدعاؤها "فقط" عندما نتأكد أن المستخدم هو "طالب"
  Future<void> _handleStudentTokenRegistration(DocumentReference studentDocRef, Map<String, dynamic>? studentData) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;

        // 1. اطلب الإذن الآن (عندما نعرف أنه طالب)
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true,
        );
        debugPrint('User granted notification permission (in role check): ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional)
        {
          // 2. احصل على التوكن الآن
          String? token = await messaging.getToken();
          debugPrint("FCM Token acquired for student: $token");

          if (token != null) {
            final currentToken = studentData?['fcmToken'];
            if (currentToken != token) {
              // 3. احفظ التوكن في الفايرستور
              await studentDocRef.set({'fcmToken': token}, SetOptions(merge: true));
              debugPrint("FCM Token saved/updated for student.");
            }
          }
        } else {
          debugPrint("FCM Token: Permission not granted, skipping token save for student.");
        }
      } catch (e) {
        debugPrint("Error getting/saving FCM token for student in AuthWrapper: $e");
      }
    }
  }

  // --- ✅✅✅ START OF PERFORMANCE FIX (3) ✅✅✅ ---
  // تم تعديل هذه الدالة لتستدعي دالة حفظ التوكن "بدون" أن توقف الواجهة
  Future<String> _getUserRole(User user) async {
    try {
      final teacherDoc =
      await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        debugPrint("User role determined: teacher");
        return 'teacher';
      }

      final studentDocRef = _firestore.collection('students').doc(user.uid);
      final studentDoc = await studentDocRef.get();
      if (studentDoc.exists) {
        debugPrint("User role determined: student");

        // --- ✅✅✅ START OF MODIFICATION (إضافة تحديث آخر ظهور) ✅✅✅ ---
        // نقوم بتحديث آخر ظهور للطالب هنا
        // نستخدم .then() بدلاً من await حتى لا نوقف تحميل الواجهة
        studentDocRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
        }).then((_) {
          debugPrint("Student lastSeen updated from AuthWrapper.");
        }).catchError((e) {
          debugPrint("Failed to update lastSeen from AuthWrapper: $e");
        });
        // --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---


        // --- ✅ التعديل هنا ---
        // استدعاء الدالة الجديدة للتعامل مع التوكن *بعد* التحقق من أنه طالب
        // (تم حذف await) هذا سيجعلها تعمل في الخلفية ولن توقف تحميل الواجهة
        _handleStudentTokenRegistration(studentDocRef, studentDoc.data() as Map<String, dynamic>?);
        // --- نهاية التعديل ---

        return 'student';
      }

      debugPrint("User role determined: unauthorized (not found in users or students)");
      await FirebaseAuth.instance.signOut();
      return 'unauthorized';

    } catch (e, s) {
      debugPrint("Error checking user role: $e\nStacktrace: $s");
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        debugPrint("Error signing out after role check failure: $signOutError");
      }
      return 'unauthorized';
    }
  }
  // --- ✅✅✅ END OF PERFORMANCE FIXES ✅✅✅ ---


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasError) {
          return const Scaffold(body: Center(child: Text("حدث خطأ في المصادقة.")));
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<String>(
            future: _getUserRole(authSnapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasError) {
                // في حالة حدوث خطأ، أعده لصفحة الترحيب بدلاً من تعليقه
                return const WelcomePage();
              }

              switch (roleSnapshot.data) {
                case 'teacher':
                  return const AddPage();
                case 'student':
                  return const StudentViewPage();
                case 'unauthorized':
                  return const WelcomePage();
                default:
                  return const WelcomePage();
              }
            },
          );
        }

        return const WelcomePage();
      },
    );
  }
}

// Data models for the leaderboards
class TopStudent {
  final String name;
  final int likes;
  final String grade;
  final String className;
  TopStudent({required this.name, required this.likes, required this.grade, required this.className});
}

class TopClass {
  final String name;
  final int likes;
  final int totalLikesInTopClass;
  TopClass({required this.name, required this.likes, this.totalLikesInTopClass = 0});
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isInstallable = false;
  bool _updateAvailable = false;
  bool _isLoadingLeaderboards = true; // <-- (مهم) سيبدأ وهو يعرض الشيمر
  List<TopStudent> _topStudents = [];
  List<TopClass> _topClasses = [];
  String _notificationPermission = 'default'; // 'default', 'granted', 'denied'

  @override
  void initState() {
    super.initState();
    _setupPwaListeners();
    _checkNotificationPermission();

    // --- ✅✅✅ START OF PERFORMANCE FIX (4) - تنفيذ اقتراحك ✅✅✅ ---
    // لن يتم تحميل لوحة المتصدرين فوراً
    // _fetchLeaderboards(); // <-- 🛑 تم التعطيل

    // سيتم تأخير التحميل 300 مللي ثانية
    // هذا يعطي الواجهة (الجزء العلوي) فرصة للظهور فوراً
    // وسيعرض الشيمر في الجزء السفلي أثناء التحميل
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchLeaderboards();
      }
    });
    // --- ✅✅✅ END OF PERFORMANCE FIX (4) ✅✅✅ ---
  }

  void _setupPwaListeners() {
    if (kIsWeb) {
      // PWA install listener
      js.context['pwa-installable-listener'] = (event) {
        try {
          final isReady = js.context['isInstallable'] ?? false;
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
    }
  }

  @override
  void dispose() {
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


  void _checkNotificationPermission() async {
    if (kIsWeb) {
      if (html.Notification.supported) {
        if(mounted) {
          setState(() {
            _notificationPermission = html.Notification.permission!;
          });
        }
      }
    } else {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        if(mounted) {
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            setState(() => _notificationPermission = 'granted');
          } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
            setState(() => _notificationPermission = 'denied');
          } else {
            setState(() => _notificationPermission = 'default');
          }
        }
      } catch (e) {
        debugPrint("Error checking mobile notification permission: $e");
        if(mounted) setState(() => _notificationPermission = 'default');
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        if(mounted) {
          setState(() {
            _notificationPermission = permission;
          });
        }
        if(permission == 'granted') {
          _showBrowserNotification("تم التفعيل!", "ستتلقى الإشعارات الهامة الآن.");
        }
      }
    } else {
      try {
        final messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if(mounted) {
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            setState(() => _notificationPermission = 'granted');
          } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
            setState(() => _notificationPermission = 'denied');
          } else {
            setState(() => _notificationPermission = 'default');
          }
        }
      } catch (e) {
        debugPrint("Error requesting mobile notification permission: $e");
      }
    }
  }


  Future<void> _fetchLeaderboards() async {
    if (!mounted) return;
    // لا نحتاج لتغيير _isLoadingLeaderboards إلى true لأنه بدأ كذلك
    // setState(() => _isLoadingLeaderboards = true);
    try {
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
          grade: data['grades'] ?? 'N/A',
          className: data['classes'] ?? 'N/A',
        );
      }).toList();

      final allStudentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('totalLikes', isGreaterThan: 0)
          .get();

      final Map<String, int> classLikes = {};
      for (var doc in allStudentsSnapshot.docs) {
        final data = doc.data();
        final String? grade = data['grades'];
        final String? className = data['classes'];
        final int likes = data['totalLikes'] ?? 0;

        if (grade != null && className != null) {
          final String classKey = '$grade / $className';
          classLikes.update(classKey, (value) => value + likes, ifAbsent: () => likes);
        }
      }

      final List<TopClass> classes = classLikes.entries.map((entry) {
        return TopClass(name: entry.key, likes: entry.value);
      }).toList();

      classes.sort((a, b) => b.likes.compareTo(a.likes));

      int topClassLikes = classes.isNotEmpty ? classes.first.likes : 1;
      final List<TopClass> top5Classes = classes.take(5).map((c) =>
          TopClass(name: c.name, likes: c.likes, totalLikesInTopClass: topClassLikes)
      ).toList();


      if (mounted) {
        setState(() {
          _topStudents = students;
          _topClasses = top5Classes;
          _isLoadingLeaderboards = false; // <-- (مهم) إيقاف الشيمر
        });
      }

    } catch (e, s) {
      debugPrint("Error fetching leaderboards: $e\nStacktrace: $s");
      if(mounted) {
        setState(() {
          _isLoadingLeaderboards = false; // <-- (مهم) إيقاف الشيمر حتى لو حدث خطأ
        });
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

  void _triggerUpdate() {
    if (kIsWeb) {
      try {
        js.context.callMethod('triggerPwaUpdate');
      } catch (e) {
        debugPrint("Error calling triggerPwaUpdate: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // --- ✅✅✅ التعديل هنا: استخدام CustomScrollView يسمح بالتحميل الكسول ---
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // 1. الجزء العلوي (يظهر فوراً)
                      _buildLoginCard(),
                      const SizedBox(height: 24),

                      // 2. الجزء السفلي (يعرض الشيمر ثم البيانات)
                      _buildTopStudentsCard(),
                      const SizedBox(height: 16),
                      _buildTopClassesCard(),

                      const SizedBox(height: 32),
                      _buildFooter(),
                      const SizedBox(height: 70), // مسافة للزر العائم
                    ],
                  ),
                ),
              ),
            ],
          ),
          // --- ✅✅✅ نهاية التعديل ---
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SpeedDial(
        heroTag: 'main-fab',
        icon: Icons.support_agent,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        buttonSize: const Size(60.0, 60.0),
        childrenButtonSize: const Size(60.0, 60.0),
        spaceBetweenChildren: 8.0,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.code),
            label: '<مبرمج المنصة> مصطفي سعيد ',
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            onTap: () => _launchUrlHelper('https://wa.me/966569064173'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.school),
            label: 'مدير المدرسة أ:عبدالله المطرفي',
            onTap: () => _launchUrlHelper('https://wa.me/966539547972'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.supervisor_account),
            label: 'وكيل الشئون التعليمية أ: عماد الجندي',
            onTap: () => _launchUrlHelper('https://wa.me/966502361091'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_pin),
            label: 'وكيل المدرسة أ: عصام المطرفي',
            onTap: () => _launchUrlHelper('https://wa.me/966501468550'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.support),
            label: 'موجه الطلاب 4-6: أ/ عبدالرحمن ',
            onTap: () => _launchUrlHelper('https://wa.me/966500971015'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.support),
            label: 'موجه الطلاب 1-3: أ/ يحيي',
            onTap: () => _launchUrlHelper('https://wa.me/966502649649'),
          ),
        ],
      ),
    );
  }

  // --- ✅✅✅ START OF MODIFICATION (New Top Students Card) ✅✅✅ ---
  // (هذه الدالة الآن تعرض الشيمر تلقائياً إذا كانت _isLoadingLeaderboards = true)
  Widget _buildTopStudentsCard() {
    final Map<int, double> podiumHeights = {1: 150.0, 2: 120.0, 3: 90.0};
    final List<TopStudent> students = _topStudents;

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
                // --- ✅ إضافة "جمل أكثر" ---
                Text("🏆 الطلاب المتميزون", style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            // --- ✅ إضافة "جمل أكثر" ---
            Text(
              "الأعلى انضباطاً على مستوى المدرسة",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            // --- ✅ استخدام الشيمر الاحترافي ---
            if (_isLoadingLeaderboards) // <-- (مهم) التحقق من حالة التحميل
              _buildLeaderboardShimmer()
            else if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("كن أنت الأول! لا يوجد طلاب متميزون حالياً"),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (students.length > 1)
                      Flexible(child: _buildRankPodium(context, students[1], 2, podiumHeights[2]!)),
                    if (students.isNotEmpty)
                      Flexible(child: _buildRankPodium(context, students[0], 1, podiumHeights[1]!)),
                    if (students.length > 2)
                      Flexible(child: _buildRankPodium(context, students[2], 3, podiumHeights[3]!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankPodium(BuildContext context, TopStudent student, int rank, double height) {
    final rankColors = {
      1: Colors.amber,
      2: Colors.grey.shade400,
      3: const Color(0xFFCD7F32),
    };

    return AnimationConfiguration.staggeredList(
      position: rank,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedTrophy(rank: rank),
              const SizedBox(height: 8),
              Text(
                student.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${student.grade} / ${student.className}",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thumb_up, color: Colors.blue.shade700, size: 14),
                  const SizedBox(width: 4),
                  Text('${student.likes}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 100,
                height: height,
                decoration: BoxDecoration(
                  color: rankColors[rank],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.black.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- ✅✅✅ END OF MODIFICATION (New Top Students Card) ✅✅✅ ---


  // --- ✅✅✅ START OF MODIFICATION (New Top Classes Card) ✅✅✅ ---
  // (هذه الدالة الآن تعرض الشيمر تلقائياً إذا كانت _isLoadingLeaderboards = true)
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
                // --- ✅ إضافة "جمل أكثر" ---
                Text("🏛️ الفصول الأكثر انضباطاً", style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            // --- ✅ إضافة "جمل أكثر" ---
            Text(
              "كن سبباً في فوز فصلك!",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            // --- ✅ استخدام الشيمر الاحترافي ---
            if (_isLoadingLeaderboards) // <-- (مهم) التحقق من حالة التحميل
              _buildLeaderboardShimmer()
            else if (_topClasses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("لا توجد بيانات لعرضها حالياً"),
              )
            else
              AnimationLimiter(
                child: Column(
                  children: _topClasses.asMap().entries.map((entry) {
                    int idx = entry.key;
                    TopClass topClass = entry.value;
                    double progress = (topClass.totalLikesInTopClass > 0)
                        ? (topClass.likes / topClass.totalLikesInTopClass)
                        : 0.0;

                    return AnimationConfiguration.staggeredList(
                      position: idx,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.teal.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.teal.withOpacity(0.2),
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(topClass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(topClass.likes.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.thumb_up, color: Colors.blue, size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 40.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.teal.withOpacity(0.2),
                                      color: Colors.teal,
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// --- ✅✅✅ ويدجت الشيمر الاحترافي الجديد ✅✅✅ ---
  Widget _buildLeaderboardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) =>
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 40,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
  // --- ✅✅✅ END OF MODIFICATION (New Top Classes Card & Shimmer) ✅✅✅ ---


  Widget _buildLoginCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.4, 180.0).clamp(100.0, 180.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (kIsWeb && _updateAvailable)
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
            Image.asset('assets/m1.png', height: logoSize, width: logoSize, errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.school, size: logoSize, color: Theme.of(context).primaryColor.withOpacity(0.5));
            }),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              // --- ✅ تعديل: استخدام أنيميشن مختلف للمبرمج ---
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontFamily: 'Cairo',
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText(
                      'elm3refa.site',
                      textAlign: TextAlign.center,
                      speed: const Duration(milliseconds: 150),
                    ),
                    WavyAnimatedText(
                      'elm3refa.site', // (هذا السطر كان به خطأ إملائي في ملفك الأصلي، أصلحته في السطر الذي قبله ولكن تركته هنا مطابقاً للأصل)
                      textAlign: TextAlign.center,
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1000),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'بوابة مدرسة المعرفة الاهلية',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
            ),
            // --- ✅ إضافة "جمل أكثر" ---
            Text(
              "بوابتك الذكية لمتابعة الأداء الأكاديمي والسلوكي",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('دخول المعلمين'),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginPage(accountType: 'teacher'),
                  ));
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
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginPage(accountType: 'student'),
                  ));
                },
              ),
            ),
            const SizedBox(height: 20),
            if (kIsWeb && _isInstallable)
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

            const SizedBox(height: 12),
            _buildNotificationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    switch (_notificationPermission) {
      case 'granted':
      // --- ✅ تحسين: إضافة أيقونة أوضح ---
        return OutlinedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
          label: const Text('الإشعارات مفعلة بنجاح', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.normal)),
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.green.withOpacity(0.5)),
          ),
        );
      case 'denied':
      // --- ✅ تحسين: إضافة أيقونة أوضح ---
        return OutlinedButton.icon(
          icon: const Icon(Icons.notifications_off_outlined, color: Colors.red, size: 20),
          label: const Text('الإشعارات محظورة (يرجى تفعيلها من إعدادات المتصفح)', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.normal)),
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.withOpacity(0.5)),
          ),
        );
      case 'default':
      default:
      // --- ✅ تحسين: جعل الزر أكثر جاذبية ---
        return ElevatedButton.icon(
          icon: const Icon(Icons.notifications_active, size: 20),
          label: const Text('تفعيل الإشعارات الهامة'),
          onPressed: _requestNotificationPermission,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14, // حجم أصغر
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // padding أصغر
          ),
        );
    }
  }


  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 24.0,
        runSpacing: 16.0,
        children: [
          _buildFooterColumn(
            'للشكاوي والملاحظات',
            [
              'مدير المدرسة أ: عبدالله المطرفي (966539547972+)',
              'وكيل الشئون التعليمية: أ/عماد الجندي (966502361091+)',
              'وكيل المدرسة: ا عصام المطرفي (966501468550+)',
              'موجه الطلاب 4-6: أ عبدالرحمن (966500971015+)',
              'موجه الطلاب 1-3: أ يحيي (966502649649+)',
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
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
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
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            item,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        )),
      ],
    );
  }
}


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
  bool _isLoading = false;

  Future<void> _signIn() async {
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
        debugPrint("Sign in successful but user object is null.");
        throw FirebaseAuthException(code: 'user-not-found');
      }

      debugPrint("Sign in successful for UID: ${user.uid}. Navigating back to AuthWrapper.");

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ ما.';
      debugPrint("FirebaseAuthException during sign in: Code: ${e.code}, Message: ${e.message}");

      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'network-request-failed') {
        message = 'مشكلة في الاتصال بالشبكة. يرجى المحاولة مرة أخرى.';
      } else if (e.code == 'too-many-requests') {
        message = 'تم حظر هذا الجهاز مؤقتًا بسبب كثرة محاولات الدخول الفاشلة.';
      } else {
        message = 'حدث خطأ غير متوقع (${e.code}).';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e, s) {
      debugPrint("Generic error during sign in: $e\nStacktrace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع. حاول مرة أخرى.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.accountType == 'teacher';
    final portalName = isTeacher ? 'بوابة المعلمين' : 'بوابة الطلاب';
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.4, 180.0).clamp(100.0, 180.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              tooltip: 'الرجوع',
                            ),
                          ],
                        ),

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
                          validator: (value) => (value == null || value.isEmpty || !value.contains('@'))
                              ? 'الرجاء إدخال بريد إلكتروني صحيح'
                              : null,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          enabled: !_isLoading,
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
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
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
      ),
    );
  }
}

/// ويدجت الكأس المتحرك (تم نسخه هنا ليعمل في WelcomePage)
class _AnimatedTrophy extends StatefulWidget {
  final int rank;
  const _AnimatedTrophy({required this.rank});

  @override
  __AnimatedTrophyState createState() => __AnimatedTrophyState();
}

class __AnimatedTrophyState extends State<_AnimatedTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, dynamic> rankDetails = {
      1: {'color': const Color(0xFFFFD700), 'size': 60.0},
      2: {'color': const Color(0xFFC0C0C0), 'size': 50.0},
      3: {'color': const Color(0xFFCD7F32), 'size': 40.0},
    };

    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.emoji_events,
        color: rankDetails[widget.rank]['color'],
        size: rankDetails[widget.rank]['size'],
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
    );
  }
}