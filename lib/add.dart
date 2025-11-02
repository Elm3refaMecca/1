// add.dart (MODIFIED - تمت إضافة قسم إحصائيات لعدد الزوار والمتصلين للأدمن)

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:almarefamecca/online_students_page.dart';
import 'package:almarefamecca/profile_page.dart';
import 'package:almarefamecca/student_view.dart';
import 'package:almarefamecca/test_selection_page.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:universal_html/html.dart' as html;
// --- (إضافة جديدة) المكتبات المطلوبة ---
import 'package:url_launcher/url_launcher.dart';

// --- ✅✅✅  إضافة المكتبة المطلوبة للتكريم  ✅✅✅ ---
import 'package:animated_text_kit/animated_text_kit.dart';


class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isExporting = false; // خاص بالأيقونة الزرقاء (الادمن)
  bool _isMassExporting = false; // خاص بالأيقونة الخضراء (المعلم)
  bool _isAdmin = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (!mounted) return;

      final data = userDataSnapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _userData = data;
        _isAdmin = data['profession'] == 'admin';
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchEduFormsUrl() async {
    final Uri url = Uri.parse('https://edu-forms.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح الرابط: $url')),
        );
      }
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (_user == null) {
          return const Center(child: Text("المستخدم غير مسجل."));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("الإشعارات", style: Theme.of(context).textTheme.headlineSmall),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
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
                          child: Text("لا توجد إشعارات حالياً.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markNotificationsAsRead(snapshot.data!.docs);
                    });

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

                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(data['message'] ?? '...'),
                          subtitle: Text(formattedDate),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _markNotificationsAsRead(List<QueryDocumentSnapshot> docs) {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      if (doc.data() is Map<String, dynamic> && !(doc.data() as Map<String, dynamic>)['isRead']) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    batch.commit().catchError((e) {
      // Optional: handle error
    });
  }

  Future<void> _exportFullSchoolDataToExcel() async {
    setState(() => _isExporting = true);

    try {
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      final students = studentsSnapshot.docs;
      final testToSubjectMap = SchoolAnalyticsPage._createTestToSubjectMap();
      final allSubjects = testToSubjectMap.values.toSet().toList()..sort();

      final excel = Excel.createExcel();
      final sheet = excel['بيانات المدرسة كاملة'];
      sheet.isRTL = true;
      excel.delete('Sheet1');

      final headers = ['المرحلة', 'الصف', 'الفصل', 'اسم الطالب', ...allSubjects];

      final headerStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString("#FF1976D2"), // Blue color
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center
      );
      final separatorStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString("#FFFFEB3B"), // Yellow color
          horizontalAlign: HorizontalAlign.Center
      );


      final Map<String, Map<String, Map<String, List<DocumentSnapshot>>>> schoolStructure = {};
      for (var studentDoc in students) {
        final data = studentDoc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final stage = data['stages'] as String? ?? 'N/A';
        final grade = data['grades'] as String? ?? 'N/A';
        final className = data['classes'] as String? ?? 'N/A';
        schoolStructure.putIfAbsent(stage, () => {}).putIfAbsent(grade, () => {}).putIfAbsent(className, () => []).add(studentDoc);
      }

      final gradeOrder = [
        'الصف السادس', 'الصف الخامس', 'الصف الرابع', 'الصف الثالث', 'الصف الثاني', 'الصف الأول',
        'الصف الثالث المتوسط', 'الصف الثاني المتوسط', 'الصف الأول المتوسط',
        'الصف الثالث الثانوي', 'الصف الثاني الثانوي', 'الصف الأول الثانوي'
      ];

      for (int i = 0; i < 2; i++) {
        schoolStructure.forEach((stage, grades) {
          for (final gradeName in gradeOrder) {
            if (grades.containsKey(gradeName)) {
              final classes = grades[gradeName];
              if (classes == null) continue;

              classes.forEach((className, studentList) {
                // --- 1. Add Separator Row ---
                sheet.appendRow([]); // Empty row for spacing
                final separatorRowIndex = sheet.maxRows;
                final classKey = '$stage - $gradeName - $className';
                sheet.merge(
                    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: separatorRowIndex),
                    CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: separatorRowIndex)
                );
                var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: separatorRowIndex));
                cell.value = TextCellValue("كشف درجات: $classKey");
                cell.cellStyle = separatorStyle;

                // --- 2. Add Header Row (Repeated) ---
                sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
                final headerRowIndex = sheet.maxRows - 1; // The row we just added
                for(int i=0; i<headers.length; i++) {
                  sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRowIndex)).cellStyle = headerStyle;
                }

                // --- 3. Sort and Add Student Data ---
                studentList.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>?;
                  final bData = b.data() as Map<String, dynamic>?;
                  final aName = aData?['name'] as String? ?? '';
                  final bName = bData?['name'] as String? ?? '';
                  return aName.compareTo(bName);
                });

                for (var studentDoc in studentList) {
                  final data = studentDoc.data() as Map<String, dynamic>?;
                  if (data == null) continue;

                  final studentName = data['name'] as String? ?? 'N/A';

                  final subjectAverages = <String, double>{};
                  final subjectScores = <String, List<num>>{};

                  data.forEach((key, value) {
                    if (value is num && testToSubjectMap.containsKey(key)) {
                      final subject = testToSubjectMap[key];
                      if (subject != null) {
                        subjectScores.putIfAbsent(subject, () => []).add(value);
                      }
                    }
                  });

                  subjectScores.forEach((subject, scores) {
                    if (scores.isNotEmpty) {
                      subjectAverages[subject] = scores.reduce((a, b) => a + b) / scores.length;
                    }
                  });

                  final List<CellValue> row = [
                    TextCellValue(stage),
                    TextCellValue(gradeName),
                    TextCellValue(className),
                    TextCellValue(studentName),
                    ...allSubjects.map((subject) {
                      final avg = subjectAverages[subject];
                      return avg != null ? DoubleCellValue(double.parse(avg.toStringAsFixed(2))) : TextCellValue('');
                    })
                  ];
                  sheet.appendRow(row);
                }
              });
            }
          }
        });
      }

      _saveAndDownloadExcel(context, excel, 'بيانات_المدرسة_الكاملة.xlsx');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير البيانات: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Tooltip(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_userData?['name'] ?? 'أهلاً بك', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_isAdmin ? 'Admin Access' : (_userData?['profession1'] ?? 'معلم'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _user == null ? null : FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return badges.Badge(
                showBadge: count > 0,
                badgeContent: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0), // ارتفاع مناسب
          child: Container(
            height: 30.0,
            alignment: Alignment.center,
            color: Colors.deepPurple.shade700, // لون مميز للتكريم
            child: SizedBox(
              width: 210, // عرض مناسب
              child: AnimatedTextKit(
                animatedTexts: [
                  RotateAnimatedText(
                    'مبرمج المنصة: أ/ مصطفي سعيد',
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo', // ضمان استخدام الخط العربي
                    ),
                  ),
                  RotateAnimatedText(
                    'باشراف ابتدائية المعرفة الاهلية بمكة المكرمة ',
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  RotateAnimatedText(
                    'للدعم الفني: 966569064173+',
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
                repeatForever: true, // تكرار لا نهائي
                pause: const Duration(milliseconds: 1500), // مدة التوقف بين كل نص
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isExporting || _isMassExporting
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          _isExporting
              ? "جاري تصدير ملف الإدارة، قد يستغرق الأمر بعض الوقت..."
              : "جاري تجميع وتصدير الملف المجمع...",
          textAlign: TextAlign.center,
        )
      ],))
          : _buildTeacherDashboard(),
    );
  }

  // --- ✅✅✅ (تعديل) تم تحويل لوحة التحكم إلى ListView لإضافة قسم الإحصائيات ✅✅✅ ---
  Widget _buildTeacherDashboard() {
    // سنستخدم ListView ليسمح لنا بوضع قسم الإحصائيات في الأعلى
    // وقسم الأزرار (GridView) في الأسفل
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --- ✅✅✅ (إضافة) قسم الإحصائيات للأدمن فقط ✅✅✅ ---
        if (_isAdmin) ...[
          _buildAnalyticsSection(),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
        ],
        // --- ✅✅✅ (نهاية الإضافة) ✅✅✅ ---

        // لوحة التحكم الأصلية (الأزرار)
        GridView.count(
          shrinkWrap: true, // مهم جداً داخل ListView
          physics: const NeverScrollableScrollPhysics(), // مهم جداً داخل ListView
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildDashboardButton(
              title: 'رصد الدرجات',
              icon: Icons.edit_note,
              color: Colors.blue.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GradeEntrySelectionPage(isBehaviorMode: false, isAdmin: _isAdmin)));
              },
            ),
            _buildDashboardButton(
              title: 'الطالب المنضبط',
              icon: Icons.sentiment_very_satisfied,
              color: Colors.teal.shade600,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GradeEntrySelectionPage(isBehaviorMode: true, isAdmin: _isAdmin)));
              },
            ),
            _buildDashboardButton(
              title: 'تعميم النماذج التعليمية',
              icon: Icons.assignment,
              color: Colors.indigo.shade600,
              onTap: _launchEduFormsUrl,
            ),
            _buildDashboardButton(
              title: 'صندوق الشكاوى',
              icon: Icons.inbox,
              color: Colors.orange.shade800,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsBoxPage()));
              },
            ),
            _buildDashboardButton(
              title: 'تحليل المخالفات',
              icon: Icons.flag,
              color: Colors.red.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ViolationsLogPage()));
              },
            ),
            if (_isAdmin)
              _buildDashboardButton(
                title: 'البحث عن نتائج طالب',
                icon: Icons.person_search,
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSearchPage()));
                },
              ),
            if (_isAdmin)
              _buildDashboardButton(
                title: 'استخراج درجات فصل (PDF)',
                icon: Icons.picture_as_pdf,
                color: Colors.red.shade600,
                onTap: _showComingSoonSnackBar,
              ),
            if (_isAdmin)
              _buildDashboardButton(
                title: 'تحليلات بيانات المدرسة',
                icon: Icons.analytics_outlined,
                color: Colors.purple.shade600,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolAnalyticsPage()));
                },
              ),
            if (_isAdmin)
              _buildDashboardButton(
                title: 'بيانات المدرسة كاملة (Excel)',
                icon: Icons.corporate_fare,
                color: Colors.blueGrey.shade700,
                onTap: _exportFullSchoolDataToExcel,
              ),
          ],
        ),
      ],
    );
  }

  // --- ✅✅✅ (إضافة) ويدجت قسم الإحصائيات بالكامل ✅✅✅ ---
  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 إحصائيات حية للمنصة',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // استخدام Row لعرض البطاقات جنباً إلى جنب
        Row(
          children: [
            // البطاقة الأولى: المتصلون حالياً
            Expanded(
              child: _buildOnlineStudentsCard(),
            ),
            const SizedBox(width: 16),
            // البطاقة الثانية: إجمالي الطلاب
            Expanded(
              child: _buildTotalStudentsCard(),
            ),
          ],
        ),
      ],
    );
  }

  /// بطاقة إحصائية لعرض عدد الطلاب المتصلين الآن (تحديث لحظي)
  Widget _buildOnlineStudentsCard() {
    // --- (ملاحظة) هذا العداد سيبقى دقيقاً (آخر دقيقتين) للواجهة فقط ---
    final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // --- ✅✅✅ (الإضافة) جعل البطاقة قابلة للضغط ✅✅✅ ---
      child: InkWell(
        onTap: () {
          // --- (الإضافة) الانتقال إلى صفحة "سجل الظهور" الجديدة ---
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OnlineStudentsPage()),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'متصل حالياً', // سيبقى العنوان كما هو
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                  // --- (الإضافة) أيقونة توضح أنها قابلة للضغط ---
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.green.shade400),
                ],
              ),
              const SizedBox(height: 12),
              // استخدام StreamBuilder لتحديث العدد لحظياً
              StreamBuilder<QuerySnapshot>(
                // --- (ملاحظة) هذا الاستعلام يبقى كما هو لعرض العدد اللحظي ---
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('lastSeen', isGreaterThan: Timestamp.fromDate(twoMinutesAgo))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 28, // ارتفاع ثابت لمنع "قفز" الواجهة
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text('خطأ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red));
                  }

                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const Text('طالب', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }  /// بطاقة إحصائية لعرض العدد الإجمالي للطلاب (يتم جلبه مرة واحدة)
  ///
  Widget _buildTotalStudentsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'الغياب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // استخدام FutureBuilder لجلب العدد الإجمالي (count)
            // هذه الميزة تتطلب تفعيل (default) index في الفايرستور
            FutureBuilder<AggregateQuerySnapshot>(
              future: FirebaseFirestore.instance.collection('students').count().get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 28, // ارتفاع ثابت
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                if (snapshot.hasError) {
                  return const Text('خطأ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red));
                }

                final count = snapshot.data?.count ?? 0;
                return Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                );
              },
            ),
            const Text('مسجل', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  // --- ✅✅✅ (نهاية الإضافات) ✅✅✅ ---


  Widget _buildDashboardButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة ستكون متاحة قريباً!')),
    );
  }
}

