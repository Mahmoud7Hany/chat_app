// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, file_names

import 'package:chat/pages/LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // حقل اسم المستخدم
  bool _isLoading = false; // متغير لتحديد ما إذا كانت العملية جارية

  // دالة لتسجيل المستخدم في Firebase و تخزين بياناته في Firestore
  Future<void> _signUp() async {
    // التحقق من أن جميع الحقول مملوءة
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      // إذا كان أحد الحقول فارغًا، عرض رسالة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("الرجاء ملء جميع الحقول")));
      return;
    }

    setState(() {
      _isLoading = true; // تفعيل مؤشر التحميل
    });

    try {
      // إنشاء مستخدم جديد في Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // تخزين بيانات المستخدم (اسم المستخدم والبريد الإلكتروني وكلمة المرور) في Firestore مع وقت الإرسال
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': _usernameController.text, // تخزين اسم المستخدم
        'email': _emailController.text, // تخزين البريد الإلكتروني
        'password': _passwordController.text, // تخزين كلمة المرور
        'createdAt': FieldValue.serverTimestamp(), // تخزين وقت التسجيل
        'isVerified': false,
        'isAdmin': false, // الإعداد الافتراضي للمستخدم العادي
        'isBanned': false,
        'banReason': null,
        'banUntil': null,
      });

      // التوجيه إلى صفحة الشات بعد التسجيل واستبدال الصفحة الحالية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم انشاء حساب بنجاح')));
    } catch (e) {
      String errorMessage = 'فشل التسجيل';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'كلمة المرور ضعيفة، يرجى اختيار كلمة مرور أقوى.';
            break;
          case 'email-already-in-use':
            errorMessage = 'البريد الإلكتروني هذا مُستخدم بالفعل.';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صالح.';
            break;
          default:
            errorMessage = 'حدث خطأ غير متوقع: ${e.message}';
            break;
        }
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() {
        _isLoading = false; // إخفاء مؤشر التحميل بعد اكتمال العملية
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // الرجوع إلى الصفحة السابقة
          },
        ),
        title: const Text('قم بالتسجيل'),
        automaticallyImplyLeading: false, // إخفاء زر الرجوع
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // يضمن أن العمود لا يأخذ أكثر من الحجم المطلوب
              children: [
                // حقل إدخال اسم المستخدم
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                        16), // يسمح بـ 16 حرفًا فقط
                  ],
                ),

                const SizedBox(height: 10),

                // حقل إدخال البريد الإلكتروني
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'بريد إلكتروني',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // حقل إدخال كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(height: 20),

                // زر التسجيل
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator() // إظهار دائرة التحميل إذا كانت العملية جارية
                      : const Text("تسجيل"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
