// student_view.dart
// ✅ (FIXED) تم إصلاح مشكلة القفز للأعلى عند تصفح النتائج بإزالة السكرول المتداخل
// ✅ (ADDED) تم تفعيل زر فيزا الطلاب وإضافة صفحة العرض الخاصة بها

import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;

import 'package:almarefamecca/student_results_view.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

// --- PDF/PRINTING IMPORTS ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// --- END OF PDF IMPORTS ---

import 'package:almarefamecca/secondary_pages.dart';

import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for PDF fonts/images
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:universal_html/html.dart' as html;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:card_swiper/card_swiper.dart';

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
  final int count;
  final bool isWorking;

  _DashboardButtonData({
    required this.title,
    required this.icon,
    this.assetPath,
    required this.color,
    required this.onTap,
    this.count = 0,
    this.isWorking = true,
  });
}

class _StudentViewPageState extends State<StudentViewPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  StudentView _currentView = StudentView.dashboard;
  late TabController _tabController;
  final Map<String, Color> _subjectColors = {};

  String? _studentDocId;

  late final Map<String, TestInfo> _allTestsMap;
  bool _isPrinting = false;
  StreamSubscription? _notificationSubscription;
  final Set<String> _processedNotificationIds = {};

  Timer? _lastSeenTimer;
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
    Subject(name: 'مصدر', icon: Icons.source),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isTeacherView = widget.studentId != null;
    _initializeData();
  }

  // ✅✅✅ دالة التحديث الموحدة ✅✅✅
  Future<void> _onRefresh() async {
    // انتظار بسيط لرؤية الأيقونة
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 800));
      html.window.location.reload();
    } else {
      _initializeData(); // إعادة تحميل البيانات
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
    _tabController.dispose();
    _notificationSubscription?.cancel();
    _lastSeenTimer?.cancel();
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
        debugPrint("Error updating lastSeen via timer: $e");
      }
    }
  }

  void _startLastSeenTimer() {
    _lastSeenTimer?.cancel();
    _lastSeenTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateLastSeen();
    });
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
    };

    standardSubjects.forEach((profKey, subjName) {
      tests.add(TestInfo(key: 'e1$profKey', name: 'الاختبار الأول (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e2$profKey', name: 'الاختبار الثاني (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e3$profKey', name: 'الاختبار الثالث (دوري)', subject: subjName, testGroup: 'periodic'));
      tests.add(TestInfo(key: 'e14$profKey', name: 'اختبار قبلي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e15$profKey', name: 'اختبار بعدي', subject: subjName, testGroup: 'additional'));
      tests.add(TestInfo(key: 'e16$profKey', name: 'اختبار احتياطي', subject: subjName, testGroup: 'additional'));
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

        if (!_isTeacherView && _studentDocId != null) {
          _listenForNewNotifications();
          _requestNotificationPermission();
          _startLastSeenTimer();
        }

      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching student data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _requestNotificationPermission() {
    if (kIsWeb) {
      if (html.Notification.supported) {
        html.Notification.requestPermission().then((permission) {
          if (permission != 'granted') {
            debugPrint('Notification permission not granted.');
          }
        });
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
    }, onError: (error) {
      debugPrint("Error listening to notifications: $error");
    });
  }

  void _playNotificationSound() {
    if (kIsWeb) {
      try {
        final html.AudioElement audio = html.AudioElement('1.mp3');
        audio.play();
      } catch (e) {
        debugPrint("Error playing notification sound: $e");
      }
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
        bool _isChecking = false;
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
                    Icon(
                      Icons.lock_person_outlined,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مطلوب إذن ولي الأمر',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
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
                      readOnly: _isChecking,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.key_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  onPressed: _isChecking ? null : () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  icon: _isChecking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: Text(_isChecking ? 'جاري التحقق...' : 'دخول'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isChecking ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => _isChecking = true);

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
                        debugPrint("Error checking password: $e");
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

  Future<void> _generateAndSavePdf() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تحضير ملف PDF...')),
    );

    try {
      debugPrint("PDF: Loading fonts...");
      pw.Font regularFont;
      pw.Font boldFont;
      try {
        regularFont = await PdfGoogleFonts.cairoRegular();
        boldFont = await PdfGoogleFonts.cairoBold();
      } catch (fontError) {
        debugPrint("PDF: Font loading failed: $fontError. Using fallback.");
        regularFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }
      debugPrint("PDF: Fonts loaded.");
      final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

      debugPrint("PDF: Capturing widget image...");
      debugPrint("PDF: Widget captured.");

      final doc = pw.Document(theme: theme);

      final studentName = _studentData?['name'] ?? 'طالب';
      final studentClass = "${_studentData?['stages'] ?? ''} / ${_studentData?['grades'] ?? ''} / ${_studentData?['classes'] ?? ''}";

      doc.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            textDirection: pw.TextDirection.rtl,
            margin: pw.EdgeInsets.all(32),
          ),
          header: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20.0),
            child: pw.Column(
                children: [
                  pw.Text('تقرير الأداء الأكاديمي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22)),
                  pw.Text('الطالب: $studentName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text(studentClass, style: const pw.TextStyle(fontSize: 16)),
                  pw.Divider(color: PdfColors.grey)
                ]
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10.0),
            child: pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          ),
          build: (context) => [
          ],
        ),
      );
      debugPrint("PDF: Page added.");

      debugPrint("PDF: Saving layout...");
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
      debugPrint("PDF: Save complete.");

    } catch (e, s) {
      debugPrint("------- Error generating PDF from widget capture -------");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $s");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء ملف PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      // ✅ تغليف المحتوى بـ RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 40.0,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            _buildBody(), // الآن _buildBody يضمن إرجاع قوائم قابلة للسحب
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
        baseTitle = 'قاعة الشرف للطلاب المنضبطين';
        break;
      case StudentView.teacherComplaints:
        baseTitle = 'سجل الملاحظات السلوكية';
        break;
      default:
        baseTitle = _isTeacherView ? 'تقرير الطالب: $studentName' : 'لوحة الطالب';
    }

    titleWidget = Text(
      baseTitle,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );


    List<Widget> appBarActions = [];
    if (isDashboard && !_isTeacherView) {
      appBarActions.addAll(_buildDashboardActions());
    }

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
            child: Image.asset('assets/2.png', color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).primaryColor,
      elevation: 1.0,
      title: titleWidget,
      centerTitle: true, // دائما توسيط العنوان
      leading: (_isTeacherView && isDashboard) || !isDashboard
          ? IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor),
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
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          child: AnimatedTextKit(
            animatedTexts: [
              RotateAnimatedText(
                'مبرمج المنصة: أ/ مصطفي سعيد',
                textAlign: TextAlign.center,
                textStyle: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Cairo',
                ),
              ),
              RotateAnimatedText(
                'باشراف ابتدائية المعرفة الاهلية بمكة ',
                textAlign: TextAlign.center,
                textStyle: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Cairo',
                ),
              ),
              RotateAnimatedText(
                'هذا الاصدار تجريبي ونتمني لكم يوما سعيدا',
                textAlign: TextAlign.center,
                textStyle: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
            repeatForever: true,
            pause: const Duration(milliseconds: 1500),
          ),
        ),
      )
          : null,
    );
  }

  // ✅ تعديل هنا لضمان أن كل صفحة ترجع قائمة قابلة للسحب
  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_studentData == null) {
      return ListView( // ✅ استخدام ListView بدلاً من Center ليقبل السحب
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.4),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('عفواً، لم يتم العثور على بيانات الطالب.'),
                  const SizedBox(height: 20),
                  if (!_isTeacherView)
                    ElevatedButton(
                      onPressed: _signOutAndGoToLogin,
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
      // ✅✅✅ الإصلاح: إزالة SingleChildScrollView هنا لأن صفحة النتائج تحتوي عليه بالفعل ✅✅✅
        return StudentResultsView(
          studentData: _studentData!,
          allTestsMap: _allTestsMap,
          subjects: subjects,
          subjectColors: _subjectColors,
          printKey: _printKey,
        );
      case StudentView.noble:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildNobleStudentView(),
        );
      case StudentView.teacherComplaints:
        return _buildTeacherComplaintsView();
      default:
      // الداشبورد هو ListView أصلاً
        return _buildDashboard();
    }
  }

  void _showPlaceholderSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ✅✅✅ دالة بناء الداشبورد المعدلة (مع الهيدر) ✅✅✅
  Widget _buildDashboard() {
    final int totalLikes = _studentData?['totalLikes'] ?? 0;
    final int totalDislikes = _studentData?['totalDislikes'] ?? 0;

    final Map<String, String> imageMap = {
      'النتائج والتحليل': 'assets/a13.png',
      'الطالب المنضبط': 'assets/a1.png',
      'الملاحظات السلوكية': 'assets/a9.png',
      'فيزا الطلاب': 'assets/a2.png',
      'الكتاب المدرسي': 'assets/a3.png',
      'الاحتفالات': 'assets/a5.png',
      'استديو الطالب': 'assets/a11.png',
      'التوكاتسو ': 'assets/a4.png',
      'المسابقات': 'assets/a10.png',
      'المؤذن': 'assets/a6.png',
    };

    final List<_DashboardButtonData> buttonDataList = [
      _DashboardButtonData(
        title: 'النتائج والتحليل',
        icon: Icons.bar_chart_rounded,
        assetPath: imageMap['النتائج والتحليل'],
        color: Colors.green.shade700,
        onTap: () => setState(() => _currentView = StudentView.results),
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الطالب المنضبط',
        icon: Icons.thumb_up,
        assetPath: imageMap['الطالب المنضبط'],
        color: Colors.blue.shade700,
        count: totalLikes,
        onTap: () => setState(() => _currentView = StudentView.noble),
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الملاحظات السلوكية',
        icon: Icons.report_problem_outlined,
        assetPath: imageMap['الملاحظات السلوكية'],
        color: Colors.red.shade700,
        count: totalDislikes,
        onTap: _promptForParentPassword,
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الكتاب المدرسي',
        icon: Icons.menu_book,
        assetPath: imageMap['الكتاب المدرسي'],
        color: Colors.brown.shade500,
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
        color: Colors.amber.shade800,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TokkatsuViewPage()),
          );
        },
        isWorking: true,
      ),
      // ✅✅✅ زر فيزا الطلاب المفعل ✅✅✅
      _DashboardButtonData(
        title: 'فيزا الطلاب',
        icon: Icons.credit_card,
        assetPath: imageMap['فيزا الطلاب'],
        color: Colors.deepPurple.shade500,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentVisaPage(studentData: _studentData!)),
          );
        },
        isWorking: true,
      ),
      _DashboardButtonData(
        title: 'الاحتفالات',
        icon: Icons.celebration,
        assetPath: imageMap['الاحتفالات'],
        color: Colors.pink.shade500,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
        isWorking: false,
      ),
      _DashboardButtonData(
        title: 'استديو الطالب',
        icon: Icons.photo_library,
        assetPath: imageMap['استديو الطالب'],
        color: Colors.orange.shade700,
        onTap: () => _showPlaceholderSnackBar('لا يوجد صور لك متوفرة حالياً.'),
        isWorking: false,
      ),
      _DashboardButtonData(
        title: 'المسابقات',
        icon: Icons.military_tech,
        assetPath: imageMap['المسابقات'],
        color: Colors.lightGreen.shade700,
        onTap: () => _showPlaceholderSnackBar('لا توجد مسابقات حالية الآن.'),
        isWorking: false,
      ),
      _DashboardButtonData(
        title: 'المؤذن',
        icon: Icons.mic,
        assetPath: imageMap['المؤذن'],
        color: Colors.cyan.shade600,
        onTap: () => _showPlaceholderSnackBar('سيتوفر قريبا'),
        isWorking: false,
      ),
    ];

    // ✅✅✅ الهيدر المطابق لحساب المعلم ✅✅✅
    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade500],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // الصورة الشخصية للطالب (أو أيقونة افتراضية)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
              ),
              child: CircleAvatar(
                radius: 22,
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
                    ? const Icon(Icons.person, color: Colors.blue, size: 26)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // الاسم والصف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مرحباً، ${_studentData?['name'] ?? '...'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      // عرض الصف والفصل بدلاً من المسمى الوظيفي
                      '${_studentData?['grades'] ?? ''} - ${_studentData?['classes'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: 0.7,
              child: Icon(Icons.school_outlined, color: Colors.white.withOpacity(0.2), size: 40),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero, // إزالة الحشو الافتراضي ليلتصق الهيدر بالأعلى
      children: [
        buildHeader(),
        const SizedBox(height: 10),
        // عرض شبكة الأزرار
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AnimationLimiter(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buttonDataList.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 150 / 180,
              ),
              itemBuilder: (context, index) {
                final data = buttonDataList[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: (MediaQuery.of(context).size.width / (150 + 16)).floor(),
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              width: 150,
                              child: _buildDashboardButton(
                                icon: data.icon,
                                assetPath: data.assetPath,
                                color: data.color,
                                onTap: data.onTap,
                                count: data.count,
                                isWorking: data.isWorking,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            flex: 1,
                            child: Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
    int count = 0,
    required bool isWorking,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: (assetPath != null && assetPath.isNotEmpty)
                  ? Image.asset(
                assetPath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(icon, size: 40, color: Colors.white),
                  );
                },
              )
                  : Center(
                child: Icon(icon, size: 40, color: Colors.white),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

            // مؤشر الحالة (صح أزرق أو ترس انتظار)
            Positioned(
              bottom: 10,
              left: 10,
              child: Tooltip(
                message: isWorking ? 'خدمة مفعلة' : 'قيد التطوير',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
                    ],
                  ),
                  child: Icon(
                    isWorking ? Icons.check_circle_rounded : Icons.settings_suggest_rounded,
                    size: 18,
                    color: isWorking ? Colors.blue : Colors.orange.shade300,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- ✅✅✅ معايير الطالب المنضبط (مع إصلاح قص النصوص) ✅✅✅ ---
  Widget _buildNobleCriteriaSlider() {
    final List<Map<String, dynamic>> nobleCriteria = [
      {
        'title': 'السمت الحسن والصلاة',
        'icon': Icons.mosque,
        'color': Colors.teal,
        'desc': 'المحافظة على الصلاة في وقتها والتحلي بالوقار.'
      },
      {
        'title': 'أدب الحوار وخفض الصوت',
        'icon': Icons.record_voice_over,
        'color': Colors.indigo,
        'desc': 'الحديث بأدب وعدم رفع الصوت فوق صوت المعلم.'
      },
      {
        'title': 'الاحترام والأخوة',
        'icon': Icons.handshake,
        'color': Colors.blue,
        'desc': 'احترام المعلمين والزملاء وتقديرهم.'
      },
      {
        'title': 'بيئتي مسؤوليتي',
        'icon': Icons.cleaning_services,
        'color': Colors.green,
        'desc': 'المحافظة الدائمة على نظافة الفصل والممتلكات.'
      },
      {
        'title': 'الهدوء والسكينة',
        'icon': Icons.self_improvement,
        'color': Colors.purple,
        'desc': 'الالتزام بالهدوء وتجنب الفوضى داخل الصف.'
      },
      {
        'title': 'التعاون والإيثار',
        'icon': Icons.volunteer_activism,
        'color': Colors.redAccent,
        'desc': 'مساعدة الزملاء وتفضيل المصلحة العامة.'
      },
      {
        'title': 'الجدية والاجتهاد',
        'icon': Icons.edit_note,
        'color': Colors.orange,
        'desc': 'إنجاز المهام والواجبات والمشاركة الفاعلة.'
      },
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth * 0.45).clamp(170.0, 220.0);
    const double sliderHeight = 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(Icons.stars_rounded, color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(width: 8),
              Text(
                "معايير اختيار الطلاب المنضبطين:",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: sliderHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                ui.PointerDeviceKind.touch,
                ui.PointerDeviceKind.mouse,
              },
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: nobleCriteria.length,
              itemBuilder: (context, index) {
                final item = nobleCriteria[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (item['color'] as Color).withOpacity(0.05),
                        (item['color'] as Color).withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (item['color'] as Color).withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (item['color'] as Color).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(item['icon'], color: item['color'], size: 34),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Text(
                              item['desc'],
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNobleStudentView() {
    // ✅ دمج المحتوى في Column
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            "🏆 قاعة الشرف: فرسان الانضباط 🏆",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        // ✅ (MODIFIED) جرس التنبيهات الخاص للطالب المنضبط
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .doc(_studentDocId) // تأكد أن متغير رقم الطالب متاح هنا
              .collection('notifications')
              .where('isRead', isEqualTo: false) // نعد فقط غير المقروء
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, size: 30, color: Colors.blue), // لون أزرق
                  onPressed: () => _showNotifications(1), // ✅ فتح على تبويب الإشعارات الخاصة (1)
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue, // ✅ لون أزرق للتناسق
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        )

        ,_buildNobleCriteriaSlider(),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.black87, fontSize: 12, height: 1.5),
                    children: [
                      const TextSpan(
                        text: "تنويه هام: ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const TextSpan(
                        text: "نقاط التميز (اللايكات) تُمنح بشكل ",
                      ),
                      const TextSpan(
                        text: "تتابعي وتراكمي ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: "يعكس استمرار انضباط الطالب، وهي ثمرة ",
                      ),
                      const TextSpan(
                        text: "تقييم تكاملي تشاركي بين جميع المعلمين، ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: "ولا يتم منحها بشكل عشوائي.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      "سيتم تكريم هؤلاء الطلاب المنضبطين وتكريمهم بمكافآت قيمة في جميع الفعاليات والاحتفالات المدرسية تقديراً لتميزهم السلوكي والأخلاقي.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
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
    );
  }

  Widget _buildTeacherComplaintsView() {
    if (_studentDocId == null) {
      return ListView(children: [const SizedBox(height: 300), const Center(child: Text("لا يمكن عرض الملاحظات. الطالب غير معرّف."))]);
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
        // ✅ تحويل الحالة الفارغة إلى قائمة قابلة للسحب
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
    final Color iconColor = Theme.of(context).primaryColor;

    return [
      // ✅ 1. أيقونة الإشعارات العامة (خضراء بالكامل)
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcast_notifications')
            .orderBy('timestamp', descending: true)
            .limit(10) // تتبع آخر 10 فقط
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          // (يمكن تحسين المنطق لعد "غير المقروء" فقط إذا تم حفظ حالة القراءة محلياً)
          // هنا نعرض نقطة إذا كان هناك تعاميم حديثة (كمثال)
          return badges.Badge(
            showBadge: count > 0,
            badgeContent: Text('!', // رمز تنبيه
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            badgeStyle: badges.BadgeStyle(badgeColor: Colors.green), // ✅ لون الشارة أخضر
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            child: IconButton(
              icon: Icon(Icons.notifications_active, color: Colors.green.shade600), // ✅ لون الأيقونة أخضر
              tooltip: 'التعاميم العامة',
              onPressed: () => _showNotifications(0), // فتح تبويب التعاميم (0)
            ),
          );
        },
      ),

      // ✅ 2. أيقونة الإشعارات الخاصة (زرقاء بالكامل)
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
            badgeStyle: badges.BadgeStyle(badgeColor: Colors.blue), // ✅ لون الشارة أزرق
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            child: IconButton(
              icon: Icon(Icons.notifications, color: iconColor), // ✅ لون الأيقونة أزرق (primary)
              tooltip: 'إشعاراتي',
              onPressed: () => _showNotifications(1), // فتح تبويب إشعارات خاصة (1)
            ),
          );
        },
      ),
      IconButton(
        icon: Icon(Icons.person_outline, color: iconColor),
        tooltip: 'الملف الشخصي',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const StudentProfilePage())),
      ),
      IconButton(
        icon: Icon(Icons.logout, color: iconColor),
        tooltip: 'تسجيل الخروج',
        onPressed: _signOutAndGoToLogin,
      ),
    ];
  }

  // ✅ تعديل الدالة لتقبل initialIndex
  void _showNotifications(int initialIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // استخدام DefaultTabController للتبديل بين الإشعارات العامة والخاصة
        return DefaultTabController(
          length: 2,
          initialIndex: initialIndex, // تحديد التبويب المختار
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              // عند فتح القائمة، نعتبر الإشعارات الخاصة مقروءة إذا كنا في التبويب الخاص
              // (للبساطة هنا نقوم بذلك عند الفتح)
              _markNotificationsAsRead();

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("مركز الإشعارات",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  // شريط التبويب
                  const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: "تعاميم عامة"), // تبويب 0
                      Tab(text: "إشعارات خاصة"), // تبويب 1
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 1. تبويب الإشعارات العامة (المصدر: broadcast_notifications)
                        _buildNotificationList(
                          stream: FirebaseFirestore.instance
                              .collection('broadcast_notifications')
                              .orderBy('timestamp', descending: true)
                              .limit(50) // آخر 50 إشعار فقط
                              .snapshots(),
                          isPublic: true,
                          scrollController: scrollController,
                        ),

                        // 2. تبويب الإشعارات الخاصة (المصدر: students -> notifications)
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

  // دالة مساعدة لبناء القائمة (أضفها داخل الكلاس _StudentViewPageState)
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

            // تحديد العنوان والنص بناء على نوع الإشعار
            String title = isPublic ? (data['title'] ?? 'إشعار عام') : 'تنبيه';
            String body = isPublic ? (data['body'] ?? '...') : (data['message'] ?? '...');
            String senderName = isPublic ? (data['senderName'] ?? 'الإدارة') : 'النظام';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPublic ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                child: Icon(
                  isPublic ? Icons.campaign : Icons.person,
                  color: isPublic ? Colors.green.shade700 : Colors.blue,
                ),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formattedDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (isPublic) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.person_outline, size: 12, color: Colors.grey),
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
    _lastSeenTimer?.cancel();
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
                      content: Text('حدث خطأ أثناء إرسال الرد: $e'),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
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
                        Icon(Icons.reply_rounded, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'الرد على الملاحظة',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('الرد على الملاحظة'),
                  onPressed: () => _showReplySheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
  // قائمة البيانات
  final List<TokkatsuItem> tokkatsuItems = const [
    TokkatsuItem(
      imagePath: 'assets/m1.png',
      title: 'المقدمة',
      description: 'أهلاً بكم في رحلة التوكاتسو. هذا النظام ليس مجرد أنشطة، بل هو أسلوب حياة يهدف لبناء شخصية متوازنة ومبدعة قادرة على مواجهة تحديات المستقبل.',
    ),
    TokkatsuItem(
      imagePath: 'assets/t9.png',
      title: 'ما هو التوكاتسو؟',
      description: 'التوكاتسو (Tokkatsu) هي أنشطة لا صفية يابانية، تركز على تنمية المهارات غير المعرفية مثل: التعاون، الانضباط، الاحترام، والعمل الجماعي، لبناء المواطن الصالح.',
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
      description: 'نظام تبادل الأدوار القيادية، حيث يكون كل طالب "قائداً" للفصل ليوم واحد، مما يكسر حاجز الخوف وينمي المهارات القيادية.',
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
    // تحديد عرض الشاشة
    final double screenWidth = MediaQuery.of(context).size.width;
    // تحديد هل نحن على شاشة واسعة أم لا
    final bool isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية هادئة جداً
      appBar: AppBar(
        title: const Text(
          'أنشطة التوكاتسو',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ✅ الحل السحري: التوسيط + تقييد العرض
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800, // أقصى عرض للمحتوى هو 800 بكسل حتى لو الشاشة 4K
          ),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: isWideScreen ? 0 : 16.0, // هوامش جانبية فقط في الموبايل
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
        // ظل ناعم يعطي عمقاً للتصميم
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // لقص الصورة داخل الحواف الدائرية
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ استخدام AspectRatio يحافظ على تناسب الصورة مهما كان العرض
          AspectRatio(
            aspectRatio: isWideScreen ? 21 / 9 : 16 / 9, // في الشاشات العريضة نجعل الصورة بانورامية أكثر
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
          ),

          // المحتوى النصي
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
                    color: Color(0xFF1565C0),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                // خط زخرفي صغير تحت العنوان
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.amber,
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
                    height: 1.7, // تباعد أسطر مريح للقراءة
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
        title: const Text('الكتب والمقررات الدراسية'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.white],
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
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
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
    // منطق تحديد المحتوى بناءً على الصف الدراسي
    String title = "المهارات الرقمية";
    Widget content;
    Color cardColor = Colors.blue.shade50;

    // الصفوف الأولية (1-3)
    if (['الصف الأول', 'الصف الثاني', 'الصف الثالث'].contains(grade)) {
      content = _buildInfoContent(
        icon: Icons.local_library_rounded,
        title: "نسخة ورقية",
        text: "عزيزي الطالب، يتم تسليم النسخة الورقية من كتاب المهارات الرقمية لك مباشرة في المدرسة.",
        color: Colors.blue.shade700,
      );
    }
    // الصف الرابع
    else if (grade == 'الصف الرابع') {
      content = _buildLinkContent(
        context,
        url: "https://ktby.net/10767/",
        desc: "كتاب المهارات الرقمية - الصف الرابع (نسخة إلكترونية)",
        btnText: "تصفح الكتاب الآن",
      );
      cardColor = Colors.indigo.shade50;
    }
    // الصف الخامس
    else if (grade == 'الصف الخامس') {
      content = _buildLinkContent(
        context,
        url: "https://ktby.net/10769/",
        desc: "كتاب المهارات الرقمية - الصف الخامس (نسخة إلكترونية)",
        btnText: "تصفح الكتاب الآن",
      );
      cardColor = Colors.indigo.shade50;
    }
    // الصف السادس
    else if (grade == 'الصف السادس') {
      content = _buildLinkContent(
        context,
        url: "https://ktby.net/10770/",
        desc: "كتاب المهارات الرقمية - الصف السادس (نسخة إلكترونية)",
        btnText: "تصفح الكتاب الآن",
      );
      cardColor = Colors.indigo.shade50;
    }
    // صفوف أخرى (احتياطي)
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
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.laptop_mac, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.precision_manufacturing, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                const Expanded(
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
          // Content
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
                      final Uri url = Uri.parse('https://wa.me/966502649649'); // رقم الأستاذ يحيي
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
          Icon(Icons.check_circle_outline, color: Colors.deepPurple.shade300, size: 20),
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
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(btnText),
            style: ElevatedButton.styleFrom(
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

// ✅✅✅ صفحة عرض الفيزا للطلاب (جديد) ✅✅✅
class StudentVisaPage extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentVisaPage({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    final String? visaCode = studentData['visaCode'];
    final String studentName = studentData['name'] ?? 'طالب';

    return Scaffold(
      appBar: AppBar(
        title: const Text('فيزا الطلاب الرقمية'),
        backgroundColor: Colors.deepPurple.shade600,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (visaCode != null && visaCode.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.nfc, color: Colors.white54, size: 30),
                            Image.asset('assets/m1.png', width: 40, color: Colors.white.withOpacity(0.8)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // استخدام رابط API موثوق لعرض QR Code لضمان العمل بدون مكتبات خارجية معقدة
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$visaCode',
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 180,
                                width: 180,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 180,
                                width: 180,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red),
                                    Text("تعذر تحميل الرمز"),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _formatVisaCode(visaCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('STUDENT NAME', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text(studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Icon(Icons.credit_card, color: Colors.white70, size: 35),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('نسخ رقم الفيزا'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: visaCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الكود بنجاح!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ] else ...[
                const Icon(Icons.credit_card_off, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'عفواً، لم يتم إصدار فيزا لك بعد.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يرجى مراجعة إدارة المدرسة لتفعيل حسابك.',
                  style: TextStyle(color: Colors.grey),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  String _formatVisaCode(String code) {
    // تقسيم الكود إلى مجموعات من 4 أحرف
    if (code.length != 16) return code;
    return '${code.substring(0, 4)}  ${code.substring(4, 8)}  ${code.substring(8, 12)}  ${code.substring(12, 16)}';
  }
}