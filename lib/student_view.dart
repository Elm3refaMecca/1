import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:almarefamecca/secondary_pages.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:universal_html/html.dart' as html;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:card_swiper/card_swiper.dart';
import 'main.dart';

enum StudentView { dashboard, results, noble, teacherComplaints }

class StudentViewPage extends StatefulWidget {
  final String? studentId;

  const StudentViewPage({super.key, this.studentId});

  @override
  _StudentViewPageState createState() => _StudentViewPageState();
}

class _DashboardButtonData {
  final String title;
  final IconData icon;
  final String? assetPath;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isWorking;
  final bool isFeatured;

  _DashboardButtonData({
    required this.title,
    required this.icon,
    this.assetPath,
    required this.color,
    required this.onTap,
    this.badgeText,
    this.isWorking = true,
    this.isFeatured = false,
  });
}

class _StudentViewPageState extends State<StudentViewPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  StudentView _currentView = StudentView.dashboard;
  final Map<String, Color> _subjectColors = {};

  String? _studentDocId;

  late final Map<String, TestInfo> _allTestsMap;
  bool _isPrinting = false;

  StreamSubscription<DocumentSnapshot>? _studentDataSub;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  final Set<String> _processedNotificationIds = {};
  bool _listenersSetup = false;

  bool _isTeacherView = false;

  final GlobalKey _printKey = GlobalKey();

  final List<Subject> subjects = [
    Subject(name: 'رياضيات', icon: Icons.calculate),
    Subject(name: 'لغتي', icon: Icons.translate),
    Subject(name: 'إسلاميات', icon: Icons.mosque),
    Subject(name: 'علوم', icon: Icons.science),
    Subject(name: 'انجليزي', icon: Icons.book),
    Subject(name: 'اجتماعيات', icon: Icons.public),
    Subject(name: 'فنية', icon: Icons.palette),
    Subject(name: 'بدنية', icon: Icons.fitness_center),
    Subject(name: 'رقمية', icon: Icons.computer),
    Subject(name: 'تفكير', icon: Icons.psychology),
    Subject(name: 'نشاط', icon: Icons.star),
    Subject(name: 'حياتية', icon: Icons.eco),
    Subject(name: 'روبوت', icon: Icons.precision_manufacturing),
    Subject(name: 'قيم وسلوك', icon: Icons.volunteer_activism),
    Subject(name: 'أخرى', icon: Icons.more_horiz),
    Subject(name: 'مصدر', icon: Icons.source),
  ];

  @override
  void initState() {
    super.initState();
    _isTeacherView = widget.studentId != null;
    _initializeData();
  }

  Future<void> _onRefresh() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 800));
      html.window.location.reload();
    } else {
      _initializeData();
      if (mounted) setState(() {});
    }
  }

  void _initializeData() {
    _allTestsMap = {for (var test in _getAllPossibleTests()) test.key: test};
    _fetchStudentData();
    _assignSubjectColors();
  }

  @override
  void dispose() {
    _studentDataSub?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateLastSeen() async {
    if (!_isTeacherView && _studentDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_studentDocId)
            .update({'lastSeen': FieldValue.serverTimestamp()});
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  void _startLastSeenTimer() {
    _updateLastSeen();
  }

  List<TestInfo> _getAllPossibleTests() {
    final List<TestInfo> tests = [];
    final Map<String, String> standardSubjects = {
      'profession1': 'رياضيات',
      'profession2': 'لغتي',
      'profession3': 'إسلاميات',
      'profession4': 'علوم',
      'profession5': 'نشاط',
      'profession6': 'انجليزي',
      'profession7': 'اجتماعيات',
      'profession8': 'فنية',
      'profession9': 'حياتية',
      'profession10': 'بدنية',
      'profession11': 'رقمية',
      'profession12': 'تفكير',
      'profession14': 'قرآن',
      'profession15': 'تجويد',
      'profession16': 'توحيد',
      'profession17': 'فقه',
      'profession18': 'حديث',
      'profession19': 'تفسير',
      'profession20': 'أخرى',
      'profession21': 'روبوت',
      'profession22': 'قيم وسلوك',
    };

    standardSubjects.forEach((profKey, subjName) {
      tests.add(TestInfo(key: 'e1$profKey', name: 'الاختبار الأول (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e2$profKey', name: 'الاختبار الثاني (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e3$profKey', name: 'الاختبار الثالث (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e4$profKey', name: 'الاختبار الأول (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e5$profKey', name: 'الاختبار الثاني (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e6$profKey', name: 'الاختبار الثالث (دوري)', subject: subjName, testGroup: 'periodic'));

      tests.add(TestInfo(key: 'e14$profKey', name: 'اختبار قبلي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e15$profKey', name: 'اختبار بعدي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e16$profKey', name: 'اختبار احتياطي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e17$profKey', name: 'اختبار قبلي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e18$profKey', name: 'اختبار بعدي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e19$profKey', name: 'اختبار احتياطي', subject: subjName, testGroup: 'additional'));
    });

    const String nafesBaseKey = 'profession13';
    const Map<String, String> nafesSubjectShortcodes = {
      'رياضيات': 'math',
      'لغتي': 'lughati',
      'علوم': 'science',
    };

    nafesSubjectShortcodes.forEach((subjectName, shortcode) {
      tests.addAll([
        TestInfo(key: 'e1${nafesBaseKey}_$shortcode', name: 'الأول أساسي', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e2${nafesBaseKey}_$shortcode', name: 'الثاني أساسي', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e3${nafesBaseKey}_$shortcode', name: 'الاول ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e4${nafesBaseKey}_$shortcode', name: 'الثاني ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e5${nafesBaseKey}_$shortcode', name: 'الثالث ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e6${nafesBaseKey}_$shortcode', name: 'الرابع ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e7${nafesBaseKey}_$shortcode', name: 'الخامس ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e8${nafesBaseKey}_$shortcode', name: 'السادس ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e9${nafesBaseKey}_$shortcode', name: 'السابع ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e10${nafesBaseKey}_$shortcode', name: 'الثامن ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e11${nafesBaseKey}_$shortcode', name: 'التاسع ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 'e12${nafesBaseKey}_$shortcode', name: 'العاشر ف نافس', subject: subjectName, testGroup: 'nafes'),

        TestInfo(key: 't2_e1${nafesBaseKey}_$shortcode', name: 'الأول أساسي', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e2${nafesBaseKey}_$shortcode', name: 'الثاني أساسي', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e3${nafesBaseKey}_$shortcode', name: 'الاول ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e4${nafesBaseKey}_$shortcode', name: 'الثاني ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e5${nafesBaseKey}_$shortcode', name: 'الثالث ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e6${nafesBaseKey}_$shortcode', name: 'الرابع ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e7${nafesBaseKey}_$shortcode', name: 'الخامس ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e8${nafesBaseKey}_$shortcode', name: 'السادس ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e9${nafesBaseKey}_$shortcode', name: 'السابع ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e10${nafesBaseKey}_$shortcode', name: 'الثامن ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e11${nafesBaseKey}_$shortcode', name: 'التاسع ف نافس', subject: subjectName, testGroup: 'nafes'),
        TestInfo(key: 't2_e12${nafesBaseKey}_$shortcode', name: 'العاشر ف نافس', subject: subjectName, testGroup: 'nafes'),
      ]);
    });

    return tests;
  }

  void _assignSubjectColors() {
    final List<MaterialColor> vibrantColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.cyan,
      Colors.deepOrange, Colors.lightGreen, Colors.brown, Colors.blueGrey
    ];

    for (int i = 0; i < subjects.length; i++) {
      _subjectColors[subjects[i].name] = vibrantColors[i % vibrantColors.length];
    }
  }

  Future<void> _fetchStudentData() async {
    final studentDocumentId = _isTeacherView
        ? widget.studentId
        : FirebaseAuth.instance.currentUser?.uid;

    if (studentDocumentId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _studentDataSub?.cancel();
    _studentDataSub = FirebaseFirestore.instance
        .collection('students')
        .doc(studentDocumentId)
        .snapshots()
        .listen((docSnapshot) {
      if (mounted && docSnapshot.exists) {
        setState(() {
          _studentData = docSnapshot.data();
          _studentDocId = docSnapshot.id;
          _isLoading = false;
        });

        if (!_isTeacherView && _studentDocId != null && !_listenersSetup) {
          _listenersSetup = true;
          _listenForNewNotifications();
          _requestNotificationPermission();
          _startLastSeenTimer();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _requestNotificationPermission() {
    if (kIsWeb) {
      if (html.Notification.supported) {
        html.Notification.requestPermission().then((permission) {});
      }
    }
  }

  void _listenForNewNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = FirebaseFirestore.instance
        .collection('students')
        .doc(_studentDocId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      bool foundNew = false;
      String lastMessage = '';

      for (var doc in snapshot.docs) {
        if (!_processedNotificationIds.contains(doc.id)) {
          _processedNotificationIds.add(doc.id);
          foundNew = true;
          lastMessage = doc.data()['message'] ?? 'لديك إشعار جديد';
        }
      }

      if (foundNew) {
        _playNotificationSound();
        _showBrowserNotification(lastMessage);
      }
    }, onError: (error) {});
  }

  void _playNotificationSound() {
    if (kIsWeb) {
      try {
        final html.AudioElement audio = html.AudioElement('1.mp3');
        audio.play();
      } catch (e) {}
    }
  }

  void _showBrowserNotification(String message) {
    if (kIsWeb && html.Notification.supported) {
      if (html.Notification.permission == 'granted') {
        html.Notification('إشعار جديد من مدارس المعرفة',
            body: message,
            icon: 'icons/Icon-192.png');
      }
    }
  }

  void _navigateToDismissalPage() {
    if (_studentDocId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDismissalPage(
          studentId: _studentDocId!,
          studentName: _studentData?['name'] ?? 'الطالب',
          grade: _studentData?['grades'] ?? '',
          className: _studentData?['classes'] ?? '',
        ),
      ),
    );
  }

  Future<void> _promptForParentPassword() async {
    if (_studentDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ. الرجاء إعادة تسجيل الدخول.')),
      );
      return;
    }

    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? passwordCorrect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isChecking = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              contentPadding: const EdgeInsets.all(24.0),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_person_outlined,
                      size: 50,
                      color: Color(0xFF1A237E),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مطلوب إذن ولي الأمر',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, color: const Color(0xFF1A237E)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لعرض سجل الملاحظات، الرجاء إدخال كلمة مرور ولي الأمر.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      readOnly: isChecking,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF1A237E)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: <Widget>[
                TextButton(
                  onPressed: isChecking ? null : () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  icon: isChecking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: Text(isChecking ? 'جاري التحقق...' : 'دخول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isChecking ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isChecking = true);

                      try {
                        final docSnapshot = await FirebaseFirestore.instance
                            .collection('students')
                            .doc(_studentDocId!)
                            .get();

                        final studentData = docSnapshot.data();
                        final String? correctPassword = studentData?['pp']?.toString();

                        final enteredPassword = passwordController.text;

                        if (correctPassword != null && correctPassword == enteredPassword) {
                          if (!context.mounted) return;
                          Navigator.of(context).pop(true);
                          _safeSetState(() { _currentView = StudentView.teacherComplaints; });
                        } else {
                          if (!context.mounted) return;
                          Navigator.of(context).pop(false);
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop(false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (passwordCorrect == true) {
      setState(() => _currentView = StudentView.teacherComplaints);
    } else {
      if(passwordController.text.isNotEmpty){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('كلمة المرور غير صحيحة.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 40.0,
        color: const Color(0xFF1A237E),
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            _buildBody(),
            if (_isPrinting)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      SizedBox(height: 20),
                      Text(
                        'جاري إنشاء ملف PDF...',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  AppBar _buildAppBar() {
    bool isDashboard = _currentView == StudentView.dashboard;
    final studentName = _studentData?['name'] ?? '';

    Widget titleWidget;
    String baseTitle;

    switch (_currentView) {
      case StudentView.results:
        baseTitle = 'النتائج والتحليل الدراسي';
        break;
      case StudentView.noble:
        baseTitle = 'قاعة الشرف وسجل الانضباط';
        break;
      case StudentView.teacherComplaints:
        baseTitle = 'سجل الملاحظات السلوكية';
        break;
      default:
        baseTitle = _isTeacherView ? 'تقرير الطالب: $studentName' : 'الرئيسية';
    }

    titleWidget = Text(
      baseTitle,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    List<Widget> appBarActions = [];
    if (isDashboard && !_isTeacherView) {
      appBarActions.addAll(_buildDashboardActions());
    }

    appBarActions.add(
      Tooltip(
        message: 'تحديث الصفحة',
        child: GestureDetector(
          onTap: () {
            if (kIsWeb) {
              html.window.location.reload();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/2.png', color: Colors.white),
          ),
        ),
      ),
    );

    return AppBar(
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      elevation: 0,
      title: titleWidget,
      centerTitle: true,
      leading: (_isTeacherView && isDashboard) || !isDashboard
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          if (!isDashboard) {
            setState(() => _currentView = StudentView.dashboard);
          } else {
            Navigator.of(context).pop();
          }
        },
      )
          : null,
      actions: appBarActions,
      automaticallyImplyLeading: !isDashboard || _isTeacherView,
      bottom: (isDashboard && !_isTeacherView)
          ? PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: Container(
          height: 30.0,
          alignment: Alignment.center,
          color: const Color(0xFFC5A059),
          child: AnimatedTextKit(
            animatedTexts: [
              RotateAnimatedText(
                'المعرفة الاهلية - بوابتكم للتميز',
                textAlign: TextAlign.center,
                textStyle: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                  fontFamily: 'Cairo',
                ),
              ),
              RotateAnimatedText(
                'نصنع المستقبل بإبداع اليوم',
                textAlign: TextAlign.center,
                textStyle: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
            repeatForever: true,
            pause: const Duration(milliseconds: 2000),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Lottie.network('3.json'),
        ),
      );
    }
    if (_studentData == null) {
      return ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.4),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('عفواً، لم يتم العثور على بيانات الطالب.', style: TextStyle(color: Color(0xFF1A237E))),
                  const SizedBox(height: 20),
                  if (!_isTeacherView)
                    ElevatedButton(
                      onPressed: _signOutAndGoToLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                      child: const Text('العودة لتسجيل الدخول'),
                    )
                ],
              ),
            ),
          ]
      );
    }

    switch (_currentView) {
      case StudentView.results:
        return StudentResultsView(
          studentData: _studentData!,
          allTestsMap: _allTestsMap,
          subjects: subjects,
          subjectColors: _subjectColors,
          printKey: _printKey,
        );
      case StudentView.noble:
        return NobleStudentDashboard(studentId: _studentDocId!);
      case StudentView.teacherComplaints:
        return _buildTeacherComplaintsView();
      default:
        return _buildDashboard();
    }
  }

  void _showPlaceholderSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDashboard() {
    final int totalLikes = _studentData?['totalLikes'] ?? 0;
    final int totalDislikes = _studentData?['totalDislikes'] ?? 0;
    final String shortName = (_studentData?['name'] ?? 'الطالب').toString().split(' ').first;

    final Map<String, String> imageMap = {
      'النتائج والتحليل': 'assets/a13.png',
      'الطالب المنضبط': 'assets/a1.png',
      'الملاحظات السلوكية': 'assets/a9.png',
      'الشهادات': 'assets/a2.png',
      'الكتاب المدرسي': 'assets/a3.png',
      'ملف الإنجاز': 'assets/a5.png',
      'استديو الطالب': 'assets/a11.png',
      'التوكاتسو ': 'assets/a4.png',
      'المسابقات': 'assets/a10.png',
      'المؤذن': 'assets/a6.png',
    };

    final List<_DashboardButtonData> buttonDataList = [
      _DashboardButtonData(
        title: 'انصراف $shortName',
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF00ACC1),
        onTap: _navigateToDismissalPage,
        isFeatured: true,
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'النتائج والتحليل',
        icon: Icons.bar_chart_rounded,
        assetPath: imageMap['النتائج والتحليل'],
        color: const Color(0xFF1A237E),
        onTap: () => setState(() => _currentView = StudentView.results),
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الطالب المنضبط',
        icon: Icons.thumb_up,
        assetPath: imageMap['الطالب المنضبط'],
        color: const Color(0xFF2E7D32),
        badgeText: totalLikes > 0 ? '$totalLikes' : null,
        onTap: () => setState(() => _currentView = StudentView.noble),
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الملاحظات السلوكية',
        icon: Icons.report_problem_outlined,
        assetPath: imageMap['الملاحظات السلوكية'],
        color: const Color(0xFFC62828),
        badgeText: totalDislikes > 0 ? '$totalDislikes' : null,
        onTap: _promptForParentPassword,
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الكتاب المدرسي',
        icon: Icons.menu_book,
        assetPath: imageMap['الكتاب المدرسي'],
        color: const Color(0xFFC5A059),
        onTap: () {
          final String grade = _studentData?['grades'] ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SchoolBooksPage(grade: grade)),
          );
        },
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'التوكاتسو ',
        icon: Icons.emoji_events,
        assetPath: imageMap['التوكاتسو '],
        color: const Color(0xFFF57F17),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TokkatsuViewPage()),
          );
        },
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الشهادات والتقدير',
        icon: Icons.workspace_premium_rounded,
        assetPath: imageMap['الشهادات'],
        color: const Color(0xFF4527A0),
        onTap: () {
          if (_studentDocId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentCertificatesPage(studentData: _studentData!, studentId: _studentDocId!)),
            );
          }
        },
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'ملف الإنجاز',
        icon: Icons.folder_shared_rounded,
        assetPath: imageMap['ملف الإنجاز'],
        color: const Color(0xFF00695C),
        onTap: () {
          if (_studentDocId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentPortfolioPage(studentId: _studentDocId!, studentData: {},)),
            );
          }
        },
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'استديو الطالب',
        icon: Icons.photo_library,
        assetPath: imageMap['استديو الطالب'],
        color: const Color(0xFFE65100),
        onTap: () => _showPlaceholderSnackBar('لا يوجد صور لك متوفرة حالياً.'),
        isWorking: false,
      ),
      _DashboardButtonData(
        title: 'المسابقات',
        icon: Icons.military_tech,
        assetPath: imageMap['المسابقات'],
        color: const Color(0xFF558B2F),
        onTap: () => _showPlaceholderSnackBar('لا توجد مسابقات حالية الآن.'),
        isWorking: false,
      ),
      _DashboardButtonData(
        title: 'المؤذن',
        icon: Icons.mic,
        assetPath: imageMap['المؤذن'],
        color: const Color(0xFF0277BD),
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
        isWorking: false,
      ),
    ];

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC5A059), width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                backgroundImage: (_studentData != null &&
                    _studentData!.containsKey('photo') &&
                    _studentData!['photo'] != null &&
                    _studentData!['photo'].toString().isNotEmpty)
                    ? NetworkImage(_studentData!['photo'])
                    : null,
                child: (_studentData == null ||
                    !_studentData!.containsKey('photo') ||
                    _studentData!['photo'] == null ||
                    _studentData!['photo'].toString().isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFF1A237E), size: 26)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مرحباً، ${_studentData?['name'] ?? '...'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A059),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_studentData?['grades'] ?? ''} - ${_studentData?['classes'] ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: 0.8,
              child: Icon(Icons.school_outlined, color: Colors.white.withOpacity(0.2), size: 50),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        buildHeader(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AnimationLimiter(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buttonDataList.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final data = buttonDataList[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: (MediaQuery.of(context).size.width / 160).floor(),
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              width: double.infinity,
                              child: _buildDashboardButton(
                                icon: data.icon,
                                assetPath: data.assetPath,
                                color: data.color,
                                onTap: data.onTap,
                                badgeText: data.badgeText,
                                isWorking: data.isWorking,
                                isFeatured: data.isFeatured,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 1,
                            child: Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDashboardButton({
    required IconData icon,
    String? assetPath,
    required Color color,
    required VoidCallback onTap,
    String? badgeText,
    required bool isWorking,
    bool isFeatured = false,
  }) {
    final bool isNobleButton = icon == Icons.thumb_up;
    final String? nobleCount = isNobleButton && badgeText != null ? badgeText : null;

    return _AnimatedScaleButton(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: isFeatured
                  ? Border.all(color: const Color(0xFFC5A059), width: 2)
                  : Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (assetPath != null && assetPath.isNotEmpty)
                      ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(icon, size: 40, color: color),
                        );
                      },
                    ),
                  )
                      : Center(
                    child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle
                        ),
                        child: Icon(icon, size: 36, color: color)),
                  ),

                  if (isNobleButton && nobleCount != null)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Text(
                          nobleCount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isFeatured)
            Positioned(
              top: -8,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD50000),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  "سريع",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.1, duration: 800.ms),
            ),

          if (badgeText != null && !isNobleButton)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 8,
            left: 8,
            child: Tooltip(
              message: isWorking ? 'خدمة مفعلة' : 'قيد التطوير',
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
                  ],
                ),
                child: Icon(
                  isWorking ? Icons.check_circle_rounded : Icons.settings_suggest_rounded,
                  size: 16,
                  color: isWorking ? Colors.green : Colors.orange.shade400,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTeacherComplaintsView() {
    if (_studentDocId == null) {
      return ListView(children: [const SizedBox(height: 300), const Center(child: Text("لا يمكن عرض الملاحظات. الطالب غير معرّف.", style: TextStyle(color: Color(0xFF1A237E))))]);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('behavior_reports')
          .where('studentId', isEqualTo: _studentDocId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['type'] == 'dislike' || data.containsKey('teacherNote');
        }).toList();

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['timestamp'] as Timestamp?;
          final bTime = bData['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'سجلك السلوكي نظيف!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                    Text(
                      'لم يتم تسجيل أي ملاحظات سلبية عليك.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _DislikeCard(
              reportDoc: doc,
              studentName: _studentData?['name'] ?? 'الطالب',
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDashboardActions() {
    return [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcast_notifications')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          final bool hasNews = count > 0;

          Widget iconWidget = IconButton(
            icon: Icon(
              Icons.notifications_active,
              color: hasNews ? const Color(0xFFC5A059) : Colors.white,
              size: 28,
            ),
            tooltip: 'التعاميم العامة',
            onPressed: () => _showNotifications(0),
          );

          if (hasNews) {
            iconWidget = iconWidget.animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white)
                .then()
                .shake(hz: 4, curve: Curves.easeInOutCubic);
          }

          return badges.Badge(
            showBadge: hasNews,
            badgeContent: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.redAccent,
              padding: const EdgeInsets.all(6),
              elevation: 4,
            ),
            position: badges.BadgePosition.topEnd(top: -5, end: -5),
            child: Container(
              decoration: hasNews ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC5A059).withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ) : null,
              child: iconWidget,
            ),
          );
        },
      ),

      StreamBuilder<QuerySnapshot>(
        stream: _studentDocId == null
            ? null
            : FirebaseFirestore.instance
            .collection('students')
            .doc(_studentDocId)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return badges.Badge(
            showBadge: count > 0,
            badgeContent: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            badgeStyle: badges.BadgeStyle(badgeColor: Colors.red),
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              tooltip: 'إشعاراتي',
              onPressed: () => _showNotifications(1),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.person_outline, color: Colors.white),
        tooltip: 'الملف الشخصي',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const StudentProfilePage())),
      ),
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        tooltip: 'تسجيل الخروج',
        onPressed: _signOutAndGoToLogin,
      ),
    ];
  }

  void _showNotifications(int initialIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialIndex,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              _markNotificationsAsRead();

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("مركز الإشعارات",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  ),
                  const TabBar(
                    labelColor: Color(0xFF1A237E),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFFC5A059),
                    tabs: [
                      Tab(text: "تعاميم عامة"),
                      Tab(text: "إشعارات خاصة"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildNotificationList(
                          stream: FirebaseFirestore.instance
                              .collection('broadcast_notifications')
                              .orderBy('timestamp', descending: true)
                              .limit(50)
                              .snapshots(),
                          isPublic: true,
                          scrollController: scrollController,
                        ),

                        _buildNotificationList(
                          stream: _studentDocId == null
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                              .collection('students')
                              .doc(_studentDocId)
                              .collection('notifications')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          isPublic: false,
                          scrollController: scrollController,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationList({required Stream<QuerySnapshot> stream, required bool isPublic, required ScrollController scrollController}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPublic ? Icons.public_off : Icons.notifications_off, size: 50, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  isPublic ? "لا توجد تعاميم مدرسية." : "لا توجد إشعارات خاصة.",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            Timestamp? ts = data['timestamp'];
            String formattedDate = ts != null
                ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(ts.toDate())
                : '..';

            String title = data['title'] ?? (isPublic ? 'إشعار عام' : 'تنبيه سلوكي');
            String body = data['message'] ?? data['body'] ?? data['reason'] ?? 'لا يوجد تفاصيل';
            String senderName = isPublic ? (data['senderName'] ?? 'الإدارة') : 'النظام';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPublic ? Colors.green.withOpacity(0.1) : const Color(0xFF1A237E).withOpacity(0.1),
                child: Icon(
                  isPublic ? Icons.campaign : Icons.person,
                  color: isPublic ? Colors.green.shade700 : const Color(0xFF1A237E),
                ),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body, style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formattedDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (isPublic) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(senderName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ]
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markNotificationsAsRead() async {
    if (_studentDocId == null) return;
    final notificationsRef = FirebaseFirestore.instance
        .collection('students')
        .doc(_studentDocId)
        .collection('notifications');
    final unreadNotifs =
    await notificationsRef.where('isRead', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadNotifs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    _processedNotificationIds.clear();
  }

  Future<void> _signOutAndGoToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }
}

class _DislikeCard extends StatefulWidget {
  final DocumentSnapshot reportDoc;
  final String studentName;

  const _DislikeCard({required this.reportDoc, required this.studentName});

  @override
  _DislikeCardState createState() => _DislikeCardState();
}

class _DislikeCardState extends State<_DislikeCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showReplySheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _replyController = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> _submitReply() async {
              if (!_formKey.currentState!.validate()) return;
              setModalState(() => _isSubmitting = true);

              try {
                final reportRef = FirebaseFirestore.instance
                    .collection('behavior_reports')
                    .doc(widget.reportDoc.id);

                await reportRef.update({
                  'studentReply': _replyController.text.trim(),
                  'replyTimestamp': FieldValue.serverTimestamp(),
                  'status': 'replied_by_student',
                });

                setModalState(() => _isSubmitting = false);

                if (Navigator.of(ctx).canPop()) {
                  Navigator.pop(ctx);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال ردك بنجاح.'),
                    backgroundColor: Colors.green,
                  ),
                );

              } catch (e) {
                setModalState(() => _isSubmitting = false);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ أثناء إرسال الرد.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded, color: Color(0xFF1A237E)),
                        const SizedBox(width: 12),
                        Text(
                          'الرد على الملاحظة',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _replyController,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'اكتب ردك هنا لتوضيح الموقف',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E))),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'الرجاء كتابة ردك';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: _isSubmitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_rounded),
                              label: Text(_isSubmitting ? 'جاري الإرسال...' : 'إرسال الرد'),
                              onPressed: _isSubmitting ? null : _submitReply,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConversationBubble(BuildContext context, {
    required bool isMe,
    required String author,
    required String text,
    required Timestamp? timestamp,
    bool isFinal = false,
  }) {
    final formattedDate = timestamp != null
        ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(timestamp.toDate())
        : '...';
    final Color bubbleColor = isMe
        ? (isFinal ? Colors.grey.shade200 : const Color(0xFF1A237E).withOpacity(0.1))
        : Colors.green.withOpacity(0.1);
    final Color textColor = isMe && isFinal ? Colors.black54 : Colors.black87;

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(author, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
          child: Text(formattedDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportDoc.data() as Map<String, dynamic>;
    final teacherName = data['teacherName'] ?? 'معلم';
    final teacherId = data['teacherId'];
    final subject = data['subject'] ?? 'مادة';

    final teacherNote = data['reason'] ?? data['teacherNote'] ?? 'لم يتم كتابة تفاصيل السلوك.';

    final studentReply = data['studentReply'] as String?;
    final teacherFinalReply = data['teacherFinalReply'] as String?;
    final status = data['status'];

    final timestamp = data['timestamp'] as Timestamp?;
    final replyTimestamp = data['replyTimestamp'] as Timestamp?;
    final finalReplyTimestamp = data['teacherFinalReplyTimestamp'] as Timestamp?;

    String statusText;
    Color statusColor;

    switch (status) {
      case 'replied_by_student':
        statusText = 'بانتظار رد المعلم';
        statusColor = Colors.blue.shade300;
        break;
      case 'closed':
        statusText = 'مغلقة';
        statusColor = Colors.grey;
        break;
      default:
        statusText = 'مطلوب الرد';
        statusColor = Colors.red.shade300;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.red.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: InkWell(
                onTap: () {
                  if (teacherId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        TeacherProfileViewPage(teacherId: teacherId)));
                  }
                },
                child: Text(
                  "أ. $teacherName",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
              ),
              subtitle: Text("مادة: $subject"),
              trailing: Chip(
                label: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: statusColor,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Divider(),

            _buildConversationBubble(
              context,
              isMe: true,
              author: 'ملاحظة المعلم',
              text: teacherNote,
              timestamp: timestamp,
            ),

            if (studentReply != null && studentReply.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildConversationBubble(
                context,
                isMe: false,
                author: 'رد ولي الأمر',
                text: studentReply,
                timestamp: replyTimestamp,
              ),
            ],

            if (teacherFinalReply != null && teacherFinalReply.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildConversationBubble(
                context,
                isMe: true,
                author: 'الرد النهائي للمعلم',
                text: teacherFinalReply,
                timestamp: finalReplyTimestamp,
                isFinal: true,
              ),
            ],

            if (status != 'replied_by_student' && status != 'closed') ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('الرد على الملاحظة'),
                  onPressed: () => _showReplySheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedScaleButton({required this.child, required this.onTap});

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class TokkatsuItem {
  final String imagePath;
  final String title;
  final String description;

  const TokkatsuItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class TokkatsuViewPage extends StatefulWidget {
  const TokkatsuViewPage({super.key});

  @override
  State<TokkatsuViewPage> createState() => _TokkatsuViewPageState();
}

class _TokkatsuViewPageState extends State<TokkatsuViewPage> {
  final List<TokkatsuItem> tokkatsuItems = const [
    TokkatsuItem(
      imagePath: 'assets/m1.png',
      title: 'المقدمة',
      description: 'أهلاً بكم في رحلة التوكاتسو. هذا النظام ليس مجرد أنشطة، بل هو أسلوب حياة يهدف لبناء شخصية متوازنة ومبدعة قادرة على مواجهة تحديات المستقبل.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t9.png',
      title: 'ما هو التوكاتسو؟',
      description: 'التوكاتسو هي أنشطة لا صفية يابانية، تركز على تنمية المهارات غير المعرفية مثل: التعاون، الانضباط، الاحترام، والعمل الجماعي، لبناء المواطن الصالح.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t8.png',
      title: 'الفائدة والأثر',
      description: 'يهدف التوكاتسو إلى تحسين البيئة المدرسية، تعزيز الثقة بالنفس، وتنمية القدرة على حل المشكلات واتخاذ القرارات، مما يخلق جيلاً مبدعاً ومسؤولاً.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t1.png',
      title: 'نظافة الفصل',
      description: 'يتولى الطلاب بأنفسهم مسؤولية تنظيف وترتيب فصلهم بشكل يومي، مما يغرس فيهم قيم التواضع والمسؤولية والانتماء للمكان.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t2.png',
      title: 'مجلس الفصل',
      description: 'جلسات نقاشية ديمقراطية يديرها الطلاب بأنفسهم لمناقشة التحديات، وضع القوانين الصفية، واتخاذ القرارات الجماعية.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t3.png',
      title: 'المناقشة التوجيهية',
      description: 'تعلم آداب الحوار الراقي، الاستماع الجيد للآخرين، احترام اختلاف وجهات النظر، والوصول إلى توافق يرضي الجميع.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t4.png',
      title: 'الريادة اليومية',
      description: 'نظام تبادل الأدوار القيادية، حيث يكون كل طالب قائداً للفصل ليوم واحد، مما يكسر حاجز الخوف وينمي المهارات القيادية.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t5.png',
      title: 'النظافة الشخصية',
      description: 'ترسيخ عادات العناية بالمظهر العام، غسل الأيدي، والوقاية الصحية كأسلوب حياة يومي وليس مجرد تعليمات.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t6.png',
      title: 'الأنشطة الصفية',
      description: 'التعلم الممتع من خلال الأنشطة الجماعية والألعاب الهادفة التي تعزز روح الفريق والمنافسة الإيجابية.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t7.png',
      title: 'تحمل المسؤولية',
      description: 'تنمية الوعي بالمسؤولية الفردية والجماعية تجاه المجتمع المدرسي، والمحافظة على الممتلكات العامة.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'أنشطة التوكاتسو',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: isWideScreen ? 0 : 16.0,
            ),
            itemCount: tokkatsuItems.length,
            itemBuilder: (context, index) {
              return _buildResponsiveCard(tokkatsuItems[index], isWideScreen);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveCard(TokkatsuItem item, bool isWideScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: isWideScreen ? 21 / 9 : 16 / 9,
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    height: 1.7,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SchoolBooksPage extends StatelessWidget {
  final String grade;

  const SchoolBooksPage({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكتب والمقررات الدراسية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A237E).withOpacity(0.05), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, "المقررات الأساسية", Icons.menu_book),
            _buildDigitalSkillsCard(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "برامج إثرائية عالمية", Icons.science),
            _buildStemBookCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalSkillsCard(BuildContext context) {
    String title = "المهارات الرقمية";
    Widget content;
    Color cardColor = Colors.blue.shade50;

    if (['الصف الأول', 'الصف الثاني', 'الصف الثالث'].contains(grade)) {
      content = _buildInfoContent(
        icon: Icons.local_library_rounded,
        title: "نسخة ورقية",
        text: "عزيزي الطالب، يتم تسليم النسخة الورقية من كتاب المهارات الرقمية لك مباشرة في المدرسة.",
        color: const Color(0xFF1A237E),
      );
    }
    else if (grade == 'الصف الرابع') {
      content = _buildLinkContent(
        context,
        url: "https://ktby.net/10767/",
        desc: "كتاب المهارات الرقمية - الصف الرابع (نسخة إلكترونية)",
        btnText: "تصفح الكتاب الآن",
      );
      cardColor = const Color(0xFF1A237E).withOpacity(0.05);
    }
    else if (grade == 'الصف الخامس') {
      content = _buildLinkContent(
        context,
        url: "https://ktby.net/10769/",
        desc: "كتاب المهارات الرقمية - الصف الخامس (نسخة إلكترونية)",
        btnText: "تصفح الكتاب الآن",
      );
      cardColor = const Color(0xFF1A237E).withOpacity(0.05);
    }
    else if (grade == 'الصف السادس') {
      content = _buildLinkContent(
        context,
        url: "https://ktby.net/10770/",
        desc: "كتاب المهارات الرقمية - الصف السادس (نسخة إلكترونية)",
        btnText: "تصفح الكتاب الآن",
      );
      cardColor = const Color(0xFF1A237E).withOpacity(0.05);
    }
    else {
      content = _buildInfoContent(
        icon: Icons.info_outline_rounded,
        title: "تنبيه",
        text: "يرجى مراجعة إدارة المدرسة لاستلام الكتب المقررة لصفك.",
        color: Colors.grey.shade700,
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.laptop_mac, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildStemBookCard(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.precision_manufacturing, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("مقرر الروبوت (STEM العالمي)",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("بوابة المستقبل والاختراع",
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint("يُعنى هذا المقرر بتنمية مهارات الاختراع والابتكار لدى الطالب."),
                _buildBulletPoint("يساعد الطلاب بشكل مباشر على اكتشاف مواهبهم التقنية والهندسية."),
                _buildBulletPoint("منهج عالمي معتمد يفتح آفاقاً واسعة للمستقبل."),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "ملاحظة: يتم تسليم الطالب الكتاب في جميع صفوف المرحلة الابتدائية بطلب مباشر من حضراتكم.",
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text("طلب الكتاب عبر واتساب (أ. يحيي)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse('https://wa.me/966502649649');
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('لا يمكن فتح الواتساب')));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFFC5A059), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildInfoContent({required IconData icon, required String title, required String text, required Color color}) {
    return Column(
      children: [
        Icon(icon, size: 48, color: color.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildLinkContent(BuildContext context, {required String url, required String desc, required String btnText}) {
    return Column(
      children: [
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(btnText),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final Uri uri = Uri.parse(url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا يمكن فتح الرابط')));
              }
            },
          ),
        ),
      ],
    );
  }
}

class StudentPortfolioPage extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentPortfolioPage({super.key, required this.studentId, required this.studentData});

  @override
  State<StudentPortfolioPage> createState() => _StudentPortfolioPageState();
}

class _StudentPortfolioPageState extends State<StudentPortfolioPage> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      final int fileSize = await pickedFile.length();
      if (fileSize > 40 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حجم الملف كبير جداً (أكثر من 40 ميجا)'), backgroundColor: Colors.red)
        );
        return;
      }

      final String? caption = await _showCaptionDialog();
      if (caption == null) return;

      setState(() => _isUploading = true);

      Uint8List fileBytes = await pickedFile.readAsBytes();
      final String fileName = '${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String tgCaption = '📸 ملف إنجاز جديد (ألبوم الصور)\n👤 معرف الطالب: ${widget.studentId}\n📝 الوصف: $caption';

      String? fileId = await TelegramStorage.uploadDocument(fileBytes, fileName, tgCaption);

      if (fileId != null) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .collection('portfolio')
            .add({
          'imageUrl': fileId,
          'caption': caption,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الصورة إلى ملف إنجازك بنجاح ✅'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("فشل الاتصال");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> _showCaptionDialog() async {
    final TextEditingController captionController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("وصف الصورة", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اكتب تعليقاً بسيطاً تحت صورتك"),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: "أدخل النص هنا...",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, captionController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
              child: const Text("نشر"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteImage(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف الصورة", style: TextStyle(color: Color(0xFF1A237E))),
        content: const Text("هل أنت متأكد من حذف هذه الصورة من ملف إنجازك؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("تراجع")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('portfolio')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحذف بنجاح")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("حدث خطأ أثناء الحذف")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = FirebaseAuth.instance.currentUser?.uid == widget.studentId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف إنجازي (ألبوم الصور)', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: isMe
          ? FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        backgroundColor: const Color(0xFFC5A059),
        icon: _isUploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.add_a_photo, color: Color(0xFF1A237E)),
        label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة', style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
      )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A237E).withOpacity(0.05), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .doc(widget.studentId)
              .collection('portfolio')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('ألبوم صورك فارغ حالياً', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    if (isMe)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("اضغط على زر الإضافة لرفع شهاداتك وصورك", style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              );
            }

            return AnimationLimiter(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String fileId = data['imageUrl'] ?? '';
                  final String caption = data['caption'] ?? '';

                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () => _showFullImage(context, fileId, caption),
                          onLongPress: isMe ? () => _deleteImage(doc.id) : null,
                          child: Hero(
                            tag: fileId,
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              clipBehavior: Clip.antiAlias,
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: SmartTelegramImage(fileId: fileId, fit: BoxFit.cover),
                                  ),
                                  if (caption.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      color: Colors.white,
                                      child: Text(
                                        caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A237E),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String fileId, String caption) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: fileId,
                    child: SmartTelegramImage(fileId: fileId, fit: BoxFit.contain),
                  ),
                ),
              ),
              if (caption.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentCertificatesPage extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const StudentCertificatesPage({super.key, required this.studentData, required this.studentId});

  @override
  State<StudentCertificatesPage> createState() => _StudentCertificatesPageState();
}

class _StudentCertificatesPageState extends State<StudentCertificatesPage> {
  bool _isLoadingArchive = true;
  List<String> _archiveYears = [];
  Map<String, Map<String, dynamic>> _archivesData = {};
  String? _selectedArchiveYear;

  @override
  void initState() {
    super.initState();
    _fetchArchives();
  }

  Future<void> _fetchArchives() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('archives')
          .get();

      if (snap.docs.isNotEmpty) {
        final List<String> years = snap.docs.map((d) => d.id).toList();
        years.sort((a, b) => b.compareTo(a));

        final Map<String, Map<String, dynamic>> dataMap = {};
        for (var doc in snap.docs) {
          dataMap[doc.id] = doc.data() as Map<String, dynamic>;
        }

        if (mounted) {
          setState(() {
            _archiveYears = years;
            _archivesData = dataMap;
            _selectedArchiveYear = years.first;
            _isLoadingArchive = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingArchive = false);
      }
    } catch (e) {
      debugPrint("Error fetching archives: $e");
      if (mounted) setState(() => _isLoadingArchive = false);
    }
  }

  double _calculateTermPercentage(Map<String, dynamic> data, int term) {
    final Map<String, String> standardSubjects = {
      'profession1': 'رياضيات',
      'profession2': 'لغتي',
      'profession3': 'إسلاميات',
      'profession4': 'علوم',
      'profession5': 'نشاط',
      'profession6': 'انجليزي',
      'profession7': 'اجتماعيات',
      'profession8': 'فنية',
      'profession9': 'حياتية',
      'profession10': 'بدنية',
      'profession11': 'رقمية',
      'profession12': 'تفكير',
      'profession14': 'قرآن',
      'profession15': 'تجويد',
      'profession16': 'توحيد',
      'profession17': 'فقه',
      'profession18': 'حديث',
      'profession19': 'تفسير',
      'profession20': 'أخرى',
      'profession21': 'روبوت',
      'profession22': 'قيم وسلوك',
    };

    List<double> subjectPercents = [];

    standardSubjects.forEach((profKey, subjName) {
      List<num> grades = [];
      int startIdx = term == 1 ? 1 : 4;
      int endIdx = term == 1 ? 3 : 6;
      for (int i = startIdx; i <= endIdx; i++) {
        String key = 'e$i$profKey';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }
      int eStart = term == 1 ? 14 : 17;
      int eEnd = term == 1 ? 16 : 19;
      for (int i = eStart; i <= eEnd; i++) {
        String key = 'e$i$profKey';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }

      if (grades.isNotEmpty) {
        double avg = grades.reduce((a, b) => a + b) / grades.length;
        subjectPercents.add((avg / 20) * 100);
      }
    });

    final List<String> nafesKeys = ['math', 'lughati', 'science'];
    for (String n in nafesKeys) {
      List<num> grades = [];
      for (int i = 1; i <= 12; i++) {
        String key = term == 1 ? 'e${i}profession13_$n' : 't2_e${i}profession13_$n';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }
      if (grades.isNotEmpty) {
        double avg = grades.reduce((a, b) => a + b) / grades.length;
        subjectPercents.add((avg / 10) * 100);
      }
    }

    if (subjectPercents.isEmpty) return 0.0;
    return subjectPercents.reduce((a, b) => a + b) / subjectPercents.length;
  }

  Future<Map<String, dynamic>> _fetchTermStats(int term, {Map<String, dynamic>? customData}) async {
    final data = customData ?? widget.studentData;
    double myPercent = _calculateTermPercentage(data, term);
    if (myPercent == 0.0) return {'percent': 0.0, 'rank': -1, 'subjects': [], 'likes': 0, 'maxLikes': 0};

    final Map<String, String> standardSubjects = {
      'profession1': 'رياضيات', 'profession2': 'لغتي', 'profession3': 'إسلاميات',
      'profession4': 'علوم', 'profession6': 'انجليزي', 'profession7': 'اجتماعيات',
      'profession8': 'فنية', 'profession10': 'بدنية', 'profession11': 'رقمية', 'profession12': 'تفكير',
      'profession20': 'أخرى', 'profession21': 'روبوت', 'profession22': 'قيم وسلوك',
    };

    List<Map<String, dynamic>> subjectGrades = [];

    standardSubjects.forEach((profKey, subjName) {
      List<num> grades = [];
      int startIdx = term == 1 ? 1 : 4;
      int endIdx = term == 1 ? 3 : 6;
      for (int i = startIdx; i <= endIdx; i++) {
        String key = 'e$i$profKey';
        if (data[key] != null && data[key] is num && data[key] >= 0) {
          grades.add(data[key]);
        }
      }
      if (grades.isNotEmpty) {
        double avg = grades.reduce((a, b) => a + b) / grades.length;
        subjectGrades.add({'name': subjName, 'percent': ((avg / 20) * 100).clamp(0, 100)});
      }
    });

    int myLikes = data['totalLikes'] ?? data['likes'] ?? 0;
    int rank = -1;
    int maxLikes = myLikes;

    if (customData == null) {
      String grade = data['grades'] ?? '';
      String className = data['classes'] ?? '';

      final schoolMaxSnap = await FirebaseFirestore.instance.collection('students')
          .orderBy('totalLikes', descending: true)
          .limit(1)
          .get();

      if (schoolMaxSnap.docs.isNotEmpty) {
        final maxData = schoolMaxSnap.docs.first.data();
        maxLikes = maxData['totalLikes'] ?? maxData['likes'] ?? 0;
      }

      final snap = await FirebaseFirestore.instance.collection('students')
          .where('grades', isEqualTo: grade)
          .where('classes', isEqualTo: className)
          .get();

      List<Map<String, dynamic>> allStudents = [];
      for(var doc in snap.docs) {
        double p = _calculateTermPercentage(doc.data(), term);
        allStudents.add({'id': doc.id, 'percent': p});
      }

      allStudents.sort((a,b) => b['percent'].compareTo(a['percent']));
      rank = allStudents.indexWhere((s) => s['id'] == widget.studentId) + 1;

      if (myLikes > maxLikes) {
        maxLikes = myLikes;
      }
    }

    return {
      'percent': myPercent,
      'rank': rank,
      'subjects': subjectGrades,
      'likes': myLikes,
      'maxLikes': maxLikes
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('settings').doc('terms_locks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          bool term1Locked = false;
          bool term2Locked = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            term1Locked = data?['term1_locked'] ?? false;
            term2Locked = data?['term2_locked'] ?? false;
          }
          int initialIndex = 0;

          return DefaultTabController(
            key: const ValueKey('cert_tabs_force_first'),
            length: 3,
            initialIndex: initialIndex,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('الشهادات والتقدير', style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                bottom: const TabBar(
                  indicatorColor: Color(0xFFC5A059),
                  indicatorWeight: 4,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: "الترم الأول"),
                    Tab(text: "الترم الثاني"),
                    Tab(text: "الأرشيف"),
                  ],
                ),
              ),
              body: Container(
                color: Colors.grey.shade100,
                child: TabBarView(
                  children: [
                    _buildTermView(1, term1Locked),
                    _buildTermView(2, term2Locked),
                    _buildArchiveView(),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildArchiveView() {
    if (_isLoadingArchive) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_archiveYears.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد أرشيف شهادات لسنوات سابقة.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade200, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedArchiveYear,
              isExpanded: true,
              icon: const Icon(Icons.history, color: Color(0xFF1A237E)),
              items: _archiveYears.map((String year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(
                    'نتائج العام الدراسي: $year',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedArchiveYear = newValue);
                }
              },
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              if (_selectedArchiveYear != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("الترم الأول", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                ),
                _buildArchiveTermView(1, _archivesData[_selectedArchiveYear!]!),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(thickness: 2, height: 40),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("الترم الثاني", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                ),
                _buildArchiveTermView(2, _archivesData[_selectedArchiveYear!]!),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveTermView(int term, Map<String, dynamic> archiveData) {
    return FutureBuilder<Map<String, dynamic>>(
        future: _fetchTermStats(term, customData: archiveData),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          }
          final percent = snapshot.data?['percent'] ?? 0.0;
          if (percent == 0.0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                    "لا توجد شهادة محفوظة للترم ${term == 1 ? 'الأول' : 'الثاني'} في هذا العام.",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                ),
              ),
            );
          }

          final int rank = snapshot.data?['rank'] ?? -1;
          final List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(snapshot.data?['subjects'] ?? []);
          final int studentLikes = snapshot.data?['likes'] ?? 0;
          final int maxLikes = snapshot.data?['maxLikes'] ?? 0;
          final String studentName = archiveData['name'] ?? 'الطالب';
          final String termName = term == 1 ? 'الترم الأول' : 'الترم الثاني';

          return Column(
              children: [
                _buildFrontPage(studentName, termName, percent, rank, studentLikes, maxLikes, isArchive: true, archiveYear: _selectedArchiveYear),
                _buildBackPage(term, termName, percent, rank, subjects),
              ]
          );
        }
    );
  }

  Widget _buildCertificateContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5A059), Color(0xFFFFF1C5), Color(0xFFC5A059)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFrontPage(String studentName, String termName, double percent, int rank, int studentLikes, int maxLikes, {bool isArchive = false, String? archiveYear}) {
    String rankText = (rank > 0 && rank <= 10 && !isArchive) ? ' وحصوله على المركز (الـ $rank) على مستوى المرحلة،' : '';
    String goldenLikeSvgRaw = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#D4AF37"><path d="M1 21h4V9H1v12zm22-11c0-1.1-.9-2-2-2h-6.31l.95-4.57.03-.32c0-.41-.17-.79-.44-1.06L14.17 1 7.59 7.59C7.22 7.95 7 8.45 7 9v10c0 1.1.9 2 2 2h9c.83 0 1.54-.5 1.84-1.22l3.02-7.05c.09-.23.14-.47.14-.73v-2z"/></svg>''';

    return _buildCertificateContainer(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/m1.png', width: 85, height: 85, fit: BoxFit.contain),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: SvgPicture.asset(
                          percent >= 90.0 ? 'assets/sh1.svg' : 'assets/sh2.svg',
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Image.asset('assets/2.png', width: 60, height: 60, fit: BoxFit.contain),
                  ]
              ),
              const SizedBox(height: 20),
              const Text("تسر إدارة المدرسة أن تمنح هذا التقدير للطالب:", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(studentName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
              const SizedBox(height: 12),
              Text("للعام الدراسي ${isArchive ? archiveYear : '1445 / 1446 هـ'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 16),
              Text(
                  "لتفوقه واجتهاده الملحوظ خلال $termName (التقييم التراكمي)، وحصوله على نسبة ${percent.toStringAsFixed(1)}%$rankText\nمتمنين له دوام التوفيق والنجاح.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.6, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(goldenLikeSvgRaw, width: 22, height: 22),
                  const SizedBox(width: 8),
                  Text(
                    'وقد حصل الطالب علي نقاط $studentLikes من أصل $maxLikes',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                        children: [
                          const Text('مدير المدرسة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1A237E))),
                          const SizedBox(height: 25),
                          const Text('أ. عبدالله عائش المطرفي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        ]
                    )
                  ]
              )
            ]
        )
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildBackPage(int term, String termName, double overallPercent, int rank, List<Map<String, dynamic>> subjects) {
    return _buildCertificateContainer(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/m1.png', width: 40, height: 40),
                  Text("مستوي - $termName", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  Image.asset('assets/2.png', width: 40, height: 40),
                ],
              ),
              const Divider(color: Color(0xFFC5A059), thickness: 1.5),
              const SizedBox(height: 12),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatBadge("النسبة الكلية", "${overallPercent.toStringAsFixed(1)}%"),
                    if (rank > 0 && rank <= 10)
                      _buildStatBadge("الترتيب بالمرحلة", "الـ $rank", isGold: true),
                  ]
              ),
              const SizedBox(height: 16),
              ...subjects.map((sg) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sg['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        Text('${sg['percent'].toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1A237E))),
                      ]
                  )
              )).toList()
            ]
        )
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStatBadge(String title, String value, {bool isGold = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isGold ? const Color(0xFFFFF1C5) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isGold ? const Color(0xFFC5A059) : Colors.blue.shade200),
          ),
          child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isGold ? const Color(0xFFC5A059) : const Color(0xFF1A237E))),
        )
      ],
    );
  }

  Widget _buildTermView(int term, bool isLocked) {
    if (!isLocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('لم يتم اعتماد نتيجة الترم ${term == 1 ? 'الأول' : 'الثاني'} بعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('الرصد لا يزال مستمراً، ستصدر الشهادة فور إغلاق الترم من قبل الإدارة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final String studentName = widget.studentData['name'] ?? 'الطالب';
    final String termName = term == 1 ? 'الترم الأول' : 'الترم الثاني';

    return FutureBuilder<Map<String, dynamic>>(
        future: _fetchTermStats(term),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final double percent = snapshot.data?['percent'] ?? 0.0;
          final int rank = snapshot.data?['rank'] ?? -1;

          final List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(snapshot.data?['subjects'] ?? []);

          final int studentLikes = snapshot.data?['likes'] ?? 0;
          final int maxLikes = snapshot.data?['maxLikes'] ?? 0;

          if (percent == 0.0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('لا توجد درجات مرصودة لطباعة الشهادة.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildFrontPage(studentName, termName, percent, rank, studentLikes, maxLikes),
              _buildBackPage(term, termName, percent, rank, subjects),
              const SizedBox(height: 40),
            ],
          );
        }
    );
  }
}

class NobleStudentDashboard extends StatefulWidget {
  final String studentId;
  const NobleStudentDashboard({super.key, required this.studentId});

  @override
  State<NobleStudentDashboard> createState() => _NobleStudentDashboardState();
}

class _NobleStudentDashboardState extends State<NobleStudentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _categoriesCount = {};
  List<DocumentSnapshot> _studentLikes = [];
  bool _isLoading = true;

  String _selectedFilter = 'الكل';

  final List<Map<String, dynamic>> criteriaDefinitions = [
    {'title': 'السمت والصلاة', 'icon': Icons.mosque, 'color': Colors.teal, 'keywords': ['صلاة', 'دين', 'وضوء', 'أخلاق', 'قرآن', 'بر الوالدين', 'أمانة', 'صدق', 'محافظة', 'مسجد']},
    {'title': 'أدب الحوار', 'icon': Icons.record_voice_over, 'color': Colors.indigo, 'keywords': ['حوار', 'صوت', 'إنصات', 'استماع', 'أدب', 'تحدث', 'كظم', 'احترام المتحدث']},
    {'title': 'الاحترام والأخوة', 'icon': Icons.handshake, 'color': Colors.blue, 'keywords': ['احترام', 'أخوة', 'زملاء', 'زميله', 'إصلاح', 'علاقة']},
    {'title': 'البيئة والنظافة', 'icon': Icons.cleaning_services, 'color': Colors.green, 'keywords': ['نظاف', 'بيئة', 'ممتلكات', 'فصل', 'مدرسة', 'طاولة']},
    {'title': 'الهدوء والسكينة', 'icon': Icons.handshake, 'color': Colors.purple, 'keywords': ['هدوء', 'سكينة', 'التزام', 'زي', 'انضباط']},
    {'title': 'التعاون والإيثار', 'icon': Icons.volunteer_activism, 'color': Colors.redAccent, 'keywords': ['تعاون', 'إيثار', 'مساعدة', 'فريق', 'مجموعة', 'قائد', 'معلم صغير']},
    {'title': 'الجدية والاجتهاد', 'icon': Icons.edit_note, 'color': Colors.orange, 'keywords': ['جدية', 'اجتهاد', 'واجب', 'مشاركة', 'مستوى', 'ذكاء', 'خط', 'دفتر', 'قراءة', 'بحث', 'مهام', 'بديهة']},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _fetchBehaviorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _categorizeReason(String reason) {
    for (var crit in criteriaDefinitions) {
      for (var kw in crit['keywords']) {
        if (reason.contains(kw)) return crit['title'];
      }
    }
    return 'إنجازات متنوعة';
  }

  Future<void> _fetchBehaviorData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('behavior_reports')
          .where('studentId', isEqualTo: widget.studentId)
          .where('type', isEqualTo: 'like')
          .get();

      Map<String, int> counts = {for (var c in criteriaDefinitions) c['title']: 0};
      counts['إنجازات متنوعة'] = 0;

      for (var doc in snap.docs) {
        final reason = (doc.data() as Map<String, dynamic>)['reason'] ?? '';
        final category = _categorizeReason(reason);
        counts[category] = (counts[category] ?? 0) + 1;
      }

      if(mounted) {
        setState(() {
          _studentLikes = snap.docs;
          _categoriesCount = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showCategoryDetails(String categoryTitle, Color color) {
    final docs = _studentLikes.where((d) => _categorizeReason((d.data() as Map)['reason'] ?? '') == categoryTitle).toList();

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text(categoryTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const Divider(),
              if (docs.isEmpty) const Padding(padding: EdgeInsets.all(20.0), child: Text("لا توجد إنجازات في هذا القسم بعد."))
              else Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: color.withOpacity(0.05),
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.star, color: color),
                        title: Text(data['reason'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text("من: أ. ${data['teacherName']} - مادة: ${data['subject']}", style: const TextStyle(fontSize: 11)),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1A237E),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFC5A059),
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "لوحة الشرف والتكريم"),
              Tab(text: "إنجازاتي وأوسمتي"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardTab(),
              _isLoading ? const Center(child: CircularProgressIndicator()) : _buildMyAchievementsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyHonorsPage())),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFC5A059), Color(0xFFF5D76E)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: const Row(
              children: [
                Icon(Icons.military_tech, color: Color(0xFF1A237E), size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("حصاد الأسبوع للتكريم", style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("اضغط هنا لفرز المتميزين حسب التاريخ", style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Color(0xFF1A237E), size: 16),
              ],
            ),
          ).animate().fadeIn().scale(),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text("🌟 المتصدرون حسب المعيار:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildFilterChip('الكل', Icons.all_inclusive, const Color(0xFF1A237E)),
              ...criteriaDefinitions.map((c) => _buildFilterChip(c['title'], c['icon'], c['color']))
            ],
          ),
        ),
        const Divider(height: 30),

        Expanded(
          child: _selectedFilter == 'الكل'
              ? _buildAllTimeLeaderboard()
              : _buildFilteredLeaderboard(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String title, IconData icon, Color color) {
    bool isSelected = _selectedFilter == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? Colors.transparent : color.withOpacity(0.3)),
        onSelected: (bool selected) {
          if (selected) setState(() => _selectedFilter = title);
        },
      ),
    );
  }

  Widget _buildAllTimeLeaderboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('students').orderBy('totalLikes', descending: true).limit(10).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final students = snapshot.data!.docs;
              if (students.isEmpty) return const Text("لا يوجد بيانات");

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data = students[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'طالب';
                  final likes = data['totalLikes'] ?? 0;
                  final isMe = students[index].id == widget.studentId;

                  return Card(
                    color: isMe ? const Color(0xFFC5A059).withOpacity(0.1) : Colors.white,
                    elevation: isMe ? 2 : 0,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isMe ? const Color(0xFFC5A059) : Colors.grey.shade200)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index < 3 ? const Color(0xFFC5A059) : const Color(0xFF1A237E).withOpacity(0.1),
                        child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? Colors.white : const Color(0xFF1A237E))),
                      ),
                      title: Text(name, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                      trailing: Text("$likes 👍", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const Text("🏫 الفصول المتصدرة عامة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('students').orderBy('totalLikes', descending: true).limit(100).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final Map<String, int> classScores = {};
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['grades'] != null && data['classes'] != null && (data['totalLikes'] ?? 0) > 0) {
                  final key = "${data['grades']} - ${data['classes']}";
                  classScores[key] = (classScores[key] ?? 0) + (data['totalLikes'] as int);
                }
              }
              final topClasses = classScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: math.min(10, topClasses.length),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: Text("#${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                      title: Text(topClasses[index].key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: Text("${topClasses[index].value} نقطة", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC5A059))),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildFilteredLeaderboard() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('behavior_reports').where('type', isEqualTo: 'like').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد بيانات لهذا الفرز"));

        Map<String, int> studentScores = {};
        Map<String, String> studentNames = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final reason = data['reason'] ?? '';
          if (_categorizeReason(reason) == _selectedFilter) {
            final sId = data['studentId'] ?? '';
            final sName = data['studentName'] ?? 'طالب';
            if (sId.isNotEmpty) {
              studentScores[sId] = (studentScores[sId] ?? 0) + 1;
              studentNames[sId] = sName;
            }
          }
        }

        if (studentScores.isEmpty) return const Center(child: Text("لا يوجد تميز مسجل في هذا القسم بعد."));

        final sortedStudents = studentScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final topStudents = sortedStudents.take(10).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: topStudents.length,
          itemBuilder: (context, index) {
            final sId = topStudents[index].key;
            final score = topStudents[index].value;
            final name = studentNames[sId] ?? '';
            final isMe = sId == widget.studentId;

            return Card(
              color: isMe ? const Color(0xFFC5A059).withOpacity(0.1) : Colors.white,
              elevation: isMe ? 2 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isMe ? const Color(0xFFC5A059) : Colors.grey.shade200)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: index < 3 ? const Color(0xFFC5A059) : const Color(0xFF1A237E).withOpacity(0.1),
                  child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? Colors.white : const Color(0xFF1A237E))),
                ),
                title: Text(name, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                trailing: Text("$score ⭐", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyAchievementsTab() {
    int totalPoints = _categoriesCount.values.fold(0, (a, b) => a + b);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFC5A059), size: 50),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("مجموع أوسمتك", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text("$totalPoints وسام", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0).fadeIn(),

          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("🎯 السجل المفصل للإنجازات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: criteriaDefinitions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final crit = criteriaDefinitions[index];
              final count = _categoriesCount[crit['title']] ?? 0;
              final color = crit['color'] as Color;

              return InkWell(
                onTap: count > 0 ? () => _showCategoryDetails(crit['title'], color) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(crit['icon'], color: count > 0 ? color : Colors.grey, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(crit['title'], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: count > 0 ? color : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                        child: Text("$count نقطة", style: TextStyle(fontSize: 11, color: count > 0 ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 100 * index)).scale(curve: Curves.easeOutBack);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class WeeklyHonorsPage extends StatefulWidget {
  const WeeklyHonorsPage({super.key});

  @override
  State<WeeklyHonorsPage> createState() => _WeeklyHonorsPageState();
}

class _WeeklyHonorsPageState extends State<WeeklyHonorsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  List<MapEntry<String, int>> _topStudents = [];
  List<MapEntry<String, int>> _topClasses = [];
  Map<String, String> _studentNamesMap = {};
  Map<String, String> _studentClassesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchWeeklyData();
  }

  Future<void> _fetchWeeklyData() async {
    setState(() => _isLoading = true);
    try {
      final studentsSnap = await FirebaseFirestore.instance.collection('students').get();
      Map<String, Map<String, dynamic>> studentsDataMap = {};

      for (var doc in studentsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        studentsDataMap[doc.id] = data;
        _studentNamesMap[doc.id] = data['name'] ?? 'طالب';

        final grade = data['grades'] ?? '';
        final className = data['classes'] ?? '';
        _studentClassesMap[doc.id] = (grade.isNotEmpty && className.isNotEmpty)
            ? "$grade / $className"
            : "فصل غير محدد";
      }

      final DateTime start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final reportsSnap = await FirebaseFirestore.instance.collection('behavior_reports')
          .where('type', isEqualTo: 'like')
          .get();

      Map<String, int> sScores = {};
      Map<String, int> cScores = {};

      for (var doc in reportsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? ts = data['timestamp'] as Timestamp?;

        if (ts != null) {
          final DateTime recordDate = ts.toDate();
          if (recordDate.isBefore(start) || recordDate.isAfter(end)) {
            continue;
          }
        } else {
          continue;
        }

        final String sId = data['studentId'] ?? '';
        if (sId.isEmpty) continue;

        sScores[sId] = (sScores[sId] ?? 0) + 1;

        if (studentsDataMap.containsKey(sId)) {
          final sData = studentsDataMap[sId]!;
          if (sData['grades'] != null && sData['classes'] != null) {
            String classKey = "${sData['grades']} - ${sData['classes']}";
            cScores[classKey] = (cScores[classKey] ?? 0) + 1;
          }
        }
      }

      final sortedStudents = sScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final sortedClasses = cScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _topStudents = sortedStudents.take(20).toList();
          _topClasses = sortedClasses.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFC5A059),
            colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchWeeklyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeStr = "${intl.DateFormat('yyyy/MM/dd').format(_startDate)} إلى ${intl.DateFormat('yyyy/MM/dd').format(_endDate)}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('حصاد الأسبوع وتكريم المتميزين', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Text("الفترة المحددة للفرز:", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC5A059))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.date_range, color: Color(0xFFC5A059)),
                        const SizedBox(width: 12),
                        Text(dateRangeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)))
                : (_topStudents.isEmpty
                ? const Center(child: Text("لا توجد إنجازات مسجلة في هذه الفترة."))
                : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF1A237E),
                    indicatorColor: Color(0xFFC5A059),
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: "فرسان الأسبوع"),
                      Tab(text: "فصول الصدارة"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStudentsList(),
                        _buildClassesList(),
                      ],
                    ),
                  )
                ],
              ),
            )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topStudents.length,
      itemBuilder: (context, index) {
        final sId = _topStudents[index].key;
        final score = _topStudents[index].value;
        final name = _studentNamesMap[sId] ?? 'طالب';
        final classInfo = _studentClassesMap[sId] ?? 'غير محدد';

        Color rankColor = Colors.grey.shade200;
        IconData rankIcon = Icons.star;
        if (index == 0) { rankColor = const Color(0xFFC5A059); rankIcon = Icons.emoji_events; }
        else if (index == 1) { rankColor = Colors.grey.shade400; rankIcon = Icons.emoji_events; }
        else if (index == 2) { rankColor = Colors.brown.shade300; rankIcon = Icons.emoji_events; }

        return Card(
          elevation: index < 3 ? 4 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: index < 3 ? rankColor : Colors.transparent, width: 1.5)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: index < 3 ? rankColor.withOpacity(0.2) : const Color(0xFF1A237E).withOpacity(0.1),
              child: Icon(rankIcon, color: index < 3 ? rankColor : const Color(0xFF1A237E), size: 28),
            ),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: index < 3 ? 16 : 14)),
            subtitle: Text(classInfo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$score", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: index < 3 ? rankColor : Colors.grey.shade700)),
                const Text("وسام", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ).animate().slideX(delay: Duration(milliseconds: 50 * index));
      },
    );
  }

  Widget _buildClassesList() {
    if (_topClasses.isEmpty) return const Center(child: Text("لا توجد بيانات للفصول"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topClasses.length,
      itemBuilder: (context, index) {
        final className = _topClasses[index].key;
        final score = _topClasses[index].value;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), shape: BoxShape.circle),
              child: Text("#${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ),
            title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E))),
            trailing: Chip(
              label: Text("$score نقطة", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: const Color(0xFF1A237E),
            ),
          ),
        ).animate().slideX(delay: Duration(milliseconds: 50 * index));
      },
    );
  }
}

class StudentDismissalPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String grade;
  final String className;

  const StudentDismissalPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.className,
  });

  @override
  State<StudentDismissalPage> createState() => _StudentDismissalPageState();
}

class _StudentDismissalPageState extends State<StudentDismissalPage> {
  final _reasonController = TextEditingController();
  String _selectedPickup = 'السائق';
  bool _isSubmitting = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة سبب الخروج المبكر'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('dismissal_requests').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'grade': widget.grade,
        'className': widget.className,
        'pickupBy': _selectedPickup,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _reasonController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح! بانتظار الموافقة.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteRequest(String docId, Timestamp? requestTime) async {
    if (requestTime != null) {
      final int elapsedMinutes = DateTime.now().difference(requestTime.toDate()).inMinutes;
      if (elapsedMinutes > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عذراً، انتهت مهلة الـ 5 دقائق المسموح بها لإلغاء الطلب.'), backgroundColor: Colors.red)
        );
        return;
      }
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الطلب', style: TextStyle(color: Color(0xFF1A237E))),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب وحذفه؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، الغي الطلب'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance.collection('dismissal_requests').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء وحذف الطلب بنجاح'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحذف.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('طلب انصراف مبكر', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF1A237E), size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "سلامة أبنائنا أمانة مشتركة بين الأسرة والمدرسة. نرجو التأكد من بيانات المستلم وسبب الخروج للحفاظ على سلامتهم.",
                      style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إنشاء طلب جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('من سيقوم باستلام الطالب؟', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPickup,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E))),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: ['السائق', 'الأب', 'الأم', 'أقارب آخرون'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedPickup = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text('سبب الخروج المبكر:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'مثال: موعد مستشفى، ظرف عائلي...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E))),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'جاري الإرسال...' : 'إرسال الطلب للموافقة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submitRequest,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerRight,
              child: Text("📋 سجل طلبات الانصراف السابقة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dismissal_requests')
                  .where('studentId', isEqualTo: widget.studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: SelectableText('حدث خطأ.', style: TextStyle(color: Colors.red)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد طلبات سابقة.')));

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['timestamp'] as Timestamp?;
                  final bTime = bData['timestamp'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final status = data['status'];
                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final date = ts != null ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(ts.toDate()) : 'جاري الحفظ...';

                    bool canDelete = false;
                    if (status == 'pending' && ts != null) {
                      final int elapsedMinutes = DateTime.now().difference(ts.toDate()).inMinutes;
                      if (elapsedMinutes <= 5) {
                        canDelete = true;
                      }
                    }

                    Color statusColor = Colors.grey;
                    String statusText = '';
                    IconData statusIcon = Icons.info;

                    if (status == 'pending') { statusColor = Colors.orange; statusText = 'قيد المراجعة'; statusIcon = Icons.access_time_filled; }
                    else if (status == 'approved') { statusColor = Colors.green; statusText = 'تمت الموافقة'; statusIcon = Icons.check_circle; }
                    else if (status == 'rejected') { statusColor = Colors.red; statusText = 'مرفوض'; statusIcon = Icons.cancel; }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusColor.withOpacity(0.5))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    if (canDelete) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _deleteRequest(docId, ts),
                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Text("المستلم: ${data['pickupBy']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E))),
                            const SizedBox(height: 4),
                            Text("السبب: ${data['reason'] ?? 'بدون سبب'}", style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}