class GradeEntrySelectionPage extends StatefulWidget {
  final bool isBehaviorMode;
  final bool isAdmin;
  const GradeEntrySelectionPage({super.key, required this.isBehaviorMode, required this.isAdmin});

  @override
  _GradeEntrySelectionPageState createState() => _GradeEntrySelectionPageState();
}

class _GradeEntrySelectionPageState extends State<GradeEntrySelectionPage> {
  Map<String, dynamic>? _userData;
  String? _selectedStage, _selectedGrade, _selectedClass;
  bool _isLoading = true;
  bool _isMassExporting = false; // --- حالة تحميل الأيقونة الخضراء ---

  Map<String, Map<String, List<String>>> _classSubjectMapByGrade = {};

  List<String> _subjectsForSelectedClass = [];

  List<String> _availableStages = [];
  Map<String, List<String>> _gradesByStage = {};
  List<String> _gradesForSelectedStage = [];
  List<String> _classesForSelectedGrade = [];

  final List<String> _allStages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
  final List<String> _allGrades = ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس', 'الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط', 'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];
  final List<String> _allClasses = ['الفصل 1', 'الفصل 2', 'الفصل 3', 'الفصل 4', 'الفصل 5', 'الفصل 6'];
  final List<String> _allSubjects = [
    'رياضيات', 'لغتي', 'إسلاميات', 'علوم', 'نشاط', 'انجليزي',
    'اجتماعيات', 'فنية', 'حياتية', 'بدنية', 'رقمية', 'تفكير'
  ];

  final Map<String, String> _subjectToProfessionKeyMap = {
    'رياضيات': 'profession1',
    'لغتي': 'profession2',
    'إسلاميات': 'profession3',
    'علوم': 'profession4',
    'نشاط': 'profession5',
    'انجليزي': 'profession6',
    'اجتماعيات': 'profession7',
    'فنية': 'profession8',
    'حياتية': 'profession9',
    'بدنية': 'profession10',
    'رقمية': 'profession11',
    'تفكير': 'profession12',
    // نافس ليس له professionKey هنا لأنه يعامل بشكل مختلف
  };


  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;

      final data = userDataSnapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      _userData = data;
      if (widget.isAdmin) {
        _availableStages = _allStages;
      } else {
        _parseTeacherPermissions(data);
      }

      setState(() => _isLoading = false);

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseTeacherPermissions(Map<String, dynamic> data) {
    final stages = <String>{};
    final grades = <String, Set<String>>{};
    final classSubjects = <String, Map<String, List<String>>>{};

    final structure = {
      'المرحلة الابتدائية': {
        'field': 'stage1',
        'grades': {
          'الصف الأول': {'field': 'grade1', 'classField': 'class1'},
          'الصف الثاني': {'field': 'grade2', 'classField': 'class2'},
          'الصف الثالث': {'field': 'grade3', 'classField': 'class3'},
          'الصف الرابع': {'field': 'grade4', 'classField': 'class4'},
          'الصف الخامس': {'field': 'grade5', 'classField': 'class5'},
          'الصف السادس': {'field': 'grade6', 'classField': 'class6'},
        }
      },
      'المرحلة المتوسطة': {
        'field': 'stage2',
        'grades': {
          'الصف الأول المتوسط': {'field': 'grade11', 'classField': 'class11'},
          'الصف الثاني المتوسط': {'field': 'grade22', 'classField': 'class22'},
          'الصف الثالث المتوسط': {'field': 'grade33', 'classField': 'class33'},
        }
      },
      'المرحلة الثانوية': {
        'field': 'stage3',
        'grades': {
          'الصف الأول الثانوي': {'field': 'grade111', 'classField': 'class111'},
          'الصف الثاني الثانوي': {'field': 'grade222', 'classField': 'class222'},
          'الصف الثالث الثانوي': {'field': 'grade333', 'classField': 'class333'},
        }
      },
    };

    structure.forEach((stageName, stageInfo) {
      final stageData = stageInfo as Map<String, dynamic>;
      if (data[stageData['field']] != null && data[stageData['field']] != '0') {
        stages.add(stageName);
        grades.putIfAbsent(stageName, () => <String>{});

        final gradesMap = stageData['grades'] as Map<String, dynamic>?;
        if (gradesMap != null) {
          gradesMap.forEach((gradeName, gradeInfo) {
            final gradeData = gradeInfo as Map<String, dynamic>;
            if (data[gradeData['field']] != null && data[gradeData['field']] != '0') {
              grades[stageName]!.add(gradeName);

              final classValue = data[gradeData['classField']];
              if (classValue is String && classValue.isNotEmpty && classValue != '0') {
                classSubjects.putIfAbsent(gradeName, () => <String, List<String>>{});

                final pairs = classValue.split(',');
                for (final pair in pairs) {
                  final parts = pair.split('=');
                  if (parts.length == 2) {
                    final className = parts[0].trim();
                    final subjectName = parts[1].trim();
                    if (className.isNotEmpty && subjectName.isNotEmpty) {
                      classSubjects[gradeName]!.putIfAbsent(className, () => []).add(subjectName);
                    }
                  }
                }
              }
            }
          });
        }
      }
    });

    _availableStages = stages.toList();
    _gradesByStage = grades.map((key, value) => MapEntry(key, value.toList()));
    _classSubjectMapByGrade = classSubjects;
  }

  Future<void> _exportAllAssignedStudentsToExcel() async {
    if ((_userData == null || _userData!.isEmpty) && !widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للمعلم لتصديرها.'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isMassExporting = true);

    try {
      final excel = Excel.createExcel();
      // --- (تعديل) اسم الشيت ---
      final sheet = excel['كشف درجات المعلم المجمع'];
      sheet.isRTL = true;
      excel.delete('Sheet1');

      // 1. تعريف الأعمدة الثابتة لنموذج "الأيقونة الزرقاء"
      final List<CellValue> mainHeaders = [
        TextCellValue('اسم الطالب'),
        TextCellValue('الدرجة'),
        TextCellValue('النسبة المئوية'),
        TextCellValue('التقييم'),
      ];

      // 2. تعريف أنماط التنسيق
      final headerStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString("#FF1976D2"),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center
      );
      final separatorStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString("#FFFFEB3B"),
          horizontalAlign: HorizontalAlign.Center
      );

      // 3. تعريف الاختبارات القياسية (بدون نافس)
      final List<String> testNames = ['الاختبار الأول', 'الاختبار الثاني', 'الاختبار الثالث', 'قبلي', 'بعدي', 'احتياطي'];
      final List<String> testKeys = ['e1', 'e2', 'e3', 'e14', 'e15', 'e16'];
      const double maxGrade = 20.0;

      // 4. جلب جميع الطلاب وتجميعهم حسب الفصول
      final Map<String, List<DocumentSnapshot>> studentsByClass = {};
      final querySnapshot = await FirebaseFirestore.instance.collection('students').get();
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final classId = "${data['stages'] ?? 'N/A'} - ${data['grades'] ?? 'N/A'} - ${data['classes'] ?? 'N/A'}";
        studentsByClass.putIfAbsent(classId, () => []).add(doc);
      }

      // 5. دالة مساعدة لإنشاء التقييم
      String getEvaluation(num grade, double maxGrade) {
        if (grade < 0) return "N/A"; // غائب
        double percentage = (grade / maxGrade) * 100;
        if (percentage >= 90) return "ممتاز";
        if (percentage >= 80) return "جيد جدا";
        if (percentage >= 70) return "جيد";
        if (percentage >= 50) return "مقبول";
        return "يحتاج لمتابعة";
      }

      // 6. تجميع قائمة الفصول والمواد المسندة للمعلم
      List<Map<String, String>> assignments = [];
      if(widget.isAdmin) {
        for (var classKey in studentsByClass.keys) {
          final parts = classKey.split(' - ');
          if (parts.length != 3) continue;
          for (var subject in _allSubjects) {
            assignments.add({
              "stage": parts[0],
              "grade": parts[1],
              "class": parts[2],
              "subject": subject,
            });
          }
        }
      } else {
        _gradesByStage.forEach((stage, grades) {
          for (final grade in grades) {
            final classMap = _classSubjectMapByGrade[grade];
            if (classMap != null) {
              classMap.forEach((className, subjects) {
                for (final subject in subjects) {
                  assignments.add({
                    "stage": stage,
                    "grade": grade,
                    "class": className,
                    "subject": subject,
                  });
                }
              });
            }
          }
        });
      }

      // ترتيب القائمة
      assignments.sort((a, b) {
        int classCmp = "${a['stage']}-${a['grade']}-${a['class']}".compareTo("${b['stage']}-${b['grade']}-${b['class']}");
        if (classCmp != 0) return classCmp;
        return a['subject']!.compareTo(b['subject']!);
      });


      // 7. --- الحلقة الرئيسية لبناء الملف ---
      bool didAddAnyData = false;

      for (final assignment in assignments) {
        final stage = assignment['stage']!;
        final gradeName = assignment['grade']!;
        final className = assignment['class']!;
        final subject = assignment['subject']!;

        final professionKey = _subjectToProfessionKeyMap[subject];
        if (professionKey == null) continue;

        final classKey = "$stage - $gradeName - $className";
        final students = studentsByClass[classKey];
        if (students == null || students.isEmpty) continue;

        // 8. المرور على الاختبارات الـ 6 لهذه المادة
        for (int i = 0; i < testKeys.length; i++) {
          final testKey = testKeys[i];
          final testName = testNames[i];
          final testFieldKey = '$testKey$professionKey';

          // 9. التحقق أن "جميع" الطلاب مرصود لهم درجة لهذا الاختبار
          bool allStudentsGraded = true;
          for (final studentDoc in students) {
            final data = studentDoc.data() as Map<String, dynamic>;
            // --- (تعديل) التحقق من وجود المفتاح فقط ---
            if (!data.containsKey(testFieldKey)) {
              allStudentsGraded = false;
              break;
            }
          }

          if (!allStudentsGraded) {
            continue;
          }

          didAddAnyData = true;

          // 11. إضافة صف الفاصل
          sheet.appendRow([]);
          final separatorRowIndex = sheet.maxRows;
          final separatorText = "كشف درجات: $classKey - مادة: $subject - ($testName)";
          sheet.merge(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: separatorRowIndex),
              CellIndex.indexByColumnRow(columnIndex: mainHeaders.length - 1, rowIndex: separatorRowIndex)
          );
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: separatorRowIndex));
          cell.value = TextCellValue(separatorText);
          cell.cellStyle = separatorStyle;

          // 12. إضافة رأس الجدول (مكرر)
          sheet.appendRow(mainHeaders);
          final headerRowIndex = sheet.maxRows - 1;
          for(int h=0; h<mainHeaders.length; h++) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: h, rowIndex: headerRowIndex)).cellStyle = headerStyle;
          }

          // 13. ترتيب الطلاب أبجدياً وإضافة بياناتهم
          students.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            return (dataA['name'] ?? '').compareTo(dataB['name'] ?? '');
          });

          for (var studentDoc in students) {
            final data = studentDoc.data() as Map<String, dynamic>;
            final studentName = data['name'] ?? 'N/A';
            // --- ✅✅✅ إصلاح خطأ النوع هنا ✅✅✅ ---
            final dynamic gradeValue = data[testFieldKey]; // جلب القيمة بدون تحويل مبدئي
            num? gradeNum; // استخدام النوع القابل للإلغاء

            if (gradeValue is num) {
              gradeNum = gradeValue;
            }
            // ------------------------------------

            if (gradeNum == null) {
              // حالة الدرجة مفقودة أو غير صالحة
              sheet.appendRow([
                TextCellValue(studentName),
                TextCellValue('لم ترصد'),
                TextCellValue('N/A'),
                TextCellValue('N/A')
              ]);
            } else if (gradeNum == -1) {
              // حالة "غائب"
              sheet.appendRow([
                TextCellValue(studentName),
                TextCellValue('غائب'),
                TextCellValue('N/A'),
                TextCellValue('N/A')
              ]);
            } else {
              // حالة "مرصود"
              final double percentage = (gradeNum / maxGrade) * 100;
              final String evaluation = getEvaluation(gradeNum, maxGrade);
              sheet.appendRow([
                TextCellValue(studentName),
                DoubleCellValue(gradeNum.toDouble()),
                TextCellValue('${percentage.toStringAsFixed(1)}%'),
                TextCellValue(evaluation)
              ]);
            }
          }
        }
      }

      // 14. التحقق إذا لم يتم إضافة أي بيانات
      if (!didAddAnyData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على أي اختبارات مرصودة بالكامل لجميع الطلاب.'), backgroundColor: Colors.orange),
        );
        setState(() => _isMassExporting = false);
        return;
      }

      // 15. ضبط عرض الأعمدة
      for (int i=0; i<mainHeaders.length; i++) {
        sheet.setColAutoFit(i);
      }

      // 16. حفظ وتنزيل الملف
      _saveAndDownloadExcel(context, excel, 'كشف_درجات_المعلم_المجمع.xlsx');

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير الملف: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isMassExporting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBehaviorMode ? 'اختيار فصل لتقييم السلوك' : 'اختيار فصل ومادة للرصد'),
        actions: [
          if (!widget.isBehaviorMode)
            IconButton(
              icon: const Icon(Icons.download_for_offline, color: Colors.greenAccent, size: 28),
              tooltip: 'تنزيل كشف Excel مجمع (للاختبارات المرصودة بالكامل)',
              onPressed: _isMassExporting ? null : _exportAllAssignedStudentsToExcel,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/2.png'),
          ),
        ],
      ),
      body: _isLoading || _isMassExporting
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isMassExporting
                  ? 'جاري تجميع وتصدير الملف المجمع...\nسيتم فقط تضمين الاختبارات المرصودة بالكامل.'
                  : 'جاري تحميل البيانات...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('1. اختر المرحلة الدراسية', Icons.layers),
          const SizedBox(height: 12),
          _buildDropdown(_availableStages, _selectedStage, 'اختر المرحلة', (val) => setState(() {
            _selectedStage = val;
            _selectedGrade = null;
            _selectedClass = null;
            _gradesForSelectedStage = val != null ? (widget.isAdmin ? _allGrades : (_gradesByStage[val] ?? [])) : [];
            _classesForSelectedGrade = [];
            _subjectsForSelectedClass = [];
          })),
          const SizedBox(height: 24),

          if (_selectedStage != null) ...[
            _buildSectionTitle('2. اختر الصف الدراسي', Icons.school),
            const SizedBox(height: 12),
            _buildDropdown(_gradesForSelectedStage, _selectedGrade, 'اختر الصف', (val) => setState(() {
              _selectedGrade = val;
              _selectedClass = null;
              _classesForSelectedGrade = val != null
                  ? (widget.isAdmin
                  ? _allClasses
                  : (_classSubjectMapByGrade[val]?.keys.toList() ?? []))
                  : [];
              _subjectsForSelectedClass = [];
            })),
            const SizedBox(height: 24),
          ],

          if (_selectedGrade != null) ...[
            _buildSectionTitle('3. اختر الفصل', Icons.class_),
            const SizedBox(height: 12),
            _buildDropdown(_classesForSelectedGrade, _selectedClass, 'اختر الفصل', (val) => setState(() {
              _selectedClass = val;
              if (val != null && _selectedGrade != null && !widget.isAdmin) {
                _subjectsForSelectedClass = _classSubjectMapByGrade[_selectedGrade!]?[val] ?? [];
              } else {
                _subjectsForSelectedClass = widget.isAdmin ? _allSubjects : []; // الأدمن يرى كل المواد دائماً
              }
            })),
            const SizedBox(height: 24),
          ],

          if (_selectedClass != null) ...[
            const Divider(thickness: 1, height: 30),
            _buildSectionTitle(widget.isBehaviorMode ? '4. تقييم سلوك الفصل' : '4. اختر المادة', widget.isBehaviorMode ? Icons.sentiment_very_satisfied : Icons.book),
            const SizedBox(height: 16),
            _buildSubjectGrid(
              // الأدمن يرى كل المواد، المعلم يرى مواده فقط
              widget.isAdmin ? _allSubjects : _subjectsForSelectedClass,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String? currentValue, String hint, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      hint: Text(hint),
      isExpanded: true,
      items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSubjectGrid(List<String> subjects) {
    if (subjects.isEmpty && !widget.isAdmin) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('لا توجد مواد مسندة لك في هذا الفصل.'),
      ));
    }

    if (widget.isBehaviorMode) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.people_alt_outlined),
          label: const Text('الانتقال لصفحة تقييم السلوك'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          onPressed: () {
            if (_selectedStage != null && _selectedGrade != null && _selectedClass != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TestSelectionPage(
                    stage: _selectedStage!,
                    grade: _selectedGrade!,
                    className: _selectedClass!,
                    subject: 'سلوك', // Subject can be a placeholder here
                    professionKey: 'behavior', // professionKey can be a placeholder
                    isBehaviorMode: widget.isBehaviorMode,
                    isAdmin: widget.isAdmin,
                  ),
                ),
              );
            }
          },
        ),
      );
    }


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5))
            ),
            elevation: 3,
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            if (_selectedStage != null && _selectedGrade != null && _selectedClass != null) {
              final professionKey = _subjectToProfessionKeyMap[subject];
              if (professionKey == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: المادة "$subject" غير قابلة للاختيار هنا (قد تكون نافس).')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TestSelectionPage(
                    stage: _selectedStage!,
                    grade: _selectedGrade!,
                    className: _selectedClass!,
                    subject: subject,
                    professionKey: professionKey,
                    isBehaviorMode: widget.isBehaviorMode,
                    isAdmin: widget.isAdmin,
                  ),
                ),
              );
            }
          },
          child: Text(
              subject,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
        );
      },
    );
  }
}

