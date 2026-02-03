// add1.dart
// ✅ (MODIFIED) تم تحديث معايير السلوك (Likes/Dislikes) لتكون إلزامية وشاملة
// ✅ تم إضافة ميزة الرصد الجماعي (Bulk Action) للفصل كاملاً
// ✅ تم دمج التقييم مع رصد الدرجة ورفعه على Firebase

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

// ---------------------------------------------------------------------------
// 1. صفحة اختيار المرحلة والصف والفصل والمادة (البوابة الرئيسية)
// ---------------------------------------------------------------------------

class GradeEntrySelectionPage extends StatefulWidget {
  final bool isBehaviorMode;
  final bool isAdmin;

  const GradeEntrySelectionPage({
    super.key,
    required this.isBehaviorMode,
    required this.isAdmin,
  });

  @override
  _GradeEntrySelectionPageState createState() => _GradeEntrySelectionPageState();
}

class _GradeEntrySelectionPageState extends State<GradeEntrySelectionPage> {
  Map<String, dynamic>? _userData;
  String? _selectedStage, _selectedGrade, _selectedClass;
  bool _isLoading = true;

  Map<String, Map<String, List<String>>> _classSubjectMapByGrade = {};

  List<String> _subjectsForSelectedClass = [];
  List<String> _availableStages = [];
  Map<String, List<String>> _gradesByStage = {};
  List<String> _gradesForSelectedStage = [];
  List<String> _classesForSelectedGrade = [];

  final List<String> _allStages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
  final List<String> _allGrades = [
    'الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس',
    'الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'
  ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBehaviorMode ? 'اختيار فصل لتقييم السلوك' : 'اختيار فصل ومادة للرصد'),
        backgroundColor: widget.isBehaviorMode ? Colors.teal : Colors.blue,
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
                _subjectsForSelectedClass = _classSubjectMapByGrade[_selectedGrade!]?[val] ?? [];
              } else {
                _subjectsForSelectedClass = widget.isAdmin ? _allSubjects : [];
              }
            })),
            const SizedBox(height: 24),
          ],
          if (_selectedClass != null) ...[
            const Divider(thickness: 1, height: 30),
            _buildSectionTitle(widget.isBehaviorMode ? '4. تقييم سلوك الفصل' : '4. اختر المادة',
                widget.isBehaviorMode ? Icons.sentiment_very_satisfied : Icons.book),
            const SizedBox(height: 16),
            _buildSubjectGrid(
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
        Icon(icon, color: widget.isBehaviorMode ? Colors.teal : Colors.blue),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isBehaviorMode ? Colors.teal : Colors.blue)),
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
      return const Center(
          child: Padding(
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
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          onPressed: () {
            if (_selectedStage != null && _selectedGrade != null && _selectedClass != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeEntryPage(
                    stage: _selectedStage!,
                    grade: _selectedGrade!,
                    className: _selectedClass!,
                    subject: 'سلوك',
                    testFieldKey: 'behavior',
                    testName: 'تقييم السلوك والمواظبة',
                    isBehaviorMode: true,
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
            foregroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.blue.withOpacity(0.5))),
            elevation: 3,
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            if (_selectedStage != null && _selectedGrade != null && _selectedClass != null) {
              final professionKey = _subjectToProfessionKeyMap[subject];
              if (professionKey == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: المادة "$subject" غير قابلة للاختيار هنا.')),
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
                    isBehaviorMode: false,
                    isAdmin: widget.isAdmin,
                  ),
                ),
              );
            }
          },
          child: Text(subject,
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 2. صفحة اختيار الاختبار (TestSelectionPage)
// ---------------------------------------------------------------------------

class TestItem {
  final String testFieldKey;
  final String name;
  final String term;

  TestItem({
    required this.testFieldKey,
    required this.name,
    required this.term,
  });
}

class TestSelectionPage extends StatelessWidget {
  final String stage;
  final String grade;
  final String className;
  final String subject;
  final String professionKey;
  final bool isBehaviorMode;
  final bool isAdmin;

  const TestSelectionPage({
    super.key,
    required this.stage,
    required this.grade,
    required this.className,
    required this.subject,
    required this.professionKey,
    required this.isBehaviorMode,
    required this.isAdmin,
  });

  static const Map<String, String> _subjectShortcodes = {
    'رياضيات': 'math',
    'لغتي': 'lughati',
    'علوم': 'science',
  };

  List<TestItem> _getTestsForSubject() {
    final List<TestItem> allTests = [];
    final bool isNafesSubject = ['رياضيات', 'لغتي', 'علوم'].contains(subject);
    final String currentSubjectShortcode = _subjectShortcodes[subject] ?? '';

    if (!isNafesSubject || professionKey != 'profession13') {
      allTests.addAll([
        TestItem(testFieldKey: 'e1$professionKey', name: 'الاختبار الاول (دوري)', term: 'الترم الأول'),
        TestItem(testFieldKey: 'e2$professionKey', name: 'الاختبار الثاني (دوري)', term: 'الترم الأول'),
        TestItem(testFieldKey: 'e3$professionKey', name: 'الاختبار الثالث (دوري)', term: 'الترم الأول'),
        TestItem(testFieldKey: 'e14$professionKey', name: 'اختبار قبلي', term: 'اختبارات إضافية'),
        TestItem(testFieldKey: 'e15$professionKey', name: 'اختبار بعدي', term: 'اختبارات إضافية'),
        TestItem(testFieldKey: 'e16$professionKey', name: 'اختبار احتياطي', term: 'اختبارات إضافية'),
      ]);
    }

    final bool isGrade6 = grade == 'الصف السادس';
    final bool isGrade3 = grade == 'الصف الثالث';
    final bool isScienceMathsLughati = ['علوم', 'رياضيات', 'لغتي'].contains(subject);
    final bool isMathsLughati = ['رياضيات', 'لغتي'].contains(subject);

    if (currentSubjectShortcode.isNotEmpty && ((isGrade6 && isScienceMathsLughati) || (isGrade3 && isMathsLughati))) {
      const String nafesBaseKey = 'profession13';
      allTests.addAll([
        TestItem(testFieldKey: 'e1${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الأول أساسي', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e2${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثاني أساسي', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e5${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثالث ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e6${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الرابع ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e7${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الخامس ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e8${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار السادس ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e9${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار السابع ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e10${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار الثامن ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e11${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار التاسع ف نافس', term: 'اختبارات نافس'),
        TestItem(testFieldKey: 'e12${nafesBaseKey}_$currentSubjectShortcode', name: 'الاختبار العاشر ف نافس', term: 'اختبارات نافس'),
      ]);
    }

    return allTests;
  }

  @override
  Widget build(BuildContext context) {
    final allTests = _getTestsForSubject();
    final term1Tests = allTests.where((t) => t.term == 'الترم الأول').toList();
    final additionalTests = allTests.where((t) => t.term == 'اختبارات إضافية').toList();
    final nafsTests = allTests.where((t) => t.term == 'اختبارات نافس').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('اختر الاختبار - $subject'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (term1Tests.isNotEmpty)
            _buildTermSection(context, 'الاختبارات الدورية', term1Tests),

          if (term1Tests.isNotEmpty && (additionalTests.isNotEmpty || nafsTests.isNotEmpty))
            const SizedBox(height: 24),

          if (additionalTests.isNotEmpty)
            _buildTermSection(context, 'اختبارات إضافية', additionalTests),

          if (additionalTests.isNotEmpty && nafsTests.isNotEmpty)
            const SizedBox(height: 24),

          if (nafsTests.isNotEmpty)
            _buildTermSection(context, 'اختبارات نافس', nafsTests),
        ],
      ),
    );
  }

  Widget _buildTermSection(BuildContext context, String title, List<TestItem> termTests) {
    if (termTests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Divider(),
        ...termTests.map((test) {
          return _TestTile(
            test: test,
            isAdmin: isAdmin,
            onTap: (isLocked) {
              if (isLocked && !isAdmin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا الاختبار مغلق حالياً من قبل الإدارة.')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeEntryPage(
                      stage: stage,
                      grade: grade,
                      className: className,
                      subject: subject,
                      testFieldKey: test.testFieldKey,
                      testName: test.name,
                      isBehaviorMode: false,
                    ),
                  ),
                );
              }
            },
          );
        }).toList(),
      ],
    );
  }
}

