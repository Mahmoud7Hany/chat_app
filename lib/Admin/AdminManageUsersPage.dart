// ignore_for_file: file_names, use_super_parameters

import 'package:chat/Admin/AdminBanUserPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// صفحه 'إدارة المستخدمين الي بتكون لما اضغط علي القفل الي جمب الاسم اقدر احظر المستخدم واعمل له تقيد
class AdminManageUsersPage extends StatelessWidget {
  const AdminManageUsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
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
              String username = user['username'] ?? 'Unknown';
              bool isBanned = user['isBanned'] ?? false;

              return ListTile(
                title: Text(username),
                subtitle: Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: isBanned ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(isBanned ? 'محظور' : 'نشط'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isBanned ? Icons.lock_open : Icons.lock,
                    color: isBanned ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminBanUserPage(userId: user.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
