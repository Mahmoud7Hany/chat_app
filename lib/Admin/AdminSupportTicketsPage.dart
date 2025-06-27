// lib/Admin/AdminSupportTicketsPage.dart
// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/Admin/AdminTicketDetailPage.dart'; // استيراد صفحة التفاصيل الجديدة

class AdminSupportTicketsPage extends StatefulWidget {
  const AdminSupportTicketsPage({super.key});

  @override
  State<AdminSupportTicketsPage> createState() => _AdminSupportTicketsPageState();
}

class _AdminSupportTicketsPageState extends State<AdminSupportTicketsPage> {
  String _filterStatus = 'الكل'; // 'الكل', 'جديد', 'قيد المعالجة', 'تم الرد', 'مغلق'

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بلاغات الدعم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // فلتر الحالة
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'الكل',
                child: Text('الكل'),
              ),
              const PopupMenuItem<String>(
                value: 'جديد',
                child: Text('جديد'),
              ),
              const PopupMenuItem<String>(
                value: 'قيد المعالجة',
                child: Text('قيد المعالجة'),
              ),
              const PopupMenuItem<String>(
                value: 'تم الرد',
                child: Text('تم الرد'),
              ),
              const PopupMenuItem<String>(
                value: 'مغلق',
                child: Text('مغلق'),
              ),
              const PopupMenuItem<String>( // **تعديل جديد: إضافة الحالة**
                value: 'مرفوض',
                child: Text('مرفوض'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _filterStatus == 'الكل'
            ? FirebaseFirestore.instance.collection('supportTickets').orderBy('lastUpdatedAt', descending: true).snapshots()
            : FirebaseFirestore.instance.collection('supportTickets').where('status', isEqualTo: _filterStatus).orderBy('lastUpdatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد بلاغات دعم حاليًا.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          var tickets = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: tickets.length,
            itemBuilder: (context, index) { // **تم التأكيد على وجود هذا المعامل**
              var ticket = tickets[index];
              var ticketData = ticket.data() as Map<String, dynamic>;
              String ticketId = ticket.id;
              String username = ticketData['username'] ?? 'مستخدم مجهول';
              String problemSummary = ticketData['problemDescription'] ?? 'لا يوجد وصف';
              String status = ticketData['status'] ?? 'جديد';
              Timestamp lastUpdatedAt = ticketData['lastUpdatedAt'] ?? ticketData['createdAt'];
              List<dynamic> replies = ticketData['replies'] ?? []; // عدد الردود

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminTicketDetailPage(ticketId: ticketId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'من: $username',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          problemSummary.length > 100 ? '${problemSummary.substring(0, 100)}...' : problemSummary,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'آخر تحديث: ${_formatTimestamp(lastUpdatedAt)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Icon(Icons.message, size: 18, color: Colors.blueGrey),
                            Text('${replies.length}', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}