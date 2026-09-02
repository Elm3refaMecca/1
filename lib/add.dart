import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'add1.dart';
import 'main.dart'; // يحتوي على StudentPrintHelper و QRSessionTimer
import 'package:almarefamecca/add2.dart' hide QRSessionOverlay, QRSessionTimer;
import 'package:almarefamecca/secondary_pages.dart';
import 'package:almarefamecca/student_view.dart';
import 'lesson_prep_page.dart'; // ✅ استيراد صفحة تحضيري المضافة
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:excel/excel.dart' hide Border;
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
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BehaviorManager {
  static const List<String> positiveReasons = [
    'احترام الحصة وقوانين الصف',
    'الهدوء والالتزام',
    'المحافظة على الصلاة',
    'القدوة الحسنة للزملاء',
    'الإيثار ومساعدة الآخرين',
    'عدم الغيبة والنميمة',
    'النظافة الشخصية ونظافة المكان',
    'المشاركة الفعالة والإيجابية',
    'إحضار الأدوات المدرسية كاملة',
    'أخرى (إيجابي)'
  ];

  static const List<String> negativeReasons = [
    'إهانة المعلم (سلوك مرفوض)',
    'التهاون في الصلاة',
    'عدم الاهتمام بالنظافة',
    'ضرب الزملاء أو التشاجر',
    'إتلاف السبورة أو الأقلام',
    'إتلاف جهاز الكمبيوتر',
    'إتلاف جهاز العرض (البروجيكتور)',
    'إتلاف الممتلكات المدرسية (أخرى)',
    'التحدث بصوت مرتفع / إزعاج',
    'سب أو شتم الزميل',
    'خطأ فادح (استدعاء ولي أمر)',
    'شكوى خاصة من المعلم'
  ];

  static Future<void> showBehaviorDialog(BuildContext context, String studentId, String studentName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _BehaviorSelectionSheet(studentId: studentId, studentName: studentName),
    );
  }
}

class _BehaviorSelectionSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  const _BehaviorSelectionSheet({required this.studentId, required this.studentName});

  @override
  State<_BehaviorSelectionSheet> createState() => _BehaviorSelectionSheetState();
}

