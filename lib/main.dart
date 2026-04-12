import 'package:firebase_auth/firebase_auth.dart';
import 'package:almarefamecca/firebase_options.dart';
import 'dart:js' as js;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:universal_html/html.dart' as html;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:almarefamecca/add.dart';
import 'package:almarefamecca/student_view.dart';

class QRSessionTimer {
  static Timer? _timer;
  static final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  static bool isActive = false;

  static void startSession(BuildContext context) {
    isActive = true;
    remainingSeconds.value = 300;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        stopSession();
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('انتهت جلسة السبورة (5 دقائق). تم الخروج تلقائياً للأمان.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  static void stopSession() {
    _timer?.cancel();
    isActive = false;
    remainingSeconds.value = 0;
  }
}

class QRSessionOverlay extends StatelessWidget {
  final Widget child;
  const QRSessionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (QRSessionTimer.isActive)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: QRSessionTimer.remainingSeconds,
              builder: (context, seconds, _) {
                if (seconds <= 0) return const SizedBox.shrink();

                final mins = (seconds / 60).floor();
                final secs = seconds % 60;
                final bool isUrgent = seconds < 60;

                return Material(
                  color: isUrgent ? Colors.redAccent.shade700 : Colors.red,
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'جلسة مؤقتة: سيتم الخروج خلال ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Cairo'
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () async {
                            QRSessionTimer.stopSession();
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.logout, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                    'خروج',
                                    style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class GlobalScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class ExitPopupWrapper extends StatelessWidget {
  final Widget child;
  const ExitPopupWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (QRSessionTimer.isActive) {
          QRSessionTimer.stopSession();
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('تنبيه الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'هل تريد فعلاً الخروج من التطبيق؟',
              style: TextStyle(fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.all(16),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('تراجع (بقاء)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.exit_to_app, size: 18),
                label: const Text('خروج نهائي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

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
}

void _playNotificationSound() {
  if (kIsWeb) {
    try {
      final html.AudioElement audio = html.AudioElement('1.mp3');
      audio.play().catchError((e) {});
    } catch (e) {}
  }
}

void _showBrowserNotification(String title, String body) {
  if (kIsWeb && html.Notification.supported) {
    if (html.Notification.permission == 'granted') {
      try {
        html.Notification(title, body: body, icon: 'icons/Icon-192.png');
      } catch (e) {}
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _initializeAfterFirebase();
          return const TeacherLoginApp();
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SafeLoadingWidget(),
          ),
        );
      },
    );
  }

  Future<void> _initializeAfterFirebase() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {}
  }
}

class SafeLoadingWidget extends StatelessWidget {
  const SafeLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/m1.png',
              height: 150,
              width: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.school, size: 100, color: Theme.of(context).primaryColor);
              },
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 15),
            const Text(
              "جاري التحقق من البيانات...",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo'),
            )
          ],
        ),
      ),
    );
  }
}

