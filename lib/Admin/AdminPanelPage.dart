// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// صفحه توثيق المستخدم
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  // تحديث حالة التوثيق
  Future<void> _toggleVerification(
      BuildContext context, String userId, bool isCurrentlyVerified) async {
    bool? confirm = await _showConfirmationDialog(
      context,
      title: isCurrentlyVerified ? 'إزالة التوثيق' : 'توثيق المستخدم',
      content: isCurrentlyVerified
          ? 'هل أنت متأكد أنك تريد إزالة التوثيق عن هذا المستخدم؟'
          : 'هل أنت متأكد أنك تريد توثيق هذا المستخدم؟',
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isVerified': !isCurrentlyVerified, // عكس الحالة الحالية
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyVerified ? 'تم إزالة التوثيق' : 'تم توثيق المستخدم',
          ),
        ),
      );
    }
  }

  // نافذة تأكيد الإجراء
  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // رفض
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // موافقة
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              var userId = user.id;
              var username = user['username'] ?? 'Unknown User';
              var isVerified = user['isVerified'] ?? false;

              return ListTile(
                leading: Icon(
                  Icons.person,
                  color: isVerified ? Colors.blue : Colors.grey,
                ),
                title: Text(username),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: $userId'),
                    Text(isVerified ? 'موثق' : 'غير موثق'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isVerified ? Icons.cancel : Icons.check,
                    color: isVerified ? Colors.red : Colors.green,
                  ),
                  onPressed: () =>
                      _toggleVerification(context, userId, isVerified),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
