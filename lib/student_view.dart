// student_view.dart (MODIFIED FOR NAFES KEYS AND NOTIFICATIONS)
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:async'; // <-- ✅ إضافة جديدة للاستماع
import 'dart:math';
import 'dart:typed_data'; // <-- ✅ (مطلوب للطباعة)

import 'package:almarefamecca/student_profile_page.dart';
import 'package:almarefamecca/teacher_profile_view_page.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/percent_indicator.dart';
// --- ✅✅✅ (مطلوب للطباعة) ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
// --- ✅✅✅ (نهاية) ---
import 'package:url_launcher/url_launcher.dart';

// --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
// تم إضافة المكتبات المطلوبة لتشغيل ميزة إعادة التحميل على الويب
import 'package:flutter/foundation.dart' show kIsWeb;
// --- ✅ إضافة html للتحكم بالصوت والإشعارات ---
import 'package:universal_html/html.dart' as html;
// --- ✅✅✅  إضافة المكتبات المطلوبة للتكريم والأيقونات الجمالية  ✅✅✅ ---
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---
// student_view.dart (MODIFIED FOR NAFES KEYS AND NOTIFICATIONS)
// ✅✅✅ (MAJOR REFACTOR)
// تم إعادة هيكلة الصفحة بالكامل لعرض تحليلات مفصلة لكل مجموعة اختبارات (دوري، نافس، إضافي)
// مع إضافة مكتبات تجميلية ورسائل تحفيزية وإيجابية

import 'dart:math';

import 'package:almarefamecca/student_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/percent_indicator.dart'; // (لا يزال مستخدماً في التحليل الشامل)
import 'package:url_launcher/url_launcher.dart';

// --- ✅✅✅ START OF MODIFICATION ✅✅✅ ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// --- ✅✅✅ مكتبات الواجهة العصرية الجديدة ✅✅✅ ---
import 'package:flutter_animate/flutter_animate.dart';
// --- ✅✅✅ END OF MODIFICATION ✅✅✅ ---


enum StudentView { dashboard, results, noble, teacherComplaints }

// --- 🛑 (حذف) تم حذف ReportType ---

class TestInfo {
  final String key;
  final String name;
  final String subject; // Stores the actual subject name (e.g., رياضيات)
  // ✅ (إضافة جديدة) لتصنيف الاختبارات
  final String testGroup; // e.g., "periodic", "nafes", "additional"

  TestInfo({
    required this.key,
    required this.name,
    required this.subject,
    required this.testGroup,
  });
}

class Subject {
  final String name;
  final IconData icon;
  Subject({required this.name, required this.icon});
}

// ✅ (تعديل) تم إضافة اسم لمجموعة التحليل
class _AnalysisResult {
  final String groupName; // e.g., "الاختبارات الدورية", "اختبارات نافس"
  final String subjectName;
  final double average;
  final double percentage;
  final double maxPossibleGrade; // The max grade used for THIS analysis (10 or 20)
  final num highestGrade;
  final num lowestGrade;
  final String assessment;
  final String consistency;
  final bool isBelowPassing;
  final List<MapEntry<String, num>> testResults; // Map key is test KEY now
  final List<FlSpot> trendSpots;
  final String performanceTrend;
  final double? predictedNextGrade;
  final String riskAssessment;
  // ✅ (إضافة جديدة) لحساب النسبة الإجمالية
  final int testCount; // عدد الاختبارات في هذا التحليل

  _AnalysisResult({
    required this.groupName,
    required this.subjectName,
    required this.average,
    required this.percentage,
    required this.maxPossibleGrade,
    required this.highestGrade,
    required this.lowestGrade,
    required this.assessment,
    required this.consistency,
    required this.isBelowPassing,
    required this.testResults,
    required this.trendSpots,
    required this.performanceTrend,
    this.predictedNextGrade,
    required this.riskAssessment,
    required this.testCount,
  });
}

// ✅ (إضافة جديدة) ويدجت لحمل النسبة الإجمالية للمادة
class _OverallSubjectMetric {
  final String subjectName;
  final double overallPercentage;
  final double overallAverage; // متوسط جميع الاختبارات
  _OverallSubjectMetric({required this.subjectName, required this.overallPercentage, required this.overallAverage});
}


class StudentViewPage extends StatefulWidget {
  final String? studentId;

  const StudentViewPage({super.key, this.studentId});

  @override
  _StudentViewPageState createState() => _StudentViewPageState();
}

