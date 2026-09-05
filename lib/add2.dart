import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:almarefamecca/secondary_pages.dart';
import 'package:almarefamecca/student_view.dart';

import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

// --- مساعد الطباعة للملفات ---
class StudentPrintHelper {
  static Future<void> printAccount({
    required String name,
    required String email,
    required String pass,
    required String pin,
    required String cls,
  }) async {
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                bottom: 0,
                left: 0,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'https://wa.me/966569064173',
                      width: 50,
                      height: 50,
                    ),
                    pw.SizedBox(width: 6),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('في حال وجود مشكلة التواصل مع', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text('مطور الموقع أ : مصطفى سعيد', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Text('966569064173+', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('المعرفة vip', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('رابط الموقع الرسمي:', style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey)),
                            pw.SizedBox(height: 2),
                            pw.Directionality(
                              textDirection: pw.TextDirection.ltr,
                              child: pw.Text('https://elm3rfa.vip/', style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue)),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 12),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'https://elm3rfa.vip/',
                          width: 40,
                          height: 40,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text('بيانات حساب الطالب', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('الاسم: $name', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('الفصل: $cls', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          color: PdfColors.grey100,
                        ),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('البريد الإلكتروني:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 1),
                              pw.Directionality(
                                textDirection: pw.TextDirection.ltr,
                                child: pw.Text(email, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text('كلمة المرور للحساب:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 1),
                              pw.Directionality(
                                textDirection: pw.TextDirection.ltr,
                                child: pw.Text(pass, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text('الرمز (كلمة مرور ) لأيقونة الشكاوى:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                              pw.SizedBox(height: 1),
                              pw.Directionality(
                                textDirection: pw.TextDirection.ltr,
                                child: pw.Text(pin, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                              ),
                            ]
                        )
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('باركود تسجيل الدخول السريع للحساب:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: '$email:$pass',
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'حساب_${name.replaceAll(' ', '_')}.pdf',
    );
  }
}

class QRSessionTimer {
  static Timer? _timer;
  static final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  static bool isActive = false;

  static void startSession(BuildContext context) {
    isActive = true;
    remainingSeconds.value = 300;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        stopSession();
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('انتهت جلسة السبورة (5 دقائق). تم الخروج تلقائياً للأمان.', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  static void stopSession() {
    _timer?.cancel();
    isActive = false;
    remainingSeconds.value = 0;
  }
}

class QRSessionOverlay extends StatelessWidget {
  final Widget child;
  const QRSessionOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: QRSessionTimer.remainingSeconds,
      builder: (context, seconds, _) {
        if (!QRSessionTimer.isActive || seconds <= 0) {
          return child;
        }

        final mins = (seconds / 60).floor();
        final secs = seconds % 60;
        final bool isUrgent = seconds < 60;

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: isUrgent ? const Color(0xFFB71C1C) : Colors.red,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 8,
                bottom: 8,
                left: 12,
                right: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'جلسة سبورة مؤقتة: ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      QRSessionTimer.stopSession();
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('خروج الآن', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// الصفحة الرئيسية (Add2Page)
// ---------------------------------------------------------------------------
class Add2Page extends StatefulWidget {
  const Add2Page({super.key});

  @override
  _Add2PageState createState() => _Add2PageState();
}

class _Add2PageState extends State<Add2Page> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isAdmin = false;
  User? _user;

  String _userProfession = '';
  Timer? _sessionTimer;
  bool _isScheduleApproved = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _checkTeacherScheduleStatus();
  }

  Future<void> _onRefresh() async {
    await _fetchUserData();
    await _checkTeacherScheduleStatus();
    if (mounted) setState(() {});
  }

  Future<void> _checkTeacherScheduleStatus() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('teacher_schedules').doc(_user!.uid).get();
      if (doc.exists && doc.data()?['status'] == 'approved') {
        setState(() {
          _isScheduleApproved = true;
        });
      } else {
        setState(() {
          _isScheduleApproved = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking schedule status: $e");
    }
  }

  void _logoutGuestSession() {
    _sessionTimer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الخروج تلقائياً لانتهاء جلسة الضيف (3 دقائق).', style: TextStyle(fontFamily: 'Cairo')),
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

  Future<void> _verifyAdminPin(BuildContext context, Function() onSuccess) async {
    final pinCtrl = TextEditingController();
    final fKey = GlobalKey<FormState>();

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
                  Text('تأكيد الهوية (الأدمن)', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
              content: Form(
                key: fKey,
                child: TextFormField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الرمز السري للأدمن (PIN)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'حقل مطلوب' : null,
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: checking ? null : () async {
                    if (fKey.currentState!.validate()) {
                      setDialogState(() => checking = true);
                      try {
                        final sDoc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
                        final correctPin = sDoc.data()?['admin_pin']?.toString() ?? '010';

                        if (pinCtrl.text.trim() == correctPin) {
                          Navigator.pop(ctx);
                          onSuccess();
                        } else {
                          setDialogState(() => checking = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز السري غير صحيح!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                        }
                      } catch (e) {
                        setDialogState(() => checking = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          });
        }
    );
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
          return const Center(child: Text("المستخدم غير مسجل.", style: TextStyle(fontFamily: 'Cairo')));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("الإشعارات", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Cairo')),
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
                          child: Text("لا توجد إشعارات حالياً.", style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Cairo')),
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
                          title: Text(data['message'] ?? '...', style: const TextStyle(fontFamily: 'Cairo')),
                          subtitle: Text(formattedDate, style: const TextStyle(fontFamily: 'Cairo')),
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

  @override
  Widget build(BuildContext context) {
    return QRSessionOverlay(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.lightBlue.shade400,
          elevation: 0,
          title: const Text('لوحة التحكم (الخدمات والجداول)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              onPressed: _showNotifications,
            ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 35,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Text('مطور الموقع أ : مصطفي سعيد', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildTeacherDashboard(),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherDashboard() {
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
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo'),
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
              _AnimatedGridButton(
                title: 'إدارة جداول الحصص',
                icon: _isScheduleApproved ? Icons.event_available : Icons.edit_calendar_rounded,
                color: const Color(0xFFE65100),
                badgeCount: _isScheduleApproved ? null : 0,
                statCount: _isScheduleApproved ? "✓" : null,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherScheduleFlowPage()));
                },
              ),
              if (_isAdmin) ...[
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('teacher_schedules')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'موافقة الجداول',
                      icon: Icons.fact_check_rounded,
                      color: const Color(0xFFAA00FF),
                      badgeCount: count,
                      onTap: () {
                        _verifyAdminPin(context, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScheduleApprovalsPage()));
                        });
                      },
                    );
                  },
                ),
                _AnimatedGridButton(
                  title: 'الجداول المعتمدة',
                  icon: Icons.table_chart_rounded,
                  color: const Color(0xFF00B8D4),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovedSchedulesPage()));
                  },
                ),
                _AnimatedGridButton(
                  title: 'صلاحيات وصول الفصل',
                  icon: Icons.admin_panel_settings_rounded,
                  color: Colors.redAccent.shade700,
                  onTap: () {
                    _verifyAdminPin(context, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminClassPermissionsPage()));
                    });
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admission_requests')
                      .where('status', isEqualTo: 'pending')
                      .where('grade', whereIn: ['الأول الابتدائي', 'الثاني الابتدائي', 'الثالث الابتدائي', 'الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'طلب انضمام ابتدائي',
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFF1565C0),
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAdmissionRequestsPage(stageFilter: 'ابتدائي')));
                      },
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admission_requests')
                      .where('status', isEqualTo: 'pending')
                      .where('grade', whereIn: ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'طلب انضمام متوسط',
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFF1976D2),
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAdmissionRequestsPage(stageFilter: 'متوسط')));
                      },
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admission_requests')
                      .where('status', isEqualTo: 'pending')
                      .where('grade', whereIn: ['الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'طلب انضمام ثانوي',
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFF0D47A1),
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAdmissionRequestsPage(stageFilter: 'ثانوي')));
                      },
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admission_requests')
                      .where('status', isEqualTo: 'approved')
                      .where('grade', whereIn: ['الأول الابتدائي', 'الثاني الابتدائي', 'الثالث الابتدائي', 'الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'قبول نهائي ابتدائي',
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF2E7D32),
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FinalAdmissionApprovalPage(stageFilter: 'ابتدائي')));
                      },
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admission_requests')
                      .where('status', isEqualTo: 'approved')
                      .where('grade', whereIn: ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'قبول نهائي متوسط',
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF388E3C),
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FinalAdmissionApprovalPage(stageFilter: 'متوسط')));
                      },
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admission_requests')
                      .where('status', isEqualTo: 'approved')
                      .where('grade', whereIn: ['الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'قبول نهائي ثانوي',
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF1B5E20),
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FinalAdmissionApprovalPage(stageFilter: 'ثانوي')));
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                badges.Badge(
                  showBadge: (widget.badgeCount != null && widget.badgeCount! > 0) || (widget.statCount == "✓"),
                  badgeContent: Text(widget.statCount == "✓" ? "✓" : '${widget.badgeCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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

class AdminAdmissionRequestsPage extends StatefulWidget {
  final String stageFilter;
  const AdminAdmissionRequestsPage({super.key, required this.stageFilter});

  @override
  State<AdminAdmissionRequestsPage> createState() => _AdminAdmissionRequestsPageState();
}

class _AdminAdmissionRequestsPageState extends State<AdminAdmissionRequestsPage> {
  bool _isProcessing = false;

  void _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('https://wa.me/966$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب، يرجى التأكد من الرقم.', style: TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }

  Future<void> _updateRequestStatus(String docId, String status, String visitTime) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('admission_requests').doc(docId).update({
        'status': status,
        'visitTime': visitTime,
        'processedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالة الطلب وموعد الزيارة بنجاح.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRequestDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    TextEditingController visitTimeCtrl = TextEditingController(text: data['visitTime'] ?? 'لم يحدد');

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24, left: 24, right: 24
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تفاصيل طلب الالتحاق', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontFamily: 'Cairo')),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),

                  _buildDetailRow('اسم الطالب:', data['studentName']),
                  _buildDetailRow('رقم الهوية:', data['studentId']?.isEmpty == true ? 'غير متوفر' : data['studentId']),
                  _buildDetailRow('الصف المطلوب:', data['grade']),
                  _buildDetailRow('الحي السكني:', data['neighborhood']),
                  _buildDetailRow('المدرسة السابقة:', data['previousSchool']?.isEmpty == true ? 'غير متوفر' : data['previousSchool']),
                  _buildDetailRow('ملاحظات الأب:', data['notes']?.isEmpty == true ? 'لا توجد ملاحظات' : data['notes']),

                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'جوال ولي الأمر: 966${data['parentPhone']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.green),
                          tooltip: 'مراسلة عبر واتساب',
                          onPressed: () => _openWhatsApp(data['parentPhone'] ?? ''),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('تحديد موعد الزيارة / المقابلة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: visitTimeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'مثال: يوم الأحد الساعة 9:00 صباحاً',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text('تحديث حالة الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('قبول مبدئي', style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () {
                            Navigator.pop(context);
                            _updateRequestStatus(docId, 'approved', visitTimeCtrl.text.trim());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('رفض', style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () {
                            Navigator.pop(context);
                            _updateRequestStatus(docId, 'rejected', visitTimeCtrl.text.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildDetailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Cairo')),
          const SizedBox(width: 8),
          Expanded(child: Text(value?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'))),
        ],
      ),
    );
  }

  List<String> _getStageGrades() {
    if (widget.stageFilter == 'ابتدائي') {
      return ['الأول الابتدائي', 'الثاني الابتدائي', 'الثالث الابتدائي', 'الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي'];
    } else if (widget.stageFilter == 'متوسط') {
      return ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'];
    } else {
      return ['الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات انضمام - المرحلة ${widget.stageFilter}', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admission_requests')
                .where('status', isEqualTo: 'pending')
                .where('grade', whereIn: _getStageGrades())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد طلبات معلقة لهذه المرحلة.', style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo')));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      title: Text(data['studentName'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontFamily: 'Cairo')),
                      subtitle: Text('الصف: ${data['grade']} - الجوال: ${data['parentPhone']}', style: const TextStyle(fontFamily: 'Cairo')),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showRequestDetails(context, doc),
                    ),
                  );
                },
              );
            },
          ),
          if (_isProcessing) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }
}

class FinalAdmissionApprovalPage extends StatefulWidget {
  final String stageFilter;
  const FinalAdmissionApprovalPage({super.key, required this.stageFilter});

  @override
  State<FinalAdmissionApprovalPage> createState() => _FinalAdmissionApprovalPageState();
}

class _FinalAdmissionApprovalPageState extends State<FinalAdmissionApprovalPage> {
  bool _isProcessing = false;

  List<String> _getStageGrades() {
    if (widget.stageFilter == 'ابتدائي') {
      return ['الأول الابتدائي', 'الثاني الابتدائي', 'الثالث الابتدائي', 'الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي'];
    } else if (widget.stageFilter == 'متوسط') {
      return ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'];
    } else {
      return ['الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'];
    }
  }

  String _mapAdmissionToStudentGrade(String admissionGrade) {
    if (admissionGrade == 'الأول الابتدائي') return 'الصف الأول';
    if (admissionGrade == 'الثاني الابتدائي') return 'الصف الثاني';
    if (admissionGrade == 'الثالث الابتدائي') return 'الصف الثالث';
    if (admissionGrade == 'الرابع الابتدائي') return 'الصف الرابع';
    if (admissionGrade == 'الخامس الابتدائي') return 'الصف الخامس';
    if (admissionGrade == 'السادس الابتدائي') return 'الصف السادس';
    return admissionGrade;
  }

  void _processFinalApproval(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String selectedClass = 'الفصل 1';

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool processingLocal = false;
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('القبول النهائي: ${data['studentName']}', style: const TextStyle(fontFamily: 'Cairo')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الصف: ${data['grade']}', style: const TextStyle(fontFamily: 'Cairo')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'توزيعه على فصل *', border: OutlineInputBorder()),
                    items: List.generate(10, (i) => 'الفصل ${i + 1}').map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                    onChanged: (val) => setDialogState(() => selectedClass = val!),
                  ),
                  if (processingLocal) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                ElevatedButton(
                  onPressed: processingLocal ? null : () async {
                    setDialogState(() => processingLocal = true);
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
                            name: 'tempStudentApprov_${DateTime.now().millisecondsSinceEpoch}_$nextAvailableNumber',
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
                      String mappedGrade = _mapAdmissionToStudentGrade(data['grade'] ?? '');
                      String studentStage = 'المرحلة الابتدائية';
                      if (widget.stageFilter == 'متوسط') studentStage = 'المرحلة المتوسطة';
                      if (widget.stageFilter == 'ثانوي') studentStage = 'المرحلة الثانوية';

                      await newStudentRef.set({
                        'uid': newAuthUid,
                        'name': data['studentName'],
                        'stages': studentStage,
                        'grades': mappedGrade,
                        'classes': selectedClass,
                        'guardian_phone': data['parentPhone'] ?? '-',
                        'national_id': data['studentId'] ?? '-',
                        'email': finalEmail,
                        'pp': finalPassword,
                        'complaints_pin': complaintsPin,
                        'totalLikes': 0,
                        'totalDislikes': 0,
                        'timestamp': FieldValue.serverTimestamp()
                      });

                      await FirebaseFirestore.instance.collection('admission_requests').doc(doc.id).delete();

                      Navigator.pop(ctx);
                      _showAccountResultDialogLocal(data['studentName'], finalEmail, finalPassword, complaintsPin, selectedClass);
                    } catch (e) {
                      setDialogState(() => processingLocal = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo'))));
                    }
                  },
                  child: const Text('اعتماد الطالب وإنشاء الحساب', style: TextStyle(fontFamily: 'Cairo')),
                )
              ],
            );
          });
        }
    );
  }

  void _showAccountResultDialogLocal(String name, String email, String pass, String pin, String cls) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('تم اعتماد وبث بيانات الطالب', style: TextStyle(fontFamily: 'Cairo')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الاسم: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                Text('الفصل: $cls', style: const TextStyle(fontFamily: 'Cairo')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('البريد: $email', style: const TextStyle(fontFamily: 'Cairo')),
                      Text('كلمة المرور للحساب: $pass', style: const TextStyle(fontFamily: 'Cairo')),
                      Text('الرمز السري للشكاوى: $pin', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة الباركود', style: TextStyle(fontFamily: 'Cairo')),
                onPressed: () => StudentPrintHelper.printAccount(name: name, email: email, pass: pass, pin: pin, cls: cls),
              ),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'تم تفعيل حساب الطالب:\nالاسم: $name\nالفصل: $cls\nالبريد: $email\nكلمة المرور: $pass\nالرمز السري للشكاوى: $pin'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ!', style: TextStyle(fontFamily: 'Cairo'))));
                },
                child: const Text('نسخ للوالد', style: TextStyle(fontFamily: 'Cairo')),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('القبول النهائي - ${widget.stageFilter}', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admission_requests')
            .where('status', isEqualTo: 'approved')
            .where('grade', whereIn: _getStageGrades())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب مقبولين مبدئياً بانتظار الاعتماد النهائي.', style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Cairo')));
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
                  title: Text(data['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo')),
                  subtitle: Text('الصف: ${data['grade']} - موعد مقابلة: ${data['visitTime'] ?? 'لم يحدد'}', style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: const Icon(Icons.verified_user, color: Colors.green),
                  onTap: () => _processFinalApproval(doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TeacherScheduleFlowPage extends StatefulWidget {
  const TeacherScheduleFlowPage({super.key});

  @override
  State<TeacherScheduleFlowPage> createState() => _TeacherScheduleFlowPageState();
}

class _TeacherScheduleFlowPageState extends State<TeacherScheduleFlowPage> {
  bool _isLoading = true;
  String? _status;
  Map<String, dynamic>? _scheduleData;
  User? _user;

  bool _isAdmin = false;
  List<Map<String, dynamic>> _teachersList = [];
  String _selectedTeacherId = '';
  String _selectedTeacherName = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      _isAdmin = userDoc.data()?['profession'] == 'admin';

      if (_isAdmin) {
        final tSnap = await FirebaseFirestore.instance.collection('users').where('profession', isNotEqualTo: 'admin').get();
        _teachersList = tSnap.docs.map((d) => {'id': d.id, 'name': d['name'] ?? 'معلم'}).toList();
        if (_teachersList.isNotEmpty) {
          _selectedTeacherId = _teachersList.first['id'];
          _selectedTeacherName = _teachersList.first['name'];
        }
      } else {
        _selectedTeacherId = _user!.uid;
        _selectedTeacherName = userDoc.data()?['name'] ?? 'معلم';
      }
      await _fetchSchedule();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }

  Future<void> _fetchSchedule() async {
    if (_selectedTeacherId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('teacher_schedules').doc(_selectedTeacherId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _scheduleData = doc.data();
          _status = _scheduleData!['status'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _scheduleData = null;
          _status = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if ((_status == null || _status == 'draft') && !_isAdmin) {
      return TeacherSchedulePhase1(
        scheduleData: _scheduleData,
        teacherId: _selectedTeacherId,
        teacherName: _selectedTeacherName,
        isAdmin: _isAdmin,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'إدارة جداول الحصص' : 'جدول الحصص الخاص بي', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.deepOrange,
        bottom: _isAdmin && _teachersList.isNotEmpty
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade800,
            child: DropdownButtonFormField<String>(
              value: _selectedTeacherId,
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
                  _fetchSchedule();
                }
              },
            ),
          ),
        )
            : null,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: _status == 'approved' ? Colors.green.shade100 : Colors.orange.shade100,
            child: Row(
              children: [
                Icon(_status == 'approved' ? Icons.check_circle : Icons.hourglass_bottom, color: _status == 'approved' ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      _scheduleData == null
                          ? 'لا يوجد جدول لهذا المعلم'
                          : (_status == 'approved' ? 'الجدول معتمد من الإدارة' : 'الجدول قيد مراجعة الإدارة'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherSchedulePhase1(
                      scheduleData: _scheduleData,
                      teacherId: _selectedTeacherId,
                      teacherName: _selectedTeacherName,
                      isAdmin: _isAdmin,
                    ))).then((value) => _fetchSchedule());
                  },
                  child: const Text('تعديل الجدول', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                )
              ],
            ),
          ),
          Expanded(
            child: _scheduleData == null || _scheduleData!['phase2Data'] == null
                ? const Center(child: Text('لا يوجد جدول لعرضه', style: TextStyle(fontFamily: 'Cairo')))
                : ScheduleViewer(scheduleData: _scheduleData!['phase2Data']),
          )
        ],
      ),
    );
  }
}

