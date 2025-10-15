// add.dart (MODIFIED)

import 'dart:async';
import 'dart:io';
import 'dart:math';

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

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isExporting = false;
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

  // --- ✅ MODIFIED: Function now opens WhatsApp specifically ---
  Future<void> _launchWhatsAppForSupport() async {
    // الرقم مخصص للمبرمج مصطفى سعيد
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

      final headers = ['المرحلة', 'الصف', 'الفصل', 'اسم الطالب', ...allSubjects];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

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

  // --- ✅ MODIFIED: The build method is cleaner now ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/2.png'),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isExporting
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("جاري تصدير الملف، قد يستغرق الأمر بعض الوقت...")],))
          : _buildTeacherDashboard(), // The body is now just the dashboard
      // --- ✅ NEW: Added a clear FloatingActionButton for technical support ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchWhatsAppForSupport,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.support_agent),
        label: const Text('الدعم الفني للمنصة'),
        tooltip: '</>  أ/مصطفي سعيد لحل المشكلات التقنية',
      ),
    );
  }


  Widget _buildTeacherDashboard() {
    return GridView.count(
      padding: const EdgeInsets.all(20),
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
          title: 'صندوق الشكاوى',
          icon: Icons.inbox,
          color: Colors.orange.shade800,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsBoxPage()));
          },
        ),
        // --- ( ✅ الأيقونة الجديدة لتحليل المخالفات ) ---
        _buildDashboardButton(
          title: 'تحليل المخالفات',
          icon: Icons.flag, // أيقونة مناسبة للتقارير والمخالفات
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
    );
  }

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

  // --- [MODIFIED] This data structure now holds a list of subjects for each class.
  // Map<GradeName, Map<ClassName, List<SubjectName>>>
  Map<String, Map<String, List<String>>> _classSubjectMapByGrade = {};

  // --- [NEW] This list will hold the specific subjects available for the chosen class.
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

  // --- [MODIFIED] This function now handles multiple subjects for the same class.
  void _parseTeacherPermissions(Map<String, dynamic> data) {
    final stages = <String>{};
    final grades = <String, Set<String>>{};
    final classSubjects = <String, Map<String, List<String>>>{}; // New: Map<Grade, Map<Class, List<Subjects>>>

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
                      // This is the key change: it adds the subject to a list for the class.
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

  // --- [MODIFIED] The build method is updated for the new user flow.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBehaviorMode ? 'اختيار فصل لتقييم السلوك' : 'اختيار فصل ومادة للرصد'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/2.png'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                // Get the list of subjects for the chosen class
                _subjectsForSelectedClass = _classSubjectMapByGrade[_selectedGrade!]?[val] ?? [];
              } else {
                _subjectsForSelectedClass = [];
              }
            })),
            const SizedBox(height: 24),
          ],

          if (_selectedClass != null) ...[
            const Divider(thickness: 1, height: 30),
            _buildSectionTitle('4. اختر المادة', Icons.book),
            const SizedBox(height: 16),
            _buildSubjectGrid(
              // For admins, show all subjects. For teachers, show only the subjects for the selected class.
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

  // --- [MODIFIED] This function now accepts a list of subjects to display.
  Widget _buildSubjectGrid(List<String> subjects) {
    if (subjects.isEmpty && !widget.isAdmin) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('لا توجد مواد مسندة لك في هذا الفصل.'),
      ));
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
                  SnackBar(content: Text('خطأ: المادة "$subject" غير قابلة للاختيار.')),
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

// ===================================================================
// START OF NEW PAGES
// ===================================================================

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

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    subtitle: Text('$grade / $className'),
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

// ===================================================================
// START OF NEW SCHOOL ANALYTICS CODE
// ===================================================================

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

    // Modified to check for class name within the new "ClassName=SubjectName" format
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

  // --- [MODIFIED] This is a heavy function. We will provide detailed loading messages.
  Future<void> _generateFullSchoolReport() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'الخطوة 1/4: جاري جلب بيانات جميع الطلاب...';
      });
      // For very large schools, consider paginating this query or using a Cloud Function.
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();

      setState(() => _loadingMessage = 'الخطوة 2/4: جاري جلب بيانات المعلمين...');
      final teachersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _allTeachers = teachersSnapshot.docs.map((doc) => TeacherInfo(
        id: doc.id,
        name: doc.data()['name'] ?? 'معلم غير معروف',
        permissions: doc.data(),
      )).toList();


      setState(() => _loadingMessage = 'الخطوة 3/4: جاري معالجة درجات الطلاب...');
      // This part processes data in memory. It's fast for hundreds of students,
      // but for thousands, a backend solution (Cloud Function) would be more scalable.
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

  Future<void> _exportRankedClasses(BuildContext context, List<RankedClass> classes) async {
    final excel = Excel.createExcel();
    final sheet = excel['ترتيب الفصول'];
    sheet.isRTL = true;
    sheet.appendRow([
      TextCellValue('الترتيب'), TextCellValue('الفصل'), TextCellValue('متوسط الدرجات'), TextCellValue('المعلمون')
    ]);
    for (int i = 0; i < classes.length; i++) {
      final rc = classes[i];
      final teachers = rc.teachers.isEmpty ? 'لا يوجد معلمين' : rc.teachers.map((t) => t.name).join(', ');
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(rc.classId),
        DoubleCellValue(double.parse(rc.average.toStringAsFixed(2))),
        TextCellValue(teachers)
      ]);
    }
    _saveAndDownloadExcel(context, excel, 'ranked_classes_report.xlsx');
  }

  Future<void> _exportTopStudents(BuildContext context, Map<String, List<StudentDataPoint>> topStudents) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    topStudents.forEach((grade, students) {
      final sheet = excel[grade];
      sheet.isRTL = true;
      sheet.appendRow([
        TextCellValue('الترتيب'), TextCellValue('الطالب'), TextCellValue('الفصل'), TextCellValue('متوسط الدرجات'), TextCellValue('النسبة المئوية')
      ]);
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(student.name),
          TextCellValue(student.className),
          DoubleCellValue(double.parse(student.averageScore.toStringAsFixed(2))),
          TextCellValue('${(student.averagePercentage * 100).toStringAsFixed(1)}%'),
        ]);
      }
    });

    _saveAndDownloadExcel(context, excel, 'top_10_students_report.xlsx');
  }

  Future<void> _exportDetailedComparison(BuildContext context, FullSchoolReport report, List<StudentDataPoint> allStudents) async {
    final excel = Excel.createExcel();
    final sheet = excel['تفصيل المستويات'];
    sheet.isRTL = true;

    sheet.appendRow([
      TextCellValue('المستوى'), TextCellValue('الاسم'), TextCellValue('متوسط الدرجات'), TextCellValue('النسبة المئوية')
    ]);

    report.stageAverages.forEach((stage, avg) {
      sheet.appendRow([TextCellValue('مرحلة'), TextCellValue(stage), DoubleCellValue(avg), TextCellValue('')]);
      final gradesInStage = allStudents.where((s) => s.stage == stage).map((s) => s.grade).toSet();
      for (final grade in gradesInStage) {
        final gradeAvg = report.gradeAverages[grade] ?? 0;
        sheet.appendRow([TextCellValue('  صف'), TextCellValue(grade), DoubleCellValue(gradeAvg), TextCellValue('')]);
        final classesInGrade = allStudents.where((s) => s.grade == grade).map((s) => s.className).toSet();
        for (final className in classesInGrade) {
          final classId = '$stage - $grade - $className';
          final classAvg = report.classAverages[classId] ?? 0;
          sheet.appendRow([TextCellValue('    فصل'), TextCellValue(className), DoubleCellValue(classAvg), TextCellValue('')]);
          final studentsInClass = allStudents.where((s) => s.stage == stage && s.grade == grade && s.className == className).toList();
          studentsInClass.sort((a, b) => b.averageScore.compareTo(a.averageScore));
          for (final student in studentsInClass) {
            sheet.appendRow([
              TextCellValue('      طالب'),
              TextCellValue(student.name),
              DoubleCellValue(student.averageScore),
              TextCellValue('${(student.averagePercentage * 100).toStringAsFixed(1)}%')
            ]);
          }
        }
      }
    });

    _saveAndDownloadExcel(context, excel, 'detailed_levels_report.xlsx');
  }

  Future<void> _exportMisbehavingStudents(BuildContext context, List<StudentDataPoint> students) async {
    final excel = Excel.createExcel();
    final sheet = excel['الطلاب أصحاب الملاحظات'];
    sheet.isRTL = true;
    sheet.appendRow([
      TextCellValue('الترتيب'),
      TextCellValue('اسم الطالب'),
      TextCellValue('المرحلة'),
      TextCellValue('الصف'),
      TextCellValue('الفصل'),
      TextCellValue('عدد الملاحظات')
    ]);
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(student.name),
        TextCellValue(student.stage),
        TextCellValue(student.grade),
        TextCellValue(student.className),
        IntCellValue(student.totalDislikes)
      ]);
    }
    _saveAndDownloadExcel(context, excel, 'misbehaving_students_report.xlsx');
  }


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
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'تصدير القائمة إلى Excel',
          onPressed: () => _exportMisbehavingStudents(context, report.misbehavingStudents),
        ),
      ],
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
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'تصدير الترتيب إلى Excel',
          onPressed: () => _exportRankedClasses(context, report.rankedClasses),
        ),
      ],
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
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'تصدير الأوائل إلى Excel',
          onPressed: () => _exportTopStudents(context, report.topStudentsPerGrade),
        )
      ],
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
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'تصدير التفصيل إلى Excel',
          onPressed: () => _exportDetailedComparison(context, report, allStudentsData),
        )
      ],
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

  Future<void> _exportGradeComparison(BuildContext context, GradeComparisonResult result) async {
    final excel = Excel.createExcel();
    final sheet = excel['مقارنة فصول ${result.gradeName}'];
    sheet.isRTL = true;

    sheet.appendRow([TextCellValue('مقارنة أداء الفصول')]);
    sheet.appendRow([TextCellValue('الفصل'), TextCellValue('متوسط الدرجات')]);
    result.classAverages.forEach((className, avg) {
      sheet.appendRow([TextCellValue(className), DoubleCellValue(double.parse(avg.toStringAsFixed(2)))]);
    });
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('مقارنة المواد عبر الفصول')]);
    final allSubjects = result.subjectAveragesPerClass.values.expand((map) => map.keys).toSet().toList();
    final header = [TextCellValue('المادة'), ...result.subjectAveragesPerClass.keys.map((cn) => TextCellValue(cn))];
    sheet.appendRow(header);

    for (var subject in allSubjects) {
      final row = [TextCellValue(subject)];
      for (var className in result.subjectAveragesPerClass.keys) {
        final avg = result.subjectAveragesPerClass[className]![subject] ?? 0.0;
        row.add(DoubleCellValue(double.parse(avg.toStringAsFixed(2))) as TextCellValue);
      }
      sheet.appendRow(row);
    }
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('الطلاب الأوائل على الصف')]);
    sheet.appendRow([TextCellValue('الترتيب'), TextCellValue('الطالب'), TextCellValue('الفصل'), TextCellValue('المتوسط')]);
    for(int i = 0; i < result.topPerformersInGrade.length; i++) {
      final student = result.topPerformersInGrade[i];
      sheet.appendRow([
        IntCellValue(i+1),
        TextCellValue(student.name),
        TextCellValue(student.className),
        DoubleCellValue(double.parse(student.averageScore.toStringAsFixed(2)))
      ]);
    }
    _saveAndDownloadExcel(context, excel, 'grade_comparison_${result.gradeName}.xlsx');
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
            Text('تقرير مقارن لفصول: ${result.gradeName}', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'تصدير التقرير إلى Excel',
              onPressed: () => _exportGradeComparison(context, result),
            )
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
      _subjectToProfessionKeyMap.forEach((subjectName, profKey) {
        if (teacherData[profKey] == subjectName) {
          teacherSubjects[subjectName] = profKey;
        }
      });
      if (teacherSubjects.isEmpty) throw Exception('هذا المعلم ليس لديه مواد دراسية.');

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

  Future<void> _exportTeacherReportToExcel(TeacherAnalysisResult result) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];
    sheet.isRTL = true;

    void addHeader(String text, int rowIndex) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      cell.value = TextCellValue(text);
      cell.cellStyle = CellStyle(bold: true, fontSize: 14, backgroundColorHex: ExcelColor.blueGrey, fontColorHex: ExcelColor.white, horizontalAlign: HorizontalAlign.Center);
    }

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('تقرير أداء المعلم: ${result.name}');

    addHeader('المقاييس الأساسية', 2);
    sheet.appendRow([llValue('المقياس'), llValue('المادة/الفصل'), TextCellValue('القيمة')]);
    result.netValueAdded.forEach((subject, value) {
      sheet.appendRow([TextCellValue('القيمة المضافة الصافية'), TextCellValue(subject), TextCellValue(value.toStringAsFixed(2))]);
    });
    result.teachingConsistency.forEach((classSubject, value) {
      sheet.appendRow([TextCellValue('مؤشر اتساق التدريس'), TextCellValue(classSubject), TextCellValue(value.toStringAsFixed(2))]);
    });
    result.benchmarkGap.forEach((subject, value) {
      sheet.appendRow([TextCellValue('فجوة الأداء المعياري'), TextCellValue(subject), TextCellValue(value.toStringAsFixed(2))]);
    });

    int currentRow = sheet.maxRows + 1;
    addHeader('أداء الفصول', currentRow);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow + 1)).value = TextCellValue('المادة - الفصل');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow + 1)).value = TextCellValue('متوسط الأداء');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 1)).value = TextCellValue('حجم الفصل (طالب)');
    result.classSubjectAverages.forEach((classSubject, avg) {
      sheet.appendRow([TextCellValue(classSubject), TextCellValue(avg.toStringAsFixed(2)), TextCellValue(result.classSizes[classSubject]?.toString() ?? 'N/A')]);
    });

    currentRow = sheet.maxRows + 1;
    addHeader('متابعة السلوك', currentRow);
    sheet.appendRow([TextCellValue('إعجاب (طالب نبيل)'), TextCellValue(result.likesGiven.toString())]);
    sheet.appendRow([TextCellValue('ملاحظة سلوكية'), TextCellValue(result.dislikesGiven.toString())]);

    currentRow = sheet.maxRows + 2;
    addHeader('توصيات للإدارة', currentRow);
    for (var rec in result.recommendationsToAdmin) {
      sheet.appendRow([TextCellValue(rec)]);
    }

    currentRow = sheet.maxRows + 2;
    addHeader('توصيات للمعلم', currentRow);
    for (var rec in result.recommendationsToTeacher) {
      sheet.appendRow([TextCellValue(rec)]);
    }

    for (var i = 0; i < 4; i++) {
      sheet.setColAutoFit(i);
    }

    _saveAndDownloadExcel(context, excel, "teacher_report_${result.name.replaceAll(' ', '_')}.xlsx");
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
            if (_result != null && !_isLoading) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'تصدير التقرير إلى Excel',
                onPressed: () => _exportTeacherReportToExcel(_result!),
              ),
            ]
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

