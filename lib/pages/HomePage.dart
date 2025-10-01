// lib/pages/HomePage.dart
// ignore_for_file: deprecated_member_use, file_names, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:chat/Admin/AdminManageUsersPage.dart';
import 'package:chat/Admin/AdminPanelPage.dart';
import 'package:chat/pages/ChatPage.dart';
import 'package:chat/pages/LoginPage.dart';
import 'package:chat/pages/Support/SupportPage.dart';
import 'package:chat/pages/chatPrivate/PrivateChatsListPage.dart';
import 'package:chat/pages/chatPrivate/ProfilePage.dart';
import 'package:chat/widgets/BanCountdownWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chat/pages/NotificationsPage.dart'; // Import the new notifications page

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
  final currentUser = FirebaseAuth.instance.currentUser!;

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
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.data() == null) {
              return const Text(
                'تحميل...',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              );
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final username = (userData != null &&
                    userData['username'] != null &&
                    (userData['username'] as String).trim().isNotEmpty)
                ? userData['username'] as String
                : 'مستخدم';
            return Text(
              username,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            );
          },
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
          // زر الملف الشخصي
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'الملف الشخصي',
            onPressed: () {
              final currentUserId = FirebaseAuth.instance.currentUser!.uid;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userId: currentUserId),
                ),
              );
            },
          ),
          // زر الإشعارات مع شارة الإشعار (NEW)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('recipientId',
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('isRead',
                    isEqualTo: false) // Filter unread notifications
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnreadNotifications =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    tooltip: 'الإشعارات',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                  if (hasUnreadNotifications)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),
          // زر الدعم مع شارة الإشعار
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('supportTickets')
                .where('userId',
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('hasUnreadAdminReply', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnreadReplies =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    tooltip: 'الدعم',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SupportPage()),
                      );
                    },
                  ),
                  if (hasUnreadReplies)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),
          // زر تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // بانر تحكم المشرف
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  final bool isAdmin = userData?['isAdmin'] ?? false;
                  if (isAdmin) {
                    return _buildAdminPanelBanner(context); // عرض بانر المشرف
                  }
                }
                return const SizedBox
                    .shrink(); // لا تعرض أي شيء إذا لم يكن مشرفًا
              },
            ),

            // قسم تحديث التطبيق
            if (_isUpdateAvailable)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 20),
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.system_update_alt,
                          color: Colors.red.shade700, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحديث جديد متاح!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'قم بتحديث التطبيق الآن للحصول على أفضل تجربة.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.red.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _launchStore,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('تحديث'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // أزرار الدردشة (العامة والخاصة)
            Row(
              children: [
                Expanded(
                  child: _buildChatActionButton(
                    context,
                    title: 'الدردشة العامة',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blueAccent,
                    onTap: () => navigateToPublicChat(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChatActionButton(
                    context,
                    title: 'الرسائل الخاصة',
                    icon: Icons.message_outlined,
                    color: Colors.green,
                    onTap: () => navigateToPrivateMessages(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // قسم عرض حالة الحظر أو قائمة المستخدمين
            _isBanned
                ? _banUntil != null
                    ? Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: BanCountdownWidget(
                            banUntil: _banUntil!,
                            banReason: _banReason,
                            onBanEnd:
                                _unbanUser, // **تمت إضافة المعامل المطلوب هنا**
                          ),
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gpp_bad,
                                  size: 60, color: Colors.red.shade700),
                              const SizedBox(height: 16),
                              Text(
                                'تم إيقاف حسابك بشكل دائم.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_banReason != null && _banReason!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'السبب: $_banReason',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.support_agent,
                                    color: Colors.white),
                                label: const Text('تواصل مع الدعم',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SupportPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade500,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المستخدمون',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Icon(Icons.group,
                                  size: 28,
                                  color: Theme.of(context).primaryColor),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'ابحث عن مستخدم...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                var allUsers = snapshot.data!.docs;

                                // تطبيق البحث
                                var filteredUsers = allUsers.where((doc) {
                                  var username = (doc['username'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return username.contains(searchQuery);
                                }).toList();

                                // تقسيم المستخدمين إلى مشرفين وغير مشرفين
                                List<QueryDocumentSnapshot> admins = [];
                                List<QueryDocumentSnapshot> normalUsers = [];
                                for (var doc in filteredUsers) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  if (data['isAdmin'] == true) {
                                    admins.add(doc);
                                  } else {
                                    normalUsers.add(doc);
                                  }
                                }

                                // ترتيب المشرفين من الأقدم للأحدث (حسب createdAt)
                                admins.sort((a, b) {
                                  final aCreated =
                                      (a['createdAt'] as Timestamp?)
                                              ?.toDate() ??
                                          DateTime(2000);
                                  final bCreated =
                                      (b['createdAt'] as Timestamp?)
                                              ?.toDate() ??
                                          DateTime(2000);
                                  return aCreated.compareTo(
                                      bCreated); // تصاعدي (الأقدم أولاً)
                                });

                                // ترتيب المستخدمين من الأحدث للأقدم (حسب createdAt)
                                normalUsers.sort((a, b) {
                                  final aCreated =
                                      (a['createdAt'] as Timestamp?)
                                              ?.toDate() ??
                                          DateTime(2000);
                                  final bCreated =
                                      (b['createdAt'] as Timestamp?)
                                              ?.toDate() ??
                                          DateTime(2000);
                                  return bCreated.compareTo(
                                      aCreated); // تنازلي (الأحدث أولاً)
                                });

                                // دمج القوائم: المشرفين أولاً ثم المستخدمين
                                var finalList = [...admins, ...normalUsers];

                                if (finalList.isEmpty) {
                                  return Center(
                                    child: Text(
                                      searchQuery.isEmpty
                                          ? 'لا يوجد مستخدمون حاليًا.'
                                          : 'لا يوجد مستخدم بهذا الاسم.',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: finalList.length,
                                  itemBuilder: (context, index) {
                                    var user = finalList[index].data()
                                        as Map<String, dynamic>;
                                    var userId = finalList[index].id;
                                    bool isAdmin = user['isAdmin'] ?? false;
                                    bool isVerified =
                                        user['isVerified'] ?? false;
                                    String username =
                                        user['username'] ?? 'مستخدم مجهول';
                                    String? profilePic = user['profilePic'];

                                    // تمييز بطاقة المشرف بإطار ذهبي
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: isAdmin
                                          ? BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.amber.shade100,
                                                  Colors.white,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              border: Border.all(
                                                color: const Color(0xFFD4AF37),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber.shade200.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            )
                                          : null,
                                      child: Card(
                                        elevation: isAdmin ? 3 : 1,
                                        color: isAdmin ? Colors.white : null,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          leading: Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundImage: profilePic != null
                                                    ? NetworkImage(profilePic)
                                                    : null,
                                                backgroundColor: profilePic == null
                                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                                    : null,
                                                child: profilePic == null
                                                    ? Text(
                                                        username.isNotEmpty
                                                            ? username[0].toUpperCase()
                                                            : "U",
                                                        style: TextStyle(
                                                          color: Theme.of(context).primaryColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 24,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              if (isAdmin)
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.verified_user,
                                                      size: 16,
                                                      color: Color(0xFFD4AF37),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  username,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isAdmin ? const Color(0xFFD4AF37) : null,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isVerified)
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 4),
                                                  child: Icon(
                                                    Icons.verified,
                                                    color: Color(0xFF0083B0),
                                                    size: 18,
                                                  ),
                                                ),
                                              if (isAdmin)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFD4AF37),
                                                        Color(0xFFFFD700),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Icons.shield,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'مشرف',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios,
                                            color: isAdmin ? const Color(0xFFD4AF37) : Colors.grey[400],
                                            size: 18,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfilePage(userId: userId)),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 17),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50], // خلفية فاتحة وأنيقة
    );
  }

  // ويدجت مساعد لإنشاء أزرار الدردشة بأسلوب البطاقة
  Widget _buildChatActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (icon == Icons.chat_bubble_outline) {
      // Logic for public chat badge
      // We query for messages sent by others and filter client-side to check for unread ones.
      final publicChatUnreadStream = FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .snapshots(); // Removed the invalid `whereNotIn` filter

      return StreamBuilder<QuerySnapshot>(
        stream: publicChatUnreadStream,
        builder: (context, snapshot) {
          bool hasUnread = false;
          if (snapshot.hasData) {
            // Client-side filtering to check if the message is unread by the current user.
            hasUnread = snapshot.data!.docs.any((message) {
              final messageData = message.data() as Map<String, dynamic>?;
              if (messageData == null) return false;
              final readBy = messageData['readBy'] as List<dynamic>? ?? [];
              return !readBy.contains(currentUserId);
            });
          }

          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 40, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasUnread)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Logic for private chat badge
      // This stream listens to all private chats the user is in.
      // We will rely on the `hasUnreadMessagesFor_` field on the main chat document.
      final privateChatUnreadStream = FirebaseFirestore.instance
          .collection('private_chats')
          .where('users', arrayContains: currentUserId)
          .snapshots();

      return StreamBuilder<QuerySnapshot>(
        stream: privateChatUnreadStream,
        builder: (context, snapshot) {
          bool hasUnread = false;
          if (snapshot.hasData) {
            // Check if any of the user's private chats has an unread message flag.
            hasUnread = snapshot.data!.docs.any((chatDoc) {
              final chatData = chatDoc.data() as Map<String, dynamic>?;
              if (chatData == null) return false;

              // We check the summary field we'll add in the PrivateChatPage file.
              return chatData['hasUnreadMessagesFor_$currentUserId'] == true;
            });
          }

          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 40, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasUnread)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // ويدجت مساعد لإنشاء بانر المشرف
  Widget _buildAdminPanelBanner(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700),  // ذهبي فاتح
              Color(0xFFB8860B),  // ذهبي داكن
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                  SizedBox(width: 15),
                  Text(
                    'لوحة تحكم المشرف',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAdminAction(context,
                    icon: Icons.bar_chart_rounded,
                    label: 'الإحصائيات',
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const AdminPanelPage()),
                      );
                    },
                  ),
                  _buildAdminAction(context,
                    icon: Icons.manage_accounts_rounded,
                    label:'إدارة حظر المستخدمين',
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const AdminManageUsersPage()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت مساعد لإنشاء أزرار الإجراءات داخل بانر المشرف
  Widget _buildAdminAction(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
