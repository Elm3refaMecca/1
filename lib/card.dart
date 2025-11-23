import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ ضروري للتحقق من كلمة المرور
import 'package:flutter/material.dart';

class VisaManagementPage extends StatefulWidget {
  const VisaManagementPage({super.key});

  @override
  State<VisaManagementPage> createState() => _VisaManagementPageState();
}

class _VisaManagementPageState extends State<VisaManagementPage> {
  bool _isProcessing = false;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  // دالة توليد كود عشوائي (16 خانة)
  String _generateRandomVisaCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // --- الجزء الأول: التوليد الجماعي ---
  Future<void> _handleBulkGeneration() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.groups, color: Colors.deepPurple), SizedBox(width: 8), Text('إصدار جماعي')]),
        content: const Text(
          'سيتم إنشاء كود فيزا (QR) لكل طالب جديد لا يملك واحداً.\n'
              'الطلاب الذين لديهم كود مسبقاً لن يتأثروا.\n\n'
              'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ابدأ المعالجة')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      final allStudents = studentsSnapshot.docs;
      int updatedCount = 0;
      int skippedCount = 0;

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int batchCounter = 0;

      for (var doc in allStudents) {
        final data = doc.data();
        if (data['visaCode'] == null || data['visaCode'].toString().isEmpty) {
          final String newCode = _generateRandomVisaCode();
          batch.update(doc.reference, {'visaCode': newCode});
          updatedCount++;
          batchCounter++;
        } else {
          skippedCount++;
        }

        if (batchCounter >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCounter = 0;
        }
      }

      if (batchCounter > 0) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت العملية!\nتم إصدار $updatedCount فيزا جديدة.\nتم تخطي $skippedCount طالب.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- الجزء الثاني: البحث والتعديل الفردي ---
  Future<void> _searchStudent(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final nameQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        _searchResults = nameQuery.docs;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  // ✅✅✅ التعديل الجذري هنا: التحقق من كلمة مرور الحساب ✅✅✅
  Future<void> _showChangeCodeDialog(String studentId, String studentName) async {
    final passwordController = TextEditingController(); // تغيير الاسم ليعكس المحتوى
    final formKey = GlobalKey<FormState>();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.red),
                  SizedBox(width: 10),
                  Text('تأكيد أمني مطلوب', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('أنت على وشك تغيير كود الفيزا للطالب: $studentName', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      'الرجاء إدخال كلمة المرور الخاصة بحسابك (الأدمن) للمتابعة.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      keyboardType: TextInputType.visiblePassword, // السماح بالحروف والأرقام
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة مرور الحساب',
                        hintText: 'أدخل كلمة مرور دخولك للتطبيق',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
                        return null;
                      },
                    ),
                    if (isVerifying) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: isVerifying ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isVerifying = true);

                      try {
                        // 1. الحصول على المستخدم الحالي
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || user.email == null) {
                          throw FirebaseAuthException(code: 'no-user', message: 'المستخدم غير مسجل دخول');
                        }

                        // 2. إنشاء اعتماد (Credential) بكلمة المرور المدخلة
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: passwordController.text.trim(),
                        );

                        // 3. محاولة إعادة المصادقة (Re-authenticate)
                        // إذا كانت كلمة المرور خطأ، سيتم رمي استثناء (Error) هنا
                        await user.reauthenticateWithCredential(credential);

                        // 4. إذا وصلنا هنا، فكلمة المرور صحيحة -> تنفيذ التغيير
                        final String newCode = _generateRandomVisaCode();
                        await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                          'visaCode': newCode,
                        });

                        if (mounted) {
                          Navigator.pop(context); // إغلاق الديالوج
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تغيير رمز الفيزا للطالب $studentName بنجاح!'), backgroundColor: Colors.green),
                          );
                          // تحديث القائمة
                          if (_searchController.text.isNotEmpty) {
                            _searchStudent(_searchController.text);
                          }
                        }

                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => isVerifying = false);
                        String errorMessage = 'حدث خطأ ما';
                        if (e.code == 'wrong-password') {
                          errorMessage = 'كلمة المرور غير صحيحة!';
                        } else if (e.code == 'too-many-requests') {
                          errorMessage = 'محاولات كثيرة جداً، يرجى الانتظار قليلاً';
                        } else {
                          errorMessage = 'خطأ: ${e.message}';
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isVerifying = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ غير متوقع: $e'), backgroundColor: Colors.red));
                        }
                      }
                    }
                  },
                  child: const Text('تأكيد وتغيير'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة فيزا الطلاب'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- بطاقة التوليد الجماعي ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 50, color: Colors.deepPurple),
                    const SizedBox(height: 12),
                    const Text(
                      'إصدار فيزا للطلاب الجدد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تقوم هذه الميزة بفحص جميع الطلاب، وإصدار أكواد QR تلقائية فقط لمن ليس لديهم كود مسبق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _handleBulkGeneration,
                        icon: _isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                            : const Icon(Icons.play_arrow),
                        label: Text(_isProcessing ? 'جاري المعالجة...' : 'تشغيل المعالجة التلقائية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 12),

            const Text(
              'تعديل بيانات طالب محدد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // --- حقل البحث ---
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ابحث عن اسم الطالب...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchStudent('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => _searchStudent(val),
            ),

            const SizedBox(height: 16),

            // --- نتائج البحث ---
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Center(child: Text('لم يتم العثور على نتائج.', style: TextStyle(color: Colors.grey)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final doc = _searchResults[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'بدون اسم';
                  final currentCode = data['visaCode'] ?? 'لا يوجد';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الكود الحالي: ${currentCode.toString().length > 8 ? currentCode.toString().substring(0, 8) + '...' : currentCode}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                        onPressed: () => _showChangeCodeDialog(doc.id, name),
                        child: const Text('تغيير الرمز'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}