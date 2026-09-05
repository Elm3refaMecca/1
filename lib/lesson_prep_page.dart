import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'lesson_prep_data.dart';

// ===========================================================================
// 1. صفحة استعراض ومتابعة جدول تحضير المعلمين
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
        } else {
          _fetchSelectedTeacherSchedule();
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

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isAdmin ? 'متابعة خطط وتحضير المعلمين' : 'تحضير الدروس والجدول المدرسي',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: _isAdmin && !_isLoadingTeachers
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F172A),
            child: DropdownButtonFormField<String>(
              value: _selectedTeacherId.isNotEmpty ? _selectedTeacherId : null,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _teachersList.map((t) => DropdownMenuItem<String>(
                value: t['id'],
                child: Text('المعلم: ${t['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Cairo')),
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
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF475569)),
                const SizedBox(width: 10),
                const Text('الأسبوع الدراسي:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155), fontFamily: 'Cairo')),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedWeek,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: List.generate(50, (index) {
                      int w = index + 1;
                      DateTime weekStart = _firstWeekStart.add(Duration(days: (w - 1) * 7));
                      String dateStr = intl.DateFormat('yyyy/MM/dd').format(weekStart);
                      return DropdownMenuItem<int>(
                        value: w,
                        child: Text('الأسبوع $w (يبدأ: $dateStr)', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF1E293B))),
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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF334155),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                                              Text(formattedDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo')),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
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

                                              String statusText = '';
                                              Color badgeBg = const Color(0xFFF1F5F9);
                                              Color badgeText = const Color(0xFF64748B);

                                              if (isClass) {
                                                if (isPrepared) {
                                                  if (isLatePrep) {
                                                    statusText = 'مُحضر (متأخر)';
                                                    badgeBg = const Color(0xFFFEF3C7);
                                                    badgeText = const Color(0xFF92400E);
                                                  } else {
                                                    statusText = 'مُحضر';
                                                    badgeBg = const Color(0xFFDCFCE7);
                                                    badgeText = const Color(0xFF166534);
                                                  }
                                                } else if (isPast) {
                                                  statusText = 'غير محضر';
                                                  badgeBg = const Color(0xFFFEE2E2);
                                                  badgeText = const Color(0xFF991B1B);
                                                } else {
                                                  statusText = 'بانتظار التحضير';
                                                  badgeBg = const Color(0xFFF1F5F9);
                                                  badgeText = const Color(0xFF64748B);
                                                }
                                              }

                                              return InkWell(
                                                onTap: isClass
                                                    ? () {
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
                                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: isClass ? Colors.white : const Color(0xFFF8FAFC),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: isClass ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        alignment: Alignment.center,
                                                        decoration: BoxDecoration(
                                                          color: isClass ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text('${pIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              isClass ? subject : (slot['type'] ?? 'فارغ'),
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 13,
                                                                color: isClass ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                                                fontFamily: 'Cairo',
                                                              ),
                                                            ),
                                                            if (isClass) ...[
                                                              if (grade.isNotEmpty || className.isNotEmpty)
                                                                Text('$grade - $className', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'Cairo')),
                                                              const SizedBox(height: 4),
                                                              Wrap(
                                                                spacing: 4,
                                                                children: [
                                                                  if (hasVisit)
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(0xFFFEF08A),
                                                                        borderRadius: BorderRadius.circular(4),
                                                                      ),
                                                                      child: const Text('زيارة صفية', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF854D0E), fontFamily: 'Cairo')),
                                                                    ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                    decoration: BoxDecoration(
                                                                      color: badgeBg,
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                    child: Text(statusText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: badgeText, fontFamily: 'Cairo')),
                                                                  ),
                                                                ],
                                                              )
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      if (isClass)
                                                        const Icon(Icons.chevron_left, size: 18, color: Color(0xFF94A3B8)),
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ===========================================================================
// 2. نماذج البيانات الدقيقة للتحضير وإدارة الوقت
// ===========================================================================

class _TimedItemModel {
  String text;
  int triggerOffset;

  _TimedItemModel({required this.text, this.triggerOffset = 0});

  Map<String, dynamic> toMap() => {
    'text': text,
    'triggerOffset': triggerOffset,
  };

  factory _TimedItemModel.fromMap(Map<String, dynamic> map) => _TimedItemModel(
    text: map['text'] ?? '',
    triggerOffset: map['triggerOffset'] ?? 0,
  );
}

class _DomainDigitalLink {
  TextEditingController titleCtrl;
  TextEditingController urlCtrl;
  int triggerOffset;

  _DomainDigitalLink({required this.titleCtrl, required this.urlCtrl, this.triggerOffset = 0});

  Map<String, dynamic> toMap() => {
    'title': titleCtrl.text.trim(),
    'url': urlCtrl.text.trim(),
    'triggerOffset': triggerOffset,
  };

