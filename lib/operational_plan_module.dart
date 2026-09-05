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
  final String? executionDay;
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
    this.executionDay,
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
    'executionDay': executionDay,
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
      executionDay: map['executionDay'],
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
  List<String> _cloudCategories = ['فعالية', 'مبادرة', 'قيمة', 'إجراء مدرسي يومي'];

  final List<String> _stagesList = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
  final Map<String, List<String>> _gradesByStage = {
    'المرحلة الابتدائية': ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'],
    'المرحلة المتوسطة': ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'],
    'المرحلة الثانوية': ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'],
  };

  final DateTime _schoolYearStart = DateTime(2026, 8, 30);
  int _selectedFilterWeek = 1;
  String _selectedFilterDay = 'الكل';

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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('plan_categories').get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _cloudCategories = List<String>.from(doc.data()!['categories'] ?? _cloudCategories);
        });
      }
    } catch (_) {}
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
        return Colors.teal.shade600;
      case 'لم يُنفذ':
      case 'لم ينفذ':
        return Colors.red.shade400;
      case 'مُرحّل':
      case 'رُحّل':
        return Colors.orange.shade600;
      case 'مُلغى':
      case 'ألغي':
        return Colors.blueGrey.shade400;
      case 'تحت الإجراء':
      default:
        return Colors.blue.shade600;
    }
  }

  Future<void> _changeAdminPinDialog() async {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.password, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text('تغيير الرمز السري للإدارة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الرمز الحالي', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الرمز الجديد', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.blueGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              onPressed: () async {
                final doc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
                final actualPin = doc.data()?['admin_pin']?.toString() ?? '010';
                if (currentPinCtrl.text.trim() == actualPin && newPinCtrl.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('settings').doc('guest_access').set({
                    'admin_pin': newPinCtrl.text.trim()
                  }, SetOptions(merge: true));
                  if(mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الرمز السري بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
                  }
                } else {
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز الحالي غير صحيح أو الحقل الجديد فارغ', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                }
              },
              child: const Text('تغيير وحفظ', style: TextStyle(fontFamily: 'Cairo')),
            )
          ],
        )
    );
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
                  title: Text(st, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo', color: Colors.blueGrey.shade800)),
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
            content: Text('تم تغيير حالة الإجراء إلى: $selected بنجاح!', style: const TextStyle(fontFamily: 'Cairo')),
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
                  Icon(Icons.fact_check_rounded, color: Colors.teal.shade700),
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
                        const Text('سجل الزيارات السابقة للمبادرة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        ...visits.map((v) => Card(
                          color: Colors.grey.shade50,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.verified, color: Colors.teal.shade600, size: 20),
                            title: Text('${v['type']} - ${v['visitorName'] ?? 'المدير'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo', color: Colors.black87)),
                            subtitle: Text('${v['notes']}\nالتاريخ: ${v['timestamp'] ?? ''}', style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.black54)),
                          ),
                        )),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', color: Colors.blueGrey))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('حفظ الزيارة الآن', style: TextStyle(fontFamily: 'Cairo')),
                  onPressed: () async {
                    if (notesCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة ملاحظات الزيارة', style: TextStyle(fontFamily: 'Cairo'))));
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تدوين الزيارة وحفظها بالمبادرة بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
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
                  const Text('إشعارات البرامج المتأخرة والمنتهية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.blueGrey)),
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
                        child: Text('رائع! لا توجد برامج متأخرة أو تحتاج إقفال فوري.', style: TextStyle(fontFamily: 'Cairo', color: Colors.teal, fontWeight: FontWeight.bold)),
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
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isLate ? Colors.red.shade200 : Colors.orange.shade200)),
                          color: isLate ? Colors.red.shade50 : Colors.orange.shade50,
                          child: ListTile(
                            leading: Icon(isLate ? Icons.warning_rounded : Icons.timer, color: isLate ? Colors.red : Colors.orange),
                            title: Text(m['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            subtitle: Text(
                              isLate ? 'متأخر! انتهت المدة في: ${intl.DateFormat('yyyy/MM/dd').format(endDate)}' : 'شارف على الانتهاء ويحتاج إلى إغلاق',
                              style: TextStyle(color: isLate ? Colors.red.shade800 : Colors.orange.shade800, fontSize: 12, fontFamily: 'Cairo'),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0),
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

  void _openAddOrEditItemDialog({DocumentSnapshot? doc}) {
    final Map<String, dynamic> data = doc != null ? (doc.data() as Map<String, dynamic>) : {};

    String selectedCategory = data['category'] ?? _cloudCategories.first;
    if (!_cloudCategories.contains(selectedCategory)) {
      if (_cloudCategories.isNotEmpty) selectedCategory = _cloudCategories.first;
    }

    final customCategoryCtrl = TextEditingController();

    String selectedProgramTitle = data['title'] ?? '';
    bool isCustomProgram = data['isCustomProgram'] ?? false;
    final customProgramCtrl = TextEditingController(text: selectedProgramTitle);

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
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(doc == null ? 'إضافة مبادرة تشغيلية جديدة' : 'تعديل / إقفال المبادرة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1565C0))),
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
                        value: _cloudCategories.contains(selectedCategory) ? selectedCategory : null,
                        decoration: const InputDecoration(labelText: 'نوع البند *', border: OutlineInputBorder(), isDense: true),
                        items: _cloudCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customCategoryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'أو إضافة بند جديد للسحابة',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0),
                            onPressed: () async {
                              String newCat = customCategoryCtrl.text.trim();
                              if (newCat.isNotEmpty && !_cloudCategories.contains(newCat)) {
                                setDlgState(() {
                                  _cloudCategories.add(newCat);
                                  selectedCategory = newCat;
                                  customCategoryCtrl.clear();
                                });
                                await FirebaseFirestore.instance.collection('settings').doc('plan_categories').set({
                                  'categories': FieldValue.arrayUnion([newCat])
                                }, SetOptions(merge: true));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسحابة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
                                }
                              }
                            },
                            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: customProgramCtrl,
                        onChanged: (val) {
                          selectedProgramTitle = val.trim();
                          isCustomProgram = false;
                        },
                        decoration: const InputDecoration(
                          labelText: 'اسم البرنامج / المبادرة *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const Text('تحديد توقيت المبادرة (نظام الـ 52 أسبوعاً أو بالأيام):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Color(0xFF1565C0))),
                      const SizedBox(height: 8),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('مستمر لنهاية العام الدراسي (كامل الـ 52 أسبوعاً)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13, color: Colors.black87)),
                        value: isContinuous,
                        activeColor: const Color(0xFF1565C0),
                        onChanged: (v) => setDlgState(() => isContinuous = v ?? false),
                      ),

                      if (!isContinuous) ...[
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('تحديد بنظام الأسابيع (52 أسبوع)', style: TextStyle(fontFamily: 'Cairo')),
                              selected: dateSelectionMode == 'weeks',
                              selectedColor: Colors.blue.shade100,
                              onSelected: (val) => setDlgState(() => dateSelectionMode = 'weeks'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('تحديد بالتواريخ الدقيقة (باليوم)', style: TextStyle(fontFamily: 'Cairo')),
                              selected: dateSelectionMode == 'days',
                              selectedColor: Colors.blue.shade100,
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
                                  decoration: const InputDecoration(labelText: 'من الأسبوع', border: OutlineInputBorder(), isDense: true),
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
                                  decoration: const InputDecoration(labelText: 'إلى الأسبوع', border: OutlineInputBorder(), isDense: true),
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
                      const Text('أيام التنفيذ المحددة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Colors.blueGrey)),
                      Wrap(
                        spacing: 8,
                        children: PlanStaticData.daysOfWeek.map((day) {
                          return FilterChip(
                            label: Text(day, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedDays.contains(day),
                            selectedColor: Colors.blue.shade100,
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

                      const Text('الحصص المحددة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Colors.blueGrey)),
                      Wrap(
                        spacing: 8,
                        children: List.generate(8, (i) => i + 1).map((period) {
                          return FilterChip(
                            label: Text('الحصة $period', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            selected: selectedPeriods.contains(period),
                            selectedColor: Colors.blue.shade100,
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
                        decoration: const InputDecoration(labelText: 'المرحلة الدراسية', border: OutlineInputBorder(), isDense: true),
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
                            selectedColor: Colors.blue.shade100,
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
                          _buildStatusOption('تحت الإجراء', Icons.sync, Colors.blue.shade600, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('مكتمل', Icons.check_circle, Colors.teal.shade600, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('مُرحّل', Icons.next_plan, Colors.orange.shade600, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('لم يُنفذ', Icons.cancel, Colors.red.shade600, executionStatus, (v) => setDlgState(() => executionStatus = v)),
                          _buildStatusOption('مُلغى', Icons.block, Colors.blueGrey.shade600, executionStatus, (v) => setDlgState(() => executionStatus = v)),
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
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
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
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey, fontFamily: 'Cairo'))),
                if (doc != null)
                  TextButton(
                    onPressed: () async {
                      await doc.reference.delete();
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0),
                  onPressed: () async {
                    selectedProgramTitle = customProgramCtrl.text.trim();
                    if (selectedProgramTitle.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار أو كتابة مسمى البرنامج', style: TextStyle(fontFamily: 'Cairo'))));
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0),
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
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0),
                          onPressed: () {
                            if (ctrl.text.trim().isNotEmpty) {
                              onAddCustom(ctrl.text.trim());
                              Navigator.pop(c);
                            }
                          },
                          child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
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
              backgroundColor: t.isCustom ? Colors.red.shade50 : Colors.blue.shade50,
              label: Text(t.name, style: TextStyle(color: t.isCustom ? Colors.red.shade800 : Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
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
              _buildConditionTile('1. تحت الإجراء:', 'البرنامج قيد التنفيذ والمتابعة حالياً ضمن مدته الزمنية.', Colors.blue.shade600),
              _buildConditionTile('2. مكتمل:', 'تم إنجاز المبادرة وتحقيق المستهدفات التربوية وإقفالها نظامياً.', Colors.teal.shade600),
              _buildConditionTile('3. مُرحّل:', 'تم تمديد فترة البرنامج أو جدولته لموعد لاحق.', Colors.orange.shade600),
              _buildConditionTile('4. لم يُنفذ:', 'انقضت المدة المحددة دون تنفيذ وتتطلب اتخاذ إجراء إداري.', Colors.red.shade600),
              _buildConditionTile('5. مُلغى:', 'تم إلغاء المبادرة لانتفاء الحاجة بقرار من إدارة المدرسة.', Colors.blueGrey.shade600),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
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
            decoration: BoxDecoration(color: color.withOpacity(0.05), border: Border(right: BorderSide(color: color.withOpacity(0.8), width: 4))),
            child: Text('$title (${dayDocs.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color, fontFamily: 'Cairo')),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 55,
                columnSpacing: 16,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                columns: const [
                  DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('البرنامج / المبادرة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('التوقيت والأسابيع', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('المستهدفون', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('المنفذون', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('لجنة المتابعة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('الحالة (تغيير سريع)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo', fontSize: 12))),
                  DataColumn(label: Text('الزيارات والملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                  DataColumn(label: Text('إجراء', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey))),
                ],
                rows: dayDocs.map((doc) => _buildDataRow(doc)).toList(),
              ),
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
    final Color badgeColor = isPendingApproval ? Colors.orange.shade400 : _getStatusBadgeColor(status);
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
        DataCell(Text(entry.category, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11))),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: entry.isCustomProgram ? Colors.red.shade800 : Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              if (isPendingApproval)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text('مقترح بحاجة لاعتماد', style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(durationStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.blueGrey)),
              Text('$daysStr | $periodsStr', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
            ],
          ),
        ),
        DataCell(Text(entry.targetGrades.isEmpty ? entry.stage : entry.targetGrades.join('، '), style: const TextStyle(fontSize: 11, fontFamily: 'Cairo'))),
        DataCell(
          Wrap(
            spacing: 4,
            children: entry.executors.map((ex) {
              Color tColor = ex.hasApproved ? (ex.isCustom ? Colors.red.shade600 : Colors.black87) : Colors.orange.shade600;
              String tName = ex.name + (ex.hasApproved ? '' : ' (بانتظار الموافقة)');
              return Text(tName, style: TextStyle(color: tColor, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Cairo'));
            }).toList(),
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            children: entry.followUpCommittee.map((c) => Text(c.name, style: TextStyle(color: c.isCustom ? Colors.red.shade600 : Colors.black87, fontSize: 10, fontFamily: 'Cairo'))).toList(),
          ),
        ),
        DataCell(
          InkWell(
            onTap: isPendingApproval ? null : () => _quickChangeStatus(doc.reference, status),
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: isPendingApproval ? 'بانتظار الاعتماد' : 'اضغط لتغيير الحالة فوراً',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isPendingApproval ? 'قيد المراجعة' : status, style: TextStyle(color: badgeColor.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                    if (!isPendingApproval) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: badgeColor.withOpacity(0.9), size: 16),
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
                icon: const Icon(Icons.note_add, size: 12),
                label: Text('زيارة (${visits.length})', style: const TextStyle(fontSize: 10, fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: visits.isNotEmpty ? Colors.teal.shade50 : Colors.blueGrey.shade50,
                  foregroundColor: visits.isNotEmpty ? Colors.teal.shade800 : Colors.blueGrey.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 0,
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, foregroundColor: Colors.green.shade800, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), elevation: 0),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('تسكين', style: TextStyle(fontSize: 10, fontFamily: 'Cairo')),
                  onPressed: () {}, // _openApproveTeacherInitiativeDialog(doc), // Removed undefined call
                ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1565C0), size: 16),
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
        title: const Text('الخطة التشغيلية لمدير المدرسة 1448هـ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.password),
            tooltip: 'تغيير الرقم السري للإدارة',
            onPressed: _changeAdminPinDialog,
          ),
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
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text('إضافة برنامج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
        onPressed: () => _openAddOrEditItemDialog(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF1565C0), size: 18),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text('🌟 عرض جميع المبادرات (كامل السنة)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                      ),
                      ...List.generate(52, (index) {
                        int w = index + 1;
                        DateTime sDate = _getWeekStartDate(w);
                        DateTime eDate = _getWeekEndDate(w);
                        String sStr = intl.DateFormat('MM/dd').format(sDate);
                        String eStr = intl.DateFormat('MM/dd').format(eDate);
                        return DropdownMenuItem<int>(
                          value: w,
                          child: Text('الأسبوع $w ($sStr إلى $eStr)', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
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
                  child: const Text('الأسبوع الحالي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11)),
                )
              ],
            ),
          ),

          if (_selectedFilterWeek > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  ActionChip(
                    label: Text('الكل', style: TextStyle(color: _selectedFilterDay == 'الكل' ? Colors.white : Colors.black87, fontSize: 11, fontFamily: 'Cairo')),
                    backgroundColor: _selectedFilterDay == 'الكل' ? Colors.blueGrey.shade700 : Colors.grey.shade200,
                    onPressed: () => setState(() => _selectedFilterDay = 'الكل'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                      avatar: Icon(Icons.today, size: 14, color: _selectedFilterDay != 'الكل' ? Colors.white : Colors.black87),
                      label: Text('اليوم الحالي', style: TextStyle(color: _selectedFilterDay != 'الكل' ? Colors.white : Colors.black87, fontSize: 11, fontFamily: 'Cairo')),
                      backgroundColor: _selectedFilterDay != 'الكل' ? Colors.blueGrey.shade700 : Colors.grey.shade200,
                      onPressed: () {
                        String todayName = intl.DateFormat('EEEE', 'ar').format(DateTime.now());
                        if (PlanStaticData.daysOfWeek.contains(todayName)) {
                          setState(() => _selectedFilterDay = todayName);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اليوم إجازة', style: TextStyle(fontFamily: 'Cairo'))));
                        }
                      }
                  ),
                  const Spacer(),
                  Text(
                    'مبادرات الأسبوع $_selectedFilterWeek | $selectedWeekRangeStr',
                    style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Cairo'),
                  ),
                ],
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
                        Icon(Icons.post_add, size: 70, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('لم يتم تسجيل أي برامج في الخطة حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openAddOrEditItemDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('إضافة أول برنامج الآن', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0),
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
                        Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('لا توجد مبادرات مسجلة في الأسبوع $_selectedFilterWeek', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedFilterWeek = 0),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade900, elevation: 0),
                          child: const Text('عرض جميع الأسابيع', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
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
                      if ((_selectedFilterDay == 'الكل' || _selectedFilterDay == 'مستمر / طوال الأسبوع') && groupedPlans['مستمر / طوال الأسبوع']!.isNotEmpty)
                        _buildDaySection('مستمر / طوال الأسبوع', groupedPlans['مستمر / طوال الأسبوع']!, Colors.blueGrey),

                      if ((_selectedFilterDay == 'الكل' || _selectedFilterDay == 'الأحد') && groupedPlans['الأحد']!.isNotEmpty)
                        _buildDaySection('الأحد', groupedPlans['الأحد']!, Colors.blueGrey),

                      if ((_selectedFilterDay == 'الكل' || _selectedFilterDay == 'الإثنين') && groupedPlans['الإثنين']!.isNotEmpty)
                        _buildDaySection('الإثنين', groupedPlans['الإثنين']!, Colors.blueGrey),

                      if ((_selectedFilterDay == 'الكل' || _selectedFilterDay == 'الثلاثاء') && groupedPlans['الثلاثاء']!.isNotEmpty)
                        _buildDaySection('الثلاثاء', groupedPlans['الثلاثاء']!, Colors.blueGrey),

                      if ((_selectedFilterDay == 'الكل' || _selectedFilterDay == 'الأربعاء') && groupedPlans['الأربعاء']!.isNotEmpty)
                        _buildDaySection('الأربعاء', groupedPlans['الأربعاء']!, Colors.blueGrey),

                      if ((_selectedFilterDay == 'الكل' || _selectedFilterDay == 'الخميس') && groupedPlans['الخميس']!.isNotEmpty)
                        _buildDaySection('الخميس', groupedPlans['الخميس']!, Colors.blueGrey),

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