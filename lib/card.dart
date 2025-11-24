import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ---------------------------------------------------------------------------
// قائمة الرموز التسويقية (مخصصة للمقصف/البقالة) 🛒
// ---------------------------------------------------------------------------
final List<IconData> marketingIcons = [
  Icons.local_grocery_store,
  Icons.water_drop,
  Icons.local_drink,
  Icons.cookie,
  Icons.cake,
  Icons.takeout_dining,
  Icons.icecream,
  Icons.lunch_dining,
  Icons.apple,
  Icons.fastfood,
  Icons.local_cafe,
  Icons.local_pizza,
  Icons.breakfast_dining,
  Icons.emoji_food_beverage,
  Icons.set_meal,
  Icons.shopping_bag,
  Icons.restaurant,
  Icons.favorite,
  Icons.star,
  Icons.verified,
];

// ---------------------------------------------------------------------------
// دوال مساعدة للأمان والسجلات (Security & Logging Helpers)
// ---------------------------------------------------------------------------

/// دالة للتحقق من هوية الأدمن عن طريق طلب كلمة المرور الحالية
Future<bool> _confirmWithPassword(BuildContext context) async {
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  if (user == null || user.email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خطأ: لا يوجد مستخدم مسجل دخول.')),
    );
    return false;
  }

  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool isChecking = false;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.red),
                SizedBox(width: 10),
                Text('تأكيد الهوية'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إجراء حساس: يرجى إدخال كلمة المرور الخاصة بحسابك لتأكيد العملية.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  if (isChecking)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isChecking ? null : () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isChecking
                    ? null
                    : () async {
                  if (formKey.currentState!.validate()) {
                    setDialogState(() => isChecking = true);
                    try {
                      // محاولة إعادة المصادقة
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: passwordController.text,
                      );
                      await user.reauthenticateWithCredential(credential);
                      if (context.mounted) Navigator.pop(context, true);
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() => isChecking = false);
                      String errorMsg = 'كلمة المرور غير صحيحة';
                      if (e.code == 'network-request-failed') {
                        errorMsg = 'خطأ في الاتصال بالشبكة';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                      );
                    } catch (e) {
                      setDialogState(() => isChecking = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('حدث خطأ غير متوقع'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  ) ?? false;
}

/// دالة لحفظ سجل العمليات الحساسة في الفايربيز
Future<void> _logAuditAction({
  required String actionType, // e.g., "VISA_RESET", "DEPOSIT", "DEDUCTION"
  required String studentId,
  required String studentName,
  required String details, // e.g., "Amount: 500", "NewCode: XYZ..."
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final userData = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
  final adminName = userData.data()?['name'] ?? user?.email ?? 'Unknown Admin';

  await FirebaseFirestore.instance.collection('admin_audit_logs').add({
    'action': actionType,
    'adminId': user?.uid,
    'adminName': adminName,
    'adminEmail': user?.email,
    'studentId': studentId,
    'studentName': studentName,
    'details': details,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

// ---------------------------------------------------------------------------
// 1. اللوحة الرئيسية (Dashboard)
// ---------------------------------------------------------------------------

class VisaManagementPage extends StatelessWidget {
  const VisaManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = Colors.lightBlue.shade300;
    final Color backgroundColor = const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'نظام المقصف والفيزا',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ كارت الخزنة
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (context, snapshot) {
                  double totalVault = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      totalVault += (doc.data() as Map<String, dynamic>)['total'] ?? 0;
                    }
                  }
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text('خزنة المبيعات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          '${totalVault.toStringAsFixed(2)} ﷼',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Arial'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ✅✅✅ القائمة الرئيسية ✅✅✅
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Wrap(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.start,
                  spacing: 40.0,
                  runSpacing: 40.0,
                  children: [
                    _buildFreeIcon(
                      context,
                      'تعديل الفيزا',
                      Icons.qr_code_scanner_rounded,
                      Colors.cyan,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaGenerationView())),
                    ),
                    // ✅ زر العمليات المالية (إيداع/خصم)
                    _buildFreeIcon(
                      context,
                      'العمليات المالية',
                      Icons.monetization_on_rounded,
                      Colors.purple,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDepositPage())),
                    ),
                    _buildFreeIcon(
                      context,
                      'المخزن',
                      Icons.inventory_2_rounded,
                      Colors.blue,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementPage())),
                    ),
                    _buildFreeIcon(
                      context,
                      'نقطة البيع',
                      Icons.point_of_sale_rounded,
                      Colors.teal,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenPOSPage())),
                    ),
                    _buildFreeIcon(
                      context,
                      'التقارير',
                      Icons.bar_chart_rounded,
                      Colors.indigo,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaAnalyticsPage())),
                    ),
                    _buildFreeIcon(
                      context,
                      'التقويم',
                      Icons.calendar_month_rounded,
                      Colors.orange,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesCalendarPage())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeIcon(BuildContext context, String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: color.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, size: 30, color: color.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ صفحة العمليات المالية (إيداع/خصم) مع التحقق الأمني
// ---------------------------------------------------------------------------

class AdminDepositPage extends StatefulWidget {
  const AdminDepositPage({super.key});

  @override
  State<AdminDepositPage> createState() => _AdminDepositPageState();
}

class _AdminDepositPageState extends State<AdminDepositPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String _operationType = 'deposit'; // 'deposit' or 'deduction'

  // دالة البحث عن طالب
  Future<void> _searchStudent(String query) async {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await FirebaseFirestore.instance
          .collection('students')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      setState(() { _searchResults = res.docs; _isSearching = false; });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _processTransaction(String studentId, String name, double currentBalance) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController(); // سبب الخصم أو الإيداع

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('إدارة رصيد: $name'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الرصيد الحالي: ${currentBalance.toStringAsFixed(2)} ريال',
                    style: TextStyle(fontWeight: FontWeight.bold, color: currentBalance < 0 ? Colors.red : Colors.green),
                  ),
                  const SizedBox(height: 20),
                  // تبديل نوع العملية
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('إيداع (+)')),
                          selected: _operationType == 'deposit',
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: _operationType == 'deposit' ? Colors.green.shade900 : Colors.black),
                          onSelected: (val) => setDialogState(() => _operationType = 'deposit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('خصم (-)')),
                          selected: _operationType == 'deduction',
                          selectedColor: Colors.red.shade100,
                          labelStyle: TextStyle(color: _operationType == 'deduction' ? Colors.red.shade900 : Colors.black),
                          onSelected: (val) => setDialogState(() => _operationType = 'deduction'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      suffixText: 'ريال',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'سبب العملية (اختياري)',
                      hintText: 'مثال: مكافأة / تصحيح خطأ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _operationType == 'deposit' ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final double? amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')));
                    return;
                  }

                  Navigator.pop(context); // إغلاق نافذة المبلغ

                  // ✅ التحقق الأمني بكلمة مرور الأدمن
                  bool verified = await _confirmWithPassword(context);
                  if (verified) {
                    try {
                      double change = (_operationType == 'deposit') ? amount : -amount;
                      String actionLog = (_operationType == 'deposit') ? 'MONEY_DEPOSIT' : 'MONEY_DEDUCTION';

                      // تنفيذ العملية
                      await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                        'walletBalance': FieldValue.increment(change)
                      });

                      // ✅ تسجيل في السجل الأمني (Audit Log)
                      await _logAuditAction(
                        actionType: actionLog,
                        studentId: studentId,
                        studentName: name,
                        details: 'Amount: $amount SAR | Reason: ${reasonController.text}',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تمت العملية بنجاح (${_operationType == 'deposit' ? 'إيداع' : 'خصم'} $amount ريال)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _searchStudent(_searchController.text); // تحديث القائمة
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('تأكيد العملية'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العمليات المالية (Admin)'), backgroundColor: Colors.purple),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'ابحث عن طالب للإيداع أو الخصم...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _searchStudent,
              ),
            ),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final data = _searchResults[index].data() as Map<String, dynamic>;
                  final balance = (data['walletBalance'] ?? 0).toDouble();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(Icons.account_balance_wallet, color: Colors.purple),
                      ),
                      title: Text(data['name'] ?? '...'),
                      subtitle: Text('الرصيد الحالي: $balance ريال'),
                      trailing: ElevatedButton(
                        onPressed: () => _processTransaction(_searchResults[index].id, data['name'], balance),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                        child: const Text('إدارة الرصيد'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. صفحة إصدار وتعديل الفيزا (Visa Generation) مع زر إعادة التعيين الآمن
// ---------------------------------------------------------------------------

class VisaGenerationView extends StatefulWidget {
  const VisaGenerationView({super.key});

  @override
  State<VisaGenerationView> createState() => _VisaGenerationViewState();
}

class _VisaGenerationViewState extends State<VisaGenerationView> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  bool _isProcessing = false;

  String _generateRandomVisaCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _handleBulkGeneration() async {
    // هذه الدالة تنشئ أكواد للطلاب الذين ليس لديهم كود فقط
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('توليد تلقائي'),
        content: const Text('سيتم إنشاء كود فيزا لكل طالب جديد لا يملك واحداً.\nهل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isProcessing = true);

    try {
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int counter = 0;
      int updated = 0;

      for (var doc in studentsSnapshot.docs) {
        if (doc.data()['visaCode'] == null || doc.data()['visaCode'].toString().isEmpty) {
          batch.update(doc.reference, {'visaCode': _generateRandomVisaCode(), 'walletBalance': 0.0});
          updated++;
          counter++;
        }
        if (counter >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          counter = 0;
        }
      }
      if (counter > 0) await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إصدار $updated فيزا جديدة'), backgroundColor: Colors.cyan));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ✅ دالة إعادة تعيين الفيزا لطالب محدد (Secure Reset)
  Future<void> _handleSingleVisaReset(String studentId, String studentName) async {
    // 1. تحذير
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 10), Text('تغيير كود الفيزا')]),
        content: Text('أنت على وشك تغيير كود الفيزا للطالب: $studentName\nالكود القديم سيتوقف عن العمل فوراً.\n\nهل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. التحقق من كلمة المرور
    bool verified = await _confirmWithPassword(context);
    if (!verified) return;

    setState(() => _isProcessing = true);

    try {
      // توليد كود جديد
      String newCode = _generateRandomVisaCode();

      // تحديث قاعدة البيانات
      await FirebaseFirestore.instance.collection('students').doc(studentId).update({
        'visaCode': newCode,
      });

      // ✅ تسجيل العملية
      await _logAuditAction(
        actionType: 'VISA_RESET',
        studentId: studentId,
        studentName: studentName,
        details: 'New generated code',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الكود بنجاح!'), backgroundColor: Colors.green));
        _searchStudent(_searchController.text); // تحديث العرض
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التغيير: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _searchStudent(String query) async {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await FirebaseFirestore.instance
          .collection('students')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      setState(() { _searchResults = res.docs; _isSearching = false; });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('إصدار وتعديل الفيزا'),
        backgroundColor: Colors.cyan.shade600,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  // زر التوليد الجماعي
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _handleBulkGeneration,
                      icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.auto_fix_high),
                      label: const Text('توليد تلقائي للطلاب الجدد (بدون كود)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'ابحث عن طالب لتغيير كوده...',
                      prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                    ),
                    onChanged: _searchStudent,
                  ),
                ],
              ),
            ),
            if (_isProcessing) const LinearProgressIndicator(),
            const SizedBox(height: 10),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _searchResults.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final data = _searchResults[index].data() as Map<String, dynamic>;
                  final visaCode = data['visaCode'] ?? 'غير متوفر';
                  final name = data['name'] ?? '...';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.cyan.shade100,
                        child: Icon(Icons.qr_code, color: Colors.cyan.shade700),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الكود الحالي: $visaCode', style: const TextStyle(fontFamily: 'monospace')),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        tooltip: 'تغيير الكود (يتطلب كلمة مرور)',
                        onPressed: () => _handleSingleVisaReset(_searchResults[index].id, name),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. المخزن (Store)
// ---------------------------------------------------------------------------

class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');

  Future<String?> _scanBarcode(BuildContext context) async {
    String? scannedCode;
    try {
      scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('امسح الباركود'), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
            body: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final code = barcodes.first.rawValue!;
                  Navigator.pop(context, code);
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error: $e');
    }
    return scannedCode;
  }

  void _showProductDialog({DocumentSnapshot? product}) {
    final nameController = TextEditingController(text: product?['name']);
    final priceController = TextEditingController(text: product?['price']?.toString());
    final stockController = TextEditingController(text: product == null ? '' : '');
    final serialController = TextEditingController(text: product?['serial']);
    final reasonController = TextEditingController();

    int selectedIconIndex = product?['iconIndex'] ?? 0;
    String operationType = 'add';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product == null ? 'منتج جديد' : 'إدارة المخزون', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: marketingIcons.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedIconIndex;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIconIndex = index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(marketingIcons[index], color: isSelected ? Colors.blue : Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'اسم المنتج', prefixIcon: const Icon(Icons.shopping_bag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'السعر', suffixText: 'ريال', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: serialController,
                        decoration: InputDecoration(
                          labelText: 'الباركود',
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.blue),
                            onPressed: () async {
                              String? code = await _scanBarcode(context);
                              if (code != null) serialController.text = code;
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (product == null) ...[
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'الرصيد الافتتاحي', prefixIcon: const Icon(Icons.inventory), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("المتوفر حالياً: ${product['stock']} قطعة", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("توريد (+)", style: TextStyle(fontSize: 12)),
                                value: 'add',
                                groupValue: operationType,
                                activeColor: Colors.green,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setModalState(() => operationType = val!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("تالف/صرف (-)", style: TextStyle(fontSize: 12)),
                                value: 'remove',
                                groupValue: operationType,
                                activeColor: Colors.red,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setModalState(() => operationType = val!),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'الكمية (التغيير)',
                            hintText: 'أدخل العدد هنا',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            labelText: 'ملاحظة / سبب التعديل',
                            hintText: 'مثال: فاتورة رقم 101',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال البيانات')));
                        return;
                      }

                      int stockChange = int.tryParse(stockController.text) ?? 0;

                      final basicData = {
                        'name': nameController.text,
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'serial': serialController.text,
                        'iconIndex': selectedIconIndex,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      try {
                        if (product == null) {
                          basicData['stock'] = stockChange;
                          await _productsRef.add(basicData);
                        } else {
                          final docRef = _productsRef.doc(product.id);
                          final batch = FirebaseFirestore.instance.batch();
                          batch.update(docRef, basicData);
                          if (stockChange > 0) {
                            int finalChange = operationType == 'add' ? stockChange : -stockChange;
                            batch.update(docRef, {'stock': FieldValue.increment(finalChange)});
                            final logRef = docRef.collection('stock_logs').doc();
                            batch.set(logRef, {
                              'amount': stockChange,
                              'type': operationType,
                              'reason': reasonController.text.isEmpty ? 'تحديث يدوي' : reasonController.text,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                          }
                          await batch.commit();
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: Text(product == null ? 'إنشاء المنتج' : 'حفظ التعديلات', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('إدارة المخزن والمنتجات'),
        backgroundColor: Colors.lightBlue.shade400,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: Colors.lightBlue.shade600,
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            // قائمة المنتجات
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productsRef.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('حدث خطأ في تحميل البيانات'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                        Text('المخزن فارغ', style: TextStyle(color: Colors.grey)),
                      ],
                    ));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final int stock = data['stock'] ?? 0;
                      final int iconIdx = data['iconIndex'] ?? 0;

                      final IconData prodIcon = (iconIdx >= 0 && iconIdx < marketingIcons.length)
                          ? marketingIcons[iconIdx]
                          : Icons.shopping_bag;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: stock < 5 ? Colors.red.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(prodIcon, color: stock < 5 ? Colors.red : Colors.blue.shade600, size: 28),
                          ),
                          title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('السعر: ${data['price']} ريال', style: TextStyle(color: Colors.grey.shade700)),
                              Text(stock < 5 ? '⚠️ الكمية منخفضة: $stock' : 'المتبقي: $stock',
                                  style: TextStyle(color: stock < 5 ? Colors.red : Colors.green, fontSize: 12)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showProductDialog(product: doc),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. نقطة البيع (POS)
// ---------------------------------------------------------------------------

class CanteenPOSPage extends StatefulWidget {
  const CanteenPOSPage({super.key});

  @override
  State<CanteenPOSPage> createState() => _CanteenPOSPageState();
}

class _CanteenPOSPageState extends State<CanteenPOSPage> {
  final TextEditingController _visaController = TextEditingController();
  Map<String, dynamic>? _studentData;
  String? _studentId;
  List<Map<String, dynamic>> _cart = [];
  double _totalAmount = 0.0;
  bool _isLoadingStudent = false;

  Future<void> _scanVisa(BuildContext context) async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('مسح فيزا الطالب'), backgroundColor: Colors.teal),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final code = barcodes.first.rawValue!;
                Navigator.pop(context, code);
              }
            },
          ),
        ),
      ),
    );

    if (scanned != null) {
      _visaController.text = scanned;
      _findStudentByVisa(scanned);
    }
  }

  Future<void> _findStudentByVisa(String code) async {
    setState(() { _isLoadingStudent = true; _studentData = null; _studentId = null; });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('visaCode', isEqualTo: code.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _studentData = snapshot.docs.first.data();
          _studentId = snapshot.docs.first.id;
        });
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على طالب')));
      }
    } finally {
      setState(() => _isLoadingStudent = false);
    }
  }

  void _addToCart(Map<String, dynamic> product, String docId) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == docId);
      if (index >= 0) {
        if (_cart[index]['qty'] < product['stock']) {
          _cart[index]['qty']++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نفذت الكمية')));
        }
      } else {
        _cart.add({
          'id': docId,
          'name': product['name'],
          'price': product['price'],
          'qty': 1,
          'maxStock': product['stock']
        });
      }
      _calculateTotal();
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (_cart[index]['qty'] > 1) {
        _cart[index]['qty']--;
      } else {
        _cart.removeAt(index);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _cart) {
      total += item['price'] * item['qty'];
    }
    setState(() => _totalAmount = total);
  }

  Future<void> _processPayment() async {
    if (_studentId == null || _cart.isEmpty) return;
    double currentBalance = (_studentData!['walletBalance'] ?? 0).toDouble();
    if (currentBalance < _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ!'), backgroundColor: Colors.red));
      return;
    }
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(FirebaseFirestore.instance.collection('students').doc(_studentId), {
          'walletBalance': currentBalance - _totalAmount
        });
        for (var item in _cart) {
          DocumentReference prodRef = FirebaseFirestore.instance.collection('products').doc(item['id']);
          transaction.update(prodRef, {'stock': FieldValue.increment(-item['qty'])});

          DocumentReference logRef = prodRef.collection('stock_logs').doc();
          transaction.set(logRef, {
            'amount': item['qty'],
            'type': 'remove',
            'reason': 'مبيعات POS',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
        DocumentReference invoiceRef = FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(invoiceRef, {
          'studentId': _studentId,
          'studentName': _studentData!['name'],
          'items': _cart,
          'total': _totalAmount,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم البيع بنجاح'), backgroundColor: Colors.teal));
        setState(() { _cart.clear(); _totalAmount = 0; _visaController.clear(); _studentData = null; _studentId = null; });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: const Text('نقطة البيع'),
        backgroundColor: Colors.teal.shade400,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 30),
            tooltip: 'وضع عصا الليزر',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LaserPosPage()));
            },
          )
        ],
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _visaController, decoration: const InputDecoration(labelText: 'كود الفيزا', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)), onSubmitted: (val) => _findStudentByVisa(val))),
                      const SizedBox(width: 10),
                      IconButton(icon: const Icon(Icons.camera_alt, size: 30, color: Colors.teal), onPressed: () => _scanVisa(context))
                    ],
                  ),
                  if (_studentData != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_studentData!['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('الرصيد: ${(_studentData!['walletBalance'] ?? 0).toStringAsFixed(2)} ريال', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').where('stock', isGreaterThan: 0).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        return GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.75, crossAxisSpacing: 8, mainAxisSpacing: 8),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final prod = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                            final int iconIdx = prod['iconIndex'] ?? 0;
                            final IconData prodIcon = (iconIdx >= 0 && iconIdx < marketingIcons.length) ? marketingIcons[iconIdx] : Icons.fastfood;

                            return InkWell(
                              onTap: () => _addToCart(prod, snapshot.data!.docs[index].id),
                              child: Card(
                                elevation: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(prodIcon, size: 30, color: Colors.orange.shade300),
                                    const SizedBox(height: 4),
                                    Text(prod['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('${prod['price']} ريال', style: const TextStyle(fontSize: 11, color: Colors.teal)),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(width: 1, color: Colors.grey.shade300),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade100, child: const Center(child: Text('السلة', style: TextStyle(fontWeight: FontWeight.bold)))),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (ctx, i) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(_cart[i]['name'], style: const TextStyle(fontSize: 12)),
                              subtitle: Text('${_cart[i]['price']} ريال', style: const TextStyle(fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                                    onPressed: () => _decreaseQty(i),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('${_cart[i]['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                                    onPressed: () {
                                      if (_cart[i]['qty'] < _cart[i]['maxStock']) {
                                        setState(() {
                                          _cart[i]['qty']++;
                                          _calculateTotal();
                                        });
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: Column(
                            children: [
                              Text('المجموع: ${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (_studentId != null && _cart.isNotEmpty) ? _processPayment : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade400, foregroundColor: Colors.white), child: const Text('دفع'))),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. صفحة عصا الليزر (Kiosk / Laser Mode)
// ---------------------------------------------------------------------------

class LaserPosPage extends StatefulWidget {
  const LaserPosPage({super.key});

  @override
  State<LaserPosPage> createState() => _LaserPosPageState();
}

class _LaserPosPageState extends State<LaserPosPage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _inputController = TextEditingController();

  String _statusMessage = 'امسح فيزا الطالب للبدء...';
  Color _statusColor = Colors.grey;

  Map<String, dynamic>? _currentStudent;
  String? _currentStudentId;
  List<Map<String, dynamic>> _currentCart = [];
  double _currentTotal = 0.0;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _handleInput(String value) {
    if (value.isEmpty) return;
    _inputController.clear();
    FocusScope.of(context).requestFocus(_focusNode);
    _processBarcode(value.trim());
  }

  Future<void> _processBarcode(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (_currentStudent == null) {
        if (code.length == 16) {
          final snapshot = await FirebaseFirestore.instance.collection('students').where('visaCode', isEqualTo: code).limit(1).get();
          if (snapshot.docs.isNotEmpty) {
            setState(() {
              _currentStudent = snapshot.docs.first.data();
              _currentStudentId = snapshot.docs.first.id;
              _statusMessage = 'أهلاً ${_currentStudent!['name']} - امسح المنتجات الآن';
              _statusColor = Colors.green;
            });
          } else {
            setState(() { _statusMessage = 'فيزا غير مسجلة!'; _statusColor = Colors.red; });
          }
        } else {
          setState(() { _statusMessage = 'الرجاء مسح فيزا الطالب أولاً'; _statusColor = Colors.orange; });
        }
      } else {
        final prodSnapshot = await FirebaseFirestore.instance.collection('products').where('serial', isEqualTo: code).limit(1).get();
        if (prodSnapshot.docs.isNotEmpty) {
          final prodData = prodSnapshot.docs.first.data();
          final prodId = prodSnapshot.docs.first.id;

          if ((prodData['stock'] ?? 0) > 0) {
            _addItemToCart(prodData, prodId);
            setState(() { _statusMessage = 'تمت إضافة ${prodData['name']}'; _statusColor = Colors.blue; });
          } else {
            setState(() { _statusMessage = 'نفذت الكمية!'; _statusColor = Colors.red; });
          }
        } else {
          if (code.length == 16) {
            _resetSession();
            await _processBarcode(code);
          } else {
            setState(() { _statusMessage = 'منتج غير معروف'; _statusColor = Colors.red; });
          }
        }
      }
    } catch (e) {
      setState(() { _statusMessage = 'خطأ: $e'; _statusColor = Colors.red; });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _addItemToCart(Map<String, dynamic> prod, String id) {
    setState(() {
      final index = _currentCart.indexWhere((element) => element['id'] == id);
      if (index >= 0) {
        _currentCart[index]['qty']++;
      } else {
        _currentCart.add({
          'id': id,
          'name': prod['name'],
          'price': (prod['price'] ?? 0).toDouble(),
          'qty': 1,
        });
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double t = 0;
    for (var i in _currentCart) {
      t += i['price'] * i['qty'];
    }
    setState(() => _currentTotal = t);
  }

  void _resetSession() {
    setState(() {
      _currentStudent = null;
      _currentStudentId = null;
      _currentCart.clear();
      _currentTotal = 0;
      _statusMessage = 'امسح فيزا الطالب للبدء...';
      _statusColor = Colors.grey;
    });
  }

  Future<void> _confirmPayment() async {
    if (_currentStudentId == null || _currentCart.isEmpty) return;

    double balance = (_currentStudent!['walletBalance'] ?? 0).toDouble();
    if (balance < _currentTotal) {
      setState(() { _statusMessage = 'الرصيد غير كافٍ!'; _statusColor = Colors.red; });
      return;
    }

    setState(() { _statusMessage = 'جاري الدفع...'; _isProcessing = true; });

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(FirebaseFirestore.instance.collection('students').doc(_currentStudentId), {
          'walletBalance': balance - _currentTotal
        });

        for (var item in _currentCart) {
          DocumentReference prodRef = FirebaseFirestore.instance.collection('products').doc(item['id']);
          transaction.update(prodRef, {'stock': FieldValue.increment(-item['qty'])});

          DocumentReference logRef = prodRef.collection('stock_logs').doc();
          transaction.set(logRef, {
            'amount': item['qty'],
            'type': 'remove',
            'reason': 'ليزر POS',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        DocumentReference invRef = FirebaseFirestore.instance.collection('transactions').doc();
        transaction.set(invRef, {
          'studentId': _currentStudentId,
          'studentName': _currentStudent!['name'],
          'items': _currentCart,
          'total': _currentTotal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      setState(() {
        _statusMessage = 'تم الدفع بنجاح ✅';
        _statusColor = Colors.green;
      });

      await Future.delayed(const Duration(seconds: 2));
      _resetSession();

    } catch (e) {
      setState(() { _statusMessage = 'فشل الدفع: $e'; _statusColor = Colors.red; });
    } finally {
      setState(() => _isProcessing = false);
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نظام الليزر (Kiosk Mode)'), backgroundColor: Colors.black87),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(_focusNode),
        child: Column(
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  autofocus: true,
                  onSubmitted: _handleInput,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: _statusColor,
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentStudent != null) ...[
                            const Icon(Icons.account_circle, size: 100, color: Colors.blueGrey),
                            const SizedBox(height: 10),
                            Text(_currentStudent!['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text('الرصيد: ${(_currentStudent!['walletBalance']??0).toStringAsFixed(2)} ريال', style: const TextStyle(fontSize: 18, color: Colors.green)),
                            const Divider(thickness: 2),
                            const Text('المجموع المطلوب', style: TextStyle(color: Colors.grey)),
                            Text('${_currentTotal.toStringAsFixed(2)} ريال', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: _currentCart.isNotEmpty ? _confirmPayment : null,
                              icon: const Icon(Icons.check_circle, size: 30),
                              label: const Text('تأكيد الدفع', style: TextStyle(fontSize: 20)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              ),
                            )
                          ] else ...[
                            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey),
                            const Text('انتظار العميل...', style: TextStyle(fontSize: 20, color: Colors.grey))
                          ]
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(padding: const EdgeInsets.all(10), width: double.infinity, color: Colors.blueGrey, child: const Text('المنتجات الممسوحة', style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentCart.length,
                            itemBuilder: (context, index) {
                              final item = _currentCart[index];
                              return ListTile(
                                leading: CircleAvatar(child: Text('${item['qty']}')),
                                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Text('${(item['price']*item['qty']).toStringAsFixed(2)} ريال'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. التقارير (Analytics)
// ---------------------------------------------------------------------------

class VisaAnalyticsPage extends StatelessWidget {
  const VisaAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('التقارير المالية'), backgroundColor: Colors.indigo.shade400, elevation: 0),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (context, snapshot) {
                  double totalSales = 0;
                  int count = 0;
                  if (snapshot.hasData) {
                    count = snapshot.data!.docs.length;
                    for (var doc in snapshot.data!.docs) {
                      totalSales += (doc.data() as Map<String, dynamic>)['total'] ?? 0;
                    }
                  }
                  return Row(
                    children: [
                      Expanded(child: _buildStatBox('المبيعات (الخزنة)', '${totalSales.toStringAsFixed(2)} ريال', Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatBox('عدد العمليات', '$count', Colors.teal)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerRight, child: Text('آخر العمليات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true).limit(20).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد بيانات'));

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        final date = (data['timestamp'] as Timestamp?)?.toDate();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                            title: Text(data['studentName'] ?? 'طالب'),
                            subtitle: Text(date != null ? DateFormat('MM/dd hh:mm a').format(date) : ''),
                            trailing: Text('${data['total']} ريال', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade100),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. صفحة تقويم المبيعات (Sales Calendar)
// ---------------------------------------------------------------------------

class SalesCalendarPage extends StatefulWidget {
  const SalesCalendarPage({super.key});

  @override
  State<SalesCalendarPage> createState() => _SalesCalendarPageState();
}

class _SalesCalendarPageState extends State<SalesCalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('تقويم المبيعات'),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد بيانات'));
                  }

                  final dayDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['timestamp'] as Timestamp?;
                    if (ts == null) return false;
                    final date = ts.toDate();
                    return date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                  }).toList();

                  if (dayDocs.isEmpty) {
                    return const Center(child: Text('لا توجد مبيعات في هذا اليوم'));
                  }

                  double dayTotal = 0;
                  for (var doc in dayDocs) {
                    dayTotal += (doc.data() as Map<String, dynamic>)['total'] ?? 0;
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي اليوم:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${dayTotal.toStringAsFixed(2)} ريال', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: dayDocs.length,
                          itemBuilder: (context, index) {
                            final data = dayDocs[index].data() as Map<String, dynamic>;
                            final date = (data['timestamp'] as Timestamp).toDate();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.receipt, color: Colors.orange),
                                title: Text(data['studentName'] ?? 'طالب'),
                                subtitle: Text(DateFormat('hh:mm a').format(date)),
                                trailing: Text('${data['total']} ريال', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}