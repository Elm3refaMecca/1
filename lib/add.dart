import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:almarefamecca/add1.dart';
import 'package:almarefamecca/secondary_pages.dart';
import 'package:almarefamecca/student_view.dart';
import 'package:almarefamecca/teacher_excellence.dart';

import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
              content: Text('انتهت جلسة السبورة (5 دقائق). تم الخروج تلقائياً للأمان.'),
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
                          Text('خروج الآن', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
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

  static void showBehaviorDialog(BuildContext context, String studentId, String studentName) {
    showModalBottomSheet(
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

      await FirebaseFirestore.instance.collection('behavior_logs').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'type': type,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('students').doc(widget.studentId).collection('notifications').add({
        'title': type == 'like' ? '🌟 نقاط تميز' : '⚠️ تنبيه سلوكي',
        'message': type == 'like'
            ? 'حصل الطالب ${widget.studentName} على إشارة حسنة من أ. $teacherName.\nالسبب: $reason'
            : 'تم تسجيل ملاحظة سلوكية على الطالب ${widget.studentName} من أ. $teacherName.\nالسبب المباشر: $reason',
        'type': 'behavior',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل ${type == 'like' ? 'التميز' : 'المخالفة'} وإشعار ولي الأمر بنجاح.'),
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

  @override
  Widget build(BuildContext context) {
    final bool isGuest = _userProfession == 'gest';

    Widget pageContent = QRSessionOverlay(
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (QRSessionTimer.isActive) {
            QRSessionTimer.stopSession();
            await FirebaseAuth.instance.signOut();
            if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.lightBlue.shade400,
            elevation: 0,
            leading: Tooltip(
              message: 'تحديث الصفحة للحصول على آخر التعديلات',
              child: GestureDetector(
                onTap: () {
                  if (kIsWeb) {
                    html.window.location.reload();
                  } else {
                    _onRefresh();
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Cairo')
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
                      icon: const Icon(Icons.notifications_rounded),
                      tooltip: 'الإشعارات',
                      onPressed: _showNotifications,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
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
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'تسجيل الخروج',
                onPressed: () async {
                  QRSessionTimer.stopSession();
                  await FirebaseAuth.instance.signOut();
                  if(mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
                : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTeacherDashboard(),
              ],
            ),
          ),
          floatingActionButton: null,
        ),
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
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: CircleAvatar(
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
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        jobTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.8,
                child: Icon(Icons.person_outline_rounded, color: Colors.white.withOpacity(0.3), size: 45),
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
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 8 : 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 22,
            childAspectRatio: 0.78,
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
                        icon: Icons.wifi_tethering_rounded,
                        color: const Color(0xFF00BFA5),
                        onTap: () {},
                        statCount: '...',
                      );
                    }
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _AnimatedGridButton(
                      title: 'متصل حالياً',
                      icon: Icons.wifi_tethering_rounded,
                      color: const Color(0xFF00BFA5),
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
                        color: const Color(0xFF546E7A),
                        onTap: () {},
                        statCount: '...',
                      );
                    }
                    final count = snapshot.hasData ? snapshot.data!.count : 0;
                    return _AnimatedGridButton(
                      title: 'الغياب',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF546E7A),
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

              _AnimatedGridButton(
                title: 'رصد الدرجات',
                icon: Icons.edit_document,
                color: const Color(0xFF2962FF),
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

              _AnimatedGridButton(
                title: 'فصولي وطلباتي',
                icon: Icons.class_rounded,
                color: const Color(0xFF00897B),
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeacherClassesManagerPage()),
                    );
                  }
                },
              ),

              if (_isAdmin)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('teacher_class_requests')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int requestsCount = 0;
                    if (snapshot.hasData) {
                      requestsCount = snapshot.data!.docs.length;
                    }
                    return _AnimatedGridButton(
                      title: 'طلبات الفصول',
                      icon: Icons.assignment_ind_rounded,
                      color: const Color(0xFF00ACC1),
                      badgeCount: requestsCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminTeacherRequestsPage()),
                        );
                      },
                    );
                  },
                ),

              _AnimatedGridButton(
                title: 'ربط حساب جوجل',
                svgPath: 'assets/g1.svg',
                color: const Color(0xFF651FFF),
                onTap: () {
                  if (isGuest) {
                    _showGuestError();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoogleAccountLinkerPage()),
                    );
                  }
                },
              ),

              _AnimatedGridButton(
                title: 'الطالب المنضبط',
                icon: Icons.star_rounded,
                color: const Color(0xFFFF9100),
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

              _AnimatedGridButton(
                title: 'تعميم النماذج',
                icon: Icons.dynamic_form_rounded,
                color: const Color(0xFF3D5AFE),
                onTap: _launchEduFormsUrl,
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
                  title: 'رمز الضيف',
                  icon: Icons.vpn_key_rounded,
                  color: const Color(0xFFAA00FF),
                  onTap: _showChangeGuestPinDialog,
                ),
              if (showAdminFeatures)
                _AnimatedGridButton(
                  title: 'استكمال الرصد',
                  icon: Icons.donut_large_rounded,
                  color: const Color(0xFF00B8D4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GradeCompletionAnalyticsPage()),
                    );
                  },
                ),

              if (_isAdmin)
                _AnimatedGridButton(
                  title: 'تحميل الشهادات',
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFFE65100),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkCertificateDownloadPage()));
                  },
                ),

              _AnimatedGridButton(
                title: 'ملف الإنجاز',
                icon: Icons.folder_shared_rounded,
                color: const Color(0xFF37474F),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeacherPortfolioPage(isAdmin: _isAdmin)),
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

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                badges.Badge(
                  showBadge: widget.badgeCount != null && widget.badgeCount! > 0,
                  badgeContent: Text('${widget.badgeCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  position: badges.BadgePosition.topEnd(top: -4, end: -4),
                  badgeAnimation: const badges.BadgeAnimation.scale(),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red.shade600,
                    elevation: 3,
                  ),
                  child: Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.12),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: widget.color.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                    child: widget.statCount != null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.svgPath != null
                              ? SvgPicture.asset(widget.svgPath!, width: boxSize * 0.32, height: boxSize * 0.32)
                              : Icon(widget.icon, size: boxSize * 0.32, color: widget.color.withOpacity(0.6)),
                          const SizedBox(height: 2),
                          Text(
                            widget.statCount!,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: widget.color,
                                fontFamily: 'Cairo'
                            ),
                          ),
                        ],
                      ),
                    )
                        : Center(
                      child: Container(
                        padding: EdgeInsets.all(widget.svgPath != null ? boxSize * 0.15 : boxSize * 0.20),
                        decoration: BoxDecoration(
                          color: widget.svgPath != null ? Colors.transparent : widget.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: widget.svgPath != null
                            ? SvgPicture.asset(widget.svgPath!, width: boxSize * 0.45, height: boxSize * 0.45)
                            : Icon(widget.icon, size: boxSize * 0.40, color: widget.color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
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

class TeacherClassesManagerPage extends StatefulWidget {
  const TeacherClassesManagerPage({super.key});

  @override
  _TeacherClassesManagerPageState createState() => _TeacherClassesManagerPageState();
}

class _TeacherClassesManagerPageState extends State<TeacherClassesManagerPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<Map<String, String>> _currentAssignments = [];
  final List<Map<String, String>> _requestedAdditions = [];
  final List<Map<String, String>> _requestedRemovals = [];

  String? _selectedStage;
  String? _selectedGrade;
  String? _selectedClass;
  String? _selectedSubject;

  final List<String> _stages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];

  // ✅ القوائم الافتراضية الشاملة مع صيغة "الفصل 1"
  List<String> _classesList = [
    'الفصل 1', 'الفصل 2', 'الفصل 3', 'الفصل 4', 'الفصل 5', 'الفصل 6',
    'الفصل 7', 'الفصل 8', 'الفصل 9', 'الفصل 10', 'أ', 'ب', 'ج', 'د', 'هـ'
  ];
  List<String> _subjectsList = [
    'رياضيات', 'لغتي', 'علوم', 'انجليزي', 'إسلاميات', 'اجتماعيات', 'فنية', 'بدنية', 'رقمية', 'حياتية', 'تفكير', 'نشاط'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTeacherSubjectsAndClasses();
    _fetchCurrentClasses();
  }

  Future<void> _fetchTeacherSubjectsAndClasses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        List<String> teacherSubjects = [];

        if (data.containsKey('subjects') && data['subjects'] is List) {
          teacherSubjects = List<String>.from(data['subjects']);
        } else if (data.containsKey('subject')) {
          final subjData = data['subject'];
          if (subjData is String && subjData.isNotEmpty) {
            teacherSubjects = subjData.split(RegExp(r'[,،]')).map((e) => e.trim()).toList();
          } else if (subjData is List) {
            teacherSubjects = List<String>.from(subjData);
          }
        }

        if (mounted && teacherSubjects.isNotEmpty) {
          setState(() {
            _subjectsList = teacherSubjects;
          });
        }
      }

      final appData = await FirebaseFirestore.instance.collection('settings').doc('app_data').get();
      if (appData.exists && appData.data() != null) {
        if (appData.data()!.containsKey('classes')) {
          if (mounted) {
            setState(() {
              // ✅ حماية برمجية لضمان وجود كلمة "الفصل"
              _classesList = (appData.data()!['classes'] as List).map((e) {
                String c = e.toString().trim();
                return int.tryParse(c) != null ? 'الفصل $c' : c;
              }).toList();
            });
          }
        }

        if (_subjectsList.isEmpty && appData.data()!.containsKey('subjects')) {
          if (mounted) {
            setState(() {
              _subjectsList = List<String>.from(appData.data()!['subjects']);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching teacher data: $e");
    }
  }

  List<String> _getGradesForStage(String? stage) {
    if (stage == 'المرحلة الابتدائية') return ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'];
    if (stage == 'المرحلة المتوسطة') return ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'];
    if (stage == 'المرحلة الثانوية') return ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];
    return [];
  }

  Future<void> _fetchCurrentClasses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data == null) {
        setState(() => _isLoading = false);
        return;
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

      List<Map<String, String>> parsedAssignments = [];

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
                      String className = parts[0].trim();
                      // ✅ توحيد الصيغة حتى تظهر زر الإزالة بشكل صحيح
                      if(int.tryParse(className) != null) className = 'الفصل $className';
                      parsedAssignments.add({
                        'stage': stageName,
                        'grade': gradeName,
                        'className': className,
                        'subject': parts[1].trim(),
                      });
                    }
                  }
                }
              }
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _currentAssignments = parsedAssignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تحميل الفصول: $e')));
      }
    }
  }

  void _markForRemoval(Map<String, String> assignment) {
    setState(() {
      _currentAssignments.remove(assignment);
      _requestedRemovals.add(assignment);
    });
  }

  void _undoRemoval(Map<String, String> assignment) {
    setState(() {
      _requestedRemovals.remove(assignment);
      _currentAssignments.add(assignment);
    });
  }

  void _addNewAssignmentRequest() {
    if (_selectedStage == null || _selectedGrade == null || _selectedClass == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار جميع الحقول من القوائم للإضافة.')));
      return;
    }

    final newAssignment = {
      'stage': _selectedStage!,
      'grade': _selectedGrade!,
      'className': _selectedClass!,
      'subject': _selectedSubject!,
    };

    setState(() {
      _requestedAdditions.add(newAssignment);
      _selectedClass = null;
      _selectedSubject = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة لقائمة الطلبات (لم يتم الإرسال بعد)'), backgroundColor: Colors.blue));
  }

  void _undoAddition(Map<String, String> assignment) {
    setState(() {
      _requestedAdditions.remove(assignment);
    });
  }

  Future<void> _submitRequestToAdmin() async {
    if (_requestedAdditions.isEmpty && _requestedRemovals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد تعديلات لإرسالها.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final teacherName = userDoc.data()?['name'] ?? 'معلم';

      await FirebaseFirestore.instance.collection('teacher_class_requests').add({
        'teacherId': user?.uid,
        'teacherName': teacherName,
        'additions': _requestedAdditions,
        'removals': _requestedRemovals,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _requestedAdditions.clear();
          _requestedRemovals.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب التعديل للإدارة بنجاح. يرجى انتظار الموافقة.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإرسال: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفصول والمواد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الفصول المسندة لك حالياً:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            if (_currentAssignments.isEmpty)
              const Text('لا توجد فصول مسندة حالياً.', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentAssignments.length,
                itemBuilder: (context, index) {
                  final item = _currentAssignments[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                      title: Text('${item['stage']} - ${item['grade']}'),
                      subtitle: Text('الفصل: ${item['className']} | المادة: ${item['subject']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
                        tooltip: 'طلب إزالة هذا الفصل',
                        onPressed: () => _markForRemoval(item),
                      ),
                    ),
                  );
                },
              ),

            const Divider(height: 40, thickness: 2),

            const Text('إضافة فصل جديد لجدولك:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'السنة الدراسية (المرحلة)', border: OutlineInputBorder()),
                      value: _selectedStage,
                      items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedStage = val;
                          _selectedGrade = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'الصف', border: OutlineInputBorder()),
                      value: _selectedGrade,
                      items: _getGradesForStage(_selectedStage).map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGrade = val),
                      disabledHint: const Text('اختر المرحلة أولاً'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'الفصل (الشعبة)', border: OutlineInputBorder()),
                            value: _classesList.contains(_selectedClass) ? _selectedClass : null,
                            items: _classesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _selectedClass = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'المادة', border: OutlineInputBorder()),
                            value: _subjectsList.contains(_selectedSubject) ? _selectedSubject : null,
                            items: _subjectsList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _selectedSubject = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة إلى مسودة الطلب'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900),
                      onPressed: _addNewAssignmentRequest,
                    )
                  ],
                ),
              ),
            ),

            const Divider(height: 40, thickness: 2),

            const Text('مسودة الطلب (التعديلات المقترحة):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            if (_requestedAdditions.isEmpty && _requestedRemovals.isEmpty)
              const Text('لا توجد تعديلات مقترحة حتى الآن.', style: TextStyle(color: Colors.grey)),

            if (_requestedAdditions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text('سيتم إضافة الفصول التالية:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
              ..._requestedAdditions.map((item) => Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.add_box_rounded, color: Colors.green),
                  title: Text('${item['stage']} - ${item['grade']}'),
                  subtitle: Text('الفصل: ${item['className']} | المادة: ${item['subject']}'),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _undoAddition(item)),
                ),
              )).toList(),
            ],

            if (_requestedRemovals.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 4),
                child: Text('سيتم إزالة الفصول التالية من جدولك:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              ..._requestedRemovals.map((item) => Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.indeterminate_check_box_rounded, color: Colors.red),
                  title: Text('${item['stage']} - ${item['grade']}'),
                  subtitle: Text('الفصل: ${item['className']} | المادة: ${item['subject']}'),
                  trailing: IconButton(icon: const Icon(Icons.undo_rounded, color: Colors.blue), onPressed: () => _undoRemoval(item)),
                ),
              )).toList(),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _requestedAdditions.isNotEmpty || _requestedRemovals.isNotEmpty
          ? SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 50,
        child: ElevatedButton.icon(
          icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
          label: Text(_isSubmitting ? 'جاري الإرسال...' : 'إرسال الطلب النهائي للإدارة', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
          onPressed: _isSubmitting ? null : _submitRequestToAdmin,
        ),
      )
          : null,
    );
  }
}

