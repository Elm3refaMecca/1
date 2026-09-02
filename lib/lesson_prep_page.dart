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

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'متابعة تحضير المعلمين' : 'تحضيري - جدول الحصص المعتمد', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Text('المعلم: ${t['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                const Text('اختر الأسبوع الدراسي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        child: Text('الأسبوع $w (يبدأ: $dateStr)', style: const TextStyle(fontSize: 13)),
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
                                        Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                          child: Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                            child: Row(
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
                                                        ),
                                                      ),
                                                      if (isClass) ...[
                                                        if (grade.isNotEmpty || className.isNotEmpty)
                                                          Text('$grade - $className', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
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
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.visibility, size: 12, color: Colors.black87),
                                                                    const SizedBox(width: 4),
                                                                    const Text('زيارة صفية', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87)),
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
                                                                  Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
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
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00796B))),
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
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
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
                            title: Text(item, style: const TextStyle(fontSize: 13, height: 1.4)),
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
        title: Text(widget.isViewerOnly ? 'عرض: ${widget.subject}' : 'تحضير: ${widget.subject} (${widget.grade} - ${widget.className})', style: const TextStyle(fontSize: 15)),
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
                  child: const Text('أنت في وضع المشاهدة فقط (صلاحيات المدير)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.teal.shade200)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الأسبوع: ${widget.weekNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('اليوم: ${widget.dayName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('التاريخ: $formattedDate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00796B))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTimeDistributionCard(),
              const SizedBox(height: 20),

              const Text('عنوان الدرس *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        : const Text('اعتماد وحفظ التحضير سحابياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    Text('توزيع وقت الحصة (45 دقيقة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isExact45 ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text('المجموع: $_totalAssignedTime / 45 د', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
        SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(
          child: Slider(
            value: currentValue.toDouble(), min: 0, max: 45, divisions: 45,
            label: '$currentValue د', activeColor: const Color(0xFF00796B),
            onChanged: widget.isViewerOnly ? null : (val) => onChanged(val.round()),
          ),
        ),
        Container(width: 40, alignment: Alignment.center, child: Text('$currentValue د', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  ],
                ),
                if (!widget.isViewerOnly)
                  ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('اختيار/كتابة', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedItems.isEmpty)
              const Text('لم يتم إدراج بنود بعد.', style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: selectedItems.map((item) {
                  return Chip(
                    backgroundColor: color.withOpacity(0.08),
                    label: Text(item, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
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
                Text('مهارات تخصصية دقيقة للمادة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
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
                    label: Text(s, style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
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
                    Text('المصادر الرقمية (10 روابط)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
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
                Text('التقويم والتغذية الراجعة (الواجبات)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange)),
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

// ===========================================================================
// 3. شاشة الخطة التشغيلية والإجرائية للمدير (مستقلة ومطابقة لوزارة التعليم)
// ===========================================================================
class AdminOperationalPlanPage extends StatefulWidget {
  const AdminOperationalPlanPage({super.key});

  @override
  State<AdminOperationalPlanPage> createState() => _AdminOperationalPlanPageState();
}

class _AdminOperationalPlanPageState extends State<AdminOperationalPlanPage> {
  int _selectedWeek = 1;

  final Map<int, String> _hijriDatesMap = {
    1: '17 - 21 / 3 / 1448 هـ',
    2: '24 - 28 / 3 / 1448 هـ',
    3: '2 - 6 / 4 / 1448 هـ',
    4: '9 - 11 / 4 / 1448 هـ',
    5: '16 - 20 / 4 / 1448 هـ',
    6: '23 - 27 / 4 / 1448 هـ',
    7: '30 / 4 - 4 / 5 / 1448 هـ',
    8: '7 - 11 / 5 / 1448 هـ',
    9: '14 - 18 / 5 / 1448 هـ',
    10: '21 - 25 / 5 / 1448 هـ',
    11: '28 / 5 - 2 / 6 / 1448 هـ',
    12: '5 - 9 / 6 / 1448 هـ',
    13: '19 - 23 / 6 / 1448 هـ',
    14: '26 / 6 - 1 / 7 / 1448 هـ',
    15: '4 - 8 / 7 / 1448 هـ',
    16: '11 - 15 / 7 / 1448 هـ',
    17: '18 - 22 / 7 / 1448 هـ',
    18: '25 - 29 / 7 / 1448 هـ',
  };

  void _openAddOrEditItemDialog({DocumentSnapshot? doc}) {
    final Map<String, dynamic> data = doc != null ? (doc.data() as Map<String, dynamic>) : {};

    String selectedCategory = data['category'] ?? 'مبادرة';
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final executorCtrl = TextEditingController(text: data['executor'] ?? '');
    final supervisorCtrl = TextEditingController(text: data['supervisor'] ?? 'لجنة متابعة تنفيذ برامج الخطة');
    String executionStatus = data['status'] ?? 'تحت الإجراء';
    final notesCtrl = TextEditingController(text: data['notes'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(doc == null ? 'إضافة بند تشغيلي للأسبوع $_selectedWeek' : 'تعديل بند تشغيلي', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'نوع البند *', border: OutlineInputBorder()),
                      items: ['فعالية', 'مبادرة', 'قيمة', 'إجراء مدرسي يومي'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'مسمى البرنامج / المبادرة / الإجراء *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: executorCtrl,
                      decoration: const InputDecoration(labelText: 'المنفذ * (مثال: يحيى حكومي، معلمو البدنية)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: supervisorCtrl,
                      decoration: const InputDecoration(labelText: 'المتابع', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('حالة التنفيذ والمتابعة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1565C0))),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatusOption('تحت الإجراء', Icons.sync, Colors.blue, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                        _buildStatusOption('مكتمل', Icons.check_circle, Colors.green, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                        _buildStatusOption('مُرحّل', Icons.next_plan, Colors.orange, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                        _buildStatusOption('لم يُنفذ', Icons.cancel, Colors.red, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                        _buildStatusOption('مُلغى', Icons.block, Colors.blueGrey, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'الملاحظات والتوصيات', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                if (doc != null)
                  TextButton(
                    onPressed: () async {
                      await doc.reference.delete();
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || executorCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة اسم البرنامج والمنفذ')));
                      return;
                    }

                    final dataToSave = {
                      'weekNumber': _selectedWeek,
                      'category': selectedCategory,
                      'title': titleCtrl.text.trim(),
                      'executor': executorCtrl.text.trim(),
                      'supervisor': supervisorCtrl.text.trim(),
                      'status': executionStatus,
                      'notes': notesCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (doc == null) {
                      await FirebaseFirestore.instance.collection('school_operational_plan_1448').add(dataToSave);
                    } else {
                      await doc.reference.update(dataToSave);
                    }

                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حفظ واعتـماد'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusOption(String title, IconData icon, Color color, String currentStatus, Function(String) onSelect) {
    bool isSelected = currentStatus == title;
    return InkWell(
      onTap: () => onSelect(title),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showOfficialConditionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('شروط التنفيذ والمتابعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('حالات المتابعة الإدارية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const Divider(),
              _buildConditionTile('1. تحت الإجراء:', 'البرنامج قيد التنفيذ حالياً، أو يأخذ مدى زمنياً ممتداً ولم ينتهِ بعد.', Colors.blue),
              _buildConditionTile('2. مكتمل:', 'تم إنجاز البرنامج أو المبادرة وتحقيق الأهداف التربوية بنجاح.', Colors.green),
              _buildConditionTile('3. مُرحّل:', 'تم تأجيل البرنامج لأسبوع آخر لظروف طارئة أو تعارض في الجدولة.', Colors.orange),
              _buildConditionTile('4. لم يُنفذ:', 'انقضى الوقت ولم يتم التنفيذ لعدم توفر متطلبات، ويستوجب ذكر السبب.', Colors.red),
              _buildConditionTile('5. مُلغى:', 'أُلغي البرنامج بقرار من الإدارة لانتفاء الحاجة.', Colors.blueGrey),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            child: const Text('فهمت'),
          )
        ],
      ),
    );
  }

  Widget _buildConditionTile(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'Cairo'),
                children: [
                  TextSpan(text: '$title ', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String hijriDate = _hijriDatesMap[_selectedWeek] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخطة التشغيلية لمدير المدرسة 1448هـ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.rule_folder),
            tooltip: 'شروط وضوابط التنفيذ',
            onPressed: _showOfficialConditionsDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة بند للخطة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openAddOrEditItemDialog(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('الأسبوع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedWeek,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: List.generate(18, (index) {
                      int w = index + 1;
                      return DropdownMenuItem<int>(
                        value: w,
                        child: Text('الأسبوع $w (${_hijriDatesMap[w] ?? ""})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  .collection('school_operational_plan_1448')
                  .where('weekNumber', isEqualTo: _selectedWeek)
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
                        Icon(Icons.post_add, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('لم يتم تسجيل أي برامج للأسبوع $_selectedWeek حتى الآن', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openAddOrEditItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أول بند تشغيلي الآن'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                        )
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('توزيع البرامج والمبادرات - الأسبوع $_selectedWeek', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(hijriDate, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
                          border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                          columns: const [
                            DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('البرنامج / المبادرة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المنفذ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المتابع', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجراء', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String status = data['status'] ?? 'لم ينفذ';

                            Color badgeColor = Colors.grey;
                            if (status == 'مكتمل' || status == 'نُفذ') badgeColor = Colors.green;
                            if (status == 'لم يُنفذ' || status == 'لم ينفذ') badgeColor = Colors.red;
                            if (status == 'مُرحّل' || status == 'رُحّل') badgeColor = Colors.orange;
                            if (status == 'مُلغى' || status == 'ألغي') badgeColor = Colors.blueGrey;
                            if (status == 'تحت الإجراء') badgeColor = Colors.blue;

                            return DataRow(
                              cells: [
                                DataCell(Text(data['category'] ?? '-')),
                                DataCell(Text(data['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(data['executor'] ?? '-')),
                                DataCell(Text(data['supervisor'] ?? '-')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                                    child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                                DataCell(Text(data['notes']?.isNotEmpty == true ? data['notes'] : '-')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF1565C0), size: 18),
                                    onPressed: () => _openAddOrEditItemDialog(doc: doc),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 70),
                    ],
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