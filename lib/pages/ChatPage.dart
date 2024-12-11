// ignore_for_file: library_private_types_in_public_api, file_names, use_build_context_synchronously

import 'package:chat/Admin/AdminManageUsersPage.dart';
import 'package:chat/Admin/AdminPanelPage.dart';
import 'package:chat/pages/LoginPage.dart';
import 'package:chat/pages/Support/SupportPage%20.dart';
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

  // دالة لإرسال الرسالة
  void _sendMessage() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userDoc.exists) {
      var userData = userDoc.data();
      if (userData!['isBanned'] == true) {
        String banReason = userData['banReason'] ?? 'تم حظرك.';
        Timestamp? banUntil = userData['banUntil'];

        // التحقق إذا انتهى وقت الحظر
        if (banUntil != null && banUntil.toDate().isBefore(DateTime.now())) {
          // إزالة الحظر لأن المدة انتهت
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            'isBanned': false,
            'banReason': null,
            'banUntil': null,
          });
        } else {
          // عرض رسالة الحظر
          String banMessage = banUntil != null
              ? "$banReason. الحظر ينتهي في: ${banUntil.toDate()}"
              : "$banReason. الحظر دائم.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(banMessage)),
          );
          return;
        }
      }
    }

    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('messages').add({
        'message': _messageController.text,
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      _scrollToBottom(); // التمرير التلقائي بعد الإرسال
    }
  }

  // دالة للتمرير إلى آخر رسالة
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

  // دالة لتخزين حالة تسجيل الخروج
  Future<void> _clearLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }

  // التحقق مما إذا كان المستخدم الحالي هو أدمن
  Future<bool> _isAdmin() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    return userDoc['isAdmin'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('محادثة'),
        actions: [
          // توثيق المستخدم ان الادمن يقدر يوثق الحسابات
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }

              if (snapshot.hasData && snapshot.data!.exists) {
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                bool isAdmin = userData['isAdmin'] ?? false;

                if (isAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminPanelPage()),
                      );
                    },
                  );
                }
              }
              return Container();
            },
          ),

          // اداره المستخدم حظر مستخدم من الكتابه
          // الجزء ده خاص بعرض الايقون علطول لكن الي يقدر يدخل عليها الادمن فقط واي شخص اخر يقول له ليس لديك الصلحيات يعني لازم يكون ادمن
          // IconButton(
          //   icon: const Icon(Icons.manage_accounts),
          //   onPressed: () async {
          //     var userDoc = await FirebaseFirestore.instance
          //         .collection('users')
          //         .doc(FirebaseAuth.instance.currentUser!.uid)
          //         .get();

          //     if (userDoc.exists && (userDoc['isAdmin'] ?? false)) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => const AdminManageUsersPage()),
          //       );
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //             content: Text('ليس لديك صلاحية الوصول إلى هذه الصفحة.')),
          //       );
          //     }
          //   },
          // ),

          // اداره المستخدم حظر مستخدم من الكتابه
          // الجزء ده خاص بعرض الايقونه فقط لما يكون ادمن غير كده تختفي
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }

              if (snapshot.hasData && snapshot.data!.exists) {
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                bool isAdmin = userData['isAdmin'] ?? false;

                if (isAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.manage_accounts),
                    onPressed: () async {
                      var userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get();

                      if (userDoc.exists && (userDoc['isAdmin'] ?? false)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AdminManageUsersPage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'ليس لديك صلاحية الوصول إلى هذه الصفحة.')),
                        );
                      }
                    },
                  );
                }
              }
              return Container(); // إخفاء الزر إذا لم يكن المستخدم أدمن
            },
          ),

          // الدعم
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

          // تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              bool? shouldLogOut = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('تأكيد الخروج'),
                    content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('تأكيد'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogOut == true) {
                await FirebaseAuth.instance.signOut();
                await _clearLoginStatus();
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index]['message'];
                    var senderId = messages[index]['senderId'];
                    var messageId = messages[index].id;
                    var timestamp = messages[index]['createdAt'] as Timestamp?;

                    String formattedTime = timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                                timestamp.millisecondsSinceEpoch)
                            .toLocal()
                            .toString()
                        : 'غير متوفر';

                    bool isCurrentUser =
                        senderId == FirebaseAuth.instance.currentUser!.uid;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(senderId)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var userData = userSnapshot.data!;
                        var username = userData['username'] ?? 'Unknown User';
                        var isVerified = userData['isVerified'] ?? false;

                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // هنا نغير
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      username,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.check_circle,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.green,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  softWrap: true, // يسمح بتغليف النص
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isCurrentUser
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                FutureBuilder<bool>(
                                  future: _isAdmin(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container();
                                    }
                                    if (snapshot.hasData && snapshot.data!) {
                                      return Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('messages')
                                                .doc(messageId)
                                                .delete();
                                          },
                                        ),
                                      );
                                    }
                                    return Container();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        const InputDecoration(labelText: 'أدخل الرسالة'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
