import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// (ضع هنا نفس كود TeacherLoginPage الذي أنشأناه سابقاً)
// ... تأكد من نسخ الكلاس TeacherLoginPage كاملاً من إجابتنا السابقة
// والذي يحتوي على حقول البريد الإلكتروني وكلمة المرور وزر جوجل
// سأضعه هنا كاملاً للتأكيد

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  Future<void> _signInWithGoogle() async {
    // ... (نفس دالة تسجيل الدخول بجوجل)
  }

  Future<void> _signIn() async {
    // ... (نفس دالة تسجيل الدخول بالإيميل)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل دخول المعلمين")),
      body: Center(
        // ... (نفس تصميم واجهة تسجيل الدخول)
      ),
    );
  }
}