class _BehaviorSelectionSheetState extends State<_BehaviorSelectionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _submitBehavior(String type, String reason) async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final teacherDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final teacherName = teacherDoc.data()?['name'] ?? 'معلم';

      final batch = FirebaseFirestore.instance.batch();

      final reportRef = FirebaseFirestore.instance.collection('behavior_reports').doc();
      batch.set(reportRef, {
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'type': type,
        'reason': reason,
        'subject': 'سلوك',
        'timestamp': FieldValue.serverTimestamp(),
        'dateString': intl.DateFormat('yyyy/MM/dd').format(DateTime.now()),
        'status': type == 'dislike' ? 'pending_reply' : 'like_added',
      });

      final notificationRef = FirebaseFirestore.instance.collection('students').doc(widget.studentId).collection('notifications').doc();
      batch.set(notificationRef, {
        'title': type == 'like' ? '🌟 نقاط تميز' : '⚠️ تنبيه سلوكي',
        'message': type == 'like'
            ? 'حصل الطالب ${widget.studentName} على إشارة حسنة من أ. $teacherName.\nالسبب: $reason'
            : 'تم تسجيل ملاحظة سلوكية على الطالب ${widget.studentName} من أ. $teacherName.\nالسبب المباشر: $reason',
        'type': 'behavior',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      final studentRef = FirebaseFirestore.instance.collection('students').doc(widget.studentId);
      batch.update(studentRef, {
        type == 'like' ? 'totalLikes' : 'totalDislikes': FieldValue.increment(1),
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل ${type == 'like' ? 'التميز' : 'المخالفة'} وتصنيفها في أوسمة الطالب بنجاح.'),
            backgroundColor: type == 'like' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('سجل السلوك: ${widget.studentName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'إيجابي (Like)', icon: Icon(Icons.thumb_up_alt_rounded, color: Colors.green)),
                Tab(text: 'سلبي (Dislike)', icon: Icon(Icons.thumb_down_alt_rounded, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReasonList(BehaviorManager.positiveReasons, 'like', Colors.green.shade50),
                  _buildReasonList(BehaviorManager.negativeReasons, 'dislike', Colors.red.shade50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonList(List<String> reasons, String type, Color bgColor) {
    return Container(
      color: bgColor.withOpacity(0.3),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: reasons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final reason = reasons[index];
          final bool isCustom = reason.contains('أخرى') || reason.contains('شكوى') || reason.contains('خطأ فادح');

          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'like' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSubmitting ? null : () {
              if (isCustom) {
                _showCustomReasonDialog(type);
              } else {
                _submitBehavior(type, reason);
              }
            },
            child: Text(reason, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  void _showCustomReasonDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'like' ? 'سبب التميز' : 'تفاصيل المخالفة/الشكوى'),
        content: TextField(
          controller: _customReasonController,
          decoration: const InputDecoration(hintText: 'اكتب التفاصيل هنا...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_customReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _submitBehavior(type, _customReasonController.text.trim());
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
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
    await _fetchUserData();
    if (mounted) setState(() {});
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

  // --- نافذة تفعيل وإدارة شفرة المعلم السحابية ---
  void _showTeacherCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('shafra').doc(_user!.uid).snapshots(),
          builder: (context, snapshot) {
            bool isActive = false;
            int remainingMinutes = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final Timestamp? expiresAt = data['expiresAt'];
              if (expiresAt != null) {
                final diff = expiresAt.toDate().difference(DateTime.now());
                if (diff.inMinutes > 0) {
                  isActive = true;
                  remainingMinutes = diff.inMinutes;
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text('شفرة المعلم'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تقوم هذه الميزة بتوليد شفرة أمان مخفية صالحة لمدة نصف ساعة (30 دقيقة). تُحفظ الشفرة سحابياً لتأمين العمليات على شاشة الفصل في تطبيق الديسكتوب، دون إظهار الرقم للمعلم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 40),
                          const SizedBox(height: 8),
                          const Text('الشفرة مفعلة ومحفوظة سحابياً', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('متبقي على انتهاء الصلاحية: $remainingMinutes دقيقة', style: const TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.red, size: 40),
                          SizedBox(height: 8),
                          Text('لا توجد شفرة مفعلة حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync_lock),
                  label: Text(isActive ? 'تجديد الشفرة (30 دقيقة)' : 'تفعيل الشفرة الآن'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
                      final random = Random();
                      final code = (1000000 + random.nextInt(9000000)).toString();
                      final expiration = DateTime.now().add(const Duration(minutes: 30));

                      await FirebaseFirestore.instance.collection('shafra').doc(_user!.uid).set({
                        'teacherId': _user!.uid,
                        'teacherName': _userData?['name'] ?? 'معلم',
                        'code': code,
                        'expiresAt': Timestamp.fromDate(expiration),
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم توليد الشفرة وحفظها سحابياً بنجاح! تطبيق الديسكتوب جاهز للاستخدام.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء التفعيل: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _quickLogoutAllDevices() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تسجيل خروج طارئ سريع'),
          ],
        ),
        content: const Text('هل تريد إنهاء كافة الجلسات المفتوحة على جميع الأجهزة والسبورات وتسجيل الخروج فوراً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الخروج المباشر'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (_user != null) {
          final activeLogins = await FirebaseFirestore.instance
              .collection('smart_screen_logins')
              .where('teacherId', isEqualTo: _user!.uid)
              .get();

          for (var doc in activeLogins.docs) {
            await doc.reference.update({'status': 'terminated'});
          }
        }

        QRSessionTimer.stopSession();
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الخروج السريع وإسقاط الجلسات بنجاح.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _verifyAdminPin(BuildContext context, Function() onSuccess) async {
    final pinCtrl = TextEditingController();
    final fKey = GlobalKey<FormState>();

    void submitPin(StateSetter setDialogState, BuildContext ctx) async {
      if (fKey.currentState!.validate()) {
        setDialogState(() => true);
        try {
          final sDoc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
          final correctPin = sDoc.data()?['admin_pin']?.toString() ?? '010';

          if (pinCtrl.text.trim() == correctPin) {
            Navigator.pop(ctx);
            onSuccess();
          } else {
            setDialogState(() => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز السري غير صحيح!'), backgroundColor: Colors.red));
          }
        } catch (e) {
          setDialogState(() => false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
        }
      }
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool checking = false;
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.red),
                  SizedBox(width: 10),
                  Text('تأكيد الهوية (الأدمن)'),
                ],
              ),
              content: Form(
                key: fKey,
                child: TextFormField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'الرمز السري للأدمن (PIN)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'حقل مطلوب' : null,
                  onFieldSubmitted: (_) => submitPin(setDialogState, ctx),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: checking ? null : () => submitPin(setDialogState, ctx),
                  child: const Text('تأكيد'),
                ),
              ],
            );
          });
        }
    );
  }

  Future<void> _showPromoteYearDialog() async {
    final yearController = TextEditingController(text: "2025-2026");
    final formKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool isChecking = false;
          return StatefulBuilder(builder: (context, setDialogState) {
            return _isAdmin ? AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.move_up_rounded, color: Colors.purple),
                  SizedBox(width: 10),
                  Text('الاعتماد وترحيل العام'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'تنبيه هام: سيتم ترحيل جميع الطلاب للصف والمرحلة التالية، وأرشفة سجل درجاتهم للعام الحالي بالكامل ليتم الرجوع إليها لاحقاً.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: yearController,
                      decoration: const InputDecoration(
                        labelText: 'مسمى العام الحالي (للأرشفة)',
                        hintText: 'مثال: 2025-2026',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  onPressed: isChecking ? null : () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _verifyAdminPin(context, () async {
                        setState(() => _isLoading = true);
                        try {
                          await _executePromotion(yearController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم ترحيل الطلاب وأرشفة الدرجات بنجاح!'), backgroundColor: Colors.green));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الترحيل: $e'), backgroundColor: Colors.red));
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      });
                    }
                  },
                  child: const Text('متابعة الترحيل'),
                ),
              ],
            ) : const SizedBox.shrink();
          });
        }
    );
  }

  Future<void> _executePromotion(String archiveYear) async {
    final studentsSnap = await FirebaseFirestore.instance.collection('students').get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int operationCount = 0;

    Map<String, String> gradePromotion = {
      'الصف الأول': 'الصف الثاني',
      'الصف الثاني': 'الصف الثالث',
      'الصف الثالث': 'الصف الرابع',
      'الصف الرابع': 'الصف الخامس',
      'الصف الخامس': 'الصف السادس',
      'الصف السادس': 'الصف الأول المتوسط',
      'الصف الأول المتوسط': 'الصف الثاني المتوسط',
      'الصف الثاني المتوسط': 'الصف الثالث المتوسط',
      'الصف الثالث المتوسط': 'الصف الأول الثانوي',
      'الصف الأول الثانوي': 'الصف الثاني الثانوي',
      'الصف الثاني الثانوي': 'الصف الثالث الثانوي',
      'الصف الثالث الثانوي': 'خريج',
    };

    Map<String, String> stagePromotion = {
      'الصف الأول المتوسط': 'المرحلة المتوسطة',
      'الصف الأول الثانوي': 'المرحلة الثانوية',
    };

    for(var doc in studentsSnap.docs) {
      final data = doc.data();

      final archiveRef = doc.reference.collection('archives').doc(archiveYear);
      batch.set(archiveRef, data);
      operationCount++;

      if (operationCount >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        operationCount = 0;
      }

      String currentGrade = data['grades'] ?? '';
      String currentStage = data['stages'] ?? '';
      String newGrade = gradePromotion[currentGrade] ?? currentGrade;
      String newStage = stagePromotion[newGrade] ?? currentStage;

      Map<String, dynamic> updates = {
        'grades': newGrade,
        'stages': newStage,
      };

      data.forEach((key, value) {
        if ((key.startsWith('e') && key.contains('profession')) ||
            (key.startsWith('t2_e') && key.contains('profession')) ||
            key.startsWith('eval_')) {
          updates[key] = FieldValue.delete();
        }
      });

      batch.update(doc.reference, updates);
      operationCount++;

      if (operationCount >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
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
                          leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
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
    batch.commit().catchError((e) {});
  }

  void _showTeacherManagementDialog() {
    _verifyAdminPin(context, () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Colors.indigo),
              SizedBox(width: 8),
              Text('إدارة حسابات المعلمين'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigoAccent,
                  child: Icon(Icons.auto_mode_rounded, color: Colors.white),
                ),
                title: const Text('توليد حساب تلقائي للمعلم', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('توليد بريد وكلمة مرور عشوائية للرقم المتاح'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateTeacherDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.edit_note_rounded, color: Colors.white),
                ),
                title: const Text('انشاء حساب جديد بشكل يدوي', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إدخال الاسم والبريد وكلمة المرور وصلاحية الأدمن'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateTeacherManualDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.badge, color: Colors.white),
                ),
                title: const Text('بيانات المعلمين', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('استعراض المعلمين وبطاقاتهم التعريفية وحذفهم'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAccountsListPage()));
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ],
        ),
      );
    });
  }

  void _showCreateTeacherManualDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isAdminRole = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool creating = false;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إنشاء حساب جديد بشكل يدوي', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم المعلم كاملاً *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(labelText: 'كلمة المرور للمعلم *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('صلاحيات الأدمن', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('إعطاء هذا الحساب كافة صلاحيات مدير النظام'),
                    value: isAdminRole,
                    activeColor: Colors.indigo,
                    onChanged: (val) {
                      setDialogState(() => isAdminRole = val);
                    },
                  ),
                  if (creating) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: creating ? null : () async {
                  final String name = nameCtrl.text.trim();
                  final String email = emailCtrl.text.trim();
                  final String pass = passCtrl.text.trim();

                  if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تعبئة جميع الحقول المطلوبة')));
                    return;
                  }

                  setDialogState(() => creating = true);
                  try {
                    UserCredential? userCred;
                    FirebaseApp? tempApp;

                    tempApp = await Firebase.initializeApp(
                      name: 'manualTeacherCreation_${DateTime.now().millisecondsSinceEpoch}',
                      options: Firebase.app().options,
                    );

                    userCred = await FirebaseAuth.instanceFor(app: tempApp)
                        .createUserWithEmailAndPassword(email: email, password: pass);

                    String newAuthUid = userCred.user!.uid;
                    await tempApp.delete();

                    final newTeacherRef = FirebaseFirestore.instance.collection('users').doc(newAuthUid);
                    await newTeacherRef.set({
                      'uid': newAuthUid,
                      'name': name,
                      'email': email,
                      'pp': pass,
                      'profession': isAdminRole ? 'admin' : 'teacher',
                      'timestamp': FieldValue.serverTimestamp()
                    });

                    Navigator.pop(ctx);
                    _showTeacherAccountResultDialog(name, email, pass);
                  } catch (e) {
                    setDialogState(() => creating = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الإنشاء: $e')));
                  }
                },
                child: const Text('إنشاء الحساب وحفظه'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showCreateTeacherDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool creating = false;
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('انشاء حساب معلم جديد', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم المعلم كاملاً *', border: OutlineInputBorder()),
                    ),
                    if (creating) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: creating ? null : () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة اسم المعلم')));
                      return;
                    }
                    setDialogState(() => creating = true);
                    try {
                      int nextAvailableNumber = 61;
                      final existingSnap = await FirebaseFirestore.instance.collection('users').get();
                      final Set<int> busyNumbers = {};
                      for (var d in existingSnap.docs) {
                        final emailStr = d.data()['email']?.toString() ?? '';
                        if (emailStr.contains('@t.com')) {
                          final numPart = emailStr.split('@').first;
                          final parsed = int.tryParse(numPart);
                          if (parsed != null) busyNumbers.add(parsed);
                        }
                      }

                      while (busyNumbers.contains(nextAvailableNumber)) {
                        nextAvailableNumber++;
                      }

                      final random = Random();
                      final finalPassword = List.generate(8, (_) => random.nextInt(10).toString()).join();
                      String finalEmail = '$nextAvailableNumber@t.com';

                      UserCredential? userCred;
                      FirebaseApp? tempApp;

                      while (userCred == null) {
                        finalEmail = '$nextAvailableNumber@t.com';
                        try {
                          tempApp = await Firebase.initializeApp(
                            name: 'tempTeacherCreation_${DateTime.now().millisecondsSinceEpoch}_$nextAvailableNumber',
                            options: Firebase.app().options,
                          );

                          userCred = await FirebaseAuth.instanceFor(app: tempApp)
                              .createUserWithEmailAndPassword(email: finalEmail, password: finalPassword);
                        } on FirebaseAuthException catch (authErr) {
                          if (tempApp != null) {
                            await tempApp.delete();
                            tempApp = null;
                          }
                          if (authErr.code == 'email-already-in-use') {
                            nextAvailableNumber++;
                          } else {
                            rethrow;
                          }
                        } catch (e) {
                          if (tempApp != null) {
                            await tempApp.delete();
                            tempApp = null;
                          }
                          rethrow;
                        }
                      }

                      String newAuthUid = userCred.user!.uid;
                      if (tempApp != null) {
                        await tempApp.delete();
                      }

                      final newTeacherRef = FirebaseFirestore.instance.collection('users').doc(newAuthUid);
                      await newTeacherRef.set({
                        'uid': newAuthUid,
                        'name': nameCtrl.text.trim(),
                        'email': finalEmail,
                        'pp': finalPassword,
                        'profession': 'teacher',
                        'timestamp': FieldValue.serverTimestamp()
                      });

                      Navigator.pop(ctx);
                      _showTeacherAccountResultDialog(nameCtrl.text.trim(), finalEmail, finalPassword);
                    } catch (e) {
                      setDialogState(() => creating = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الإنشاء: $e')));
                    }
                  },
                  child: const Text('توليد حساب المعلم وحفظه'),
                ),
              ],
            );
          });
        }
    );
  }

  void _showTeacherAccountResultDialog(String name, String email, String pass) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('تم إنشاء حساب المعلم بنجاح'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اسم المعلم: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('البريد الإلكتروني: $email'),
                      const SizedBox(height: 4),
                      Text('كلمة المرور للحساب: $pass'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('نسخ البيانات'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'بيانات حساب المعلم:\nالاسم: $name\nالبريد: $email\nكلمة المرور: $pass'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ البيانات بنجاح!'), backgroundColor: Colors.green));
                },
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ],
          );
        }
    );
  }

  void _showCreateStudentDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nationalIdCtrl = TextEditingController();
    String selectedStage = 'المرحلة الابتدائية';
    String? selectedGrade;
    String selectedClass = 'الفصل 1';

    final List<String> stages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
    final List<String> primaryGrades = ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'];
    final List<String> intermediateGrades = ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'];
    final List<String> secondaryGrades = ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];

    List<String> getGrades() {
      if (selectedStage == 'المرحلة الابتدائية') return primaryGrades;
      if (selectedStage == 'المرحلة المتوسطة') return intermediateGrades;
      return secondaryGrades;
    }

    selectedGrade = getGrades().first;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool creating = false;
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('انشاء حساب طالب جديد', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الطالب رباعي *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStage,
                      decoration: const InputDecoration(labelText: 'المرحلة الدراسية *', border: OutlineInputBorder()),
                      items: stages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedStage = val!;
                          selectedGrade = getGrades().first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGrade,
                      decoration: const InputDecoration(labelText: 'الصف *', border: OutlineInputBorder()),
                      items: getGrades().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setDialogState(() => selectedGrade = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: const InputDecoration(labelText: 'الفصل *', border: OutlineInputBorder()),
                      items: List.generate(10, (i) => 'الفصل ${i + 1}').map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setDialogState(() => selectedClass = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم هاتف ولي الأمر (اختياري)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: nationalIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رقم هوية الطالب (اختياري)', border: OutlineInputBorder())),
                    if (creating) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: creating ? null : () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة اسم الطالب')));
                      return;
                    }
                    setDialogState(() => creating = true);
                    try {
                      int nextAvailableNumber = 601;
                      final existingSnap = await FirebaseFirestore.instance.collection('students').get();
                      final Set<int> busyNumbers = {};
                      for (var d in existingSnap.docs) {
                        final emailStr = d.data()['email']?.toString() ?? '';
                        if (emailStr.contains('@')) {
                          final numPart = emailStr.split('@').first;
                          final parsed = int.tryParse(numPart);
                          if (parsed != null) busyNumbers.add(parsed);
                        }
                      }

                      while (busyNumbers.contains(nextAvailableNumber)) {
                        nextAvailableNumber++;
                      }

                      final random = Random();
                      final finalPassword = List.generate(8, (_) => random.nextInt(10).toString()).join();
                      const String complaintsPin = '0000';

                      UserCredential? userCred;
                      FirebaseApp? tempApp;
                      String finalEmail = '$nextAvailableNumber@elma3refa.com';

                      while (userCred == null) {
                        finalEmail = '$nextAvailableNumber@elma3refa.com';
                        try {
                          tempApp = await Firebase.initializeApp(
                            name: 'tempStudentCreation_${DateTime.now().millisecondsSinceEpoch}_$nextAvailableNumber',
                            options: Firebase.app().options,
                          );

                          userCred = await FirebaseAuth.instanceFor(app: tempApp)
                              .createUserWithEmailAndPassword(email: finalEmail, password: finalPassword);
                        } on FirebaseAuthException catch (authErr) {
                          if (tempApp != null) {
                            await tempApp.delete();
                            tempApp = null;
                          }
                          if (authErr.code == 'email-already-in-use') {
                            nextAvailableNumber++;
                          } else {
                            rethrow;
                          }
                        } catch (e) {
                          if (tempApp != null) {
                            await tempApp.delete();
                            tempApp = null;
                          }
                          rethrow;
                        }
                      }

                      String newAuthUid = userCred.user!.uid;
                      if (tempApp != null) {
                        await tempApp.delete();
                      }

                      final newStudentRef = FirebaseFirestore.instance.collection('students').doc(newAuthUid);
                      await newStudentRef.set({
                        'uid': newAuthUid,
                        'name': nameCtrl.text.trim(),
                        'stages': selectedStage,
                        'grades': selectedGrade,
                        'classes': selectedClass,
                        'guardian_phone': phoneCtrl.text.trim().isEmpty ? '-' : phoneCtrl.text.trim(),
                        'national_id': nationalIdCtrl.text.trim().isEmpty ? '-' : nationalIdCtrl.text.trim(),
                        'email': finalEmail,
                        'pp': finalPassword,
                        'complaints_pin': '0000',
                        'totalLikes': 0,
                        'totalDislikes': 0,
                        'timestamp': FieldValue.serverTimestamp()
                      });

                      Navigator.pop(ctx);
                      _showAccountResultDialog(nameCtrl.text.trim(), finalEmail, finalPassword, complaintsPin, selectedClass);
                    } catch (e) {
                      setDialogState(() => creating = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الإنشاء: $e')));
                    }
                  },
                  child: const Text('توليد الحساب وحفظه'),
                ),
              ],
            );
          });
        }
    );
  }

  void _showAccountResultDialog(String name, String email, String pass, String pin, String cls) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('تم إنشاء الحساب بنجاح'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اسم الطالب: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('الفصل المسند: $cls'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('البريد الإلكتروني: $email'),
                      const SizedBox(height: 4),
                      Text('كلمة المرور للحساب: $pass'),
                      const SizedBox(height: 4),
                      Text('الرمز السري للشكاوى: $pin', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('يمكنك طباعة أو نسخ البيانات كاملة لإعطائها لولي الأمر مباشرة.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة الباركود'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال أمر الطباعة')));
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('نسخ البيانات'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'بيانات حساب الطالب المكتملة:\nالاسم: $name\nالفصل: $cls\nالبريد: $email\nكلمة المرور: $pass\nالرمز السري للشكاوى: $pin'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ بيانات الحساب بنجاح!'), backgroundColor: Colors.green));
                },
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ],
          );
        }
    );
  }

  void _showClassListDialog() {
    String selectedStage = 'المرحلة الابتدائية';
    String? selectedGrade;
    String selectedClass = 'الفصل 1';

    final List<String> stages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
    final List<String> primaryGrades = ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'];
    final List<String> intermediateGrades = ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'];
    final List<String> secondaryGrades = ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];

    List<String> getGrades() {
      if (selectedStage == 'المرحلة الابتدائية') return primaryGrades;
      if (selectedStage == 'المرحلة المتوسطة') return intermediateGrades;
      return secondaryGrades;
    }

    selectedGrade = getGrades().first;

    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('استعراض قوائم الفصول والمراحل', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStage,
                    decoration: const InputDecoration(labelText: 'المرحلة الدراسية', border: OutlineInputBorder()),
                    items: stages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedStage = val!;
                        selectedGrade = getGrades().first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(labelText: 'الصف الدراسي', border: OutlineInputBorder()),
                    items: getGrades().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => selectedGrade = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'الفصل الدراسي', border: OutlineInputBorder()),
                    items: List.generate(10, (i) => 'الفصل ${i + 1}').map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => selectedClass = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClassStudentsListPage(stage: selectedStage, grade: selectedGrade!, className: selectedClass, verifyAdminPin: _verifyAdminPin)));
                  },
                  child: const Text('عرض القائمة'),
                )
              ],
            );
          });
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade400,
        elevation: 0,
        title: const Text('لوحة التحكم الرئيسي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Colors.white),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'تسجيل الخروج السريع لجميع الأجهزة',
            onPressed: _quickLogoutAllDevices,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildTeacherDashboard(),
        ),
      ),
    );
  }

  Widget _buildTeacherDashboard() {
    final bool isGuest = _userProfession == 'gest';
    final bool showAdminFeatures = _isAdmin || isGuest;
    String jobTitle = _isAdmin ? 'مدير النظام' : 'معلم';

    double screenWidth = MediaQuery.of(context).size.width;
    int columns = screenWidth > 1200 ? 8 : screenWidth > 800 ? 6 : 4;

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
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
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
                    ? const Icon(Icons.person_rounded, color: Colors.blue, size: 26)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'مرحباً، ${_userData?['name'] ?? '...'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      jobTitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 20,
            childAspectRatio: 0.85,
            children: [
              // --- ميزة الخطة التشغيلية للمدير ---
              if (_isAdmin)
                _AnimatedGridButton(
                  title: 'الخطة التشغيلية',
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOperationalPlanPage()));
                  },
                ),

              // --- ميزة تحضيري (جديدة ومربوطة مباشرة بملف lesson_prep_page.dart) ---
              _AnimatedGridButton(
                title: _isAdmin ? 'متابعة التحضير' : 'تحضيري',
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF00796B),
                onTap: () async {
                  if (isGuest) {
                    _showGuestError();
                    return;
                  }
                  if (_isAdmin) {
                    // المدير ينتقل للشاشة مباشرة للاختيار من القائمة
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LessonPrepSchedulePage(),
                      ),
                    );
                    return;
                  }
                  try {
                    final scheduleDoc = await FirebaseFirestore.instance
                        .collection('teacher_schedules')
                        .doc(_user!.uid)
                        .get();

                    if (!scheduleDoc.exists || scheduleDoc.data()?['status'] != 'approved') {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('عفواً، لا يوجد جدول حصص معتمد لك حالياً. يرجى اعتماد جدولك أولاً من قسم الخدمات والجداول.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonPrepSchedulePage(
                            teacherScheduleData: scheduleDoc.data()!,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء جلب الجدول: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),

              // --- ميزة شفرة المعلم السحابية ---
              _AnimatedGridButton(
                title: 'شفرة المعلم',
                icon: Icons.vpn_key_rounded,
                color: Colors.blueGrey,
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    _showTeacherCodeDialog();
                  }
                },
              ),
              _AnimatedGridButton(
                title: 'الخدمات والجداول',
                icon: Icons.dashboard_customize_rounded,
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Add2Page()),
                  );
                },
              ),
              _AnimatedGridButton(
                title: 'البروشورات والأقسام',
                icon: Icons.view_carousel_rounded,
                color: Colors.cyan.shade700,
                onTap: () {
                  if (_isAdmin) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBrochuresManagementPage()));
                  } else {
                    _verifyAdminPin(context, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBrochuresManagementPage()));
                    });
                  }
                },
              ),
              _AnimatedGridButton(
                title: 'رصد الدرجات',
                icon: Icons.edit_document,
                color: const Color(0xFF2962FF),
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GradeEntrySelectionPage(isBehaviorMode: false, isAdmin: _isAdmin)));
                  }
                },
              ),
              if (_isAdmin) ...[
                _AnimatedGridButton(
                  title: 'انشاء حساب طالب',
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFF00796B),
                  onTap: _showCreateStudentDialog,
                ),
                _AnimatedGridButton(
                  title: 'إدارة حسابات المعلمين',
                  icon: Icons.badge_rounded,
                  color: Colors.indigo,
                  onTap: _showTeacherManagementDialog,
                ),
                _AnimatedGridButton(
                  title: 'قوائم الفصول',
                  icon: Icons.view_list_rounded,
                  color: const Color(0xFF455A64),
                  onTap: _showClassListDialog,
                ),
              ],
              _AnimatedGridButton(
                title: 'الطالب المنضبط',
                icon: Icons.star_rounded,
                color: const Color(0xFFFF9100),
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GradeEntrySelectionPage(isBehaviorMode: true, isAdmin: _isAdmin)));
                  }
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('behavior_reports')
                    .where('status', whereIn: ['replied_by_student', 'new', 'pending'])
                    .snapshots(),
                builder: (context, snapshot) {
                  int msgCount = 0;
                  if (snapshot.hasData && _user != null) {
                    final docs = snapshot.data!.docs;
                    if (_isAdmin) {
                      msgCount = docs.length;
                    } else {
                      msgCount = docs.where((d) => (d.data() as Map)['teacherId'] == _user!.uid).length;
                    }
                  }

                  return _AnimatedGridButton(
                    title: 'صندوق الشكاوى',
                    icon: Icons.mark_email_unread_rounded,
                    color: const Color(0xFFFF3D00),
                    badgeCount: msgCount,
                    onTap: () {
                      if (isGuest) {
                        _showGuestError();
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsBoxPage()));
                      }
                    },
                  );
                },
              ),
              _AnimatedGridButton(
                title: 'تحليل المخالفات',
                icon: Icons.analytics_rounded,
                color: const Color(0xFFD50000),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ViolationsLogPage()));
                },
              ),
              if (showAdminFeatures)
                _AnimatedGridButton(
                  title: 'بحث نتائج طالب',
                  icon: Icons.person_search_rounded,
                  color: const Color(0xFF00C853),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSearchPage()));
                  },
                ),
              if (_isAdmin)
                _AnimatedGridButton(
                  title: 'اعتماد وترحيل',
                  icon: Icons.move_up_rounded,
                  color: const Color(0xFF8E24AA),
                  onTap: _showPromoteYearDialog,
                ),
              _AnimatedGridButton(
                title: 'ملف إنجازي',
                icon: Icons.folder_shared_rounded,
                color: const Color(0xFF37474F),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherPortfolioFormPage()));
                },
              ),
              _AnimatedGridButton(
                title: 'سجل ملفات الإنجاز',
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF00695C),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTeachersPortfoliosPage()));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

