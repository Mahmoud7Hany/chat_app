// ignore_for_file: file_names, library_private_types_in_public_api, use_super_parameters, avoid_print, prefer_null_aware_operators, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PrivateChatPage.dart';

// قائمة المحادثات الخاصة
class PrivateChatsListPage extends StatelessWidget {
  const PrivateChatsListPage({Key? key}) : super(key: key);

  // إزالة دالة saveLastMessage لأنها غير ضرورية الآن

  // دالة لتنسيق الوقت بنظام 12 ساعة مع عرض التاريخ إذا كانت الرسالة من أيام سابقة
  String _formatTimestamp(DateTime dateTime) {
    DateTime now = DateTime.now();
    String period = dateTime.hour < 12 ? 'ص' : 'م';
    int hour12 = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    hour12 = hour12 == 0 ? 12 : hour12;
    String minutes = dateTime.minute.toString().padLeft(2, '0');
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return '$hour12:$minutes $period';
    } else {
      String year = dateTime.year.toString();
      String month = dateTime.month.toString().padLeft(2, '0');
      String day = dateTime.day.toString().padLeft(2, '0');
      return '$hour12:$minutes $period، $year/$month/$day';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرسائل الخاصة')),
            body: Center(child: Text('خطأ: ${userSnapshot.error}')),
          );
        }
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرسائل الخاصة')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // الحصول على بيانات المستخدم الحالي للتحقق من حالة الحظر
        final currentUserData =
            userSnapshot.data!.data() as Map<String, dynamic>;
        bool isBanned = currentUserData['isBanned'] ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'الرسائل الخاصة',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('private_chats')
                .where('users', arrayContains: currentUserId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print(snapshot.error);
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد رسائل خاصة بعد.'));
              }

              var chats = snapshot.data!.docs;
              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  var chatData = chats[index].data() as Map<String, dynamic>;
                  List<dynamic> users = chatData['users'];
                  String otherUserId = users.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => '');
                  if (otherUserId.isEmpty) {
                    return const SizedBox();
                  }
                  
                  // Check for unread status for the current user
                  bool hasUnread = chatData['hasUnreadMessagesFor_$currentUserId'] ?? false;
                  
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text('خطأ: ${userSnapshot.error}'),
                        );
                      }
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            child: ListTile(
                              title: Text('جاري التحميل...'),
                            ),
                          ),
                        );
                      }
                      if (!userSnapshot.hasData) {
                        return const SizedBox();
                      }
                      var otherUserData =
                          userSnapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                      String username =
                          otherUserData['username'] ?? 'مستخدم مجهول';
                      String? profilePic = otherUserData['profilePic'];
                      bool isVerified = otherUserData['isVerified'] ?? false;
                      bool isAdmin = otherUserData['isAdmin'] ?? false;
                      String lastMessage = chatData['lastMessage'] ?? '';
                      Timestamp? timestamp = chatData['timestamp'];
                      DateTime? lastTime =
                          timestamp != null ? timestamp.toDate() : null;
                      String formattedTime =
                          lastTime != null ? _formatTimestamp(lastTime) : '';

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('private_chats')
                            .doc(chats[index].id)
                            .collection('messages')
                            .where('senderId', isEqualTo: otherUserId)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, unreadSnapshot) {
                          int unreadCount = 0;
                          if (unreadSnapshot.hasData) {
                            unreadCount = unreadSnapshot.data!.docs.length;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundImage: profilePic != null
                                      ? NetworkImage(profilePic)
                                      : null,
                                  child: profilePic == null
                                      ? const Icon(Icons.person, size: 25)
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
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
                                                size: 16,
                                              ),
                                            ),
                                          if (isAdmin)
                                            Container(
                                              margin: const EdgeInsets.only(left: 4),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFFD700),  // ذهبي فاتح
                                                    Color(0xFFB8860B),  // ذهبي داكن
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
                                    ),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    if (hasUnread && unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                                onTap: () {
                                  if (isBanned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'لا يمكنك التواصل لأن حسابك محظور.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PrivateChatPage(
                                        chatId: chats[index].id,
                                        otherUserId: otherUserId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// لا حاجة لتعديل هنا لأن عرض الدردشات يعتمد على وجود مستند في private_chats
// بعد تعديل PrivateChatPage ستظهر الدردشة تلقائياً بعد أول رسالة