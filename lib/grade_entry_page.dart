// grade_entry_page.dart (MODIFIED)

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
  Map<String, dynamic> _grades = {}; // Stores fetched and updated grades
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

      // Sort students alphabetically by name
      students.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>? ?? {};
        final bData = b.data() as Map<String, dynamic>? ?? {};
        final String aName = aData['name'] ?? '';
        final String bName = bData['name'] ?? '';
        return aName.compareTo(bName);
      });

      // Prepare map to hold grades and behavior counts
      final grades = <String, dynamic>{};
      final likes = <String, int>{};
      final dislikes = <String, int>{};

      for (var studentDoc in students) {
        final data = studentDoc.data() as Map<String, dynamic>?;
        final studentId = studentDoc.id;
        // Fetch the specific grade for the current test
        final score = data?[widget.testFieldKey];
        grades[studentId] = score; // Can be null if not graded yet

        // Fetch behavior counts
        likes[studentId] = data?['totalLikes'] ?? 0;
        dislikes[studentId] = data?['totalDislikes'] ?? 0;
      }

      // Update state once all data is processed
      if (mounted) {
        setState(() {
          _students = students;
          _grades = grades; // Update the grades map
          _likes.addAll(likes); // Update likes
          _dislikes.addAll(dislikes); // Update dislikes
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
        'status': type == 'dislike' ? 'pending_reply' : 'like_added', // Status for like
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
          content: Text(type == 'like' ? 'تم تسجيل الإعجاب بنجاح' : 'تم تسجيل الملاحظة بنجاح'),
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


  Future<void> _saveGrade(String studentId, num grade) async {
    try {
      final studentRef = _firestore.collection('students').doc(studentId);
      await studentRef.update({ widget.testFieldKey: grade });
      setState(() => _grades[studentId] = grade);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(grade == -1 ? 'تم تسجيل الطالب كـ "غائب"' : 'تم حفظ الدرجة بنجاح'),
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

  // --- ✅✅✅ START OF RESTORATION (استعادة دالة التحميل الزرقاء) ✅✅✅ ---
  Future<void> _exportToExcel() async {
    // Check if all grades are entered before proceeding
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
    final Sheet sheetObject = excel['Sheet1']; // Use the default sheet

    sheetObject.isRTL = true; // Set sheet direction to Right-to-Left

    // Define Headers
    final List<String> headers = ['اسم الطالب', 'الدرجة', 'النسبة المئوية', 'التقييم'];
    // Append header row with TextCellValue objects
    sheetObject.appendRow(headers.map((header) => TextCellValue(header)).toList());

    // Style the header row
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        // --- (تعديل بسيط) استخدام اللون الأزرق للرأس ---
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    // Determine max grade based on test type
    final bool isNafes = widget.testFieldKey.contains('profession13');
    final double maxGrade = isNafes ? 10.0 : 20.0;

    // Helper function for evaluation based on grade and maxGrade
    String getEvaluation(num grade) {
      // Use percentage for a more flexible evaluation
      double percentage = (grade / maxGrade) * 100;
      if (percentage >= 90) return "ممتاز";
      if (percentage >= 80) return "جيد جدا";
      if (percentage >= 70) return "جيد";
      if (percentage >= 50) return "مقبول"; // Added 'مقبول'
      return "يحتاج لمتابعة"; // Changed from "أولى بالرعاية"
    }

    // Iterate through students and add their data to the sheet
    // --- (تعديل) التأكد من جلب الطلاب بالترتيب الصحيح من الحالة المحلية ---
    List<DocumentSnapshot> sortedStudents = List.from(_students);
    sortedStudents.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>? ?? {};
      final bData = b.data() as Map<String, dynamic>? ?? {};
      final String aName = aData['name'] ?? '';
      final String bName = bData['name'] ?? '';
      return aName.compareTo(bName);
    });

    for (var studentDoc in sortedStudents) { // <-- استخدام القائمة المرتبة
      final studentId = studentDoc.id;
      final studentName = (studentDoc.data() as Map<String, dynamic>)['name'] ?? 'اسم غير معروف';
      final grade = _grades[studentId]; // Get grade from the local map

      // Ensure grade is not null before processing (shouldn't happen if _areAllGradesEntered passed)
      if (grade != null) {
        if (grade == -1) {
          // Handle absent case
          final List<CellValue> row = [
            TextCellValue(studentName),
            TextCellValue('غائب'), // Write "غائب"
            TextCellValue('N/A'),
            TextCellValue('N/A')
          ];
          sheetObject.appendRow(row);
        } else {
          // Handle graded case
          final double percentage = (grade / maxGrade) * 100;
          final String evaluation = getEvaluation(grade);
          final List<CellValue> row = [
            TextCellValue(studentName),
            DoubleCellValue(grade.toDouble()), // Store grade as number
            // Format percentage as string with one decimal place
            TextCellValue('${percentage.toStringAsFixed(1)}%'),
            TextCellValue(evaluation)
          ];
          sheetObject.appendRow(row);
        }
      }
    }

    // Auto-fit columns for better readability
    for (var i = 0; i < headers.length; i++) {
      sheetObject.setColAutoFit(i);
    }

    // Define file name
    final String fileName = "درجات-${widget.testName}-${widget.className}.xlsx";

    // Save the Excel file bytes
    final fileBytes = excel.save();

    // Ensure file bytes were generated
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إنشاء ملف Excel.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Handle file saving/downloading based on platform
    try {
      if (kIsWeb) {
        // Web platform: Use html package to trigger download
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click(); // Trigger download
        html.Url.revokeObjectUrl(url); // Release object URL
      } else {
        // Mobile/Desktop platform: Use path_provider and open_filex
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(fileBytes); // Write bytes to file

        // Attempt to open the file
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done) {
          // Handle error if file couldn't be opened
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('لم يتم العثور على تطبيق لفتح ملفات Excel. الخطأ: ${result.message}')),
            );
          }
        }
      }
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير الملف بنجاح باسم: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message if saving/opening failed
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
  // --- ✅✅✅ END OF RESTORATION (نهاية استعادة دالة التحميل الزرقاء) ✅✅✅ ---

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
      // Display the actual grade, converting num to String
      text = currentGrade.toString();
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      borderColor = Colors.green.shade300;
      fontWeight = FontWeight.bold;
    } else {
      text = 'رصد'; // Text for when grade is null (not entered yet)
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      borderColor = Colors.orange.shade300;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80, // Fixed width for consistent alignment
        height: 40, // Fixed height
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
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGradeEntryDialog({
    required String studentId,
    required String studentName,
    required dynamic currentGrade, // The current grade (can be null, -1, or number)
    required double maxGrade,
    required double passingGrade,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) {
        // Use the separate dialog widget
        return _GradeEntryDialog(
          studentId: studentId,
          studentName: studentName,
          currentGrade: currentGrade,
          maxGrade: maxGrade,
          passingGrade: passingGrade,
          onSaveGrade: _saveGrade,   // Pass the save function
          onDeleteGrade: _deleteGrade, // Pass the delete function
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool allGradesEntered = _areAllGradesEntered();

    final bool isNafes = widget.testFieldKey.contains('profession13');
    final double maxGrade = isNafes ? 10.0 : 20.0;
    final double passingGrade = isNafes ? 5.0 : 10.0; // Assuming 50% passing

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testName), // Display test name
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
          // --- ✅✅✅ START OF RESTORATION (استعادة زر التحميل الأزرق) ✅✅✅ ---
          // Show export button only if not in behavior mode
          if (!widget.isBehaviorMode)
            IconButton(
              icon: Icon(
                Icons.download_for_offline_outlined,
                // --- (تعديل بسيط) استخدام اللون الأزرق الفاتح ---
                color: allGradesEntered ? Colors.lightBlueAccent : Colors.white38,
              ),
              tooltip: 'تحميل ملف الدرجات لهذا الاختبار (Excel)',
              // onPressed is null if not all grades are entered, disabling the button
              onPressed: allGradesEntered ? _exportToExcel : null,
            ),
          // --- ✅✅✅ END OF RESTORATION (نهاية استعادة زر التحميل الأزرق) ✅✅✅ ---
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? const Center(child: Text('لا يوجد طلاب في هذا الفصل.', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _students.length,
        separatorBuilder: (context, index) => const Divider(), // Add dividers
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
              mainAxisSize: MainAxisSize.min, // Keep buttons together
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
                : null, // No subtitle if not in behavior mode
            trailing: !widget.isBehaviorMode
                ? _buildGradeChip(
              currentGrade: currentGrade, // Pass the fetched grade
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
                : null, // No grade chip if in behavior mode
          );
        },
      ),
    );
  }
}