class TeacherSchedulePhase1 extends StatefulWidget {
  final Map<String, dynamic>? scheduleData;
  final String teacherId;
  final String teacherName;
  final bool isAdmin;

  const TeacherSchedulePhase1({
    super.key,
    this.scheduleData,
    required this.teacherId,
    required this.teacherName,
    required this.isAdmin,
  });

  @override
  State<TeacherSchedulePhase1> createState() => _TeacherSchedulePhase1State();
}

class _TeacherSchedulePhase1State extends State<TeacherSchedulePhase1> {
  final List<String> _allSubjects = [
    'رياضيات', 'لغتي', 'علوم', 'انجليزي', 'إسلاميات', 'اجتماعيات', 'فنية', 'بدنية', 'رقمية', 'حياتية', 'تفكير', 'نشاط', 'روبوت', 'قيم وسلوك', 'أخرى'
  ];
  final List<String> _allStages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];

  final List<String> _allClasses = [
    'الفصل 1', 'الفصل 2', 'الفصل 3', 'الفصل 4', 'الفصل 5', 'الفصل 6',
    'الفصل 7', 'الفصل 8', 'الفصل 9', 'الفصل 10', 'أ', 'ب', 'ج', 'د', 'هـ'
  ];

  List<Map<String, String>> _addedAssignments = [];

  String? _selectedStageToAdd;
  String? _selectedGradeToAdd;
  String? _selectedClassToAdd;
  String? _selectedSubjectToAdd;

  List<String> _getGradesForStage(String? stage) {
    if (stage == 'المرحلة الابتدائية') return ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'];
    if (stage == 'المرحلة المتوسطة') return ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'];
    if (stage == 'المرحلة الثانوية') return ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];
    return [];
  }

  @override
  void initState() {
    super.initState();
    if (widget.scheduleData != null && widget.scheduleData!['phase1Data'] != null) {
      final p1 = widget.scheduleData!['phase1Data'];
      if (p1['assignments'] != null) {
        _addedAssignments = (p1['assignments'] as List).map((e) => Map<String, String>.from(e as Map)).toList();
      }
    }
  }

  void _addAssignment() {
    if (_selectedStageToAdd == null || _selectedGradeToAdd == null || _selectedClassToAdd == null || _selectedSubjectToAdd == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المرحلة والصف والفصل والمادة كمجموعة موحدة', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }

    final assignment = {
      'stage': _selectedStageToAdd!,
      'grade': _selectedGradeToAdd!,
      'class': _selectedClassToAdd!,
      'subject': _selectedSubjectToAdd!,
    };

    bool exists = _addedAssignments.any((a) =>
    a['stage'] == assignment['stage'] &&
        a['grade'] == assignment['grade'] &&
        a['class'] == assignment['class'] &&
        a['subject'] == assignment['subject']);

    if (!exists) {
      setState(() {
        _addedAssignments.add(assignment);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الإسناد مضاف بالفعل', style: TextStyle(fontFamily: 'Cairo'))));
    }
  }

  void _goToPhase2() {
    if (_addedAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إضافة الفصول والمواد التي تدرسها (كتلة واحدة)', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }

    final p1Data = {
      'assignments': _addedAssignments,
      'stage': _addedAssignments.first['stage'],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherSchedulePhase2(
          phase1Data: p1Data,
          existingPhase2Data: widget.scheduleData?['phase2Data'],
          teacherId: widget.teacherId,
          teacherName: widget.teacherName,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('المرحلة 1: البيانات الأساسية لجدول ${widget.teacherName}', style: const TextStyle(fontFamily: 'Cairo'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حدد الفصول والمواد التي تدرسها بالتتابع الموحد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'المرحلة الدراسية', border: OutlineInputBorder()),
                      value: _selectedStageToAdd,
                      items: _allStages.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedStageToAdd = val;
                        _selectedGradeToAdd = null;
                        _selectedClassToAdd = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'الصف', border: OutlineInputBorder()),
                      value: _selectedGradeToAdd,
                      items: _getGradesForStage(_selectedStageToAdd).map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedGradeToAdd = val;
                        _selectedClassToAdd = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'الفصل', border: OutlineInputBorder()),
                            value: _selectedClassToAdd,
                            items: _allClasses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                            onChanged: (val) => setState(() => _selectedClassToAdd = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'المادة', border: OutlineInputBorder()),
                            value: _selectedSubjectToAdd,
                            items: _allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                            onChanged: (val) => setState(() => _selectedSubjectToAdd = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addAssignment,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة لجدولك', style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_addedAssignments.isNotEmpty) ...[
              const Text('تمت الإضافة لجدولك:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              ..._addedAssignments.map((a) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('${a['stage']} - ${a['grade']} - ${a['class']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  subtitle: Text('المادة: ${a['subject']}', style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _addedAssignments.remove(a)),
                  ),
                ),
              )).toList(),
            ],
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _goToPhase2,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                child: const Text('الانتقال للمرحلة الثانية (تخطيط الجدول)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TeacherSchedulePhase2 extends StatefulWidget {
  final Map<String, dynamic> phase1Data;
  final Map<String, dynamic>? existingPhase2Data;
  final String teacherId;
  final String teacherName;
  final bool isAdmin;

  const TeacherSchedulePhase2({
    super.key,
    required this.phase1Data,
    this.existingPhase2Data,
    required this.teacherId,
    required this.teacherName,
    required this.isAdmin,
  });

  @override
  State<TeacherSchedulePhase2> createState() => _TeacherSchedulePhase2State();
}

class _TeacherSchedulePhase2State extends State<TeacherSchedulePhase2> {
  final List<String> days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
  late Map<String, List<Map<String, dynamic>>> _schedule;
  final List<String> periodTypes = ['حصة', 'فارغ', 'إشراف دور', 'اجتماع المادة'];
  final List<String> floors = ['الطابق الأول', 'الطابق الثاني', 'الطابق الثالث', 'الطابق الرابع', 'الطابق الخامس', 'الطابق السادس', 'الطابق السابع'];
  final List<String> dailySupervisionTasks = ['فارغ', 'مشرف في المقصف', 'مشرف استقبال الباب الخارجي', 'مشرف استقبال الباب الداخلي', 'مشرف الساحة', 'مشرف دورات المياة', 'مشرف صلاة', 'مشرف تنظيم'];
  List<String> _activeLabsList = [];

  bool _isSubmitting = false;
  Map<String, bool> _labSubjects = {};

  bool _coreEditsUnlocked = false;

  Map<String, Map<int, Map<String, dynamic>>> _classBookings = {};
  Map<String, Map<int, Map<String, dynamic>>> _labBookings = {};

  @override
  void initState() {
    super.initState();
    _coreEditsUnlocked = widget.existingPhase2Data == null || widget.isAdmin;
    _initSchedule();
    _loadActiveLabs();
    _loadOtherSchedules();
  }

  void _initSchedule() {
    _schedule = {};
    for (String day in days) {
      _schedule[day] = List.generate(8, (index) {
        if (widget.existingPhase2Data != null && widget.existingPhase2Data![day] != null) {
          return Map<String, dynamic>.from(widget.existingPhase2Data![day][index]);
        } else {
          if (index < 7) {
            return {'type': 'فارغ'};
          } else {
            return {'type': 'إشراف اليوم', 'task': 'فارغ'};
          }
        }
      });
    }

    if (widget.existingPhase2Data != null) {
      for (String day in days) {
        for (int i = 0; i < 7; i++) {
          final slot = _schedule[day]![i];
          if (slot['type'] == 'حصة' && slot['isLab'] == true && slot['subject'] != null) {
            _labSubjects[slot['subject']] = true;
          }
        }
      }
    }
  }

  Future<void> _loadActiveLabs() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('active_classrooms')
          .where('type', isEqualTo: 'lab')
          .where('isActive', isEqualTo: true)
          .get();

      List<String> temp = [];
      for (var doc in snap.docs) {
        String name = doc.data()['name'] ?? '';
        if (name.isNotEmpty && !temp.contains(name)) {
          temp.add(name);
        }
      }
      if (temp.isEmpty) {
        temp = [
          'معمل حاسوب 1', 'معمل حاسوب 2', 'معمل علوم 1', 'معمل علوم 2',
          'معمل فنية 1', 'معمل روبوت 1', 'معمل إنجليزي 1', 'معمل إنجليزي 2', 'معمل لغات'
        ];
      }
      if (mounted) {
        setState(() => _activeLabsList = temp);
      }
    } catch (_) {}
  }

  // ✅ دالة الفلترة الذكية للمعامل حسب نوع المادة المسندة للحصة
  List<String> _getFilteredLabsForSubject(String? subject) {
    if (subject == null || subject.isEmpty) return _activeLabsList;

    List<String> keywords = [];
    if (subject.contains('انجليزي') || subject.contains('English')) {
      keywords = ['انجليزي', 'إنجليزي', 'لغات', 'English'];
    } else if (subject.contains('علوم')) {
      keywords = ['علوم', 'مختبر'];
    } else if (subject.contains('حاسوب') || subject.contains('رقمية')) {
      keywords = ['حاسوب', 'حاسب', 'رقمية', 'كمبيوتر'];
    } else if (subject.contains('فنية')) {
      keywords = ['فنية', 'رسم'];
    } else if (subject.contains('روبوت')) {
      keywords = ['روبوت', 'STEM', 'ستيم'];
    }

    if (keywords.isEmpty) return _activeLabsList;

    final filtered = _activeLabsList.where((lab) {
      return keywords.any((k) => lab.toLowerCase().contains(k.toLowerCase()));
    }).toList();

    return filtered.isNotEmpty ? filtered : _activeLabsList;
  }

  Future<void> _loadOtherSchedules() async {
    final snap = await FirebaseFirestore.instance.collection('teacher_schedules').get();
    for (var doc in snap.docs) {
      if (doc.id == widget.teacherId) continue;
      final data = doc.data();
      final phase2 = data['phase2Data'] as Map<String, dynamic>?;
      if (phase2 == null) continue;
      final tName = data['teacherName'] ?? 'معلم آخر';

      for (String day in days) {
        _classBookings.putIfAbsent(day, () => {});
        _labBookings.putIfAbsent(day, () => {});

        List periods = phase2[day] ?? [];
        for (int i = 0; i < periods.length; i++) {
          var slot = periods[i];
          if (slot['type'] == 'حصة') {
            String classKey = '${slot['stage']}-${slot['grade']}-${slot['class']}';
            _classBookings[day]!.putIfAbsent(i, () => {});
            _classBookings[day]![i]![classKey] = {'teacherId': doc.id, 'teacherName': tName};

            if (slot['isLab'] == true && slot['labName'] != null) {
              String labKey = slot['labName'];
              _labBookings[day]!.putIfAbsent(i, () => {});
              _labBookings[day]![i]![labKey] = {'teacherId': doc.id, 'teacherName': tName};
            }
          }
        }
      }
    }
  }

  bool _isComprehensiveEdit() {
    if (widget.existingPhase2Data == null) return true;
    for (String day in days) {
      for (int i = 0; i < 8; i++) {
        var oldSlot = widget.existingPhase2Data![day][i];
        var newSlot = _schedule[day]![i];

        if (oldSlot['type'] != newSlot['type']) return true;

        if (newSlot['type'] == 'حصة') {
          if (oldSlot['stage'] != newSlot['stage'] ||
              oldSlot['grade'] != newSlot['grade'] ||
              oldSlot['class'] != newSlot['class'] ||
              oldSlot['subject'] != newSlot['subject']) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _updateTeacherPermissions(String tId) async {
    Map<String, dynamic> updates = {};
    List<String> fieldsToReset = [
      'stage1', 'stage2', 'stage3',
      'grade1', 'grade2', 'grade3', 'grade4', 'grade5', 'grade6',
      'grade11', 'grade22', 'grade33',
      'grade111', 'grade222', 'grade333',
      'class1', 'class2', 'class3', 'class4', 'class5', 'class6',
      'class11', 'class22', 'class33',
      'class111', 'class222', 'class333'
    ];
    for (var f in fieldsToReset) {
      updates[f] = FieldValue.delete();
    }

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

    Map<String, List<String>> classUpdates = {};
    final assignments = widget.phase1Data['assignments'] as List? ?? [];

    for (var item in assignments) {
      final stage = item['stage'];
      final grade = item['grade'];
      String className = item['class'].toString().trim();
      if (int.tryParse(className) != null) className = "الفصل $className";
      final subject = item['subject'];

      final stageInfo = structure[stage];
      if (stageInfo != null) {
        updates[stageInfo['field'] as String] = stage;
        final gradeInfo = (stageInfo['grades'] as Map)[grade];
        if (gradeInfo != null) {
          updates[gradeInfo['field'] as String] = grade;
          String classField = gradeInfo['classField'] as String;
          String newPair = "$className=$subject";
          classUpdates.putIfAbsent(classField, () => []).add(newPair);
        }
      }
    }

    classUpdates.forEach((key, list) {
      updates[key] = list.toSet().join(', ');
    });

    await FirebaseFirestore.instance.collection('users').doc(tId).update(updates);
  }

  Future<void> _submitSchedule() async {
    setState(() => _isSubmitting = true);

    for (String day in days) {
      for (int i = 0; i < 8; i++) {
        var slot = _schedule[day]![i];
        if (slot['type'] == 'حصة') {
          String classKey = '${slot['stage']}-${slot['grade']}-${slot['class']}';
          var cConflict = _classBookings[day]?[i]?[classKey];
          if (cConflict != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تعارض! الفصل $classKey مسند بالفعل يوم $day في الحصة ${i + 1} مع المعلم (${cConflict['teacherName']}). لا يمكن وجود أكثر من معلم لنفس الفصل في نفس الحصة.', style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ));
            setState(() => _isSubmitting = false);
            return;
          }

          if (slot['isLab'] == true && slot['labName'] != null) {
            String labKey = slot['labName'];
            var lConflict = _labBookings[day]?[i]?[labKey];
            if (lConflict != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('هذا ممنوع! الحصة محجوزة مع المعلم (${lConflict['teacherName']}) في معمل "$labKey". يرجى عقد اجتماع للاتفاق على حصص المعمل.', style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 7),
              ));
              setState(() => _isSubmitting = false);
              return;
            }
          }
        }
      }
    }

    try {
      bool isComprehensive = _isComprehensiveEdit();
      String finalStatus = 'pending';

      if (widget.isAdmin) {
        finalStatus = 'approved';
      } else if (!isComprehensive) {
        finalStatus = 'approved';
      }

      await FirebaseFirestore.instance.collection('teacher_schedules').doc(widget.teacherId).set({
        'teacherId': widget.teacherId,
        'teacherName': widget.teacherName,
        'status': finalStatus,
        'phase1Data': widget.phase1Data,
        'phase2Data': _schedule,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (finalStatus == 'approved') {
        await _updateTeacherPermissions(widget.teacherId);
      }

      if (mounted) {
        if (finalStatus == 'approved') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اعتماد الجدول بنجاح وتحديث الصلاحيات المعنية! ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب التعديل الشامل للإدارة بنجاح للموافقة عليه. ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
        }
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _unlockCoreEdits() async {
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width:8), Text('كسر قفل الجدول', style: TextStyle(fontFamily: 'Cairo'))]),
            content: const Text('التعديل المسموح به بدون الرجوع للإدارة هو إضافة أو إزالة معمل فقط.\n\nفي حال كسر القفل لتعديل الحصص الأساسية، سيتعين عليك إرسال طلب جديد للإدارة للموافقة عليه، ولن يتم اعتماد الجدول حتى توافق الإدارة. هل تريد المتابعة؟', style: TextStyle(fontFamily: 'Cairo', height: 1.5)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Cairo'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم، اكسر القفل', style: TextStyle(fontFamily: 'Cairo')),
              )
            ]
        )
    );

    if (confirm == true) {
      setState(() {
        _coreEditsUnlocked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة 2: تخطيط وتسكين الجدول', style: TextStyle(fontFamily: 'Cairo'))),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.blue.shade50,
            child: const Text('حدد نوع كل حصة والفصل. عند تفعيل خيار المعمل، يتم عرض المعامل الخاصة بنوع المادة المحددة فقط لمنع الأخطاء.', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          ),
          if (!widget.isAdmin && widget.existingPhase2Data != null && !_coreEditsUnlocked)
            Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200)
                ),
                child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.red),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('تعديل الحصص الأساسية مقفل. يمكنك تفعيل المعامل فقط دون الرجوع للإدارة.', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: _unlockCoreEdits,
                        child: const Text('كسر القفل للتعديل الشامل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      )
                    ]
                )
            ),
          Expanded(
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, dIndex) {
                String day = days[dIndex];
                return ExpansionTile(
                  title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo')),
                  initiallyExpanded: dIndex == 0,
                  children: List.generate(8, (pIndex) {
                    return _buildPeriodEditor(day, pIndex);
                  }),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSchedule,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ واعتـماد الجدول', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPeriodEditor(String day, int pIndex) {
    Map<String, dynamic> slot = _schedule[day]![pIndex];
    bool isCoreLocked = !_coreEditsUnlocked;

    if (pIndex == 7) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const CircleAvatar(child: Text('8')),
              const SizedBox(width: 12),
              const Expanded(flex: 1, child: Text('الفسحة / إشراف اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.all(8),
                    prefixIcon: isCoreLocked ? const Icon(Icons.lock, color: Colors.red, size: 16) : null,
                  ),
                  value: dailySupervisionTasks.contains(slot['task']) ? slot['task'] : 'فارغ',
                  items: dailySupervisionTasks.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')))).toList(),
                  onChanged: isCoreLocked ? null : (val) => setState(() => slot['task'] = val),
                ),
              )
            ],
          ),
        ),
      );
    }

    // المعامل المفلترة حسب مادة الحصة الحالية
    final List<String> availableSubjectLabs = _getFilteredLabsForSubject(slot['subject']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${pIndex + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.all(8),
                      labelText: 'نوع الحصة',
                      prefixIcon: isCoreLocked ? const Icon(Icons.lock, color: Colors.red, size: 16) : null,
                    ),
                    value: slot['type'],
                    items: periodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                    onChanged: isCoreLocked ? null : (val) {
                      setState(() {
                        slot['type'] = val;
                        slot.remove('stage');
                        slot.remove('grade');
                        slot.remove('class');
                        slot.remove('subject');
                        slot.remove('isLab');
                        slot.remove('labName');
                        slot.remove('floor');
                        slot.remove('task');
                      });
                    },
                  ),
                ),
              ],
            ),
            if (slot['type'] == 'حصة') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(8),
                  labelText: 'الفصل والمادة المسندة',
                  prefixIcon: isCoreLocked ? const Icon(Icons.lock, color: Colors.red, size: 16) : null,
                ),
                value: () {
                  if (slot['class'] != null && slot['subject'] != null && slot['grade'] != null) {
                    final str = '${slot['grade']} - ${slot['class']} - ${slot['subject']}';
                    final assignments = widget.phase1Data['assignments'] as List? ?? [];
                    bool exists = assignments.any((a) => '${a['grade']} - ${a['class']} - ${a['subject']}' == str);
                    if (exists) return str;
                  }
                  return null;
                }(),
                items: (widget.phase1Data['assignments'] as List).map((a) {
                  final str = '${a['grade']} - ${a['class']} - ${a['subject']}';
                  return DropdownMenuItem(value: str, child: Text(str, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')));
                }).toList(),
                onChanged: isCoreLocked ? null : (val) {
                  setState(() {
                    if (val != null) {
                      final selectedA = (widget.phase1Data['assignments'] as List).firstWhere(
                              (a) => '${a['grade']} - ${a['class']} - ${a['subject']}' == val
                      );
                      slot['stage'] = selectedA['stage'];
                      slot['grade'] = selectedA['grade'];
                      slot['class'] = selectedA['class'];
                      slot['subject'] = selectedA['subject'];

                      final labsForThis = _getFilteredLabsForSubject(slot['subject']);
                      if (_labSubjects[slot['subject']] == true) {
                        slot['isLab'] = true;
                        if (labsForThis.isNotEmpty && (slot['labName'] == null || !labsForThis.contains(slot['labName']))) {
                          slot['labName'] = labsForThis.first;
                        }
                      } else {
                        if (slot['labName'] != null && !labsForThis.contains(slot['labName'])) {
                          slot['labName'] = labsForThis.isNotEmpty ? labsForThis.first : null;
                        }
                      }
                    }
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(
                        'معمل (${slot['subject'] ?? "الحصة"})',
                        style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      value: slot['isLab'] ?? false,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          slot['isLab'] = val;
                          if (val == true) {
                            if (slot['subject'] != null) {
                              _labSubjects[slot['subject']] = true;
                            }
                            final validLabs = _getFilteredLabsForSubject(slot['subject']);
                            if (validLabs.isNotEmpty && (slot['labName'] == null || !validLabs.contains(slot['labName']))) {
                              slot['labName'] = validLabs.first;
                            }
                          } else {
                            slot.remove('labName');
                          }
                        });
                      },
                    ),
                  ),
                  if (slot['isLab'] == true)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), labelText: 'المعمل المتاح للمادة'),
                        value: (availableSubjectLabs.contains(slot['labName'])) ? slot['labName'] : (availableSubjectLabs.isNotEmpty ? availableSubjectLabs.first : null),
                        items: availableSubjectLabs.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')))).toList(),
                        onChanged: (val) => setState(() => slot['labName'] = val),
                      ),
                    ),
                ],
              )
            ],
            if (slot['type'] == 'إشراف دور') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                        labelText: 'الطابق',
                        prefixIcon: isCoreLocked ? const Icon(Icons.lock, color: Colors.red, size: 16) : null,
                      ),
                      value: slot['floor'],
                      items: floors.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')))).toList(),
                      onChanged: isCoreLocked ? null : (val) => setState(() => slot['floor'] = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                        labelText: 'المهمة (اختياري)',
                        prefixIcon: isCoreLocked ? const Icon(Icons.lock, color: Colors.red, size: 16) : null,
                      ),
                      initialValue: slot['task'],
                      readOnly: isCoreLocked,
                      onChanged: (val) => slot['task'] = val,
                    ),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