class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({super.key});

  @override
  _StudentSearchPageState createState() => _StudentSearchPageState();
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  String _searchStatus = 'أدخل اسم الطالب للبحث...';

  // --- ✅✅✅ (إضافة) دالة تنسيق "آخر ظهور" ✅✅✅ ---
  Widget _buildLastSeenWidget(Timestamp? lastSeenTimestamp) {
    // تحديد اللغة العربية لتنسيق الوقت

    if (lastSeenTimestamp == null) {
      return const Text(
        'لم يُسجل',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final lastSeen = lastSeenTimestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return const Text(
        'متصل الآن',
        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
      );
    } else if (difference.inMinutes < 60) {
      return Text(
        'آخر ظهور: ${difference.inMinutes} د',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (difference.inHours < 24) {
      return Text(
        'آخر ظهور: ${difference.inHours} س',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (difference.inDays == 1) {
      return const Text(
        'آخر ظهور: أمس',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else {
      // استخدام 'ar' لضمان تنسيق التاريخ بالعربي
      return Text(
        intl.DateFormat('yyyy/MM/dd', 'ar').format(lastSeen),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
  }


  Future<void> _searchStudent(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchStatus = 'أدخل اسم الطالب أو رقمه...';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchStatus = 'جاري البحث...';
    });

    try {
      final nameQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final emailQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: query.toLowerCase())
          .get();

      QuerySnapshot<Map<String, dynamic>> numberEmailQuery;
      if (int.tryParse(query) != null) {
        final startEmail = '$query@elma3refa.com';
        final endEmail = '$query\uf8ff@elma3refa.com';
        numberEmailQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isGreaterThanOrEqualTo: startEmail)
            .where('email', isLessThanOrEqualTo: endEmail)
            .get();
      } else {
        numberEmailQuery = await FirebaseFirestore.instance.collection('students').where('email', isEqualTo: 'a-dummy-email-that-will-never-exist').get();
      }

      final Map<String, DocumentSnapshot> results = {};
      for (var doc in nameQuery.docs) {
        results[doc.id] = doc;
      }
      for (var doc in emailQuery.docs) {
        results[doc.id] = doc;
      }
      for (var doc in numberEmailQuery.docs) {
        results[doc.id] = doc;
      }


      setState(() {
        _searchResults = results.values.toList();
        _searchStatus = _searchResults.isEmpty ? 'لم يتم العثور على نتائج.' : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchStatus = 'حدث خطأ أثناء البحث.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث عن طالب'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم الطالب أو بريده الإلكتروني أو رقمه',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchStudent('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchStudent(value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(child: Text(_searchStatus, style: const TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final student = _searchResults[index];
                final data = student.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'اسم غير متوفر';
                final grade = data['grades'] ?? 'صف غير متوفر';
                final className = data['classes'] ?? 'فصل غير متوفر';
                // --- ✅✅✅ (تعديل) جلب "آخر ظهور" ✅✅✅ ---
                final lastSeen = data['lastSeen'] as Timestamp?;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    subtitle: Text('$grade / $className'),
                    // --- ✅✅✅ (تعديل) إضافة "آخر ظهور" هنا ✅✅✅ ---
                    trailing: _buildLastSeenWidget(lastSeen),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentViewPage(studentId: student.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDataPoint {
  final String studentId;
  final String name;
  final String stage;
  final String grade;
  final String className;
  final Map<String, num> allTestScores;
  final double averageScore;
  final double averagePercentage;
  final int totalDislikes;

  StudentDataPoint({
    required this.studentId,
    required this.name,
    required this.stage,
    required this.grade,
    required this.className,
    required this.allTestScores,
    required this.averageScore,
    required this.averagePercentage,
    required this.totalDislikes,
  });
}

class TeacherInfo {
  final String id;
  final String name;
  final Map<String, dynamic> permissions;

  TeacherInfo({required this.id, required this.name, required this.permissions});

  bool teachesClass(String stage, String grade, String className) {
    final structure = {
      'المرحلة الابتدائية': {
        'field': 'stage1',
        'grades': {
          'الصف الأول': {'field': 'grade1', 'classField': 'class1'},
          'الصف الثاني': {'field': 'grade2', 'classField': 'class2'},
          'الصف الثالث': {'field': 'grade3', 'classField': 'class3'},
          'الصف الرابع': {'field': 'grade4', 'classField': 'class4'},
          'الصف الخامس': {'field': 'grade5', 'classField': 'class5'},
          'الصف السادس': {'field': 'grade6', 'classField': 'class6'},
        }
      },
      'المرحلة المتوسطة': {
        'field': 'stage2',
        'grades': {
          'الصف الأول المتوسط': {'field': 'grade11', 'classField': 'class11'},
          'الصف الثاني المتوسط': {'field': 'grade22', 'classField': 'class22'},
          'الصف الثالث المتوسط': {'field': 'grade33', 'classField': 'class33'},
        }
      },
      'المرحلة الثانوية': {
        'field': 'stage3',
        'grades': {
          'الصف الأول الثانوي': {'field': 'grade111', 'classField': 'class111'},
          'الصف الثاني الثانوي': {'field': 'grade222', 'classField': 'class222'},
          'الصف الثالث الثانوي': {'field': 'grade333', 'classField': 'class333'},
        }
      },
    };

    final stageInfo = structure[stage];
    if (stageInfo == null || permissions[stageInfo['field']] == '0') return false;

    final gradeInfo = (stageInfo['grades'] as Map<String, dynamic>?)?[grade];
    if (gradeInfo == null || permissions[gradeInfo['field']] == '0') return false;

    final assignedClasses = permissions[gradeInfo['classField']] as String?;
    if (assignedClasses == null || assignedClasses == '0') return false;

    return assignedClasses.split(',').any((pair) => pair.split('=').first.trim() == className);
  }
}

class RankedClass {
  final String classId;
  final double average;
  final List<TeacherInfo> teachers;
  RankedClass({required this.classId, required this.average, required this.teachers});
}


class FullSchoolReport {
  final Map<String, double> stageAverages;
  final Map<String, double> gradeAverages;
  final Map<String, double> classAverages;
  final List<RankedClass> rankedClasses;
  final Map<String, List<StudentDataPoint>> topStudentsPerGrade;
  final List<StudentDataPoint> misbehavingStudents;

  FullSchoolReport({
    required this.stageAverages,
    required this.gradeAverages,
    required this.classAverages,
    required this.rankedClasses,
    required this.topStudentsPerGrade,
    required this.misbehavingStudents,
  });
}

class GradeComparisonResult {
  final String gradeName;
  final List<StudentDataPoint> topPerformersInGrade;
  final Map<String, double> classAverages;
  final Map<String, Map<String, double>> subjectAveragesPerClass;
  final List<String> recommendations;

  GradeComparisonResult({
    required this.gradeName,
    required this.topPerformersInGrade,
    required this.classAverages,
    required this.subjectAveragesPerClass,
    required this.recommendations,
  });
}

class StudentPerformance {
  final String name;
  final double average;
  StudentPerformance({required this.name, required this.average});
}

class TeacherAnalysisResult {
  final String name;
  final int likesGiven;
  final int dislikesGiven;
  final Map<String, double> classSubjectAverages;
  final Map<String, double> netValueAdded;
  final Map<String, double> teachingConsistency;
  final Map<String, double> benchmarkGap;
  final Map<String, int> classSizes;
  final List<Map<String, String>> nobleStudents;
  final List<Map<String, String>> misbehavingStudents;
  final List<String> recommendationsToAdmin;
  final List<String> recommendationsToTeacher;


  TeacherAnalysisResult({
    required this.name,
    required this.likesGiven,
    required this.dislikesGiven,
    required this.classSubjectAverages,
    required this.netValueAdded,
    required this.teachingConsistency,
    required this.benchmarkGap,
    required this.classSizes,
    required this.nobleStudents,
    required this.misbehavingStudents,
    required this.recommendationsToAdmin,
    required this.recommendationsToTeacher,
  });
}

class SchoolAnalyticsPage extends StatefulWidget {
  const SchoolAnalyticsPage({super.key});

  @override
  _SchoolAnalyticsPageState createState() => _SchoolAnalyticsPageState();

  static Map<String, String> _createTestToSubjectMap() {
    final Map<String, String> map = {};
    final Map<String, String> subjects = {
      'profession1': 'رياضيات', 'profession2': 'لغتي', 'profession3': 'إسلاميات',
      'profession4': 'علوم', 'profession5': 'نشاط', 'profession6': 'انجليزي',
      'profession7': 'اجتماعيات', 'profession8': 'فنية', 'profession9': 'حياتية',
      'profession10': 'بدنية', 'profession11': 'رقمية', 'profession12': 'تفكير',
    };
    subjects.forEach((profKey, subjName) {
      for (int i = 1; i <= 16; i++) {
        map['e$i$profKey'] = subjName;
      }
    });
    for (int i = 1; i <= 12; i++) {
      map['e${i}profession13'] = 'نافس';
    }
    return map;
  }
}

class _SchoolAnalyticsPageState extends State<SchoolAnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _loadingMessage = 'جاري جلب بيانات المدرسة...';
  List<StudentDataPoint> _allStudentsData = [];
  List<TeacherInfo> _allTeachers = [];
  FullSchoolReport? _fullSchoolReport;

  static final Map<String, String> _testKeyToSubjectMap = SchoolAnalyticsPage._createTestToSubjectMap();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateFullSchoolReport();
  }

  Future<void> _generateFullSchoolReport() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'الخطوة 1/4: جاري جلب بيانات جميع الطلاب...';
      });
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();

      setState(() => _loadingMessage = 'الخطوة 2/4: جاري جلب بيانات المعلمين...');
      final teachersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _allTeachers = teachersSnapshot.docs.map((doc) => TeacherInfo(
        id: doc.id,
        name: doc.data()['name'] ?? 'معلم غير معروف',
        permissions: doc.data(),
      )).toList();


      setState(() => _loadingMessage = 'الخطوة 3/4: جاري معالجة درجات الطلاب...');
      List<StudentDataPoint> studentDataPoints = [];
      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        final Map<String, num> allTestScores = {};
        data.forEach((key, value) {
          if (value is num && _testKeyToSubjectMap.containsKey(key)) {
            allTestScores[key] = value;
          }
        });

        double totalScore = 0;
        int scoreCount = 0;
        double totalMaxScore = 0;

        allTestScores.forEach((key, score) {
          bool isNafes = _testKeyToSubjectMap[key] == 'نافس';
          totalScore += score;
          totalMaxScore += isNafes ? 10.0 : 20.0;
          scoreCount++;
        });

        final averageScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;
        final averagePercentage = totalMaxScore > 0 ? totalScore / totalMaxScore : 0.0;
        final totalDislikes = data['totalDislikes'] as int? ?? 0;

        studentDataPoints.add(StudentDataPoint(
          studentId: doc.id,
          name: data['name'] ?? 'N/A',
          stage: data['stages'] ?? 'N/A',
          grade: data['grades'] ?? 'N/A',
          className: data['classes'] ?? 'N/A',
          allTestScores: allTestScores,
          averageScore: averageScore,
          averagePercentage: averagePercentage,
          totalDislikes: totalDislikes,
        ));
      }
      _allStudentsData = studentDataPoints;

      setState(() => _loadingMessage = 'الخطوة 4/4: جاري حساب الإحصائيات والترتيب...');
      final stageGrades = <String, List<num>>{};
      final gradeGrades = <String, List<num>>{};
      final classGrades = <String, List<num>>{};
      final studentsByGrade = <String, List<StudentDataPoint>>{};

      for (var student in _allStudentsData) {
        if (student.averageScore == 0) continue;
        stageGrades.putIfAbsent(student.stage, () => []).add(student.averageScore);
        gradeGrades.putIfAbsent(student.grade, () => []).add(student.averageScore);
        classGrades.putIfAbsent('${student.stage} - ${student.grade} - ${student.className}', () => []).add(student.averageScore);
        studentsByGrade.putIfAbsent(student.grade, () => []).add(student);
      }

      final stageAverages = stageGrades.map((key, value) => MapEntry(key, value.isEmpty ? 0.0 : value.reduce((a,b)=> a+b) / value.length));
      final gradeAverages = gradeGrades.map((key, value) => MapEntry(key, value.isEmpty ? 0.0 : value.reduce((a,b)=> a+b) / value.length));
      final classAverages = classGrades.map((key, value) => MapEntry(key, value.isEmpty ? 0.0 : value.reduce((a,b)=> a+b) / value.length));

      final rankedClasses = classAverages.entries.map((entry) {
        final parts = entry.key.split(' - ');
        final stage = parts[0];
        final grade = parts[1];
        final className = parts[2];
        final teachers = _allTeachers.where((t) => t.teachesClass(stage, grade, className)).toList();
        return RankedClass(classId: entry.key, average: entry.value, teachers: teachers);
      }).toList();
      rankedClasses.sort((a, b) => b.average.compareTo(a.average));

      final topStudentsPerGrade = <String, List<StudentDataPoint>>{};
      studentsByGrade.forEach((grade, students) {
        students.sort((a, b) => b.averageScore.compareTo(a.averageScore));
        topStudentsPerGrade[grade] = students.take(10).toList();
      });

      final misbehavingStudents = _allStudentsData
          .where((student) => student.totalDislikes > 0)
          .toList();
      misbehavingStudents.sort((a, b) => b.totalDislikes.compareTo(a.totalDislikes));

      _fullSchoolReport = FullSchoolReport(
        stageAverages: stageAverages,
        gradeAverages: gradeAverages,
        classAverages: classAverages,
        rankedClasses: rankedClasses,
        topStudentsPerGrade: topStudentsPerGrade,
        misbehavingStudents: misbehavingStudents,
      );

    } catch(e, s) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ فادح أثناء تحليل البيانات: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليلات بيانات المدرسة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.insights), text: 'نظرة عامة عالمدرسة'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'تحليل صف (مقارنات تفصيلية)'),
            Tab(icon: Icon(Icons.person), text: 'تحليل أداء المعلمين'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_loadingMessage)]))
          : TabBarView(
        controller: _tabController,
        children: [
          ComparisonAnalyticsView(
            allStudentsData: _allStudentsData,
            fullSchoolReport: _fullSchoolReport,
          ),
          GradeComparisonView(allStudentsData: _allStudentsData, testKeyToSubjectMap: _testKeyToSubjectMap),
          TeacherAnalyticsView(allStudentsData: _allStudentsData, testKeyToSubjectMap: _testKeyToSubjectMap),
        ],
      ),
    );
  }
}

