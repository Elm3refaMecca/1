import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'lesson_prep_data.dart';

// ===========================================================================
// 1. نماذج البيانات (Models)
// ===========================================================================

class OperationalTeacherItem {
  final String id;
  final String name;
  final bool isCustom;
  final bool hasApproved;

  OperationalTeacherItem({
    required this.id,
    required this.name,
    this.isCustom = false,
    this.hasApproved = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isCustom': isCustom,
    'hasApproved': hasApproved,
  };

  factory OperationalTeacherItem.fromMap(Map<String, dynamic> map) => OperationalTeacherItem(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    isCustom: map['isCustom'] ?? false,
    hasApproved: map['hasApproved'] ?? true,
  );
}

class OperationalPlanEntry {
  final String? id;
  final String title;
  final String category;
  final bool isCustomProgram;
  final String stage;
  final List<String> targetGrades;
  final DateTime startDate;
  final DateTime endDate;
  final bool isContinuousUntilYearEnd;
  final int? startWeek;
  final int? endWeek;
  final int? executionWeek;
  final List<String> executionDays;
  final List<int> executionPeriods;
  final List<String> executorsIds;
  final Map<String, bool> collaboratorApprovals;
  final String dateSelectionMode;
  final List<OperationalTeacherItem> executors;
  final List<OperationalTeacherItem> followUpCommittee;
  final String status;
  final String notes;
  final bool isCustomNotes;
  final bool isTeacherInitiated;
  final String? teacherId;
  final String? teacherName;
  final bool isApprovedByAdmin;
  final DateTime? adminFollowUpDate;
  final List<Map<String, dynamic>> visitsLog;

  OperationalPlanEntry({
    this.id,
    required this.title,
    required this.category,
    this.isCustomProgram = false,
    required this.stage,
    required this.targetGrades,
    required this.startDate,
    required this.endDate,
    this.isContinuousUntilYearEnd = false,
    this.startWeek,
    this.endWeek,
    this.executionWeek,
    this.executionDays = const [],
    this.executionPeriods = const [],
    this.executorsIds = const [],
    this.collaboratorApprovals = const {},
    this.dateSelectionMode = 'weeks',
    required this.executors,
    required this.followUpCommittee,
    this.status = 'تحت الإجراء',
    this.notes = '',
    this.isCustomNotes = false,
    this.isTeacherInitiated = false,
    this.teacherId,
    this.teacherName,
    this.isApprovedByAdmin = true,
    this.adminFollowUpDate,
    this.visitsLog = const [],
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'isCustomProgram': isCustomProgram,
    'stage': stage,
    'targetGrades': targetGrades,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isContinuousUntilYearEnd': isContinuousUntilYearEnd,
    'startWeek': startWeek,
    'endWeek': endWeek,
    'executionWeek': executionWeek,
    'executionDays': executionDays,
    'executionPeriods': executionPeriods,
    'executorsIds': executorsIds,
    'collaboratorApprovals': collaboratorApprovals,
    'dateSelectionMode': dateSelectionMode,
    'executors': executors.map((e) => e.toMap()).toList(),
    'followUpCommittee': followUpCommittee.map((e) => e.toMap()).toList(),
    'status': status,
    'notes': notes,
    'isCustomNotes': isCustomNotes,
    'isTeacherInitiated': isTeacherInitiated,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'isApprovedByAdmin': isApprovedByAdmin,
    'adminFollowUpDate': adminFollowUpDate?.toIso8601String(),
    'visitsLog': visitsLog,
  };

  factory OperationalPlanEntry.fromMap(String docId, Map<String, dynamic> map) {
    return OperationalPlanEntry(
      id: docId,
      title: map['title'] ?? '',
      category: map['category'] ?? 'مبادرة',
      isCustomProgram: map['isCustomProgram'] ?? false,
      stage: map['stage'] ?? 'المرحلة الابتدائية',
      targetGrades: List<String>.from(map['targetGrades'] ?? []),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now(),
      isContinuousUntilYearEnd: map['isContinuousUntilYearEnd'] ?? false,
      startWeek: map['startWeek'] ?? map['executionWeek'],
      endWeek: map['endWeek'] ?? map['startWeek'] ?? map['executionWeek'],
      executionWeek: map['executionWeek'] ?? map['startWeek'],
      executionDays: List<String>.from(map['executionDays'] ?? (map['executionDay'] != null ? [map['executionDay']] : [])),
      executionPeriods: List<int>.from(map['executionPeriods'] ?? []),
      executorsIds: List<String>.from(map['executorsIds'] ?? []),
      collaboratorApprovals: Map<String, bool>.from(map['collaboratorApprovals'] ?? {}),
      dateSelectionMode: map['dateSelectionMode'] ?? 'weeks',
      executors: (map['executors'] as List? ?? [])
          .map((e) => OperationalTeacherItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      followUpCommittee: (map['followUpCommittee'] as List? ?? [])
          .map((e) => OperationalTeacherItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      status: map['status'] ?? 'تحت الإجراء',
      notes: map['notes'] ?? '',
      isCustomNotes: map['isCustomNotes'] ?? false,
      isTeacherInitiated: map['isTeacherInitiated'] ?? false,
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      isApprovedByAdmin: map['isApprovedByAdmin'] ?? true,
      adminFollowUpDate: map['adminFollowUpDate'] != null ? DateTime.tryParse(map['adminFollowUpDate']) : null,
      visitsLog: List<Map<String, dynamic>>.from(map['visitsLog'] ?? []),
    );
  }
}

// ===========================================================================
// 2. واجهة الخطة التشغيلية للمدير
// ===========================================================================

class AdminOperationalPlanPage extends StatefulWidget {
  const AdminOperationalPlanPage({super.key});

  @override
  State<AdminOperationalPlanPage> createState() => _AdminOperationalPlanPageState();
}

class _AdminOperationalPlanPageState extends State<AdminOperationalPlanPage> {
  final _collectionRef = FirebaseFirestore.instance.collection('school_operational_plan_1448');

  List<OperationalTeacherItem> _cloudTeachers = [];

  final List<String> _stagesList = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
  final Map<String, List<String>> _gradesByStage = {
    'المرحلة الابتدائية': ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'],
    'المرحلة المتوسطة': ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'],
    'المرحلة الثانوية': ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'],
  };

  final DateTime _schoolYearStart = DateTime(2026, 8, 30);
  final Map<String, int> _dayIndexMap = {
    'الأحد': 0, 'الإثنين': 1, 'الثلاثاء': 2, 'الأربعاء': 3, 'الخميس': 4,
  };

  int _selectedFilterWeek = 1;

  final List<String> _statusList = [
    'تحت الإجراء',
    'مكتمل',
    'مُرحّل',
    'لم يُنفذ',
    'مُلغى',
  ];

  @override
  void initState() {
    super.initState();
    _determineCurrentWeek();
    _loadTeachersFromFirestore();
  }

  void _determineCurrentWeek() {
    final now = DateTime.now();
    if (now.isAfter(_schoolYearStart)) {
      int diffDays = now.difference(_schoolYearStart).inDays;
      int currentW = (diffDays / 7).floor() + 1;
      if (currentW >= 1 && currentW <= 52) {
        _selectedFilterWeek = currentW;
      }
    }
  }

  DateTime _getWeekStartDate(int week) {
    return _schoolYearStart.add(Duration(days: (week - 1) * 7));
  }

  DateTime _getWeekEndDate(int week) {
    return _schoolYearStart.add(Duration(days: ((week - 1) * 7) + 6));
  }

  DateTime _calculateExactDate(int weekNumber, String dayName) {
    int dayOffset = _dayIndexMap[dayName] ?? 0;
    return _schoolYearStart.add(Duration(days: ((weekNumber - 1) * 7) + dayOffset));
  }

  Future<void> _loadTeachersFromFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      List<OperationalTeacherItem> list = [];
      for (var doc in snap.docs) {
        final d = doc.data();
        if (d['profession'] != 'admin' && d['name'] != null) {
          list.add(OperationalTeacherItem(id: doc.id, name: d['name'], isCustom: false, hasApproved: true));
        }
      }
      if (mounted) setState(() => _cloudTeachers = list);
    } catch (_) {}
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'مكتمل':
      case 'نُفذ':
        return Colors.green.shade700;
      case 'لم يُنفذ':
      case 'لم ينفذ':
        return Colors.red.shade700;
      case 'مُرحّل':
      case 'رُحّل':
        return Colors.orange.shade800;
      case 'مُلغى':
      case 'ألغي':
        return Colors.blueGrey;
      case 'تحت الإجراء':
      default:
        return Colors.blue.shade700;
    }
  }

