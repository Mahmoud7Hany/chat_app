// lib/pages/NotificationsPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; // Import for log

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Mark all unread notifications as read when the page is opened.
    _markNotificationsAsRead();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _markNotificationsAsRead() async {
    if (currentUser == null) return;

    final unreadNotifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadNotifications.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // A function to format the timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No time available';
    DateTime messageTime = timestamp.toDate();
    DateTime now = DateTime.now();
    String period = messageTime.hour < 12 ? 'ص' : 'م';
    int hour12 = messageTime.hour > 12 ? messageTime.hour - 12 : messageTime.hour;
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

  // A function to delete a notification
  Future<void> _deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // NEW: Function to check if a notification has expired
  bool _isExpired(Timestamp? expiryDate) {
    if (expiryDate == null) {
      return false; // Permanent notification
    }
    return DateTime.now().isAfter(expiryDate.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // This is the part that prints the error to the terminal.
            log('Firestore Error: ${snapshot.error}', name: 'Firestore');
            // Display a user-friendly message on the screen.
            return Center(child: Text('حدث خطأ. يرجى مراجعة سجلات التطبيق.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات.'));
          }

          // Filter out expired notifications
          var allNotifications = snapshot.data!.docs;
          var nonExpiredNotifications = allNotifications.where((doc) {
            var notificationData = doc.data() as Map<String, dynamic>;
            Timestamp? expiryDate = notificationData['expiryDate'];
            return !_isExpired(expiryDate);
          }).toList();

          if (nonExpiredNotifications.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات.'));
          }

          return ListView.builder(
            itemCount: nonExpiredNotifications.length,
            itemBuilder: (context, index) {
              var notification = nonExpiredNotifications[index].data() as Map<String, dynamic>;
              String message = notification['message'] ?? 'No message';
              Timestamp createdAt = notification['createdAt'];
              String notificationId = nonExpiredNotifications[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(message),
                  subtitle: Text(_formatTimestamp(createdAt)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteNotification(notificationId),
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