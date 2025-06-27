// lib/pages/chatPrivate/PrivateChatPage.dart
// ignore_for_file: file_names, library_private_types_in_public_api, use_super_parameters, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// صفحة الدردشة الخاصة
class PrivateChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const PrivateChatPage(
      {Key? key, required this.chatId, required this.otherUserId})
      : super(key: key);

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // جلب حالة المشرف للمستخدم الحالي من مجموعة "users"
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          _isAdmin = doc.data()?['isAdmin'] ?? false;
        });
      }
    });

    // Mark messages as read when the chat page is opened
    _markMessagesAsRead();
  }

  // دالة جديدة لتحديث رسائل الطرف الآخر كمقروءة
  void _markMessagesAsRead() async {
    // Update the main chat document to mark messages as read for the current user.
    await FirebaseFirestore.instance
        .collection('private_chats')
        .doc(widget.chatId)
        .update({
      'hasUnreadMessagesFor_${currentUser.uid}': false,
    });
  }

  // دالة لإرسال الرسالة وتحديث قاعدة البيانات الخاصة بالدردشة
  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String otherUserId = widget.otherUserId;
    String chatId = widget.chatId;

    // تحقق من وجود مستند الدردشة، إذا لم يوجد أنشئه
    final chatDocRef = FirebaseFirestore.instance.collection('private_chats').doc(chatId);
    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      await chatDocRef.set({
        'users': [currentUserId, otherUserId],
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'hasUnreadMessagesFor_$otherUserId': true,
        'hasUnreadMessagesFor_$currentUserId': false,
      });
    }

    // إضافة الرسالة إلى مجموعة "messages" الفرعية داخل الدردشة الخاصة
    await chatDocRef.collection('messages').add({
      'senderId': currentUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // تحديث الحقل lastMessage في المستند الرئيسي للدردشة وتعيين علامة "غير مقروء" للطرف الآخر
    await chatDocRef.update({
      'lastMessage': message,
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'hasUnreadMessagesFor_$otherUserId': true,
    });

    _messageController.clear(); // تصفير الحقل دائماً بعد الإرسال
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // دالة لتنسيق الوقت بنفس طريقة ChatPage.dart
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

  // دالة لبناء صورة المستخدم (Avatar) بناءً على الحرف الأول من اسم المستخدم
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

  // دالة لحذف الرسالة (تظهر فقط للمشرف)
  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('private_chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        // تعديل العنوان ليعرض بيانات المستخدم الآخر (اسم المستخدم، التوثيق، والمشرف)
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .snapshots(), // Use snapshots for real-time updates
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              String username = userData['username'] ?? 'User';
              bool isAdmin = userData['isAdmin'] ?? false;
              bool isVerified = userData['isVerified'] ?? false;
              bool isOnline = userData['isOnline'] ?? false;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6, right: 4),
                          child: Icon(Icons.verified,
                              color: Color.fromARGB(255, 56, 231, 3), size: 20),
                        ),
                      if (isAdmin)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade300,
                                Colors.purple.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'مشرف',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Display online/offline status
                  Text(
                    isOnline ? 'متصل الآن' : 'غير متصل',
                    style: TextStyle(
                      color: isOnline ? Colors.greenAccent : Colors.grey.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            } else {
              return const Text(
                'دردشة خاصة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              );
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('private_chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                // التمرير التلقائي لأسفل القائمة بعد تحميل الرسائل
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(data['senderId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        String username = 'U';
                        bool isMessageUserAdmin = false;
                        bool isVerified = false;
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          var userData = userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          username = (userData?['username'] ?? 'U').toString();
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
                                      // عرض اسم المستخدم مع الشارات (المشرف والتوثيق)
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                      BorderRadius.circular(12),
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
                                                    Icon(Icons.shield,
                                                        color: Colors.white,
                                                        size: 12),
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
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4),
                                                child: Icon(
                                                  Icons.verified,
                                                  color: Color(0xFF0083B0),
                                                  size: 16,
                                                  shadows: [
                                                    Shadow(
                                                      color: Color(0xFF0083B0),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
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
                                        data['message'] ?? '',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // عرض الوقت وتوفير زر الحذف (للمشرف) بجانب الوقت
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTimestamp(data['timestamp']),
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
                                                  await _deleteMessage(
                                                      messages[index].id);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'تم حذف الرسالة')),
                                                  );
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
                            ));
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // حقل إدخال الرسالة بتصميم مشابه لتصميم ChatPage.dart
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
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