import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:almarefamecca/add1.dart';
import 'package:almarefamecca/card.dart'; // ✅ تم إضافة استيراد ملف الفيزا الجديد
import 'package:almarefamecca/secondary_pages.dart';
import 'package:almarefamecca/student_view.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isExporting = false;
  // تم حذف _isMassExporting لأنها انتقلت للملف الآخر
  bool _isAdmin = false;
  User? _user;

  String _userProfession = '';
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _onRefresh() async {
    if (kIsWeb) {
      await _fetchUserData();
      if (mounted) setState(() {});
    } else {
      await _fetchUserData();
      if (mounted) setState(() {});
    }
  }

  void _logoutGuestSession() {
    _sessionTimer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الخروج تلقائياً لانتهاء جلسة الضيف (3 دقائق).'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
    FirebaseAuth.instance.signOut();
  }

  void _resetGuestSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 3), _logoutGuestSession);
  }

  void _stopGuestSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  Future<void> _fetchUserData() async {
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDataSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (!mounted) return;

      final data = userDataSnapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String profession = data['profession'] ?? '';
      final bool isGuest = profession == 'gest';

      setState(() {
        _userData = data;
        _isAdmin = data['profession'] == 'admin';
        _userProfession = profession;
        _isLoading = false;
      });

      if (isGuest) {
        _resetGuestSessionTimer();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _showGuestError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة غير متاحة لحساب الضيف.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showChangeGuestPinDialog() async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final firestore = FirebaseFirestore.instance;
    final settingRef = firestore.collection('settings').doc('guest_access');

    String currentPin = 'جاري التحميل...';
    bool isLoading = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isLoading) {
              settingRef.get().then((doc) {
                if (doc.exists && doc.data() != null && doc.data()!.containsKey('admin_pin')) {
                  currentPin = doc.data()!['admin_pin'].toString();
                } else {
                  currentPin = '010';
                }
                if (mounted) {
                  setDialogState(() {
                    pinController.text = currentPin;
                    isLoading = false;
                  });
                }
              }).catchError((e) {
                if (mounted) {
                  setDialogState(() {
                    currentPin = 'خطأ في التحميل';
                    isLoading = false;
                  });
                }
              });
            }

            return AlertDialog(
              title: const Text('التحكم في رمز دخول الضيف (المدير)'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الرمز السري الحالي: ${isLoading ? "..." : currentPin}'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الرمز السري الجديد',
                        hintText: 'مثال: 123',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال الرمز';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'الرجاء إدخال أرقام فقط';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هذا هو الرمز (PIN) الذي يستخدمه "الضيف المدير" للدخول.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newPin = pinController.text.trim();
                      try {
                        await settingRef.set({
                          'admin_pin': newPin,
                        }, SetOptions(merge: true));

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تحديث الرمز السري للضيف بنجاح إلى: $newPin'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل تحديث الرمز: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('حفظ التعديل'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBroadcastNotificationDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _bodyController = TextEditingController();
    bool _isSending = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('إرسال إشعار عام'),
                ],
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      readOnly: _isSending,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الإشعار',
                        hintText: 'مثال: "تذكير هام"',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال عنوان';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      readOnly: _isSending,
                      decoration: const InputDecoration(
                        labelText: 'نص الرسالة',
                        hintText: 'اكتب محتوى الرسالة هنا...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال نص الرسالة';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isSending ? null : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'جاري الإرسال...' : 'إرسال الآن'),
                  onPressed: _isSending ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() {
                        _isSending = true;
                      });

                      try {
                        await FirebaseFirestore.instance.collection('broadcast_notifications').add({
                          'title': _titleController.text.trim(),
                          'body': _bodyController.text.trim(),
                          'senderId': _user?.uid ?? 'admin',
                          'senderName': _userData?['name'] ?? 'Admin',
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إرسال طلب الإشعار بنجاح!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                      } catch (e) {
                        setDialogState(() {
                          _isSending = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل إرسال الإشعار: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  // ---------------------------------------------------------------------------
  // ⛔️ تم حذف دوال _generateRandomVisaCode و _generateBulkStudentVisas من هنا
  // ⛔️ ونقلها إلى ملف card.dart
  // ---------------------------------------------------------------------------

  Future<void> _launchEduFormsUrl() async {
    final Uri url = Uri.parse('https://edu-forms.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح الرابط: $url')),
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
                            ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                            .format(ts.toDate())
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
    });
  }

  Future<void> _exportFullSchoolDataToExcel() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      final students = studentsSnapshot.docs;

      final Map<String, String> testToSubjectMap = {};
      final Map<String, String> subjects = {
        'profession1': 'رياضيات',
        'profession2': 'لغتي',
        'profession3': 'إسلاميات',
        'profession4': 'علوم',
        'profession5': 'نشاط',
        'profession6': 'انجليزي',
        'profession7': 'اجتماعيات',
        'profession8': 'فنية',
        'profession9': 'حياتية',
        'profession10': 'بدنية',
        'profession11': 'رقمية',
        'profession12': 'تفكير',
      };
      subjects.forEach((profKey, subjName) {
        for (int i = 1; i <= 16; i++) {
          testToSubjectMap['e$i$profKey'] = subjName;
        }
      });
      for (int i = 1; i <= 12; i++) {
        testToSubjectMap['e${i}profession13'] = 'نافس';
      }

      final allSubjects = testToSubjectMap.values.toSet().toList()..sort();

      final excel = Excel.createExcel();
      final sheet = excel['بيانات المدرسة كاملة'];
      sheet.isRTL = true;
      excel.delete('Sheet1');

      final headers = ['المرحلة', 'الصف', 'الفصل', 'اسم الطالب', ...allSubjects];

      final headerStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString("#FF1976D2"),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center);
      final separatorStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString("#FFFFEB3B"),
          horizontalAlign: HorizontalAlign.Center);

      final Map<String, Map<String, Map<String, List<DocumentSnapshot>>>> schoolStructure = {};
      for (var studentDoc in students) {
        final data = studentDoc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final stage = data['stages'] as String? ?? 'N/A';
        final grade = data['grades'] as String? ?? 'N/A';
        final className = data['classes'] as String? ?? 'N/A';
        schoolStructure
            .putIfAbsent(stage, () => {})
            .putIfAbsent(grade, () => {})
            .putIfAbsent(className, () => [])
            .add(studentDoc);
      }

      final gradeOrder = [
        'الصف السادس',
        'الصف الخامس',
        'الصف الرابع',
        'الصف الثالث',
        'الصف الثاني',
        'الصف الأول',
        'الصف الثالث المتوسط',
        'الصف الثاني المتوسط',
        'الصف الأول المتوسط',
        'الصف الثالث الثانوي',
        'الصف الثاني الثانوي',
        'الصف الأول الثانوي'
      ];

      int processedCount = 0;

      for(var stageEntry in schoolStructure.entries) {
        final stage = stageEntry.key;
        final grades = stageEntry.value;

        for (final gradeName in gradeOrder) {
          if (grades.containsKey(gradeName)) {
            final classes = grades[gradeName];
            if (classes == null) continue;

            for(var classEntry in classes.entries) {
              final className = classEntry.key;
              final studentList = classEntry.value;

              sheet.appendRow([]);
              final separatorRowIndex = sheet.maxRows;
              final classKey = '$stage - $gradeName - $className';
              sheet.merge(
                  CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: separatorRowIndex),
                  CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: separatorRowIndex));
              var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: separatorRowIndex));
              cell.value = TextCellValue("كشف درجات: $classKey");
              cell.cellStyle = separatorStyle;

              sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
              final headerRowIndex = sheet.maxRows - 1;
              for (int i = 0; i < headers.length; i++) {
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRowIndex)).cellStyle = headerStyle;
              }

              studentList.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>?;
                final bData = b.data() as Map<String, dynamic>?;
                return (aData?['name'] as String? ?? '').compareTo(bData?['name'] as String? ?? '');
              });

              for (var studentDoc in studentList) {
                processedCount++;
                if (processedCount % 20 == 0) {
                  await Future.delayed(Duration.zero);
                }

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
            }
          }
        }
      }

      _saveAndDownloadExcel(context, excel, 'بيانات_المدرسة_الكاملة.xlsx');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير البيانات: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة ستكون متاحة قريباً!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = _userProfession == 'gest';

    Widget pageContent = PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('للحفاظ على التطبيق مفتوحاً، استخدم زر القائمة الرئيسية (Home) للخروج.', textAlign: TextAlign.center),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blueGrey,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlue.shade300,
          elevation: 0,
          leading: Tooltip(
            message: 'تحديث الصفحة للحصول على آخر التعديلات',
            child: GestureDetector(
              onTap: () {
                if (kIsWeb) {
                  html.window.location.reload();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/2.png'),
              ),
            ),
          ),
          title: const Text(
              'لوحة التحكم',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
          ),
          centerTitle: true,
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: _user == null
                  ? null
                  : FirebaseFirestore.instance
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
              onPressed: () {
                if (isGuest) {
                  _showGuestError();
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                }
              },
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30.0),
            child: Container(
              height: 30.0,
              alignment: Alignment.center,
              color: Colors.cyan.shade600,
              child: SizedBox(
                width: double.infinity,
                child: AnimatedTextKit(
                  animatedTexts: [
                    RotateAnimatedText(
                      'في حالة وجود مشكلة التواصل',
                      textAlign: TextAlign.center,
                      textStyle: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                    RotateAnimatedText(
                      '< > // مصطفي سعيد 966569064173',
                      textAlign: TextAlign.center,
                      textStyle: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  ],
                  repeatForever: true,
                  pause: const Duration(milliseconds: 900),
                  displayFullTextOnTap: true,
                ),
              ),
            ),
          ),
        ),

        body: RefreshIndicator(
          onRefresh: _onRefresh,
          displacement: 40.0,
          color: Colors.lightBlue.shade300,
          backgroundColor: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isExporting
              ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "جاري تصدير ملف الإدارة، قد يستغرق الأمر بعض الوقت...",
                  textAlign: TextAlign.center,
                )
              ]))
              : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildTeacherDashboard(),
            ],
          ),
        ),

        floatingActionButton: null,
      ),
    );

    if (isGuest) {
      return Listener(
        onPointerDown: (_) => _resetGuestSessionTimer(),
        onPointerMove: (_) => _resetGuestSessionTimer(),
        onPointerUp: (_) => _resetGuestSessionTimer(),
        behavior: HitTestBehavior.translucent,
        child: pageContent,
      );
    } else {
      if (_sessionTimer != null) {
        _stopGuestSessionTimer();
      }
      return pageContent;
    }
  }

  Widget _buildTeacherDashboard() {
    final bool isGuest = _userProfession == 'gest';
    final bool showAdminFeatures = _isAdmin || isGuest;
    String jobTitle = _isAdmin ? 'مدير النظام' : 'معلم';

    final onlineThreshold = DateTime.now().subtract(const Duration(seconds: 70));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  backgroundImage: (_userData != null &&
                      _userData!.containsKey('photo') &&
                      _userData!['photo'] != null &&
                      _userData!['photo'].toString().isNotEmpty)
                      ? NetworkImage(_userData!['photo'])
                      : null,
                  child: (_userData == null ||
                      !_userData!.containsKey('photo') ||
                      _userData!['photo'] == null ||
                      _userData!['photo'].toString().isEmpty)
                      ? const Icon(Icons.person, color: Colors.blue, size: 26)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'مرحباً، ${_userData?['name'] ?? '...'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        jobTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.7,
                child: Icon(Icons.school_outlined, color: Colors.white.withOpacity(0.2), size: 40),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 8 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            children: [
              if (showAdminFeatures)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .where('lastSeen', isGreaterThan: Timestamp.fromDate(onlineThreshold))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _AnimatedGridButton(
                        title: 'متصل حالياً',
                        icon: Icons.wifi,
                        color: Colors.green.shade600,
                        onTap: () {},
                        statCount: '...',
                      );
                    }
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'متصل حالياً',
                      icon: Icons.wifi,
                      color: Colors.green.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OnlineStudentsPage()),
                        );
                      },
                      statCount: '$count',
                    );
                  },
                ),

              if (showAdminFeatures)
                FutureBuilder<AggregateQuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('students').count().get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _AnimatedGridButton(
                        title: 'الغياب',
                        icon: Icons.people_alt_rounded,
                        color: Colors.blue.shade700,
                        onTap: () {},
                        statCount: '...',
                      );
                    }
                    final count = snapshot.hasData ? snapshot.data!.count : 0;
                    return _AnimatedGridButton(
                      title: 'الغياب',
                      icon: Icons.people_alt_rounded,
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AbsenceStatsPage()),
                        );
                      },
                      statCount: '$count',
                    );
                  },
                ),

              _buildDashboardButton(
                title: 'رصد الدرجات',
                icon: Icons.edit_note,
                assetPath: 'assets/b1.png',
                color: Colors.blue.shade700,
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GradeEntrySelectionPage(isBehaviorMode: false, isAdmin: _isAdmin)));
                  }
                },
              ),
              _buildDashboardButton(
                title: 'الطالب المنضبط',
                icon: Icons.sentiment_very_satisfied,
                assetPath: 'assets/b2.png',
                color: Colors.teal.shade600,
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GradeEntrySelectionPage(isBehaviorMode: true, isAdmin: _isAdmin)));
                  }
                },
              ),
              _buildDashboardButton(
                title: 'تعميم النماذج',
                icon: Icons.assignment,
                assetPath: 'assets/b3.png',
                color: Colors.indigo.shade600,
                onTap: _launchEduFormsUrl,
              ),
              _buildDashboardButton(
                title: 'صندوق الشكاوى',
                icon: Icons.inbox,
                assetPath: 'assets/b4.png',
                color: Colors.orange.shade800,
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsBoxPage()));
                  }
                },
              ),
              _buildDashboardButton(
                title: 'تحليل المخالفات',
                icon: Icons.flag,
                assetPath: 'assets/b5.png',
                color: Colors.red.shade700,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ViolationsLogPage()));
                },
              ),
              if (showAdminFeatures)
                _buildDashboardButton(
                  title: 'بحث نتائج طالب',
                  icon: Icons.person_search,
                  assetPath: 'assets/b6.png',
                  color: Colors.green.shade700,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSearchPage()));
                  },
                ),
              if (showAdminFeatures)
                _buildDashboardButton(
                  title: 'استخراج PDF',
                  icon: Icons.picture_as_pdf,
                  assetPath: 'assets/b7.png',
                  color: Colors.red.shade600,
                  onTap: _showComingSoonSnackBar,
                ),
              if (showAdminFeatures)
                _buildDashboardButton(
                  title: 'بيانات Excel',
                  icon: Icons.corporate_fare,
                  assetPath: 'assets/b8.png',
                  color: Colors.blueGrey.shade700,
                  onTap: _exportFullSchoolDataToExcel,
                ),
              if (_isAdmin)
                _buildDashboardButton(
                  title: 'رمز الضيف',
                  icon: Icons.vpn_key,
                  assetPath: 'assets/b9.png',
                  color: Colors.purple.shade600,
                  onTap: _showChangeGuestPinDialog,
                ),
              if (showAdminFeatures)
                _buildDashboardButton(
                  title: 'استكمال الرصد',
                  icon: Icons.pie_chart,
                  assetPath: 'assets/b10.png',
                  color: Colors.cyan.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GradeCompletionAnalyticsPage()),
                    );
                  },
                ),
              if (_isAdmin)
                _buildDashboardButton(
                  title: 'إشعار عام',
                  icon: Icons.campaign,
                  assetPath: 'assets/b11.png',
                  color: Colors.amber.shade700,
                  onTap: _showBroadcastNotificationDialog,
                ),
              // ✅✅✅ زر إدارة فيزا الطلاب (للمدير فقط) ✅✅✅
              if (_isAdmin)
                _buildDashboardButton(
                  title: 'إضافة فيزا الطلاب',
                  icon: Icons.credit_card,
                  assetPath: 'assets/a2.png', // تأكد من وجود الأيقونة
                  color: Colors.deepPurple.shade600,
                  onTap: () {
                    // الانتقال لصفحة إدارة الفيزا في الملف الآخر
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VisaManagementPage()),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDashboardButton({
    required String title,
    required IconData icon,
    String? assetPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _AnimatedGridButton(
      title: title,
      icon: icon,
      assetPath: assetPath,
      color: color,
      onTap: onTap,
    );
  }

  void showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة ستكون متاحة قريباً!')),
    );
  }
}

