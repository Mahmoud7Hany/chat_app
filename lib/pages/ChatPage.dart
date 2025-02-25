import 'package:chat/Admin/AdminManageUsersPage.dart';
import 'package:chat/Admin/AdminPanelPage.dart';
import 'package:chat/pages/LoginPage.dart';
import 'package:chat/pages/Support/SupportPage.dart';
import 'package:chat/widgets/BanCountdownWidget.dart'; // استدعاء الويجت الجديد
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // متغيرات حالة المستخدم
  bool _isBanned = false;
  DateTime? _banUntil;
  String? _banReason;
  bool _canViewMessages = true;
  bool _isAdmin = false; // متغير لتحديد حالة المشرف

  @override
  void initState() {
    super.initState();
    // الاشتراك في مستند المستخدم فقط، بدون مؤقت
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _isBanned = data['isBanned'] ?? false;
          _banReason = data['banReason'];
          _banUntil = data['banUntil'] != null
              ? (data['banUntil'] as Timestamp).toDate()
              : null;
          _canViewMessages = data['canViewMessages'] ?? true;
          _isAdmin = data['isAdmin'] ?? false; // تحديث حالة المشرف
        });
      }
    });
  }

  // دالة لرفع الحظر تلقائيًا (يتم استدعاؤها من داخل BanCountdownWidget)
  Future<void> _unbanUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'isBanned': false,
      'banReason': null,
      'banUntil': null,
      'canViewMessages': true, // إعادة تمكين المشاهدة تلقائياً
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفع الحظر تلقائياً.')),
    );
  }

  // إرسال رسالة
  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'message': _messageController.text,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _messageController.clear();
    _scrollToBottom();
  }

  // التمرير لأسفل
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime messageTime = timestamp.toDate();
    DateTime now = DateTime.now();
    String period = messageTime.hour < 12 ? 'ص' : 'م';
    int hour12 =
        messageTime.hour > 12 ? messageTime.hour - 12 : messageTime.hour;
    hour12 = hour12 == 0 ? 12 : hour12;
    String minutes = messageTime.minute.toString().padLeft(2, '0');
    if (messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day) {
      return '$hour12:$minutes $period';
    } else {
      String year = messageTime.year.toString();
      String month = messageTime.month.toString().padLeft(2, '0');
      String day = messageTime.day.toString().padLeft(2, '0');
      return '$hour12:$minutes $period، $year/$month/$day';
    }
  }

  Widget _buildAvatar(String username) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // بناء واجهة الصفحة
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محادثة',
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
      body: Column(
        children: [
          // التحقق من إمكانية مشاهدة الرسائل
          if (!_canViewMessages)
            Expanded(
              child: Center(
                child: Text(
                  'تم منعك من مشاهدة الرسائل.',
                  style: TextStyle(fontSize: 18, color: Colors.red[700]),
                ),
              ),
            )
          else
            // عرض الرسائل
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد رسائل',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  List<DocumentSnapshot> messages = snapshot.data!.docs;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message =
                          messages[index].data() as Map<String, dynamic>;
                      bool isMe = message['senderId'] ==
                          FirebaseAuth.instance.currentUser!.uid;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(message['senderId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          String username = 'U';
                          bool isMessageUserAdmin = false;
                          bool isVerified = false;
                          if (userSnapshot.hasData &&
                              userSnapshot.data != null) {
                            var userData = userSnapshot.data!.data()
                                as Map<String, dynamic>?;
                            username =
                                (userData?['username'] ?? 'U').toString();
                            isMessageUserAdmin = userData?['isAdmin'] ?? false;
                            isVerified = userData?['isVerified'] ?? false;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (!isMe) _buildAvatar(username),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isMe ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // عرض اسم المستخدم + توثيق/مشرف
                                      if (userSnapshot.hasData &&
                                          userSnapshot.data != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isMessageUserAdmin)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 4),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.purple.shade300,
                                                        Colors.purple.shade600,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.purple
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.shield,
                                                        color: Colors.white,
                                                        size: 12,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'مشرف',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (isVerified)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 4),
                                                  child: Icon(
                                                    Icons.verified,
                                                    color: Color(0xFF0083B0),
                                                    size: 16,
                                                    shadows: [
                                                      Shadow(
                                                        color: const Color(
                                                                0xFF0083B0)
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // نص الرسالة
                                      Text(
                                        message['message'] ?? '',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // وقت الإرسال + زر الحذف (الزر يظهر فقط للمشرف)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTimestamp(
                                                message['createdAt']),
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (_isAdmin)
                                            GestureDetector(
                                              onTap: () async {
                                                bool? confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'حذف الرسالة'),
                                                      content: const Text(
                                                          'هل أنت متأكد من حذف هذه الرسالة؟'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false),
                                                          child: const Text(
                                                              'إلغاء'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true),
                                                          child: const Text(
                                                            'حذف',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                if (confirm == true) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('messages')
                                                      .doc(messages[index].id)
                                                      .delete();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'تم حذف الرسالة'),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMe) _buildAvatar(username),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          // إذا كان محظورًا مؤقتًا، نعرض BanCountdownWidget
          if (_isBanned && _banUntil != null)
            BanCountdownWidget(
              banUntil: _banUntil!,
              banReason: _banReason,
              onBanEnd:
                  _unbanUser, // عند انتهاء العداد، يتم استدعاء دالة رفع الحظر
            )
          // إذا كان حظرًا دائمًا (banUntil = null) أو حظر بلا زمن محدد
          else if (_isBanned && _banUntil == null)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تم حظرك من ارسال الرسائل بشكل دائم.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_banReason != null)
                    Text(
                      'السبب: $_banReason',
                      style: TextStyle(fontSize: 14, color: Colors.red[700]),
                    ),
                ],
              ),
            )
          // إذا لم يكن محظورًا نعرض حقل الإدخال
          else if (!_isBanned)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'اكتب رسالتك هنا...',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColorDark,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
