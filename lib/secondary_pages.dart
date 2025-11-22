// secondary_pages.dart
// ✅ (FIXED) تم إصلاح مشكلة "الصورة المكسورة" بمعالجة بناء الرابط بشكل صحيح (استخدام & بدلاً من ? عند وجود توكن)
// ✅ (FIXED) تم ضبط الصورة لتظهر كاملة في المنتصف (Contain) مع تصغيرها قليلاً (Padding 15)
// ✅ (MODIFIED) الحد الأقصى 3 ميجا بايت مفعل

import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // ضروري لقراءة الملفات في الويب

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

// --- 1. محتوى من: profile_page.dart (معدل بالكامل - هوية معلم) ---

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
        if (mounted) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        if (mounted) setState(() { _isLoading = false; });
      }
    } else {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  // ✅ دالة الرفع المعدلة والمصححة
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // جودة جيدة
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      Uint8List fileBytes = await pickedFile.readAsBytes();

      // 1. التحقق من الحجم (3 ميجا)
      const int maxFileSize = 3 * 1024 * 1024;
      if (fileBytes.length > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عفواً، حجم الصورة كبير جداً. الحد الأقصى هو 3 ميجابايت.'), backgroundColor: Colors.orange),
          );
          setState(() => _isUploading = false);
        }
        return;
      }

      // 2. الرفع (استخدام اسم ثابت للملف لتجنب التكرار)
      final String fileName = '${_user!.uid}.jpg';
      final ref = FirebaseStorage.instance.ref().child('photosT').child(fileName);

      await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));

      // 3. الحصول على الرابط وتصحيحه (الحل لمشكلة الصورة المكسورة)
      String url = await ref.getDownloadURL();

      // ✅✅✅ التصحيح الجوهري: نتحقق هل الرابط يحتوي على علامات استفهام مسبقاً أم لا
      // إذا كان الرابط يحتوي على '?' فهذا يعني وجود توكن، لذا نستخدم '&' للفصل
      final String separator = url.contains('?') ? '&' : '?';
      final String uniqueUrl = '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';

      // 4. الحفظ في قاعدة البيانات
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set(
        {'photo': uniqueUrl},
        SetOptions(merge: true),
      );

      if(mounted) {
        setState(() {
          if (_userData == null) _userData = {};
          _userData!['photo'] = uniqueUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة بنجاح'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      debugPrint("Error uploading image: $e");
      if(mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = _userData?['photo'];
    final bool hasImage = photoUrl != null && photoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('هوية المعلم', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('الرجاء تسجيل الدخول.'))
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // الرأس
                    SizedBox(
                      height: 190,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // الخلفية
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                              ),
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade800, Colors.cyan.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),

                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(Icons.school, size: 150, color: Colors.white.withOpacity(0.1)),
                          ),
                          const Positioned(
                            top: 20,
                            child: Text(
                              "B A D G E   I D",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // ✅✅✅ قسم الصورة المصحح بالكامل ✅✅✅
                          Positioned(
                            bottom: 0,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _isUploading
                                        ? const Center(child: CircularProgressIndicator())
                                        : (hasImage
                                        ? Container(
                                      color: Colors.white,
                                      // ✅ Padding 15: يصغر الصورة عن الحواف فتظهر وكأنها في منتصف الدائرة البيضاء
                                      padding: const EdgeInsets.all(15.0),
                                      child: Image.network(
                                        photoUrl,
                                        key: ValueKey(photoUrl), // تحديث عند تغيير الرابط
                                        // ✅ Contain: يضمن ظهور الصورة كاملة دون قص أي جزء منها
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400);
                                        },
                                      ),
                                    )
                                        : Icon(Icons.person, size: 70, color: Colors.grey.shade400)),
                                  ),
                                ),

                                // زر الكاميرا
                                GestureDetector(
                                  onTap: _isUploading ? null : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // باقي المعلومات
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            _userData?['name'] ?? 'الاسم غير متوفر',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (_userData?['profession'] == 'admin') ? 'مدير النظام' : 'عضو هيئة تدريس',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.email_outlined, 'البريد الإلكتروني', _user?.email ?? '-'),
                          const Divider(height: 24),
                          _buildDetailRow(Icons.phone_outlined, 'رقم الهاتف', _userData?['phone'] ?? '-', canCopy: true),
                          const Divider(height: 24),
                          _buildSubjectsSection(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // تذييل البطاقة
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(30, (index) {
                          return Container(
                            width: index % 2 == 0 ? 2 : 4,
                            height: 25,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            color: Colors.black12,
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "المملكة العربية السعودية - ابتدائية المعرفة بمكة المكرمة",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {bool canCopy = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: canCopy ? () {
                  if (value != '-' && value.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ رقم الهاتف'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (canCopy && value != '-' && value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.copy, size: 14, color: Colors.blue.shade300),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsSection() {
    List<String> subjects = [];
    for (int i = 1; i <= 14; i++) {
      if (_userData?['profession$i'] != null && (_userData!['profession$i'] as String).isNotEmpty) {
        subjects.add(_userData!['profession$i']);
      }
    }

    if (subjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.work_outline, color: Colors.blue.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              'المواد المسندة',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: subjects.map((subj) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              subj,
              style: TextStyle(color: Colors.blue.shade800, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// --- 2. محتوى من: grade_entry_page.dart ---

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

    for (var i = 0; i < headers.length; i++) {
      sheetObject.setColAutoFit(i);
    }

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
          maxGrade: maxGrade,
          passingGrade: passingGrade,
          onSaveGrade: _saveGrade,
          onDeleteGrade: _deleteGrade,
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
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(
      text: (widget.currentGrade != null && widget.currentGrade != -1)
          ? widget.currentGrade.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
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
      await widget.onSaveGrade(widget.studentId, grade);
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
      await widget.onSaveGrade(widget.studentId, -1);
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
              SizedBox(
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

// --- 3. محتوى من: teacher_profile_view_page.dart ---

class TeacherProfileViewPage extends StatelessWidget {
  final String teacherId;

  const TeacherProfileViewPage({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف المعلم الشخصي'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(teacherId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("Error fetching teacher data: ${snapshot.error}");
            return const Center(child: Text('حدث خطأ أثناء جلب بيانات المعلم.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('لم يتم العثور على بيانات المعلم.'));
          }

          final data = snapshot.data!.data();
          if (data == null || data is! Map<String, dynamic>) {
            return const Center(child: Text('صيغة بيانات المعلم غير صحيحة.'));
          }
          final userData = data;

          final String name = userData['name'] ?? 'اسم غير متوفر';
          final String? photoUrl = userData['photo'];
          final String profession1 = userData['profession1'] ?? 'غير متوفر';
          final String? profession2 = userData['profession2'];
          final String? profession3 = userData['profession3'];
          final String phoneNumber = userData['phone'] ?? 'غير متوفر';


          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(Icons.person, size: 60, color: primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildInfoRowTeacher(Icons.work_outline, 'المادة الأساسية', profession1),
                      if (profession2 != null && profession2.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRowTeacher(Icons.work_outline, 'المادة الثانية', profession2),
                      ],
                      if (profession3 != null && profession3.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRowTeacher(Icons.work_outline, 'المادة الثالثة', profession3),
                      ],
                      const Divider(),
                      _buildInfoRowTeacher(Icons.phone_outlined, 'للتواصل', phoneNumber),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRowTeacher(IconData icon, String label, String value) {
    return Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 16))),
              ],
            ),
          );
        }
    );
  }
}

// --- 4. محتوى من: test_selection_page.dart ---

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
    if (isBehaviorMode) {
      return GradeEntryPage(
        stage: stage,
        grade: grade,
        className: className,
        subject: subject,
        testFieldKey: 'behavior_mode',
        testName: 'تقييم سلوك الطلاب',
        isBehaviorMode: true,
      );
    }


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
                      isBehaviorMode: isBehaviorMode,
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
        debugPrint("Error listening to lock status for ${widget.test.testFieldKey}: $error");
        setState(() {
          _isLocked = true;
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
      debugPrint("Error toggling lock status for ${widget.test.testFieldKey}: $e");
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('جارِ تحميل حالة الاختبار...'),
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

// --- 5. محتوى من: online_students_page.dart ---

class OnlineStudentsPage extends StatelessWidget {
  const OnlineStudentsPage({super.key});

  String _formatFullTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'لم يسجل دخول بعد';

    final formatter = intl.DateFormat('EEEE، yyyy/MM/dd | hh:mm a', 'ar');
    return formatter.format(timestamp.toDate());
  }

  String _formatSessionTime(Timestamp? timestamp) {
    if (timestamp == null) return 'لا يوجد بيانات';

    final lastSeen = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 70) {
      return 'متصل الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  String _formatTotalActiveTime(int? totalSeconds, bool isOnline) {

    if (isOnline && (totalSeconds == null || totalSeconds == 0)) {
      return 'نشط الآن (أقل من دقيقة)';
    }

    if (totalSeconds == null || totalSeconds <= 0) {
      return 'لا يوجد نشاط مسجل';
    }

    final duration = Duration(seconds: totalSeconds);

    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;

    List<String> parts = [];

    if (days > 0) {
      if (days == 1) parts.add('يوم');
      else if (days == 2) parts.add('يومين');
      else if (days >= 3 && days <= 10) parts.add('$days أيام');
      else parts.add('$days يوم');
    }

    if (hours > 0) {
      if (hours == 1) parts.add('ساعة');
      else if (hours == 2) parts.add('ساعتين');
      else if (hours >= 3 && hours <= 10) parts.add('$hours ساعات');
      else parts.add('$hours ساعة');
    }

    if (days == 0 && minutes > 0) {
      if (minutes == 1) parts.add('دقيقة');
      else if (minutes == 2) parts.add('دقيقتين');
      else if (minutes >= 3 && minutes <= 10) parts.add('$minutes دقائق');
      else parts.add('$minutes دقيقة');
    }

    if (parts.isEmpty) {
      if (totalSeconds < 60) {
        return 'أقل من دقيقة';
      }
      else if (minutes > 0) {
        if (minutes == 1) return 'دقيقة';
        else if (minutes == 2) return 'دقيقتين';
        else if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
        else return '$minutes دقيقة';
      } else {
        return 'لا يوجد نشاط مسجل';
      }
    }

    return parts.take(2).join(' و ');
  }


  bool _isCurrentlyOnline(Timestamp? timestamp) {
    if (timestamp == null) return false;
    final lastSeen = timestamp.toDate();
    final difference = DateTime.now().difference(lastSeen);
    return difference.inSeconds < 70;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل آخر ظهور للطلاب'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .orderBy('lastSeen', descending: true)
            .limit(200)
            .snapshots(),
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
                  Icon(Icons.people_outline, color: Colors.grey, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد طلاب مسجلون لعرض سجل الظهور.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'اسم غير معروف';
              final grade = data['grades'] ?? 'غير محدد';
              final className = data['classes'] ?? 'غير محدد';
              final lastSeenTimestamp = data['lastSeen'] as Timestamp?;

              final totalActiveSeconds = data['totalActiveSeconds'] as int?;

              final isOnline = _isCurrentlyOnline(lastSeenTimestamp);
              final statusText = isOnline ? 'متصل حالياً' : 'غير متصل';
              final statusColor = isOnline ? Colors.green.shade600 : Colors.blueGrey.shade400;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isOnline ? BorderSide(color: Colors.green.shade400, width: 2) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.circle : Icons.person_pin_circle_rounded,
                            color: statusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Chip(
                            label: Text(statusText, style: TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: statusColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      const Divider(height: 20, thickness: 1),

                      _buildDetailRow(
                        icon: Icons.school,
                        label: 'الفصل الدراسي',
                        value: '$grade / $className',
                        context: context,
                      ),

                      const SizedBox(height: 8),

                      _buildDetailRow(
                        icon: Icons.schedule,
                        label: 'آخر ظهور كامل',
                        value: _formatFullTimestamp(lastSeenTimestamp),
                        context: context,
                        isTime: true,
                      ),

                      const SizedBox(height: 8),

                      _buildDetailRow(
                        icon: Icons.timer,
                        label: 'آخر نشاط',
                        value: _formatSessionTime(lastSeenTimestamp),
                        context: context,
                        isTime: true,
                        valueColor: isOnline ? Colors.green.shade700 : Colors.black54,
                      ),

                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.access_time_filled,
                        label: 'إجمالي النشاط',
                        value: _formatTotalActiveTime(totalActiveSeconds, isOnline),
                        context: context,
                        isTime: true,
                        valueColor: Colors.deepPurple.shade700,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
    bool isTime = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontFamily: isTime ? 'monospace' : null,
            ),
            textDirection: isTime ? TextDirection.ltr : TextDirection.rtl,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

// --- 6. محتوى من: student_profile_page.dart ---

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(_user!.uid)
          .get();

      if (mounted) {
        if (docSnapshot.exists) {
          setState(() {
            _studentData = docSnapshot.data();
          });
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي للطالب'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('الرجاء تسجيل الدخول لعرض الملف الشخصي.'))
          : _studentData == null
          ? const Center(child: Text('لم يتم العثور على بيانات الطالب.'))
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person_pin, size: 60, color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _studentData?['name'] ?? 'اسم غير متوفر',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _user?.email ?? 'بريد إلكتروني غير متوفر',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRowStudent(Icons.email_outlined, 'البريد الإلكتروني', _user?.email ?? 'غير متوفر'),
                  const Divider(),
                  _buildInfoRowStudent(Icons.phone_outlined, 'هاتف ولي الأمر', _studentData?['guardian_phone'] ?? 'غير متوفر'),
                  const Divider(),
                  _buildInfoRowStudent(Icons.layers_outlined, 'المرحلة', _studentData?['stages'] ?? 'غير متوفر'),
                  const Divider(),
                  _buildInfoRowStudent(Icons.school_outlined, 'الصف', _studentData?['grades'] ?? 'غير متوفر'),
                  const Divider(),
                  _buildInfoRowStudent(Icons.class_outlined, 'الفصل', _studentData?['classes'] ?? 'غير متوفر'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowStudent(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 16))),
        ],
      ),
    );
  }
}

// --- 7. محتوى من: noble_student_page.dart ---

class NobleStudentPage extends StatefulWidget {
  final String stage;
  final String grade;
  final String className;
  final String subject;

  const NobleStudentPage({
    super.key,
    required this.stage,
    required this.grade,
    required this.className,
    required this.subject,
  });

  @override
  _NobleStudentPageState createState() => _NobleStudentPageState();
}

class _NobleStudentPageState extends State<NobleStudentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _students = [];
  final Map<String, int> _likes = {};
  final Map<String, int> _dislikes = {};


  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
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

      for (var studentDoc in students) {
        final data = studentDoc.data() as Map<String, dynamic>?;
        final studentId = studentDoc.id;

        _likes[studentId] = data?['totalLikes'] ?? 0;
        _dislikes[studentId] = data?['totalDislikes'] ?? 0;
      }

      if (mounted) {
        setState(() {
          _students = students;
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

  Future<String?> _showDislikeDialogNoble(String studentName) async {
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

  Future<void> _addBehaviorReportNoble(String studentId, String studentName, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? teacherNote;
    if (type == 'dislike') {
      teacherNote = await _showDislikeDialogNoble(studentName);
      if (teacherNote == null) return;
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
        if (type == 'dislike') 'status': 'pending_reply',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطالب المنضبط'),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.green, size: 28),
                  onPressed: () => _addBehaviorReportNoble(studentId, studentName, 'like'),
                  tooltip: 'إعجاب (سلوك نبيل)',
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down, color: Colors.red, size: 28),
                  onPressed: () => _addBehaviorReportNoble(studentId, studentName, 'dislike'),
                  tooltip: 'ملاحظة (سلوك شغب)',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}