class ComparisonAnalyticsView extends StatelessWidget {
  final List<StudentDataPoint> allStudentsData;
  final FullSchoolReport? fullSchoolReport;

  const ComparisonAnalyticsView({
    super.key,
    required this.allStudentsData,
    required this.fullSchoolReport,
  });

  @override
  Widget build(BuildContext context) {
    if (fullSchoolReport == null) {
      return const Center(child: Text('لم يتم العثور على بيانات لعرضها.'));
    }

    final report = fullSchoolReport!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRankedClassesCard(context, report),
        const SizedBox(height: 16),
        _buildTopStudentsCard(context, report),
        const SizedBox(height: 16),
        _buildDetailedComparisonCard(context, report),
        const SizedBox(height: 16),
        _buildMisbehavingStudentsCard(context, report),
      ],
    );
  }

  Widget _buildMisbehavingStudentsCard(BuildContext context, FullSchoolReport report) {
    return _buildAnalyticsCard(
      title: '❗️ قائمة الطلاب أصحاب الملاحظات السلوكية',
      icon: Icons.priority_high,
      iconColor: Colors.red.shade700,
      child: report.misbehavingStudents.isEmpty
          ? const ListTile(
        leading: Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text('لا يوجد طلاب لديهم ملاحظات سلوكية مسجلة.'),
      )
          : ExpansionTile(
        title: Text('عرض قائمة الطلاب (${report.misbehavingStudents.length} طالب)'),
        children: report.misbehavingStudents.map((student) {
          return Card(
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Text(
                  '${report.misbehavingStudents.indexOf(student) + 1}',
                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${student.grade} / ${student.className}'),
              trailing: Chip(
                avatar: Icon(Icons.thumb_down, color: Colors.red.shade800, size: 16),
                label: Text(
                  student.totalDislikes.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankedClassesCard(BuildContext context, FullSchoolReport report) {
    return _buildAnalyticsCard(
      title: '🏆 ترتيب فصول المدرسة حسب الأداء',
      icon: Icons.emoji_events,
      iconColor: Colors.amber,
      child: report.rankedClasses.isEmpty
          ? const Text('لا توجد بيانات كافية لعرض الترتيب.')
          : Column(
        children: report.rankedClasses.map((rankedClass) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${report.rankedClasses.indexOf(rankedClass) + 1}'),
              ),
              title: Text(rankedClass.classId, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                rankedClass.teachers.isEmpty
                    ? 'لا يوجد معلمين مسجلين'
                    : 'المعلمون: ${rankedClass.teachers.map((t) => t.name).join(', ')}',
              ),
              trailing: Text(
                rankedClass.average.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopStudentsCard(BuildContext context, FullSchoolReport report) {
    return _buildAnalyticsCard(
      title: '⭐ الطلاب العشرة الأوائل على كل صف',
      icon: Icons.star,
      iconColor: Colors.orange,
      child: report.topStudentsPerGrade.isEmpty
          ? const Text('لا توجد بيانات كافية.')
          : ExpansionPanelList(
        elevation: 2,
        expansionCallback: (panelIndex, isExpanded) {},
        children: report.topStudentsPerGrade.entries.map((entry) {
          final grade = entry.key;
          final students = entry.value;
          return ExpansionPanel(
            isExpanded: true,
            headerBuilder: (context, isExpanded) => ListTile(
              title: Text('أوائل $grade', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: Column(
              children: students.map((student) {
                return ListTile(
                  leading: Text('${students.indexOf(student) + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  title: Text(student.name),
                  subtitle: Text('الفصل: ${student.className}'),
                  trailing: Text(student.averageScore.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedComparisonCard(BuildContext context, FullSchoolReport report) {
    return _buildAnalyticsCard(
      title: '📊 تفصيل المستويات الدراسية',
      subtitle: 'عرض هرمي للمتوسطات من المرحلة حتى الطالب',
      icon: Icons.account_tree,
      iconColor: Colors.purple,
      child: Column(
        children: report.stageAverages.entries.map((stageEntry) {
          final stageName = stageEntry.key;
          final stageAvg = stageEntry.value;
          final gradesInStage = allStudentsData.where((s) => s.stage == stageName).map((s) => s.grade).toSet().toList();

          return ExpansionTile(
            title: Text(stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: Text(stageAvg.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
            children: gradesInStage.map((gradeName) {
              final gradeAvg = report.gradeAverages[gradeName] ?? 0;
              final classesInGrade = allStudentsData.where((s) => s.grade == gradeName).map((s) => s.className).toSet().toList();

              return ExpansionTile(
                title: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(gradeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                trailing: Text(gradeAvg.toStringAsFixed(2)),
                children: classesInGrade.map((className) {
                  final classId = '$stageName - $gradeName - $className';
                  final classAvg = report.classAverages[classId] ?? 0;
                  final studentsInClass = allStudentsData.where((s) => s.stage == stageName && s.grade == gradeName && s.className == className).toList();
                  studentsInClass.sort((a,b)=> b.averageScore.compareTo(a.averageScore));

                  return ExpansionTile(
                    title: Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: Text(className),
                    ),
                    trailing: Text(classAvg.toStringAsFixed(2)),
                    children: studentsInClass.map((student) {
                      return ListTile(
                        title: Padding(
                          padding: const EdgeInsets.only(right: 48.0),
                          child: Text(student.name),
                        ),
                        trailing: Text(student.averageScore.toStringAsFixed(2)),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class GradeComparisonView extends StatefulWidget {
  final List<StudentDataPoint> allStudentsData;
  final Map<String, String> testKeyToSubjectMap;
  const GradeComparisonView({super.key, required this.allStudentsData, required this.testKeyToSubjectMap});

  @override
  _GradeComparisonViewState createState() => _GradeComparisonViewState();
}

class _GradeComparisonViewState extends State<GradeComparisonView> {
  String? _selectedGrade;
  bool _isLoading = false;
  GradeComparisonResult? _result;

  late final List<String> _availableGrades;

  @override
  void initState() {
    super.initState();
    _parseAvailableGrades();
  }

  void _parseAvailableGrades() {
    _availableGrades = widget.allStudentsData.map((s) => s.grade).toSet().toList()..sort();
  }

  void _generateGradeReport() {
    if (_selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الصف أولاً.')));
      return;
    }

    setState(() { _isLoading = true; _result = null; });

    final gradeStudents = widget.allStudentsData.where((s) => s.grade == _selectedGrade).toList();
    if (gradeStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على طلاب في هذا الصف.')));
      setState(() => _isLoading = false);
      return;
    }

    gradeStudents.sort((a,b) => b.averageScore.compareTo(a.averageScore));
    final topPerformersInGrade = gradeStudents.take(10).toList();

    final classAverages = <String, double>{};
    final studentsByClass = <String, List<StudentDataPoint>>{};
    for (var student in gradeStudents) {
      studentsByClass.putIfAbsent(student.className, () => []).add(student);
    }
    studentsByClass.forEach((className, students) {
      final avg = students.map((s) => s.averageScore).reduce((a,b) => a+b) / students.length;
      classAverages[className] = avg;
    });

    final subjectAveragesPerClass = <String, Map<String, double>>{};
    studentsByClass.forEach((className, students) {
      final subjectGrades = <String, List<num>>{};
      for (var student in students) {
        student.allTestScores.forEach((testKey, score) {
          final subjectName = widget.testKeyToSubjectMap[testKey];
          if (subjectName != null && subjectName != 'نافس') {
            subjectGrades.putIfAbsent(subjectName, () => []).add(score);
          }
        });
      }
      subjectAveragesPerClass[className] = subjectGrades.map((subject, grades) => MapEntry(subject, grades.reduce((a, b) => a+b)/grades.length));
    });


    final recommendations = <String>[];
    if (classAverages.isNotEmpty) {
      final sortedClasses = classAverages.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      recommendations.add("الفصل الأعلى أداءً هو: ${sortedClasses.first.key} بمتوسط ${sortedClasses.first.value.toStringAsFixed(2)}.");
      if (sortedClasses.length > 1) {
        recommendations.add("الفصل الأقل أداءً هو: ${sortedClasses.last.key} بمتوسط ${sortedClasses.last.value.toStringAsFixed(2)}. قد يحتاج هذا الفصل لدعم إضافي.");
      }
    }


    final result = GradeComparisonResult(
      gradeName: _selectedGrade!,
      topPerformersInGrade: topPerformersInGrade,
      classAverages: classAverages,
      subjectAveragesPerClass: subjectAveragesPerClass,
      recommendations: recommendations,
    );

    setState(() { _result = result; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDropdown(_availableGrades, _selectedGrade, 'اختر الصف لعرض المقارنة', (val) => setState(() {
          _selectedGrade = val;
        })),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.analytics),
          label: const Text('اعرض تحليل الصف والمقارنات'),
          onPressed: _isLoading ? null : _generateGradeReport,
        ),
        const Divider(height: 30),

        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        if (_result != null)
          _buildGradeResultView(_result!),
      ],
    );
  }

  Widget _buildGradeResultView(GradeComparisonResult result) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'تقرير مقارن لفصول: ${result.gradeName}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildAnalyticsCard(
          title: '📝 توصيات وملاحظات',
          icon: Icons.flag,
          child: result.recommendations.isEmpty
              ? const ListTile(title: Text("لا توجد ملاحظات."))
              : Column(
            children: result.recommendations.map((rec) => ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: Text(rec),
            )).toList(),
          ),
        ),
        _buildAnalyticsCard(
          title: '📊 مقارنة متوسط أداء الفصول',
          icon: Icons.groups,
          child: Column(
            children: result.classAverages.entries.map((entry) {
              return ListTile(
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(entry.value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              );
            }).toList(),
          ),
        ),
        _buildAnalyticsCard(
          title: '⭐ الطلاب الأوائل على مستوى الصف',
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
          child: Column(
            children: result.topPerformersInGrade.map((p) {
              return ListTile(
                leading: Text("${result.topPerformersInGrade.indexOf(p) + 1}."),
                title: Text(p.name),
                subtitle: Text("الفصل: ${p.className}"),
                trailing: Text(p.averageScore.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}



class TeacherAnalyticsView extends StatefulWidget {
  final List<StudentDataPoint> allStudentsData;
  final Map<String, String> testKeyToSubjectMap;

  const TeacherAnalyticsView({super.key, required this.allStudentsData, required this.testKeyToSubjectMap});

  @override
  _TeacherAnalyticsViewState createState() => _TeacherAnalyticsViewState();
}

class _TeacherAnalyticsViewState extends State<TeacherAnalyticsView> {
  String? _selectedTeacherId;
  bool _isLoading = false;
  bool _isFetchingTeachers = true;
  List<MapEntry<String, String>> _teachers = [];
  TeacherAnalysisResult? _result;

  final Map<String, String> _subjectToProfessionKeyMap = {
    'رياضيات': 'profession1', 'لغتي': 'profession2', 'إسلاميات': 'profession3',
    'علوم': 'profession4', 'نشاط': 'profession5', 'انجليزي': 'profession6',
    'اجتماعيات': 'profession7', 'فنية': 'profession8', 'حياتية': 'profession9',
    'بدنية': 'profession10', 'رقمية': 'profession11', 'تفكير': 'profession12',
    'نافس': 'profession13',
  };

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('profession', isNotEqualTo: 'admin').get();
      final teachers = snapshot.docs
          .map((doc) => MapEntry(doc.id, doc.data()['name'] as String? ?? 'اسم غير معروف'))
          .toList();
      if(mounted){
        setState(() {
          _teachers = teachers;
          _isFetchingTeachers = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isFetchingTeachers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل جلب قائمة المعلمين: $e')),
        );
      }
    }
  }

  double _calculateStandardDeviation(List<num> numbers) {
    if (numbers.length < 2) return 0.0;
    final double mean = numbers.fold<double>(0, (a, b) => a + b) / numbers.length;
    final variance = numbers.map((x) => pow(x - mean, 2)).fold<double>(0, (a, b) => a + b) / numbers.length;
    return sqrt(variance);
  }

  Future<void> _generateTeacherReport() async {
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار معلم أولاً.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final teacherDoc = await FirebaseFirestore.instance.collection('users').doc(_selectedTeacherId).get();
      final teacherData = teacherDoc.data();
      if (teacherData == null) throw Exception('لم يتم العثور على المعلم');

      final teacherName = teacherData['name'] ?? 'معلم';

      final behaviorReportsSnapshot = await FirebaseFirestore.instance.collection('behavior_reports').where('teacherId', isEqualTo: _selectedTeacherId).get();
      final likesGiven = behaviorReportsSnapshot.docs.where((d) => d.data()['type'] == 'like').length;
      final dislikesGiven = behaviorReportsSnapshot.docs.where((d) => d.data()['type'] == 'dislike').length;

      final nobleStudents = behaviorReportsSnapshot.docs
          .where((d) => d.data()['type'] == 'like')
          .map((d) {
        final data = d.data();
        return {
          "name": (data['studentName'] as String?) ?? 'طالب',
          "subject": (data['subject'] as String?) ?? 'مادة'
        };
      }).toList();

      final misbehavingStudents = behaviorReportsSnapshot.docs
          .where((d) => d.data()['type'] == 'dislike')
          .map((d) {
        final data = d.data();
        return {
          "name": (data['studentName'] as String?) ?? 'طالب',
          "subject": (data['subject'] as String?) ?? 'مادة'
        };
      }).toList();

      final Map<String, String> teacherSubjects = {};
      final Set<String> foundSubjects = {};

      final classFields = [
        'class1', 'class2', 'class3', 'class4', 'class5', 'class6',
        'class11', 'class22', 'class33',
        'class111', 'class222', 'class333'
      ];

      for (var field in classFields) {
        if (teacherData.containsKey(field) && teacherData[field] is String) {
          final String assignments = teacherData[field];
          final pairs = assignments.split(',');
          for (var pair in pairs) {
            final parts = pair.split('=');
            if (parts.length == 2) {
              final subjectName = parts[1].trim();
              if (subjectName.isNotEmpty) {
                foundSubjects.add(subjectName);
              }
            }
          }
        }
      }

      for (var subject in foundSubjects) {
        if (_subjectToProfessionKeyMap.containsKey(subject)) {
          teacherSubjects[subject] = _subjectToProfessionKeyMap[subject]!;
        }
      }

      if (teacherSubjects.isEmpty) {
        throw Exception('هذا المعلم ليس لديه مواد دراسية مسندة في أي فصل.');
      }
      final Map<String, List<num>> valueAddedScores = {};
      final Map<String, List<num>> consistencyScores = {};
      final Map<String, List<num>> benchmarkInternalScores = {};
      final Map<String, List<num>> benchmarkNafesScores = {};
      final Map<String, Set<String>> classStudentIds = {};
      final Map<String, List<num>> classSubjectGrades = {};

      for (final student in widget.allStudentsData) {
        final studentClassId = '${student.grade} - ${student.className}';
        final studentInternalScoresBySubject = <String, List<num>>{};
        num studentNafesTotal = 0;
        int studentNafesCount = 0;

        student.allTestScores.forEach((testKey, score) {
          final subjectName = widget.testKeyToSubjectMap[testKey];
          if(subjectName != null) {
            if(subjectName == 'نافس') {
              studentNafesTotal += score;
              studentNafesCount++;
            } else {
              studentInternalScoresBySubject.putIfAbsent(subjectName, () => []).add(score);
            }
          }
        });

        teacherSubjects.forEach((subjectName, profKey) {
          final preTestKey = 'e14$profKey';
          final postTestKey = 'e15$profKey';
          if (student.allTestScores.containsKey(preTestKey) && student.allTestScores.containsKey(postTestKey)) {
            final diff = student.allTestScores[postTestKey]! - student.allTestScores[preTestKey]!;
            valueAddedScores.putIfAbsent(subjectName, () => []).add(diff);
          }

          final periodicKeys = ['e1$profKey', 'e2$profKey', 'e3$profKey'];
          final scoresForConsistency = <num>[];
          periodicKeys.forEach((key) {
            if (student.allTestScores.containsKey(key)) {
              scoresForConsistency.add(student.allTestScores[key]!);
            }
          });

          if(scoresForConsistency.isNotEmpty) {
            final classKey = '$subjectName - $studentClassId';
            consistencyScores.putIfAbsent(classKey, () => []).addAll(scoresForConsistency);
            classSubjectGrades.putIfAbsent(classKey, () => []).addAll(scoresForConsistency);
            classStudentIds.putIfAbsent(classKey, () => <String>{}).add(student.studentId);
          }

          if (studentInternalScoresBySubject.containsKey(subjectName) && studentNafesCount > 0) {
            final internalScores = studentInternalScoresBySubject[subjectName]!;
            final avgInternal = internalScores.reduce((a,b) => a+b) / internalScores.length;
            final avgNafes = studentNafesTotal / studentNafesCount;
            benchmarkInternalScores.putIfAbsent(subjectName, () => []).add(avgInternal);
            benchmarkNafesScores.putIfAbsent(subjectName, () => []).add(avgNafes);
          }
        });
      }

      final Map<String, double> finalNetValueAdded = valueAddedScores.map((key, list) => MapEntry(key, list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length));
      final Map<String, double> finalTeachingConsistency = consistencyScores.map((key, list) => MapEntry(key, _calculateStandardDeviation(list)));
      final Map<String, double> finalBenchmarkGap = {};
      benchmarkInternalScores.forEach((subjectName, internalAvgs) {
        final nafesAvgs = benchmarkNafesScores[subjectName];
        if (nafesAvgs != null && internalAvgs.isNotEmpty && nafesAvgs.isNotEmpty) {
          final totalInternalAvg = internalAvgs.reduce((a, b) => a + b) / internalAvgs.length;
          final totalNafesAvg = nafesAvgs.reduce((a, b) => a + b) / nafesAvgs.length;
          finalBenchmarkGap[subjectName] = totalNafesAvg - totalInternalAvg;
        }
      });
      final Map<String, int> finalClassSizes = classStudentIds.map((key, value) => MapEntry(key, value.length));
      final Map<String, double> finalClassSubjectAverages = classSubjectGrades.map((key, grades) => MapEntry(key, grades.isEmpty ? 0 : grades.reduce((a, b) => a + b) / grades.length));

      final List<String> recommendationsToAdmin = [];
      final List<String> recommendationsToTeacher = [];

      finalNetValueAdded.forEach((subject, value) {
        if(value < 0.5) {
          recommendationsToAdmin.add("مؤشر تطور الطلاب في مادة $subject ضعيف (${value.toStringAsFixed(1)}). يُنصح بعقد اجتماع مع المعلم لمناقشة استراتيجيات رفع المستوى.");
          recommendationsToTeacher.add("مؤشر تطورك في مادة $subject ضعيف. حاول استخدام طرق تدريس مختلفة ومبتكرة لزيادة تفاعل الطلاب وتحصيلهم.");
        }
      });

      finalTeachingConsistency.forEach((classSubject, value) {
        if(value > 3.0) {
          recommendationsToAdmin.add("مستوى الطلاب في ($classSubject) متذبذب جداً (تشتت ${value.toStringAsFixed(1)}). يجب متابعة أداء الفصل مع المعلم لفهم الفجوات الكبيرة بين الطلاب.");
          recommendationsToTeacher.add("يوجد تفاوت كبير في مستوى طلابك في ($classSubject). حاول التركيز على المجموعات الصغيرة وتقديم دعم إضافي للطلاب الأقل مستوى.");
        }
      });

      if(dislikesGiven > 10 && dislikesGiven > likesGiven * 2) {
        recommendationsToAdmin.add("عدد الملاحظات السلوكية المسجلة من قبل المعلم مرتفع ($dislikesGiven). يجب مناقشة استراتيجيات ضبط الصف معه.");
        recommendationsToTeacher.add("عدد ملاحظاتك السلوكية ($dislikesGiven) مرتفع. حاول بناء علاقة إيجابية مع الطلاب واستخدام أساليب تحفيزية لضبط الصف.");
      }


      final result = TeacherAnalysisResult(
        name: teacherName,
        likesGiven: likesGiven,
        dislikesGiven: dislikesGiven,
        classSubjectAverages: finalClassSubjectAverages,
        netValueAdded: finalNetValueAdded,
        teachingConsistency: finalTeachingConsistency,
        benchmarkGap: finalBenchmarkGap,
        classSizes: finalClassSizes,
        nobleStudents: nobleStudents,
        misbehavingStudents: misbehavingStudents,
        recommendationsToAdmin: recommendationsToAdmin,
        recommendationsToTeacher: recommendationsToTeacher,
      );

      setState(() => _result = result);

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إنشاء التقرير: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTeacherId,
                hint: Text(_isFetchingTeachers ? 'جاري تحميل المعلمين...' : 'اختر معلماً'),
                isExpanded: true,
                items: _teachers.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value))).toList(),
                onChanged: _isFetchingTeachers ? null : (val) => setState(() => _selectedTeacherId = val),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.analytics),
          label: const Text('اعرض تحليل أداء المعلم'),
          onPressed: _isLoading ? null : _generateTeacherReport,
        ),
        const Divider(height: 30),

        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        if (_result != null)
          _buildTeacherResultView(_result!),
      ],
    );
  }

  Widget _buildTeacherResultView(TeacherAnalysisResult result) {
    return Column(
      children: [
        Text(
          'تقرير الأداء للمعلم: ${result.name}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        _buildAnalyticsCard(
            title: '📝 توصيات علاجية وإجرائية',
            icon: Icons.flag,
            iconColor: Colors.red.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("لفت انتباه الإدارة:", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ...result.recommendationsToAdmin.map((rec) => ListTile(
                  leading: Icon(Icons.arrow_forward, color: Colors.orange.shade800, size: 20),
                  title: Text(rec, style: const TextStyle(fontSize: 14)),
                  dense: true,
                )),
                if(result.recommendationsToAdmin.isEmpty) const ListTile(title: Text("لا توجد ملاحظات عاجلة.", style: TextStyle(fontStyle: FontStyle.italic))),
                const Divider(),
                Text("رسالة إلى المعلم:", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ...result.recommendationsToTeacher.map((rec) => ListTile(
                  leading: Icon(Icons.arrow_forward, color: Colors.green.shade800, size: 20),
                  title: Text(rec, style: const TextStyle(fontSize: 14)),
                  dense: true,
                )),
                if(result.recommendationsToTeacher.isEmpty) const ListTile(title: Text("أداؤك متوازن وممتاز، استمر في العطاء.", style: TextStyle(fontStyle: FontStyle.italic))),
              ],
            )
        ),

        _buildAnalyticsCard(
          title: '📈 مقاييس الأداء الأساسية',
          icon: Icons.assessment,
          child: Column(
            children: [
              _buildMetricExpansionTile(
                title: 'مجهود المعلم وتأثيره',
                subtitle: 'متوسط الفرق بين الاختبار القبلي والبعدي. كلما زاد الرقم كان أفضل.',
                icon: Icons.trending_up,
                data: result.netValueAdded,
                unit: ' درجة',
              ),
              _buildMetricExpansionTile(
                title: 'ثبات المستوى (التذبذب)',
                subtitle: 'مدى تقارب درجات الطلاب. كلما قل الرقم كان المستوى أكثر استقراراً.',
                icon: Icons.line_axis,
                data: result.teachingConsistency,
                unit: ' تشتت',
                isLowerBetter: true,
              ),
              _buildMetricExpansionTile(
                title: 'مقارنة مع اختبار نافس الوطني',
                subtitle: 'الفرق بين متوسط نافس ومتوسط الاختبارات. الرقم الموجب يعني أن أداء الطلاب داخلياً أفضل.',
                icon: Icons.compare_arrows,
                data: result.benchmarkGap,
                unit: '',
                isPositiveGood: true,
              ),
            ],
          ),
        ),

        _buildAnalyticsCard(
          title: '📊 أداء فصول المعلم',
          subtitle: 'متوسط أداء كل فصل يدرسه المعلم مع عدد الطلاب للمقارنة العادلة',
          icon: Icons.groups,
          child: _buildClassPerformanceList(result.classSubjectAverages, result.classSizes),
        ),

        _buildAnalyticsCard(
            title: '👍👎 تقييمات السلوك',
            icon: Icons.thumbs_up_down,
            child: Column(
              children: [
                _buildBehaviorExpansionTile(
                  title: "الطلاب المنضبطين الذين كرمهم المعلم",
                  count: result.likesGiven,
                  students: result.nobleStudents,
                  icon: Icons.thumb_up,
                  color: Colors.green,
                ),
                const Divider(),
                _buildBehaviorExpansionTile(
                  title: "طلاب لديهم ملاحظات سلوكية",
                  count: result.dislikesGiven,
                  students: result.misbehavingStudents,
                  icon: Icons.thumb_down,
                  color: Colors.red,
                ),
              ],
            )
        ),
      ],
    );
  }

  Widget _buildClassPerformanceList(Map<String, double> data, Map<String, int> classSizes) {
    if(data.isEmpty) {
      return const ListTile(title: Text('لا توجد بيانات كافية لعرض أداء الفصول.'));
    }
    return Column(
      children: data.entries.map((entry) {
        final classSize = classSizes[entry.key] ?? 0;
        return ListTile(
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('$classSize طالب'),
          trailing: Text(
            entry.value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBehaviorExpansionTile({
    required String title,
    required int count,
    required List<Map<String, String>> students,
    required IconData icon,
    required Color color,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ),
      children: students.isEmpty
          ? [const ListTile(title: Text('لا يوجد طلاب مسجلين في هذه الفئة.'))]
          : students.map((student) => ListTile(
        title: Text(student["name"]!),
        trailing: Text("في مادة ${student["subject"]!}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        dense: true,
      )).toList(),
    );
  }

  Widget _buildMetricExpansionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Map<String, double> data,
    required String unit,
    bool? isPositiveGood,
    bool? isLowerBetter,
  }) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      children: data.isEmpty
          ? [const ListTile(title: Text('لا توجد بيانات كافية لعرض هذا المقياس.'))]
          : data.entries.map((entry) {
        final value = entry.value;
        Color valueColor = Colors.black87;
        if(isPositiveGood == true) {
          valueColor = value >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        } else if (isLowerBetter == true) {
          if (value < 1.5) valueColor = Colors.green.shade700;
          else if (value < 3.0) valueColor = Colors.orange.shade800;
          else valueColor = Colors.red.shade700;
        }

        return ListTile(
          title: Text(entry.key),
          trailing: Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor),
          ),
        );
      }).toList(),
    );
  }

  llValue(String s) {}
}

class ComplaintsBoxPage extends StatefulWidget {
  const ComplaintsBoxPage({super.key});

  @override
  State<ComplaintsBoxPage> createState() => _ComplaintsBoxPageState();
}

class _ComplaintsBoxPageState extends State<ComplaintsBoxPage> {
  Stream<QuerySnapshot> _buildStream() {
    return FirebaseFirestore.instance
        .collection('behavior_reports')
        .where('status', whereIn: ['replied_by_student', 'closed'])
        .orderBy('replyTimestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صندوق الشكاوى والردود'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('صندوق الشكاوى فارغ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('لم تصل أي ردود من أولياء الأمور بعد.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _ComplaintConversationCard(reportDoc: doc);
            },
          );
        },
      ),
    );
  }
}
class _ComplaintConversationCard extends StatefulWidget {
  final DocumentSnapshot reportDoc;
  const _ComplaintConversationCard({required this.reportDoc});

  @override
  __ComplaintConversationCardState createState() => __ComplaintConversationCardState();
}

class __ComplaintConversationCardState extends State<_ComplaintConversationCard> {
  final TextEditingController _finalReplyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _submitTeacherFinalReply() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: المستخدم غير مسجل.'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    try {
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final replierName = currentUserDoc.data()?['name'] ?? 'معلم';

      final reportRef = FirebaseFirestore.instance.collection('behavior_reports').doc(widget.reportDoc.id);
      final reportData = widget.reportDoc.data() as Map<String, dynamic>? ?? {};
      final studentId = reportData['studentId'];
      final subject = reportData['subject'];

      final batch = FirebaseFirestore.instance.batch();

      batch.update(reportRef, {
        'teacherFinalReply': _finalReplyController.text.trim(),
        'teacherFinalReplyTimestamp': FieldValue.serverTimestamp(),
        'status': 'closed',
        'finalReplierId': currentUser.uid,
        'finalReplierName': replierName,
      });

      if (studentId != null) {
        final studentNotificationRef = FirebaseFirestore.instance.collection('students').doc(studentId).collection('notifications').doc();
        batch.set(studentNotificationRef, {
          'message': 'وصل رد من أ. $replierName بخصوص ملاحظة مادة $subject',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'reportId': widget.reportDoc.id,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الرد وإغلاق الشكوى بنجاح.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الرد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  void dispose() {
    _finalReplyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportDoc.data() as Map<String, dynamic>;
    final studentName = data['studentName'] ?? 'طالب';
    final subject = data['subject'] ?? 'مادة';
    final teacherNote = data['teacherNote'] ?? '...';
    final studentReply = data['studentReply'] ?? '...';
    final teacherFinalReply = data['teacherFinalReply'] as String?;

    final finalReplierName = data['finalReplierName'] as String?;
    final originalTeacherName = data['teacherName'] ?? 'المعلم';
    final timestamp = data['timestamp'] as Timestamp?;
    final replyTimestamp = data['replyTimestamp'] as Timestamp?;
    final finalReplyTimestamp = data['teacherFinalReplyTimestamp'] as Timestamp?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("مادة: $subject"),
              trailing: Chip(
                label: Text(
                  teacherFinalReply != null ? 'مغلقة' : 'بانتظار الرد',
                  style: TextStyle(color: teacherFinalReply != null ? Colors.white : Colors.black87),
                ),
                backgroundColor: teacherFinalReply != null ? Colors.grey : Colors.amber.shade300,
              ),
            ),
            const Divider(height: 20),
            _buildConversationBubble(
              context,
              isMe: true,
              author: 'ملاحظة من: أ. $originalTeacherName',
              text: teacherNote,
              timestamp: timestamp,
            ),
            const SizedBox(height: 12),
            _buildConversationBubble(
              context,
              isMe: false,
              author: 'رد ولي الأمر',
              text: studentReply,
              timestamp: replyTimestamp,
            ),
            if (teacherFinalReply != null) ...[
              const SizedBox(height: 12),
              _buildConversationBubble(
                context,
                isMe: true,
                author: 'رد نهائي من: أ. ${finalReplierName ?? originalTeacherName}',
                text: teacherFinalReply,
                timestamp: finalReplyTimestamp,
                isFinal: true,
              ),
            ] else ...[
              const Divider(height: 24),
              if (FirebaseAuth.instance.currentUser != null)
                FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists && (snapshot.data!.data() as Map).containsKey('profession')) {
                        return Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _finalReplyController,
                                decoration: const InputDecoration(
                                  labelText: 'اكتب ردك النهائي هنا',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 3,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء كتابة ردك' : null,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: _isSubmitting
                                    ? const Center(child: CircularProgressIndicator())
                                    : ElevatedButton.icon(
                                  icon: const Icon(Icons.send),
                                  label: const Text('إرسال الرد وإغلاق الشكوى'),
                                  onPressed: _submitTeacherFinalReply,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                ),
            ]
          ],
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15)),
        ),
        const SizedBox(height: 4),
        Text(formattedDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class ViolationsLogPage extends StatefulWidget {
  const ViolationsLogPage({super.key});

  @override
  _ViolationsLogPageState createState() => _ViolationsLogPageState();
}

class _ViolationsLogPageState extends State<ViolationsLogPage> {
  bool _isAdmin = false;
  bool _isLoading = true;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _isAdmin = (userDoc.data()?['profession'] == 'admin');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Stream<QuerySnapshot> _buildStream() {
    Query query = FirebaseFirestore.instance
        .collection('behavior_reports')
        .where('type', isEqualTo: 'dislike')
        .orderBy('timestamp', descending: true);

    if (!_isAdmin) {
      query = query.where('teacherId', isEqualTo: _currentUser?.uid);
    }
    return query.snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل مخالفات الطلاب'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _buildStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text('لا توجد مخالفات مسجلة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text('لم يتم تسجيل أي ملاحظات سلوكية على الطلاب بعد.', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data!.docs;
          final Map<String, List<DocumentSnapshot>> violationsByStudent = {};

          for (var report in reports) {
            final studentName = report['studentName'] as String? ?? 'طالب غير معروف';
            violationsByStudent.putIfAbsent(studentName, () => []).add(report);
          }

          final sortedStudents = violationsByStudent.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: sortedStudents.length,
            itemBuilder: (context, index) {
              final entry = sortedStudents[index];
              final studentName = entry.key;
              final studentViolations = entry.value;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    child: Text(
                      studentViolations.length.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Text(_isAdmin ? "عرض مخالفات الطالب" : 'اضغط لعرض تفاصيل المخالفات'),
                  children: studentViolations.map((violationDoc) {
                    final data = violationDoc.data() as Map<String, dynamic>;
                    final note = data['teacherNote'] ?? 'لا يوجد تفصيل.';
                    final teacherName = data['teacherName'] ?? 'معلم';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final formattedDate = timestamp != null
                        ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(timestamp.toDate())
                        : '...';

                    return ListTile(
                      title: Text(note),
                      subtitle: Text("بواسطة: أ. $teacherName - في: $formattedDate"),
                      dense: true,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


extension on Sheet {
  void setColAutoFit(int i) {}
}

Future<void> _saveAndDownloadExcel(BuildContext context, Excel excel, String fileName) async {
  final fileBytes = excel.save();
  if (fileBytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إنشاء ملف Excel.'), backgroundColor: Colors.red));
    return;
  }
  try {
    if (kIsWeb) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(fileBytes); // Write bytes to file
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        throw Exception('لا يمكن فتح الملف: ${result.message}');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تصدير الملف بنجاح: $fileName'), backgroundColor: Colors.green));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تصدير الملف: $e'), backgroundColor: Colors.red));
  }
}


Widget _buildDropdown(List<String> items, String? currentValue, String hint, ValueChanged<String?> onChanged) {
  return DropdownButtonFormField<String>(
    value: currentValue,
    hint: Text(hint),
    isExpanded: true,
    items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
    onChanged: onChanged,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Widget _buildAnalyticsCard({
  required String title,
  required IconData icon,
  required Widget child,
  String? subtitle,
  Color? iconColor,
  List<Widget>? actions,
}) {
  return Builder(builder: (context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if(subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ]
                    ],
                  ),
                ),
                if (actions != null) ...actions,
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  });
}