// Separate StatefulWidget for the grade entry dialog
class _GradeEntryDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final dynamic currentGrade; // Can be null, -1, or number
  final double maxGrade;
  final double passingGrade;
  final Future<void> Function(String studentId, num grade) onSaveGrade;
  final Future<void> Function(String studentId) onDeleteGrade;

  const _GradeEntryDialog({
    required this.studentId,
    required this.studentName,
    required this.currentGrade,
    required this.maxGrade,
    required this.passingGrade,
    required this.onSaveGrade,
    required this.onDeleteGrade,
  });

  @override
  State<_GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<_GradeEntryDialog> {
  late TextEditingController _gradeController;
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  bool _isSaving = false; // To show loading indicator

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(
      text: (widget.currentGrade != null && widget.currentGrade != -1)
          ? widget.currentGrade.toString()
          : '', // Empty if null or absent
    );
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return; // Prevent double taps
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
        return; // Exit if parsing fails
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
        if (confirmed != true) return; // User cancelled the warning
      }
      await widget.onSaveGrade(widget.studentId, grade);
      if (mounted) Navigator.pop(context); // Close dialog on success
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
      await widget.onSaveGrade(widget.studentId, -1); // Save -1
      if (mounted) Navigator.pop(context); // Close dialog
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
      if (mounted) Navigator.pop(context); // Close dialog
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: null, // No title, student name is in content
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0), // Adjust padding
      content: SingleChildScrollView(
        child: _isSaving
            ? const SizedBox(
          height: 150, // Provide height for indicator
          child: Center(child: CircularProgressIndicator()),
        )
            : Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Fit content height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الطالب: ${widget.studentName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(
                width: 120, // Set desired width
                child: TextFormField(
                  controller: _gradeController,
                  autofocus: true,
                  textAlign: TextAlign.center, // Center text input
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold), // Larger font
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
                      return 'أدخل درجة'; // Error if empty
                    }
                    final grade = num.tryParse(value.trim());
                    if (grade == null) {
                      return 'رقم غير صالح'; // Error if not a number
                    }
                    if (grade < 0) {
                      return 'لا يمكن أن تكون سالبة'; // Error if negative (allow -1 separately)
                    }
                    if (grade > widget.maxGrade) {
                      return 'أعلى من ${widget.maxGrade}';
                    }
                    return null; // Valid input
                  },
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
            spacing: 8.0, // Horizontal space between buttons
            runSpacing: 4.0, // Vertical space if they wrap
            alignment: WrapAlignment.end, // Align buttons to the right
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
      actionsAlignment: MainAxisAlignment.end, // Align actions row
    );
  }
}


// Extension needed for Excel autoFitColumn (add if not present)
extension on Sheet {
  void setColAutoFit(int columnIndex) {
    // This is a placeholder. The actual implementation depends on the 'excel' package version.
    // If autoFitColumn exists directly, this extension is not needed.
    // If it doesn't, you might need to calculate the width manually based on content,
    // or check the package documentation for the correct method.
    // For newer versions, it might be:
    // this.setColumnAutoFit(columnIndex);
  }
}