// main.dart (معدل لإضافة Lottie في الشاشة الافتتاحية)

// ✅✅✅ (FIXED) تم إصلاح مشكلة البطء عند أول تشغيل ✅✅✅
// ✅ (MODIFIED) تمت إضافة تحديث "آخر ظهور" للطالب عند تسجيل الدخول
// ✅ (MODIFIED) تمت إعادة هيكلة "الدخول كضيف" (طالب ومدير فقط)
// ✅ (MODIFIED) تم تعديل دخول "الضيف المدير" ليقرأ الرمز السري من Firestore

// ✅ (NEW REQUEST) تمت إضافة أيقونة AI عائمة "قابلة للسحب"
// ✅ (NEW REQUEST) تم تعديل واجهة الكمبيوتر (إزالة الحواف البيضاء) ورفع الشعار
// ✅ (NEW REQUEST) تم حذف أنيميشن VIP وإعادة ترتيب الأزرار
// ✅ (NEW REQUEST) تم تصغير حجم الخط الرئيسي
// ✅ (NEW REQUEST) تم تحديث تصميم نافذة دخول الضيف المدير
// ✅ (NEW REQUEST) استبدال شعار الشاشة الافتتاحية بملف Lottie (1.json)

// --- 💡 (تعديل) تم تحديث نصوص "الرؤية والرسالة" حسب الصورة المرفقة ---

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, Persistence, User, AuthWrapper, FirebaseAuthException;
import 'package:almarefamecca/firebase_options.dart';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math;

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:universal_html/html.dart' as html;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ إضافة مكتبة Lottie
import 'package:lottie/lottie.dart';

// (تم حذف shimmer لأنه كان يُستخدم في لوحات الصدارة فقط)
// import 'package:shimmer/shimmer.dart';

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

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint("Firebase Auth persistence set to LOCAL.");
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    if (e.toString().contains('setPersistence')) {
      debugPrint("Error setting auth persistence: $e");
    }
  }
  runApp(const TeacherLoginApp());
}