class _StudentViewPageState extends State<StudentViewPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  StudentView _currentView = StudentView.dashboard;
  late TabController _tabController;
  final Map<String, Color> _subjectColors = {};

  String? _studentDocId;

  // Map to hold all possible test info (key -> TestInfo)
  late final Map<String, TestInfo> _allTestsMap;

  // --- ✅ (تعديل) تم الإبقاء عليه لخاصية الطباعة ---
  final ScreenshotController _screenshotController = ScreenshotController();

  // --- ✅✅✅ START OF NOTIFICATION MODIFICATION ✅✅✅ ---
  StreamSubscription? _notificationSubscription;
  final Set<String> _processedNotificationIds = {};
  // --- ✅✅✅ END OF NOTIFICATION MODIFICATION ✅✅✅ ---


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
    Subject(name: 'مصدر', icon: Icons.source),
    // Nafes subjects are handled implicitly by _getAllPossibleTests associating keys with correct subject names
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  void _initializeData() {
    // Populate _allTestsMap first
    _allTestsMap = {for (var test in _getAllPossibleTests()) test.key: test};
    _fetchStudentData();
    _assignSubjectColors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // --- ✅✅✅ START OF NOTIFICATION MODIFICATION ✅✅✅ ---
    _notificationSubscription?.cancel(); // إلغاء المتابعة عند الخروج
    // --- ✅✅✅ END OF NOTIFICATION MODIFICATION ✅✅✅ ---
    super.dispose();
  }

  // ✅ (تعديل) تم إضافة testGroup
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
    };

    // Generate standard test keys
    standardSubjects.forEach((profKey, subjName) {
      tests.add(TestInfo(key: 'e1$profKey', name: 'الاختبار الأول (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e2$profKey', name: 'الاختبار الثاني (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e3$profKey', name: 'الاختبار الثالث (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e14$profKey', name: 'اختبار قبلي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e15$profKey', name: 'اختبار بعدي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e16$profKey', name: 'اختبار احتياطي', subject: subjName, testGroup: 'additional'));
    });

    // Generate Nafes test keys for relevant subjects
    const String nafesBaseKey = 'profession13';
    const Map<String, String> nafesSubjectShortcodes = {
      'رياضيات': 'math',
      'لغتي': 'lughati',
      'علوم': 'science',
    };

    nafesSubjectShortcodes.forEach((subjectName, shortcode) {
      // Nafes tests are associated with their *actual* subject name
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

    // Assign colors based on the `subjects` list (which contains actual subject names)
    for (int i = 0; i < subjects.length; i++) {
      _subjectColors[subjects[i].name] = vibrantColors[i % vibrantColors.length];
    }
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '966569064173';
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');

    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح تطبيق واتساب.')),
        );
      }
    }
  }

  Future<void> _fetchStudentData() async {
    final studentDocumentId = widget.studentId ?? FirebaseAuth.instance.currentUser?.uid;

    if (studentDocumentId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentDocumentId)
          .get();

      if (mounted && docSnapshot.exists) {
        setState(() {
          _studentData = docSnapshot.data();
          _studentDocId = docSnapshot.id;
          _isLoading = false;
        });
        // --- ✅✅✅ START OF NOTIFICATION MODIFICATION ✅✅✅ ---
        // بمجرد جلب بيانات الطالب، نبدأ الاستماع للإشعارات
        if (_studentDocId != null) {
          _listenForNewNotifications();
          _requestNotificationPermission(); // طلب الإذن عند تحميل الصفحة
        }
        // --- ✅✅✅ END OF NOTIFICATION MODIFICATION ✅✅✅ ---
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching student data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ✅✅✅ START OF NOTIFICATION MODIFICATION ✅✅✅ ---
  /// دالة لطلب إذن عرض الإشعارات من المتصفح
  void _requestNotificationPermission() {
    if (kIsWeb) {
      // التأكد من أن المتصفح يدعم الإشعارات
      if (html.Notification.supported) {
        html.Notification.requestPermission().then((permission) {
          if (permission != 'granted') {
            debugPrint('Notification permission not granted.');
          }
        });
      }
    }
  }

  /// دالة للاستماع المستمر للإشعارات الجديدة
  void _listenForNewNotifications() {
    _notificationSubscription?.cancel(); // إلغاء أي متابعة سابقة
    _notificationSubscription = FirebaseFirestore.instance
        .collection('students')
        .doc(_studentDocId)
        .collection('notifications')
        .where('isRead', isEqualTo: false) // جلب الإشعارات غير المقروءة فقط
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return; // لا يوجد شيء جديد

      bool foundNew = false;
      String lastMessage = '';

      for (var doc in snapshot.docs) {
        // التحقق إذا كان هذا الإشعار لم يتم عرضه مسبقاً
        if (!_processedNotificationIds.contains(doc.id)) {
          _processedNotificationIds.add(doc.id); // تعليمه كـ "معالج"
          foundNew = true;
          lastMessage = doc.data()['message'] ?? 'لديك إشعار جديد';
        }
      }

      // إذا وجدنا إشعارات جديدة (لم تُعرض من قبل)
      if (foundNew) {
        _playNotificationSound(); // تشغيل الصوت
        _showBrowserNotification(lastMessage); // عرض الإشعار
      }
    }, onError: (error) {
      debugPrint("Error listening to notifications: $error");
    });
  }

  /// دالة تشغيل ملف الصوت 1.mp3 من مجلد web
  void _playNotificationSound() {
    if (kIsWeb) {
      try {
        // إنشاء عنصر صوتي بشكل برمجي
        final html.AudioElement audio = html.AudioElement('1.mp3'); // يفترض وجود 1.mp3 في مجلد web
        audio.play();
      } catch (e) {
        debugPrint("Error playing notification sound: $e");
        // قد يفشل التشغيل التلقائي بسبب سياسات المتصفح، يحتاج لتفاعل المستخدم أولاً
      }
    }
  }

  /// دالة عرض الإشعار في المتصفح (مثل إشعارات جوجل كروم)
  void _showBrowserNotification(String message) {
    if (kIsWeb && html.Notification.supported) {
      // نتأكد أن لدينا الإذن أولاً
      if (html.Notification.permission == 'granted') {
        // إنشاء الإشعار
        html.Notification('إشعار جديد من مدارس المعرفة',
            body: message,
            icon: 'icons/Icon-192.png'); // تأكد من وجود هذه الأيقونة في web/icons
      }
      // إذا لم يكن الإذن ممنوحاً، فإن دالة _requestNotificationPermission
      // التي استدعيت عند تحميل الصفحة تكون قد طلبت الإذن بالفعل.
    }
  }
  // --- ✅✅✅ END OF NOTIFICATION MODIFICATION ✅✅✅ ---


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
        return AlertDialog(
          title: const Text('مطلوب إذن ولي الأمر'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الرجاء إدخال كلمة المرور لعرض هذه الصفحة.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
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
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('دخول'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final docSnapshot = await FirebaseFirestore.instance
                      .collection('students')
                      .doc(_studentDocId!)
                      .get();

                  final studentData = docSnapshot.data();
                  final String? correctPassword = studentData?['pp']?.toString();

                  final enteredPassword = passwordController.text;

                  if (correctPassword != null && correctPassword == enteredPassword) {
                    Navigator.of(context).pop(true);
                  } else {
                    Navigator.of(context).pop(false);
                  }
                }
              },
            ),
          ],
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

  // --- ✅ (جديد) دالة لطباعة التقرير طبق الأصل ---
  Future<void> _printResultsPage() async {
    try {
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 300), // إعطاء فرصة للواجهة للرسم
        pixelRatio: 1.5, // جودة أعلى قليلاً
      );
      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل التقاط صورة للتقرير.')),
          );
        }
        return;
      }

      final pdfDoc = pw.Document();
      pdfDoc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(imageBytes)),
            );
          }
      ));

      final String studentName = _studentData?['name'] ?? 'student';
      final safeStudentName = studentName.replaceAll(' ', '_');
      final fileName = 'report_card_$safeStudentName.pdf';

      // استخدام layoutPdf لفتح نافذة الطباعة مباشرة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfDoc.save(),
        name: fileName,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إعداد الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- ✅ (جديد) دالة لإنشاء الزر العائم ---
  Widget? _buildFloatingActionButton() {
    if (_currentView == StudentView.results) {
      return FloatingActionButton(
        onPressed: _printResultsPage, // استدعاء دالة الطباعة الجديدة
        tooltip: 'طباعة التقرير',
        child: const Icon(Icons.print),
      );
    }
    return null; // لا يظهر في الشاشات الأخرى
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBody(),
        ],
      ),
      // --- ✅ (جديد) إضافة الزر العائم ---
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    final bool isTeacherView = widget.studentId != null;
    bool isDashboard = _currentView == StudentView.dashboard;
    String title;

    switch (_currentView) {
      case StudentView.results:
        title = 'النتائج والتحليل الدراسي';
        break;
      case StudentView.noble:
        title = 'قاعة الشرف للطلاب المنضبطين';
        break;
      case StudentView.teacherComplaints:
        title = 'سجل الملاحظات السلوكية';
        break;
      default:
        title = isTeacherView ? 'تقرير الطالب: ${_studentData?['name'] ?? ''}' : 'أهلاً بك، ${_studentData?['name'] ?? ''}';
    }

    List<Widget> appBarActions = [];
    if (isDashboard && !isTeacherView) {
      appBarActions.addAll(_buildDashboardActions());
    }
    // --- 🛑 (حذف) تم حذف زر التحميل القديم ---
    // else if (_currentView == StudentView.results) {
    //   appBarActions.add(...);
    // }

    appBarActions.add(
      Tooltip(
        message: 'تحديث الصفحة للحصول على آخر التعديلات',
        child: GestureDetector(
          onTap: () {
            if (kIsWeb) {
              html.window.location.reload();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/2.png'),
          ),
        ),
      ),
    );

    return AppBar(
      title: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
      centerTitle: !isDashboard || isTeacherView,
      leading: (isTeacherView && isDashboard) || !isDashboard
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios),
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
      automaticallyImplyLeading: !isDashboard || isTeacherView,
      bottom: (isDashboard && !isTeacherView) // يظهر فقط في الواجهة الرئيسية للطالب
          ? PreferredSize(
        preferredSize: const Size.fromHeight(30.0), // ارتفاع مناسب
        child: Container(
          height: 30.0,
          alignment: Alignment.center,
          color: Colors.deepPurple.shade700, // لون مميز للتكريم
          child: AnimatedTextKit(
            animatedTexts: [
              RotateAnimatedText(
                'مبرمج المنصة: أ/ مصطفي سعيد',
                textAlign: TextAlign.center,
                textStyle: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              RotateAnimatedText(
                'باشراف ابتدائية المعرفة الاهلية بمكة ',
                textAlign: TextAlign.center,
                textStyle: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              RotateAnimatedText(
                'هذا الاصدار تجريبي ونتمني لكم يوما سعيدا',
                textAlign: TextAlign.center,
                textStyle: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
            repeatForever: true,
            pause: const Duration(milliseconds: 1500),
          ),
        ),
      )
          : null, // لا يظهر في الصفحات الداخلية
    );
  }

  Widget _buildBody() {
    final bool isTeacherView = widget.studentId != null;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_studentData == null) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('عفواً، لم يتم العثور على بيانات الطالب.'),
              const SizedBox(height: 20),
              if (!isTeacherView)
                ElevatedButton(
                  onPressed: _signOutAndGoToLogin,
                  child: const Text('العودة لتسجيل الدخول'),
                )
            ],
          ));
    }

    switch (_currentView) {
      case StudentView.results:
        return _buildResultsView();
      case StudentView.noble:
        return _buildNobleStudentView();
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

    final List<Widget> dashboardButtons = [
      _buildDashboardButton(
        title: 'النتائج والتحليل',
        icon: Icons.bar_chart_rounded,
        color: Colors.green.shade700,
        onTap: () => setState(() => _currentView = StudentView.results),
      ),
      _buildDashboardButton(
        title: 'الطالب المنضبط',
        icon: Icons.thumb_up,
        color: Colors.blue.shade700,
        count: totalLikes,
        onTap: () => setState(() => _currentView = StudentView.noble),
      ),
      _buildDashboardButton(
        title: 'الملاحظات السلوكية',
        icon: Icons.report_problem_outlined,
        color: Colors.red.shade700,
        count: totalDislikes,
        onTap: _promptForParentPassword,
      ),
      _buildDashboardButton(
        title: 'فيزا الطلاب',
        icon: Icons.credit_card,
        color: Colors.deepPurple.shade500,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا جدا'),
      ),
      _buildDashboardButton(
        title: 'الكتاب المدرسي',
        icon: Icons.menu_book,
        color: Colors.brown.shade500,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
      _buildDashboardButton(
        title: 'الاحتفالات',
        icon: Icons.celebration,
        color: Colors.pink.shade500,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
      _buildDashboardButton(
        title: 'استديو الطالب',
        icon: Icons.photo_library,
        color: Colors.orange.shade700,
        onTap: () => _showPlaceholderSnackBar('لا يوجد صور لك متوفرة حالياً.'),
      ),
      _buildDashboardButton(
        title: 'الانجازات',
        icon: Icons.emoji_events,
        color: Colors.amber.shade800,
        onTap: () => _showPlaceholderSnackBar('لا يوجد لديك أي إنجازات مسجلة حالياً.'),
      ),
      _buildDashboardButton(
        title: 'المسابقات',
        icon: Icons.military_tech,
        color: Colors.lightGreen.shade700,
        onTap: () => _showPlaceholderSnackBar('لا توجد مسابقات حالية الآن.'),
      ),
      _buildDashboardButton(
        title: 'الإذاعة المدرسية',
        icon: Icons.mic,
        color: Colors.cyan.shade600,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
      _buildDashboardButton(
        title: 'كرة القدم',
        icon: Icons.sports_soccer,
        color: Colors.black,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
      _buildDashboardButton(
        title: 'الكاراتيه',
        icon: Icons.sports_kabaddi,
        color: Colors.red.shade900,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
      _buildDashboardButton(
        title: 'السباحة',
        icon: Icons.pool,
        color: Colors.blue.shade900,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
      _buildDashboardButton(
        title: 'المسابقات الرقمية',
        icon: Icons.laptop_chromebook,
        color: Colors.grey.shade700,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
      ),
    ];

    return AnimationLimiter(
      child: GridView.extent(
        maxCrossAxisExtent: 150,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: List.generate(
          dashboardButtons.length,
              (index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: (MediaQuery.of(context).size.width / 166).floor(),
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: dashboardButtons[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int count = 0,
  }) {
    return _AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const style = TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      );
                      final painter = TextPainter(
                        text: TextSpan(text: title, style: style),
                        maxLines: 1,
                        textDirection: TextDirection.rtl,
                      )..layout();

                      if (painter.width > constraints.maxWidth) {
                        return _MarqueeText(text: title, style: style);
                      } else {
                        return Text(
                          title,
                          textAlign: TextAlign.center,
                          style: style,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  // --- ✅✅✅ START OF (MAJOR REFACTOR) ✅✅✅ ---
  // (دالة جديدة) تقوم بتجميع الاختبارات حسب النوع (دوري، نافس، إضافي)
  // وتعيد خريطة تحتوي على اسم المادة وقائمة بالتحليلات الخاصة بها
  Map<String, List<_AnalysisResult>> _buildSubjectAnalyses() {
    // 1. تجميع الدرجات حسب المادة، ثم حسب نوع الاختبار
    // Map<SubjectName, Map<TestGroup, Map<TestKey, Grade>>>
    final Map<String, Map<String, Map<String, num>>> subjectGroupedGrades = {};

    _studentData?.forEach((key, value) {
      if (value is num && _allTestsMap.containsKey(key)) {
        final testInfo = _allTestsMap[key]!;
        // testInfo.subject = "رياضيات"
        // testInfo.testGroup = "periodic"
        // key = "e1profession1"
        // value = 18
        subjectGroupedGrades
            .putIfAbsent(testInfo.subject, () => {})
            .putIfAbsent(testInfo.testGroup, () => {})[testInfo.key] = value;
      }
    });

    // 2. تحليل كل مجموعة فرعية على حدة
    // Map<SubjectName, List<_AnalysisResult>>
    final Map<String, List<_AnalysisResult>> finalAnalyses = {};

    subjectGroupedGrades.forEach((subjectName, groups) {
      final List<_AnalysisResult> subjectAnalyses = [];

      // 3. تحليل مجموعة "الاختبارات الدورية" (إن وجدت)
      if (groups.containsKey('periodic') && groups['periodic']!.isNotEmpty) {
        subjectAnalyses.add(_analyzeSubjectGrades(
          subjectName: subjectName,
          groupName: "الاختبارات الدورية",
          testResults: groups['periodic']!,
          maxGrade: 20.0, // الدوري دائماً من 20
        ));
      }

      // 4. تحليل مجموعة "اختبارات نافس" (إن وجدت)
      if (groups.containsKey('nafes') && groups['nafes']!.isNotEmpty) {
        subjectAnalyses.add(_analyzeSubjectGrades(
          subjectName: subjectName,
          groupName: "اختبارات نافس",
          testResults: groups['nafes']!,
          maxGrade: 10.0, // نافس دائماً من 10
        ));
      }

      // 5. تحليل مجموعة "الاختبارات الإضافية" (إن وجدت)
      if (groups.containsKey('additional') && groups['additional']!.isNotEmpty) {
        subjectAnalyses.add(_analyzeSubjectGrades(
          subjectName: subjectName,
          groupName: "اختبارات قياس المستوي (قبلي , بعدي )",
          testResults: groups['additional']!,
          maxGrade: 20.0, // الإضافي غالباً من 20 (افتراضي)
        ));
      }

      if (subjectAnalyses.isNotEmpty) {
        finalAnalyses[subjectName] = subjectAnalyses;
      }
    });

    return finalAnalyses;
  }
  // --- ✅✅✅ END OF (MAJOR REFACTOR) ✅✅✅ ---

  // ✅ (دالة جديدة) لحساب المقاييس الإجمالية للمادة
  // تأخذ مخرجات الدالة السابقة
  List<_OverallSubjectMetric> _calculateOverallMetrics(Map<String, List<_AnalysisResult>> subjectAnalyses) {
    final List<_OverallSubjectMetric> metrics = [];

    subjectAnalyses.forEach((subjectName, analyses) {
      double totalWeightedSum = 0;
      int totalTests = 0;
      double totalAverageSum = 0;

      for (var analysis in analyses) {
        // (متوسط المجموعة * عدد اختباراتها)
        totalWeightedSum += (analysis.average * analysis.testCount);
        totalTests += analysis.testCount;
        // (نسبة المجموعة * عدد اختباراتها) - لحساب النسبة الإجمالية
        totalAverageSum += (analysis.percentage * analysis.testCount);
      }

      if (totalTests > 0) {
        metrics.add(_OverallSubjectMetric(
          subjectName: subjectName,
          // النسبة الإجمالية = مجموع (النسبة * العدد) / العدد الإجمالي
          overallPercentage: totalAverageSum / totalTests,
          // المتوسط الإجمالي = مجموع (المتوسط * العدد) / العدد الإجمالي
          overallAverage: totalWeightedSum / totalTests,
        ));
      }
    });

    return metrics;
  }


  Widget _buildResultsView() {
    // 1. (جديد) قم ببناء التحليلات المفصلة (دوري، نافس، ...)
    final allSubjectAnalyses = _buildSubjectAnalyses();

    // 2. (جديد) قم بحساب المقاييس الإجمالية لكل مادة
    final overallMetrics = _calculateOverallMetrics(allSubjectAnalyses);

    if (allSubjectAnalyses.isEmpty) {
      return const Center(
        child: Text('لا توجد نتائج دراسية لعرضها حالياً.',
            style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return Screenshot(
      controller: _screenshotController,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 3. (تعديل) إرسال المقاييس الإجمالية للويدجت الشامل
              _buildOverallAnalysisWidget(overallMetrics),
              const SizedBox(height: 24),
              // 4. (تعديل) بناء كروت المواد باستخدام التحليلات المفصلة
              ...allSubjectAnalyses.entries.map((entry) {
                final subjectName = entry.key;
                final analysesList = entry.value; // List<_AnalysisResult>
                final subjectIcon = subjects
                    .firstWhere((s) => s.name == subjectName,
                    orElse: () => Subject(name: '', icon: Icons.book))
                    .icon;
                final subjectColor = _subjectColors[subjectName] ?? Colors.blue;

                return _SubjectResultCard(
                  subjectName: subjectName,
                  analyses: analysesList, // إرسال القائمة
                  subjectIcon: subjectIcon,
                  color: subjectColor,
                  allTestsMap: _allTestsMap,
                );
              }).toList(),

            ],
          ),
        ),
      ),
    );
  }

  // ✅ (تعديل) هذا الويدجت الآن يأخذ المقاييس الإجمالية
  Widget _buildOverallAnalysisWidget(List<_OverallSubjectMetric> overallMetrics) {
    if (overallMetrics.isEmpty) return const SizedBox.shrink();

    final double overallAveragePercentage =
        overallMetrics.map((m) => m.overallPercentage).reduce((a, b) => a + b) /
            overallMetrics.length;

    overallMetrics.sort((a, b) => b.overallAverage.compareTo(a.overallAverage));
    final strengths = overallMetrics.take(3).toList();
    final weaknesses = overallMetrics.reversed.take(3).toList();

    // ✅ (تعديل) تحسين الرسائل الإيجابية
    String overallAssessment;
    if (overallAveragePercentage >= 0.9) {
      overallAssessment =
      'أداء استثنائي ورائع! أنت تسير على طريق التفوق. حافظ على هذا المستوى المتميز.';
    } else if (overallAveragePercentage >= 0.75) {
      overallAssessment =
      'أداء عام ممتاز. لديك نقاط قوة واضحة ومستوى يبعث على الفخر. عمل رائع!';
    } else if (overallAveragePercentage >= 0.60) {
      overallAssessment =
      'أداء عام جيد جداً ومستقر. بالتركيز على بعض النقاط ستصل إلى الامتياز بسهولة.';
    } else if (overallAveragePercentage >= 0.50) {
      overallAssessment =
      'أداء جيد وهناك إمكانيات كبيرة للتحسن. بالجهد والمتابعة ستحقق نتائج أفضل بكثير.';
    } else {
      overallAssessment =
      'الأداء العام يحتاج إلى متابعة وجهد إضافي. لديك القدرة على تحقيق نتائج أفضل، ثق بنفسك.';
    }


    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'المحصلة النهائية والتقييم الشامل',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 24),
            Center(
              child: CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 12.0,
                animation: true,
                percent: overallAveragePercentage,
                center: Text(
                  "${(overallAveragePercentage * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22.0),
                ),
                footer: const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text("متوسط الأداء العام",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.0)),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'التقييم الشامل:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              overallAssessment,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 24),
            Text(
              'أبرز نقاط القوة (أعلى المواد أداءً):',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...strengths.map((s) => ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green[700]),
              title: Text(s.subjectName),
              trailing: Text(
                  '${(s.overallPercentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const Divider(height: 24),
            Text(
              'مواد تحتاج إلى تركيز إضافي:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...weaknesses.map((w) => ListTile(
              leading:
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
              title: Text(w.subjectName),
              trailing: Text(
                  '${(w.overallPercentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  // --- ✅✅✅ START OF (MAJOR REFACTOR) ✅✅✅ ---
  // (تعديل) الدالة الآن تأخذ اسم المجموعة والحد الأقصى للدرجة
  _AnalysisResult _analyzeSubjectGrades({
    required String subjectName,
    required String groupName, // "الاختبارات الدورية", "اختبارات نافس", ...
    required Map<String, num> testResults, // testResults key is test KEY
    required double maxGrade, // 20.0 or 10.0
  }) {
    // Sort tests by key for consistent trend analysis
    final sortedTests = testResults.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Filter out absent marks (-1) before calculations
    final validGrades = sortedTests.map((e) => e.value).where((g) => g >= 0).toList();

    // Use the passed maxGrade
    final double maxGradeForThisAnalysis = maxGrade;
    final double passingGradeForThisAnalysis = maxGradeForThisAnalysis / 2.0;

    // Handle case where there are no valid grades
    if (validGrades.isEmpty) {
      return _AnalysisResult(
        groupName: groupName,
        subjectName: subjectName,
        average: 0,
        percentage: 0,
        maxPossibleGrade: maxGradeForThisAnalysis, // Use determined max grade
        highestGrade: 0,
        lowestGrade: 0,
        assessment: 'لا توجد درجات',
        consistency: 'N/A',
        isBelowPassing: false,
        testResults: sortedTests, // Still show original results with 'غائب' (key -> grade)
        trendSpots: [],
        performanceTrend: 'لا يوجد بيانات كافية',
        predictedNextGrade: null,
        riskAssessment: 'غير محدد',
        testCount: sortedTests.length, // (جديد)
      );
    }

    // --- Calculations using valid grades ---
    final double average = validGrades.reduce((a, b) => a + b) / validGrades.length;
    final double percentage = (average / maxGradeForThisAnalysis).clamp(0.0, 1.0); // Use correct max grade
    final num highest = validGrades.reduce(max);
    final num lowest = validGrades.reduce(min);
    final bool isBelowPassing = average < passingGradeForThisAnalysis; // Use correct passing grade

    // --- Consistency (Standard Deviation) ---
    final double variance = validGrades.map((g) => pow(g - average, 2)).reduce((a, b) => a + b) / validGrades.length;
    final double stdDev = sqrt(variance);
    // ✅ (تعديل) رسائل تحفيزية
    String consistency;
    if (stdDev > (maxGradeForThisAnalysis * 0.15)) { // Use correct max grade
      consistency = 'يحتاج إلى ثبات'; // (رسالة أفضل)
    } else if (stdDev < (maxGradeForThisAnalysis * 0.05)) { // Use correct max grade
      consistency = 'مستقر جداً';
    } else {
      consistency = 'مستقر';
    }

    // --- Assessment ---
    // ✅ (تعديل) رسائل تحفيزية وإيجابية
    String assessment;
    if (percentage >= 0.95)
      assessment = 'متفوق ورائع!';
    else if (percentage >= 0.85)
      assessment = 'ممتاز';
    else if (percentage >= 0.75)
      assessment = 'جيد جداً';
    else if (percentage >= 0.60)
      assessment = 'جيد';
    else if (percentage >= 0.50)
      assessment = 'مقبول';
    else
      assessment = 'يحتاج لمتابعة'; // (تم إزالة "بسيطة" للوضوح)

    // --- Trend Analysis ---
    final trendSpots = <FlSpot>[];
    int validIndex = 0;
    for (int i = 0; i < sortedTests.length; i++) {
      if (sortedTests[i].value >= 0) {
        trendSpots.add(FlSpot(validIndex.toDouble(), sortedTests[i].value.toDouble()));
        validIndex++;
      }
    }

    // --- Performance Trend & Prediction ---
    // ✅ (تعديل) رسائل تحفيزية
    String performanceTrend = 'مستقر';
    double? predictedNextGrade;
    String riskAssessment = 'في المسار الصحيح'; // (رسالة أفضل)

    if (validGrades.length >= 2) {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int i = 0; i < validGrades.length; i++) {
        sumX += i;
        sumY += validGrades[i];
        sumXY += i * validGrades[i];
        sumX2 += i * i;
      }
      final n = validGrades.length.toDouble();
      final double denominator = (n * sumX2 - sumX * sumX);

      if (denominator != 0) {
        final double slope = (n * sumXY - sumX * sumY) / denominator;

        // ✅ (تعديل) التعامل مع الإشارات السالبة (Rule #8)
        if (slope > (maxGradeForThisAnalysis * 0.05)) { // Use correct max grade
          performanceTrend = 'تحسن ملحوظ';
        } else if (slope < -(maxGradeForThisAnalysis * 0.05)) { // Use correct max grade
          performanceTrend = 'تراجع يحتاج انتباه'; // (رسالة أفضل)
        }

        final double intercept = (sumY - slope * sumX) / n;
        predictedNextGrade = (slope * n + intercept).clamp(0.0, maxGradeForThisAnalysis); // Use correct max grade
      } else {
        performanceTrend = 'مستقر (نقاط بيانات غير كافية للاتجاه)';
      }

      // Risk Assessment
      // ✅ (تعديل) رسائل تحفيزية
      if (isBelowPassing && (performanceTrend.contains('تراجع'))) {
        riskAssessment = 'يحتاج دعم فوري'; // (رسالة أفضل)
      } else if (isBelowPassing || (predictedNextGrade != null && predictedNextGrade < passingGradeForThisAnalysis)) {
        riskAssessment = 'يحتاج لبعض التركيز'; // (رسالة أفضل)
      } else if (performanceTrend.contains('تراجع')){
        riskAssessment = 'يحتاج لبعض التركيز'; // (رسالة أفضل)
      }

    } else {
      performanceTrend = 'يتطلب اختبارين للتحليل';
      if(isBelowPassing && validGrades.isNotEmpty) {
        riskAssessment = 'يحتاج لبعض التركيز'; // (رسالة أفضل)
      } else if (validGrades.isEmpty) {
        riskAssessment = 'غير محدد';
      }
    }

    return _AnalysisResult(
      groupName: groupName, // (جديد)
      subjectName: subjectName,
      average: average,
      percentage: percentage,
      maxPossibleGrade: maxGradeForThisAnalysis, // Store the determined max grade
      highestGrade: highest,
      lowestGrade: lowest,
      assessment: assessment,
      consistency: consistency,
      isBelowPassing: isBelowPassing,
      testResults: sortedTests, // Pass the original data (key -> grade)
      trendSpots: trendSpots,
      performanceTrend: performanceTrend,
      predictedNextGrade: predictedNextGrade,
      riskAssessment: riskAssessment,
      testCount: sortedTests.length, // (جديد)
    );
  }
  // --- ✅✅✅ END OF (MAJOR REFACTOR) ✅✅✅ ---


  // --- 🛑 (حذف) تم حذف _showReportOptions ---
  // --- 🛑 (حذف) تم حذف _generateAndSharePdf ---
  // --- 🛑 (حذف) تم حذف _buildStudentDataPdf ---
  // --- 🛑 (حذف) تم حذف _buildTableReportPdf ---
  // --- 🛑 (حذف) تم حذف _buildPdfTableRow ---
  // --- 🛑 (حذف) تم حذف _buildPdfTableHeader ---
  // --- 🛑 (حذف) تم حذف _buildPdfTableCell ---
  // --- 🛑 (حذف) تم حذف _buildOverallAnalysisPdf ---
  // --- 🛑 (حذف) تم حذف _buildSubjectPdf ---
  // --- 🛑 (حذف) تم حذف _buildPdfInfoRow ---

  Widget _buildNobleStudentView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "🏆 قاعة الشرف: الطلاب المنضبطين 🏆",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .orderBy('totalLikes', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا يوجد طلاب منظبطين حالياً.'));
              }
              final docs = snapshot.data!.docs;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (docs.length > 1) Flexible(child: _buildRankPodium(context, docs[1], 2)),
                    if (docs.isNotEmpty) Flexible(child: _buildRankPodium(context, docs[0], 1)),
                    if (docs.length > 2) Flexible(child: _buildRankPodium(context, docs[2], 3)),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.amber.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.white, size: 30),
                          SizedBox(width: 12),
                          Text(
                            "مكافأة الأبطال",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "سيتم تكريم هؤلاء الطلاب المنضبطين وتكريمهم بمكافآت قيمة في جميع الفعاليات والاحتفالات المدرسية تقديراً لتميزهم.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankPodium(BuildContext context, DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'طالب';
    final likes = data['totalLikes'] ?? 0;

    final podiumHeights = {1: 150.0, 2: 120.0, 3: 90.0};
    final rankColors = {
      1: Colors.amber,
      2: Colors.grey.shade400,
      3: const Color(0xFFCD7F32),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedTrophy(rank: rank),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up, color: Colors.blue.shade700, size: 16),
            const SizedBox(width: 4),
            Text('$likes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 100,
          height: podiumHeights[rank],
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
    );
  }

  Widget _buildTeacherComplaintsView() {
    if (_studentDocId == null) {
      return const Center(child: Text("لا يمكن عرض الملاحظات. الطالب غير معرّف."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('behavior_reports')
          .where('studentId', isEqualTo: _studentDocId)
          .where('type', isEqualTo: 'dislike')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                SizedBox(height: 20),
                Text(
                  'سجلك السلوكي نظيف!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'لم يتم تسجيل أي ملاحظات سلبية عليك.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
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
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'الإشعارات',
              onPressed: _showNotifications,
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.person_outline),
        tooltip: 'الملف الشخصي',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const StudentProfilePage())),
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'تسجيل الخروج',
        onPressed: _signOutAndGoToLogin,
      ),
    ];
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        if (_studentDocId == null) {
          return const Center(child: Text("لا يمكن عرض الإشعارات."));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            _markNotificationsAsRead();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("الإشعارات",
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .doc(_studentDocId)
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  "لا توجد إشعارات حالياً.",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                )));
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
                              ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                              .format(ts.toDate())
                              : '..';
                          final bool isLike =
                          (data['message'] ?? '').contains('نبل');
                          return ListTile(
                            leading: Icon(
                                isLike
                                    ? Icons.sentiment_very_satisfied
                                    : Icons.priority_high,
                                color: isLike ? Colors.green : Colors.red),
                            title: Text(data['message'] ?? '...'),
                            subtitle: Text(formattedDate),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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
    // --- ✅✅✅ START OF NOTIFICATION MODIFICATION ✅✅✅ ---
    // بمجرد قراءة الإشعارات، نقوم بمسح قائمة الإشعارات "المُعالجة"
    // للسماح بظهور إشعارات جديدة مرة أخرى
    _processedNotificationIds.clear();
    // --- ✅✅✅ END OF NOTIFICATION MODIFICATION ✅✅✅ ---
  }

  Future<void> _signOutAndGoToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'غير متوفر';
    return intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
        .format(timestamp.toDate());
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
  late final TextEditingController _replyController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
// student_view.dart

  Future<void> _submitReply() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final reportRef = FirebaseFirestore.instance
          .collection('behavior_reports')
          .doc(widget.reportDoc.id);

      await reportRef.update({
        'studentReply': _replyController.text.trim(),
        'replyTimestamp': FieldValue.serverTimestamp(),
        'status': 'replied_by_student',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال ردك بنجاح.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الرد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
        ? (isFinal ? Colors.grey.shade200 : Theme.of(context).primaryColor.withOpacity(0.1))
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
    final teacherNote = data['teacherNote'] ?? '...';
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
        statusColor = Colors.orange.shade300;
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: Text("مادة: $subject"),
              trailing: Chip(
                label: Text(statusText, style: const TextStyle(color: Colors.black87)),
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
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        labelText: 'اكتب ردك هنا لتوضيح الموقف',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء كتابة ردك';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _isSubmitting
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('إرسال الرد'),
                        onPressed: _submitReply,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

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
      1: {'color': const Color(0xFFFFD700), 'size': 70.0},
      2: {'color': const Color(0xFFC0C0C0), 'size': 60.0},
      3: {'color': const Color(0xFFCD7F32), 'size': 50.0},
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

// --- ✅✅✅ START OF (MAJOR REFACTOR) ✅✅✅ ---
// (تعديل) هذا الويدجت أصبح يعرض "قائمة" من التحليلات للمادة الواحدة
class _SubjectResultCard extends StatelessWidget {
  const _SubjectResultCard({
    required this.subjectName,
    required this.analyses, // (جديد) قائمة بالتحليلات (دوري، نافس، ...)
    required this.subjectIcon,
    required this.color,
    required this.allTestsMap,
  });

  final String subjectName;
  final List<_AnalysisResult> analyses; // (جديد)
  final IconData subjectIcon;
  final Color color;
  final Map<String, TestInfo> allTestsMap;

  // --- ✅ (جديد) دالة لشرح التقييم ---
  /// ويدجت جديد لشرح التقييم
  Widget _buildAssessmentExplanation(BuildContext context, String assessment) {
    String explanation;
    IconData icon;
    Color color;

    switch (assessment) {
      case 'متفوق ورائع!':
        explanation = 'أداء استثنائي! هذا يعني أن الطالب يتقن المهارات بشكل كامل ومتميز في هذا المقرر .';
        icon = Icons.auto_awesome;
        color = Colors.amber.shade700;
        break;
      case 'ممتاز':
        explanation = 'أداء ممتاز! الطالب يظهر فهماً قوياً للمادة ويتجاوز التوقعات في هذا المقرر  .';
        icon = Icons.check_circle;
        color = Colors.green.shade700;
        break;
      case 'جيد جداً':
        explanation = 'أداء جيد جداً! الطالب يظهر فهماً جيداً لمعظم المهارات في هذا المقرر  .';
        icon = Icons.thumb_up_alt;
        color = Colors.blue.shade700;
        break;
      case 'جيد':
        explanation = 'أداء جيد. الطالب يسير في المسار الصحيح ويظهر فهماً للمهارات الأساسية.';
        icon = Icons.trending_up;
        color = Colors.lightGreen.shade800;
        break;
      case 'مقبول':
        explanation = 'أداء مقبول. الطالب يحقق الحد الأدنى من المهارات المطلوبة في هذا المقرر  .';
        icon = Icons.thumbs_up_down;
        color = Colors.orange.shade800;
        break;
      case 'يحتاج لمتابعة':
      default:
        explanation = 'يحتاج لمتابعة. الطالب يواجه بعض الصعوبات ويحتاج إلى دعم إضافي في هذا المقرر  .';
        icon = Icons.warning_amber_rounded;
        color = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شرح التقييم: ($assessment)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- ✅ (نهاية) دالة شرح التقييم ---


  // (جديد) دالة لإنشاء ويدجت التحليل للمجموعة الواحدة
  Widget _buildAnalysisGroup(BuildContext context, _AnalysisResult analysis) {
    // تحديد لون العداد بناءً على التقييم
    Color gaugeColor;
    if (analysis.percentage >= 0.85)
      gaugeColor = Colors.green;
    else if (analysis.percentage >= 0.70)
      gaugeColor = Colors.blue;
    else if (analysis.percentage >= 0.50)
      gaugeColor = Colors.orange;
    else
      gaugeColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. اسم مجموعة التحليل (دوري، نافس، ...)
          Text(
            analysis.groupName, // "الاختبارات الدورية"
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 2. العداد الاحترافي (جديد)
              SizedBox(
                width: 130,
                height: 130,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 100,
                      showLabels: false,
                      showTicks: false,
                      axisLineStyle: AxisLineStyle(
                        thickness: 0.15,
                        cornerStyle: CornerStyle.bothCurve,
                        color: gaugeColor.withOpacity(0.2),
                        thicknessUnit: GaugeSizeUnit.factor,
                      ),
                      pointers: <GaugePointer>[
                        RangePointer(
                          value: analysis.percentage * 100,
                          cornerStyle: CornerStyle.bothCurve,
                          width: 0.15,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: gaugeColor,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          positionFactor: 0.1,
                          angle: 90,
                          widget: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${(analysis.percentage * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: gaugeColor,
                                ),
                              ),
                              Text(
                                analysis.assessment, // "ممتاز", "جيد", ...
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).scale(delay: 200.ms),
              const SizedBox(width: 16),
              // 3. المعلومات الأساسية (أعلى، أدنى، ...)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoChip(
                        label: 'المتوسط',
                        value: '${analysis.average.toStringAsFixed(1)} / ${analysis.maxPossibleGrade.toInt()}',
                        icon: Icons.functions,
                        color: color),
                    const SizedBox(height: 8),
                    _InfoChip(
                        label: 'مستوى الأداء',
                        value: analysis.consistency,
                        icon: Icons.show_chart_outlined,
                        color: color),
                    const SizedBox(height: 8),
                    _InfoChip(
                        label: 'أعلى درجة',
                        value: '${analysis.highestGrade} / ${analysis.maxPossibleGrade.toInt()}',
                        icon: Icons.arrow_upward_outlined,
                        color: Colors.green),
                    const SizedBox(height: 8),
                    _InfoChip(
                        label: 'أدنى درجة',
                        value: '${analysis.lowestGrade} / ${analysis.maxPossibleGrade.toInt()}',
                        icon: Icons.arrow_downward_outlined,
                        color: Colors.redAccent),
                  ],
                ).animate().fade(delay: 300.ms).slideX(begin: 0.2),
              ),
            ],
          ),
          // --- ✅ (جديد) إضافة شرح التقييم ---
          const SizedBox(height: 16),
          _buildAssessmentExplanation(context, analysis.assessment),
          // --- ✅ (نهاية) ---
          const Divider(height: 32),
          // 4. التحليل التنبؤي
          Text('التحليل التنبؤي للمسار',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildPredictiveInfo(
            context,
            icon: Icons.trending_up,
            color: analysis.performanceTrend.contains('تحسن')
                ? Colors.green
                : (analysis.performanceTrend.contains('تراجع')
                ? Colors.red
                : Colors.grey),
            label: 'اتجاه الأداء',
            value: analysis.performanceTrend,
          ),
          const SizedBox(height: 12),
          if (analysis.predictedNextGrade != null)
            _buildPredictiveInfo(
              context,
              icon: Icons.track_changes,
              color: Theme.of(context).primaryColor,
              label: 'الدرجة التالية المتوقعة',
              value:
              '~${analysis.predictedNextGrade!.toStringAsFixed(1)} / ${analysis.maxPossibleGrade.toInt()}',
            ),
          const Divider(height: 32),
          // 5. الرسم البياني للمجموعة
          Text('تتبع الأداء الزمني',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _PerformanceTrendChart(
              spots: analysis.trendSpots,
              color: color,
              maxGrade: analysis.maxPossibleGrade),
          const Divider(height: 32),
          // --- ✅ (تعديل) إظهار الدرجات مباشرة ---
          Text(
            'تفاصيل الدرجات (${analysis.groupName})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (analysis.testResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('لا توجد درجات مسجلة لهذه المجموعة.', style: TextStyle(color: Colors.grey)),
            )
          else
            Column(
              children: analysis.testResults.map((entry) {
                final testInfo = allTestsMap[entry.key];
                final testNameDisplay = testInfo?.name ?? entry.key;
                final double maxGradeForThisTest = (testInfo != null && testInfo.key.contains('profession13'))
                    ? 10.0
                    : 20.0;
                // --- ✅ (تعديل) تلوين الدرجة المنخفضة ---
                final bool isBelowPassing = entry.value >= 0 && entry.value < (maxGradeForThisTest / 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(testNameDisplay, style: const TextStyle(fontSize: 15)),
                      Text(
                        entry.value == -1
                            ? 'غائب'
                            : '${entry.value} / ${maxGradeForThisTest.toInt()}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: entry.value == -1
                              ? Colors.grey.shade600
                              : (isBelowPassing ? Colors.red.shade700 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          // --- 🛑 (حذف) تم حذف ExpansionTile ---
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.1);
  }

  // (جديد) دالة للحصول على ويدجت تقييم المسار الكلي
  Widget _getOverallRiskAssessmentWidget() {
    // تحديد المسار الأخطر بين جميع التحليلات
    String overallRisk = 'في المسار الصحيح';
    if (analyses.any((a) => a.riskAssessment == 'يحتاج دعم فوري')) {
      overallRisk = 'يحتاج دعم فوري';
    } else if (analyses.any((a) => a.riskAssessment == 'يحتاج لبعض التركيز')) {
      overallRisk = 'يحتاج لبعض التركيز';
    }

    IconData icon;
    Color color;
    switch (overallRisk) {
      case 'يحتاج دعم فوري':
        icon = Icons.dangerous;
        color = Colors.red.shade700;
        break;
      case 'يحتاج لبعض التركيز':
        icon = Icons.warning_amber_rounded;
        color = Colors.amber.shade800;
        break;
      default:
        icon = Icons.check_circle;
        color = Colors.green.shade700;
        break;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(overallRisk,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. رأس الكارت (اسم المادة والتقييم الإجمالي)
            Row(
              children: [
                Icon(subjectIcon, size: 28, color: color),
                const SizedBox(width: 12),
                Text(subjectName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                _getOverallRiskAssessmentWidget(), // (جديد)
              ],
            ),
            // 2. (جديد) المرور على قائمة التحليلات وبناء ويدجت لكل واحد
            ...analyses.map((analysis) => _buildAnalysisGroup(context, analysis)),
          ],
        ),
      ),
    ).animate().fade(duration: 200.ms);
  }
  // --- ✅✅✅ END OF (MAJOR REFACTOR) ✅✅✅ ---


  Widget _buildPredictiveInfo(BuildContext context,
      {required IconData icon,
        required Color color,
        required String label,
        required String value}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text('$label:',
            style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

class _PerformanceTrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double maxGrade;

  const _PerformanceTrendChart({
    required this.spots,
    required this.color,
    required this.maxGrade,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text(
            'يتطلب عرض الرسم البياني وجود اختبارين على الأقل.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    double yInterval = maxGrade / 4;
    if (yInterval < 1) yInterval = 1;

    double xInterval = (spots.length / 5).ceil().toDouble();
    if (xInterval < 1) xInterval = 1;

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(value.toInt().toString()),
                  ),
                )
            ),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: xInterval,
                    getTitlesWidget: _bottomTitleWidgets)),
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1)),
          minY: 0,
          maxY: maxGrade, // Use maxGrade from analysis
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white)),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: color.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  return LineTooltipItem(touchedSpot.y.toStringAsFixed(1), textStyle);
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ).animate().fade(duration: 500.ms), // (جديد) إضافة أنيميشن
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey.shade700,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text('خ${value.toInt() + 1}', style: style),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({required this.text, required this.style});
  @override
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_scrollController.hasClients || !_scrollController.position.hasContentDimensions || _scrollController.position.maxScrollExtent == 0) {
        return;
      }
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) {
          timer.cancel();
          return;
        }
        try {
          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: (widget.text.length * 150).clamp(2000, 8000)),
            curve: Curves.ease,
          );
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted || !_scrollController.hasClients) {
            timer.cancel();
            return;
          }
          await _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: (widget.text.length * 150).clamp(2000, 8000)),
            curve: Curves.ease,
          );
        } catch (e) {
          print("Error during marquee animation: $e");
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
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