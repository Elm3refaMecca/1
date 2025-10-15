// main.dart (MODIFIED)

import 'dart:async';
import 'dart:js' as js; // لاستدعاء دوال JavaScript
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math; // استيراد مكتبة الرياضيات لتحديد الحجم الأقصى

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
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/add': (context) => const AddPage(),
        '/student_view': (context) => const StudentViewPage(),
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
                  return const AddPage();
                case 'student':
                  return const StudentViewPage();
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

  // New state variables for leaderboards
  bool _isLoadingLeaderboards = true;
  List<TopStudent> _topStudents = [];
  List<TopClass> _topClasses = [];

  @override
  void initState() {
    super.initState();
    // PWA install listener
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

    // Fetch data from Firestore
    _fetchLeaderboards();
  }

  Future<void> _fetchLeaderboards() async {
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
          .where('totalLikes', isGreaterThan: 0)
          .get();

      final Map<String, int> classLikes = {};
      for (var doc in allStudentsSnapshot.docs) {
        final data = doc.data();
        final String className = '${data['grades']} / ${data['classes']}';
        final int likes = data['totalLikes'] ?? 0;
        classLikes.update(className, (value) => value + likes, ifAbsent: () => likes);
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

    } catch (e) {
      debugPrint("Error fetching leaderboards: $e");
      if(mounted) {
        setState(() {
          _isLoadingLeaderboards = false;
        });
      }
    }
  }

  void _showInstallPrompt() {
    js.context.callMethod('showInstallPrompt');
  }

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
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Login Section
                      (constraints.maxWidth > 900)
                          ? _buildWideLayout()
                          : _buildMobileLayout(),

                      // Leaderboards Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 550),
                          child: Column(
                            children: [
                              _buildTopStudentsCard(),
                              const SizedBox(height: 16),
                              _buildTopClassesCard(),
                            ],
                          ),
                        ),
                      ),

                      // Footer Section
                      const Spacer(),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
      // This line moves the Floating Action Button to the right side of the screen
      // in an RTL (Arabic) layout.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: SpeedDial(
        heroTag: 'main-fab',
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
      // --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---
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
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.5, 240.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/m1.png', height: logoSize, width: logoSize),
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
            const SizedBox(height: 20),
            if (_isInstallable)
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
                'مدير المدرسة  أ: عبدالله المطرفي (966539547972+)',
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
    final portalName = isTeacher ? 'بوابة المعلمين' : 'بوابة الطلاب';
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(screenWidth * 0.4, 180.0);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
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
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                Image.asset('assets/m1.png', height: logoSize, width: logoSize),
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
              ),
            );
          },
        ),
      ),
    );
  }
}