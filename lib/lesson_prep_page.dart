import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'lesson_prep_data.dart';

// ===========================================================================
// 1. صفحة استعراض ومتابعة جدول تحضير المعلمين (خاصة بالمعلم ومتابعة الإدارة)
// ===========================================================================
class LessonPrepSchedulePage extends StatefulWidget {
  final Map<String, dynamic>? teacherScheduleData;

  const LessonPrepSchedulePage({super.key, this.teacherScheduleData});

  @override
  State<LessonPrepSchedulePage> createState() => _LessonPrepSchedulePageState();
}

class _LessonPrepSchedulePageState extends State<LessonPrepSchedulePage> {
  int _selectedWeek = 1;
  final DateTime _firstWeekStart = DateTime(2026, 8, 30);

  final List<String> _daysOrder = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
  final Map<String, int> _dayIndexMap = {
    'الأحد': 0, 'الإثنين': 1, 'الثلاثاء': 2, 'الأربعاء': 3, 'الخميس': 4,
  };

  final String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isAdmin = false;

  String _selectedTeacherId = '';
  String _selectedTeacherName = '';
  Map<String, dynamic> _currentSchedule = {};

  List<Map<String, dynamic>> _teachersList = [];
  bool _isLoadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _selectedTeacherId = currentAuthUid;
    _checkAdminAndLoadTeachers();
  }

  Future<void> _checkAdminAndLoadTeachers() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentAuthUid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        _isAdmin = data['profession'] == 'admin';
        _selectedTeacherName = data['name'] ?? 'المعلم';
      }

      if (_isAdmin) {
        final teachersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('profession', isNotEqualTo: 'admin')
            .get();

        List<Map<String, dynamic>> temp = [];
        for (var doc in teachersSnap.docs) {
          final td = doc.data();
          temp.add({'id': doc.id, 'name': td['name'] ?? 'معلم'});
        }

        if (mounted) {
          setState(() {
            _teachersList = temp;
            if (temp.isNotEmpty) {
              _selectedTeacherId = temp.first['id'];
              _selectedTeacherName = temp.first['name'];
            }
            _isLoadingTeachers = false;
          });
          _fetchSelectedTeacherSchedule();
        }
      } else {
        if (widget.teacherScheduleData != null) {
          setState(() {
            _currentSchedule = widget.teacherScheduleData!['phase2Data'] ?? {};
            _isLoadingTeachers = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _fetchSelectedTeacherSchedule() async {
    if (_selectedTeacherId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('teacher_schedules').doc(_selectedTeacherId).get();
      if (doc.exists && doc.data() != null) {
        setState(() => _currentSchedule = doc.data()!['phase2Data'] ?? {});
      } else {
        setState(() => _currentSchedule = {});
      }
    } catch (e) {
      setState(() => _currentSchedule = {});
    }
  }

  DateTime _calculateLessonDate(String dayName, int weekNumber) {
    int dayOffset = _dayIndexMap[dayName] ?? 0;
    return _firstWeekStart.add(Duration(days: ((weekNumber - 1) * 7) + dayOffset));
  }

  Future<void> _approveInitiative(String docId, List<OperationalTeacherItem> executors, Map<String, bool> approvals) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('school_operational_plan_1448').doc(docId);
      final updatedApprovals = Map<String, bool>.from(approvals);
      updatedApprovals[currentAuthUid] = true;

      final updatedExecutors = executors.map((e) {
        if (e.id == currentAuthUid) {
          return OperationalTeacherItem(id: e.id, name: e.name, isCustom: e.isCustom, hasApproved: true);
        }
        return e;
      }).toList();

      await docRef.update({
        'collaboratorApprovals': updatedApprovals,
        'executors': updatedExecutors.map((e) => e.toMap()).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة على التعاون في المبادرة بنجاح!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الموافقة: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'متابعة تحضير المعلمين' : 'تحضيري - جدول الحصص المعتمد', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        bottom: _isAdmin && !_isLoadingTeachers
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.teal.shade800,
            child: DropdownButtonFormField<String>(
              value: _selectedTeacherId.isNotEmpty ? _selectedTeacherId : null,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _teachersList.map((t) => DropdownMenuItem<String>(
                value: t['id'],
                child: Text('المعلم: ${t['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTeacherId = val;
                    _selectedTeacherName = _teachersList.firstWhere((e) => e['id'] == val)['name'];
                  });
                  _fetchSelectedTeacherSchedule();
                }
              },
            ),
          ),
        )
            : null,
      ),
      body: _isLoadingTeachers
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFF00796B)),
                const SizedBox(width: 8),
                const Text('اختر الأسبوع الدراسي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedWeek,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: List.generate(50, (index) {
                      int w = index + 1;
                      DateTime weekStart = _firstWeekStart.add(Duration(days: (w - 1) * 7));
                      String dateStr = intl.DateFormat('yyyy/MM/dd').format(weekStart);
                      return DropdownMenuItem<int>(
                        value: w,
                        child: Text('الأسبوع $w (يبدأ: $dateStr)', style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWeek = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lesson_preparations')
                    .where('teacherId', isEqualTo: _selectedTeacherId)
                    .where('weekNumber', isEqualTo: _selectedWeek)
                    .snapshots(),
                builder: (context, prepSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('classroom_visits')
                          .where('teacherId', isEqualTo: _selectedTeacherId)
                          .where('weekNumber', isEqualTo: _selectedWeek)
                          .snapshots(),
                      builder: (context, visitSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('school_operational_plan_1448')
                                .where('executorsIds', arrayContains: _selectedTeacherId)
                                .snapshots(),
                            builder: (context, planSnapshot) {

                              Map<String, Map<String, dynamic>> preparedLessons = {};
                              if (prepSnapshot.hasData) {
                                for (var doc in prepSnapshot.data!.docs) {
                                  preparedLessons[doc.id] = doc.data() as Map<String, dynamic>;
                                }
                              }

                              Set<String> classroomVisits = {};
                              if (visitSnapshot.hasData) {
                                for (var doc in visitSnapshot.data!.docs) {
                                  classroomVisits.add(doc.id);
                                }
                              }

                              List<OperationalPlanEntry> teacherPlans = [];
                              if (planSnapshot.hasData) {
                                teacherPlans = planSnapshot.data!.docs.map((doc) =>
                                    OperationalPlanEntry.fromMap(doc.id, doc.data() as Map<String, dynamic>)
                                ).toList();
                              }

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(12),
                                itemCount: _daysOrder.length,
                                itemBuilder: (context, dIndex) {
                                  String dayName = _daysOrder[dIndex];
                                  DateTime lessonDate = _calculateLessonDate(dayName, _selectedWeek);
                                  DateTime lessonDateOnly = DateTime(lessonDate.year, lessonDate.month, lessonDate.day);
                                  String formattedDate = intl.DateFormat('yyyy/MM/dd').format(lessonDate);
                                  String dateStrForId = intl.DateFormat('yyyyMMdd').format(lessonDate);
                                  List periods = _currentSchedule[dayName] as List? ?? [];

                                  return Container(
                                    width: 290,
                                    margin: const EdgeInsets.only(left: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.teal.shade200, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00796B),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                                child: Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: periods.isNotEmpty ? periods.length : 7,
                                            itemBuilder: (context, pIndex) {
                                              Map<String, dynamic> slot = (pIndex < periods.length)
                                                  ? Map<String, dynamic>.from(periods[pIndex] as Map? ?? {})
                                                  : {'type': 'فارغ'};

                                              bool isClass = slot['type'] == 'حصة';
                                              String subject = slot['subject'] ?? '';
                                              String grade = slot['grade'] ?? '';
                                              String className = slot['class'] ?? '';

                                              String prepDocId = '${_selectedTeacherId}_W${_selectedWeek}_${dateStrForId}_P${pIndex + 1}';

                                              bool hasVisit = classroomVisits.contains(prepDocId);
                                              bool isPrepared = preparedLessons.containsKey(prepDocId);
                                              bool isLatePrep = isPrepared ? (preparedLessons[prepDocId]!['isLatePrep'] ?? false) : false;
                                              bool isPast = lessonDateOnly.isBefore(today);
                                              bool isMoreThan3Weeks = lessonDateOnly.difference(today).inDays > 21;

                                              String statusText = '';
                                              Color statusColor = Colors.transparent;
                                              IconData statusIcon = Icons.info;

                                              if (isClass) {
                                                if (isPrepared) {
                                                  if (isLatePrep) {
                                                    statusText = 'مُحَضَّرة (متأخر)';
                                                    statusColor = Colors.orange.shade700;
                                                    statusIcon = Icons.warning_amber_rounded;
                                                  } else {
                                                    statusText = 'مُحَضَّرة';
                                                    statusColor = Colors.green.shade700;
                                                    statusIcon = Icons.check_circle;
                                                  }
                                                } else if (isPast) {
                                                  statusText = 'فاتت ولم تُحضر';
                                                  statusColor = Colors.red.shade700;
                                                  statusIcon = Icons.cancel;
                                                } else {
                                                  statusText = 'بانتظار التحضير';
                                                  statusColor = Colors.grey.shade600;
                                                  statusIcon = Icons.hourglass_empty;
                                                }
                                              }

                                              List<OperationalPlanEntry> periodPlans = teacherPlans.where((plan) {
                                                bool matchesWeek = plan.isContinuousUntilYearEnd;
                                                if (!matchesWeek) {
                                                  if (plan.dateSelectionMode == 'weeks') {
                                                    int sW = plan.startWeek ?? plan.executionWeek ?? 1;
                                                    int eW = plan.endWeek ?? sW;
                                                    matchesWeek = _selectedWeek >= sW && _selectedWeek <= eW;
                                                  } else {
                                                    matchesWeek = plan.executionWeek == _selectedWeek;
                                                  }
                                                }
                                                bool matchesDay = plan.executionDays.contains(dayName);
                                                bool matchesPeriod = plan.executionPeriods.contains(pIndex + 1);

                                                return matchesWeek && matchesDay && matchesPeriod;
                                              }).toList();

                                              return InkWell(
                                                onTap: isClass
                                                    ? () {
                                                  if (isMoreThan3Weeks && _selectedTeacherId == currentAuthUid) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('تحذير: لا يمكنك التسابق في التحضير! الحد الأقصى المسموح به هو 3 أسابيع مقدماً فقط.'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => LessonDetailPrepFormPage(
                                                        weekNumber: _selectedWeek,
                                                        dayName: dayName,
                                                        lessonDate: lessonDate,
                                                        periodIndex: pIndex + 1,
                                                        subject: subject,
                                                        grade: grade,
                                                        className: className,
                                                        stage: slot['stage'] ?? 'المرحلة الابتدائية',
                                                        teacherId: _selectedTeacherId,
                                                        teacherName: _selectedTeacherName,
                                                        isViewerOnly: (_isAdmin && _selectedTeacherId != currentAuthUid),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                    : null,
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: isClass ? Colors.teal.shade50.withOpacity(0.3) : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: isClass ? (isPast && !isPrepared ? Colors.red.shade300 : Colors.teal.shade200) : Colors.grey.shade200,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 14,
                                                            backgroundColor: isClass ? const Color(0xFF00796B) : Colors.grey.shade400,
                                                            child: Text('${pIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  isClass ? subject : (slot['type'] ?? 'فارغ'),
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 14,
                                                                    color: isClass ? Colors.black87 : Colors.grey,
                                                                    fontFamily: 'Cairo',
                                                                  ),
                                                                ),
                                                                if (isClass) ...[
                                                                  if (grade.isNotEmpty || className.isNotEmpty)
                                                                    Text('$grade - $className', style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontFamily: 'Cairo')),
                                                                  const SizedBox(height: 8),
                                                                  Wrap(
                                                                    spacing: 6,
                                                                    runSpacing: 4,
                                                                    children: [
                                                                      if (hasVisit)
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.yellow.shade600,
                                                                            borderRadius: BorderRadius.circular(6),
                                                                          ),
                                                                          child: const Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                              Icon(Icons.visibility, size: 12, color: Colors.black87),
                                                                              SizedBox(width: 4),
                                                                              Text('زيارة صفية', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87, fontFamily: 'Cairo')),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                                        decoration: BoxDecoration(
                                                                          color: statusColor.withOpacity(0.1),
                                                                          border: Border.all(color: statusColor, width: 1.5),
                                                                          borderRadius: BorderRadius.circular(6),
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            Icon(statusIcon, size: 12, color: statusColor),
                                                                            const SizedBox(width: 4),
                                                                            Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, fontFamily: 'Cairo')),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          if (isClass)
                                                            Icon(
                                                                (_isAdmin && _selectedTeacherId != currentAuthUid) ? Icons.visibility : Icons.edit_note,
                                                                color: const Color(0xFF00796B),
                                                                size: 22
                                                            ),
                                                        ],
                                                      ),

                                                      if (periodPlans.isNotEmpty) ...[
                                                        const SizedBox(height: 8),
                                                        const Divider(height: 1, color: Colors.amber),
                                                        const SizedBox(height: 8),
                                                        ...periodPlans.map((plan) {
                                                          bool needsMyApproval = plan.collaboratorApprovals[currentAuthUid] == false;
                                                          return Container(
                                                            margin: const EdgeInsets.only(bottom: 6),
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.amber.shade50,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.amber.shade300),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                                                    const SizedBox(width: 4),
                                                                    Expanded(child: Text('مبادرة: ${plan.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'))),
                                                                  ],
                                                                ),
                                                                Text('الحالة: ${plan.status}', style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey)),
                                                                if (needsMyApproval && _selectedTeacherId == currentAuthUid)
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 6),
                                                                    child: SizedBox(
                                                                      width: double.infinity,
                                                                      child: ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: Colors.green,
                                                                          foregroundColor: Colors.white,
                                                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                                                          minimumSize: const Size(0, 30),
                                                                        ),
                                                                        onPressed: () => _approveInitiative(plan.id!, plan.executors, plan.collaboratorApprovals),
                                                                        child: const Text('موافقة على التعاون', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                                                      ),
                                                                    ),
                                                                  )
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ]
                                                    ],
                                                  ),
                                                ),
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
                        );
                      }
                  );
                }
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ===========================================================================
// 2. نموذج تحضير درس المعلم المفصل (LessonDetailPrepFormPage)
// ===========================================================================
class LessonDetailPrepFormPage extends StatefulWidget {
  final int weekNumber;
  final String dayName;
  final DateTime lessonDate;
  final int periodIndex;
  final String subject;
  final String grade;
  final String className;
  final String stage;
  final String teacherId;
  final String teacherName;
  final bool isViewerOnly;

