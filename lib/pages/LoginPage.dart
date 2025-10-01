// ignore_for_file: library_private_types_in_public_api, file_names, unused_element, use_build_context_synchronously, deprecated_member_use

import 'package:chat/pages/SignUpPage.dart';
import 'package:chat/pages/Support/SupportPage.dart';
import 'package:chat/pages/HomePage.dart';
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

  // متغيرات لحالة ورسالة الخطأ لكل حقل
  String? _emailError;
  String? _passwordError;
  bool _emailHasError = false;
  bool _passwordHasError = false;

  bool _isLoading = false; // متغير لتحديد ما إذا كانت العملية جارية
  bool _obscurePassword = true; // متغير للتحكم بإخفاء/إظهار كلمة المرور

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
    setState(() {
      // إعادة تعيين الأخطاء
      _emailError = null;
      _passwordError = null;
      _emailHasError = false;
      _passwordHasError = false;
    });

    bool hasError = false;

    // التحقق من البريد الإلكتروني
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = "الرجاء إدخال البريد الإلكتروني";
        _emailHasError = true;
      });
      hasError = true;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = "صيغة البريد الإلكتروني غير صحيحة";
        _emailHasError = true;
      });
      hasError = true;
    }

    // التحقق من كلمة المرور
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "الرجاء إدخال كلمة المرور";
        _passwordHasError = true;
      });
      hasError = true;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = "كلمة المرور يجب أن تكون 6 أحرف أو أكثر";
        _passwordHasError = true;
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _setLoginStatus();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        // لطباعة كود الخطأ أثناء التطوير
        // ignore: avoid_print
        print('FirebaseAuthException code: ${e.code}');
        switch (e.code) {
          case 'user-not-found':
            setState(() {
              _emailError = 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
              _emailHasError = true;
            });
            break;
          case 'wrong-password':
            setState(() {
              _passwordError = 'كلمة المرور غير صحيحة. الرجاء المحاولة مرة أخرى.';
              _passwordHasError = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'كلمة المرور غير صحيحة. الرجاء التأكد والمحاولة مرة أخرى.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.deepOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'invalid-credential':
            setState(() {
              _passwordError = 'كلمة المرور أو البريد الإلكتروني غير صحيح. الرجاء التأكد والمحاولة مرة أخرى.';
              _passwordHasError = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'كلمة المرور أو البريد الإلكتروني غير صحيح. الرجاء التأكد والمحاولة مرة أخرى.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.deepOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'invalid-email':
            setState(() {
              _emailError = 'البريد الإلكتروني غير صالح. تأكد من كتابته بشكل صحيح.';
              _emailHasError = true;
            });
            break;
          case 'user-disabled':
            setState(() {
              _emailError = 'تم تقييد حسابك، يرجى التواصل مع الدعم.';
              _emailHasError = true;
            });
            break;
          default:
            // لطباعة كود الخطأ غير المتوقع أثناء التطوير
            // ignore: avoid_print
            print('Unexpected FirebaseAuthException: ${e.code}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'حدث خطأ غير متوقع: ${e.message}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
        }
      } else {
        // فحص نص الخطأ إذا كان متعلق بكلمة المرور
        final errorMsg = e.toString();
        if (errorMsg.contains('password') || errorMsg.contains('كلمة المرور')) {
          setState(() {
            _passwordError = 'كلمة المرور غير صحيحة. الرجاء التأكد والمحاولة مرة أخرى.';
            _passwordHasError = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'كلمة المرور غير صحيحة. الرجاء التأكد والمحاولة مرة أخرى.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.deepOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // لطباعة الخطأ غير المتوقع أثناء التطوير
          // ignore: avoid_print
          print('Unexpected error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'حدث خطأ غير متوقع. حاول لاحقاً.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_rounded,
                          size: 80,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'مرحباً بك',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'سجل دخولك للمتابعة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _emailHasError
                                    ? Colors.red
                                    : Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _emailHasError
                                    ? Colors.red
                                    : Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            errorText: _emailError,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _passwordHasError
                                    ? Colors.orange
                                    : Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _passwordHasError
                                    ? Colors.orange
                                    : Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            errorText: _passwordError,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                : const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     const Text(
                        //       'ليس لديك حساب؟',
                        //       style: TextStyle(color: Colors.grey),
                        //     ),
                        //     TextButton(
                        //       onPressed: () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) => const SignUpPage(),
                        //           ),
                        //         );
                        //       },
                        //       child: Text(
                        //         'سجل الآن',
                        //         style: TextStyle(
                        //           color: Theme.of(context).primaryColor,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        IconButton(
                          icon: const Icon(Icons.support_agent),
                          tooltip: 'الدعم',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SupportPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