// =============================================================================
// صفحة إدارة البروشورات والأقسام التفاعلية
// =============================================================================
class AdminBrochuresManagementPage extends StatefulWidget {
  const AdminBrochuresManagementPage({super.key});

  @override
  State<AdminBrochuresManagementPage> createState() => _AdminBrochuresManagementPageState();
}

class _AdminBrochuresManagementPageState extends State<AdminBrochuresManagementPage> {
  bool _isUploading = false;

  final Map<String, String> _typeLabels = {
    'hero': 'بروشور علوي (بداية الموقع)',
    'middle': 'بروشور منتصف الموقع',
    'awards': 'جوائز المدرسة 🏆',
    'logos': 'لوجوهات المدرسة 🎨',
    'reels': 'ريلز الطلاب (مقاطع قصيرة) 🎬',
    'facilities': 'مرافق المدرسة 🏫',
  };

  Future<void> _uploadBrochure(String defaultType) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;
    bool isVideo = (defaultType == 'reels');

    if (isVideo) {
      file = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }

    if (file == null) return;

    final int fileSize = await file.length();
    if (fileSize > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عفواً، حجم الملف يتجاوز الحد الأقصى (50 ميجابايت).'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    String selectedType = defaultType;
    final orderCtrl = TextEditingController(text: '1');
    final durationCtrl = TextEditingController(text: '4');
    final titleCtrl = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload_rounded, color: Colors.cyan),
              SizedBox(width: 8),
              Text('إعدادات المحتوى المرفوع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'اختر القسم المستهدف *', border: OutlineInputBorder()),
                  items: _typeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان أو الوصف (اختياري)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الترتيب (مثال: 1, 2, 3...)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (!isVideo)
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'زمن العرض بالثواني (مثال: 4)', border: OutlineInputBorder()),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade800, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('متابعة الرفع للسحابة'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploading = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final String ext = isVideo ? 'mp4' : 'jpg';
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$selectedType.$ext';

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('website_brochures')
          .child(fileName);

      await storageRef.putData(bytes, SettableMetadata(contentType: isVideo ? 'video/mp4' : 'image/jpeg'));
      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('website_brochures').add({
        'type': selectedType,
        'title': titleCtrl.text.trim(),
        'imageUrl': downloadUrl,
        'fileName': fileName,
        'isVideo': isVideo,
        'order': int.tryParse(orderCtrl.text.trim()) ?? 1,
        'durationSeconds': int.tryParse(durationCtrl.text.trim()) ?? 4,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الرفع وحفظ المحتوى بنجاح ✅'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الرفع: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _editBrochureProperties(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    String selectedType = data['type'] ?? 'hero';
    final orderCtrl = TextEditingController(text: (data['order'] ?? 1).toString());
    final durationCtrl = TextEditingController(text: (data['durationSeconds'] ?? 4).toString());
    final titleCtrl = TextEditingController(text: data['title'] ?? '');

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('تعديل الخصائص والترتيب ✏️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _typeLabels.containsKey(selectedType) ? selectedType : 'hero',
                  decoration: const InputDecoration(labelText: 'القسم المخصص', border: OutlineInputBorder()),
                  items: _typeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان / الوصف', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الترتيب الظاهري', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (data['isVideo'] != true)
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'زمن العرض بالثواني', border: OutlineInputBorder()),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      await doc.reference.update({
        'type': selectedType,
        'title': titleCtrl.text.trim(),
        'order': int.tryParse(orderCtrl.text.trim()) ?? 1,
        'durationSeconds': int.tryParse(durationCtrl.text.trim()) ?? 4,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الترتيب والخصائص بنجاح ✨'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _updateStatsDialog(String key, String title, String currentVal) async {
    final ctrl = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تحديث إحصائية: $title'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'العدد المعتمد', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('settings').doc('school_stats').set({
                key: ctrl.text.trim(),
              }, SetOptions(merge: true));
              Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الرقم بنجاح ✅'), backgroundColor: Colors.green));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البروشورات وأقسام المعرض'), backgroundColor: Colors.cyan.shade700, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isUploading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              const Center(child: Text('جاري رفع الملف إلى السحابة... يرجى الانتظار ⏳', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
            ],

            const Text('رفع محتوى جديد حسب القسم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildActionChip('بروشور علوي 🖼️', Colors.blue.shade800, () => _uploadBrochure('hero')),
                _buildActionChip('بروشور المنتصف 🖼️', Colors.teal.shade700, () => _uploadBrochure('middle')),
                _buildActionChip('جوائز المدرسة 🏆', Colors.amber.shade900, () => _uploadBrochure('awards')),
                _buildActionChip('لوجوهات المدرسة 🎨', Colors.purple.shade700, () => _uploadBrochure('logos')),
                _buildActionChip('ريلز الطلاب 🎬', Colors.red.shade700, () => _uploadBrochure('reels')),
                _buildActionChip('مرافق المدرسة 🏫', Colors.indigo.shade700, () => _uploadBrochure('facilities')),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            const Text('إحصائيات وأرقام المدرسة المعروضة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
            const SizedBox(height: 10),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('school_stats').snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final graduates = data['graduates_count']?.toString() ?? '1500+';
                final smiles = data['smiles_count']?.toString() ?? '50000+';

                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          title: const Text('إجمالي الخريجين', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(graduates, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateStatsDialog('graduates_count', 'إجمالي الخريجين', graduates),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        color: Colors.pink.shade50,
                        child: ListTile(
                          title: const Text('ابتسامة حققناها', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(smiles, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateStatsDialog('smiles_count', 'كم ابتسامة حققتها المدرسة', smiles),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const Text('المحتويات والبروشورات المرفوعة سحابياً:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('website_brochures').orderBy('order', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد عناصر مضافة حالياً.')));

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String typeKey = data['type'] ?? 'hero';
                    final typeText = _typeLabels[typeKey] ?? 'عام';
                    final String imageUrl = data['imageUrl'] ?? '';
                    final int order = data['order'] ?? (index + 1);
                    final int duration = data['durationSeconds'] ?? 4;
                    final bool isVideo = data['isVideo'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isVideo
                                ? Container(color: Colors.black12, child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 35))
                                : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        title: Text(data['title']?.isNotEmpty == true ? data['title'] : typeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('الترتيب: $order ${!isVideo ? "| مدة العرض: $duration ثوانٍ" : ""}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'تعديل الترتيب والخصائص',
                              onPressed: () => _editBrochureProperties(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'حذف',
                              onPressed: () async {
                                try {
                                  if (data['fileName'] != null) {
                                    await FirebaseStorage.instance.ref().child('website_brochures').child(data['fileName']).delete().catchError((_){});
                                  }
                                  await doc.reference.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحذف: $e')));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, Color color, VoidCallback onTap) {
    return ActionChip(
      elevation: 2,
      backgroundColor: color,
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: onTap,
    );
  }
}

class TeacherAccountsListPage extends StatefulWidget {
  const TeacherAccountsListPage({super.key});

  @override
  State<TeacherAccountsListPage> createState() => _TeacherAccountsListPageState();
}

class _TeacherAccountsListPageState extends State<TeacherAccountsListPage> {

  Future<void> _verifyAdminPinDialog(BuildContext context, Function() onSuccess) async {
    final pinCtrl = TextEditingController();
    final fKey = GlobalKey<FormState>();

    void submitPin(StateSetter setDialogState, BuildContext ctx) async {
      if (fKey.currentState!.validate()) {
        setDialogState(() => true);
        try {
          final sDoc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
          final correctPin = sDoc.data()?['admin_pin']?.toString() ?? '010';

          if (pinCtrl.text.trim() == correctPin) {
            Navigator.pop(ctx);
            onSuccess();
          } else {
            setDialogState(() => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز السري غير صحيح!'), backgroundColor: Colors.red));
          }
        } catch (e) {
          setDialogState(() => false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
        }
      }
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool checking = false;
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.red),
                  SizedBox(width: 10),
                  Text('تأكيد هوية الأدمن (PIN)'),
                ],
              ),
              content: Form(
                key: fKey,
                child: TextFormField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'الرمز السري للأدمن (PIN)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'حقل مطلوب' : null,
                  onFieldSubmitted: (_) => submitPin(setDialogState, ctx),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: checking ? null : () => submitPin(setDialogState, ctx),
                  child: const Text('تأكيد'),
                ),
              ],
            );
          });
        }
    );
  }

  void _showTeacherCard(BuildContext context, Map<String, dynamic> data) {
    final String name = data['name']?.toString() ?? data['Name']?.toString() ?? '-';
    final String email = data['email']?.toString() ?? data['Email']?.toString() ?? data['user_email']?.toString() ?? '-';
    final String pass = data['pp']?.toString() ?? data['Password']?.toString() ?? data['password']?.toString() ?? data['pass']?.toString() ?? 'مخفية لأسباب أمنية';

    _verifyAdminPinDialog(context, () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.badge, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(child: Text('البطاقة التعريفية: $name', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الاسم: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('البريد الإلكتروني: $email', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('كلمة المرور للحساب: $pass', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('نسخ البطاقة'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'البطاقة التعريفية للمعلم:\nالاسم: $name\nالبريد: $email\nكلمة المرور: $pass'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ بيانات البطاقة!'), backgroundColor: Colors.green));
              },
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ],
        ),
      );
    });
  }

  void _deleteTeacher(BuildContext context, String teacherId, String teacherName) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email?.toLowerCase().trim() ?? '';

    if (currentEmail != 'mostafa.said@gmail.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عفواً، الحساب mostafa.said@gmail.com فقط هو المخول بحذف المعلمين والأدمن!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    _verifyAdminPinDialog(context, () async {
      try {
        await FirebaseFirestore.instance.collection('users').doc(teacherId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف حساب المعلم ($teacherName) بنجاح.'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة بيانات المعلمين والأدمن'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد حسابات مدرجة حالياً.', style: TextStyle(color: Colors.grey)));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isAdmin = data['profession'] == 'admin';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red.shade100 : Colors.indigo.shade100,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? Colors.red : Colors.indigo,
                    ),
                  ),
                  title: Text(
                    '${data['name'] ?? ''}${isAdmin ? ' (أدمن)' : ''}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? Colors.red.shade900 : Colors.black87),
                  ),
                  subtitle: Text('البريد: ${data['email'] ?? '-'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.badge_rounded, color: Colors.indigo),
                        tooltip: 'عرض البطاقة التعريفية',
                        onPressed: () => _showTeacherCard(context, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                        tooltip: 'حذف الحساب',
                        onPressed: () => _deleteTeacher(context, doc.id, data['name'] ?? 'معلم'),
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

  Future<void> _handleVisaReset(String studentId, String studentName) async {
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

    final pinController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    void submitPin(StateSetter setDialogState, BuildContext ctx) async {
      if (formKey.currentState!.validate()) {
        setDialogState(() => true);
        try {
          final doc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
          final String correctPin = doc.data()?['admin_pin']?.toString() ?? '010';

          if (pinController.text.trim() == correctPin) {
            if (mounted) Navigator.pop(ctx, true);
          } else {
            setDialogState(() => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز غير صحيح!'), backgroundColor: Colors.red));
          }
        } catch (e) {
          setDialogState(() => false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
        }
      }
    }

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
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'رمز الأدمن (PIN)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      return null;
                    },
                    onFieldSubmitted: (_) => submitPin(setDialogState, context),
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
                onPressed: isChecking ? null : () => submitPin(setDialogState, context),
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
                prefixIcon: const Icon(Icons.search_rounded),
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
              onSubmitted: (value) {
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
                    leading: const Icon(Icons.person_rounded),
                    title: Text(name),
                    subtitle: Text('$grade / $className'),
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
                            } else if (value == 'behavior') {
                              BehaviorManager.showBehaviorDialog(context, student.id, name);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'view_profile',
                              child: Row(
                                children: const [
                                  Icon(Icons.visibility_rounded, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('عرض الملف'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'reset_visa',
                              child: Row(
                                children: const [
                                  Icon(Icons.refresh, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('تغيير رمز الفيزا'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'behavior',
                              child: Row(
                                children: const [
                                  Icon(Icons.thumb_up_alt_rounded, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('تسجيل سلوك'),
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
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صندوق الشكاوى والردود'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade100,
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه هام: يرجى عدم الرد على أي رسالة تخص معلم آخر. الرد مسؤولية المعلم المرسل للشكوى فقط.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                        Icon(Icons.inbox_rounded, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('صندوق الشكاوى فارغ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('لم تصل أي ردود من أولياء الأمور بعد.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['replyTimestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['replyTimestamp'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

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
          ),
        ],
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

    final teacherNote = data['reason'] ?? data['teacherNote'] ?? 'لا يوجد تفصيل.';
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
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
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
                                  icon: const Icon(Icons.send_rounded),
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
        Text(
          author,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            height: 1.5,
          ),
          textDirection: TextDirection.ltr,
        ),
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
        .where('type', isEqualTo: 'dislike');

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
                  Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
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

          final reports = snapshot.data!.docs.toList();
          reports.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          final Map<String, List<DocumentSnapshot>> violationsByStudent = {};

          for (var report in reports) {
            final studentName = (report.data() as Map<String, dynamic>)['studentName'] as String? ?? 'طالب غير معروف';
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
                    final note = data['reason'] ?? data['teacherNote'] ?? 'لا يوجد تفصيل.';
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

class ClassStudentsListPage extends StatefulWidget {
  final String stage;
  final String grade;
  final String className;
  final Future<void> Function(BuildContext context, Function() onSuccess) verifyAdminPin;

  const ClassStudentsListPage({super.key, required this.stage, required this.grade, required this.className, required this.verifyAdminPin});

  @override
  State<ClassStudentsListPage> createState() => _ClassStudentsListPageState();
}

class _ClassStudentsListPageState extends State<ClassStudentsListPage> {
  void _deleteStudent(String id, String name) {
    widget.verifyAdminPin(context, () async {
      try {
        await FirebaseFirestore.instance.collection('students').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف الطالب $name بنجاح نهائياً.'), backgroundColor: Colors.orange));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحذف: $e')));
      }
    });
  }

  void _showStudentAccountDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final email = data['email'] ?? 'غير متوفر';
    final password = data['pp'] ?? 'غير متوفر';
    final complaintsPin = data['complaints_pin'] ?? '0000';
    final guardianPhone = data['guardian_phone'] ?? 'غير متوفر';

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.badge_rounded, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text('تفاصيل حساب الطالب: ${data['name'] ?? ''}', style: const TextStyle(fontSize: 16))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCopyTile('البريد الإلكتروني للحساب', email),
                const SizedBox(height: 8),
                _buildCopyTile('كلمة مرور الحساب', password),
                const SizedBox(height: 8),
                _buildCopyTile('الرمز السري للشكاوى والمتابعة', complaintsPin),
                const SizedBox(height: 8),
                _buildCopyTile('رقم الشكاوى/ولي الأمر', guardianPhone),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
                onPressed: () {
                  StudentPrintHelper.printAccount(
                    name: data['name'] ?? '',
                    email: email,
                    pass: password,
                    pin: complaintsPin,
                    cls: data['classes'] ?? widget.className,
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy_all),
                label: const Text('نسخ الكل'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'تفاصيل حساب الطالب:\nالاسم: ${data['name']}\nالبريد: $email\nكلمة المرور: $password\nالرمز السري للشكاوى: $complaintsPin\nهاتف الشكاوى/الوالد: $guardianPhone'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ تفاصيل الحساب بالكامل!'), backgroundColor: Colors.green));
                },
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ],
          );
        }
    );
  }

  Widget _buildCopyTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.blue),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ $title!'), duration: const Duration(seconds: 1)));
            },
          )
        ],
      ),
    );
  }

  void _transferStudent(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String selectedStage = data['stages'] ?? 'المرحلة الابتدائية';
    String selectedGrade = data['grades'] ?? 'الصف الأول';
    String selectedClass = data['classes'] ?? 'الفصل 1';

    final List<String> stages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];
    final List<String> primaryGrades = ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'];
    final List<String> intermediateGrades = ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'];
    final List<String> secondaryGrades = ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];

    List<String> getGrades() {
      if (selectedStage == 'المرحلة الابتدائية') return primaryGrades;
      if (selectedStage == 'المرحلة المتوسطة') return intermediateGrades;
      return secondaryGrades;
    }

    selectedGrade = getGrades().first;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('نقل الطالب: ${data['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStage,
                    decoration: const InputDecoration(labelText: 'المرحلة الجديدة', border: OutlineInputBorder()),
                    items: stages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedStage = val!;
                        selectedGrade = getGrades().first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(labelText: 'الصف الجديد', border: OutlineInputBorder()),
                    items: getGrades().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => selectedGrade = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'الفصل الجديد', border: OutlineInputBorder()),
                    items: List.generate(10, (i) => 'الفصل ${i + 1}').map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => selectedClass = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.verifyAdminPin(context, () async {
                      await FirebaseFirestore.instance.collection('students').doc(doc.id).update({
                        'stages': selectedStage,
                        'grades': selectedGrade,
                        'classes': selectedClass,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نقل الطالب وتحديث فصله بنجاح'), backgroundColor: Colors.green));
                    });
                  },
                  child: const Text('تأكيد النقل برمز PIN'),
                )
              ],
            );
          });
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قائمة ${widget.grade} - ${widget.className}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('stages', isEqualTo: widget.stage)
            .where('grades', isEqualTo: widget.grade)
            .where('classes', isEqualTo: widget.className)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب مدرجين في هذا الفصل حالياً.', style: TextStyle(color: Colors.grey)));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('البريد: ${data['email'] ?? '-'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.badge_rounded, color: Colors.green), tooltip: 'تفاصيل حساب الطالب والطباعة', onPressed: () => _showStudentAccountDetails(doc)),
                      IconButton(icon: const Icon(Icons.compare_arrows, color: Colors.blue), tooltip: 'نقل الطالب لفصل آخر', onPressed: () => _transferStudent(doc)),
                      IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), tooltip: 'حذف الطالب نهائياً', onPressed: () => _deleteStudent(doc.id, data['name'] ?? '')),
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
}

// ===========================================================================
// الكلاسات المساعدة وأزرار التحكم
// ===========================================================================

class _AnimatedGridButton extends StatefulWidget {
  final String title;
  final IconData? icon;
  final String? svgPath;
  final Color color;
  final VoidCallback onTap;
  final String? statCount;
  final int? badgeCount;

  const _AnimatedGridButton({
    required this.title,
    this.icon,
    this.svgPath,
    required this.color,
    required this.onTap,
    this.statCount,
    this.badgeCount,
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
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double boxSize = constraints.maxWidth;
            final double circleSize = boxSize * 0.75;
            final double iconSize = circleSize * 0.45;
            final double screenWidth = MediaQuery.of(context).size.width;

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start, // ✅ التعديل الصحيح
              children: [
                badges.Badge(
                  showBadge: (widget.badgeCount != null && widget.badgeCount! > 0) || (widget.statCount == "✓"),
                  badgeContent: Text(widget.statCount == "✓" ? "✓" : '${widget.badgeCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  position: badges.BadgePosition.topEnd(top: 0, end: 0),
                  badgeAnimation: const badges.BadgeAnimation.scale(),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: widget.statCount == "✓" ? Colors.green : Colors.red.shade600,
                    elevation: 0,
                  ),
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: widget.svgPath != null ? Colors.transparent : widget.color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: widget.statCount != null && widget.statCount != "✓"
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.svgPath != null
                              ? SvgPicture.asset(widget.svgPath!, width: iconSize * 0.7, height: iconSize * 0.7)
                              : Icon(widget.icon, size: iconSize * 0.7, color: widget.color.withOpacity(0.6)),
                          const SizedBox(height: 2),
                          Text(
                            widget.statCount!,
                            style: TextStyle(
                                fontSize: circleSize * 0.25,
                                fontWeight: FontWeight.w900,
                                color: widget.color,
                                fontFamily: 'Cairo'
                            ),
                          ),
                        ],
                      ),
                    )
                        : Center(
                      child: widget.svgPath != null
                          ? SvgPicture.asset(widget.svgPath!, width: iconSize * 1.3, height: iconSize * 1.3)
                          : Icon(widget.icon, size: iconSize, color: widget.color),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth > 600 ? 13 : 11.5,
                    color: Colors.grey.shade800,
                    height: 1.3,
                    fontFamily: 'Cairo',
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TeacherPortfolioFormPage extends StatefulWidget {
  const TeacherPortfolioFormPage({super.key});

  @override
  State<TeacherPortfolioFormPage> createState() => _TeacherPortfolioFormPageState();
}

class _TeacherPortfolioFormPageState extends State<TeacherPortfolioFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _specialtyCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _expCtrl = TextEditingController();
  final TextEditingController _linkCtrl = TextEditingController();

  String? _existingImageUrl;
  XFile? _newImageFile;
  Uint8List? _imageBytes;

  String? _previousPortfolioLink;
  Timestamp? _linkUpdatedAt;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('teacher_portfolios_profiles').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameCtrl.text = data['name'] ?? '';
        _specialtyCtrl.text = data['specialty'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _idCtrl.text = data['nationalId'] ?? '';
        _aboutCtrl.text = data['about'] ?? '';
        _expCtrl.text = data['experience'] ?? '';
        _linkCtrl.text = data['portfolioLink'] ?? '';
        _existingImageUrl = data['imageUrl'];

        _previousPortfolioLink = data['previousPortfolioLink'];
        _linkUpdatedAt = data['linkUpdatedAt'] as Timestamp?;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (bytes.length > 15 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('عفواً، حجم الصورة يتجاوز الحد الأقصى.'), backgroundColor: Colors.red)
          );
        }
        return;
      }
      setState(() {
        _newImageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  bool get _canRestorePreviousLink {
    if (_previousPortfolioLink == null || _previousPortfolioLink!.isEmpty || _linkUpdatedAt == null) {
      return false;
    }
    final difference = DateTime.now().difference(_linkUpdatedAt!.toDate());
    return difference.inHours < 24;
  }

  Future<void> _restorePreviousLink() async {
    if (!_canRestorePreviousLink) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final String restoreTarget = _previousPortfolioLink!;
      await FirebaseFirestore.instance.collection('teacher_portfolios_profiles').doc(user.uid).set({
        'portfolioLink': restoreTarget,
        'previousPortfolioLink': FieldValue.delete(),
        'linkUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _linkCtrl.text = restoreTarget;
        _previousPortfolioLink = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم العودة للرابط والباركود القديم بنجاح ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الاستعادة: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('teacher_portfolios_profiles').doc(user.uid).get();
    final String currentSavedLink = doc.exists ? (doc.data()?['portfolioLink'] ?? '') : '';
    final String newEnteredLink = _linkCtrl.text.trim().isEmpty ? 'https://elm3rfa.vip/?teacher=${user.uid}' : _linkCtrl.text.trim();

    if (currentSavedLink.isNotEmpty && currentSavedLink != newEnteredLink) {
      final bool confirmChange = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('تنبيه: تغيير الـ QR والرابط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          content: const Text(
            'تأكيد تعديل الرابط سيتسبب في تغيير الرمز القديم (QR Code) واستبداله بآخر جديد.\n\nتنويه: يمكنك العودة واسترجاع الرابط القديم خلال 24 ساعة من التعديل.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد التعديل والتبديل'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmChange) return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _existingImageUrl;

      if (_imageBytes != null) {
        final String fileName = '${user.uid}_profile.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child('teacher_portfolios_images').child(fileName);
        await storageRef.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        finalImageUrl = await storageRef.getDownloadURL();
      }

      Map<String, dynamic> updateData = {
        'name': _nameCtrl.text.trim(),
        'specialty': _specialtyCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'nationalId': _idCtrl.text.trim(),
        'about': _aboutCtrl.text.trim(),
        'experience': _expCtrl.text.trim(),
        'portfolioLink': newEnteredLink,
        'imageUrl': finalImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (currentSavedLink.isNotEmpty && currentSavedLink != newEnteredLink) {
        updateData['previousPortfolioLink'] = currentSavedLink;
        updateData['linkUpdatedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance.collection('teacher_portfolios_profiles').doc(user.uid).set(updateData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وتحديث بيانات ملف الإنجاز بنجاح ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        await _loadExistingProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد ملف الإنجاز'), backgroundColor: const Color(0xFF37474F), foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.indigo.shade300, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                      ),
                      child: ClipOval(
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                            ? Image.network(_existingImageUrl!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.person, size: 55, color: Colors.grey))
                            : const Icon(Icons.person, size: 55, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('اضغط على الكاميرا لاختيار صورتك الشخصية', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold))),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المعلم كاملاً *', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyCtrl,
                decoration: const InputDecoration(labelText: 'التخصص (مثال: رياضيات، لغة عربية) *', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'التخصص مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رقم الهوية', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aboutCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'نبذة عنك (صف نفسك) *',
                  helperText: 'ستظهر هذه النبذة في الكادر التعريفي بالموقع.',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'النبذة مطلوبة' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الخبرات (اختياري)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط ملف الإنجاز (مفتوح للتعديل 📂)',
                  hintText: 'https://...',
                  helperText: 'إذا تركته فارغاً سيتم توليد رابط تلقائي خاص بك.',
                  border: OutlineInputBorder(),
                ),
              ),

              if (_canRestorePreviousLink) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'يمكنك الاسترجاع والعودة للينك والـ QR القديم (متاح خلال 24 ساعة من التعديل).',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                        onPressed: _restorePreviousLink,
                        child: const Text('استرجاع الآن', style: TextStyle(fontSize: 11)),
                      )
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37474F), foregroundColor: Colors.white),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AllTeachersPortfoliosPage extends StatelessWidget {
  const AllTeachersPortfoliosPage({super.key});

  void _showTeacherBioDialog(BuildContext context, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'بدون اسم';
    final String position = data['position'] ?? 'غير محدد';
    final String specialty = data['specialty'] ?? 'غير محدد';
    final String about = data['about'] ?? 'لا توجد نبذة مدخلة حالياً.';
    final String experience = data['experience'] ?? 'لا توجد خبرات مضافة.';
    final String portfolioLink = data['portfolioLink'] ?? '';
    final String? imageUrl = data['imageUrl'];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 20, left: 20, right: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.indigo, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
                    ),
                    child: ClipOval(
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.person, size: 50, color: Colors.grey))
                          : const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 4),
                  Text('$position - $specialty', style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const Divider(height: 30),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('النبذة التعريفية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text(about, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                  ),
                  const SizedBox(height: 16),

                  if (experience.isNotEmpty && experience != 'لا توجد خبرات مضافة.') ...[
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('الخبرات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(experience, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.indigo)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (portfolioLink.isNotEmpty) ...[
                    const Text('رمز QR الخاص بملف الإنجاز المباشر:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse(portfolioLink);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: QrImageView(
                        data: portfolioLink,
                        version: QrVersions.auto,
                        size: 130.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('اضغط على الرمز لفتح الرابط مباشرة', style: TextStyle(fontSize: 11, color: Colors.blue)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل ملفات الإنجاز'), backgroundColor: const Color(0xFF00695C), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teacher_portfolios_profiles').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد ملفات إنجاز حالياً.'));

          final docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'بدون اسم';
              final String position = data['position'] ?? 'غير محدد';
              final String specialty = data['specialty'] ?? '';
              final String portfolioLink = data['portfolioLink'] ?? '';
              final String? imageUrl = data['imageUrl'];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: InkWell(
                  onTap: () => _showTeacherBioDialog(context, data),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.teal.shade400, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))
                              ]
                          ),
                          child: ClipOval(
                            child: imageUrl != null
                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 45, color: Colors.grey))
                                : const Icon(Icons.person, size: 45, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          position,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (specialty.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'تخصص: $specialty',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (portfolioLink.isNotEmpty)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                              child: QrImageView(
                                data: portfolioLink,
                                version: QrVersions.auto,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                          )
                        else
                          const Expanded(child: Center(child: Text('اضغط لقراءة النبذة', style: TextStyle(color: Colors.blue, fontSize: 11)))),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}