  const LessonDetailPrepFormPage({
    super.key,
    required this.weekNumber,
    required this.dayName,
    required this.lessonDate,
    required this.periodIndex,
    required this.subject,
    required this.grade,
    required this.className,
    required this.stage,
    required this.teacherId,
    required this.teacherName,
    required this.isViewerOnly,
  });

  @override
  State<LessonDetailPrepFormPage> createState() => _LessonDetailPrepFormPageState();
}

class _LessonDetailPrepFormPageState extends State<LessonDetailPrepFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _lessonTitleCtrl = TextEditingController();
  final List<String> _selectedOutcomes = [];
  final TextEditingController _customOutcomeCtrl = TextEditingController();

  final List<String> _selectedValues = [];
  final TextEditingController _customValueCtrl = TextEditingController();

  final List<String> _selectedStrategies = [];
  final TextEditingController _customStrategyCtrl = TextEditingController();

  final List<String> _selectedGifted = [];
  final TextEditingController _customGiftedCtrl = TextEditingController();

  final List<String> _selectedPractical = [];
  final TextEditingController _customPracticalCtrl = TextEditingController();

  final List<TextEditingController> _digitalLinkControllers = [];
  final List<String> _specializedSkills = [];
  final TextEditingController _skillInputCtrl = TextEditingController();

  final TextEditingController _hwPageCtrl = TextEditingController();
  final TextEditingController _hwTitleCtrl = TextEditingController();
  final TextEditingController _hwTextCtrl = TextEditingController();

  int _timeExplanation = 20;
  int _timeOutcomes = 5;
  int _timeStrategies = 10;
  int _timeEvaluation = 5;
  int _timeValues = 5;

  int get _totalAssignedTime =>
      _timeExplanation + _timeOutcomes + _timeStrategies + _timeEvaluation + _timeValues;

  String get _prepDocId {
    String dateStr = intl.DateFormat('yyyyMMdd').format(widget.lessonDate);
    return '${widget.teacherId}_W${widget.weekNumber}_${dateStr}_P${widget.periodIndex}';
  }

  @override
  void initState() {
    super.initState();
    _loadExistingPrep();
  }

  @override
  void dispose() {
    _lessonTitleCtrl.dispose();
    _customOutcomeCtrl.dispose();
    _customValueCtrl.dispose();
    _customStrategyCtrl.dispose();
    _customGiftedCtrl.dispose();
    _customPracticalCtrl.dispose();
    for (var c in _digitalLinkControllers) {
      c.dispose();
    }
    _skillInputCtrl.dispose();
    _hwPageCtrl.dispose();
    _hwTitleCtrl.dispose();
    _hwTextCtrl.dispose();
    super.dispose();
  }

  List<String> _getFilteredList(Map<String, List<String>> sourceMap) {
    List<String> combinedList = [];
    if (sourceMap.containsKey('عام')) combinedList.addAll(sourceMap['عام']!);

    bool isStemTarget = ['علوم', 'رياضيات', 'روبوت', 'رقمية'].contains(widget.subject);
    if (isStemTarget && sourceMap.containsKey('STEM')) combinedList.addAll(sourceMap['STEM']!);

    if (sourceMap.containsKey(widget.subject)) {
      combinedList.addAll(sourceMap[widget.subject]!);
    } else {
      if (['قرآن', 'تجويد', 'توحيد', 'فقه', 'حديث', 'تفسير'].contains(widget.subject)) {
        if (sourceMap.containsKey('إسلاميات')) combinedList.addAll(sourceMap['إسلاميات']!);
      }
    }
    return combinedList;
  }

  Future<void> _loadExistingPrep() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lesson_preparations')
          .doc(_prepDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _lessonTitleCtrl.text = data['lessonTitle'] ?? '';

        if (data['outcomes'] != null) _selectedOutcomes.addAll(List<String>.from(data['outcomes']));
        if (data['values'] != null) _selectedValues.addAll(List<String>.from(data['values']));
        if (data['strategies'] != null) _selectedStrategies.addAll(List<String>.from(data['strategies']));
        if (data['gifted'] != null) _selectedGifted.addAll(List<String>.from(data['gifted']));
        if (data['practical'] != null) _selectedPractical.addAll(List<String>.from(data['practical']));
        if (data['specializedSkills'] != null) _specializedSkills.addAll(List<String>.from(data['specializedSkills']));

        if (data['digitalLinks'] != null) {
          List<dynamic> links = data['digitalLinks'];
          for (var l in links) {
            _digitalLinkControllers.add(TextEditingController(text: l.toString()));
          }
        }

        final hw = data['homework'] as Map<String, dynamic>?;
        if (hw != null) {
          _hwPageCtrl.text = hw['page'] ?? '';
          _hwTitleCtrl.text = hw['title'] ?? '';
          _hwTextCtrl.text = hw['text'] ?? '';
        }

        final timeMap = data['timeDistribution'] as Map<String, dynamic>?;
        if (timeMap != null) {
          _timeExplanation = timeMap['explanation'] ?? 20;
          _timeOutcomes = timeMap['outcomes'] ?? 5;
          _timeStrategies = timeMap['strategies'] ?? 10;
          _timeEvaluation = timeMap['evaluation'] ?? 5;
          _timeValues = timeMap['values'] ?? 5;
        }
      }
    } catch (e) {
      debugPrint("Error loading preparation: $e");
    } finally {
      if (_digitalLinkControllers.isEmpty) {
        _digitalLinkControllers.add(TextEditingController());
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreparation() async {
    if (widget.isViewerOnly) return;
    if (!_formKey.currentState!.validate()) return;

    if (_lessonTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال عنوان الدرس'), backgroundColor: Colors.red));
      return;
    }

    if (_totalAssignedTime != 45) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تنبيه: يجب أن يكون مجموع الدقائق 45 دقيقة تماماً (المجموع الحالي: $_totalAssignedTime د).'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<String> linksToSave = _digitalLinkControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final DateTime lessonDateOnly = DateTime(widget.lessonDate.year, widget.lessonDate.month, widget.lessonDate.day);
      bool isLatePrep = lessonDateOnly.isBefore(today);

      final prepData = {
        'docId': _prepDocId,
        'teacherId': widget.teacherId,
        'teacherName': widget.teacherName,
        'weekNumber': widget.weekNumber,
        'dayName': widget.dayName,
        'lessonDate': intl.DateFormat('yyyy/MM/dd').format(widget.lessonDate),
        'periodIndex': widget.periodIndex,
        'stage': widget.stage,
        'grade': widget.grade,
        'className': widget.className,
        'subject': widget.subject,
        'lessonTitle': _lessonTitleCtrl.text.trim(),
        'outcomes': _selectedOutcomes,
        'values': _selectedValues,
        'strategies': _selectedStrategies,
        'gifted': _selectedGifted,
        'practical': _selectedPractical,
        'specializedSkills': _specializedSkills,
        'digitalLinks': linksToSave,
        'isLatePrep': isLatePrep,
        'homework': {
          'page': _hwPageCtrl.text.trim(),
          'title': _hwTitleCtrl.text.trim(),
          'text': _hwTextCtrl.text.trim(),
        },
        'timeDistribution': {
          'explanation': _timeExplanation,
          'outcomes': _timeOutcomes,
          'strategies': _timeStrategies,
          'evaluation': _timeEvaluation,
          'values': _timeValues,
          'total': 45,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('lesson_preparations')
          .doc(_prepDocId)
          .set(prepData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ تحضير الدرس بنجاح سحابياً! ✅'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openMultiSelectDialog({
    required String title,
    required List<String> sourceList,
    required List<String> targetList,
    required TextEditingController customCtrl,
  }) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filteredItems = sourceList.where((item) {
              if (searchQuery.isEmpty) return true;
              return item.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00796B), fontFamily: 'Cairo')),
              content: SizedBox(
                width: double.maxFinite,
                height: 550,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'بحث سريع في البنك...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (!widget.isViewerOnly)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customCtrl,
                              decoration: const InputDecoration(
                                labelText: 'إضافة بند يدوي مخصص...',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            onPressed: () {
                              if (customCtrl.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  targetList.add(customCtrl.text.trim());
                                  customCtrl.clear();
                                });
                                setState(() {});
                              }
                            },
                            child: const Text('إضافة'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.library_books, color: Colors.blue.shade700, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('معروض حالياً: ${filteredItems.length} من أصل ${sourceList.length} بند متخصص ومدمج.',
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, idx) {
                          final item = filteredItems[idx];
                          final isSelected = targetList.contains(item);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(item, style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'Cairo')),
                            value: isSelected,
                            activeColor: Colors.teal,
                            onChanged: widget.isViewerOnly ? null : (val) {
                              setDialogState(() {
                                if (val == true) {
                                  targetList.add(item);
                                } else {
                                  targetList.remove(item);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
                if (!widget.isViewerOnly)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
                    child: const Text('تم واعتماد'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = intl.DateFormat('yyyy/MM/dd').format(widget.lessonDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isViewerOnly ? 'عرض: ${widget.subject}' : 'تحضير: ${widget.subject} (${widget.grade} - ${widget.className})', style: const TextStyle(fontSize: 15, fontFamily: 'Cairo')),
        backgroundColor: widget.isViewerOnly ? Colors.blueGrey : const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isViewerOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                  child: const Text('أنت في وضع المشاهدة فقط (صلاحيات المدير)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontFamily: 'Cairo')),
                ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.teal.shade200)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الأسبوع: ${widget.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                    Text('اليوم: ${widget.dayName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                    Text('التاريخ: $formattedDate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00796B), fontFamily: 'Cairo')),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTimeDistributionCard(),
              const SizedBox(height: 20),

              const Text('عنوان الدرس *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lessonTitleCtrl,
                readOnly: widget.isViewerOnly,
                decoration: const InputDecoration(
                  hintText: 'اكتب عنوان الدرس هنا...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title_rounded, color: Colors.teal),
                ),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب إدخال عنوان الدرس' : null,
              ),
              const SizedBox(height: 20),

              _buildSectionPicker(
                title: 'نواتج التعلم المستهدفة',
                icon: Icons.track_changes_rounded,
                color: Colors.blue.shade700,
                selectedItems: _selectedOutcomes,
                onOpen: () => _openMultiSelectDialog(
                  title: 'نواتج التعلم (عام + ${widget.subject} + STEM)',
                  sourceList: _getFilteredList(LessonPrepData.learningOutcomesMap),
                  targetList: _selectedOutcomes,
                  customCtrl: _customOutcomeCtrl,
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionPicker(
                title: 'الربط بالقيم والهوية الوطنية السعودية',
                icon: Icons.flag_rounded,
                color: Colors.green.shade800,
                selectedItems: _selectedValues,
                onOpen: () => _openMultiSelectDialog(
                  title: 'القيم والهوية الوطنية',
                  sourceList: _getFilteredList(LessonPrepData.valuesAndIdentityMap),
                  targetList: _selectedValues,
                  customCtrl: _customValueCtrl,
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionPicker(
                title: 'استراتيجيات التدريس والتعلم النشط',
                icon: Icons.psychology_rounded,
                color: Colors.orange.shade800,
                selectedItems: _selectedStrategies,
                onOpen: () => _openMultiSelectDialog(
                  title: 'استراتيجيات التدريس وربط المواد (STEM)',
                  sourceList: _getFilteredList(LessonPrepData.strategiesMap),
                  targetList: _selectedStrategies,
                  customCtrl: _customStrategyCtrl,
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionPicker(
                title: 'أنشطة رعاية الموهوبين والفائقين',
                icon: Icons.star_rounded,
                color: Colors.purple.shade700,
                selectedItems: _selectedGifted,
                onOpen: () => _openMultiSelectDialog(
                  title: 'أنشطة الموهوبين (عام + ${widget.subject})',
                  sourceList: _getFilteredList(LessonPrepData.giftedActivitiesMap),
                  targetList: _selectedGifted,
                  customCtrl: _customGiftedCtrl,
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionPicker(
                title: 'تطبيقات عملية مرتبطة بالحياة',
                icon: Icons.public_rounded,
                color: Colors.teal.shade800,
                selectedItems: _selectedPractical,
                onOpen: () => _openMultiSelectDialog(
                  title: 'تطبيقات حياتية (عام + ${widget.subject})',
                  sourceList: _getFilteredList(LessonPrepData.practicalApplicationsMap),
                  targetList: _selectedPractical,
                  customCtrl: _customPracticalCtrl,
                ),
              ),
              const SizedBox(height: 20),

              _buildSpecializedSkillsSection(),
              const SizedBox(height: 20),

              _buildDigitalLinksSection(),
              const SizedBox(height: 20),

              _buildHomeworkSection(),
              const SizedBox(height: 35),

              if (!widget.isViewerOnly)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePreparation,
                    icon: const Icon(Icons.save_rounded),
                    label: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('اعتماد وحفظ التحضير سحابياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDistributionCard() {
    bool isExact45 = _totalAssignedTime == 45;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.pink.shade50.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.pinkAccent),
                    SizedBox(width: 8),
                    Text('توزيع وقت الحصة (45 دقيقة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isExact45 ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text('المجموع: $_totalAssignedTime / 45 د', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimeSlider('الشرح والعرض:', _timeExplanation, (val) => setState(() => _timeExplanation = val)),
            _buildTimeSlider('نواتج ومناقشة:', _timeOutcomes, (val) => setState(() => _timeOutcomes = val)),
            _buildTimeSlider('أنشطة واستراتيجيات:', _timeStrategies, (val) => setState(() => _timeStrategies = val)),
            _buildTimeSlider('قيم وتطبيقات:', _timeValues, (val) => setState(() => _timeValues = val)),
            _buildTimeSlider('تقويم وواجبات:', _timeEvaluation, (val) => setState(() => _timeEvaluation = val)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlider(String label, int currentValue, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo'))),
        Expanded(
          child: Slider(
            value: currentValue.toDouble(), min: 0, max: 45, divisions: 45,
            label: '$currentValue د', activeColor: const Color(0xFF00796B),
            onChanged: widget.isViewerOnly ? null : (val) => onChanged(val.round()),
          ),
        ),
        Container(width: 40, alignment: Alignment.center, child: Text('$currentValue د', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'))),
      ],
    );
  }

  Widget _buildSectionPicker({required String title, required IconData icon, required Color color, required List<String> selectedItems, required VoidCallback onOpen}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color, fontFamily: 'Cairo')),
                  ],
                ),
                if (!widget.isViewerOnly)
                  ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('اختيار/كتابة', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedItems.isEmpty)
              const Text('لم يتم إدراج بنود بعد.', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'))
            else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: selectedItems.map((item) {
                  return Chip(
                    backgroundColor: color.withOpacity(0.08),
                    label: Text(item, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    deleteIcon: widget.isViewerOnly ? null : const Icon(Icons.close, size: 14),
                    onDeleted: widget.isViewerOnly ? null : () => setState(() => selectedItems.remove(item)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializedSkillsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.indigo),
                SizedBox(width: 8),
                Text('مهارات تخصصية دقيقة للمادة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo, fontFamily: 'Cairo')),
              ],
            ),
            if (!widget.isViewerOnly) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillInputCtrl,
                      decoration: const InputDecoration(hintText: 'اكتب مهارة تخصصية...', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: () {
                      if (_skillInputCtrl.text.trim().isNotEmpty) {
                        setState(() { _specializedSkills.add(_skillInputCtrl.text.trim()); _skillInputCtrl.clear(); });
                      }
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (_specializedSkills.isNotEmpty)
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _specializedSkills.map((s) {
                  return Chip(
                    backgroundColor: Colors.indigo.shade50,
                    label: Text(s, style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    deleteIcon: widget.isViewerOnly ? null : const Icon(Icons.close, size: 14),
                    onDeleted: widget.isViewerOnly ? null : () => setState(() => _specializedSkills.remove(s)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalLinksSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.link_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('المصادر الرقمية (10 روابط)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue, fontFamily: 'Cairo')),
                  ],
                ),
                if (!widget.isViewerOnly && _digitalLinkControllers.length < 10)
                  TextButton.icon(
                    onPressed: () { setState(() => _digitalLinkControllers.add(TextEditingController())); },
                    icon: const Icon(Icons.add, size: 16), label: const Text('إضافة رابط'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._digitalLinkControllers.asMap().entries.map((entry) {
              int idx = entry.key; TextEditingController ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text('${idx + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: ctrl, readOnly: widget.isViewerOnly, keyboardType: TextInputType.url, decoration: InputDecoration(hintText: 'https://...', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
                    if (!widget.isViewerOnly && _digitalLinkControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () { setState(() { ctrl.dispose(); _digitalLinkControllers.removeAt(idx); }); },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text('التقويم والتغذية الراجعة (الواجبات)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 1, child: TextField(controller: _hwPageCtrl, readOnly: widget.isViewerOnly, decoration: const InputDecoration(labelText: 'الصفحة', hintText: 'مثال: ص 45', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: TextField(controller: _hwTitleCtrl, readOnly: widget.isViewerOnly, decoration: const InputDecoration(labelText: 'عنوان الواجب', hintText: 'مثال: حل تدريبات الدرس الأول', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _hwTextCtrl, readOnly: widget.isViewerOnly, maxLines: 3, decoration: const InputDecoration(labelText: 'تفاصيل الواجب', hintText: 'اكتب نص الواجب والتعليمات...', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}