class TeacherLoginApp extends StatelessWidget {
  const TeacherLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1976D2);
    const Color accentColor = Color(0xFF00ACC1);
    const Color backgroundColor = Color(0xFFF0F4F8);

    return MaterialApp(
      title: 'بوابة ابدائية المعرفة الاهلية',
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
      // --- ✅✅✅ (REQUEST 3) - START OF MODIFICATION ---
      // (إضافة الأيقونة العائمة الدائمة القابلة للسحب هنا)
      builder: (context, child) => _GlobalFabStack(child: child),
      // --- ✅✅✅ (REQUEST 3) - END OF MODIFICATION ---
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

// --- ✅✅✅ (REQUEST 3) - START OF MODIFICATION ---
/// ويدجت جديد لإدارة حالة الزر العائم القابل للسحب
class _GlobalFabStack extends StatefulWidget {
  final Widget? child;
  const _GlobalFabStack({this.child});
  @override
  _GlobalFabStackState createState() => _GlobalFabStackState();
}

class _GlobalFabStackState extends State<_GlobalFabStack> {
  // الموضع الافتراضي للزر (سيتم تحديثه عند أول بناء)
  // --- (تم التعديل) تغيير الموضع الافتراضي الأولي ليكون أعلى الشاشة ---
  Offset _aiFabOffset = const Offset(20, 40); // (كان 20, 20)
  bool _isOffsetInitialized = false;

  @override
  Widget build(BuildContext context) {
    // --- (تم التعديل) جلب الحشوة العلوية (لمنطقة شريط الحالة) ---
    final padding = MediaQuery.of(context).padding;

    if (!_isOffsetInitialized) {
      final size = MediaQuery.of(context).size;

      // الموضع الأولي: 24 بكسل من أعلى اليمين
      _aiFabOffset = Offset(
          size.width - 56 - 24,  // X: (العرض) - (عرض الزر) - (حشوة) = اليمين
          padding.top + 24       // Y: (الحشوة العلوية) + (حشوة) = الأعلى
      );
      // (كان الموضع السابق أسفل اليمين)
      // _aiFabOffset = Offset(size.width - 56 - 24, size.height - 56 - 24);
      _isOffsetInitialized = true;
    }

    return Stack(
      children: [
        // 1. الصفحة الحالية (WelcomePage, AddPage, etc.)
        if (widget.child != null) widget.child!,

        // 2. الزر العائم القابل للسحب
        Positioned(
          left: _aiFabOffset.dx,
          top: _aiFabOffset.dy,
          child: GestureDetector(
            // عند السحب (باللمس أو الماوس)
            onPanUpdate: (details) {
              setState(() {
                _aiFabOffset = Offset(
                  // تحديد الموضع الأفقي ومنعه من الخروج من الشاشة
                  (_aiFabOffset.dx + details.delta.dx).clamp(8.0, MediaQuery.of(context).size.width - 56 - 8), // 8.0 حشوة
                  // --- (تم التعديل) تحديد الموضع العمودي ليبدأ من بعد الحشوة العلوية ---
                  (_aiFabOffset.dy + details.delta.dy).clamp(padding.top + 8.0, MediaQuery.of(context).size.height - 56 - 8),
                );
              });
            },
            child: FloatingActionButton(
              heroTag: 'ai-fab', // ضروري لـ Hero
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✨ خدمة المساعد الذكي (AI) قادمة قريباً!', textAlign: TextAlign.right),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              backgroundColor: Colors.black, // لون مميز
              foregroundColor: Colors.white54,
              child: const Icon(Icons.auto_awesome), // أيقونة الـ AI
            ),
          ),
        ),
      ],
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

  // --- 💡💡💡 (هذا هو الكود الصحيح والمعدل) 💡💡💡 ---
  Future<void> _setupFCM() async {
    // التحقق أولاً إذا كانت المنصة مدعومة (ويب أو موبايل)
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;

        // --- 💡 (هذا هو التعديل) ---
        // تم إخراج هذا الكود من 'if (!kIsWeb)'
        // ليتمكن المتصفح (الويب) من الاشتراك في الموضوع العام
        try {
          // الاشتراك في الموضوع العام لجميع المنصات
          await messaging.subscribeToTopic('public_announcements');
          debugPrint("Subscribed to public_announcements topic (Web and Mobile)");
        } catch (e) {
          debugPrint("Failed to subscribe to topic: $e");
        }
        // --- (نهاية التعديل) ---

        // هذا الكود يستمع للإشعارات **أثناء فتح التطبيق**
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          if (message.notification != null) {
            final title = message.notification!.title ?? 'إشعار جديد';
            final body = message.notification!.body ?? 'لديك إشعار جديد';
            debugPrint('Message also contained a notification: $title / $body');

            // تشغيل الصوت وإظهار الإشعار في المتصفح
            _playNotificationSound();
            _showBrowserNotification(title, body);
          }
        });

        // هذا الكود يتعامل مع الإشعارات التي تفتح التطبيق (وهو مغلق)
        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint("App launched from terminated state by notification: ${initialMessage.data}");
        }

        // هذا الكود يتعامل مع الإشعارات التي تفتح التطبيق (وهو في الخلفية)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('A new onMessageOpenedApp event was published!');
          debugPrint("App resumed from background by notification: ${message.data}");
        });

        debugPrint("FCM Listeners setup complete.");

      } catch(e) {
        debugPrint("Error setting up FCM listeners: $e");
      }
    } else {
      // إذا كانت المنصة غير مدعومة (مثل ديسكتوب)
      debugPrint("FCM setup skipped for this platform.");
    }
  }
  // --- 💡💡💡 (نهاية الكود الصحيح) 💡💡💡 ---


  Future<void> _handleStudentTokenRegistration(DocumentReference studentDocRef, Map<String, dynamic>? studentData) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;

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
          String? token = await messaging.getToken();
          debugPrint("FCM Token acquired for student: $token");

          if (token != null) {
            final currentToken = studentData?['fcmToken'];
            if (currentToken != token) {
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

        studentDocRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
        }).then((_) {
          debugPrint("Student lastSeen updated from AuthWrapper.");
        }).catchError((e) {
          debugPrint("Failed to update lastSeen from AuthWrapper: $e");
        });

        _handleStudentTokenRegistration(studentDocRef, studentDoc.data() as Map<String, dynamic>?);

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