// --- ✅ START OF MODIFICATION ---
// The entire implementation of ComplaintsBoxPage is replaced here.
class ComplaintsBoxPage extends StatefulWidget {
  const ComplaintsBoxPage({super.key});

  @override
  State<ComplaintsBoxPage> createState() => _ComplaintsBoxPageState();
}

class _ComplaintsBoxPageState extends State<ComplaintsBoxPage> {
  // The state is now simpler. We don't need to track the admin status anymore
  // as the view is the same for everyone.

  /// Builds the Firestore stream to fetch complaints.
  ///
  /// This query is now the same for all users (admins and teachers).
  /// It fetches all behavior reports that have been replied to by a parent
  /// or have been closed, ordered by the most recent reply.
  /// This query works correctly with the existing index on `status` and `replyTimestamp`.
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
      // We directly use a StreamBuilder, which handles loading states internally.
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          // The check `!snapshot.hasData` is important for the initial frame.
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

          // No client-side filtering is needed.
          // All fetched documents are displayed directly.
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
// --- ✅ END OF MODIFICATION ---

// --- (ويدجت عرض المحادثة بين المعلم وولي الأمر) ---
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

  // --- 🛑 MODIFICATION START 🛑 ---
  Future<void> _submitTeacherFinalReply() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    // Get the current user to save their ID and Name.
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
      // Fetch the current teacher's name
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final replierName = currentUserDoc.data()?['name'] ?? 'معلم';