  Future<void> _quickChangeStatus(DocumentReference docRef, String currentStatus) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.published_with_changes, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Text('تغيير حالة الإجراء مباشرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                ],
              ),
              const SizedBox(height: 12),
              ..._statusList.map((st) {
                final isCurrent = st == currentStatus;
                final color = _getStatusBadgeColor(st);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: color, radius: 10),
                  title: Text(st, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo')),
                  trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => Navigator.pop(ctx, st),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != currentStatus) {
      await docRef.update({
        'status': selected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تغيير حالة الإجراء إلى: $selected بنجاح!'),
            backgroundColor: _getStatusBadgeColor(selected),
          ),
        );
      }
    }
  }

  void _openAddVisitDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final visits = List<Map<String, dynamic>>.from(data['visitsLog'] ?? []);
    final notesCtrl = TextEditingController();
    String visitType = 'متابعة ميدانية';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.fact_check_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('تدوين زيارة / إثبات متابعة:\n${data['title'] ?? ''}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: visitType,
                        decoration: const InputDecoration(labelText: 'نوع الزيارة / الإثبات', border: OutlineInputBorder()),
                        items: ['متابعة ميدانية', 'إثبات زيارة صفية', 'رصد شواهد', 'اجتماع مع المنفذين', 'تقييم ختامي']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Cairo'))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => visitType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'الملاحظات والتوجيهات خلال الزيارة *',
                          hintText: 'اكتب ما تم رصده وتوجيهه...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (visits.isNotEmpty) ...[
                        const Divider(),
                        const Text('سجل الزيارات السابقة للمبادرة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                        const SizedBox(height: 8),
                        ...visits.map((v) => Card(
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.verified, color: Colors.teal, size: 20),
                            title: Text('${v['type']} - ${v['visitorName'] ?? 'المدير'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                            subtitle: Text('${v['notes']}\nالتاريخ: ${v['timestamp'] ?? ''}', style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                          ),
                        )),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo'))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('حفظ الزيارة الآن', style: TextStyle(fontFamily: 'Cairo')),
                  onPressed: () async {
                    if (notesCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة ملاحظات الزيارة')));
                      return;
                    }

                    final user = FirebaseAuth.instance.currentUser;
                    final now = DateTime.now();
                    final formattedTime = intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(now);

                    final newVisit = {
                      'type': visitType,
                      'notes': notesCtrl.text.trim(),
                      'timestamp': formattedTime,
                      'visitorUid': user?.uid ?? '',
                      'visitorName': user?.displayName ?? 'إدارة المدرسة',
                      'dateTimeIso': now.toIso8601String(),
                    };

                    await doc.reference.update({
                      'visitsLog': FieldValue.arrayUnion([newVisit]),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تدوين الزيارة وحفظها بالمبادرة بنجاح ✅'), backgroundColor: Colors.green));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final now = DateTime.now();
        return Container(
          height: 550,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('إشعارات البرامج المتأخرة والمنتهية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _collectionRef.where('status', isNotEqualTo: 'مكتمل').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    final urgentItems = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['endDate'] == null || data['isContinuousUntilYearEnd'] == true) return false;
                      final endDate = DateTime.tryParse(data['endDate']);
                      if (endDate == null) return false;
                      return endDate.isBefore(now) || endDate.difference(now).inDays <= 2;
                    }).toList();

                    if (urgentItems.isEmpty) {
                      return const Center(
                        child: Text('رائع! لا توجد برامج متأخرة أو تحتاج إقفال فوري.', style: TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold)),
                      );
                    }

                    return ListView.builder(
                      itemCount: urgentItems.length,
                      itemBuilder: (context, idx) {
                        final d = urgentItems[idx];
                        final m = d.data() as Map<String, dynamic>;
                        final endDate = DateTime.parse(m['endDate']);
                        final isLate = endDate.isBefore(now);

                        return Card(
                          color: isLate ? Colors.red.shade50 : Colors.orange.shade50,
                          child: ListTile(
                            leading: Icon(isLate ? Icons.warning_rounded : Icons.timer, color: isLate ? Colors.red : Colors.orange),
                            title: Text(m['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            subtitle: Text(
                              isLate ? 'متأخر! انتهت المدة في: ${intl.DateFormat('yyyy/MM/dd').format(endDate)}' : 'شارف على الانتهاء ويحتاج إلى إغلاق',
                              style: TextStyle(color: isLate ? Colors.red.shade900 : Colors.orange.shade900, fontSize: 12, fontFamily: 'Cairo'),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openAddOrEditItemDialog(doc: d);
                              },
                              child: const Text('إقفال الآن', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                            ),
                          ),
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

  void _openApproveTeacherInitiativeDialog(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    int selectedWeek = data['executionWeek'] ?? 1;
    List<String> selectedDays = List<String>.from(data['executionDays'] ?? (data['executionDay'] != null ? [data['executionDay']] : [PlanStaticData.daysOfWeek.first]));
    List<int> selectedPeriods = List<int>.from(data['executionPeriods'] ?? []);
    bool isContinuous = data['isContinuousUntilYearEnd'] ?? false;

    List<OperationalTeacherItem> currentExecutors = (data['executors'] as List? ?? [])
        .map((e) => OperationalTeacherItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    List<OperationalTeacherItem> selectedCommittee = (data['followUpCommittee'] as List? ?? [])
        .map((e) => OperationalTeacherItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final customTeacherCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            DateTime exactCalculatedDate = _calculateExactDate(selectedWeek, selectedDays.isNotEmpty ? selectedDays.first : PlanStaticData.daysOfWeek.first);
            String formattedExactDate = intl.DateFormat('yyyy/MM/dd').format(exactCalculatedDate);

            bool pendingCollaborators = currentExecutors.any((ex) => !ex.hasApproved);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('اعتماد وتسكين مبادرة: ${data['title']}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text('المعلم المقترح: ${data['teacherName'] ?? 'معلم'} | المستهدفون: ${data['stage']} - ${(data['targetGrades'] as List? ?? []).join('، ')}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ),
                      const SizedBox(height: 16),
                      const Text('تحديد موعد التسكين في الجدول:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontFamily: 'Cairo')),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<int>(
                        value: selectedWeek,
                        decoration: const InputDecoration(labelText: 'الأسبوع الدراسي *', border: OutlineInputBorder()),
                        items: List.generate(52, (i) => DropdownMenuItem(value: i + 1, child: Text('الأسبوع ${i + 1}', style: const TextStyle(fontFamily: 'Cairo')))),
                        onChanged: (val) { if (val != null) setDlgState(() => selectedWeek = val); },
                      ),
                      const SizedBox(height: 12),

                      const Text('أيام التنفيذ المحددة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                      Wrap(
                        spacing: 8,
                        children: PlanStaticData.daysOfWeek.map((day) {
                          return FilterChip(
                            label: Text(day, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedDays.contains(day),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) selectedDays.add(day);
                                else selectedDays.remove(day);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('الحصص المحددة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                      Wrap(
                        spacing: 8,
                        children: List.generate(8, (i) => i + 1).map((period) {
                          return FilterChip(
                            label: Text('الحصة $period', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedPeriods.contains(period),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) selectedPeriods.add(period);
                                else selectedPeriods.remove(period);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 8),
                      Text('التاريخ الدقيق (بناءً على أول يوم): $formattedExactDate', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),

                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('استمرار المبادرة لنهاية العام الدراسي', style: TextStyle(fontFamily: 'Cairo')),
                        value: isContinuous,
                        activeColor: const Color(0xFF1565C0),
                        onChanged: (v) => setDlgState(() => isContinuous = v ?? false),
                      ),

                      const SizedBox(height: 16),
                      if (pendingCollaborators)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red)),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(child: Text('تنبيه: يجب على الزميل الموافقة أولاً قبل تسكين المبادرة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12))),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      const Divider(),
                      _buildTeacherSelectionSection(
                        title: 'أعضاء لجنة المتابعة للمبادرة:',
                        selectedList: selectedCommittee,
                        customTeacherCtrl: customTeacherCtrl,
                        onAddCustom: (name) => setDlgState(() => selectedCommittee.add(OperationalTeacherItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, isCustom: true, hasApproved: true))),
                        onToggleTeacher: (t) => setDlgState(() => selectedCommittee.any((e) => e.name == t.name) ? selectedCommittee.removeWhere((e) => e.name == t.name) : selectedCommittee.add(t)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (pendingCollaborators) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب على الزميل الموافقة أولاً قبل تسكين المبادرة', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                      return;
                    }

                    if (selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد يوم واحد على الأقل', style: TextStyle(fontFamily: 'Cairo'))));
                      return;
                    }

                    DateTime finalCalculatedDate = _calculateExactDate(selectedWeek, selectedDays.first);

                    await doc.reference.update({
                      'isApprovedByAdmin': true,
                      'status': 'تحت الإجراء',
                      'startDate': finalCalculatedDate.toIso8601String(),
                      'endDate': finalCalculatedDate.toIso8601String(),
                      'isContinuousUntilYearEnd': isContinuous,
                      'executionWeek': selectedWeek,
                      'executionDays': selectedDays,
                      'executionPeriods': selectedPeriods,
                      'adminFollowUpDate': finalCalculatedDate.toIso8601String(),
                      'followUpCommittee': selectedCommittee.map((e) => e.toMap()).toList(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    // إرسال إشعار للمنفذين بأن الإدارة قامت باعتماد وتسكين المبادرة
                    final batch = FirebaseFirestore.instance.batch();
                    for (var ex in currentExecutors) {
                      if (!ex.isCustom) {
                        final notifRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(ex.id)
                            .collection('notifications')
                            .doc();
                        batch.set(notifRef, {
                          'title': '📅 اعتماد وتسكين مبادرة',
                          'message': 'قامت إدارة المدرسة باعتماد وتسكين مبادرة "${data['title']}" في جدولك للأسبوع $selectedWeek.',
                          'timestamp': FieldValue.serverTimestamp(),
                          'isRead': false,
                        });
                      }
                    }
                    await batch.commit();

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اعتماد وتسكين المبادرة بنجاح في الخطة وإشعار المنفذين! ✅'), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text('تأكيد الاعتماد والتسكين', style: TextStyle(fontFamily: 'Cairo')),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _openAddOrEditItemDialog({DocumentSnapshot? doc}) {
    final Map<String, dynamic> data = doc != null ? (doc.data() as Map<String, dynamic>) : {};

    final List<String> availableCategories = ['فعالية', 'مبادرة', 'مبادرة معلّم', 'قيمة', 'إجراء مدرسي يومي'];
    String selectedCategory = data['category'] ?? 'مبادرة';
    if (!availableCategories.contains(selectedCategory)) {
      selectedCategory = 'مبادرة';
    }
    String selectedProgramTitle = data['title'] ?? '';
    bool isCustomProgram = data['isCustomProgram'] ?? false;
    final customProgramCtrl = TextEditingController(text: isCustomProgram ? selectedProgramTitle : '');

    String selectedStage = data['stage'] ?? _stagesList.first;
    List<String> selectedGrades = List<String>.from(data['targetGrades'] ?? []);

    String dateSelectionMode = data['dateSelectionMode'] ?? 'weeks';
    int startWeek = data['startWeek'] ?? (_selectedFilterWeek > 0 ? _selectedFilterWeek : 1);
    int endWeek = data['endWeek'] ?? startWeek;

    DateTime startDate = data['startDate'] != null ? DateTime.parse(data['startDate']) : _getWeekStartDate(startWeek);
    DateTime endDate = data['endDate'] != null ? DateTime.parse(data['endDate']) : _getWeekEndDate(endWeek);
    bool isContinuous = data['isContinuousUntilYearEnd'] ?? false;

    List<String> selectedDays = List<String>.from(data['executionDays'] ?? (data['executionDay'] != null ? [data['executionDay']] : []));
    List<int> selectedPeriods = List<int>.from(data['executionPeriods'] ?? []);

    List<OperationalTeacherItem> selectedExecutors = (data['executors'] as List? ?? [])
        .map((e) => OperationalTeacherItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    List<OperationalTeacherItem> selectedCommittee = (data['followUpCommittee'] as List? ?? [])
        .map((e) => OperationalTeacherItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final customTeacherCtrl = TextEditingController();
    String executionStatus = data['status'] ?? 'تحت الإجراء';
    String selectedNote = data['notes'] ?? '';
    bool isCustomNote = data['isCustomNotes'] ?? false;
    final customNoteCtrl = TextEditingController(text: isCustomNote ? selectedNote : '');

    DateTime? adminFollowUpDate = data['adminFollowUpDate'] != null ? DateTime.tryParse(data['adminFollowUpDate']) : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final all1000Programs = LessonPrepData.thousandProgramsBank;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(doc == null ? 'إضافة مبادرة تشغيلية جديدة' : 'تعديل / إقفال المبادرة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ],
              ),
              content: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'نوع البند *', border: OutlineInputBorder()),
                        items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      const Text('البرنامج / المبادرة (من بنك البرامج المقترحة):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: (!isCustomProgram && all1000Programs.contains(selectedProgramTitle)) ? selectedProgramTitle : null,
                        hint: const Text('اختر من قائمة البرامج المقترحة...', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: all1000Programs.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              selectedProgramTitle = val;
                              isCustomProgram = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customProgramCtrl,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              decoration: const InputDecoration(
                                labelText: 'أو أضف برنامج جديد يدوياً (يظهر بالأحمر)',
                                labelStyle: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              if (customProgramCtrl.text.trim().isNotEmpty) {
                                setDlgState(() {
                                  selectedProgramTitle = customProgramCtrl.text.trim();
                                  isCustomProgram = true;
                                });
                              }
                            },
                            child: const Text('اعتماد يدوي', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                      if (isCustomProgram)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('البرنامج المعتمد حالياً: $selectedProgramTitle (مضاف يدوياً باللون الأحمر)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                        ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const Text('تحديد توقيت المبادرة (نظام الـ 52 أسبوعاً أو بالأيام):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF1565C0))),
                      const SizedBox(height: 8),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('مستمر لنهاية العام الدراسي (كامل الـ 52 أسبوعاً)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                        value: isContinuous,
                        onChanged: (v) => setDlgState(() => isContinuous = v ?? false),
                      ),

                      if (!isContinuous) ...[
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('تحديد بنظام الأسابيع (52 أسبوع)', style: TextStyle(fontFamily: 'Cairo')),
                              selected: dateSelectionMode == 'weeks',
                              onSelected: (val) => setDlgState(() => dateSelectionMode = 'weeks'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('تحديد بالتواريخ الدقيقة (باليوم)', style: TextStyle(fontFamily: 'Cairo')),
                              selected: dateSelectionMode == 'days',
                              onSelected: (val) => setDlgState(() => dateSelectionMode = 'days'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (dateSelectionMode == 'weeks') ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: startWeek,
                                  decoration: const InputDecoration(labelText: 'من الأسبوع', border: OutlineInputBorder()),
                                  items: List.generate(52, (i) {
                                    int w = i + 1;
                                    String startStr = intl.DateFormat('MM/dd').format(_getWeekStartDate(w));
                                    return DropdownMenuItem(value: w, child: Text('الأسبوع $w ($startStr)', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)));
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDlgState(() {
                                        startWeek = val;
                                        if (endWeek < startWeek) endWeek = startWeek;
                                        startDate = _getWeekStartDate(startWeek);
                                        endDate = _getWeekEndDate(endWeek);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: endWeek,
                                  decoration: const InputDecoration(labelText: 'إلى الأسبوع', border: OutlineInputBorder()),
                                  items: List.generate(52, (i) {
                                    int w = i + 1;
                                    String endStr = intl.DateFormat('MM/dd').format(_getWeekEndDate(w));
                                    return DropdownMenuItem(value: w, child: Text('الأسبوع $w ($endStr)', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)));
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDlgState(() {
                                        endWeek = val;
                                        endDate = _getWeekEndDate(endWeek);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text('من: ${intl.DateFormat('yyyy/MM/dd').format(startDate)}', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                                  onPressed: () async {
                                    final p = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2025), lastDate: DateTime(2030));
                                    if (p != null) setDlgState(() => startDate = p);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.event, size: 16),
                                  label: Text('إلى: ${intl.DateFormat('yyyy/MM/dd').format(endDate)}', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                                  onPressed: () async {
                                    final p = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2025), lastDate: DateTime(2030));
                                    if (p != null) setDlgState(() => endDate = p);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],

                      const SizedBox(height: 12),
                      const Text('أيام التنفيذ المحددة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                      Wrap(
                        spacing: 8,
                        children: PlanStaticData.daysOfWeek.map((day) {
                          return FilterChip(
                            label: Text(day, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedDays.contains(day),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) selectedDays.add(day);
                                else selectedDays.remove(day);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('الحصص المحددة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                      Wrap(
                        spacing: 8,
                        children: List.generate(8, (i) => i + 1).map((period) {
                          return FilterChip(
                            label: Text('الحصة $period', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedPeriods.contains(period),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) selectedPeriods.add(period);
                                else selectedPeriods.remove(period);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const Text('المستهدفون من الطلاب (المرحلة والصفوف فقط):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF1565C0))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStage,
                        decoration: const InputDecoration(labelText: 'المرحلة الدراسية', border: OutlineInputBorder()),
                        items: _stagesList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              selectedStage = val;
                              selectedGrades.clear();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: (_gradesByStage[selectedStage] ?? []).map((grade) {
                          final isSelected = selectedGrades.contains(grade);
                          return FilterChip(
                            label: Text(grade, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: isSelected,
                            onSelected: (sel) {
                              setDlgState(() {
                                if (sel) {
                                  selectedGrades.add(grade);
                                } else {
                                  selectedGrades.remove(grade);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const Text('المعلمون المنفذون ولجنة المتابعة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF1565C0))),
                      const SizedBox(height: 8),
                      _buildTeacherSelectionSection(
                        title: 'المعلمون المنفذون (يمكن اختيار أكثر من 10):',
                        selectedList: selectedExecutors,
                        customTeacherCtrl: customTeacherCtrl,
                        onAddCustom: (name) {
                          setDlgState(() {
                            selectedExecutors.add(OperationalTeacherItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, isCustom: true, hasApproved: true));
                          });
                        },
                        onToggleTeacher: (teacher) {
                          setDlgState(() {
                            if (selectedExecutors.any((t) => t.name == teacher.name)) {
                              selectedExecutors.removeWhere((t) => t.name == teacher.name);
                            } else {
                              selectedExecutors.add(OperationalTeacherItem(id: teacher.id, name: teacher.name, isCustom: teacher.isCustom, hasApproved: true));
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTeacherSelectionSection(
                        title: 'أعضاء لجنة المتابعة:',
                        selectedList: selectedCommittee,
                        customTeacherCtrl: customTeacherCtrl,
                        onAddCustom: (name) {
                          setDlgState(() {
                            selectedCommittee.add(OperationalTeacherItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, isCustom: true, hasApproved: true));
                          });
                        },
                        onToggleTeacher: (teacher) {
                          setDlgState(() {
                            if (selectedCommittee.any((t) => t.name == teacher.name)) {
                              selectedCommittee.removeWhere((t) => t.name == teacher.name);
                            } else {
                              selectedCommittee.add(OperationalTeacherItem(id: teacher.id, name: teacher.name, isCustom: teacher.isCustom, hasApproved: true));
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const Text('حالة التنفيذ والمتابعة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1565C0), fontFamily: 'Cairo')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusOption('تحت الإجراء', Icons.sync, Colors.blue, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('مكتمل', Icons.check_circle, Colors.green, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('مُرحّل', Icons.next_plan, Colors.orange, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('لم يُنفذ', Icons.cancel, Colors.red, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('مُلغى', Icons.block, Colors.blueGrey, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                        ],
                      ),

                      if (executionStatus == 'تحت الإجراء' || doc != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('تاريخ متابعة المدير الفعلي:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text(adminFollowUpDate != null ? intl.DateFormat('yyyy/MM/dd').format(adminFollowUpDate!) : 'تحديد موعد متابعة', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                              onPressed: () async {
                                final p = await showDatePicker(context: context, initialDate: adminFollowUpDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                                if (p != null) setDlgState(() => adminFollowUpDate = p);
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(),

                      const Text('الملاحظات والتوصيات الإدارية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF1565C0))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: (!isCustomNote && LessonPrepData.standardNotesBank.contains(selectedNote)) ? selectedNote : null,
                        hint: const Text('اختر ملاحظة توضيحية من القائمة...', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: LessonPrepData.standardNotesBank.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              selectedNote = val;
                              isCustomNote = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customNoteCtrl,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              decoration: const InputDecoration(
                                labelText: 'أو أضف ملاحظة توضيحية يدوية (تظهر بالأحمر)',
                                labelStyle: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              if (customNoteCtrl.text.trim().isNotEmpty) {
                                setDlgState(() {
                                  selectedNote = customNoteCtrl.text.trim();
                                  isCustomNote = true;
                                });
                              }
                            },
                            child: const Text('اعتماد الملاحظة', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    if (selectedProgramTitle.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار أو كتابة مسمى البرنامج')));
                      return;
                    }

                    if (dateSelectionMode == 'weeks' && !isContinuous) {
                      startDate = _getWeekStartDate(startWeek);
                      endDate = _getWeekEndDate(endWeek);
                    }

                    final planEntry = OperationalPlanEntry(
                      title: selectedProgramTitle,
                      category: selectedCategory,
                      isCustomProgram: isCustomProgram,
                      stage: selectedStage,
                      targetGrades: selectedGrades,
                      startDate: startDate,
                      endDate: isContinuous ? startDate.add(const Duration(days: 300)) : endDate,
                      isContinuousUntilYearEnd: isContinuous,
                      startWeek: startWeek,
                      endWeek: endWeek,
                      executionWeek: startWeek,
                      executionDays: selectedDays,
                      executionPeriods: selectedPeriods,
                      executorsIds: selectedExecutors.map((e) => e.id).toList(),
                      dateSelectionMode: dateSelectionMode,
                      executors: selectedExecutors,
                      followUpCommittee: selectedCommittee,
                      status: executionStatus,
                      notes: selectedNote,
                      isCustomNotes: isCustomNote,
                      isApprovedByAdmin: doc != null ? (data['isApprovedByAdmin'] ?? true) : true,
                      adminFollowUpDate: adminFollowUpDate ?? startDate,
                    );

                    final dataMap = planEntry.toMap();
                    dataMap['updatedAt'] = FieldValue.serverTimestamp();

                    if (doc == null) {
                      await _collectionRef.add(dataMap);
                    } else {
                      await doc.reference.update(dataMap);
                    }

                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حفظ واعتـماد الخطة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTeacherSelectionSection({
    required String title,
    required List<OperationalTeacherItem> selectedList,
    required TextEditingController customTeacherCtrl,
    required Function(String) onAddCustom,
    required Function(OperationalTeacherItem) onToggleTeacher,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<OperationalTeacherItem>(
                decoration: const InputDecoration(labelText: 'اختر معلماً من النظام...', border: OutlineInputBorder(), isDense: true),
                items: _cloudTeachers.map((t) => DropdownMenuItem(value: t, child: Text(t.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)))).toList(),
                onChanged: (t) {
                  if (t != null) onToggleTeacher(t);
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (c) {
                    final ctrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('إضافة معلم خارجي يدوياً', style: TextStyle(fontFamily: 'Cairo')),
                      content: TextField(
                        controller: ctrl,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(hintText: 'اسم المعلم الخارجي...', border: OutlineInputBorder()),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () {
                            if (ctrl.text.trim().isNotEmpty) {
                              onAddCustom(ctrl.text.trim());
                              Navigator.pop(c);
                            }
                          },
                          child: const Text('إضافة'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('معلم خارجي +', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: selectedList.map((t) {
            return Chip(
              backgroundColor: t.isCustom ? Colors.red.shade100 : Colors.blue.shade50,
              label: Text(t.name, style: TextStyle(color: t.isCustom ? Colors.red.shade900 : Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => onToggleTeacher(t),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusOption(String title, IconData icon, Color color, String currentStatus, Function(String) onSelect) {
    bool isSelected = currentStatus == title;
    return InkWell(
      onTap: () => onSelect(title),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
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
            Text('شروط وضوابط الخطة التشغيلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('معايير المتابعة والإقفال الإداري:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, fontFamily: 'Cairo')),
              const Divider(),
              _buildConditionTile('1. تحت الإجراء:', 'البرنامج قيد التنفيذ والمتابعة حالياً ضمن مدته الزمنية.', Colors.blue),
              _buildConditionTile('2. مكتمل:', 'تم إنجاز المبادرة وتحقيق المستهدفات التربوية وإقفالها نظامياً.', Colors.green),
              _buildConditionTile('3. مُرحّل:', 'تم تمديد فترة البرنامج أو جدولته لموعد لاحق.', Colors.orange),
              _buildConditionTile('4. لم يُنفذ:', 'انقضت المدة المحددة دون تنفيذ وتتطلب اتخاذ إجراء إداري.', Colors.red),
              _buildConditionTile('5. مُلغى:', 'تم إلغاء المبادرة لانتفاء الحاجة بقرار من إدارة المدرسة.', Colors.blueGrey),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            child: const Text('إغلاق'),
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
          Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontFamily: 'Cairo'),
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

  bool _matchesSelectedWeek(Map<String, dynamic> data) {
    if (_selectedFilterWeek == 0) return true;

    if (data['isContinuousUntilYearEnd'] == true) return true;

    if (data['startWeek'] != null) {
      int sW = data['startWeek'];
      int eW = data['endWeek'] ?? sW;
      if (_selectedFilterWeek >= sW && _selectedFilterWeek <= eW) return true;
    }

    if (data['executionWeek'] != null && data['executionWeek'] == _selectedFilterWeek) {
      return true;
    }

    if (data['startDate'] != null && data['endDate'] != null) {
      final sDate = DateTime.tryParse(data['startDate']);
      final eDate = DateTime.tryParse(data['endDate']);
      if (sDate != null && eDate != null) {
        final wStart = _getWeekStartDate(_selectedFilterWeek);
        final wEnd = _getWeekEndDate(_selectedFilterWeek);
        if (!(eDate.isBefore(wStart) || sDate.isAfter(wEnd))) {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildDaySection(String title, List<QueryDocumentSnapshot> dayDocs, Color color) {
    if (dayDocs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border(right: BorderSide(color: color, width: 4))),
            child: Text('$title (${dayDocs.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color, fontFamily: 'Cairo')),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(color.withOpacity(0.15)),
              border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              columns: const [
                DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('البرنامج / المبادرة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('التوقيت والأسابيع', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('المستهدفون (الصفوف)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('المنفذون', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('لجنة المتابعة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('الحالة (اضغط للتغيير)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo'))),
                DataColumn(label: Text('الزيارات والملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                DataColumn(label: Text('إجراء', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
              ],
              rows: dayDocs.map((doc) => _buildDataRow(doc)).toList(),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildDataRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final entry = OperationalPlanEntry.fromMap(doc.id, data);
    final String status = entry.status;
    final bool isPendingApproval = entry.isTeacherInitiated && !entry.isApprovedByAdmin;
    final Color badgeColor = isPendingApproval ? Colors.orange.shade800 : _getStatusBadgeColor(status);
    final visits = List<Map<String, dynamic>>.from(data['visitsLog'] ?? []);

    String durationStr = '';
    if (entry.isContinuousUntilYearEnd) {
      durationStr = 'مستمر طوال العام (52 أسبوع)';
    } else if (data['dateSelectionMode'] == 'weeks' || data['startWeek'] != null) {
      int sW = data['startWeek'] ?? 1;
      int eW = data['endWeek'] ?? sW;
      durationStr = sW == eW ? 'الأسبوع $sW' : 'من الأسبوع $sW إلى $eW';
    } else {
      durationStr = '${intl.DateFormat('MM/dd').format(entry.startDate)} - ${intl.DateFormat('MM/dd').format(entry.endDate)}';
    }

    String daysStr = entry.executionDays.isNotEmpty ? entry.executionDays.join('، ') : 'غير محدد';
    String periodsStr = entry.executionPeriods.isNotEmpty ? 'الحصص: ${entry.executionPeriods.join('، ')}' : 'غير محدد';

    return DataRow(
      cells: [
        DataCell(Text(entry.category, style: const TextStyle(fontFamily: 'Cairo'))),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.isCustomProgram ? Colors.red : Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              if (isPendingApproval)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                  child: const Text('مقترح بحاجة لاعتماد', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(durationStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              Text('$daysStr | $periodsStr', style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontFamily: 'Cairo')),
            ],
          ),
        ),
        DataCell(Text(entry.targetGrades.isEmpty ? entry.stage : entry.targetGrades.join('، '), style: const TextStyle(fontSize: 11, fontFamily: 'Cairo'))),
        DataCell(
          Wrap(
            spacing: 4,
            children: entry.executors.map((ex) {
              Color tColor = ex.hasApproved ? (ex.isCustom ? Colors.red : Colors.black87) : Colors.orange.shade700;
              String tName = ex.name + (ex.hasApproved ? '' : ' (بانتظار الموافقة)');
              return Text(tName, style: TextStyle(color: tColor, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo'));
            }).toList(),
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            children: entry.followUpCommittee.map((c) => Text(c.name, style: TextStyle(color: c.isCustom ? Colors.red : Colors.black87, fontSize: 11, fontFamily: 'Cairo'))).toList(),
          ),
        ),
        DataCell(
          InkWell(
            onTap: isPendingApproval ? null : () => _quickChangeStatus(doc.reference, status),
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: isPendingApproval ? 'بانتظار الاعتماد' : 'اضغط لتغيير الحالة فوراً',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: badgeColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isPendingApproval ? 'قيد المراجعة' : status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                    if (!isPendingApproval) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.note_add, size: 14),
                label: Text('زيارة (${visits.length})', style: const TextStyle(fontSize: 10, fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: visits.isNotEmpty ? Colors.teal : Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onPressed: () => _openAddVisitDialog(doc),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPendingApproval)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('تسكين', style: TextStyle(fontSize: 10, fontFamily: 'Cairo')),
                  onPressed: () => _openApproveTeacherInitiativeDialog(doc),
                ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1565C0), size: 18),
                onPressed: () => _openAddOrEditItemDialog(doc: doc),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedWeekStart = _getWeekStartDate(_selectedFilterWeek > 0 ? _selectedFilterWeek : 1);
    DateTime selectedWeekEnd = _getWeekEndDate(_selectedFilterWeek > 0 ? _selectedFilterWeek : 1);
    String selectedWeekRangeStr = '${intl.DateFormat('yyyy/MM/dd').format(selectedWeekStart)} - ${intl.DateFormat('yyyy/MM/dd').format(selectedWeekEnd)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخطة التشغيلية لمدير المدرسة 1448هـ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _collectionRef.where('status', isNotEqualTo: 'مكتمل').snapshots(),
            builder: (context, snapshot) {
              int alertCount = 0;
              if (snapshot.hasData) {
                final now = DateTime.now();
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['endDate'] != null && data['isContinuousUntilYearEnd'] != true) {
                    final endDate = DateTime.tryParse(data['endDate']);
                    if (endDate != null && (endDate.isBefore(now) || endDate.difference(now).inDays <= 2)) {
                      alertCount++;
                    }
                  }
                }
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active),
                    tooltip: 'البرامج المتأخرة والمنتهية',
                    onPressed: _showNotificationPanel,
                  ),
                  if (alertCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$alertCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.rule_folder),
            tooltip: 'ضوابط التنفيذ',
            onPressed: _showOfficialConditionsDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة برنامج للخطة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        onPressed: () => _openAddOrEditItemDialog(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF1565C0)),
                  tooltip: 'الأسبوع السابق',
                  onPressed: _selectedFilterWeek > 1
                      ? () => setState(() => _selectedFilterWeek--)
                      : null,
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedFilterWeek,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF1565C0)),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text('🌟 عرض جميع المبادرات (كامل السنة)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                      ),
                      ...List.generate(52, (index) {
                        int w = index + 1;
                        DateTime sDate = _getWeekStartDate(w);
                        DateTime eDate = _getWeekEndDate(w);
                        String sStr = intl.DateFormat('MM/dd').format(sDate);
                        String eStr = intl.DateFormat('MM/dd').format(eDate);
                        return DropdownMenuItem<int>(
                          value: w,
                          child: Text('الأسبوع $w ($sStr إلى $eStr)', style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFilterWeek = val);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF1565C0)),
                  tooltip: 'الأسبوع التالي',
                  onPressed: _selectedFilterWeek < 52
                      ? () => setState(() => _selectedFilterWeek++)
                      : null,
                ),
                TextButton(
                  onPressed: () => setState(() => _determineCurrentWeek()),
                  child: const Text('الأسبوع الحالي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
          ),
          if (_selectedFilterWeek > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.blue.shade100,
              child: Text(
                'مبادرات الأسبوع رقم $_selectedFilterWeek | المدة: $selectedWeekRangeStr',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo'),
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _collectionRef.orderBy('updatedAt', descending: true).snapshots(),
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
                        const Text('لم يتم تسجيل أي برامج في الخطة حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openAddOrEditItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أول برنامج الآن', style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                        )
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _matchesSelectedWeek(data);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('لا توجد مبادرات مسجلة في الأسبوع $_selectedFilterWeek', style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedFilterWeek = 0),
                          child: const Text('عرض جميع الأسابيع', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  );
                }

                Map<String, List<QueryDocumentSnapshot>> groupedPlans = {
                  'مستمر / طوال الأسبوع': [],
                  'الأحد': [],
                  'الإثنين': [],
                  'الثلاثاء': [],
                  'الأربعاء': [],
                  'الخميس': [],
                };

                for (var doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool isContinuous = data['isContinuousUntilYearEnd'] == true;
                  List<String> execDays = List<String>.from(data['executionDays'] ?? (data['executionDay'] != null ? [data['executionDay']] : []));

                  if (isContinuous || execDays.isEmpty) {
                    groupedPlans['مستمر / طوال الأسبوع']!.add(doc);
                  } else {
                    for (String day in execDays) {
                      if (groupedPlans.containsKey(day)) {
                        groupedPlans[day]!.add(doc);
                      } else {
                        groupedPlans['مستمر / طوال الأسبوع']!.add(doc);
                      }
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (groupedPlans['مستمر / طوال الأسبوع']!.isNotEmpty)
                        _buildDaySection('مستمر / طوال الأسبوع', groupedPlans['مستمر / طوال الأسبوع']!, Colors.purple),

                      _buildDaySection('الأحد', groupedPlans['الأحد']!, Colors.blue),
                      _buildDaySection('الإثنين', groupedPlans['الإثنين']!, Colors.teal),
                      _buildDaySection('الثلاثاء', groupedPlans['الثلاثاء']!, Colors.orange),
                      _buildDaySection('الأربعاء', groupedPlans['الأربعاء']!, Colors.red),
                      _buildDaySection('الخميس', groupedPlans['الخميس']!, Colors.green),

                      const SizedBox(height: 80),
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

// ===========================================================================
// 3. واجهة المعلمين لرفع البرامج والتراجع عنها
// ===========================================================================

class TeacherProgramsPage extends StatefulWidget {
  const TeacherProgramsPage({super.key});

  @override
  State<TeacherProgramsPage> createState() => _TeacherProgramsPageState();
}

class _TeacherProgramsPageState extends State<TeacherProgramsPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  String _teacherName = 'معلم';
  List<OperationalTeacherItem> _cloudTeachers = [];

  final List<String> _stagesList = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
  final Map<String, List<String>> _gradesByStage = {
    'المرحلة الابتدائية': ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'],
    'المرحلة المتوسطة': ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'],
    'المرحلة الثانوية': ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'],
  };

  final DateTime _schoolYearStart = DateTime(2026, 8, 30);
  int _selectedFilterWeek = 1;

  @override
  void initState() {
    super.initState();
    _determineCurrentWeek();
    _checkRoleAndLoadTeachers();
  }

  void _determineCurrentWeek() {
    final now = DateTime.now();
    if (now.isAfter(_schoolYearStart)) {
      int diffDays = now.difference(_schoolYearStart).inDays;
      int currentW = (diffDays / 7).floor() + 1;
      if (currentW >= 1 && currentW <= 52) {
        _selectedFilterWeek = currentW;
      }
    }
  }

  DateTime _getWeekStartDate(int week) {
    return _schoolYearStart.add(Duration(days: (week - 1) * 7));
  }

  DateTime _getWeekEndDate(int week) {
    return _schoolYearStart.add(Duration(days: ((week - 1) * 7) + 6));
  }

  Future<void> _checkRoleAndLoadTeachers() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        _isAdmin = d['profession'] == 'admin';
        _teacherName = d['name'] ?? 'معلم';
      }

      final teachersSnap = await FirebaseFirestore.instance.collection('users').get();
      List<OperationalTeacherItem> temp = [];
      for (var tDoc in teachersSnap.docs) {
        final td = tDoc.data();
        if (td['profession'] != 'admin' && td['name'] != null) {
          temp.add(OperationalTeacherItem(id: tDoc.id, name: td['name'], isCustom: false));
        }
      }
      if (mounted) setState(() => _cloudTeachers = temp);
    } catch (_) {}
  }

  Future<void> _deleteTeacherInitiative(DocumentSnapshot doc, String title) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('تراجع عن المبادرة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ],
        ),
        content: Text('هل أنت متأكد من رغبتك في سحب وحذف مبادرة "$title" نهائياً؟\n(متاح طالما لم يتم اعتمادها وتسكينها من الإدارة)', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await doc.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المبادرة والتراجع عنها بنجاح ✅'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _openCreateTeacherProgramDialog() {
    final all1000Programs = PlanStaticData.programsBank;
    String selectedProgramTitle = all1000Programs.first;
    bool isCustomProgram = false;
    final customProgramCtrl = TextEditingController();

    String selectedStage = _stagesList.first;
    List<String> selectedGrades = [];

    List<String> selectedDays = [PlanStaticData.daysOfWeek.first];
    List<int> selectedPeriods = [];

    List<OperationalTeacherItem> collaborators = [];
    final customCollabCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('اقتراح مبادرة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('اختر من الـ 1000 برنامج أو أضف برنامجك المخصص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: (!isCustomProgram && all1000Programs.contains(selectedProgramTitle)) ? selectedProgramTitle : null,
                        hint: const Text('اختر برنامجاً مقترحاً...', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        items: all1000Programs.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              selectedProgramTitle = val;
                              isCustomProgram = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customProgramCtrl,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              decoration: const InputDecoration(labelText: 'أو اكتب برنامجاً جديداً يدوياً (بالأحمر)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              if (customProgramCtrl.text.trim().isNotEmpty) {
                                setDlgState(() {
                                  selectedProgramTitle = customProgramCtrl.text.trim();
                                  isCustomProgram = true;
                                });
                              }
                            },
                            child: const Text('اعتماد يدوي', style: TextStyle(fontFamily: 'Cairo')),
                          )
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(),

                      const Text('المستهدفون من الطلاب (المرحلة والصفوف):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStage,
                        decoration: const InputDecoration(labelText: 'المرحلة', border: OutlineInputBorder(), isDense: true),
                        items: _stagesList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedStage = val);
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: (_gradesByStage[selectedStage] ?? []).map((grade) {
                          final isSelected = selectedGrades.contains(grade);
                          return FilterChip(
                            label: Text(grade, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                            selected: isSelected,
                            onSelected: (sel) {
                              setDlgState(() {
                                if (sel) {
                                  selectedGrades.add(grade);
                                } else {
                                  selectedGrades.remove(grade);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),
                      const Divider(),

                      const Text('أيام التنفيذ المقترحة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: PlanStaticData.daysOfWeek.map((day) {
                          return FilterChip(
                            label: Text(day, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedDays.contains(day),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) selectedDays.add(day);
                                else selectedDays.remove(day);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('الحصص المقترحة للتنفيذ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: List.generate(8, (i) => i + 1).map((period) {
                          return FilterChip(
                            label: Text('الحصة $period', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedPeriods.contains(period),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) selectedPeriods.add(period);
                                else selectedPeriods.remove(period);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),
                      const Divider(),

                      const Text('معلمون متعاونون معك في البرنامج:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<OperationalTeacherItem>(
                        decoration: const InputDecoration(labelText: 'اختر معلماً متعاوناً...', border: OutlineInputBorder(), isDense: true),
                        items: _cloudTeachers.map((t) => DropdownMenuItem(value: t, child: Text(t.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)))).toList(),
                        onChanged: (t) {
                          if (t != null && !collaborators.any((c) => c.name == t.name)) {
                            setDlgState(() => collaborators.add(OperationalTeacherItem(id: t.id, name: t.name, isCustom: false, hasApproved: false)));
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customCollabCtrl,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              decoration: const InputDecoration(labelText: 'أو أضف معلماً متعاوناً يدوياً (بالأحمر)', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              if (customCollabCtrl.text.trim().isNotEmpty) {
                                setDlgState(() {
                                  collaborators.add(OperationalTeacherItem(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: customCollabCtrl.text.trim(),
                                    isCustom: true,
                                    hasApproved: true,
                                  ));
                                  customCollabCtrl.clear();
                                });
                              }
                            },
                            child: const Text('إضافة'),
                          )
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        children: collaborators.map((c) => Chip(
                          backgroundColor: c.isCustom ? Colors.red.shade100 : Colors.blue.shade50,
                          label: Text(c.name, style: TextStyle(color: c.isCustom ? Colors.red.shade900 : Colors.blue.shade900, fontFamily: 'Cairo', fontSize: 11)),
                          onDeleted: () => setDlgState(() => collaborators.remove(c)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (selectedProgramTitle.isEmpty) return;

                    List<OperationalTeacherItem> executorsList = [
                      OperationalTeacherItem(id: user!.uid, name: _teacherName, isCustom: false, hasApproved: true),
                      ...collaborators
                    ];

                    Map<String, bool> approvalsMap = {
                      user!.uid: true,
                    };
                    for (var c in collaborators) {
                      if (!c.isCustom) {
                        approvalsMap[c.id] = false;
                      }
                    }

                    List<String> executorsIdsList = [user!.uid, ...collaborators.map((c) => c.id)];

                    final newProgramEntry = OperationalPlanEntry(
                      title: selectedProgramTitle,
                      category: 'مبادرة معلّم',
                      isCustomProgram: isCustomProgram,
                      stage: selectedStage,
                      targetGrades: selectedGrades,
                      startDate: DateTime.now(),
                      endDate: DateTime.now().add(const Duration(days: 7)),
                      isContinuousUntilYearEnd: false,
                      executionDays: selectedDays,
                      executionPeriods: selectedPeriods,
                      executorsIds: executorsIdsList,
                      collaboratorApprovals: approvalsMap,
                      executors: executorsList,
                      followUpCommittee: [],
                      status: 'بانتظار موافقة الإدارة',
                      notes: 'مقترح تم رفعه من المعلم لانتظار التسكين',
                      isTeacherInitiated: true,
                      teacherId: user!.uid,
                      teacherName: _teacherName,
                      isApprovedByAdmin: false,
                    );

                    final dataMap = newProgramEntry.toMap();
                    dataMap['updatedAt'] = FieldValue.serverTimestamp();

                    // 1. إضافة المبادرة
                    await FirebaseFirestore.instance.collection('school_operational_plan_1448').add(dataMap);

                    // 2. إرسال إشعارات للزملاء المتعاونين
                    if (collaborators.isNotEmpty) {
                      final batch = FirebaseFirestore.instance.batch();
                      for (var collab in collaborators) {
                        if (!collab.isCustom) {
                          final notifRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(collab.id)
                              .collection('notifications')
                              .doc();
                          batch.set(notifRef, {
                            'title': '🤝 طلب تعاون في مبادرة',
                            'message': 'قام أ. $_teacherName بإضافتك كمتعاون في مبادرة "$selectedProgramTitle". يرجى مراجعة برامجك للموافقة أو الرفض.',
                            'timestamp': FieldValue.serverTimestamp(),
                            'isRead': false,
                          });
                        }
                      }
                      await batch.commit();
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البرنامج بنجاح إلى لوحة المدير وإشعار الزملاء! ✅'), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text('إرسال البرنامج للمدير', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDaySection(String title, List<QueryDocumentSnapshot> dayDocs, Color color) {
    if (dayDocs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border(right: BorderSide(color: color, width: 4))),
            child: Text('$title (${dayDocs.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color, fontFamily: 'Cairo')),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayDocs.length,
            itemBuilder: (context, idx) {
              final doc = dayDocs[idx];
              final data = doc.data() as Map<String, dynamic>;
              final entry = OperationalPlanEntry.fromMap(doc.id, data);

              final bool isApproved = data['isApprovedByAdmin'] ?? false;
              final String titleText = entry.title;
              final bool isCustomProgram = entry.isCustomProgram;
              final String teacher = entry.teacherName ?? '';
              final String status = entry.status;
              final String exWeek = entry.executionWeek?.toString() ?? '-';
              final String exDaysStr = entry.executionDays.isNotEmpty ? entry.executionDays.join('، ') : '-';
              final String exPeriodsStr = entry.executionPeriods.isNotEmpty ? entry.executionPeriods.join('، ') : '-';

              final bool isMyOwnInitiative = entry.teacherId == user?.uid;
              final bool needsMyApproval = entry.executors.any((ex) => ex.id == user?.uid && !ex.hasApproved);
              final bool hasPendingOthers = entry.executors.any((ex) => !ex.hasApproved);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isApproved ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isApproved ? Colors.green.shade100 : Colors.amber.shade100,
                            child: Icon(isApproved ? Icons.verified : Icons.hourglass_top, color: isApproved ? Colors.green : Colors.amber.shade800),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleText,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isCustomProgram ? Colors.red : Colors.black87, fontFamily: 'Cairo', fontSize: 15),
                                ),
                                Text('المبادر: $teacher | الحالة: $status', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                                if (isApproved)
                                  Text('الأسبوع $exWeek | الأيام: $exDaysStr | الحصص: $exPeriodsStr', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isApproved ? Colors.green.shade50 : Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text(isApproved ? 'معتمد' : 'بانتظار الإدارة', style: TextStyle(color: isApproved ? Colors.green.shade800 : Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                          ),
                        ],
                      ),

                      // زر التراجع والحذف لصاحب المبادرة طالما لم تعتمد
                      if (isMyOwnInitiative && !isApproved) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المبادرة قيد المراجعة ويمكنك التراجع عنها:', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('تراجع وحذف المبادرة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                              onPressed: () => _deleteTeacherInitiative(doc, titleText),
                            ),
                          ],
                        )
                      ],

                      // منطقة موافقة أو رفض الزميل المتعاون
                      if (hasPendingOthers || needsMyApproval) ...[
                        const Divider(),
                        if (hasPendingOthers && !needsMyApproval)
                          const Text('بانتظار موافقة بعض الزملاء المتعاونين قبل التسكين.', style: TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        if (needsMyApproval) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('موافقة على التعاون', style: TextStyle(fontFamily: 'Cairo')),
                                  onPressed: () async {
                                    final updatedExecutors = entry.executors.map((e) {
                                      if (e.id == user?.uid) {
                                        return OperationalTeacherItem(id: e.id, name: e.name, isCustom: e.isCustom, hasApproved: true);
                                      }
                                      return e;
                                    }).toList();

                                    final updatedApprovals = Map<String, bool>.from(entry.collaboratorApprovals);
                                    if (user != null) updatedApprovals[user!.uid] = true;

                                    await doc.reference.update({
                                      'executors': updatedExecutors.map((e) => e.toMap()).toList(),
                                      'collaboratorApprovals': updatedApprovals,
                                    });

                                    // إشعار صاحب المبادرة بالموافقة
                                    if (entry.teacherId != null) {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(entry.teacherId)
                                          .collection('notifications')
                                          .add({
                                        'title': '🤝 موافقة زميل متعاون',
                                        'message': 'وافق أ. $_teacherName على الانضمام لمبادرتك "${entry.title}".',
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'isRead': false,
                                      });
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة على التعاون في المبادرة بنجاح! ✅'), backgroundColor: Colors.green));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text('اعتذار / رفض', style: TextStyle(fontFamily: 'Cairo')),
                                onPressed: () async {
                                  // إزالة المعلم المعتذر من قائمة المنفذين
                                  final updatedExecutors = entry.executors.where((e) => e.id != user?.uid).toList();
                                  final updatedExecutorsIds = entry.executorsIds.where((id) => id != user?.uid).toList();
                                  final updatedApprovals = Map<String, bool>.from(entry.collaboratorApprovals)..remove(user?.uid);

                                  await doc.reference.update({
                                    'executors': updatedExecutors.map((e) => e.toMap()).toList(),
                                    'executorsIds': updatedExecutorsIds,
                                    'collaboratorApprovals': updatedApprovals,
                                  });

                                  // إشعار صاحب المبادرة بالاعتذار
                                  if (entry.teacherId != null) {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(entry.teacherId)
                                        .collection('notifications')
                                        .add({
                                      'title': '⚠️ اعتذار زميل عن مبادرة',
                                      'message': 'اعتذر أ. $_teacherName عن التعاون في مبادرتك "${entry.title}".',
                                      'timestamp': FieldValue.serverTimestamp(),
                                      'isRead': false,
                                    });
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاعتذار واستبعادك من المبادرة.'), backgroundColor: Colors.orange));
                                  }
                                },
                              ),
                            ],
                          ),
                        ]
                      ]
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('school_operational_plan_1448').where('isTeacherInitiated', isEqualTo: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مبادرات وبرامج المعلمين', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00796B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('اقتراح برنامج جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        onPressed: _openCreateTeacherProgramDialog,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF00796B)),
                  tooltip: 'الأسبوع السابق',
                  onPressed: _selectedFilterWeek > 1
                      ? () => setState(() => _selectedFilterWeek--)
                      : null,
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedFilterWeek,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF00796B)),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text('🌟 عرض جميع المبادرات (كامل السنة)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                      ),
                      ...List.generate(52, (index) {
                        int w = index + 1;
                        DateTime sDate = _getWeekStartDate(w);
                        DateTime eDate = _getWeekEndDate(w);
                        String sStr = intl.DateFormat('MM/dd').format(sDate);
                        String eStr = intl.DateFormat('MM/dd').format(eDate);
                        return DropdownMenuItem<int>(
                          value: w,
                          child: Text('الأسبوع $w ($sStr إلى $eStr)', style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFilterWeek = val);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF00796B)),
                  tooltip: 'الأسبوع التالي',
                  onPressed: _selectedFilterWeek < 52
                      ? () => setState(() => _selectedFilterWeek++)
                      : null,
                ),
                TextButton(
                  onPressed: () => setState(() => _determineCurrentWeek()),
                  child: const Text('الأسبوع الحالي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد برامج مسجلة للمعلمين حالياً.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 16)));
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (!_isAdmin && user != null) {
                    bool isMine = data['teacherId'] == user!.uid;
                    List executors = data['executors'] as List? ?? [];
                    bool isCollab = executors.any((ex) => ex['id'] == user!.uid);
                    if (!isMine && !isCollab) return false;
                  }
                  return _matchesSelectedWeek(data);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('لا توجد مبادرات مسجلة في الأسبوع $_selectedFilterWeek', style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: () => setState(() => _selectedFilterWeek = 0),
                          child: const Text('عرض جميع الأسابيع', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                Map<String, List<QueryDocumentSnapshot>> groupedPlans = {
                  'مستمر / طوال الأسبوع': [],
                  'الأحد': [],
                  'الإثنين': [],
                  'الثلاثاء': [],
                  'الأربعاء': [],
                  'الخميس': [],
                };

                for (var doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool isContinuous = data['isContinuousUntilYearEnd'] == true;
                  List<String> execDays = List<String>.from(data['executionDays'] ?? (data['executionDay'] != null ? [data['executionDay']] : []));

                  if (isContinuous || execDays.isEmpty) {
                    groupedPlans['مستمر / طوال الأسبوع']!.add(doc);
                  } else {
                    for (String day in execDays) {
                      if (groupedPlans.containsKey(day)) {
                        groupedPlans[day]!.add(doc);
                      } else {
                        groupedPlans['مستمر / طوال الأسبوع']!.add(doc);
                      }
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (groupedPlans['مستمر / طوال الأسبوع']!.isNotEmpty)
                        _buildDaySection('مستمر / طوال الأسبوع', groupedPlans['مستمر / طوال الأسبوع']!, Colors.purple),

                      _buildDaySection('الأحد', groupedPlans['الأحد']!, Colors.blue),
                      _buildDaySection('الإثنين', groupedPlans['الإثنين']!, Colors.teal),
                      _buildDaySection('الثلاثاء', groupedPlans['الثلاثاء']!, Colors.orange),
                      _buildDaySection('الأربعاء', groupedPlans['الأربعاء']!, Colors.red),
                      _buildDaySection('الخميس', groupedPlans['الخميس']!, Colors.green),

                      const SizedBox(height: 80),
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

  bool _matchesSelectedWeek(Map<String, dynamic> data) {
    if (_selectedFilterWeek == 0) return true;

    if (data['isContinuousUntilYearEnd'] == true) return true;

    if (data['startWeek'] != null) {
      int sW = data['startWeek'];
      int eW = data['endWeek'] ?? sW;
      if (_selectedFilterWeek >= sW && _selectedFilterWeek <= eW) return true;
    }

    if (data['executionWeek'] != null && data['executionWeek'] == _selectedFilterWeek) {
      return true;
    }

    if (data['startDate'] != null && data['endDate'] != null) {
      final sDate = DateTime.tryParse(data['startDate']);
      final eDate = DateTime.tryParse(data['endDate']);
      if (sDate != null && eDate != null) {
        final wStart = _getWeekStartDate(_selectedFilterWeek);
        final wEnd = _getWeekEndDate(_selectedFilterWeek);
        if (!(eDate.isBefore(wStart) || sDate.isAfter(wEnd))) {
          return true;
        }
      }
    }

    return false;
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