  factory _DomainDigitalLink.fromMap(Map<String, dynamic> map) {
    int offset = map['triggerOffset'] ?? 0;
    return _DomainDigitalLink(
      titleCtrl: TextEditingController(text: map['title'] ?? ''),
      urlCtrl: TextEditingController(text: map['url'] ?? ''),
      triggerOffset: offset,
    );
  }
}

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
  final ScrollController _scrollController = ScrollController();

  // مفاتيح تركيز الحقول الإجبارية للانتقال التلقائي
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _introKey = GlobalKey();
  final GlobalKey _timeKey = GlobalKey();
  final GlobalKey _evalKey = GlobalKey();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _introFocusNode = FocusNode();
  final FocusNode _hwTitleFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;

  // خيار اعتماد التحضير للأسبوع كاملاً
  bool _applyToEntireWeek = false;

  final List<String> _daysOrder = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

  final TextEditingController _lessonTitleCtrl = TextEditingController();
  final TextEditingController _introQuestionCtrl = TextEditingController();

  final List<_TimedItemModel> _selectedOutcomes = [];
  final List<_TimedItemModel> _explanationHeadings = [];
  final List<_TimedItemModel> _selectedStrategies = [];
  final List<_TimedItemModel> _selectedGifted = [];
  final List<_TimedItemModel> _specializedSkills = [];
  final List<_TimedItemModel> _selectedPractical = [];
  final List<_TimedItemModel> _selectedValues = [];

  final TextEditingController _hwPageCtrl = TextEditingController();
  final TextEditingController _hwTitleCtrl = TextEditingController();
  final TextEditingController _hwTextCtrl = TextEditingController();

  // فترات الـ 45 دقيقة
  int _timeWarmupAndOutcomes = 5;
  int _timeExplanationAndTech = 20;
  int _timeActivitiesAndGifted = 10;
  int _timePracticalAndValues = 5;
  int _timeEvaluationAndFeedback = 5;

  int get _totalAssignedTime =>
      _timeWarmupAndOutcomes +
          _timeExplanationAndTech +
          _timeActivitiesAndGifted +
          _timePracticalAndValues +
          _timeEvaluationAndFeedback;

  final Map<String, List<_DomainDigitalLink>> _domainLinks = {
    'warmup': [],
    'explanation': [],
    'activities': [],
    'practical': [],
    'evaluation': [],
  };

  List<String> _mySavedTitles = [];
  final Map<String, List<String>> _myCustomItemsBank = {
    'outcomes': [],
    'headings': [],
    'values': [],
    'strategies': [],
    'gifted': [],
    'practical': [],
    'skills': [],
  };

  List<Map<String, dynamic>> _desktopSchedule = [];
  bool _isWinterTime = false;

  String get _prepDocId {
    String dateStr = intl.DateFormat('yyyyMMdd').format(widget.lessonDate);
    return '${widget.teacherId}_W${widget.weekNumber}_${dateStr}_P${widget.periodIndex}';
  }

  @override
  void initState() {
    super.initState();
    _loadDesktopSchedule();
    _loadTeacherCustomBank();
    _loadExistingPrep();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _introFocusNode.dispose();
    _hwTitleFocusNode.dispose();

    _lessonTitleCtrl.dispose();
    _introQuestionCtrl.dispose();
    _hwPageCtrl.dispose();
    _hwTitleCtrl.dispose();
    _hwTextCtrl.dispose();
    for (var list in _domainLinks.values) {
      for (var l in list) {
        l.titleCtrl.dispose();
        l.urlCtrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadDesktopSchedule() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('school_schedule').get();
      if (doc.exists && doc.data() != null) {
        bool isLower = ['الصف الأول', 'الصف الثاني', 'الصف الثالث'].contains(widget.grade);
        String key = isLower ? 'lower_primary' : 'upper_primary';
        if (doc.data()!.containsKey(key)) {
          _desktopSchedule = List<Map<String, dynamic>>.from(doc.data()![key]);
        }
      }
      final winterDoc = await FirebaseFirestore.instance.collection('settings').doc('time_config').get();
      if (winterDoc.exists) {
        _isWinterTime = winterDoc.data()?['is_winter'] ?? false;
      }
    } catch (_) {}
  }

  Future<void> _loadTeacherCustomBank() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teacher_custom_prep_bank')
          .doc(widget.teacherId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          String titleKey = 'savedTitles_${widget.subject}_${widget.grade}';
          _mySavedTitles = List<String>.from(data[titleKey] ?? []);

          _myCustomItemsBank['outcomes'] = List<String>.from(data['outcomes'] ?? []);
          _myCustomItemsBank['headings'] = List<String>.from(data['headings'] ?? []);
          _myCustomItemsBank['values'] = List<String>.from(data['values'] ?? []);
          _myCustomItemsBank['strategies'] = List<String>.from(data['strategies'] ?? []);
          _myCustomItemsBank['gifted'] = List<String>.from(data['gifted'] ?? []);
          _myCustomItemsBank['practical'] = List<String>.from(data['practical'] ?? []);
          _myCustomItemsBank['skills'] = List<String>.from(data['skills'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error loading teacher custom bank: $e");
    }
  }

  Future<void> _saveToCustomBank(String categoryKey, String newItem) async {
    if (newItem.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('teacher_custom_prep_bank')
          .doc(widget.teacherId)
          .set({
        categoryKey: FieldValue.arrayUnion([newItem.trim()]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _loadTeacherCustomBank();
    } catch (_) {}
  }

  List<String> _getFilteredList(Map<String, List<String>> sourceMap, String bankKey) {
    List<String> combinedList = [];

    if (_myCustomItemsBank.containsKey(bankKey) && _myCustomItemsBank[bankKey]!.isNotEmpty) {
      combinedList.addAll(_myCustomItemsBank[bankKey]!);
    }

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
    return combinedList.toSet().toList();
  }

  void _populateTimedList(List<dynamic>? source, List<_TimedItemModel> target) {
    target.clear();
    if (source != null) {
      for (var item in source) {
        if (item is Map) {
          target.add(_TimedItemModel.fromMap(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          target.add(_TimedItemModel(text: item));
        }
      }
    }
  }

  void _populateStateFromData(Map<String, dynamic> data) {
    _lessonTitleCtrl.text = data['lessonTitle'] ?? '';
    _introQuestionCtrl.text = data['introQuestion'] ?? '';

    _populateTimedList(data['outcomes'], _selectedOutcomes);
    _populateTimedList(data['explanationHeadings'], _explanationHeadings);
    _populateTimedList(data['values'], _selectedValues);
    _populateTimedList(data['strategies'], _selectedStrategies);
    _populateTimedList(data['gifted'], _selectedGifted);
    _populateTimedList(data['practical'], _selectedPractical);
    _populateTimedList(data['specializedSkills'], _specializedSkills);

    for (var list in _domainLinks.values) {
      for (var l in list) {
        l.titleCtrl.dispose();
        l.urlCtrl.dispose();
      }
      list.clear();
    }

    if (data['domainLinks'] != null) {
      Map<String, dynamic> dl = Map<String, dynamic>.from(data['domainLinks']);
      dl.forEach((key, val) {
        if (_domainLinks.containsKey(key) && val is List) {
          for (var item in val) {
            _domainLinks[key]!.add(_DomainDigitalLink.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      });
    }

    final hw = data['homework'] as Map<String, dynamic>?;
    if (hw != null) {
      _hwPageCtrl.text = hw['page'] ?? '';
      _hwTitleCtrl.text = hw['title'] ?? '';
      _hwTextCtrl.text = hw['text'] ?? '';
    }

    final timeMap = data['timeDistribution'] as Map<String, dynamic>?;
    if (timeMap != null) {
      _timeWarmupAndOutcomes = timeMap['warmupAndOutcomes'] ?? 5;
      _timeExplanationAndTech = timeMap['explanationAndTech'] ?? 20;
      _timeActivitiesAndGifted = timeMap['activitiesAndGifted'] ?? 10;
      _timePracticalAndValues = timeMap['practicalAndValues'] ?? 5;
      _timeEvaluationAndFeedback = timeMap['evaluationAndFeedback'] ?? 5;
    }
    setState(() {});
  }

  Future<void> _fetchAndApplyPrepByTitle(String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('lesson_preparations')
          .where('teacherId', isEqualTo: widget.teacherId)
          .where('subject', isEqualTo: widget.subject)
          .where('grade', isEqualTo: widget.grade)
          .where('lessonTitle', isEqualTo: cleanTitle)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final previousData = snap.docs.first.data();
        _populateStateFromData(previousData);
        _lessonTitleCtrl.text = cleanTitle;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم جلب محتوى "$cleanTitle" وتطبيقه. يمكنك التعديل عليه بحرية.',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: const Color(0xFF0F766E),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching prep by title: $e");
    }
  }

  Future<void> _loadExistingPrep() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lesson_preparations')
          .doc(_prepDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        _populateStateFromData(doc.data()!);
      }
    } catch (e) {
      debugPrint("Error loading preparation: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _timeToMins(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  String _formatMinsToTime(int totalMins) {
    int h = totalMins ~/ 60;
    int m = totalMins % 60;
    String period = h >= 12 ? 'م' : 'ص';
    int h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  Map<String, Map<String, dynamic>> _calculateAccurateDomainTimings() {
    int periodStartMins = (7 * 60) + ((widget.periodIndex - 1) * 45);
    int startOffset = _isWinterTime ? 15 : 0;

    if (_desktopSchedule.isNotEmpty) {
      int activeIndex = 0;
      for (var s in _desktopSchedule) {
        if (s['isBreak'] != true) {
          activeIndex++;
          if (activeIndex == widget.periodIndex) {
            periodStartMins = _timeToMins(s['start']) + startOffset;
            break;
          }
        }
      }
    }

    int warmupStart = periodStartMins;
    int warmupEnd = warmupStart + _timeWarmupAndOutcomes;

    int explanationStart = warmupEnd;
    int explanationEnd = explanationStart + _timeExplanationAndTech;

    int activitiesStart = explanationEnd;
    int activitiesEnd = activitiesStart + _timeActivitiesAndGifted;

    int practicalStart = activitiesEnd;
    int practicalEnd = practicalStart + _timePracticalAndValues;

    int evaluationStart = practicalEnd;
    int evaluationEnd = evaluationStart + _timeEvaluationAndFeedback;

    return {
      'warmup': {
        'title': '1. التهيئة والدافعية ونواتج التعلم',
        'duration': _timeWarmupAndOutcomes,
        'startMins': warmupStart,
        'endMins': warmupEnd,
        'startTimeStr': _formatMinsToTime(warmupStart),
        'endTimeStr': _formatMinsToTime(warmupEnd),
      },
      'explanation': {
        'title': '2. الشرح والعرض والاستراتيجيات',
        'duration': _timeExplanationAndTech,
        'startMins': explanationStart,
        'endMins': explanationEnd,
        'startTimeStr': _formatMinsToTime(explanationStart),
        'endTimeStr': _formatMinsToTime(explanationEnd),
      },
      'activities': {
        'title': '3. الأنشطة الطلابية ورعاية الموهوبين',
        'duration': _timeActivitiesAndGifted,
        'startMins': activitiesStart,
        'endMins': activitiesEnd,
        'startTimeStr': _formatMinsToTime(activitiesStart),
        'endTimeStr': _formatMinsToTime(activitiesEnd),
      },
      'practical': {
        'title': '4. التطبيقات الحياتية والربط بالقيم',
        'duration': _timePracticalAndValues,
        'startMins': practicalStart,
        'endMins': practicalEnd,
        'startTimeStr': _formatMinsToTime(practicalStart),
        'endTimeStr': _formatMinsToTime(practicalEnd),
      },
      'evaluation': {
        'title': '5. التقويم والتغذية الراجعة والواجبات',
        'duration': _timeEvaluationAndFeedback,
        'startMins': evaluationStart,
        'endMins': evaluationEnd,
        'startTimeStr': _formatMinsToTime(evaluationStart),
        'endTimeStr': _formatMinsToTime(evaluationEnd),
      },
    };
  }

  // انتقال وتمرير فوري للعنصر الإجباري الناقص
  void _scrollToMissingField(GlobalKey key, [FocusNode? focusNode]) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      if (focusNode != null) {
        focusNode.requestFocus();
      }
    }
  }

  // ✅ الفحص الدقيق والتحقق من البنود الإجبارية مع نقل المعلم فوراً إليها
  bool _validateRequiredFields() {
    if (_lessonTitleCtrl.text.trim().isEmpty) {
      _scrollToMissingField(_titleKey, _titleFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة عنوان الدرس أولاً (بند إجباري)', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return false;
    }

    if (_introQuestionCtrl.text.trim().isEmpty) {
      _scrollToMissingField(_introKey, _introFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال السؤال التمهيدي للدرس (بند إجباري)', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return false;
    }

    if (_totalAssignedTime != 45) {
      _scrollToMissingField(_timeKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يجب أن يكون مجموع دقائق الحصة 45 دقيقة تماماً (المجموع الحالي: $_totalAssignedTime د).', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
      return false;
    }

    if (_hwTitleCtrl.text.trim().isEmpty && _hwTextCtrl.text.trim().isEmpty) {
      _scrollToMissingField(_evalKey, _hwTitleFocusNode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل مهمة التقويم أو الواجب (بند إجباري)', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _savePreparation() async {
    if (widget.isViewerOnly) return;
    if (!_validateRequiredFields()) return;

    setState(() => _isSaving = true);

    try {
      final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final DateTime lessonDateOnly = DateTime(widget.lessonDate.year, widget.lessonDate.month, widget.lessonDate.day);
      bool isLatePrep = lessonDateOnly.isBefore(today);

      String titleKey = 'savedTitles_${widget.subject}_${widget.grade}';
      await _saveToCustomBank(titleKey, _lessonTitleCtrl.text.trim());

      final accurateTimings = _calculateAccurateDomainTimings();

      Map<String, List<Map<String, dynamic>>> domainLinksMap = {};
      List<Map<String, dynamic>> flatTimelineEvents = [];

      void addEvents(List<_TimedItemModel> items, String type, String domainKey) {
        var dInfo = accurateTimings[domainKey]!;
        for (var item in items) {
          int actualOffset = item.triggerOffset > dInfo['duration'] ? dInfo['duration'] : item.triggerOffset;
          int triggerMins = dInfo['startMins'] + actualOffset;
          flatTimelineEvents.add({
            'type': type,
            'title': item.text,
            'domainKey': domainKey,
            'domainTitle': dInfo['title'],
            'triggerOffset': actualOffset,
            'triggerMins': triggerMins,
            'triggerTimeStr': _formatMinsToTime(triggerMins),
            'periodIndex': widget.periodIndex,
          });
        }
      }

      addEvents(_selectedOutcomes, 'outcome', 'warmup');
      addEvents(_explanationHeadings, 'heading', 'explanation');
      addEvents(_specializedSkills, 'skill', 'explanation');
      addEvents(_selectedStrategies, 'strategy', 'explanation');
      addEvents(_selectedGifted, 'gifted', 'activities');
      addEvents(_selectedPractical, 'practical', 'practical');
      addEvents(_selectedValues, 'value', 'practical');

      _domainLinks.forEach((domainKey, links) {
        domainLinksMap[domainKey] = links
            .where((l) => l.urlCtrl.text.trim().isNotEmpty)
            .map((l) => l.toMap())
            .toList();

        for (var l in links) {
          if (l.urlCtrl.text.trim().isNotEmpty) {
            var dInfo = accurateTimings[domainKey]!;
            int actualOffset = l.triggerOffset > dInfo['duration'] ? dInfo['duration'] : l.triggerOffset;
            int triggerMins = dInfo['startMins'] + actualOffset;

            flatTimelineEvents.add({
              'type': 'link',
              'title': l.titleCtrl.text.trim().isNotEmpty ? l.titleCtrl.text.trim() : 'مصدر رقمي',
              'url': l.urlCtrl.text.trim(),
              'domainKey': domainKey,
              'domainTitle': dInfo['title'],
              'triggerOffset': actualOffset,
              'triggerMins': triggerMins,
              'triggerTimeStr': _formatMinsToTime(triggerMins),
              'periodIndex': widget.periodIndex,
            });
          }
        }
      });

      flatTimelineEvents.sort((a, b) => (a['triggerMins'] as int).compareTo(b['triggerMins'] as int));

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
        'introQuestion': _introQuestionCtrl.text.trim(),

        'outcomes': _selectedOutcomes.map((e) => e.toMap()).toList(),
        'explanationHeadings': _explanationHeadings.map((e) => e.toMap()).toList(),
        'values': _selectedValues.map((e) => e.toMap()).toList(),
        'strategies': _selectedStrategies.map((e) => e.toMap()).toList(),
        'gifted': _selectedGifted.map((e) => e.toMap()).toList(),
        'practical': _selectedPractical.map((e) => e.toMap()).toList(),
        'specializedSkills': _specializedSkills.map((e) => e.toMap()).toList(),
        'domainLinks': domainLinksMap,
        'timelineEvents': flatTimelineEvents,

        'isLatePrep': isLatePrep,
        'homework': {
          'page': _hwPageCtrl.text.trim(),
          'title': _hwTitleCtrl.text.trim(),
          'text': _hwTextCtrl.text.trim(),
        },
        'timeDistribution': {
          'warmupAndOutcomes': _timeWarmupAndOutcomes,
          'explanationAndTech': _timeExplanationAndTech,
          'activitiesAndGifted': _timeActivitiesAndGifted,
          'practicalAndValues': _timePracticalAndValues,
          'evaluationAndFeedback': _timeEvaluationAndFeedback,
          'total': 45,
          'timingsDetailed': accurateTimings,
        },
        'desktopSyncReady': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. حفظ الحصة الحالية دون التأثير على الحصص المحفوظة سابقاً
      await FirebaseFirestore.instance
          .collection('lesson_preparations')
          .doc(_prepDocId)
          .set(prepData, SetOptions(merge: true));

      // 2. إذا تم تفعيل "اعتمد الدرس للاسبوع كاملا"، تطبيق التحضير على باقي حصص وفصول المعلم لنفس المادة في نفس الأسبوع
      if (_applyToEntireWeek) {
        await _applyPrepToEntireWeek(prepData);
      }

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _applyToEntireWeek
                  ? 'تم اعتماد وحفظ التحضير لجميع حصص الأسبوع بنجاح.'
                  : 'تم حفظ تحضير الحصة بنجاح دون التأثير على الحصص الأخرى.',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _applyPrepToEntireWeek(Map<String, dynamic> basePrepData) async {
    try {
      final schedDoc = await FirebaseFirestore.instance.collection('teacher_schedules').doc(widget.teacherId).get();
      if (!schedDoc.exists || schedDoc.data() == null) return;

      final phase2 = schedDoc.data()?['phase2Data'] as Map<String, dynamic>?;
      if (phase2 == null) return;

      final batch = FirebaseFirestore.instance.batch();

      for (var dName in _daysOrder) {
        List periods = phase2[dName] as List? ?? [];
        for (int pIdx = 0; pIdx < periods.length; pIdx++) {
          final slot = periods[pIdx];
          if (slot['type'] == 'حصة' &&
              slot['subject'] == widget.subject &&
              slot['grade'] == widget.grade) {

            DateTime targetDate = widget.lessonDate.add(Duration(days: (_daysOrder.indexOf(dName) - _daysOrder.indexOf(widget.dayName))));
            String dateStrForId = intl.DateFormat('yyyyMMdd').format(targetDate);
            String docId = '${widget.teacherId}_W${widget.weekNumber}_${dateStrForId}_P${pIdx + 1}';

            // تخطي الحصة الحالية لأنها حُفظت بالفعل
            if (docId == _prepDocId) continue;

            final cloned = Map<String, dynamic>.from(basePrepData);
            cloned['docId'] = docId;
            cloned['className'] = slot['class'];
            cloned['dayName'] = dName;
            cloned['periodIndex'] = pIdx + 1;
            cloned['lessonDate'] = intl.DateFormat('yyyy/MM/dd').format(targetDate);
            cloned['updatedAt'] = FieldValue.serverTimestamp();

            final docRef = FirebaseFirestore.instance.collection('lesson_preparations').doc(docId);
            batch.set(docRef, cloned, SetOptions(merge: true));
          }
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Error applying prep to entire week: $e");
    }
  }

  void _openMultiSelectDialog({
    required String title,
    required String bankKey,
    required List<String> sourceList,
    required List<_TimedItemModel> targetList,
  }) {
    String searchQuery = '';
    final TextEditingController customCtrl = TextEditingController();

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E), fontFamily: 'Cairo')),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        hintText: 'بحث في البنك المقترح...',
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      onChanged: (val) {
                        setDialogState(() => searchQuery = val.trim());
                      },
                    ),
                    const SizedBox(height: 10),
                    if (!widget.isViewerOnly)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customCtrl,
                              decoration: InputDecoration(
                                labelText: 'إضافة بند مخصص...',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            onPressed: () {
                              final text = customCtrl.text.trim();
                              if (text.isNotEmpty) {
                                setDialogState(() {
                                  if (!targetList.any((e) => e.text == text)) {
                                    targetList.add(_TimedItemModel(text: text));
                                  }
                                  sourceList.insert(0, text);
                                  customCtrl.clear();
                                });
                                _saveToCustomBank(bankKey, text);
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final itemText = filteredItems[idx];
                          final isSelected = targetList.any((e) => e.text == itemText);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(itemText, style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'Cairo', color: Color(0xFF1E293B))),
                            value: isSelected,
                            activeColor: const Color(0xFF0F766E),
                            onChanged: widget.isViewerOnly ? null : (val) {
                              setDialogState(() {
                                if (val == true) {
                                  targetList.add(_TimedItemModel(text: itemText));
                                } else {
                                  targetList.removeWhere((e) => e.text == itemText);
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)))),
                if (!widget.isViewerOnly)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                    child: const Text('حفظ واختيار', style: TextStyle(fontFamily: 'Cairo')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRequirementBadge(bool isRequired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRequired ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isRequired ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1)),
      ),
      child: Text(
        isRequired ? 'إجباري' : 'اختياري',
        style: TextStyle(
          color: isRequired ? const Color(0xFF991B1B) : const Color(0xFF475569),
          fontWeight: FontWeight.w600,
          fontSize: 10,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _buildTimedSectionPicker({
    required String title,
    required IconData icon,
    required List<_TimedItemModel> selectedItems,
    required int domainDuration,
    required int domainStartMins,
    required String bankKey,
    required Map<String, List<String>> sourceMap,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF475569), size: 18),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Cairo')),
                  const SizedBox(width: 6),
                  _buildRequirementBadge(isRequired),
                ],
              ),
              if (!widget.isViewerOnly)
                OutlinedButton(
                  onPressed: () => _openMultiSelectDialog(
                    title: title,
                    bankKey: bankKey,
                    sourceList: _getFilteredList(sourceMap, bankKey),
                    targetList: selectedItems,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF0F766E)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('اختيار من البنك', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (selectedItems.isEmpty)
            const Text('لم يتم إدراج بنود بعد.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo'))
          else
            ...selectedItems.map((item) {
              int actualOffset = item.triggerOffset > domainDuration ? domainDuration : item.triggerOffset;
              String calculatedTimeStr = _formatMinsToTime(domainStartMins + actualOffset);

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.text, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontFamily: 'Cairo')),
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: actualOffset,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      items: List.generate(domainDuration + 1, (i) {
                        return DropdownMenuItem(
                            value: i,
                            child: Text(i == 0 ? 'بدء الحصة' : 'بعد $i د', style: const TextStyle(fontSize: 10, color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontFamily: 'Cairo'))
                        );
                      }),
                      onChanged: widget.isViewerOnly ? null : (val) {
                        if (val != null) setState(() => item.triggerOffset = val);
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(calculatedTimeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'Cairo')),
                    if (!widget.isViewerOnly)
                      InkWell(
                        onTap: () => setState(() => selectedItems.remove(item)),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                        ),
                      )
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDomainDigitalLinksSection(String domainKey, int domainStartMins, int domainDuration) {
    List<_DomainDigitalLink> links = _domainLinks[domainKey]!;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  const Text('المصادر الرقمية والروابط', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155), fontFamily: 'Cairo')),
                  const SizedBox(width: 6),
                  _buildRequirementBadge(false),
                ],
              ),
              if (!widget.isViewerOnly)
                TextButton(
                  onPressed: () {
                    setState(() {
                      links.add(_DomainDigitalLink(titleCtrl: TextEditingController(), urlCtrl: TextEditingController(), triggerOffset: 0));
                    });
                  },
                  child: const Text('إضافة رابط +', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Color(0xFF0F766E))),
                ),
            ],
          ),
          if (links.isNotEmpty)
            ...links.asMap().entries.map((entry) {
              int idx = entry.key;
              _DomainDigitalLink item = entry.value;
              int actualOffset = item.triggerOffset > domainDuration ? domainDuration : item.triggerOffset;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: item.titleCtrl,
                        readOnly: widget.isViewerOnly,
                        decoration: const InputDecoration(
                          hintText: 'العنوان',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: item.urlCtrl,
                        readOnly: widget.isViewerOnly,
                        decoration: const InputDecoration(
                          hintText: 'https://...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: actualOffset,
                      isDense: true,
                      items: List.generate(domainDuration + 1, (i) => DropdownMenuItem(value: i, child: Text('$i د', style: const TextStyle(fontSize: 10)))),
                      onChanged: widget.isViewerOnly ? null : (val) {
                        if (val != null) setState(() => item.triggerOffset = val);
                      },
                    ),
                    if (!widget.isViewerOnly)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            item.titleCtrl.dispose();
                            item.urlCtrl.dispose();
                            links.removeAt(idx);
                          });
                        },
                      )
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPhaseCard({
    required String phaseTitle,
    required int timeValue,
    required ValueChanged<int> onTimeChanged,
    required String startTimeStr,
    required String endTimeStr,
    required String domainKey,
    required Map<String, dynamic> accurateTimingInfo,
    required List<Widget> content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phaseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Cairo')),
                      Text('الوقت المعتمد: $startTimeStr إلى $endTimeStr', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Slider(
                    value: timeValue.toDouble(),
                    min: 0, max: 45, divisions: 45,
                    activeColor: const Color(0xFF0F766E),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: widget.isViewerOnly ? null : (val) => onTimeChanged(val.round()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text('$timeValue د', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF1E293B), fontFamily: 'Cairo')),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...content,
                _buildDomainDigitalLinksSection(domainKey, accurateTimingInfo['startMins'], timeValue),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isExact45 = _totalAssignedTime == 45;
    final accurateTimings = _calculateAccurateDomainTimings();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isViewerOnly ? 'عرض التحضير' : 'تحضير درس: ${widget.subject} (${widget.grade} - ${widget.className})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة التحكم والاعتماد العلوية
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // خانة الاختيار: اعتماد الدرس للأسبوع كاملاً
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _applyToEntireWeek,
                      activeColor: const Color(0xFF0F766E),
                      title: const Text(
                        'اعتماد هذا الدرس للأسبوع كاملاً لجميع الفصول والحصص',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Cairo'),
                      ),
                      subtitle: const Text(
                        'عند تفعيله، يتم تطبيق التحضير على كافة فصول المادة لهذا الأسبوع مع إمكانية التعديل على أي حصة لاحقاً دون التأثير على الحصص الأخرى.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                      ),
                      onChanged: widget.isViewerOnly ? null : (val) {
                        setState(() => _applyToEntireWeek = val ?? false);
                      },
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الأسبوع: ${widget.weekNumber} | ${widget.dayName} (الحصة ${widget.periodIndex})', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontFamily: 'Cairo')),
                        Container(
                          key: _timeKey,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isExact45 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isExact45 ? 'زمن الحصة: 45 دقيقة تماماً' : 'المجموع: $_totalAssignedTime / 45 د (يجب ضبطه)',
                            style: TextStyle(
                              color: isExact45 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // المرحلة 1: التهيئة ونواتج التعلم
              _buildPhaseCard(
                phaseTitle: accurateTimings['warmup']!['title'],
                timeValue: _timeWarmupAndOutcomes,
                onTimeChanged: (val) => setState(() => _timeWarmupAndOutcomes = val),
                startTimeStr: accurateTimings['warmup']!['startTimeStr'],
                endTimeStr: accurateTimings['warmup']!['endTimeStr'],
                domainKey: 'warmup',
                accurateTimingInfo: accurateTimings['warmup']!,
                content: [
                  Container(
                    key: _titleKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('عنوان الدرس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Cairo')),
                            const SizedBox(width: 6),
                            _buildRequirementBadge(true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _lessonTitleCtrl,
                          focusNode: _titleFocusNode,
                          readOnly: widget.isViewerOnly,
                          decoration: InputDecoration(
                            hintText: 'اكتب عنوان الدرس...',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onFieldSubmitted: (v) {
                            if (v.trim().isNotEmpty) _fetchAndApplyPrepByTitle(v.trim());
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_mySavedTitles.isNotEmpty && !widget.isViewerOnly) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _mySavedTitles.map((t) => ActionChip(
                        label: Text(t, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onPressed: () {
                          setState(() => _lessonTitleCtrl.text = t);
                          _fetchAndApplyPrepByTitle(t);
                        },
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Container(
                    key: _introKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('السؤال التمهيدي للدرس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Cairo')),
                            const SizedBox(width: 6),
                            _buildRequirementBadge(true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _introQuestionCtrl,
                          focusNode: _introFocusNode,
                          readOnly: widget.isViewerOnly,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'اكتب السؤال التمهيدي أو الموقف التعليمي للتهيئة...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildTimedSectionPicker(
                    title: 'نواتج التعلم المستهدفة',
                    icon: Icons.track_changes_outlined,
                    selectedItems: _selectedOutcomes,
                    domainDuration: _timeWarmupAndOutcomes,
                    domainStartMins: accurateTimings['warmup']!['startMins'],
                    bankKey: 'outcomes',
                    sourceMap: LessonPrepData.learningOutcomesMap,
                    isRequired: false,
                  ),
                ],
              ),

              // المرحلة 2: الشرح والعرض والاستراتيجيات
              _buildPhaseCard(
                phaseTitle: accurateTimings['explanation']!['title'],
                timeValue: _timeExplanationAndTech,
                onTimeChanged: (val) => setState(() => _timeExplanationAndTech = val),
                startTimeStr: accurateTimings['explanation']!['startTimeStr'],
                endTimeStr: accurateTimings['explanation']!['endTimeStr'],
                domainKey: 'explanation',
                accurateTimingInfo: accurateTimings['explanation']!,
                content: [
                  _buildTimedSectionPicker(
                    title: 'النقاط والعناوين الرئيسية',
                    icon: Icons.format_list_bulleted,
                    selectedItems: _explanationHeadings,
                    domainDuration: _timeExplanationAndTech,
                    domainStartMins: accurateTimings['explanation']!['startMins'],
                    bankKey: 'headings',
                    sourceMap: {'عام': []},
                    isRequired: false,
                  ),
                  _buildTimedSectionPicker(
                    title: 'استراتيجيات التدريس والتعلم النشط',
                    icon: Icons.psychology_outlined,
                    selectedItems: _selectedStrategies,
                    domainDuration: _timeExplanationAndTech,
                    domainStartMins: accurateTimings['explanation']!['startMins'],
                    bankKey: 'strategies',
                    sourceMap: LessonPrepData.strategiesMap,
                    isRequired: false,
                  ),
                  _buildTimedSectionPicker(
                    title: 'المهارات التخصصية للمادة',
                    icon: Icons.workspace_premium_outlined,
                    selectedItems: _specializedSkills,
                    domainDuration: _timeExplanationAndTech,
                    domainStartMins: accurateTimings['explanation']!['startMins'],
                    bankKey: 'skills',
                    sourceMap: {'عام': []},
                    isRequired: false,
                  ),
                ],
              ),

              // المرحلة 3: الأنشطة ورعاية الموهوبين
              _buildPhaseCard(
                phaseTitle: accurateTimings['activities']!['title'],
                timeValue: _timeActivitiesAndGifted,
                onTimeChanged: (val) => setState(() => _timeActivitiesAndGifted = val),
                startTimeStr: accurateTimings['activities']!['startTimeStr'],
                endTimeStr: accurateTimings['activities']!['endTimeStr'],
                domainKey: 'activities',
                accurateTimingInfo: accurateTimings['activities']!,
                content: [
                  _buildTimedSectionPicker(
                    title: 'أنشطة رعاية الموهوبين والتحدي',
                    icon: Icons.lightbulb_outline,
                    selectedItems: _selectedGifted,
                    domainDuration: _timeActivitiesAndGifted,
                    domainStartMins: accurateTimings['activities']!['startMins'],
                    bankKey: 'gifted',
                    sourceMap: LessonPrepData.giftedActivitiesMap,
                    isRequired: false,
                  ),
                ],
              ),

              // المرحلة 4: التطبيقات الحياتية والربط بالقيم
              _buildPhaseCard(
                phaseTitle: accurateTimings['practical']!['title'],
                timeValue: _timePracticalAndValues,
                onTimeChanged: (val) => setState(() => _timePracticalAndValues = val),
                startTimeStr: accurateTimings['practical']!['startTimeStr'],
                endTimeStr: accurateTimings['practical']!['endTimeStr'],
                domainKey: 'practical',
                accurateTimingInfo: accurateTimings['practical']!,
                content: [
                  _buildTimedSectionPicker(
                    title: 'تطبيقات عملية مرتبطة بالحياة',
                    icon: Icons.public_outlined,
                    selectedItems: _selectedPractical,
                    domainDuration: _timePracticalAndValues,
                    domainStartMins: accurateTimings['practical']!['startMins'],
                    bankKey: 'practical',
                    sourceMap: LessonPrepData.practicalApplicationsMap,
                    isRequired: false,
                  ),
                  _buildTimedSectionPicker(
                    title: 'الربط بالقيم والهوية الوطنية',
                    icon: Icons.flag_outlined,
                    selectedItems: _selectedValues,
                    domainDuration: _timePracticalAndValues,
                    domainStartMins: accurateTimings['practical']!['startMins'],
                    bankKey: 'values',
                    sourceMap: LessonPrepData.valuesAndIdentityMap,
                    isRequired: false,
                  ),
                ],
              ),

              // المرحلة 5: التقويم والواجبات
              _buildPhaseCard(
                phaseTitle: accurateTimings['evaluation']!['title'],
                timeValue: _timeEvaluationAndFeedback,
                onTimeChanged: (val) => setState(() => _timeEvaluationAndFeedback = val),
                startTimeStr: accurateTimings['evaluation']!['startTimeStr'],
                endTimeStr: accurateTimings['evaluation']!['endTimeStr'],
                domainKey: 'evaluation',
                accurateTimingInfo: accurateTimings['evaluation']!,
                content: [
                  Container(
                    key: _evalKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('التقويم والواجبات', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Cairo')),
                            const SizedBox(width: 6),
                            _buildRequirementBadge(true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _hwPageCtrl,
                                readOnly: widget.isViewerOnly,
                                decoration: InputDecoration(
                                  labelText: 'الصفحة (اختياري)',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _hwTitleCtrl,
                                focusNode: _hwTitleFocusNode,
                                readOnly: widget.isViewerOnly,
                                decoration: InputDecoration(
                                  labelText: 'عنوان الواجب أو السؤال التقويمي *',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hwTextCtrl,
                          readOnly: widget.isViewerOnly,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'التعليمات والتغذية الراجعة',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // زر الاعتماد والحفظ المريح
              if (!widget.isViewerOnly)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePreparation,
                    icon: _isSaving
                        ? const SizedBox.shrink()
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('اعتماد وحفظ التحضير', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}