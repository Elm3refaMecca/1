import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentViewPage extends StatelessWidget {
  const StudentViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار مدرسيات المدرسية'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب البيانات من collection اختبار مدرسيات وترتيبها بالأحدث أولاً
        stream: FirebaseFirestore.instance.collection('assignments').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد واجبات حالياً.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في تحميل البيانات.'));
          }

          // عرض البيانات في قائمة
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var assignment = snapshot.data!.docs[index];
              String title = assignment['title'];
              String description = assignment['description'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(description),
                ),
              );
            },
          );
        },
      ),
    );
  }
}