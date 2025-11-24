import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // ✅ مكتبة الباركود

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
// 1. اللوحة الرئيسية (Dashboard)
// ---------------------------------------------------------------------------

class VisaManagementPage extends StatelessWidget {
  const VisaManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = Colors.lightBlue.shade300;
    final Color backgroundColor = const Color(0xFFFAFAFA); // خلفية نظيفة

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
        child: SingleChildScrollView( // لجعل الشاشة قابلة للتمرير إذا زادت العناصر
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

              // ✅✅✅ التوزيع الجديد (بدون شبكة Grid) ✅✅✅
              // استخدام Wrap لرص العناصر بجانب بعضها بمسافات محددة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Wrap(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.start, // يبدأ من اليمين (بسبب Directionality RTL)
                  spacing: 40.0, // ✅ المسافة الأفقية بين كل أيقونة والأخرى (بحجم أيقونة تقريباً)
                  runSpacing: 40.0, // ✅ المسافة الرأسية بين الأسطر
                  children: [
                    _buildFreeIcon(
                      context,
                      'الفيزا',
                      Icons.qr_code_2_rounded,
                      Colors.cyan,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaGenerationView())),
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

  // ✅ تصميم العنصر الحر (Free Icon)
  Widget _buildFreeIcon(BuildContext context, String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min, // يأخذ أقل مساحة ممكنة
        children: [
          // الدائرة الملونة
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color.shade50, // خلفية فاتحة جداً
              shape: BoxShape.circle,
              border: Border.all(color: color.shade100, width: 1.5), // حدود ناعمة
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4), // ظل خفيف للأسفل
                )
              ],
            ),
            child: Icon(icon, size: 30, color: color.shade700),
          ),
          const SizedBox(height: 10), // مسافة بين الأيقونة والنص
          // النص
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
// 2. صفحة إصدار الفيزا (Visa Generation)
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
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('توليد جماعي'),
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

  Future<void> _addMoneyToWallet(String studentId, String name, double currentBalance) async {
    final amountController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('شحن رصيد: $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد الحالي: ${currentBalance.toStringAsFixed(2)} ريال'),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'ريال', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade600, foregroundColor: Colors.white),
            onPressed: () async {
              final double? amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                  'walletBalance': FieldValue.increment(amount)
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الشحن بنجاح'), backgroundColor: Colors.cyan));
                  _searchStudent(_searchController.text);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _handleBulkGeneration,
                      icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.auto_fix_high),
                      label: const Text('توليد تلقائي للطلاب الجدد'),
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
                      labelText: 'ابحث عن طالب...',
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
            const SizedBox(height: 10),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _searchResults.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final data = _searchResults[index].data() as Map<String, dynamic>;
                  final balance = (data['walletBalance'] ?? 0).toDouble();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.cyan.shade100, child: Icon(Icons.person, color: Colors.cyan.shade700)),
                      title: Text(data['name'] ?? '...'),
                      subtitle: Text('💳 ${data['visaCode'] ?? 'بدون'} | 💰 $balance ريال'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _addMoneyToWallet(_searchResults[index].id, data['name'] ?? '', balance),
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
// 3. المخزن (Store) - إدارة المنتجات + نظام السجلات
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

  // ✅ نافذة عرض سجل الحركات (Logs)
  void _showProductLogs(String productId, String productName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("سجل حركة: $productName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productsRef.doc(productId).collection('stock_logs').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد حركات مسجلة"));

                  return ListView.builder(
                    controller: controller,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final log = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      final bool isAdd = log['type'] == 'add';
                      final date = (log['timestamp'] as Timestamp?)?.toDate();
                      final formattedDate = date != null ? DateFormat('yyyy/MM/dd HH:mm').format(date) : '-';

                      return ListTile(
                        leading: Icon(
                          isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
                          color: isAdd ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          isAdd ? "توريد (إضافة)" : "تالف/صرف (خصم)",
                          style: TextStyle(color: isAdd ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("${log['reason'] ?? 'بدون سبب'} | $formattedDate"),
                        trailing: Text(
                          "${isAdd ? '+' : '-'}${log['amount']}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isAdd ? Colors.green : Colors.red),
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

  // ✅ نافذة إضافة/تعديل المنتج (الاحترافية)
  void _showProductDialog({DocumentSnapshot? product}) {
    final nameController = TextEditingController(text: product?['name']);
    final priceController = TextEditingController(text: product?['price']?.toString());
    // إذا منتج جديد نعرض حقل الكمية، إذا موجود نعرض حقل التعديل
    final stockController = TextEditingController(text: product == null ? '' : '');
    final serialController = TextEditingController(text: product?['serial']);
    final reasonController = TextEditingController(); // سبب التعديل

    int selectedIconIndex = product?['iconIndex'] ?? 0;
    String operationType = 'add'; // add or remove

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

                // 1. اختيار الأيقونة
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

                // 2. البيانات الأساسية
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

                // 3. قسم المخزون (المهم جداً)
                if (product == null) ...[
                  // منتج جديد: إدخال مباشر
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'الرصيد الافتتاحي', prefixIcon: const Icon(Icons.inventory), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ] else ...[
                  // منتج موجود: عمليات إضافة/خصم
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
                          // إضافة منتج جديد
                          basicData['stock'] = stockChange; // Initial stock
                          await _productsRef.add(basicData);
                        } else {
                          // تعديل منتج موجود
                          final docRef = _productsRef.doc(product.id);
                          final batch = FirebaseFirestore.instance.batch();

                          // تحديث البيانات الأساسية
                          batch.update(docRef, basicData);

                          // منطق المخزون المتقدم
                          if (stockChange > 0) {
                            int finalChange = operationType == 'add' ? stockChange : -stockChange;

                            // تحديث العدد باستخدام increment (آمن من التداخل)
                            batch.update(docRef, {'stock': FieldValue.increment(finalChange)});

                            // إضافة سجل في الـ Logs
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
            // إحصائيات المخزون (قيمة البضاعة فقط)
            StreamBuilder<QuerySnapshot>(
              stream: _productsRef.snapshots(),
              builder: (context, snapshot) {
                double totalStockValue = 0;
                int totalItems = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalStockValue += (data['price'] ?? 0) * (data['stock'] ?? 0);
                    totalItems += (data['stock'] as num? ?? 0).toInt();
                  }
                }
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.lightBlue.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('عدد الأصناف', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('$totalItems قطعة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('قيمة البضاعة بالمخزن', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${totalStockValue.toStringAsFixed(2)} ريال', style: TextStyle(color: Colors.blue.shade800, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
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

                      // التأكد من أن مؤشر الأيقونة صالح
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history, color: Colors.grey),
                                tooltip: 'سجل الحركة',
                                onPressed: () => _showProductLogs(doc.id, data['name']),
                              ),
                              PopupMenuButton(
                                onSelected: (value) {
                                  if (value == 'edit') _showProductDialog(product: doc);
                                  if (value == 'delete') {
                                    showDialog(context: context, builder: (ctx) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: Text('هل أنت متأكد من حذف ${data['name']}؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                        ElevatedButton(onPressed: () {
                                          doc.reference.delete();
                                          Navigator.pop(ctx);
                                        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
                                      ],
                                    ));
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('تعديل / إدارة')),
                                  const PopupMenuItem(value: 'delete', child: Text('حذف المنتج', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
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

          // تسجيل حركة الصرف في المخزون
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
      appBar: AppBar(title: const Text('نقطة البيع'), backgroundColor: Colors.teal.shade400, elevation: 0),
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
                      IconButton(icon: const Icon(Icons.qr_code_scanner, size: 30, color: Colors.teal), onPressed: () => _scanVisa(context))
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
                              subtitle: Text('${_cart[i]['qty']}x', style: const TextStyle(fontSize: 11)),
                              trailing: IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: () { setState(() { _cart.removeAt(i); _calculateTotal(); }); }),
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
// 5. التقارير (Analytics)
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
// 6. صفحة تقويم المبيعات (Sales Calendar)
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