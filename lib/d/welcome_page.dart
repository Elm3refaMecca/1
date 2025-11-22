// welcome_page.dart (ملف مُصحح)

// تم حذف الاستدعاءات المتعارضة وغير الصحيحة
// import 'package:almarefamecca/d/teacher_login_page.dart';
// import '../student_view.dart';

// تم الإبقاء على الاستدعاءات الصحيحة فقط
import 'package:almarefamecca/d/teacher_login_page.dart';
import 'package:flutter/material.dart';

import '../student_view.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مدارس المعرفة الاهلية بمكة المكرمة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // 💡 ملاحظة: اللون الأبيض قد لا يظهر إذا كانت الخلفية بيضاء
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 40),
              // زر المعلم
              ElevatedButton.icon(
                icon: const Icon(Icons.school),
                label: const Text('أنا معلم'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const TeacherLoginPage(),
                  ));
                },
              ),
              const SizedBox(height: 20),
              // زر الطالب
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('أنا طالب / ولي أمر'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  // هنا يمكن إضافة تسجيل دخول جوجل للطلاب أو الانتقال مباشرة
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const StudentViewPage(),
                  ));
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                child: const Text('أو المتابعة كزائر لعرض الواجبات'),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const StudentViewPage(),
                  ));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}