// main.dart

import 'dart:async';
import 'dart:js' as js; // لاستدعاء دوال JavaScript
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

// --- MODIFIED: Added simple_speed_dial package import ---
import 'package:simple_speed_dial/simple_speed_dial.dart';

import 'package:almarefamecca/add.dart' deferred as add_page;
import 'package:almarefamecca/student_view.dart' deferred as student_view_page;
import 'package:almarefamecca/firebase_options.dart';

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~ (جديد) تم حذف المكونات المخصصة ~~~~~~~~~~~~~~~~~~~~~~
// ~ The custom SpeedDialAction class and CustomSpeedDial widget have been removed.
// ~ They are replaced by the 'simple_speed_dial' package.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


class DeferredLoader extends StatefulWidget {
  final Future<void> libraryFuture;
  final Widget Function() builder;

  const DeferredLoader({
    required this.libraryFuture,
    required this.builder,
    super.key
  });

  @override
  _DeferredLoaderState createState() => _DeferredLoaderState();
}

class _DeferredLoaderState extends State<DeferredLoader> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('حدث خطأ أثناء تحميل الصفحة: ${snapshot.error}')));
          }
          return widget.builder();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

Future<void> _launchUrlHelper(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('ar', null);
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
        '/add': (context) => DeferredLoader(
          libraryFuture: add_page.loadLibrary(),
          builder: () => add_page.AddPage(),
        ),
        '/student_view': (context) => DeferredLoader(
          libraryFuture: student_view_page.loadLibrary(),
          builder: () => student_view_page.StudentViewPage(),
        ),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> _getUserRole(User user) async {
    try {
      final teacherDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        return 'teacher';
      }
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      if (studentDoc.exists) {
        return 'student';
      }
      await FirebaseAuth.instance.signOut();
      return 'unauthorized';
    } catch (e) {
      await FirebaseAuth.instance.signOut();
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

        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<String>(
            future: _getUserRole(authSnapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              switch (roleSnapshot.data) {
                case 'teacher':
                  return DeferredLoader(
                    libraryFuture: add_page.loadLibrary(),
                    builder: () => add_page.AddPage(),
                  );
                case 'student':
                  return DeferredLoader(
                    libraryFuture: student_view_page.loadLibrary(),
                    builder: () => student_view_page.StudentViewPage(),
                  );
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

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isInstallable = false;
  int? _openSpeedDialIndex;

  @override
  void initState() {
    super.initState();
    js.context['pwa-installable-listener'] = (event) {
      final isReady = js.context['isInstallable'];
      if (mounted && _isInstallable != isReady) {
        setState(() {
          _isInstallable = isReady;
        });
      }
    };
    js.context.callMethod('addEventListener', ['pwa-installable', js.context['pwa-installable-listener']]);

    if (js.context.hasProperty('isInstallable')) {
      _isInstallable = js.context['isInstallable'];
    }
  }

  void _showInstallPrompt() {
    js.context.callMethod('showInstallPrompt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة مدرسة المعرفة الاهلية'),
        actions: [
          if (_isInstallable)
            IconButton(
              icon: const Icon(Icons.download_for_offline),
              tooltip: 'تثبيت التطبيق على جهازك',
              onPressed: _showInstallPrompt,
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: (constraints.maxWidth > 900)
                          ? _buildWideLayout()
                          : _buildMobileLayout(),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // --- MODIFIED: Changed layout to a Row and fixed 6 issues ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Social Media FAB (Left)
            SpeedDial(

              child: const Icon(Icons.public),
              speedDialChildren: <SpeedDialChild>[
                SpeedDialChild(
                  child: const Text('X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  label: 'X (Twitter)',
                  backgroundColor: Colors.black,
                  onPressed: () => _launchUrlHelper('https://x.com/your_school_handle'),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.camera_alt),
                  label: 'Instagram',
                  backgroundColor: Colors.pink,
                  onPressed: () => _launchUrlHelper('https://instagram.com/your_school_handle'),
                ),
                SpeedDialChild(
                  // FIX 6: Made icon color consistent with others
                  child: const Icon(Icons.camera, color: Colors.white),
                  label: 'Snapchat',
                  backgroundColor: Colors.yellow,
                  onPressed: () => _launchUrlHelper('https://snapchat.com/add/your_school_handle'),
                ),
              ],
            ),
            // Support FAB (Right)
            SpeedDial(

              child: const Icon(Icons.support_agent),
              speedDialChildren: <SpeedDialChild>[
                SpeedDialChild(
                  child: const Icon(Icons.code),
                  label: 'أ/مصطفي سعيد',
                  onPressed: () => _launchUrlHelper('tel:+966569064173'),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.school),
                  label: 'مدير المدرسة',
                  onPressed: () => _launchUrlHelper('tel:+966539547972'),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.supervisor_account),
                  label: 'وكيل الشئون التعليمية',
                  onPressed: () => _launchUrlHelper('tel:+966502361091'),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.person_pin),
                  label: 'وكيل المدرسة',
                  onPressed: () => _launchUrlHelper('tel:+966501468550'),
                ),
                SpeedDialChild(
                  // FIX 4 & 5: Differentiated label and made icon consistent
                  child: const Icon(Icons.support_agent),
                  label: 'موجه الطلاب: أ/ عبدالرحمن عثمان',
                  onPressed: () => _launchUrlHelper('tel:+966500971015'),
                ),
                SpeedDialChild(
                  // FIX 4 & 5: Differentiated label and made icon consistent
                  child: const Icon(Icons.support_agent),
                  label: 'موجه الطلاب: أ/ يحيي',
                  onPressed: () => _launchUrlHelper('tel:+966502649649'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildWideLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: _buildLoginCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _buildLoginCard(),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.school, size: 100, color: Color(0xFF1976D2)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 24.0,
          runSpacing: 16.0,
          children: [
            _buildFooterColumn(
              'للشكاوي والملاحظات',
              [
                'مدير المدرسة: عبدالله المطرفي (966539547972+)',
                'وكيل الشئون التعليمية: أ/عماد الجندي (966502361091+)',
                'وكيل المدرسة: ا عصام المطرفي (966501468550+)',
                'موجه الطلاب: أ عبدالرحمن عثمان (966500971015+)',
                'موجه الطلاب: أ يحيي (966502649649+)',
              ],
            ),
            _buildFooterColumn(
              'الدعم الفني والتسجيل',
              [
                'منشئ المنصة: أ/مصطفي سعيد (966569064173+)',
              ],
            ),
          ],
        ),
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
        ...items.map((item) => Text(
          item,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user == null) throw FirebaseAuthException(code: 'user-not-found');

      bool isAuthorized = false;

      if (widget.accountType == 'teacher') {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          isAuthorized = true;
        }
      } else if (widget.accountType == 'student') {
        final doc = await _firestore.collection('students').doc(user.uid).get();
        if (doc.exists) {
          isAuthorized = true;
        }
      }

      if (mounted) {
        if (isAuthorized) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          await _auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'الحساب غير مصرح له بالدخول من هذه الواجهة.'),
                backgroundColor: Colors.red),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ ما.';
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.accountType == 'teacher';
    final title = isTeacher ? 'تسجيل دخول المعلم' : 'تسجيل دخول الطالب';
    final portalName = isTeacher ? 'بوابة المعلمين' : 'بوابة الطلاب';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/2.png'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                      const Icon(Icons.school,
                          size: 100, color: Color(0xFF1976D2)),
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
                        validator: (value) => value!.isEmpty
                            ? 'الرجاء إدخال البريد الإلكتروني'
                            : null,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline)),
                        validator: (value) =>
                        value!.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
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
    );
  }
}