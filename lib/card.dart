import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // ✅ مكتبة الباركود

// ---------------------------------------------------------------------------
// 1. اللوحة الرئيسية (Dashboard)
// ---------------------------------------------------------------------------

class VisaManagementPage extends StatelessWidget {
  const VisaManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = Colors.lightBlue.shade300;
    final Color backgroundColor = const Color(0xFFE1F5FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'نظام المقصف والفيزا',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildGridCard(
                context,
                'إصدار الفيزا',
                Icons.qr_code_scanner_rounded,
                Colors.cyan,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaGenerationView())),
              ),
              _buildGridCard(
                context,
                'المخزن',
                Icons.store_mall_directory_rounded,
                Colors.lightBlue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementPage())),
              ),
              _buildGridCard(
                context,
                'نقطة البيع',
                Icons.point_of_sale_rounded,
                Colors.teal,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenPOSPage())),
              ),
              _buildGridCard(
                context,
                'التقارير',
                Icons.analytics_rounded,
                Colors.blueGrey,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaAnalyticsPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color.shade600),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
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
      backgroundColor: const Color(0xFFE0F7FA),
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
// 3. المخزن (Store) - إدارة المنتجات بالكاميرا و Firebase
// ---------------------------------------------------------------------------

class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  // ✅ الاتصال بـ Firebase Firestore
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');

  // ✅ دالة فتح الكاميرا لمسح الباركود (تمت إزالة الحظر عن الويب)
  Future<String?> _scanBarcode(BuildContext context) async {
    String? scannedCode;
    try {
      scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('امسح الباركود'),
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: MobileScanner(
              // تم استخدام الإعدادات الافتراضية لضمان التوافق
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final code = barcodes.first.rawValue!;
                  debugPrint('Barcode found! $code');
                  Navigator.pop(context, code); // إرجاع الكود وإغلاق الكاميرا
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء فتح الكاميرا: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return scannedCode;
  }

  // ✅ نافذة إضافة/تعديل المنتج
  void _showProductDialog({DocumentSnapshot? product}) {
    final nameController = TextEditingController(text: product?['name']);
    final priceController = TextEditingController(text: product?['price']?.toString());
    final stockController = TextEditingController(text: product?['stock']?.toString());
    final serialController = TextEditingController(text: product?['serial']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product == null ? 'إضافة منتج جديد' : 'تعديل المخزون', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'اسم المنتج',
                prefixIcon: const Icon(Icons.shopping_bag),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'السعر',
                      suffixText: 'ريال',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'العدد (الكمية)',
                      hintText: 'الكمية المتوفرة',
                      prefixIcon: const Icon(Icons.exposure),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: serialController,
                    decoration: InputDecoration(
                      labelText: 'الباركود (السيريال)',
                      prefixIcon: const Icon(Icons.qr_code),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ✅ زر الكاميرا لمسح الباركود
                Tooltip(
                  message: 'اضغط للمسح بالكاميرا',
                  child: Container(
                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: () async {
                        String? scannedCode = await _scanBarcode(context);
                        if (scannedCode != null) {
                          serialController.text = scannedCode;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح الباركود بنجاح!'), backgroundColor: Colors.green));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty || priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الاسم والسعر')));
                    return;
                  }

                  // تجهيز البيانات للرفع
                  final data = {
                    'name': nameController.text,
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'stock': int.tryParse(stockController.text) ?? 0,
                    'serial': serialController.text, // الباركود
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (product == null) {
                      // إضافة منتج جديد
                      await _productsRef.add(data);
                    } else {
                      // تعديل منتج موجود
                      await _productsRef.doc(product.id).update(data);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('حفظ المنتج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
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
            // إحصائيات سريعة
            StreamBuilder<QuerySnapshot>(
              stream: _productsRef.snapshots(),
              builder: (context, snapshot) {
                double totalValue = 0;
                int totalItems = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalValue += (data['price'] ?? 0) * (data['stock'] ?? 0);
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
                          const Text('إجمالي قطع المخزن', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('$totalItems قطعة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('القيمة الإجمالية', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${totalValue.toStringAsFixed(2)} ريال', style: TextStyle(color: Colors.lightBlue.shade800, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            // قائمة المنتجات من Firestore
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: stock < 5 ? Colors.red.shade50 : Colors.lightBlue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.inventory_2, color: stock < 5 ? Colors.red : Colors.lightBlue.shade400),
                          ),
                          title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('السعر: ${data['price']} ريال', style: TextStyle(color: Colors.grey.shade700)),
                              Text(stock < 5 ? '⚠️ الكمية منخفضة: $stock' : 'المتبقي: $stock',
                                  style: TextStyle(color: stock < 5 ? Colors.red : Colors.green, fontSize: 12)),
                              if (data['serial'] != null && data['serial'].toString().isNotEmpty)
                                Text('كود: ${data['serial']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'edit') _showProductDialog(product: doc);
                              if (value == 'delete') {
                                // تأكيد الحذف
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
                              const PopupMenuItem(value: 'edit', child: Text('تعديل / جرد')),
                              const PopupMenuItem(value: 'delete', child: Text('حذف المنتج', style: TextStyle(color: Colors.red))),
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
                            return InkWell(
                              onTap: () => _addToCart(prod, snapshot.data!.docs[index].id),
                              child: Card(
                                elevation: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fastfood_rounded, size: 30, color: Colors.orange.shade300),
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
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(title: const Text('التقارير المالية'), backgroundColor: Colors.blueGrey.shade400, elevation: 0),
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
                      Expanded(child: _buildStatBox('المبيعات', '${totalSales.toStringAsFixed(2)} ريال', Colors.blueGrey)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatBox('العمليات', '$count', Colors.teal)),
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