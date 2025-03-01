// ignore_for_file: deprecated_member_use, file_names, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:chat/Admin/AdminManageUsersPage.dart';
import 'package:chat/Admin/AdminPanelPage.dart';
import 'package:chat/pages/ChatPage.dart';
import 'package:chat/pages/LoginPage.dart';
import 'package:chat/pages/Support/SupportPage.dart';
import 'package:chat/pages/chatPrivate/PrivateChatsListPage.dart';
import 'package:chat/pages/chatPrivate/ProfilePage.dart';
import 'package:chat/widgets/BanCountdownWidget.dart'; // إضافة ويدجت العد التنازلي لرفع الحظر (&#8203;:contentReference[oaicite:1]{index=1})
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isUpdateAvailable = false;
  String searchQuery = "";
  bool _canViewMessages = true;
  bool _isBanned = false;
  DateTime? _banUntil;
  String? _banReason;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    // الاشتراك في مستند المستخدم لمتابعة حالة الحظر ومشاهدة الرسائل
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _canViewMessages = data['canViewMessages'] ?? true;
          _isBanned = data['isBanned'] ?? false;
          _banUntil = data['banUntil'] != null
              ? (data['banUntil'] as Timestamp).toDate()
              : null;
          _banReason = data['banReason'];
        });
      }
    });
  }

  Future<void> _checkForUpdate() async {
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
      if (remoteVersion.compareTo(appVersion) == 1) {
        setState(() {
          _isUpdateAvailable = true;
        });
      }
    } catch (e) {
      print("Error checking update: $e");
    }
  }

  // دالة رفع الحظر تلقائياً عند انتهاء العد التنازلي
  Future<void> _unbanUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'isBanned': false,
      'banReason': null,
      'banUntil': null,
      'canViewMessages': true,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفع الحظر تلقائياً.')),
    );
  }

  // الانتقال الخاص بصفحة الدردشة العامة
  void navigateToPublicChat(BuildContext context) {
    if (!_canViewMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم منعك من مشاهدة الرسائل.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage()),
    );
  }

  // الانتقال الخاص بصفحة الرسائل الخاصة
  void navigateToPrivateMessages(BuildContext context) {
    if (!_canViewMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم منعك من مشاهدة الرسائل.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivateChatsListPage()),
    );
  }

  Future<void> _launchStore() async {
    const url =
        "https://mahmoud29hany.blogspot.com/2025/02/margin-0-padding-0-box-sizing-border.html";
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          // زر لوحة التحكم وإدارة المستخدمين للمشرف
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final bool isAdmin = userData?['isAdmin'] ?? false;
                if (isAdmin) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.admin_panel_settings,
                            color: Colors.white),
                        tooltip: 'لوحة التحكم',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AdminPanelPage()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.manage_accounts,
                            color: Colors.white),
                        tooltip: 'إدارة المستخدمين',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdminManageUsersPage()),
                          );
                        },
                      ),
                    ],
                  );
                }
              }
              return Container();
            },
          ),
          // زر الدعم
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.black),
            tooltip: 'الدعم',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            },
          ),
          // زر تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white60),
            onPressed: () async {
              bool? shouldLogOut = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('تأكيد الخروج'),
                    content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('تأكيد'),
                      ),
                    ],
                  );
                },
              );
              if (shouldLogOut == true) {
                await FirebaseAuth.instance.signOut();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('isLoggedIn');
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isUpdateAvailable)
              ElevatedButton(
                onPressed: _launchStore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تحديث التطبيق'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => navigateToPublicChat(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('الدردشة العامة'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isBanned
                  ? _banUntil != null
                      ? BanCountdownWidget(
                          banUntil: _banUntil!,
                          banReason: _banReason,
                          onBanEnd: _unbanUser,
                        ) // عرض العداد التنازلي لرفع الحظر (&#8203;:contentReference[oaicite:2]{index=2})
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'تم إيقاف حسابك بشكل دائم.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.support_agent),
                                  label: const Text('الدعم'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SupportPage()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'المستخدمين',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'ابحث عن مستخدم...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                var users = snapshot.data!.docs.where((doc) {
                                  var username = (doc['username'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return username.contains(searchQuery);
                                }).toList();

                                return ListView.builder(
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    var user = users[index].data()
                                        as Map<String, dynamic>;
                                    var userId = users[index].id;
                                    bool isAdmin = user['isAdmin'] ?? false;
                                    bool isVerified =
                                        user['isVerified'] ?? false;
                                    String username =
                                        user['username'] ?? 'مستخدم مجهول';
                                    String? profilePic = user['profilePic'];

                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: profilePic != null
                                              ? NetworkImage(profilePic)
                                              : null,
                                          backgroundColor: profilePic == null
                                              ? Colors.blueAccent
                                              : null,
                                          child: profilePic == null
                                              ? Text(
                                                  username.isNotEmpty
                                                      ? username[0]
                                                          .toUpperCase()
                                                      : "",
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        title: Row(
                                          children: [
                                            Text(username,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(width: 5),
                                            if (isVerified)
                                              const Icon(Icons.verified,
                                                  color: Colors.blue, size: 16),
                                            if (isAdmin)
                                              const Icon(
                                                  Icons.admin_panel_settings,
                                                  color: Colors.orange,
                                                  size: 16),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.chat,
                                            color: Colors.blueAccent),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfilePage(
                                                        userId: userId)),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => navigateToPrivateMessages(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('عرض الرسائل الخاصة'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
