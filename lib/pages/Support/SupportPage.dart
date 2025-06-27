// lib/pages/Support/SupportPage.dart
// ignore_for_file: file_names, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// تم إزالة استيراد 'package:url_launcher/url_launcher.dart'; لأنه لم يعد مستخدمًا للتليجرام

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _problemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // عند فتح الصفحة، قم بمسح جميع إشعارات الردود غير المقروءة
    _clearUnreadAdminReplies();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // دالة جديدة لمسح علامة الردود غير المقروءة عند دخول المستخدم لصفحة الدعم
  Future<void> _clearUnreadAdminReplies() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userTickets = await FirebaseFirestore.instance
        .collection('supportTickets')
        .where('userId', isEqualTo: currentUser.uid)
        .where('hasUnreadAdminReply', isEqualTo: true)
        .get();

    for (var doc in userTickets.docs) {
      await doc.reference.update({'hasUnreadAdminReply': false});
    }
  }


  Future<void> _submitReport() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لإرسال بلاغ.')),
      );
      return;
    }
    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة تفاصيل المشكلة.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // جلب اسم المستخدم من Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      String username = (userDoc.data() as Map<String, dynamic>?)?['username'] ?? 'مستخدم مجهول';

      // **تعديل: إضافة الرسالة الأولية كأول رد في مصفوفة الردود**
      await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': currentUser.uid,
        'username': username,
        'problemDescription': _problemController.text.trim(), // يمكن الاحتفاظ بها كملخص أولي
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'جديد',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'hasUnreadAdminReply': false, // **حقل جديد للإشعار**
        'replies': [ // أول رسالة من المستخدم نفسه
          {
            'message': _problemController.text.trim(),
            'timestamp': Timestamp.now(), // **تم التعديل هنا: استخدام Timestamp.now()**
            'senderId': currentUser.uid,
            'senderUsername': username,
            'isAdminReply': false, // هذه الرسالة من المستخدم
          }
        ],
      });

      _problemController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال بلاغك بنجاح. سيتم الرد عليك قريبًا.')),
      );
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إرسال البلاغ. الرجاء المحاولة لاحقًا.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتنسيق الوقت
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'لا يوجد وقت';
    DateTime dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // دالة لإنشاء شريحة بلاغ الدعم
  Widget _buildReportCard(DocumentSnapshot report) {
    var data = report.data() as Map<String, dynamic>;
    String problem = data['problemDescription'] ?? 'لا يوجد وصف';
    String status = data['status'] ?? 'غير معروف';
    Timestamp? createdAt = data['createdAt']; // **تعديل: جعلها قابلة لأن تكون null**
    List<dynamic> replies = data['replies'] ?? [];

    Color statusColor;
    switch (status) {
      case 'جديد':
        statusColor = Colors.orange;
        break;
      case 'قيد المعالجة':
        statusColor = Colors.blue;
        break;
      case 'تم الرد':
        statusColor = Colors.green;
        break;
      case 'مغلق':
        statusColor = Colors.grey;
        break;
      case 'مرفوض': // **تعديل جديد: لون الحالة المرفوضة**
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.black;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.support_agent, color: statusColor),
        ),
        title: Text(
          'حالة البلاغ: $status',
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
        ),
        subtitle: Text(
          problem.length > 50 ? '${problem.substring(0, 50)}...' : problem,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTimestamp(createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المشكلة:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  problem,
                  style: const TextStyle(fontSize: 15),
                ),
                const Divider(height: 24),
                // **تعديل جديد: عرض رسالة خاصة إذا كان البلاغ مرفوضاً**
                if (status == 'مرفوض')
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تم رفض هذا البلاغ. إذا كنت تعتقد أن هذا حدث عن طريق الخطأ، قم بإرسال بلاغ جديد وسوف يتم الرد عليك في أقرب وقت.',
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Text(
                  'سجل المحادثة:', // تغيير الاسم ليعكس أنه سجل محادثة
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                if (replies.isEmpty)
                  const Text('لا توجد ردود حتى الآن.', style: TextStyle(color: Colors.grey))
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: replies.map<Widget>((reply) {
                      String replyContent = reply['message'] ?? 'لا يوجد رد';
                      Timestamp? replyTimestamp = reply['timestamp'] as Timestamp?; // **تعديل: جعلها قابلة لأن تكون null وتأكيد النوع**
                      bool isAdminReply = reply['isAdminReply'] ?? false;
                      String senderUsername = reply['senderUsername'] ?? (isAdminReply ? 'الدعم' : 'أنت'); // اسم المرسل

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdminReply ? Colors.blue.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isAdminReply ? Colors.blue.shade100 : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdminReply ? '$senderUsername (الدعم):' : '$senderUsername:', // عرض اسم المرسل
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isAdminReply ? Colors.blue.shade800 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(replyContent),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _formatTimestamp(replyTimestamp), // تمرير Timestamp?
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                // تم إزالة الرسالة التوضيحية عن الردود لتظهر فقط سجل المحادثة
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'مركز المساعدة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.contact_support,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'كيف يمكننا مساعدتك؟',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الرجاء وصف مشكلتك بالتفصيل وسنقوم بالرد عليك في أقرب وقت.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // قسم إرسال بلاغ جديد
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إرسال بلاغ جديد',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _problemController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'اكتب مشكلتك هنا...',
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
                                  alignLabelWithHint: true,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _submitReport,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send, color: Colors.white),
                                  label: Text(
                                    _isLoading ? 'جاري الإرسال...' : 'إرسال البلاغ',
                                    style: const TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // **تعديل: StreamBuilder جديد للتحكم في ظهور قسم البلاغات السابقة بالكامل**
                      if (currentUser != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('supportTickets')
                              .where('userId', isEqualTo: currentUser.uid)
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                            }

                            // **الشرط الجديد: إظهار القسم فقط إذا كانت هناك بلاغات**
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const SizedBox.shrink(); // إخفاء القسم بالكامل إذا كان فارغًا
                            }

                            // إذا كانت هناك بلاغات، اعرض العنوان والقائمة
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'بلاغاتي السابقة',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    return _buildReportCard(snapshot.data!.docs[index]);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 30),
                    ],
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