class AdminTeacherRequestsPage extends StatefulWidget {
  const AdminTeacherRequestsPage({super.key});

  @override
  State<AdminTeacherRequestsPage> createState() => _AdminTeacherRequestsPageState();
}

class _AdminTeacherRequestsPageState extends State<AdminTeacherRequestsPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات تعديل فصول المعلمين'),
        backgroundColor: const Color(0xFF00ACC1),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('teacher_class_requests')
                .where('status', isEqualTo: 'pending')
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
                      Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد طلبات معلقة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>?;
                final bData = b.data() as Map<String, dynamic>?;
                final aTime = aData?['timestamp'] as Timestamp?;
                final bTime = bData?['timestamp'] as Timestamp?;

                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final teacherName = data['teacherName'] ?? 'معلم غير معروف';
                  final additions = List<Map<String, dynamic>>.from(data['additions'] ?? []);
                  final removals = List<Map<String, dynamic>>.from(data['removals'] ?? []);
                  final timestamp = data['timestamp'] as Timestamp?;
                  final dateString = timestamp != null
                      ? intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(timestamp.toDate())
                      : 'غير محدد';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text(dateString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1.5),

                          if (additions.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text('المطلوب إضافته لجدول المعلم:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...additions.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4, right: 28),
                              child: Text('• ${item['stage']} - ${item['grade']} (${item['className']}) | مادة: ${item['subject']}', style: const TextStyle(fontSize: 14)),
                            )),
                            const SizedBox(height: 12),
                          ],

                          if (removals.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Text('المطلوب إزالته من جدول المعلم:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...removals.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4, right: 28),
                              child: Text('• ${item['stage']} - ${item['grade']} (${item['className']}) | مادة: ${item['subject']}', style: const TextStyle(fontSize: 14)),
                            )),
                            const SizedBox(height: 16),
                          ],

                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('ملاحظة: الموافقة هنا ستقوم بتحديث فصول المعلم في قاعدة البيانات وإضافتها لجدوله تلقائياً.', style: TextStyle(fontSize: 12, color: Colors.green))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('موافقة وتحديث'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: _isProcessing ? null : () => _updateRequestStatus(context, doc.id, 'approved', data),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('رفض'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                  onPressed: _isProcessing ? null : () => _updateRequestStatus(context, doc.id, 'rejected', data),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
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

  Future<void> _updateRequestStatus(BuildContext context, String docId, String status, Map<String, dynamic> requestData) async {
    setState(() => _isProcessing = true);

    try {
      if (status == 'approved') {
        final teacherId = requestData['teacherId'];
        if (teacherId == null) throw Exception("معرف المعلم غير موجود في الطلب");

        final userRef = FirebaseFirestore.instance.collection('users').doc(teacherId);
        final userDoc = await userRef.get();
        if (!userDoc.exists) throw Exception("لم يتم العثور على ملف المعلم");

        final userData = userDoc.data() ?? {};
        Map<String, dynamic> updates = {};

        final additions = List<Map<String, dynamic>>.from(requestData['additions'] ?? []);
        final removals = List<Map<String, dynamic>>.from(requestData['removals'] ?? []);

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

        String getClassStr(String classField) {
          if (updates.containsKey(classField)) return updates[classField];
          final val = userData[classField];
          return (val != null && val != '0') ? val.toString() : '';
        }

        for (var item in removals) {
          final stage = item['stage'];
          final grade = item['grade'];
          String className = item['className'].toString().trim();
          // ✅ معالجة الحماية: إذا كان الرقم موجوداً نضيف له كلمة "الفصل" للبحث الصحيح في الحذف
          if (int.tryParse(className) != null) className = "الفصل $className";

          final subject = item['subject'];

          final stageInfo = structure[stage];
          if (stageInfo != null) {
            final gradeInfo = (stageInfo['grades'] as Map)[grade];
            if (gradeInfo != null) {
              String classField = gradeInfo['classField'] as String;
              String currentStr = getClassStr(classField);

              if (currentStr.isNotEmpty) {
                List<String> pairs = currentStr.split(',').map((e) => e.trim()).toList();
                String target1 = "$className=$subject";
                String target2 = "${className.replaceAll('الفصل ', '')}=$subject";
                pairs.removeWhere((p) => p == target1 || p == target2);
                updates[classField] = pairs.join(', ');
              }
            }
          }
        }

        for (var item in additions) {
          final stage = item['stage'];
          final grade = item['grade'];
          String className = item['className'].toString().trim();
          if (int.tryParse(className) != null) className = "الفصل $className";
          final subject = item['subject'];

          final stageInfo = structure[stage];
          if (stageInfo != null) {
            String stageField = stageInfo['field'] as String;

            if (userData[stageField] == null || userData[stageField] == '' || userData[stageField] == '0') {
              updates[stageField] = stage;
            }

            final gradeInfo = (stageInfo['grades'] as Map)[grade];
            if (gradeInfo != null) {
              String gradeField = gradeInfo['field'] as String;
              String classField = gradeInfo['classField'] as String;

              if (userData[gradeField] == null || userData[gradeField] == '' || userData[gradeField] == '0') {
                updates[gradeField] = grade;
              }

              String currentStr = getClassStr(classField);
              String newPair = "$className=$subject";

              if (currentStr.isEmpty) {
                updates[classField] = newPair;
              } else {
                if (!currentStr.contains(newPair)) {
                  updates[classField] = "$currentStr, $newPair";
                }
              }
            }
          }
        }

        final batch = FirebaseFirestore.instance.batch();
        if (updates.isNotEmpty) {
          batch.update(userRef, updates);
        }

        batch.update(FirebaseFirestore.instance.collection('teacher_class_requests').doc(docId), {
          'status': status,
          'processedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت الموافقة وتحديث بيانات فصول المعلم بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('teacher_class_requests').doc(docId).update({
          'status': status,
          'processedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض الطلب بنجاح'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isProcessing = false);
    }
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
                            const PopupMenuItem<String>(
                              value: 'view_profile',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_rounded, color: Colors.blue),
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
                            const PopupMenuItem<String>(
                              value: 'behavior',
                              child: Row(
                                children: [
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
                Icon(Icons.pie_chart_rounded, color: Theme.of(context).primaryColor, size: 28),
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

class BulkCertificateDownloadPage extends StatefulWidget {
  const BulkCertificateDownloadPage({super.key});

  @override
  State<BulkCertificateDownloadPage> createState() => _BulkCertificateDownloadPageState();
}

class _BulkCertificateDownloadPageState extends State<BulkCertificateDownloadPage> {
  String? _selectedStage;
  String? _selectedGrade;
  String? _selectedClass;
  int? _selectedTerm;
  bool _isGenerating = false;

  final List<String> _stages = ['المرحلة الابتدائية', 'المرحلة المتوسطة', 'المرحلة الثانوية'];

  // ✅ القائمة الافتراضية للشهادات
  List<String> _classesList = [
    'الكل', 'الفصل 1', 'الفصل 2', 'الفصل 3', 'الفصل 4', 'الفصل 5',
    'الفصل 6', 'الفصل 7', 'الفصل 8', 'الفصل 9', 'الفصل 10', 'أ', 'ب', 'ج', 'د', 'هـ'
  ];

  @override
  void initState() {
    super.initState();
    _fetchClassesFromFirestore();
  }

  Future<void> _fetchClassesFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('app_data').get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('classes')) {
        if (mounted) {
          setState(() {
            // ✅ حماية برمجية: تحويل الرقم الصريح إلى "الفصل X"
            List<String> fetched = (doc.data()!['classes'] as List).map((e) {
              String c = e.toString().trim();
              return int.tryParse(c) != null ? 'الفصل $c' : c;
            }).toList();
            _classesList = ['الكل', ...fetched];
          });
        }
      }
    } catch(e) {
      debugPrint("Error fetching classes: $e");
    }
  }

  List<String> _getGradesForStage(String? stage) {
    if (stage == 'المرحلة الابتدائية') return ['الصف الأول', 'الصف الثاني', 'الصف الثالث', 'الصف الرابع', 'الصف الخامس', 'الصف السادس'];
    if (stage == 'المرحلة المتوسطة') return ['الصف الأول المتوسط', 'الصف الثاني المتوسط', 'الصف الثالث المتوسط'];
    if (stage == 'المرحلة الثانوية') return ['الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];
    return [];
  }

  double _calculateTermPercentage(Map<String, dynamic> data, int term) {
    final Map<String, String> standardSubjects = {
      'profession1': 'رياضيات', 'profession2': 'لغتي', 'profession3': 'إسلاميات',
      'profession4': 'علوم', 'profession5': 'نشاط', 'profession6': 'انجليزي',
      'profession7': 'اجتماعيات', 'profession8': 'فنية', 'profession9': 'حياتية',
      'profession10': 'بدنية', 'profession11': 'رقمية', 'profession12': 'تفكير',
    };

    List<double> subjectPercents = [];

    standardSubjects.forEach((profKey, subjName) {
      List<num> grades = [];
      int startIdx = term == 1 ? 1 : 4;
      int endIdx = term == 1 ? 3 : 6;
      for (int i = startIdx; i <= endIdx; i++) {
        String key = 'e$i$profKey';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }
      int eStart = term == 1 ? 14 : 17;
      int eEnd = term == 1 ? 16 : 19;
      for (int i = eStart; i <= eEnd; i++) {
        String key = 'e$i$profKey';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }

      if (grades.isNotEmpty) {
        double avg = grades.reduce((a, b) => a + b) / grades.length;
        subjectPercents.add((avg / 20) * 100);
      }
    });

    final List<String> nafesKeys = ['math', 'lughati', 'science'];
    for (String n in nafesKeys) {
      List<num> grades = [];
      for (int i = 1; i <= 12; i++) {
        String key = term == 1 ? 'e${i}profession13_$n' : 't2_e${i}profession13_$n';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }
      if (grades.isNotEmpty) {
        double avg = grades.reduce((a, b) => a + b) / grades.length;
        subjectPercents.add((avg / 10) * 100);
      }
    }

    if (subjectPercents.isEmpty) return 0.0;
    return subjectPercents.reduce((a, b) => a + b) / subjectPercents.length;
  }

  List<Map<String, dynamic>> _getSubjectGrades(Map<String, dynamic> data, int term) {
    final Map<String, String> standardSubjects = {
      'profession1': 'رياضيات', 'profession2': 'لغتي', 'profession3': 'إسلاميات',
      'profession4': 'علوم', 'profession6': 'انجليزي', 'profession7': 'اجتماعيات',
      'profession8': 'فنية', 'profession10': 'بدنية', 'profession11': 'رقمية', 'profession12': 'تفكير',
    };
    List<Map<String, dynamic>> subjectGrades = [];
    standardSubjects.forEach((profKey, subjName) {
      List<num> grades = [];
      int startIdx = term == 1 ? 1 : 4;
      int endIdx = term == 1 ? 3 : 6;
      for (int i = startIdx; i <= endIdx; i++) {
        String key = 'e$i$profKey';
        if (data[key] != null && data[key] is num && data[key] >= 0) grades.add(data[key]);
      }
      if (grades.isNotEmpty) {
        double avg = grades.reduce((a, b) => a + b) / grades.length;
        subjectGrades.add({'name': subjName, 'percent': ((avg / 20) * 100).clamp(0, 100)});
      }
    });
    return subjectGrades;
  }

  Future<void> _generateAndDownloadPDF() async {
    if (_selectedStage == null || _selectedGrade == null || _selectedClass == null || _selectedTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار جميع الحقول أولاً')));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      Query query = FirebaseFirestore.instance.collection('students')
          .where('stages', isEqualTo: _selectedStage)
          .where('grades', isEqualTo: _selectedGrade);

      if (_selectedClass != 'الكل') {
        query = query.where('classes', isEqualTo: _selectedClass);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد طلاب في هذا التحديد')));
        setState(() => _isGenerating = false);
        return;
      }

      List<Map<String, dynamic>> studentsList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        double p = _calculateTermPercentage(data, _selectedTerm!);
        data['calculated_percent'] = p;
        studentsList.add(data);
      }

      studentsList.sort((a, b) => (b['calculated_percent'] as double).compareTo(a['calculated_percent'] as double));

      for (int i = 0; i < studentsList.length; i++) {
        studentsList[i]['rank'] = i + 1;
        studentsList[i]['subject_grades'] = _getSubjectGrades(studentsList[i], _selectedTerm!);
      }

      final pdf = pw.Document();
      final font = await PdfGoogleFonts.amiriBold();

      pw.MemoryImage? m1Image;
      try {
        final ByteData m1Data = await rootBundle.load('assets/m1.png');
        m1Image = pw.MemoryImage(m1Data.buffer.asUint8List());
      } catch (e) {
        debugPrint("Image m1 missing, using fallback.");
      }

      pw.MemoryImage? m2Image;
      try {
        final ByteData m2Data = await rootBundle.load('assets/2.png');
        m2Image = pw.MemoryImage(m2Data.buffer.asUint8List());
      } catch (e) {
        debugPrint("Image m2 missing, using fallback.");
      }

      // ✅ استدعاء كلتا الصورتين (فوق 90 وأقل من 90)
      String? svgRaw1;
      String? svgRaw2;
      try {
        svgRaw1 = await rootBundle.loadString('assets/sh1.svg');
      } catch (e) {}
      try {
        svgRaw2 = await rootBundle.loadString('assets/sh2.svg');
      } catch (e) {}

      final String termName = _selectedTerm == 1 ? 'الترم الأول' : 'الترم الثاني';

      for (var student in studentsList) {
        if (student['calculated_percent'] == 0.0) continue;

        final studentName = student['name'] ?? 'الطالب';
        final double percentDouble = student['calculated_percent'] as double;
        final percent = percentDouble.toStringAsFixed(1);
        final rank = student['rank'];
        final rankText = (rank > 0 && rank <= 10) ? 'وحصوله على المركز (الـ $rank) على مستوى المرحلة،' : '';
        final subjects = student['subject_grades'] as List<Map<String, dynamic>>;

        // ✅ شرط ديناميكي لاختيار ملف الـ SVG بناءً على النسبة
        final String? svgRaw = percentDouble >= 90.0 ? svgRaw1 : svgRaw2;

        // --- الصفحة الأولى: واجهة التكريم ---
        pdf.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.zero,
            theme: pw.ThemeData.withFont(base: font),
            textDirection: pw.TextDirection.rtl,
            build: (pw.Context context) {
              return pw.Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const pw.EdgeInsets.all(35),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.amber, width: 8),
                    color: const PdfColor.fromInt(0xFFFDFBF7),
                  ),
                  child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              m1Image != null ? pw.Image(m1Image, width: 100, height: 100) : pw.SizedBox(width: 100, height: 100),
                              pw.Expanded(
                                child: pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 20),
                                  child: pw.Center(
                                    child: svgRaw != null
                                        ? pw.SvgImage(svg: svgRaw, width: 150)
                                        : pw.Text("شهادة شكر وتقدير", style: pw.TextStyle(font: font, fontSize: 35, color: PdfColors.indigo)),
                                  ),
                                ),
                              ),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    m2Image != null ? pw.Image(m2Image, width: 80, height: 80) : pw.SizedBox(width: 80, height: 80),
                                    pw.SizedBox(height: 4),
                                    pw.Text('elm3rfa.vip', style: pw.TextStyle(font: font, fontSize: 12)),
                                  ]
                              ),
                            ]
                        ),
                        pw.SizedBox(height: 35),
                        // ✅ إزالة كلمة المتميز
                        pw.Text('تسر إدارة المدرسة أن تمنح هذا التقدير للطالب:', style: pw.TextStyle(font: font, fontSize: 20)),
                        pw.SizedBox(height: 10),
                        pw.Text(studentName, style: pw.TextStyle(font: font, fontSize: 44, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 15),
                        pw.Text('لتفوقه واجتهاده الملحوظ خلال $termName، وحصوله على نسبة $percent%', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 20)),
                        if (rankText.isNotEmpty)
                          pw.Text(rankText, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 20)),
                        pw.Text('متمنين له دوام التوفيق والنجاح.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 20)),
                        pw.Spacer(),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end, // ✅ نقل مدير المدرسة لليسار
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              // ✅ تمت إزالة توقيع وكيل الشؤون التعليمية
                              pw.Column(children: [
                                pw.Text('مدير المدرسة', style: pw.TextStyle(font: font, color: PdfColors.indigo, fontSize: 16)),
                                pw.SizedBox(height: 25),
                                pw.Text('أ. عبدالله عائش المطرفي', style: pw.TextStyle(font: font, fontSize: 16)),
                              ]),
                            ]
                        )
                      ]
                  )
              );
            }
        ));

        // --- الصفحة الثانية: كشف الدرجات ---
        pdf.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.zero,
            theme: pw.ThemeData.withFont(base: font),
            textDirection: pw.TextDirection.rtl,
            build: (pw.Context context) {
              return pw.Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const pw.EdgeInsets.all(35),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.amber, width: 8),
                    color: const PdfColor.fromInt(0xFFFDFBF7),
                  ),
                  child: pw.Column(
                      children: [
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              m1Image != null ? pw.Image(m1Image, width: 80, height: 80) : pw.SizedBox(width: 80, height: 80),
                              pw.Text('كشف الدرجات الأكاديمية - $termName', style: pw.TextStyle(font: font, fontSize: 26, color: PdfColors.indigo)),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    m2Image != null ? pw.Image(m2Image, width: 80, height: 80) : pw.SizedBox(width: 80, height: 80),
                                    pw.SizedBox(height: 4),
                                    pw.Text('elm3rfa.vip', style: pw.TextStyle(font: font, fontSize: 12)),
                                  ]
                              ),
                            ]
                        ),
                        pw.SizedBox(height: 20),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            children: [
                              pw.Text('النسبة الكلية: $percent%', style: pw.TextStyle(font: font, fontSize: 22)),
                              if (rank <= 10) pw.Text('الترتيب بالمرحلة: الـ $rank', style: pw.TextStyle(font: font, fontSize: 22)),
                            ]
                        ),
                        pw.SizedBox(height: 30),
                        pw.Expanded(
                            child: pw.Wrap(
                              spacing: 15,
                              runSpacing: 15,
                              alignment: pw.WrapAlignment.center,
                              children: subjects.map((s) => pw.Container(
                                  width: 230,
                                  padding: const pw.EdgeInsets.all(12),
                                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                                  child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(s['name'], style: pw.TextStyle(font: font, fontSize: 16)),
                                        pw.Text('${(s['percent'] as double).toStringAsFixed(1)}%', style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.indigo)),
                                      ]
                                  )
                              )).toList(),
                            )
                        ),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'تنويه تربوي: هذه الدرجات مستمدة من تقييمات تشخيصية لقياس المهارات الأكاديمية، ولا تُضاف للمجموع العام، وإنما هي أداة قياس تساعدنا وإياكم في رسم رحلة التطوير والارتقاء بمستويات أبنائنا الطلاب الأعزاء.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.red, fontWeight: pw.FontWeight.bold),
                        ),
                      ]
                  )
              );
            }
        ));
      }
      final bytes = await pdf.save();
      final fileName = "شهادات_${_selectedGrade}_${_selectedClass}_$termName.pdf";

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        OpenFilex.open(file.path);
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم توليد وتحميل الشهادات بنجاح!'), backgroundColor: Colors.green));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحميل شهادات الطلاب (PDF)'),
        backgroundColor: const Color(0xFFE65100),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 60, color: Color(0xFFE65100)),
                    const SizedBox(height: 16),
                    const Text('استخراج شهادات التقدير', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('اختر بيانات الفصل لتحميل جميع الشهادات في ملف PDF واحد.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const Divider(height: 40),

                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'الترم الدراسي', border: OutlineInputBorder()),
                      value: _selectedTerm,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('الترم الأول')),
                        DropdownMenuItem(value: 2, child: Text('الترم الثاني')),
                      ],
                      onChanged: (val) => setState(() => _selectedTerm = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'المرحلة', border: OutlineInputBorder()),
                      value: _selectedStage,
                      items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedStage = val;
                          _selectedGrade = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'الصف', border: OutlineInputBorder()),
                      value: _selectedGrade,
                      items: _getGradesForStage(_selectedStage).map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGrade = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'الفصل (أو الكل)', border: OutlineInputBorder()),
                      value: _classesList.contains(_selectedClass) ? _selectedClass : null,
                      items: _classesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedClass = val),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isGenerating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.download),
                        label: Text(_isGenerating ? 'جاري إنشاء الـ PDF...' : 'توليد وتحميل الشهادات'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                        onPressed: _isGenerating ? null : _generateAndDownloadPDF,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}