class TeacherLoginApp extends StatelessWidget {
  const TeacherLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1976D2);
    const Color accentColor = Color(0xFF00ACC1);
    const Color backgroundColor = Color(0xFFF0F4F8);

    return MaterialApp(
      title: 'بوابة ابتدائية المعرفة الاهلية',
      debugShowCheckedModeBanner: false,
      scrollBehavior: GlobalScrollBehavior(),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        '/add': (context) => const ExitPopupWrapper(child: QRSessionOverlay(child: AddPage())),
        '/student_view': (context) => const ExitPopupWrapper(child: StudentViewPage()),
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          final accountType = args?['accountType'] ?? 'student';
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
    // لم نعد بحاجة لفحص نتيجة الـ Redirect لأننا انتقلنا للـ Popup
  }

  Future<void> _setupFCM() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;
        try {
          await messaging.subscribeToTopic('public_announcements');
        } catch (e) {}

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            final title = message.notification!.title ?? 'إشعار جديد';
            final body = message.notification!.body ?? 'لديك إشعار جديد';
            _playNotificationSound();
            _showBrowserNotification(title, body);
          }
        });
        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
      } catch(e) {}
    }
  }

  Future<void> _handleStudentTokenRegistration(DocumentReference studentDocRef, Map<String, dynamic>? studentData) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true, badge: true, sound: true, provisional: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          String? token = await messaging.getToken();
          if (token != null) {
            final currentToken = studentData?['fcmToken'];
            if (currentToken != token) {
              await studentDocRef.set({'fcmToken': token}, SetOptions(merge: true));
            }
          }
        }
      } catch (e) {}
    }
  }

  Future<String> _getUserRole(User user) async {
    try {
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        return 'teacher';
      }

      final studentDocRef = _firestore.collection('students').doc(user.uid);
      final studentDoc = await studentDocRef.get();
      if (studentDoc.exists) {
        studentDocRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
        }).catchError((e) {});
        _handleStudentTokenRegistration(studentDocRef, studentDoc.data() as Map<String, dynamic>?);
        return 'student';
      }

      final pendingTeacher = await _firestore.collection('pending_teachers').doc(user.uid).get();
      if (pendingTeacher.exists) return 'pending';

      final pendingStudent = await _firestore.collection('pending_students').doc(user.uid).get();
      if (pendingStudent.exists) return 'pending';

      return 'unregistered';

    } catch (e) {
      debugPrint("Firebase Read Error: $e");
      return 'error:$e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.white, body: SafeLoadingWidget());
        }

        if (authSnapshot.hasError) {
          return const Scaffold(body: Center(child: Text("حدث خطأ في المصادقة.")));
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<String>(
            future: _getUserRole(authSnapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(backgroundColor: Colors.white, body: SafeLoadingWidget());
              }

              final role = roleSnapshot.data;

              switch (role) {
                case 'teacher':
                  return const ExitPopupWrapper(child: QRSessionOverlay(child: AddPage()));
                case 'student':
                  return const ExitPopupWrapper(child: StudentViewPage());
                case 'pending':
                  return const ExitPopupWrapper(child: PendingApprovalScreen());
                case 'unregistered':
                  return const ExitPopupWrapper(child: RegistrationFlow());
                case 'unauthorized':
                  return const ExitPopupWrapper(child: WelcomePage());
                default:
                  if (role != null && role.startsWith('error:')) {
                    return Scaffold(
                      body: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.security_update_warning_outlined, color: Colors.red, size: 80),
                              const SizedBox(height: 20),
                              const Text("عذراً، فشل النظام في قراءة بياناتك من Firebase بسبب صلاحيات (Security Rules) أو مشكلة بالاتصال.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(role.replaceFirst('error:', ''), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14), textDirection: TextDirection.ltr),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: () => FirebaseAuth.instance.signOut(),
                                icon: const Icon(Icons.logout),
                                label: const Text("تسجيل الخروج والمحاولة مرة أخرى"),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const ExitPopupWrapper(child: WelcomePage());
              }
            },
          );
        }
        return const ExitPopupWrapper(child: WelcomePage());
      },
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _setupPwaListeners();
    _checkNotificationPermission();
  }

  void _setupPwaListeners() {
    if (kIsWeb) {
      js.context['pwa-installable-listener'] = (event) {
        try {
          final isReady = js.context['isInstallable'] ?? false;
          if (mounted && _isInstallable != isReady) {
            setState(() { _isInstallable = isReady; });
          }
        } catch (e) {}
      };
      try {
        js.context.callMethod('addEventListener', ['pwa-installable', js.context['pwa-installable-listener']]);
        if (js.context.hasProperty('isInstallable')) {
          _isInstallable = js.context['isInstallable'] ?? false;
        }
      } catch(e) {}

      js.context['pwa-update-listener'] = (event) {
        try {
          final isReady = js.context['isUpdateAvailable'] ?? true;
          if (mounted) { setState(() { _updateAvailable = true; }); }
        } catch (e) {}
      };
      try {
        js.context.callMethod('addEventListener', ['pwa-update-available', js.context['pwa-update-listener']]);
        if (js.context.hasProperty('isUpdateAvailable')) {
          setState(() { _updateAvailable = js.context['isUpdateAvailable'] ?? false; });
        }
      } catch (e) {}
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
      } catch (e) {}
    }
    super.dispose();
  }

  void _checkNotificationPermission() async {
    if (kIsWeb) {
      if (html.Notification.supported) {
        if(mounted) {
          setState(() { _notificationPermission = html.Notification.permission ?? 'default'; });
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
        if(mounted) setState(() => _notificationPermission = 'default');
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        if(mounted) {
          setState(() { _notificationPermission = permission; });
        }
        if(permission == 'granted') {
          _showBrowserNotification("تم التفعيل!", "ستتلقى الإشعارات الهامة الآن.");
        }
      }
    } else {
      try {
        final messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true, badge: true, sound: true, provisional: true,
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
      } catch (e) {}
    }
  }

  void _showInstallPrompt() {
    if (kIsWeb) {
      try { js.context.callMethod('showInstallPrompt'); } catch (e) {}
    }
  }

  void _triggerUpdate() {
    if (kIsWeb) {
      try { js.context.callMethod('triggerPwaUpdate'); } catch (e) {
        html.window.location.reload();
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (kIsWeb) {
      html.window.location.reload();
    } else {
      _setupPwaListeners();
      _checkNotificationPermission();
      if (mounted) setState(() {});
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              contentPadding: const EdgeInsets.all(24.0),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: Theme.of(context).primaryColor, size: 50),
                    const SizedBox(height: 16),
                    Text('دخول مدير (ضيف)', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('الرجاء إدخال الرقم السري الخاص بالإدارة:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
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
                TextButton(
                  onPressed: _isCheckingPin ? null : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  icon: _isCheckingPin
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: const Text('دخول'),
                  onPressed: _isCheckingPin ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => _isCheckingPin = true);
                      final enteredPin = passwordController.text.trim();

                      try {
                        final doc = await FirebaseFirestore.instance
                            .collection('settings')
                            .doc('guest_access')
                            .get();

                        final correctPin = doc.data()?['admin_pin']?.toString() ?? '010';

                        if (enteredPin == correctPin) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _performGuestLogin('2@2.2', '222222');
                        } else {
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

  Future<void> _performGuestLogin(String email, String password) async {
    if (!mounted) return;
    setState(() => _isGuestLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'فشل تسجيل دخول الضيف.';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  // ✅ استدعاء مباشر لـ Popup بدون أي تأخير زمني لتفادي الحظر من المتصفح!
  void _signInWithGoogle() {
    GoogleAuthProvider authProvider = GoogleAuthProvider();
    authProvider.addScope('email');
    authProvider.setCustomParameters({
      'prompt': 'select_account',
    });

    if (kIsWeb) {
      FirebaseAuth.instance.signInWithPopup(authProvider).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إلغاء الدخول أو حظر النافذة من المتصفح'), backgroundColor: Colors.red),
          );
        }
      });
    } else {
      FirebaseAuth.instance.signInWithProvider(authProvider);
    }
  }

  void _showQRLoginDialog() {
    final String sessionId = const Uuid().v4();

    FirebaseFirestore.instance.collection('qr_logins').doc(sessionId).set({
      'created_at': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('qr_logins').doc(sessionId).snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  if (data['auth_token'] != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!context.mounted) return;
                      Navigator.pop(context);

                      try {
                        await FirebaseAuth.instance.signInWithCustomToken(data['auth_token']);
                        FirebaseFirestore.instance.collection('qr_logins').doc(sessionId).delete();

                        if (context.mounted) {
                          QRSessionTimer.startSession(context);
                        }

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل الدخول بالتوكن: $e'), backgroundColor: Colors.red)
                        );
                      }
                    });
                  }
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('دخول سريع آمن (QR)', textAlign: TextAlign.center),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: QrImageView(
                          data: sessionId,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'افتح تطبيق المعلم على هاتفك، ثم اضغط على "دخول السبورة الذكية" من لوحة التحكم وامسح هذا الكود.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'أمان 🔒: سيتم الخروج تلقائياً بعد 5 دقائق.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      displacement: 40.0,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildLoginCard(),
                  const SizedBox(height: 24),
                  _buildVisionAndMissionCard(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            SizedBox(
              width: 450,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                child: Column(
                  children: [
                    _buildLoginCard(),
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ),

            VerticalDivider(width: 1, thickness: 1, color: Colors.grey[200]),

            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Theme.of(context).primaryColor,
                  displacement: 40.0,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              _buildVisionAndMissionCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      'جاري تهيئة الحساب السريع...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          if (_updateAvailable)
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton.extended(
                heroTag: 'update_fab',
                onPressed: _triggerUpdate,
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.system_update),
                label: const Text('تحديث التطبيق'),
                elevation: 8,
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SpeedDial(
        heroTag: 'main-fab',
        icon: Icons.chat,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        buttonSize: const Size(60.0, 60.0),
        childrenButtonSize: const Size(60.0, 60.0),
        spaceBetweenChildren: 8.0,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.code),
            label: 'Website Developer: Mostafa Saeed',
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

  Widget _buildVisionAndMissionCard() {
    final visionTitle = "رؤيتنا";
    final visionText = "تعليم متميز منافس محلياً وعالمياً، في مجتمع مدرسي محفز للإبداع والابتكار.";

    final missionTitle = "رسالتنا";
    final missionText = "تقديم تعليم نوعي، يوافق رؤى الوطن المستقبلية، ويرتقي بمهارات وقدرات منسوبيه، يرفع درجة الجودة والكفاءة وتحسين المخرج، في وسط بيئة جاذبة متفاعلة مع المجتمع.";

    final mottoTitle = "شعارنا";
    final mottoText = "تطوير المجتمع وبناء الوطن مسؤوليتي .";

    final valuesTitle = "قيمنا";
    final List<String> valuesList = [
      "الاعتزاز بالدين الإسلامي",
      "المواطنة الصالحة",
      "المسؤولية المجتمعية",
      "العمل الجماعي",
      "التميز والإبداع",
      "الجودة والإتقان",
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Column(
          children: [
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

  Widget _buildLoginCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.4, 180.0).clamp(100.0, 180.0);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 8.0, 32.0, 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
                'assets/m1.png',
                height: logoSize,
                width: logoSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.school, size: logoSize, color: Theme.of(context).primaryColor.withOpacity(0.5));
                }
            ),

            const SizedBox(height: 16),

            Text(
              'بوابة ابتدائية المعرفة الاهلية ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
            ),
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
            const SizedBox(height: 12),

            // ✅ استدعاء الزر بدون وضع مؤشر التحميل قبله لحل مشكلة المتصفح
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                onPressed: _signInWithGoogle,
                icon: SvgPicture.asset('assets/g1.svg', height: 24),
                label: const Text(
                  'سجل الدخول بجوجل',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('دخول سريع للسبورة (QR)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
                onPressed: _showQRLoginDialog,
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

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('الدخول كضيف'),
                onPressed: _isGuestLoading ? null : _showGuestLoginOptions,
              ),
            ),
            const SizedBox(height: 12),

            _buildNotificationButton(),
            const SizedBox(height: 12),

            if (kIsWeb && _isInstallable)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('تثبيت التطبيق على الجهاز'),
                    onPressed: _showInstallPrompt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
                  ),
                ),
              ),
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
              'موجه الطلاب 1-3: أ يحيي (966502649649+)',
            ],
          ),
          _buildFooterColumn(
            'الدعم الفني والتسجيل',
            [
              'مطور الموقع / مصطفي سعيد (966569064173+)',
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
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ ما.';
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

class GoogleAccountLinker extends StatefulWidget {
  const GoogleAccountLinker({super.key});

  @override
  State<GoogleAccountLinker> createState() => _GoogleAccountLinkerState();
}

class _GoogleAccountLinkerState extends State<GoogleAccountLinker> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLinked = false;
  bool _isLoading = false;
  String? _linkedEmail;

  @override
  void initState() {
    super.initState();
    _checkIfLinked();
  }

  void _checkIfLinked() {
    final user = _auth.currentUser;
    if (user != null) {
      for (var userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          setState(() {
            _isLinked = true;
            _linkedEmail = userInfo.email;
          });
          return;
        }
      }
    }
    setState(() {
      _isLinked = false;
      _linkedEmail = null;
    });
  }

  // ✅ استخدام ربط سريع بدون تأخير للمتصفح
  void _linkGoogleAccount() {
    final user = _auth.currentUser;
    if (user == null) return;

    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.setCustomParameters({
      'prompt': 'select_account',
    });

    if (kIsWeb) {
      user.linkWithPopup(googleProvider).then((_) {
        _checkIfLinked();
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إلغاء العملية أو الحظر من المتصفح'), backgroundColor: Colors.red),
          );
        }
      });
    } else {
      user.linkWithProvider(googleProvider).then((_) => _checkIfLinked());
    }
  }

  Future<void> _unlinkGoogleAccount() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.unlink('google.com');
        _checkIfLinked();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء ربط حساب Google بنجاح.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إلغاء الربط. تأكد من وجود طريقة دخول أخرى.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blueGrey),
                SizedBox(width: 10),
                Text(
                  'إعدادات الدخول السريع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            if (_isLinked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/g1.svg', height: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('حسابك مرتبط بـ Google بنجاح', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          if (_linkedEmail != null)
                            Text(_linkedEmail!, style: TextStyle(color: Colors.green.shade800, fontSize: 13)),
                        ],
                      ),
                    ),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : TextButton(
                      onPressed: _unlinkGoogleAccount,
                      child: const Text('إلغاء الربط', style: TextStyle(color: Colors.red)),
                    )
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'اربط حسابك الآن بـ Google لتتمكن من تسجيل الدخول بضغطة زر واحدة في المرات القادمة بدون الحاجة لكتابة كلمة المرور.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: _linkGoogleAccount, // تم إزالة التحقق من _isLoading لمنع حظر النافذة
                  icon: SvgPicture.asset('assets/g1.svg', height: 24),
                  label: const Text(
                    'ربط الحساب بـ Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حالة الحساب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'حسابك قيد المراجعة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'تم إرسال بياناتك للإدارة بنجاح. يرجى الانتظار حتى يتم قبول طلبك لتتمكن من الدخول للبوابة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج والعودة للرئيسية'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    if (selectedRole == 'teacher') {
      return const TeacherRegistrationForm();
    } else if (selectedRole == 'student') {
      return const StudentRegistrationForm();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('استكمال التسجيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'إلغاء وتسجيل خروج',
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'أهلاً بك! يبدو أنك تسجل دخولك لأول مرة.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى تحديد صفتك في المدرسة لاستكمال بياناتك:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleCard(
                    context,
                    title: 'معلم',
                    icon: Icons.person,
                    color: Colors.blue,
                    onTap: () => setState(() => selectedRole = 'teacher'),
                  ),
                  const SizedBox(width: 20),
                  _buildRoleCard(
                    context,
                    title: 'طالب',
                    icon: Icons.child_care,
                    color: Colors.orange,
                    onTap: () => setState(() => selectedRole = 'student'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherRegistrationForm extends StatefulWidget {
  const TeacherRegistrationForm({super.key});

  @override
  State<TeacherRegistrationForm> createState() => _TeacherRegistrationFormState();
}

class _TeacherRegistrationFormState extends State<TeacherRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();

  String? _selectedStage;
  List<String> _selectedClasses = [];

  final List<String> stages = ['الصفوف الأولية', 'الصفوف العليا'];
  final List<String> availableClasses = ['1/أ', '1/ب', '2/أ', '2/ب', '3/أ', '3/ب', '4/أ', '5/أ', '6/أ'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المرحلة')));
      return;
    }
    if (_selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار فصل واحد على الأقل')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، فقدت جلسة الاتصال. يرجى تسجيل الدخول مجدداً')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pending_teachers').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'firstName': _firstNameCtrl.text.trim(),
        'secondName': _secondNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName': '${_firstNameCtrl.text.trim()} ${_secondNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'idNumber': _idNumberCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'jobTitle': _jobTitleCtrl.text.trim(),
        'stage': _selectedStage,
        'classes': _selectedClasses,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات المعلم الجديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/registration'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('يرجى تعبئة جميع البيانات بدقة ليتم مراجعتها من قبل الإدارة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_firstNameCtrl, 'الاسم الأول')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_secondNameCtrl, 'الاسم الثاني')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_lastNameCtrl, 'الاسم الأخير')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberCtrl, 'رقم الهوية', isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneCtrl, 'رقم الهاتف', isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_jobTitleCtrl, 'الوظيفة (مثال: معلم رياضيات)'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'المرحلة الدراسية'),
                        value: _selectedStage,
                        items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _selectedStage = v),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الفصول التي تدرسها:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: availableClasses.map((c) {
                                final isSelected = _selectedClasses.contains(c);
                                return FilterChip(
                                  label: Text(c),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedClasses.add(c);
                                      } else {
                                        _selectedClasses.remove(c);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('إرسال الطلب للإدارة'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }
}

class StudentRegistrationForm extends StatefulWidget {
  const StudentRegistrationForm({super.key});

  @override
  State<StudentRegistrationForm> createState() => _StudentRegistrationFormState();
}

class _StudentRegistrationFormState extends State<StudentRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _thirdNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();

  String? _selectedGrade;
  String? _selectedClass;

  final List<String> grades = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'];
  final List<String> classes = ['أ', 'ب', 'ج'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGrade == null || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الصف والفصل')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، فقدت جلسة الاتصال. يرجى تسجيل الدخول مجدداً')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pending_students').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'firstName': _firstNameCtrl.text.trim(),
        'secondName': _secondNameCtrl.text.trim(),
        'thirdName': _thirdNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName': '${_firstNameCtrl.text.trim()} ${_secondNameCtrl.text.trim()} ${_thirdNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'idNumber': _idNumberCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'grade': _selectedGrade,
        'classRoom': _selectedClass,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات الطالب الجديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/registration'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('يرجى تعبئة جميع البيانات بدقة ليتم مراجعتها من قبل الإدارة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_firstNameCtrl, 'الاسم الأول')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_secondNameCtrl, 'الاسم الثاني')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_thirdNameCtrl, 'الاسم الثالث')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_lastNameCtrl, 'الاسم الأخير')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberCtrl, 'رقم الهوية', isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneCtrl, 'رقم هاتف ولي الأمر', isNumber: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                              value: _selectedGrade,
                              items: grades.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _selectedGrade = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'الفصل'),
                              value: _selectedClass,
                              items: classes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _selectedClass = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('إرسال الطلب للإدارة'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }
}