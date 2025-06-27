// lib/Admin/AdminTicketDetailPage.dart
// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminTicketDetailPage extends StatefulWidget {
  final String ticketId;
  const AdminTicketDetailPage({super.key, required this.ticketId});

  @override
  State<AdminTicketDetailPage> createState() => _AdminTicketDetailPageState();
}

class _AdminTicketDetailPageState extends State<AdminTicketDetailPage> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingReply = false;
  String _selectedStatus = 'جديد'; // الحالة الافتراضية

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // دالة لتنسيق الوقت
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'لا يوجد وقت';
    DateTime dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // دالة لتحديد لون الحالة
  Color _getStatusColor(String status) {
    switch (status) {
      case 'جديد':
        return Colors.orange;
      case 'قيد المعالجة':
        return Colors.blue;
      case 'تم الرد':
        return Colors.green;
      case 'مغلق':
        return Colors.grey;
      case 'مرفوض': // **تعديل جديد: لون الحالة المرفوضة**
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  // دالة لإرسال الرد
  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء كتابة الرد أولاً.")),
      );
      return;
    }

    setState(() {
      _isSendingReply = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      String adminUsername = (adminDoc.data() as Map<String, dynamic>?)?['username'] ?? 'مشرف مجهول';

      await FirebaseFirestore.instance.collection('supportTickets').doc(widget.ticketId).update({
        'replies': FieldValue.arrayUnion([
          {
            'message': _replyController.text.trim(),
            'timestamp': Timestamp.now(), // **تم التعديل هنا: استخدام Timestamp.now() بدلاً من FieldValue.serverTimestamp()**
            'senderId': currentUser.uid,
            'senderUsername': adminUsername,
            'isAdminReply': true,
          }
        ]),
        'status': 'تم الرد', // **هذا يغير الحالة تلقائيًا كما طلبت**
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'hasUnreadAdminReply': true,
      });

      _replyController.clear();
      // تأكد من تمرير ScrollController بعد إضافة عنصر جديد
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إرسال الرد. الرجاء المحاولة لاحقًا.')),
      );
    } finally {
      setState(() {
        _isSendingReply = false;
      });
    }
  }

  // دالة لتغيير حالة البلاغ
  Future<void> _changeStatus(String? newStatus) async {
    if (newStatus == null || newStatus == _selectedStatus) return;

    setState(() {
      _selectedStatus = newStatus;
    });

    try {
      await FirebaseFirestore.instance.collection('supportTickets').doc(widget.ticketId).update({
        'status': newStatus,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تغيير حالة البلاغ إلى: $newStatus')),
      );
    } catch (e) {
      print('Error changing status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تغيير الحالة. الرجاء المحاولة لاحقًا.')),
      );
    }
  }

  // دالة جديدة لحذف البلاغ
  Future<void> _deleteTicket() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف البلاغ'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا البلاغ بشكل دائم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('supportTickets').doc(widget.ticketId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف البلاغ بنجاح.')),
        );
        Navigator.of(context).pop(); // العودة إلى صفحة البلاغات
      } catch (e) {
        print('Error deleting ticket: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حذف البلاغ.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البلاغ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // قائمة منسدلة لتغيير الحالة
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                dropdownColor: Theme.of(context).primaryColorDark, // لون خلفية القائمة المنسدلة
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white), // لون النص للقيمة المختارة
                onChanged: (String? newValue) {
                  _changeStatus(newValue);
                },
                items: <String>['جديد', 'قيد المعالجة', 'تم الرد', 'مغلق', 'مرفوض'] // **تعديل جديد: إضافة الحالة**
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: _getStatusColor(value)), // لون نص الخيار في القائمة
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // زر حذف البلاغ
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'حذف البلاغ',
            onPressed: _deleteTicket,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('supportTickets').doc(widget.ticketId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('البلاغ غير موجود.'));
          }

          var ticketData = snapshot.data!.data() as Map<String, dynamic>;
          String username = ticketData['username'] ?? 'مستخدم مجهول';
          String problemDescription = ticketData['problemDescription'] ?? 'لا يوجد وصف';
          String status = ticketData['status'] ?? 'جديد';
          Timestamp createdAt = ticketData['createdAt'];
          List<dynamic> replies = ticketData['replies'] ?? [];

          // تحديث الحالة المختارة في القائمة المنسدلة بناءً على البيانات
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_selectedStatus != status) {
              setState(() {
                _selectedStatus = status;
              });
            }
          });

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // بطاقة معلومات البلاغ الأساسية
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'من: $username',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'المشكلة:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              problemDescription,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const Divider(height: 20),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                'تاريخ الإنشاء: ${_formatTimestamp(createdAt)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // قسم الردود
                    const Text(
                      'الردود:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    if (replies.isEmpty)
                      const Center(
                        child: Text('لا توجد ردود حاليًا.', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Column(
                        children: replies.map<Widget>((reply) {
                          String message = reply['message'] ?? 'لا يوجد محتوى';
                          Timestamp timestamp = reply['timestamp'];
                          String senderUsername = reply['senderUsername'] ?? 'غير معروف';
                          bool isAdminReply = reply['isAdminReply'] ?? false;

                          return Align(
                            alignment: isAdminReply ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isAdminReply ? Colors.blue.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomLeft: isAdminReply ? Radius.circular(15) : Radius.circular(5),
                                  bottomRight: isAdminReply ? Radius.circular(5) : Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdminReply ? '$senderUsername (الدعم)' : senderUsername,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isAdminReply ? Colors.blue.shade800 : Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(message, style: const TextStyle(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTimestamp(timestamp),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              // حقل إرسال الرد
              if (status != 'مغلق' && status != 'مرفوض') // **تعديل جديد: إيقاف الردود عند الرفض**
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          maxLines: null, // للسماح بعدة أسطر
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'اكتب ردك هنا...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          textDirection: TextDirection.rtl, // دعم الكتابة من اليمين لليسار
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      _isSendingReply
                          ? const CircularProgressIndicator()
                          : IconButton(
                              icon: Icon(Icons.send, color: Theme.of(context).primaryColor, size: 30),
                              onPressed: _sendReply,
                            ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}