class AdminScheduleApprovalsPage extends StatelessWidget {
  const AdminScheduleApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة وموافقة الجداول', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.purple),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teacher_schedules').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد جداول بانتظار الموافقة.', style: TextStyle(fontFamily: 'Cairo')));

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final teacherName = data['teacherName'] ?? 'معلم غير معروف';
              final docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: Colors.purple),
                  title: Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  subtitle: Text('مرحلة: ${data['phase1Data']?['stage'] ?? ''}', style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminReviewSchedulePage(docId: docId, scheduleData: data)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminReviewSchedulePage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> scheduleData;

  const AdminReviewSchedulePage({super.key, required this.docId, required this.scheduleData});

  @override
  State<AdminReviewSchedulePage> createState() => _AdminReviewSchedulePageState();
}

class _AdminReviewSchedulePageState extends State<AdminReviewSchedulePage> {
  bool _isProcessing = false;

  Future<void> _approve(BuildContext context) async {
    final pinController = TextEditingController();
    final fKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool localChecking = false;
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('تأكيد اعتماد الجدول بالـ PIN', style: TextStyle(fontFamily: 'Cairo')),
              content: Form(
                key: fKey,
                child: TextFormField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رمز الـ PIN الخاص بالأدمن'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                ElevatedButton(
                  onPressed: localChecking ? null : () async {
                    if (fKey.currentState!.validate()) {
                      setDialogState(() => localChecking = true);
                      try {
                        final sDoc = await FirebaseFirestore.instance.collection('settings').doc('guest_access').get();
                        final correctPin = sDoc.data()?['admin_pin']?.toString() ?? '010';

                        if (pinController.text.trim() == correctPin) {
                          Navigator.pop(ctx);
                          _executeApproval();
                        } else {
                          setDialogState(() => localChecking = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز السري غير صحيح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                        }
                      } catch (e) {
                        setDialogState(() => localChecking = false);
                      }
                    }
                  },
                  child: const Text('تأكيد واعتماد', style: TextStyle(fontFamily: 'Cairo')),
                )
              ],
            );
          });
        }
    );
  }

  Future<void> _executeApproval() async {
    setState(() => _isProcessing = true);
    try {
      final teacherId = widget.scheduleData['teacherId'];
      if (teacherId == null) throw Exception("معرف المعلم غير موجود في الطلب");

      Map<String, dynamic> updates = {};

      List<String> fieldsToReset = [
        'stage1', 'stage2', 'stage3',
        'grade1', 'grade2', 'grade3', 'grade4', 'grade5', 'grade6',
        'grade11', 'grade22', 'grade33',
        'grade111', 'grade222', 'grade333',
        'class1', 'class2', 'class3', 'class4', 'class5', 'class6',
        'class11', 'class22', 'class33',
        'class111', 'class222', 'class333'
      ];
      for (var f in fieldsToReset) {
        updates[f] = FieldValue.delete();
      }

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

      Map<String, List<String>> classUpdates = {};
      final assignments = widget.scheduleData['phase1Data']?['assignments'] as List? ?? [];

      for (var item in assignments) {
        final stage = item['stage'];
        final grade = item['grade'];
        String className = item['class'].toString().trim();
        if (int.tryParse(className) != null) className = "الفصل $className";
        final subject = item['subject'];

        final stageInfo = structure[stage];
        if (stageInfo != null) {
          updates[stageInfo['field'] as String] = stage;
          final gradeInfo = (stageInfo['grades'] as Map)[grade];
          if (gradeInfo != null) {
            updates[gradeInfo['field'] as String] = grade;
            String classField = gradeInfo['classField'] as String;
            String newPair = "$className=$subject";
            classUpdates.putIfAbsent(classField, () => []).add(newPair);
          }
        }
      }

      classUpdates.forEach((key, list) {
        updates[key] = list.toSet().join(', ');
      });

      final batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('users').doc(teacherId), updates);
      batch.update(FirebaseFirestore.instance.collection('teacher_schedules').doc(widget.docId), {'status': 'approved'});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الموافقة واعتماد صلاحيات الرصد للمعلم بناءً على جدوله بنجاح.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('جدول ${widget.scheduleData['teacherName']}', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.purple),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.green.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة: الموافقة على هذا الجدول ستقوم آلياً بمنح المعلم صلاحيات الرصد للفصول والمواد المذكورة فيه وتحديث ملفه تلقائياً.',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: ScheduleViewer(scheduleData: widget.scheduleData['phase2Data'])),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('موافقة واعتماد الجدول والصلاحيات (PIN)', style: TextStyle(fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: _isProcessing ? null : () => _approve(context),
                  ),
                ),
              )
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminApprovedSchedulesPage extends StatelessWidget {
  const AdminApprovedSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الجداول المعتمدة', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.cyan),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teacher_schedules').where('status', isEqualTo: 'approved').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد جداول معتمدة.', style: TextStyle(fontFamily: 'Cairo')));

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final teacherName = data['teacherName'] ?? 'معلم غير معروف';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.cyan),
                  title: Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                        appBar: AppBar(title: Text('جدول $teacherName', style: const TextStyle(fontFamily: 'Cairo'))),
                        body: ScheduleViewer(scheduleData: data['phase2Data'])
                    )));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminClassPermissionsPage extends StatelessWidget {
  const AdminClassPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صلاحيات وصول الفصل للمعلمين', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.redAccent.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('profession', isNotEqualTo: 'admin').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا يوجد معلمين على النظام.', style: TextStyle(fontFamily: 'Cairo')));

          final teachers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['profession'] != 'gest';
          }).toList();

          return ListView.builder(
            itemCount: teachers.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final doc = teachers[index];
              final data = doc.data() as Map<String, dynamic>;
              final teacherName = data['name'] ?? 'معلم';
              final teacherId = doc.id;

              List<String> assignedGradesClasses = [];
              final classFields = ['class1', 'class2', 'class3', 'class4', 'class5', 'class6', 'class11', 'class22', 'class33', 'class111', 'class222', 'class333'];
              for (var field in classFields) {
                if (data[field] != null && data[field].toString().isNotEmpty && data[field] != '0') {
                  assignedGradesClasses.add("${field.replaceAll('class', 'صف/فصل ')}: ${data[field]}");
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87, fontFamily: 'Cairo')),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('إلغاء الوصول للكل (PIN)', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                            onPressed: () async {
                              List<String> fieldsToReset = [
                                'stage1', 'stage2', 'stage3',
                                'grade1', 'grade2', 'grade3', 'grade4', 'grade5', 'grade6',
                                'grade11', 'grade22', 'grade33',
                                'grade111', 'grade222', 'grade333',
                                'class1', 'class2', 'class3', 'class4', 'class5', 'class6',
                                'class11', 'class22', 'class33',
                                'class111', 'class222', 'class333'
                              ];
                              Map<String, dynamic> updates = {};
                              for (var f in fieldsToReset) {
                                updates[f] = FieldValue.delete();
                              }
                              await FirebaseFirestore.instance.collection('users').doc(teacherId).update(updates);
                              await FirebaseFirestore.instance.collection('teacher_schedules').doc(teacherId).delete().catchError((_){});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تم سحب وإلغاء صلاحية الوصول لكافة الفصول للمعلم $teacherName بنجاح.', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (assignedGradesClasses.isEmpty)
                        const Text('لا يمتلك هذا المعلم صلاحية وصول لأي فصول حالياً.', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'))
                      else ...[
                        const Text('الفصول والمسندات المفتوحة حالياً للرصد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, fontFamily: 'Cairo')),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: assignedGradesClasses.map((item) => Chip(
                            label: Text(item, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                            backgroundColor: Colors.grey.shade100,
                          )).toList(),
                        )
                      ],
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

class ScheduleViewer extends StatelessWidget {
  final Map<dynamic, dynamic> scheduleData;
  const ScheduleViewer({super.key, required this.scheduleData});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        String day = days[index];
        List periods = scheduleData[day] ?? [];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Cairo')),
            children: List.generate(periods.length, (pIndex) {
              final pData = periods[pIndex];
              String display = 'فارغ';
              if (pData['type'] == 'حصة') {
                final stageStr = pData['stage'] != null ? '${pData['stage']} - ' : '';
                final gradeStr = pData['grade'] != null ? '${pData['grade']} - ' : '';
                final classStr = pData['class'] ?? '';
                final subjectStr = pData['subject'] ?? '';
                final labStr = pData['isLab'] == true ? ' (معمل: ${pData['labName'] ?? "غير محدد"})' : '';

                display = 'حصة: $stageStr$gradeStr$classStr - $subjectStr$labStr';
              } else if (pData['type'] == 'إشراف دور') {
                display = 'إشراف دور: ${pData['floor'] ?? ''} - ${pData['task'] ?? ''}';
              } else if (pData['type'] == 'إشراف اليوم') {
                display = 'إشراف اليوم: ${pData['task'] ?? 'فارغ'}';
              } else if (pData['type'] == 'اجتماع المادة') {
                display = 'اجتماع المادة';
              }

              return ListTile(
                leading: CircleAvatar(child: Text('${pIndex + 1}', style: const TextStyle(fontFamily: 'Cairo'))),
                title: Text(display, style: TextStyle(color: display == 'فارغ' ? Colors.grey : Colors.black87, fontFamily: 'Cairo')),
              );
            }),
          ),
        );
      },
    );
  }
}