class _AnimatedGridButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? assetPath;
  final Color color;
  final VoidCallback onTap;
  final String? statCount;

  const _AnimatedGridButton({
    required this.title,
    required this.icon,
    this.assetPath,
    required this.color,
    required this.onTap,
    this.statCount,
  });

  @override
  State<_AnimatedGridButton> createState() => _AnimatedGridButtonState();
}

class _AnimatedGridButtonState extends State<_AnimatedGridButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withOpacity(0.8), widget.color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: widget.statCount != null
                      ? Center(
                    child: Text(
                      widget.statCount!,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))
                          ]
                      ),
                    ),
                  )
                      : (widget.assetPath != null
                      ? Image.asset(
                    widget.assetPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Center(
                        child: Icon(widget.icon, size: 28, color: Colors.white)),
                  )
                      : Center(
                      child: Icon(widget.icon, size: 28, color: Colors.white))),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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

  // دالة توليد كود الفيزا العشوائي
  String _generateRandomVisaCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Widget _buildLastSeenWidget(Timestamp? lastSeenTimestamp) {
    if (lastSeenTimestamp == null) {
      return const Text(
        'لم يُسجل',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final lastSeen = lastSeenTimestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return const Text(
        'متصل الآن',
        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
      );
    } else if (difference.inMinutes < 60) {
      return Text(
        'آخر ظهور: ${difference.inMinutes} د',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (difference.inHours < 24) {
      return Text(
        'آخر ظهور: ${difference.inHours} س',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (difference.inDays == 1) {
      return const Text(
        'آخر ظهور: أمس',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else {
      return Text(
        intl.DateFormat('yyyy/MM/dd', 'ar').format(lastSeen),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
  }

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

      final emailQuery =
      await FirebaseFirestore.instance.collection('students').where('email', isEqualTo: query.toLowerCase()).get();

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
        numberEmailQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: 'a-dummy-email-that-will-never-exist')
            .get();
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

  // ✅✅✅ دالة إعادة تعيين رمز الفيزا (عملية حساسة) ✅✅✅
  Future<void> _handleVisaReset(String studentId, String studentName) async {
    // 1. التأكيد الأول
    final bool? confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير رمز الفيزا'),
        content: Text('هل تريد تغيير رمز الفيزا للطالب: $studentName؟\nالرمز القديم سيتوقف عن العمل فوراً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم، متابعة')),
        ],
      ),
    );

    if (confirm1 != true) return;

    // 2. التأكيد الثاني (تحذير أحمر)
    final bool? confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('تحذير هام')]),
        content: const Text(
          'هذه العملية لا يمكن التراجع عنها.\nسيتم فقدان الرمز السابق نهائياً.\nهل أنت متأكد تماماً؟',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، أنا متأكد'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    // 3. التأكيد الثالث (إدخال PIN الأدمن)
    final pinController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? pinConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isChecking = false;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('تأكيد الأمان'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الرجاء إدخال الرقم السري للأدمن لإتمام العملية:'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'رمز الأدمن (PIN)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      return null;
                    },
                  ),
                  if (isChecking) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: isChecking ? null : () => Navigator.pop(context, false),
                  child: const Text('إلغاء')
              ),
              ElevatedButton(
                onPressed: isChecking ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setDialogState(() => isChecking = true);
                    try {
                      // التحقق من الرمز من الفايربيز
                      final doc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
                      final String correctPin = doc.data()?['admin_pin']?.toString() ?? '010';

                      if (pinController.text.trim() == correctPin) {
                        if (mounted) Navigator.pop(context, true);
                      } else {
                        setDialogState(() => isChecking = false);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز غير صحيح!'), backgroundColor: Colors.red));
                      }
                    } catch (e) {
                      setDialogState(() => isChecking = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('تأكيد وتغيير'),
              ),
            ],
          );
        });
      },
    );

    if (pinConfirmed == true) {
      try {
        final String newCode = _generateRandomVisaCode();
        await FirebaseFirestore.instance.collection('students').doc(studentId).update({
          'visaCode': newCode,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تغيير رمز الفيزا للطالب $studentName بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red),
          );
        }
      }
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
                final lastSeen = data['lastSeen'] as Timestamp?;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    subtitle: Text('$grade / $className'),
                    // ✅ تعديل هنا لإضافة زر الخيارات
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLastSeenWidget(lastSeen),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'reset_visa') {
                              _handleVisaReset(student.id, name);
                            } else if (value == 'view_profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentViewPage(studentId: student.id),
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'view_profile',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('عرض الملف'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'reset_visa',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('تغيير رمز الفيزا'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
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

class ComplaintsBoxPage extends StatefulWidget {
  const ComplaintsBoxPage({super.key});

  @override
  State<ComplaintsBoxPage> createState() => _ComplaintsBoxPageState();
}

class _ComplaintsBoxPageState extends State<ComplaintsBoxPage> {
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
      body: StreamBuilder<QuerySnapshot>(
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
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('صندوق الشكاوى فارغ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('لم تصل أي ردود من أولياء الأمور بعد.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

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

  Future<void> _submitTeacherFinalReply() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

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
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final replierName = currentUserDoc.data()?['name'] ?? 'معلم';

      final reportRef = FirebaseFirestore.instance.collection('behavior_reports').doc(widget.reportDoc.id);
      final reportData = widget.reportDoc.data() as Map<String, dynamic>? ?? {};
      final studentId = reportData['studentId'];
      final subject = reportData['subject'];

      final batch = FirebaseFirestore.instance.batch();

      batch.update(reportRef, {
        'teacherFinalReply': _finalReplyController.text.trim(),
        'teacherFinalReplyTimestamp': FieldValue.serverTimestamp(),
        'status': 'closed',
        'finalReplierId': currentUser.uid,
        'finalReplierName': replierName,
      });

      if (studentId != null) {
        final studentNotificationRef =
        FirebaseFirestore.instance.collection('students').doc(studentId).collection('notifications').doc();
        batch.set(studentNotificationRef, {
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

    final finalReplierName = data['finalReplierName'] as String?;
    final originalTeacherName = data['teacherName'] ?? 'المعلم';
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
                author: 'رد نهائي من: أ. ${finalReplierName ?? originalTeacherName}',
                text: teacherFinalReply,
                timestamp: finalReplyTimestamp,
                isFinal: true,
              ),
            ] else ...[
              const Divider(height: 24),
              if (FirebaseAuth.instance.currentUser != null)
                FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
                    builder: (context, snapshot) {
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
                      return const SizedBox.shrink();
                    }),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildConversationBubble(
      BuildContext context, {
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
                    child: Text('لم يتم تسجيل أي ملاحظات سلوكية على الطلاب بعد.',
                        style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
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

Future<void> _saveAndDownloadExcel(BuildContext context, Excel excel, String fileName) async {
  final fileBytes = excel.save();
  if (fileBytes == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('فشل إنشاء ملف Excel.'), backgroundColor: Colors.red));
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تم تصدير الملف بنجاح: $fileName'), backgroundColor: Colors.green));
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('فشل تصدير الملف: $e'), backgroundColor: Colors.red));
  }
}

class SubjectCompletionResult {
  final String subjectName;
  final double percentage;
  final int totalEntries;
  final int enteredEntries;
  final List<DefaultingTeacherInfo> defaultingTeachers;

  SubjectCompletionResult({
    required this.subjectName,
    required this.percentage,
    required this.totalEntries,
    required this.enteredEntries,
    required this.defaultingTeachers,
  });
}

class DefaultingTeacherInfo {
  final String teacherName;
  final String classKey;
  final int missingCount;

  DefaultingTeacherInfo({
    required this.teacherName,
    required this.classKey,
    required this.missingCount,
  });
}

class GradeCompletionAnalyticsPage extends StatefulWidget {
  const GradeCompletionAnalyticsPage({super.key});

  @override
  _GradeCompletionAnalyticsPageState createState() => _GradeCompletionAnalyticsPageState();
}

class _GradeCompletionAnalyticsPageState extends State<GradeCompletionAnalyticsPage> {
  bool _isLoading = true;
  String _loadingStatus = 'جاري التحضير...';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<SubjectCompletionResult>> _testResults = {};

  static const Map<String, String> _regularSubjects = {
    'profession1': 'رياضيات',
    'profession2': 'لغتي',
    'profession6': 'انجليزي',
    'profession4': 'علوم',
    'profession7': 'اجتماعيات',
  };

  static const Map<String, String> _regularTestGroups = {
    'الاختبار الدوري الأول': 'e1',
    'الاختبار الدوري الثاني': 'e2',
    'الاختبار الدوري الثالث': 'e3',
    'اختبار قبلي': 'e14',
    'اختبار بعدي': 'e15',
    'اختبار احتياطي': 'e16',
  };

  static const Map<String, String> _nafesSubjectSuffixes = {
    'math': 'رياضيات',
    'lughati': 'لغتي',
    'science': 'علوم',
  };

  static const Map<String, String> _nafesTestGroups = {
    'نافس - الأول أساسي': 'e1profession13',
    'نافس - الثاني أساسي': 'e2profession13',
    'نافس - الاول ف نافس': 'e3profession13',
    'نافس - الثاني ف نافس': 'e4profession13',
    'نافس - الثالث ف نافس': 'e5profession13',
    'نافس - الرابع ف نافس': 'e6profession13',
    'نافس - الخامس ف نافس': 'e7profession13',
    'نافس - السادس ف نافس': 'e8profession13',
    'نافس - السابع ف نافس': 'e9profession13',
    'نافس - الثامن ف نافس': 'e10profession13',
    'نافس - التاسع ف نافس': 'e11profession13',
    'نافس - العاشر ف نافس': 'e12profession13',
  };

  @override
  void initState() {
    super.initState();
    _runAnalytics();
  }

  Map<String, String> _buildTeacherStructure(List<QueryDocumentSnapshot> allTeachers) {
    final Map<String, String> classSubjectToTeacherName = {};

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

    for (var teacherDoc in allTeachers) {
      final data = teacherDoc.data() as Map<String, dynamic>;
      final teacherName = data['name'] as String? ?? 'معلم غير معروف';
      if (data['profession'] == 'admin' || data['profession'] == 'gest') continue;

      structure.forEach((stageName, stageInfo) {
        final stageData = stageInfo as Map<String, dynamic>;
        if (data[stageData['field']] != null && data[stageData['field']] != '0') {
          final gradesMap = stageData['grades'] as Map<String, dynamic>?;
          if (gradesMap != null) {
            gradesMap.forEach((gradeName, gradeInfo) {
              final gradeData = gradeInfo as Map<String, dynamic>;
              if (data[gradeData['field']] != null && data[gradeData['field']] != '0') {
                final classValue = data[gradeData['classField']];
                if (classValue is String && classValue.isNotEmpty && classValue != '0') {
                  final pairs = classValue.split(',');
                  for (final pair in pairs) {
                    final parts = pair.split('=');
                    if (parts.length == 2) {
                      final className = parts[0].trim();
                      final subjectName = parts[1].trim();
                      final classSubjectKey = "$stageName-$gradeName-$className-$subjectName";
                      classSubjectToTeacherName[classSubjectKey] = teacherName;
                    }
                  }
                }
              }
            });
          }
        }
      });
    }
    return classSubjectToTeacherName;
  }

  Future<void> _runAnalytics() async {
    try {
      if (!mounted) return;
      setState(() {
        _loadingStatus = 'جاري جلب بيانات الطلاب...';
      });
      final studentsSnapshot = await _firestore.collection('students').get();
      final allStudents = studentsSnapshot.docs;

      if (!mounted) return;
      setState(() {
        _loadingStatus = 'جاري جلب بيانات المعلمين والمهام...';
      });
      final teachersSnapshot = await _firestore.collection('users').get();
      final allTeachers = teachersSnapshot.docs;

      final classSubjectToTeacherName = _buildTeacherStructure(allTeachers);

      if (!mounted) return;
      setState(() {
        _loadingStatus = 'جاري تحليل البيانات وحساب النسب...';
      });

      await Future.delayed(const Duration(milliseconds: 100));

      final Map<String, List<SubjectCompletionResult>> finalResults = {};

      int processCounter = 0;

      for (var groupEntry in _regularTestGroups.entries) {
        final groupName = groupEntry.key;
        final testPrefix = groupEntry.value;
        final Map<String, Map<String, int>> subjectStats = {
          for (var subject in _regularSubjects.values) subject: {'total': 0, 'entered': 0}
        };

        final Map<String, Map<String, Map<String, int>>> teacherMisses = {
          for (var subject in _regularSubjects.values) subject: {}
        };

        for (var student in allStudents) {
          processCounter++;
          if (processCounter % 100 == 0) {
            await Future.delayed(Duration.zero);
          }

          final studentData = student.data() as Map<String, dynamic>;
          final classKey = "${studentData['stages']}-${studentData['grades']}-${studentData['classes']}";

          for (var subjectEntry in _regularSubjects.entries) {
            final profKey = subjectEntry.key;
            final subjectName = subjectEntry.value;
            final testFieldKey = "$testPrefix$profKey";

            subjectStats[subjectName]!['total'] = (subjectStats[subjectName]!['total'] ?? 0) + 1;

            final dynamic gradeValue = studentData[testFieldKey];
            bool isEntered = false;

            if (gradeValue != null && gradeValue is num && gradeValue > 0) {
              isEntered = true;
            }

            if (isEntered) {
              subjectStats[subjectName]!['entered'] = (subjectStats[subjectName]!['entered'] ?? 0) + 1;
            } else {
              final classSubjectKey = "$classKey-$subjectName";
              final teacherName = classSubjectToTeacherName[classSubjectKey];
              if (teacherName != null) {
                teacherMisses[subjectName]!.update(
                  teacherName,
                      (map) {
                    map.update(classKey, (count) => count + 1, ifAbsent: () => 1);
                    return map;
                  },
                  ifAbsent: () => {classKey: 1},
                );
              }
            }
          }
        }

        final List<SubjectCompletionResult> results = [];
        subjectStats.forEach((subjectName, stats) {
          final total = stats['total']!;
          final entered = stats['entered']!;
          final percentage = (total == 0) ? 0.0 : (entered / total);

          final List<DefaultingTeacherInfo> defaultingTeachers = [];
          teacherMisses[subjectName]!.forEach((teacherName, classes) {
            classes.forEach((classKey, missingCount) {
              defaultingTeachers.add(DefaultingTeacherInfo(
                teacherName: teacherName,
                classKey: classKey.replaceAll('-', ' / '),
                missingCount: missingCount,
              ));
            });
          });

          results.add(SubjectCompletionResult(
            subjectName: subjectName,
            percentage: percentage,
            totalEntries: total,
            enteredEntries: entered,
            defaultingTeachers: defaultingTeachers..sort((a, b) => b.missingCount.compareTo(a.missingCount)),
          ));
        });
        finalResults[groupName] = results..sort((a, b) => b.percentage.compareTo(a.percentage));
      }

      processCounter = 0;

      for (var groupEntry in _nafesTestGroups.entries) {
        final groupName = groupEntry.key;
        final testPrefix = groupEntry.value;
        final Map<String, Map<String, int>> subjectStats = {
          for (var subject in _nafesSubjectSuffixes.values) subject: {'total': 0, 'entered': 0}
        };
        final Map<String, Map<String, Map<String, int>>> teacherMisses = {
          for (var subject in _nafesSubjectSuffixes.values) subject: {}
        };

        for (var student in allStudents) {
          processCounter++;
          if (processCounter % 100 == 0) {
            await Future.delayed(Duration.zero);
          }

          final studentData = student.data() as Map<String, dynamic>;
          final grade = studentData['grades'] as String?;
          final classKey = "${studentData['stages']}-${grade}-${studentData['classes']}";

          if (grade != 'الصف الثالث' && grade != 'الصف السادس') {
            continue;
          }

          for (var subjectEntry in _nafesSubjectSuffixes.entries) {
            final subjectSuffix = subjectEntry.key;
            final subjectName = subjectEntry.value;

            if (grade == 'الصف الثالث' && subjectName == 'علوم') {
              continue;
            }

            final testFieldKey = "${testPrefix}_$subjectSuffix";

            subjectStats[subjectName]!['total'] = (subjectStats[subjectName]!['total'] ?? 0) + 1;

            final dynamic gradeValue = studentData[testFieldKey];
            bool isEntered = false;

            if (gradeValue != null && gradeValue is num && gradeValue > 0) {
              isEntered = true;
            }

            if (isEntered) {
              subjectStats[subjectName]!['entered'] = (subjectStats[subjectName]!['entered'] ?? 0) + 1;
            } else {
              final classSubjectKey = "$classKey-$subjectName";
              final teacherName = classSubjectToTeacherName[classSubjectKey];
              if (teacherName != null) {
                teacherMisses[subjectName]!.update(
                  teacherName,
                      (map) {
                    map.update(classKey, (count) => count + 1, ifAbsent: () => 1);
                    return map;
                  },
                  ifAbsent: () => {classKey: 1},
                );
              }
            }
          }
        }

        final List<SubjectCompletionResult> results = [];
        subjectStats.forEach((subjectName, stats) {
          final total = stats['total']!;
          final entered = stats['entered']!;
          final percentage = (total == 0) ? 0.0 : (entered / total);

          final List<DefaultingTeacherInfo> defaultingTeachers = [];
          teacherMisses[subjectName]!.forEach((teacherName, classes) {
            classes.forEach((classKey, missingCount) {
              defaultingTeachers.add(DefaultingTeacherInfo(
                teacherName: teacherName,
                classKey: classKey.replaceAll('-', ' / '),
                missingCount: missingCount,
              ));
            });
          });

          results.add(SubjectCompletionResult(
            subjectName: subjectName,
            percentage: percentage,
            totalEntries: total,
            enteredEntries: entered,
            defaultingTeachers: defaultingTeachers..sort((a, b) => b.missingCount.compareTo(a.missingCount)),
          ));
        });
        finalResults[groupName] = results..sort((a, b) => b.percentage.compareTo(a.percentage));
      }

      if (mounted) {
        setState(() {
          _testResults = finalResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error running analytics: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = "حدث خطأ: $e";
        });
      }
    }
  }

  void _showDefaultingTeachersDialog(BuildContext context, String subjectName, List<DefaultingTeacherInfo> teachers) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('المعلمون المقصرون - $subjectName'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              itemCount: teachers.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final item = teachers[index];
                return ListTile(
                  title: Text(item.teacherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.classKey),
                  trailing: Chip(
                    label: Text('${item.missingCount} طلاب'),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: TextStyle(color: Colors.red.shade900),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل استكمال رصد الدرجات'),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_loadingStatus, textAlign: TextAlign.center),
          ],
        ),
      )
          : _testResults.isEmpty
          ? Center(
        child: Text(
          _loadingStatus.contains('خطأ') ? _loadingStatus : 'لا توجد بيانات للتحليل.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: _testResults.entries.map((entry) {
          return _buildTestGroupCard(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildTestGroupCard(String groupName, List<SubjectCompletionResult> results) {
    final bool hasData = results.any((r) => r.totalEntries > 0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    groupName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (groupName.contains('نافس'))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'يتم احتساب طلاب الصف الثالث والسادس فقط (الثالث لا يشمل العلوم).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const Divider(),
            if (!hasData)
              const Center(child: Text('لا توجد بيانات رصد لهذا الاختبار.'))
            else
              ...results
                  .where((r) => r.totalEntries > 0)
                  .map((result) => _buildPercentageRow(
                context,
                result,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageRow(BuildContext context, SubjectCompletionResult result) {
    Color progressColor;
    if (result.percentage >= 1.0) {
      progressColor = Colors.green;
    } else if (result.percentage > 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    final bool hasDefaulters = result.defaultingTeachers.isNotEmpty;

    return InkWell(
      onTap: hasDefaulters
          ? () => _showDefaultingTeachersDialog(context, result.subjectName, result.defaultingTeachers)
          : null,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        result.subjectName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasDefaulters) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 16),
                      ]
                    ],
                  ),
                ),
                Text(
                  '${(result.percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: progressColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    percent: result.percentage,
                    lineHeight: 8.0,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: progressColor,
                    barRadius: const Radius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${result.enteredEntries} / ${result.totalEntries} إدخال',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (hasDefaulters)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'اضغط لعرض المعلمين المقصرين',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AbsenceStatsPage extends StatelessWidget {
  const AbsenceStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات الطلاب والغياب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_alt_rounded, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'إجمالي الطلاب المسجلين',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              FutureBuilder<AggregateQuerySnapshot>(
                future: FirebaseFirestore.instance.collection('students').count().get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('خطأ في التحميل', style: TextStyle(color: Colors.red));
                  }
                  final count = snapshot.data?.count ?? 0;
                  return Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'طالب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}