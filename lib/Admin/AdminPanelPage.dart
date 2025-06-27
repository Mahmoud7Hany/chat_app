// lib/Admin/AdminPanelPage.dart
// ignore_for_file: use_build_context_synchronously, file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat/Admin/AdminSupportTicketsPage.dart'; // استيراد الصفحة الجديدة
import 'package:chat/Admin/AdminSendNotificationPage.dart'; // Import the new page

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
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
        'isVerified': !isCurrentlyVerified,
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

  // تحديث حالة المشرف
  Future<void> _toggleAdmin(
      BuildContext context, String userId, bool isCurrentlyAdmin) async {
    bool? confirm = await _showConfirmationDialog(
      context,
      title: isCurrentlyAdmin ? 'إزالة صلاحيات المشرف' : 'منح صلاحيات المشرف',
      content: isCurrentlyAdmin
          ? 'هل أنت متأكد أنك تريد إزالة صلاحيات المشرف من هذا المستخدم؟'
          : 'هل أنت متأكد أنك تريد منح صلاحيات المشرف لهذا المستخدم؟',
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isAdmin': !isCurrentlyAdmin,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyAdmin
                ? 'تم إزالة صلاحيات المشرف'
                : 'تم منح صلاحيات المشرف',
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;
        int totalUsers = users.length;
        int verifiedUsers =
            users.where((user) => user['isVerified'] == true).length;
        int adminUsers = users.where((user) => user['isAdmin'] == true).length;
        int bannedUsers =
            users.where((user) => user['isBanned'] == true).length;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 16),
                  child: Text(
                    'إحصائيات عامة',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'إجمالي المستخدمين',
                        totalUsers,
                        const Color(0xFF1E88E5),
                        Icons.people,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'المستخدمين الموثقين',
                        verifiedUsers,
                        const Color(0xFF43A047),
                        Icons.verified_user,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'المشرفين',
                        adminUsers,
                        const Color(0xFFFB8C00),
                        Icons.admin_panel_settings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'المستخدمين المحظورين',
                        bannedUsers,
                        const Color(0xFFE53935),
                        Icons.block,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // ** التعديل الجديد: زر إدارة بلاغات الدعم **
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminSupportTicketsPage()),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text('إدارة بلاغات الدعم', style: TextStyle(fontSize: 18, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // New button to send notifications
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminSendNotificationPage()),
                      );
                    },
                    icon: const Icon(Icons.notifications_active, color: Colors.white),
                    label: const Text('إرسال إشعار', style: TextStyle(fontSize: 18, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
        );
      },
    );
  }

  Widget _buildAnimatedStatCard(
      String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
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
            var userData = user.data() as Map<String, dynamic>;
            var username = userData['username'] ?? 'مستخدم مجهول';
            var isVerified = userData['isVerified'] ?? false;
            var isAdmin = userData['isAdmin'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      Icons.person,
                      color: isVerified ? Colors.blue : Colors.grey,
                      size: 30,
                    ),
                    if (isAdmin)
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                title: Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: $userId'),
                    Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.cancel,
                          color: isVerified ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(isVerified ? 'موثق' : 'غير موثق'),
                        const SizedBox(width: 8),
                        Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.person_outline,
                          color: isAdmin ? Colors.orange : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(isAdmin ? 'مشرف' : 'مستخدم عادي'),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isVerified
                            ? Icons.verified_user
                            : Icons.verified_user_outlined,
                        color: isVerified ? Colors.green : Colors.grey,
                      ),
                      onPressed: () =>
                          _toggleVerification(context, userId, isVerified),
                      tooltip: isVerified ? 'إلغاء التوثيق' : 'توثيق',
                    ),
                    IconButton(
                      icon: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.admin_panel_settings_outlined,
                        color: isAdmin ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () => _toggleAdmin(context, userId, isAdmin),
                      tooltip: isAdmin
                          ? 'إزالة صلاحيات المشرف'
                          : 'منح صلاحيات المشرف',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الإحصائيات'),
              Tab(text: 'المستخدمين'),
            ],
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.people),
          //     tooltip: 'إدارة المستخدمين',
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => const AllUsersPage()),
          //       );
          //     },
          //   ),
          // ],
        ),
        body: TabBarView(
          children: [
            _buildStatisticsTab(),
            _buildUsersTab(),
          ],
        ),
      ),
    );
  }
}