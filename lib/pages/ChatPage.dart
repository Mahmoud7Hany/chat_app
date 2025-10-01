// lib/pages/ChatPage.dart
// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, file_names, use_build_context_synchronously, unused_field, prefer_final_fields

import 'package:chat/pages/Support/SupportPage.dart';
import 'package:chat/widgets/BanCountdownWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  // متغيرات حالة المستخدم
  bool _isBanned = false;
  DateTime? _banUntil;
  String? _banReason;
  bool _isAdmin = false; // متغير لتحديد حالة المشرف
  bool _canViewMessages = true; // NEW: Added this variable definition
  bool _didAutoScroll = false; // إضافة متغير لتتبع النزول التلقائي
  int _lastMessagesCount = 0;  // متغير لحفظ عدد الرسائل السابق

  // إضافة متغير للتحكم في نوع الرسالة
  bool _sendAsAdmin = false;
  String _adminName = ' المشرف'; // إضافة متغير لاسم المشرف

  @override
  void initState() {
    super.initState();
    // الاشتراك في مستند المستخدم لمتابعة حالة الحظر ومشاهدة الرسائل
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
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
          _isAdmin = data['isAdmin'] ?? false; // تحديث حالة المشرف
        });
      }
    });

    // استدعاء دالة تحديث الرسائل كمقروءة عند دخول الصفحة
    _markAllMessagesAsRead();
  }
  
  // دالة جديدة لتحديث الرسائل كمقروءة عند دخول المستخدم للصفحة
  Future<void> _markAllMessagesAsRead() async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUser.uid)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in messagesSnapshot.docs) {
      // ignore: unnecessary_cast
      final messageData = doc.data() as Map<String, dynamic>;
      List<dynamic> readBy = messageData['readBy'] ?? [];
      // Check if the current user has not read the message yet
      if (!readBy.contains(currentUser.uid)) {
        // Update the 'readBy' array for this message
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUser.uid])
        });
      }
    }
    await batch.commit();
  }

  // دالة لرفع الحظر تلقائيًا (يتم استدعاؤها من داخل BanCountdownWidget)
  Future<void> _unbanUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
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
    final message = _messageController.text;
    
    // إضافة معلومات الرسالة
    Map<String, dynamic> messageData = {
      'senderId': currentUser.uid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'sendAsAdmin': _sendAsAdmin,
      'readBy': [currentUser.uid],
      'displayName': _sendAsAdmin ? _adminName : null, // تخزين نوع العرض
    };

    await FirebaseFirestore.instance.collection('messages').add(messageData);
    _messageController.clear();
    _scrollToBottom();
  }

  // التمرير لأسفل
  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
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

  Widget _buildMessageInput() {
    return Container(
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
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (_isAdmin) // إظهار زر الاختيار للمشرفين فقط
                IconButton(
                  icon: Icon(
                    _sendAsAdmin ? Icons.workspace_premium : Icons.person,
                    color: _sendAsAdmin ? const Color(0xFFFFD700) : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _sendAsAdmin = !_sendAsAdmin;
                    });
                  },
                  tooltip: _sendAsAdmin ? 'إرسال كمشرف' : 'إرسال باسمي',
                ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _isAdmin
                        ? (_sendAsAdmin ? 'اكتب رسالة كمشرف...' : 'اكتب رسالة باسمك...')
                        : 'اكتب رسالتك هنا...',
                    border: InputBorder.none,
                  ),
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
    );
  }

  // بناء واجهة الصفحة
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'محادثة عامة',
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
        actions: [
          // زر الدعم مع شارة الإشعار
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('supportTickets')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('hasUnreadAdminReply', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnreadReplies = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    tooltip: 'الدعم',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SupportPage()),
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
        ],
      ),
      body: Column(
        children: [
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
                // النزول التلقائي لأسفل عند تحميل الرسائل أو تحديثها (مرة واحدة فقط عند الفتح)
                if (!_didAutoScroll) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _scrollToBottom(jump: true);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _scrollToBottom(jump: true);
                    });
                    _didAutoScroll = true;
                  });
                }
                // النزول التلقائي عند وصول رسالة جديدة من أي مستخدم
                if (_lastMessagesCount != messages.length) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _scrollToBottom();
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _scrollToBottom();
                    });
                  });
                  _lastMessagesCount = messages.length;
                }
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
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                            var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                            
                            // التحقق من نوع الرسالة وعرض الاسم المناسب
                            if (message['sendAsAdmin'] == true) {
                                // إذا كانت الرسالة مرسلة كمشرف، نعرض "مشرف"
                                username = _adminName;
                            } else {
                                // إذا كانت رسالة عادية، نعرض اسم المستخدم
                                username = (userData?['username'] ?? 'U').toString();
                            }
                            
                            // تحديد حالة المشرف من بيانات المستخدم
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
                                  gradient: isMessageUserAdmin 
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF8E1),
                                          Color(0xFFFFECB3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                  color: isMessageUserAdmin 
                                    ? null 
                                    : (isMe ? Theme.of(context).primaryColor : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isMessageUserAdmin 
                                        ? const Color(0xFFFFD700).withOpacity(0.2)
                                        : Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // رأس الرسالة - الاسم والشارات
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          username,
                                          style: TextStyle(
                                            color: isMessageUserAdmin
                                              ? Colors.black87  // لون اسم المشرف أسود
                                              : (isMe ? Colors.white70 : Colors.black54),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (isVerified)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.verified,
                                              color: const Color(0xFF0083B0),
                                              size: 14,
                                            ),
                                          ),
                                        if (isMessageUserAdmin)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFFD700),
                                                  Color(0xFFB8860B),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0xFFFFD700),
                                                  blurRadius: 3,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.workspace_premium,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'مشرف',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black26,
                                                        blurRadius: 2,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // نص الرسالة
                                    Text(
                                      message['message'] ?? '',
                                      style: TextStyle(
                                        color: isMessageUserAdmin 
                                          ? Colors.black87  // لون النص أسود للمشرف
                                          : (isMe ? Colors.white : Colors.black87),
                                        fontSize: 16,
                                        fontWeight: isMessageUserAdmin 
                                          ? FontWeight.w600  // جعل النص أكثر وضوحاً للمشرف
                                          : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // الوقت وعلامات القراءة
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTimestamp(
                                              message['createdAt']),
                                          style: TextStyle(
                                            color: isMessageUserAdmin
                                              ? Colors.black54  // لون الوقت رمادي داكن للمشرف
                                              : (isMe ? Colors.white70 : Colors.black54),
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
                                                        child:
                                                            const Text('إلغاء'),
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
                                                await FirebaseFirestore.instance
                                                    .collection('messages')
                                                    .doc(messages[index].id)
                                                    .delete();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'تم حذف الرسالة'),
                                                      duration:
                                                          Duration(seconds: 2),
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
            _buildMessageInput(),
        ],
      ),
    );
  }
}