// --- 💡 (حذف) تم حذف كلاسات بيانات لوحة الصدارة ---
// class TopStudent { ... }
// class TopClass { ... }

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isInstallable = false;
  bool _updateAvailable = false;
  String _notificationPermission = 'default';

  bool _isGuestLoading = false;
  final _auth = FirebaseAuth.instance;

  // --- 💡 (حذف) تم حذف متغيرات حالة لوحة الصدارة ---
  // bool _isLoadingLeaderboards = true;
  // List<TopStudent> _topStudents = [];
  // List<TopClass> _topClasses = [];

  @override
  void initState() {
    super.initState();
    _setupPwaListeners();
    _checkNotificationPermission();

    // --- 💡 (حذف) تم حذف استدعاء _fetchLeaderboards ---
    // Future.delayed(const Duration(milliseconds: 300), () {
    //   if (mounted) {
    //     _fetchLeaderboards();
    //   }
    // });
  }

  void _setupPwaListeners() {
    if (kIsWeb) {
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

  // --- 💡 (حذف) تم حذف دالة _fetchLeaderboards ---
  // Future<void> _fetchLeaderboards() async { ... }

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

  void _showGuestLoginOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('اختر صفة الدخول', textAlign: TextAlign.center),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _handleGuestLogin('student');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.child_care, color: Colors.blue),
                    SizedBox(width: 16),
                    Text('ضيف (طالب)', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _handleGuestLogin('admin');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.purple),
                    SizedBox(width: 16),
                    Text('ضيف (مدير)', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleGuestLogin(String role) {
    switch (role) {
      case 'student':
        _performGuestLogin('1@1.1', 'asdasdasd');
        break;
      case 'admin':
        _showAdminGuestPasswordPrompt();
        break;
    }
  }

  // --- ✅✅✅ (REQUEST 4) - START OF MODIFICATION ---
  // (تصميم عصري وجديد لنافذة دخول الضيف)
  void _showAdminGuestPasswordPrompt() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool _isCheckingPin = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // شكل بحواف دائرية عصرية
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              contentPadding: const EdgeInsets.all(24.0),
              // إزالة العنوان القياسي
              // title: const Text('دخول مدير (ضيف)'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة عصرية
                    Icon(Icons.admin_panel_settings_rounded, color: Theme.of(context).primaryColor, size: 50),
                    const SizedBox(height: 16),
                    // العنوان داخل المحتوى
                    Text('دخول مدير (ضيف)', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('الرجاء إدخال الرقم السري الخاص بالإدارة:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 20),
                    // حقل إدخال عصري
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4), // خط كبير ومتباعد
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        labelText: 'الرقم السري (PIN)',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الرقم السري';
                        }
                        return null;
                      },
                      readOnly: _isCheckingPin,
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actions: [
                // زر إلغاء بتصميم ناعم
                TextButton(
                  onPressed: _isCheckingPin ? null : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                // زر دخول مميز مع أيقونة
                ElevatedButton.icon(
                  icon: _isCheckingPin
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: const Text('دخول'),
                  onPressed: _isCheckingPin ? null : () async {
                    if (formKey.currentState!.validate()) {
                      // 1. بدء التحميل
                      setDialogState(() => _isCheckingPin = true);
                      final enteredPin = passwordController.text.trim();

                      try {
                        // 2. جلب الرمز السري من Firestore
                        final doc = await FirebaseFirestore.instance
                            .collection('settings')
                            .doc('guest_access')
                            .get();

                        // 3. التحقق من الرمز (مع رمز افتراضي "010" إذا لم يوجد)
                        final correctPin = doc.data()?['admin_pin']?.toString() ?? '010';

                        if (enteredPin == correctPin) {
                          // 4. نجاح: إغلاق النافذة وتنفيذ الدخول
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _performGuestLogin('2@2.2', '222222');
                        } else {
                          // 5. خطأ: إظهار رسالة
                          if (!mounted) return;
                          setDialogState(() => _isCheckingPin = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرقم السري غير صحيح.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        // 6. خطأ في الاتصال
                        if (!mounted) return;
                        setDialogState(() => _isCheckingPin = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل التحقق من الرمز: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  // جعل الزر بحواف دائرية
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --- ✅✅✅ (REQUEST 4) - END OF MODIFICATION ---


  Future<void> _performGuestLogin(String email, String password) async {
    if (!mounted) return;
    setState(() => _isGuestLoading = true);

    try {
      debugPrint("Attempting guest sign in with email: $email");
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint("Guest sign in successful. Navigating to AuthWrapper.");

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'فشل تسجيل دخول الضيف.';
      debugPrint("FirebaseAuthException during guest sign in: Code: ${e.code}");
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'بيانات حساب الضيف غير صحيحة. يرجى مراجعة الإدارة.';
      } else if (e.code == 'network-request-failed') {
        message = 'مشكلة في الشبكة. حاول مرة أخرى.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Generic error during guest sign in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildLoginCard(),
                const SizedBox(height: 24),
                // --- 💡 (تعديل) استبدال لوحات الصدارة بالرؤية والرسالة ---
                _buildVisionAndMissionCard(),
                // _buildTopStudentsCard(), // <-- محذوف
                // const SizedBox(height: 16), // <-- محذوف
                // _buildTopClassesCard(), // <-- محذوف
                // --- 💡 (نهاية التعديل) ---
                const SizedBox(height: 32),
                _buildFooter(),
                const SizedBox(height: 70), // مسافة لزر الدعم
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- ✅✅✅ (REQUEST 1) - START OF MODIFICATION ---
  // (إلغاء الحواف الخارجية للبطاقة البيضاء في وضع الكمبيوتر)
  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      // إزالة الحشوة الخارجية
      padding: EdgeInsets.zero,
      child: Card(
        elevation: 0, // لا ظل
        margin: EdgeInsets.zero, // لا حواف
        child: Row(
          children: [
            // --- العمود الأول: تسجيل الدخول ---
            SizedBox(
              width: 450,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                child: Column(
                  children: [
                    _buildLoginCard(), // كارت الدخول (الآن شفاف لأنه داخل كارت أبيض)
                    const SizedBox(height: 32),
                    _buildFooter(), // الفوتر أسفل كارت الدخول
                  ],
                ),
              ),
            ),

            // --- فاصل عمودي ---
            VerticalDivider(width: 1, thickness: 1, color: Colors.grey[200]),

            // --- العمود الثاني: لوحات المتصدرين (بخلفية أفتح) ---
            Expanded(
              child: Container(
                // لون خلفية أفتح قليلاً للتمييز
                color: Theme.of(context).scaffoldBackgroundColor,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            // --- 💡 (تعديل) استبدال لوحات الصدارة بالرؤية والرسالة ---
                            _buildVisionAndMissionCard(),
                            // _buildTopStudentsCard(), // <-- محذوف
                            // const SizedBox(height: 24), // <-- محذوف
                            // _buildTopClassesCard(), // <-- محذوف
                            // --- 💡 (نهاية التعديل) ---
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- ✅✅✅ (REQUEST 1) - END OF MODIFICATION ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.0, -1.0),
                radius: 1.5,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.15),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return _buildMobileLayout();
                } else {
                  return _buildDesktopLayout(context);
                }
              },
            ),
          ),

          if (_isGuestLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 16),
                    Text(
                      'جاري تسجيل الدخول كضيف...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // زر الدعم الفني (في مكانه أسفل اليسار)
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
            label: 'موجه الطلاب 4-6: أ/ موجة طلابي س ',
            onTap: () => _launchUrlHelper('https://wa.me/966**********'),
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

  // --- 💡 (إضافة) الويدجت الجديد للرؤية والرسالة ---
  Widget _buildVisionAndMissionCard() {
    // ✅ تم تحديث النصوص وفقاً للصورة المرفقة
    final visionTitle = "رؤيتنا";
    final visionText = "تعليم متميز منافس محلياً وعالمياً، في مجتمع مدرسي محفز للإبداع والابتكار.";

    final missionTitle = "رسالتنا";
    final missionText = "تقديم تعليم نوعي، يوافق رؤى الوطن المستقبلية، ويرتقي بمهارات وقدرات منسوبيه، يرفع درجة الجودة والكفاءة وتحسين المخرج، في وسط بيئة جاذبة متفاعلة مع المجتمع.";

    // ✅ تم إضافة الشعار
    final mottoTitle = "شعارنا";
    final mottoText = "تطوير المجتمع وبناء الوطن مسؤوليتي .";

    final valuesTitle = "قيمنا";
    // ✅ تم تحديث قائمة القيم
    final List<String> valuesList = [
      "الاعتزاز بالدين الإسلامي",
      "المواطنة الصالحة",
      "المسؤولية المجتمعية",
      "العمل الجماعي",
      "التميز والإبداع",
      "الجودة والإتقان",
    ];

    // تصميم باستخدام Card و ExpansionTile
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Column(
          children: [
            // 1. الرؤية
            ExpansionTile(
              leading: Icon(Icons.visibility, color: Theme.of(context).primaryColor),
              title: Text(visionTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 18)),
              initiallyExpanded: true,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(visionText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 2. الرسالة
            ExpansionTile(
              leading: Icon(Icons.flag, color: Colors.teal.shade600),
              title: Text(missionTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade600, fontSize: 18)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(missionText, textAlign: TextAlign.justify, style: const TextStyle(fontSize: 15, height: 1.6)),
                ),
              ],
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 3. الشعار (جديد)
            ExpansionTile(
              leading: Icon(Icons.stars, color: Colors.amber.shade800),
              title: Text(mottoTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800, fontSize: 18)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(mottoText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 4. القيم
            ExpansionTile(
              leading: Icon(Icons.shield, color: Colors.deepPurple.shade600),
              title: Text(valuesTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade600, fontSize: 18)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: valuesList.map((value) {
                      return Chip(
                        label: Text(value, style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.deepPurple.shade400,
                        elevation: 2,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 💡 (حذف) تم حذف دوال لوحة الصدارة ---
  // _buildTopStudentsCard()
  // _buildRankPodium()
  // _buildTopClassesCard()
  // _buildLeaderboardShimmer()

  Widget _buildLoginCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.4, 180.0).clamp(100.0, 180.0);

    return Card(
      elevation: 0,
      color: Colors.transparent, // شفاف في وضع الكمبيوتر
      child: Padding(
        // --- ✅✅✅ (REQUEST 2) - START OF MODIFICATION ---
        // (تقليل الحشو العلوي لرفع الشعار)
        padding: const EdgeInsets.fromLTRB(32.0, 8.0, 32.0, 32.0),
        // --- ✅✅✅ (REQUEST 2) - END OF MODIFICATION ---
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

            // ✅✅✅ (MODIFIED) استبدال الصورة الثابتة بملف Lottie من مجلد web
            SizedBox(
              height: logoSize,
              width: logoSize,
              child: Lottie.network(
                '1.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // في حالة عدم تحميل ملف json، نعرض الصورة القديمة كاحتياط
                  return Image.asset('assets/m1.png', height: logoSize, width: logoSize, errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.school, size: logoSize, color: Theme.of(context).primaryColor.withOpacity(0.5));
                  });
                },
              ),
            ),

            // --- ✅✅✅ (REQUEST 3) - START OF MODIFICATION ---
            // (تم حذف الأنيميشن والسلاسل النصية المحيطة به)
            const SizedBox(height: 16),
            // --- ✅✅✅ (REQUEST 3) - END OF MODIFICATION ---

            Text(
              'بوابة ابتدائية المعرفة الاهلية ',
              textAlign: TextAlign.center,
              style: TextStyle(
                // --- ✅✅✅ (REQUEST 5) - START OF MODIFICATION ---
                  fontSize: 22, // (تم تصغيره من 26)
                  // --- ✅✅✅ (REQUEST 5) - END OF MODIFICATION ---
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
            ),
            Text(
              "بوابتك الذكية لمتابعة الأداء الأكاديمي والسلوكي",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),

            // --- ✅✅✅ (REQUEST 1) - START OF REORDERING ---
            // 1. دخول المعلمين
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

            // 2. دخول الطلاب
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

            // 3. الدخول كضيف (تم نقله هنا)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('الدخول كضيف'),
                onPressed: _isGuestLoading ? null : _showGuestLoginOptions,
              ),
            ),
            const SizedBox(height: 12),

            // 4. تفعيل الإشعارات (تم نقله هنا)
            _buildNotificationButton(),
            const SizedBox(height: 12),

            // 5. تثبيت التطبيق (تم نقله لآخر القائمة)
            if (kIsWeb && _isInstallable)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('ثبت التطبيق الان'),
                  onPressed: _showInstallPrompt,
                ),
              ),
            // --- ✅✅✅ (REQUEST 1) - END OF REORDERING ---
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    switch (_notificationPermission) {
      case 'granted':
        return OutlinedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
          label: const Text('الإشعارات مفعلة بنجاح', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.normal)),
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.green.withOpacity(0.5)),
          ),
        );
      case 'denied':
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
        return ElevatedButton.icon(
          icon: const Icon(Icons.notifications_active, size: 20),
          label: const Text('تفعيل الإشعارات الهامة'),
          onPressed: _requestNotificationPermission,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
              'موجه الطلاب 4-6: أ موجة طلابي س (966**********+)',
              'موجه الطلاب 1-3: أ يحيي (9665'
                  ''
                  ''
                  '0'
                  ''
                  '02649649+)',
            ],
          ),
          _buildFooterColumn(
            'الدعم الفني والتسجيل',
            [
              '<مبرمج المنصة/> مصطفي سعيد (966569064173+)',
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

// --- 💡 (حذف) تم حذف ويدجت الكأس المتحرك ---
// class _AnimatedTrophy { ... }

Future<void> _subscribeToPublicAnnouncements() async {
  const String topic = 'public_announcements';
  // ... (كود طلب الإذن والاشتراك)
  await FirebaseMessaging.instance.subscribeToTopic(topic);
}