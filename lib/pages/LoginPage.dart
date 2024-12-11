// ignore_for_file: library_private_types_in_public_api, file_names, unused_element, use_build_context_synchronously

import 'package:chat/pages/ChatPage.dart';
import 'package:chat/pages/SignUpPage.dart';
import 'package:chat/pages/Support/SupportPage%20.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // متغير لتحديد ما إذا كانت العملية جارية

  // دالة لتخزين حالة تسجيل الدخول
  Future<void> _setLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true); // تخزين حالة تسجيل الدخول
  }

  // دالة لتخزين حالة تسجيل الخروج
  Future<void> _clearLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn'); // مسح حالة تسجيل الدخول
  }

  // دالة لتسجيل الدخول
  Future<void> _login() async {
    // التحقق من أن الحقول غير فارغة
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء ملء جميع الحقول")),
      );
      return; // عدم المتابعة في حالة الحقول الفارغة
    }

    setState(() {
      _isLoading = true; // تفعيل دائرة التحميل
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _setLoginStatus(); // تخزين حالة تسجيل الدخول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const ChatPage()), // الانتقال إلى صفحة الشات
      );
    } catch (e) {
      String errorMessage = 'فشل تسجيل الدخول';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
            break;
          case 'wrong-password':
            errorMessage = 'كلمة المرور غير صحيحة.';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صالح.';
            break;
          default:
            errorMessage = 'حدث خطأ غير متوقع: ${e.message}';
            break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false; // إخفاء دائرة التحميل بعد اكتمال العملية
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // عدم إظهار زر الرجوع
        title: const Text('تسجيل الدخول'),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'الدعم',
            onPressed: () {
              // الانتقال إلى صفحة الدعم
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        // توسيط العناصر داخل الصفحة
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            // للتأكد من أن المحتوى يمكن التمرير
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // توسيط العناصر عمودياً
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // حقل إدخال البريد الإلكتروني
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'بريد إلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // حقل إدخال كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // زر تسجيل الدخول
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ), // تعطيل الزر أثناء التحميل
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white) // عرض دائرة التحميل
                      : const Text('تسجيل الدخول'),
                ),
                const SizedBox(height: 20),

                // رابط التسجيل الجديد للمستخدمين الجدد
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        'ليس لديك حساب؟ قم بالتسجيل',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