class _TestTile extends StatefulWidget {
  final TestItem test;
  final bool isAdmin;
  final Function(bool isLocked) onTap;

  const _TestTile({
    required this.test,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  __TestTileState createState() => __TestTileState();
}

class __TestTileState extends State<_TestTile> {
  bool? _isLocked;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _lockStatusSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLockStatus();
  }

  @override
  void dispose() {
    _lockStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenToLockStatus() {
    _lockStatusSubscription = _firestore
        .collection('test_status')
        .doc(widget.test.testFieldKey)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          _isLocked = doc.exists ? (doc.data()?['isLocked'] ?? false) : false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLocked = true; // Default to locked on error safety
        });
      }
    });
  }

  Future<void> _toggleLockStatus() async {
    if (_isLocked == null) return;
    final newStatus = !_isLocked!;

    setState(() {
      _isLocked = newStatus;
    });

    try {
      await _firestore.collection('test_status').doc(widget.test.testFieldKey).set({
        'isLocked': newStatus,
        'testName': widget.test.name,
      });
    } catch (e) {
      setState(() {
        _isLocked = !newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث حالة الاختبار: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked == null) {
      return Card(
        child: const ListTile(
          title: Text('جارِ التحميل...'),
        ),
      );
    }

    final bool isEffectivelyLocked = _isLocked!;
    final Color iconColor = isEffectivelyLocked ? Colors.grey : Theme.of(context).primaryColor;
    final Color textColor = isEffectivelyLocked ? Colors.grey : Colors.black;
    final bool canTap = !isEffectivelyLocked || widget.isAdmin;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(
          isEffectivelyLocked ? Icons.lock_outline : Icons.edit_note,
          color: iconColor,
        ),
        title: Text(
          widget.test.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        trailing: widget.isAdmin
            ? IconButton(
          icon: Icon(isEffectivelyLocked ? Icons.lock : Icons.lock_open, color: iconColor),
          tooltip: isEffectivelyLocked ? 'فتح الاختبار للمعلمين' : 'قفل الاختبار على المعلمين',
          onPressed: _toggleLockStatus,
        )
            : (isEffectivelyLocked ? null : const Icon(Icons.arrow_forward_ios, size: 16)),
        onTap: canTap ? () => widget.onTap(isEffectivelyLocked) : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. صفحة رصد الدرجات / تسجيل السلوك (GradeEntryPage) مع التقييم الإلزامي والجماعي
// ---------------------------------------------------------------------------

class GradeEntryPage extends StatefulWidget {
  final String stage;
  final String grade;
  final String className;
  final String subject;
  final String testFieldKey;
  final String testName;
  final bool isBehaviorMode;

  const GradeEntryPage({
    super.key,
    required this.stage,
    required this.grade,
    required this.className,
    required this.subject,
    required this.testFieldKey,
    required this.testName,
    required this.isBehaviorMode,
  });

  @override
  _GradeEntryPageState createState() => _GradeEntryPageState();
}

class _GradeEntryPageState extends State<GradeEntryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _students = [];
  Map<String, dynamic> _grades = {};
  Map<String, dynamic> _evaluations = {};

  final Map<String, int> _likes = {};
  final Map<String, int> _dislikes = {};

  // -------------------------------------------
  // 🟢 قوائم الإيجابيات (Likes Criteria)
  // -------------------------------------------
  final Map<String, List<String>> _positiveBehaviors = {
    'القيم والأخلاق (Character)': [
      'الأمانة والصدق (اعترف بخطأه بشجاعة)',
      'إصلاح ذات البين (حل مشكلة بين زميلين)',
      'التواضع وتقبل النصيحة',
      'بر الوالدين (يظهر في حديثه وسلوكه)',
      'كظم الغيظ (تمالك نفسه عند الغضب)',
    ],
    'المهارات الأكاديمية والقيادية': [
      'قائد فريق ناجح (يدير مجموعته بذكاء)',
      'طرح أسئلة ذكية وناقدة',
      'المعلم الصغير (شرح نقطة لزميله ببراعة)',
      'سرعة البديهة والمشاركة الفعالة',
      'جمال الخط وترتيب الدفتر',
    ],
    'المسؤولية والمبادرة': [
      'مبادرة لتنظيف الفصل دون طلب',
      'الحفاظ على ممتلكات المدرسة',
      'إحضار أدوات إضافية لمساعدة زملائه (الإيثار)',
      'الإنصات الجيد واحترام المتحدث',
      'الالتزام التام بالزي المدرسي والمظهر العام',
    ],
    'التطوير الذاتي': [
      'تحسن ملحوظ في المستوى (لمن كان مستواه ضعيفاً)',
      'إنجاز المهام قبل الوقت المحدد',
      'الحرص على صلاة الجماعة في الصف الأول',
    ],
  };

  // -------------------------------------------
  // 🔴 قوائم السلبيات (Dislikes Criteria)
  // -------------------------------------------
  final Map<String, List<String>> _negativeBehaviors = {
    'سلوكيات "الاستحقاق" والتعالي': [
      'التعامل بفوقية مع المعلم (نظرة "أنا أدفع راتبك")',
      'التهديد المبطن ("أنت لا تعرف من أبي")',
      'الجدال العقيم وتصيد الأخطاء للمعلم',
      'الضحك المستفز أو المصطنع للتشويش',
      'تقليد المعلم أو السخرية من حركاته',
    ],
    'التنمر والعلاقات الاجتماعية': [
      'التنمر اللفظي (ألقاب مسيئة، سخرية من الشكل)',
      'التنمر الجسدي (الدف، الضرب الخفيف المستفز)',
      'التنمر الإلكتروني (تصوير الزملاء، نشر شائعات)',
      'إقصاء زميل متعمداً من المجموعة (العنصرية/الشللية)',
      'التحريض ضد طالب آخر',
    ],
    'سوء استخدام التقنية والممتلكات': [
      'استخدام الساعة الذكية للغش أو اللعب',
      'إخراج الهاتف المحمول في الفصل',
      'العبث بإعدادات أجهزة المدرسة (المكيفات، الكمبيوتر)',
      'الكتابة على الطاولات أو الجدران',
      'إهدار الموارد (مناديل، أوراق، ألوان)',
    ],
    'الإهمال الأكاديمي والديني': [
      'عدم حفظ الآيات القرآنية المقررة',
      'عدم حفظ جدول الضرب / الأساسيات',
      'عدم إحضار الكتاب أو الدفتر',
      'النوم داخل الحصة',
      'الغش في الاختبارات أو الواجبات',
      'نسيان الزي الرياضي',
    ],
    'الانضباط العام': [
      'كثرة الاستئذان للخروج (الهروب المقنع)',
      'التأخر الصباحي أو التأخر عن دخول الحصة',
      'تناول الطعام/العلكة أثناء الشرح',
      'مقاطعة المعلم أثناء الحديث',
      'إثارة الفوضى عند غياب المعلم',
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndGrades();
  }

  Future<void> _fetchStudentsAndGrades() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('stages', isEqualTo: widget.stage)
          .where('grades', isEqualTo: widget.grade)
          .where('classes', isEqualTo: widget.className)
          .get();

      var students = querySnapshot.docs;

      students.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>? ?? {};
        final bData = b.data() as Map<String, dynamic>? ?? {};
        final String aName = aData['name'] ?? '';
        final String bName = bData['name'] ?? '';
        return aName.compareTo(bName);
      });

      final grades = <String, dynamic>{};
      final evaluations = <String, dynamic>{};
      final likes = <String, int>{};
      final dislikes = <String, int>{};

      for (var studentDoc in students) {
        final data = studentDoc.data() as Map<String, dynamic>?;
        final studentId = studentDoc.id;
        grades[studentId] = data?[widget.testFieldKey];

        if (data != null && data.containsKey('eval_${widget.testFieldKey}')) {
          evaluations[studentId] = data['eval_${widget.testFieldKey}'];
        }

        likes[studentId] = data?['totalLikes'] ?? 0;
        dislikes[studentId] = data?['totalDislikes'] ?? 0;
      }

      if (mounted) {
        setState(() {
          _students = students;
          _grades = grades;
          _evaluations = evaluations;
          _likes.addAll(likes);
          _dislikes.addAll(dislikes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في جلب بيانات الطلاب: $e')),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // نافذة اختيار سبب السلوك (موحدة للـ Like و Dislike)
  // --------------------------------------------------------------------------
  Future<Map<String, String>?> _showBehaviorSelectionDialog({required bool isLike}) async {
    final Map<String, List<String>> dataSource = isLike ? _positiveBehaviors : _negativeBehaviors;
    String? selectedReason;
    final noteController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isLike ? 'اختر سبب التميز (Like)' : 'اختر سبب الملاحظة (Dislike)',
                style: TextStyle(color: isLike ? Colors.green : Colors.red),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: dataSource.entries.map((entry) {
                          return ExpansionTile(
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            children: entry.value.map((reason) {
                              return RadioListTile<String>(
                                title: Text(reason, style: const TextStyle(fontSize: 12)),
                                value: reason,
                                groupValue: selectedReason,
                                dense: true,
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedReason = val;
                                  });
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة إضافية (اختياري)',
                        hintText: 'مثال: في حصة القرآن',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLike ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selectedReason == null
                      ? null // تعطيل الزر إذا لم يتم اختيار سبب
                      : () {
                    Navigator.of(context).pop({
                      'reason': selectedReason!,
                      'note': noteController.text.trim(),
                    });
                  },
                  child: const Text('تأكيد وحفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // إضافة تقرير سلوك فردي
  // --------------------------------------------------------------------------
  Future<void> _addBehaviorReport(String studentId, String studentName, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isLike = (type == 'like');
    // ✅ طلب اختيار السبب (إلزامي)
    final result = await _showBehaviorSelectionDialog(isLike: isLike);

    if (result == null) return; // تم الإلغاء
    final String reason = result['reason']!;
    final String extraNote = result['note'] ?? '';

    try {
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      final teacherName = teacherDoc.data()?['name'] ?? 'معلم غير معروف';
      final now = DateTime.now();
      final dayName = intl.DateFormat('EEEE', 'ar').format(now);

      final studentRef = _firestore.collection('students').doc(studentId);
      final reportRef = _firestore.collection('behavior_reports').doc();

      final reportData = {
        'studentId': studentId,
        'studentName': studentName,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'subject': widget.subject,
        'type': type,
        'reason': reason, // ✅ تم حفظ السبب
        'note': extraNote, // ✅ تم حفظ الملاحظة الإضافية
        'timestamp': FieldValue.serverTimestamp(),
        'dateString': intl.DateFormat('yyyy/MM/dd').format(now),
        'dayName': dayName,
        'status': type == 'dislike' ? 'pending_reply' : 'like_added',
      };

      await _firestore.runTransaction((transaction) async {
        transaction.update(studentRef, {
          type == 'like' ? 'totalLikes' : 'totalDislikes': FieldValue.increment(1),
        });
        transaction.set(reportRef, reportData);
      });

      if (mounted) {
        setState(() {
          if (type == 'like') {
            _likes[studentId] = (_likes[studentId] ?? 0) + 1;
          } else {
            _dislikes[studentId] = (_dislikes[studentId] ?? 0) + 1;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(type == 'like' ? 'تم إضافة اللايك: $reason' : 'تم إضافة الملاحظة: $reason'),
          backgroundColor: isLike ? Colors.green : Colors.redAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل تسجيل السلوك: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // --------------------------------------------------------------------------
  //  إدارة الرصد الجماعي (Bulk Action)
  // --------------------------------------------------------------------------
  Future<void> _handleBulkAction(bool isLike) async {
    if (_students.isEmpty) return;

    // 1. اختيار السبب الموحد
    final result = await _showBehaviorSelectionDialog(isLike: isLike);
    if (result == null) return;

    final String reason = result['reason']!;
    final String extraNote = result['note'] ?? '';

    // 2. تأكيد نهائي
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLike ? 'إرسال لايكات للكل' : 'إرسال ديسلايك للكل'),
        content: Text('هل أنت متأكد من منح ${isLike ? 'لايك' : 'ديسلايك'} لجميع طلاب الفصل (${_students.length} طالب)؟\n\nالسبب: $reason'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isLike ? Colors.green : Colors.red),
            child: const Text('نعم، نفذ'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      final teacherName = teacherDoc.data()?['name'] ?? 'معلم غير معروف';
      final now = DateTime.now();
      final dayName = intl.DateFormat('EEEE', 'ar').format(now);
      final dateString = intl.DateFormat('yyyy/MM/dd').format(now);

      // استخدام Batch للكتابة الجماعية (تحسين الأداء وضمان الذرية)
      WriteBatch batch = _firestore.batch();

      for (var student in _students) {
        final studentId = student.id;
        final studentName = student.data() != null ? (student.data() as Map)['name'] ?? '?' : '?';

        // مرجع الطالب للتحديث
        final studentRef = _firestore.collection('students').doc(studentId);
        batch.update(studentRef, {
          isLike ? 'totalLikes' : 'totalDislikes': FieldValue.increment(1),
        });

        // إنشاء تقرير جديد
        final reportRef = _firestore.collection('behavior_reports').doc();
        final reportData = {
          'studentId': studentId,
          'studentName': studentName,
          'teacherId': user.uid,
          'teacherName': teacherName,
          'subject': widget.subject,
          'type': isLike ? 'like' : 'dislike',
          'reason': reason,
          'note': extraNote,
          'timestamp': FieldValue.serverTimestamp(),
          'dateString': dateString,
          'dayName': dayName,
          'isBulk': true, // علامة لتمييز الإرسال الجماعي
          'status': isLike ? 'like_added' : 'pending_reply',
        };
        batch.set(reportRef, reportData);
      }

      await batch.commit();

      // تحديث الواجهة محلياً
      setState(() {
        for (var student in _students) {
          if (isLike) {
            _likes[student.id] = (_likes[student.id] ?? 0) + 1;
          } else {
            _dislikes[student.id] = (_dislikes[student.id] ?? 0) + 1;
          }
        }
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تنفيذ العملية الجماعية بنجاح!'),
          backgroundColor: Colors.blueAccent,
        ));
      }

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --------------------------------------------------------------------------
  // وظائف حفظ الدرجات القديمة (كما هي)
  // --------------------------------------------------------------------------
  Future<void> _saveGrade(String studentId, num grade, Map<String, dynamic>? evaluationData) async {
    try {
      final studentRef = _firestore.collection('students').doc(studentId);
      Map<String, dynamic> updates = { widget.testFieldKey: grade };
      if (evaluationData != null) {
        updates['eval_${widget.testFieldKey}'] = evaluationData;
      }
      await studentRef.set(updates, SetOptions(merge: true));

      setState(() {
        _grades[studentId] = grade;
        if (evaluationData != null) {
          _evaluations[studentId] = evaluationData;
        }
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(grade == -1 ? 'تم تسجيل الطالب كـ "غائب"' : 'تم حفظ الدرجة والتقييم بنجاح'),
              backgroundColor: grade == -1 ? Colors.blueGrey : Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ الدرجة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteGrade(String studentId) async {
    try {
      final studentRef = _firestore.collection('students').doc(studentId);
      await studentRef.update({
        widget.testFieldKey: FieldValue.delete(),
        'eval_${widget.testFieldKey}': FieldValue.delete(),
      });

      if (mounted) {
        setState(() {
          _grades[studentId] = null;
          _evaluations[studentId] = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم الحذف بنجاح'),
              backgroundColor: Colors.blueAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل حذف الدرجة: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _areAllGradesEntered() {
    if (_students.isEmpty) return false;
    for (final student in _students) {
      if (_grades[student.id] == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _exportToExcel() async {
    if (!_areAllGradesEntered()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب رصد جميع درجات الطلاب أولاً لتتمكن من تحميل الملف.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Sheet1'];
    sheetObject.isRTL = true;
    final List<String> headers = ['اسم الطالب', 'الدرجة', 'النسبة المئوية', 'التقييم'];
    sheetObject.appendRow(headers.map((header) => TextCellValue(header)).toList());

    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    final bool isNafes = widget.testFieldKey.contains('profession13');
    final double maxGrade = isNafes ? 10.0 : 20.0;

    String getEvaluation(num grade) {
      double percentage = (grade / maxGrade) * 100;
      if (percentage >= 90) return "ممتاز";
      if (percentage >= 80) return "جيد جدا";
      if (percentage >= 70) return "جيد";
      if (percentage >= 50) return "مقبول";
      return "يحتاج لمتابعة";
    }

    List<DocumentSnapshot> sortedStudents = List.from(_students);
    sortedStudents.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>? ?? {};
      final bData = b.data() as Map<String, dynamic>? ?? {};
      final String aName = aData['name'] ?? '';
      final String bName = bData['name'] ?? '';
      return aName.compareTo(bName);
    });

    for (var studentDoc in sortedStudents) {
      final studentId = studentDoc.id;
      final studentName = (studentDoc.data() as Map<String, dynamic>)['name'] ?? 'اسم غير معروف';
      final grade = _grades[studentId];

      if (grade != null) {
        if (grade == -1) {
          final List<CellValue> row = [
            TextCellValue(studentName),
            TextCellValue('غائب'),
            TextCellValue('N/A'),
            TextCellValue('N/A')
          ];
          sheetObject.appendRow(row);
        } else {
          final double percentage = (grade / maxGrade) * 100;
          final String evaluation = getEvaluation(grade);
          final List<CellValue> row = [
            TextCellValue(studentName),
            DoubleCellValue(grade.toDouble()),
            TextCellValue('${percentage.toStringAsFixed(1)}%'),
            TextCellValue(evaluation)
          ];
          sheetObject.appendRow(row);
        }
      }
    }

    for (var i = 0; i < headers.length; i++) { sheetObject.setColAutoFit(i); }

    final String fileName = "درجات-${widget.testName}-${widget.className}.xlsx";
    final fileBytes = excel.save();

    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إنشاء ملف Excel.'), backgroundColor: Colors.red),
      );
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('لم يتم العثور على تطبيق لفتح ملفات Excel. الخطأ: ${result.message}')),
            );
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تصدير الملف بنجاح باسم: $fileName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير الملف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildGradeChip({
    required dynamic currentGrade,
    required VoidCallback onTap,
  }) {
    String text;
    Color backgroundColor;
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;
    Color borderColor;

    if (currentGrade == -1) {
      text = 'غائب';
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      borderColor = Colors.grey.shade400;
      fontWeight = FontWeight.bold;
    } else if (currentGrade != null) {
      text = currentGrade.toString();
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      borderColor = Colors.green.shade300;
      fontWeight = FontWeight.bold;
    } else {
      text = 'رصد';
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      borderColor = Colors.orange.shade300;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 65,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGradeEntryDialog({
    required String studentId,
    required String studentName,
    required dynamic currentGrade,
    required double maxGrade,
    required double passingGrade,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _GradeEntryDialog(
          studentId: studentId,
          studentName: studentName,
          currentGrade: currentGrade,
          currentEvaluation: _evaluations[studentId],
          maxGrade: maxGrade,
          passingGrade: passingGrade,
          subjectName: widget.subject,
          onSaveGrade: _saveGrade,
          onDeleteGrade: _deleteGrade,
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // زر اختيار الإجراء الجماعي (Bulk Button)
  // --------------------------------------------------------------------------
  void _showBulkActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إجراء جماعي للفصل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.thumb_up, color: Colors.green),
                title: const Text('منح (لايك) للجميع'),
                subtitle: const Text('سيتم طلب السبب وتطبيقه على كل الطلاب'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleBulkAction(true);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.thumb_down, color: Colors.red),
                title: const Text('منح (ديسلايك) للجميع'),
                subtitle: const Text('سيتم طلب السبب وتطبيقه على كل الطلاب'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleBulkAction(false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allGradesEntered = _areAllGradesEntered();
    final bool isNafes = widget.testFieldKey.contains('profession13');
    final double maxGrade = isNafes ? 10.0 : 20.0;
    final double passingGrade = isNafes ? 5.0 : 10.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(25),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${widget.stage} / ${widget.grade} / ${widget.className}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
        actions: [
          // زر الإجراء الجماعي (فقط في وضع السلوك)
          if (widget.isBehaviorMode)
            IconButton(
              icon: const Icon(Icons.groups_3_outlined),
              tooltip: 'إجراء جماعي (لايك/ديسلايك للكل)',
              onPressed: _showBulkActionSheet,
            ),
          // زر التصدير (فقط في وضع الدرجات)
          if (!widget.isBehaviorMode)
            IconButton(
              icon: Icon(
                Icons.download_for_offline_outlined,
                color: allGradesEntered ? Colors.lightBlueAccent : Colors.white38,
              ),
              tooltip: 'تحميل ملف الدرجات لهذا الاختبار (Excel)',
              onPressed: allGradesEntered ? _exportToExcel : null,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? const Center(child: Text('لا يوجد طلاب في هذا الفصل.', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _students.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final studentDoc = _students[index];
          final studentId = studentDoc.id;
          final studentData = studentDoc.data() as Map<String, dynamic>;

          String studentName = studentData['name'] ?? 'اسم غير معروف';
          if (studentName.length > 20) {
            studentName = '${studentName.substring(0, 20)}..';
          }

          final currentGrade = _grades[studentId];
          final likeCount = _likes[studentId] ?? 0;
          final dislikeCount = _dislikes[studentId] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.isBehaviorMode) ...[
                  const SizedBox(width: 6),
                  if (likeCount > 0)
                    SizedBox(
                      height: 23,
                      child: Chip(
                        avatar: const Icon(Icons.thumb_up, color: Colors.green, size: 10.5),
                        label: Text('$likeCount', style: const TextStyle(fontSize: 9.5)),
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                        backgroundColor: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  const SizedBox(width: 4),
                  if (dislikeCount > 0)
                    SizedBox(
                      height: 23,
                      child: Chip(
                        avatar: const Icon(Icons.thumb_down, color: Colors.red, size: 10.5),
                        label: Text('$dislikeCount', style: const TextStyle(fontSize: 9.5)),
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                        backgroundColor: Colors.red.withOpacity(0.1),
                      ),
                    ),
                ]
              ],
            ),
            subtitle: widget.isBehaviorMode
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.green),
                  onPressed: () => _addBehaviorReport(studentId, studentName, 'like'),
                  tooltip: 'إعجاب (سلوك نبيل)',
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down, color: Colors.red),
                  onPressed: () => _addBehaviorReport(studentId, studentName, 'dislike'),
                  tooltip: 'ملاحظة (سلوك شغب)',
                ),
              ],
            )
                : null,
            trailing: !widget.isBehaviorMode
                ? _buildGradeChip(
              currentGrade: currentGrade,
              onTap: () {
                _showGradeEntryDialog(
                  studentId: studentId,
                  studentName: studentName,
                  currentGrade: currentGrade,
                  maxGrade: maxGrade,
                  passingGrade: passingGrade,
                );
              },
            )
                : null,
          );
        },
      ),
    );
  }
}


class _GradeEntryDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final dynamic currentGrade;
  final Map<String, dynamic>? currentEvaluation;
  final double maxGrade;
  final double passingGrade;
  final String subjectName;
  final Future<void> Function(String studentId, num grade, Map<String, dynamic>? evaluationData) onSaveGrade;
  final Future<void> Function(String studentId) onDeleteGrade;

  const _GradeEntryDialog({
    required this.studentId,
    required this.studentName,
    required this.currentGrade,
    this.currentEvaluation,
    required this.maxGrade,
    required this.passingGrade,
    required this.subjectName,
    required this.onSaveGrade,
    required this.onDeleteGrade,
  });

  @override
  State<_GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<_GradeEntryDialog> {
  late TextEditingController _gradeController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  List<String> _selectedWeaknesses = [];
  String? _severityLevel; // منخفض، متوسط، مرتفع

  final Map<String, List<String>> _subjectCriteria = {
    'لغتي': [
      'التمييز بين أقسام الكلمة',
      'التمييز بين الجملة المثبتة والمنفية',
      'التمييز بين اللام الشمسية والقمرية',
      'تمييز الموقع الإعرابي للكلمة',
      'الأساليب واستخدام علامات الترقيم',
      'التمييز بين علامات الإعراب الأصلية والفرعية',
      'التمييز بين أقسام الفعل من حيث الزمن',
      'التمييز بين الجملة الاسمية والفعلية',
      'تمييز الأفعال الخمسة',
      'الرسم الإملائي',
      'مهارات القراءة والاستيعاب',
    ],
    'رياضيات': [
      'حفظ جدول الضرب',
      'إتقان العمليات الحسابية الأربع (جمع، طرح، ضرب، قسمة)',
      'فهم واستخدام الكسور',
      'استيعاب المفاهيم الهندسية والقياس',
      'حل المسائل اللفظية',
      'ترتيب ومقارنة الأعداد',
      'تحليل البيانات والتمثيل البياني',
      'القيمة المنزلية للأعداد',
    ],
    'علوم': [
      'استيعاب المفاهيم العلمية الأساسية',
      'تطبيق خطوات المنهج العلمي',
      'التمييز بين الكائنات الحية واحتياجاتها',
      'فهم حالات المادة وخصائصها',
      'التعرف على الظواهر الطبيعية (الكون، الأرض)',
      'حفظ المصطلحات العلمية',
      'الربط بين السبب والنتيجة',
      'الطاقة والقوى والحركة',
    ],
    'انجليزي': [
      'مهارة الاستماع (Listening Skills)',
      'مهارة التحدث (Speaking Skills)',
      'مهارة القراءة (Reading Skills)',
      'مهارة الكتابة (Writing Skills)',
      'القواعد (Grammar)',
      'المفردات (Vocabulary)',
      'النطق الصحيح (Pronunciation)',
      'المشاركة والتفاعل (Participation)',
    ],
  };

  List<String> get _currentCriteriaList {
    if (widget.subjectName.contains('لغتي')) return _subjectCriteria['لغتي']!;
    if (widget.subjectName.contains('رياضيات')) return _subjectCriteria['رياضيات']!;
    if (widget.subjectName.contains('علوم')) return _subjectCriteria['علوم']!;
    if (widget.subjectName.contains('انجليزي') || widget.subjectName.contains('نجليزي')) return _subjectCriteria['انجليزي']!;
    return ['ضعف عام في الاستيعاب', 'عدم المشاركة الصفية', 'نقص في حل الواجبات', 'صعوبة في الفهم'];
  }

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(
      text: (widget.currentGrade != null && widget.currentGrade != -1)
          ? widget.currentGrade.toString()
          : '',
    );

    if (widget.currentEvaluation != null) {
      if (widget.currentEvaluation!['selected_points'] != null) {
        _selectedWeaknesses = List<String>.from(widget.currentEvaluation!['selected_points']);
      }
      _severityLevel = widget.currentEvaluation!['severity'];
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _showAssessmentSelectionDialog() async {
    final List<String> criteria = _currentCriteriaList;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تقييم جوانب القصور'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اختر نقاط الضعف:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    ...criteria.map((criterion) {
                      return CheckboxListTile(
                        title: Text(criterion, style: const TextStyle(fontSize: 14)),
                        value:   _selectedWeaknesses.contains(criterion),
                        dense: true,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedWeaknesses.add(criterion);
                            } else {
                              _selectedWeaknesses.remove(criterion);
                            }
                          });
                          this.setState(() {});
                        },
                      );
                    }).toList(),
                    const Divider(),
                    const Text('درجة القصور (اختياري):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _severityLevel,
                      hint: const Text("اختر المستوى"),
                      items: ['منخفضة', 'متوسطة', 'مرتفعة'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          _severityLevel = val;
                        });
                        this.setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final text = _gradeController.text.trim();

    try {
      final grade = num.tryParse(text);
      if (grade == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('الرجاء إدخال رقم صحيح'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      if (grade < widget.passingGrade) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ تحذير'),
            content: Text(
                'الدرجة المدخلة أقل من درجة النجاح (${widget.passingGrade}). هل أنت متأكد من رصدها؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('تأكيد الرصد'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      Map<String, dynamic>? evalData;
      if (_selectedWeaknesses.isNotEmpty) {
        evalData = {
          'selected_points': _selectedWeaknesses,
          'severity': _severityLevel,
          'timestamp': Timestamp.now(),
        };
      } else {
        evalData = null;
      }

      await widget.onSaveGrade(widget.studentId, grade, evalData);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSaveAbsent() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSaveGrade(widget.studentId, -1, null);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onDeleteGrade(widget.studentId);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEvaluation = _selectedWeaknesses.isNotEmpty;
    final Color evalBoxColor = hasEvaluation ? Colors.green.shade100 : Colors.amber.shade100;
    final Color evalBorderColor = hasEvaluation ? Colors.green : Colors.amber;

    return AlertDialog(
      title: null,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      content: SingleChildScrollView(
        child: _isSaving
            ? const SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        )
            : Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الطالب: ${widget.studentName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _gradeController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final num? value = num.tryParse(newValue.text);
                        if (value != null && value > widget.maxGrade) {
                          return oldValue;
                        }
                        return newValue;
                      }),
                    ],
                    decoration: InputDecoration(
                      labelText: 'الدرجة (من ${widget.maxGrade})',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'أدخل درجة';
                      }
                      final grade = num.tryParse(value.trim());
                      if (grade == null) {
                        return 'رقم غير صالح';
                      }
                      if (grade < 0) {
                        return 'لا يمكن أن تكون سالبة';
                      }
                      if (grade > widget.maxGrade) {
                        return 'أعلى من ${widget.maxGrade}';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: _showAssessmentSelectionDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: evalBoxColor,
                    border: Border.all(color: evalBorderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(hasEvaluation ? Icons.check_circle : Icons.rate_review, color: Colors.black54, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "تقييم جوانب القصور",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      if (hasEvaluation) ...[
                        const SizedBox(height: 6),
                        Text(
                          "${_selectedWeaknesses.length} نقاط محددة${_severityLevel != null ? ' - $_severityLevel' : ''}",
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, right: 8.0, left: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
              ),
              if (widget.currentGrade != null)
                TextButton(
                  onPressed: _isSaving ? null : _handleDelete,
                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              OutlinedButton(
                onPressed: _isSaving ? null : _handleSaveAbsent,
                child: const Text('غائب'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blueGrey),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _handleConfirm,
                child: const Text('تأكيد'),
              ),
            ],
          ),
        )
      ],
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}

extension on Sheet {
  void setColAutoFit(int columnIndex) {
  }
}