      final reportRef = FirebaseFirestore.instance.collection('behavior_reports').doc(widget.reportDoc.id);
      final reportData = widget.reportDoc.data() as Map<String, dynamic>? ?? {};
      final studentId = reportData['studentId'];
      final subject = reportData['subject'];

      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the complaint with the final reply, new status, and the replier's info.
      batch.update(reportRef, {
        'teacherFinalReply': _finalReplyController.text.trim(),
        'teacherFinalReplyTimestamp': FieldValue.serverTimestamp(),
        'status': 'closed',
        'finalReplierId': currentUser.uid,   // Save the ID of the teacher who replied
        'finalReplierName': replierName,       // Save the Name of the teacher who replied
      });

      // 2. Send a notification to the student.
      if (studentId != null) {
        final studentNotificationRef = FirebaseFirestore.instance.collection('students').doc(studentId).collection('notifications').doc();
        batch.set(studentNotificationRef, {
          // Use the name of the teacher who actually replied.
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
  // --- 🛑 MODIFICATION END 🛑 ---


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

    // --- 🛑 MODIFICATION START 🛑 ---
    // Read the new fields for the final replier's name and the original teacher's name.
    final finalReplierName = data['finalReplierName'] as String?;
    final originalTeacherName = data['teacherName'] ?? 'المعلم';
    // --- 🛑 MODIFICATION END 🛑 ---

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
              // --- 🛑 MODIFICATION 🛑 ---
              // Show the name of the original teacher.
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
                // --- 🛑 MODIFICATION 🛑 ---
                // Show the name of the teacher who wrote the final reply.
                author: 'رد نهائي من: أ. ${finalReplierName ?? originalTeacherName}',
                text: teacherFinalReply,
                timestamp: finalReplyTimestamp,
                isFinal: true,
              ),
            ] else ...[
              const Divider(height: 24),
              // --- 🛑 MODIFICATION 🛑 ---
              // Check if the current user is a teacher before showing the reply box.
              // This uses the same logic as the security rules.
              if (FirebaseAuth.instance.currentUser != null)
                FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
                    builder: (context, snapshot) {
                      // Only show the reply box if the user is a confirmed teacher.
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
                      // If user is not a teacher, show nothing.
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

// --- ( ✅ تعديل: تحويل الصفحة إلى StatefulWidget للتعامل مع صلاحيات المشرف ) ---
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

    // إذا لم يكن المستخدم مشرفاً، قم بتصفية المخالفات لعرض مخالفاته فقط
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

// --- Common Helper Widgets & Functions ---

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
      await file.writeAsBytes(fileBytes);
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