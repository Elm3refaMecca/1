import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;

// --- new imports for Excel export ---
import 'dart:io';
import 'package:excel/excel.dart' hide Border; // IMPORTANT: 'hide Border' resolves the conflict error.
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';


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
  final Map<String, int> _likes = {};
  final Map<String, int> _dislikes = {};

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
      for (var studentDoc in students) {
        final data = studentDoc.data() as Map<String, dynamic>?;
        final studentId = studentDoc.id;
        final score = data?[widget.testFieldKey];
        grades[studentId] = score;

        _likes[studentId] = data?['totalLikes'] ?? 0;
        _dislikes[studentId] = data?['totalDislikes'] ?? 0;
      }

      if (mounted) {
        setState(() {
          _students = students;
          _grades = grades;
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

  Future<String?> _showDislikeDialog(String studentName) async {
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('ملاحظة سلوكية على: $studentName'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: noteController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'سبب الملاحظة',
                hintText: 'مثال: يتحدث مع زميله أثناء الشرح',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء كتابة سبب الملاحظة';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(noteController.text.trim());
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBehaviorReport(String studentId, String studentName, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? teacherNote;
    if (type == 'dislike') {
      teacherNote = await _showDislikeDialog(studentName);
      if (teacherNote == null) return; // User cancelled the dialog
    }

    try {
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      final teacherName = teacherDoc.data()?['name'] ?? 'معلم غير معروف';
      final now = DateTime.now();
      final dayName = intl.DateFormat('EEEE', 'ar').format(now);

      final studentRef = _firestore.collection('students').doc(studentId);
      final reportRef = _firestore.collection('behavior_reports').doc();
      final notificationRef = _firestore.collection('students').doc(studentId).collection('notifications').doc();


      final reportData = {
        'studentId': studentId,
        'studentName': studentName,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'subject': widget.subject,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'dateString': intl.DateFormat('yyyy/MM/dd').format(now),
        'dayName': dayName,
        if (type == 'dislike') 'teacherNote': teacherNote,
        if (type == 'dislike') 'studentReply': null,
        if (type == 'dislike') 'replyTimestamp': null,
        'status': 'pending_reply',
      };

      String notificationMessage;
      if (type == 'like') {
        notificationMessage = 'أحسنت! أضاف لك أ. $teacherName نقطة سلوك نبيل في مادة ${widget.subject}.';
      } else {
        notificationMessage = 'تنبيه: تم تسجيل ملاحظة سلوكية عليك من قبل أ. $teacherName في مادة ${widget.subject}.';
      }

      await _firestore.runTransaction((transaction) async {
        transaction.update(studentRef, {
          type == 'like' ? 'totalLikes' : 'totalDislikes': FieldValue.increment(1),
        });
        transaction.set(reportRef, reportData);
        transaction.set(notificationRef, {
          'message': notificationMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
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
          content: Text(type == 'like' ? 'تم تسجيل الإعجاب بنجاح' : 'تم تسجيل الملاحظة وإرسال الإشعارات بنجاح'),
          backgroundColor: Colors.green,
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

  Future<void> _showGradeDialog(String studentId, String studentName, dynamic currentGrade) async {
    final gradeController = TextEditingController(text: currentGrade?.toString() ?? '');

    final bool isNafes = widget.testFieldKey.contains('profession13');
    final double maxGrade = isNafes ? 10.0 : 20.0;
    final double passingGrade = isNafes ? 5.0 : 10.0;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('رصد درجة: $studentName'),
          content: TextField(
            controller: gradeController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final num? value = num.tryParse(newValue.text);
                if (value != null && value > maxGrade) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            decoration: InputDecoration(
              labelText: 'الدرجة',
              hintText: 'أدخل الدرجة هنا',
              helperText: 'الدرجة القصوى: $maxGrade',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(gradeController.text);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final grade = num.tryParse(result);
      if (grade != null) {
        if (grade < passingGrade) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ تحذير'),
              content: const Text('الدرجة المدخلة أقل من درجة النجاح. هل أنت متأكد من رصدها؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('تأكيد الرصد'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
        }
        await _saveGrade(studentId, grade);
      }
    }
  }

  Future<void> _saveGrade(String studentId, num grade) async {
    try {
      final studentRef = _firestore.collection('students').doc(studentId);
      await studentRef.update({ widget.testFieldKey: grade });
      setState(() => _grades[studentId] = grade);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الدرجة بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ الدرجة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- ✅ NEW: Function to delete a grade or an absence mark ---
  Future<void> _deleteGrade(String studentId) async {
    try {
      final studentRef = _firestore.collection('students').doc(studentId);
      // Using FieldValue.delete() removes the field from the document
      await studentRef.update({widget.testFieldKey: FieldValue.delete()});
      if (mounted) {
        setState(() => _grades[studentId] = null);
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
      if (isNafes) {
        if (grade >= 9) return "ممتاز";
        if (grade >= 8) return "جيد جدا";
        if (grade >= 7) return "جيد";
        return "أولى بالرعاية";
      } else {
        if (grade >= 18) return "ممتاز";
        if (grade >= 16) return "جيد جدا";
        if (grade >= 14) return "جيد";
        return "أولى بالرعاية";
      }
    }

    for (var studentDoc in _students) {
      final studentId = studentDoc.id;
      final studentName = (studentDoc.data() as Map<String, dynamic>)['name'] ?? 'اسم غير معروف';
      final grade = _grades[studentId];

      if (grade != null) {
        // --- ✅ MODIFIED: Handle the absent case (-1) ---
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

    for (var i = 0; i < headers.length; i++) {
      sheetObject.autoFitColumn(i);
    }

    final String fileName = "درجات-${widget.testName}-${widget.className}.xlsx";

    final fileBytes = excel.save();

    if (fileBytes == null) return;

    try {
      if (kIsWeb) {
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
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
          SnackBar(
            content: Text('تم تصدير الملف بنجاح باسم: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تصدير الملف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- ✅ NEW: Helper widget to build the action buttons based on grade status ---
  Widget _buildGradeActions(String studentId, String studentName, dynamic currentGrade) {
    // Case 1: Grade has not been entered
    if (currentGrade == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange.shade800,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
              ),
              onPressed: () => _showGradeDialog(studentId, studentName, null),
              child: const Text('رصد درجة'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              // Use -1 to represent an absent student in Firestore
              onPressed: () => _saveGrade(studentId, -1),
              child: const Text('غائب'),
            ),
          ),
        ],
      );
    }

    // Common action buttons for edit and delete
    final editButton = IconButton(
      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 22),
      tooltip: 'تعديل الدرجة',
      visualDensity: VisualDensity.compact,
      // If student was absent, open the dialog empty to enter a new grade
      onPressed: () => _showGradeDialog(studentId, studentName, currentGrade == -1 ? null : currentGrade),
    );
    final deleteButton = IconButton(
      icon: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 22),
      tooltip: 'حذف',
      visualDensity: VisualDensity.compact,
      onPressed: () => _deleteGrade(studentId),
    );

    // Case 2: Student was marked as absent
    if (currentGrade == -1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Chip(
            label: Text('غائب', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Color(0xFFE0E0E0), // A light grey color
          ),
          const SizedBox(width: 4),
          editButton,
          deleteButton,
        ],
      );
    }
    // Case 3: A grade has been entered
    else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              currentGrade.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green.shade800,
              ),
            ),
            backgroundColor: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          const SizedBox(width: 4),
          editButton,
          deleteButton,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allGradesEntered = _areAllGradesEntered();

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
          if (!widget.isBehaviorMode)
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: 'تحميل ملف الدرجات (Excel)',
              onPressed: allGradesEntered ? _exportToExcel : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يجب رصد جميع درجات الطلاب أولاً لتتمكن من تحميل الملف.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
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
          final studentName = studentData['name'] ?? 'اسم غير معروف';
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
                Flexible(child: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                if (likeCount > 0)
                  Chip(
                    avatar: const Icon(Icons.thumb_up, color: Colors.green, size: 14),
                    label: Text('$likeCount', style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                const SizedBox(width: 4),
                if (dislikeCount > 0)
                  Chip(
                    avatar: const Icon(Icons.thumb_down, color: Colors.red, size: 14),
                    label: Text('$dislikeCount', style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
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
            // --- ✅ MODIFIED: Use the new helper widget for the trailing actions ---
            trailing: !widget.isBehaviorMode
                ? _buildGradeActions(studentId, studentName, currentGrade)
                : null,
          );
        },
      ),
    );
  }
}

extension on Sheet {
  void autoFitColumn(int i) {}
}