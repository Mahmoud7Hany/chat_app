// ignore_for_file: avoid_print

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat/pages/ChatPage.dart';
import 'package:chat/pages/LoginPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      // الإعدادات المحلية واللغات
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'AE')],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد AnimationController للتأثير (إن رغبت في استخدامه لاحقًا)
    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    scaleAnimation =
        Tween<double>(begin: 0.0, end: 10.0).animate(scaleController);

    // بدء الفحص في الخلفية بعد اكتمال بناء الواجهة
    // نستخدم Future.delayed(Duration.zero) لضمان اكتمال تسجيل المستمعين على القنوات
    Future.delayed(Duration.zero, () => _checkUpdateAndNavigate());
  }

  // دالة لفحص التحديث باستخدام Remote Config مع معالجة استثناءات لمنع توقف التطبيق
  Future<bool> remoteConfigCheck() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appVersion = packageInfo.version;
      final remoteConfig = FirebaseRemoteConfig.instance;
      // إعدادات Remote Config كما في التطبيق السابق
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 60),
        minimumFetchInterval: const Duration(seconds: 1),
      ));
      await remoteConfig.fetchAndActivate();
      // استخدام المفتاح "appVersion" كما في الكود السابق
      String remoteVersion = remoteConfig.getString('appVersion');
      print('الإصدار الحالي في التطبيق: $appVersion');
      print('الإصدار الموجود على Firebase: $remoteVersion');
      // إذا كان الإصدار الموجود على Firebase أكبر من الإصدار الحالي (بالمقارنة الأبجدية)
      if (remoteVersion.compareTo(appVersion) == 1) {
        return true; // يوجد تحديث جديد
      } else {
        return false; // لا يوجد تحديث جديد
      }
    } catch (e) {
      // عند حدوث أي خطأ يتم طباعته والعودة بقيمة false
      print("Error in remoteConfigCheck: $e");
      return false;
    }
  }

  // دالة للتحقق من التحديث ثم الانتقال إلى الشاشة المناسبة
  void _checkUpdateAndNavigate() async {
    bool hasUpdate = await remoteConfigCheck();
    if (hasUpdate) {
      // إذا كان هناك تحديث جديد، توجه إلى شاشة التحديث الإجباري
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ForceUpdateScreen()),
      );
    } else {
      // إذا لم يكن هناك تحديث، تحقق من حالة تسجيل الدخول
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // شاشة البداية
    return Scaffold();
  }
}

// شاشة التحديث الإجباري التي تُجبر المستخدم على التحديث
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({Key? key}) : super(key: key);

  // دالة لفتح متجر التطبيقات (عدل الرابط ليناسب تطبيقك)
  Future<void> _launchStore() async {
    const url =
        "https://mahmoud29hany.blogspot.com/2025/02/margin-0-padding-0-box-sizing-border.html";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'تعذر فتح الرابط: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'تحديث جديد متاح!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'قم بتحديث التطبيق الآن للحصول على أفضل تجربة وأحدث الميزات.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _launchStore,
                icon: const Icon(Icons.download),
                label: const Text('تحديث التطبيق'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
