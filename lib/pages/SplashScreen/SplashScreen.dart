// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, use_super_parameters, library_private_types_in_public_api, file_names, no_leading_underscores_for_local_identifiers

import 'package:chat/pages/LoginPage.dart';
import 'package:chat/pages/HomePage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    Future.delayed(Duration.zero, () => _checkUpdateAndNavigate());
  }

  // دالة لفحص التحديث باستخدام Remote Config مع معالجة الاستثناءات
  // تعيد القيمة nullable (true أو false أو null في حالة الخطأ)
  Future<bool?> remoteConfigCheck() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String appVersion = packageInfo.version;
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 60),
        minimumFetchInterval: const Duration(seconds: 1),
      ));
      await remoteConfig.fetchAndActivate();
      String remoteVersion = remoteConfig.getString('appVersion');
      print('الإصدار الحالي في التطبيق: $appVersion');
      print('الإصدار الموجود على Firebase: $remoteVersion');
      if (remoteVersion.compareTo(appVersion) > 0) {
        return true; // يوجد تحديث جديد
      } else {
        return false; // لا يوجد تحديث جديد
      }
    } catch (e) {
      print("Error in remoteConfigCheck: $e");
      return null;
    }
  }

  // دالة للتحقق من التحديث ثم الانتقال إلى الشاشة المناسبة مع حفظ حالة التحديث
  void _checkUpdateAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool savedForceUpdate = prefs.getBool('forceUpdate') ?? false;
    bool? hasUpdate = await remoteConfigCheck();

    if (hasUpdate == true) {
      await prefs.setBool('forceUpdate', true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ForceUpdateScreen()),
      );
    } else if (hasUpdate == false) {
      await prefs.setBool('forceUpdate', false);
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      if (savedForceUpdate) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ForceUpdateScreen()),
        );
      } else {
        bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
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
    return Scaffold();
  }
}

// شاشة التحديث الإجباري التي تُجبر المستخدم على التحديث
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({Key? key}) : super(key: key);

  // دالة لفتح متجر التطبيقات باستخدام launchUrl من حزمة url_launcher
  // يتم تمرير BuildContext لعرض رسالة عند عدم توفر الإنترنت
  Future<void> _launchStore(BuildContext context) async {
    final Uri _url = Uri.parse(
        "https://mahmoud29hany.blogspot.com/2025/02/margin-0-padding-0-box-sizing-border.html");
    try {
      bool launched =
          await launchUrl(_url, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذر فتح الرابط. الرجاء التأكد من اتصال الإنترنت.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء محاولة فتح الرابط.'),
      ));
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
                onPressed: () => _launchStore(context),
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
