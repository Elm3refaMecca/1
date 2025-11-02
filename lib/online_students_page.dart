// online_students_page.dart (مُعَدَّل بالكامل لحل مشكلة "لا يوجد نشاط")

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class OnlineStudentsPage extends StatelessWidget {
  const OnlineStudentsPage({super.key});

  // --- دالة لتنسيق التاريخ واليوم والوقت بتفاصيل ---
  String _formatFullTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'لم يسجل دخول بعد';

    // استخدام 'ar' للتأكد من الأسماء العربية للأيام
    // التنسيق: يوم_الأسبوع، ي/ش/س | س:د ص/م
    final formatter = intl.DateFormat('EEEE، yyyy/MM/dd | hh:mm a', 'ar');
    return formatter.format(timestamp.toDate());
  }

  // --- دالة لحساب مدة الجلسة (افتراضي) ---
  // بما أننا لا نحفظ وقت الجلسة الفعلي، سنحسب الفرق بين الوقت الحالي وآخر ظهور
  String _formatSessionTime(Timestamp? timestamp) {
    if (timestamp == null) return 'لا يوجد بيانات';

    final lastSeen = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 90) { // <-- (تم التعديل هنا أيضاً)
      return 'متصل الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  // --- ✅ (تم التعديل) دالة تنسيق إجمالي الوقت المتصل ---
  // (تم تعديل الدالة لتستقبل حالة الاتصال)
  String _formatTotalActiveTime(int? totalSeconds, bool isOnline) {

    // --- ✅✅✅ (الإضافة الجديدة) ---
    // إذا كان الطالب "متصل الآن" ولكن عداده صفر (لأنه دخل للتو)
    if (isOnline && (totalSeconds == null || totalSeconds == 0)) {
      return 'نشط الآن (أقل من دقيقة)';
    }
    // --- ✅✅✅ (نهاية الإضافة) ---

    // (الكود الأصلي الذي يعرض "لا يوجد نشاط" إذا كان صفراً)
    if (totalSeconds == null || totalSeconds <= 0) {
      return 'لا يوجد نشاط مسجل';
    }

    final duration = Duration(seconds: totalSeconds);

    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;

    List<String> parts = [];

    // إضافة الأيام مع مراعاة القواعد العربية
    if (days > 0) {
      if (days == 1) parts.add('يوم');
      else if (days == 2) parts.add('يومين');
      else if (days >= 3 && days <= 10) parts.add('$days أيام');
      else parts.add('$days يوم');
    }

    // إضافة الساعات مع مراعاة القواعد العربية
    if (hours > 0) {
      if (hours == 1) parts.add('ساعة');
      else if (hours == 2) parts.add('ساعتين');
      else if (hours >= 3 && hours <= 10) parts.add('$hours ساعات');
      else parts.add('$hours ساعة');
    }

    // إظهار الدقائق فقط إذا كان إجمالي الوقت أقل من يوم واحد
    if (days == 0 && minutes > 0) {
      if (minutes == 1) parts.add('دقيقة');
      else if (minutes == 2) parts.add('دقيقتين');
      else if (minutes >= 3 && minutes <= 10) parts.add('$minutes دقائق');
      else parts.add('$minutes دقيقة');
    }

    // معالجة الأوقات القصيرة جداً
    if (parts.isEmpty) {
      if (totalSeconds < 60) {
        return 'أقل من دقيقة';
      }
      // هذا الشرط سيلتقط الدقائق إذا كانت الساعات والأيام صفراً
      else if (minutes > 0) {
        if (minutes == 1) return 'دقيقة';
        else if (minutes == 2) return 'دقيقتين';
        else if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
        else return '$minutes دقيقة';
      } else {
        // حالة احتياطية (نادرة جداً)
        return 'لا يوجد نشاط مسجل';
      }
    }

    // عرض أكبر جزئين فقط (مثال: "5 أيام و 3 ساعات")
    return parts.take(2).join(' و ');
  }
  // --- ✅ (نهاية التعديل) ---


  // --- (تم التعديل) دالة لتحديد حالة الاتصال (نافذة 90 ثانية) ---
  bool _isCurrentlyOnline(Timestamp? timestamp) {
    if (timestamp == null) return false;
    final lastSeen = timestamp.toDate();
    final difference = DateTime.now().difference(lastSeen);
    // يعتبر متصلاً إذا كان آخر ظهور خلال آخر 90 ثانية
    // (الطالب يرسل تحديث كل 60 ثانية، هذا يعطي هامش 30 ثانية)
    return difference.inSeconds < 90;
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
        // فرز حسب آخر ظهور تنازلياً (الأحدث أولاً)
            .orderBy('lastSeen', descending: true)
            .limit(200)
            .snapshots(), // <-- هذا هو ما يجعل الصفحة "لحظية"
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

              // --- (تم التعديل) سيتم استدعاء الدالة الجديدة هنا ---
              final isOnline = _isCurrentlyOnline(lastSeenTimestamp);
              final statusText = isOnline ? 'متصل حالياً' : 'غير متصل';
              final statusColor = isOnline ? Colors.green.shade600 : Colors.blueGrey.shade400;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  // إضافة حافة خضراء مميزة للمتصلين حالياً
                  side: isOnline ? BorderSide(color: Colors.green.shade400, width: 2) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- الجزء العلوي: الاسم والحالة ---
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
                          // شريحة الحالة (Chip)
                          Chip(
                            label: Text(statusText, style: TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: statusColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      const Divider(height: 20, thickness: 1),

                      // --- تفاصيل الصف والفصل ---
                      _buildDetailRow(
                        icon: Icons.school,
                        label: 'الفصل الدراسي',
                        value: '$grade / $className',
                        context: context,
                      ),

                      const SizedBox(height: 8),

                      // --- تفاصيل آخر ظهور (التاريخ والوقت) ---
                      _buildDetailRow(
                        icon: Icons.schedule,
                        label: 'آخر ظهور كامل',
                        value: _formatFullTimestamp(lastSeenTimestamp),
                        context: context,
                        isTime: true,
                      ),

                      const SizedBox(height: 8),

                      // --- تفاصيل مدة الجلسة (افتراضي) ---
                      _buildDetailRow(
                        icon: Icons.timer,
                        label: 'آخر نشاط',
                        value: _formatSessionTime(lastSeenTimestamp),
                        context: context,
                        isTime: true,
                        // لون مميز للوقت القريب جداً
                        valueColor: isOnline ? Colors.green.shade700 : Colors.black54,
                      ),

                      // --- (موجود) إضافة صف جديد لعرض إجمالي النشاط ---
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.access_time_filled, // أيقونة جديدة
                        label: 'إجمالي النشاط',
                        // --- ✅✅✅ (التعديل الأهم) ---
                        // تمرير حالة الاتصال إلى الدالة
                        value: _formatTotalActiveTime(totalActiveSeconds, isOnline),
                        // --- ✅✅✅ (نهاية التعديل) ---
                        context: context,
                        isTime: true, // لإعطائه تنسيق الوقت (من اليسار لليمين)
                        valueColor: Colors.deepPurple.shade700, // لون مميز
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

  // دالة مساعدة لبناء صف تفاصيل موضح وجميل
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
              // استخدام خط 'monospace' للوقت لضمان محاذاة الأرقام
              fontFamily: isTime ? 'monospace' : null,
            ),
            textDirection: isTime ? TextDirection.ltr : TextDirection.rtl, // الوقت يفضل عرضه من اليسار لليمين
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}