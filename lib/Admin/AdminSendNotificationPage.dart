// lib/Admin/AdminSendNotificationPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSendNotificationPage extends StatefulWidget {
  const AdminSendNotificationPage({super.key});

  @override
  State<AdminSendNotificationPage> createState() => _AdminSendNotificationPageState();
}

class _AdminSendNotificationPageState extends State<AdminSendNotificationPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();

  bool _isSending = false;
  bool _isPermanent = true;
  String _recipientType = 'all'; // 'all' or 'single'
  String? _selectedUserId;

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء كتابة رسالة الإشعار.')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      DateTime? expiryDate;
      if (!_isPermanent) {
        int days = int.tryParse(_daysController.text) ?? 0;
        int hours = int.tryParse(_hoursController.text) ?? 0;
        int minutes = int.tryParse(_minutesController.text) ?? 0;
        // Calculate expiry date if any duration is provided
        if (days > 0 || hours > 0 || minutes > 0) {
          expiryDate = DateTime.now().add(Duration(days: days, hours: hours, minutes: minutes));
        }
      }

      if (_recipientType == 'all') {
        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        for (var doc in usersSnapshot.docs) {
          if (doc.id != currentUser!.uid) { // Don't send to yourself
            await FirebaseFirestore.instance.collection('notifications').add({
              'message': _messageController.text,
              'senderId': currentUser.uid,
              'recipientId': doc.id,
              'createdAt': FieldValue.serverTimestamp(),
              'expiryDate': expiryDate,
              'isRead': false,
            });
          }
        }
      } else if (_recipientType == 'single' && _selectedUserId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'message': _messageController.text,
          'senderId': currentUser!.uid,
          'recipientId': _selectedUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'expiryDate': expiryDate,
          'isRead': false,
        });
      }

      _messageController.clear();
      // Clear duration fields after sending
      _daysController.clear();
      _hoursController.clear();
      _minutesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الإشعار بنجاح.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال إشعار'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'نص الإشعار',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('إشعار دائم (لا يتم حذفه تلقائياً)'),
              value: _isPermanent,
              onChanged: (value) {
                setState(() => _isPermanent = value);
              },
            ),
            const SizedBox(height: 16),
            if (!_isPermanent) ...[
              const Text('مدة انتهاء الصلاحية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'أيام',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ساعات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دقائق',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text('المستلمون:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('لجميع المستخدمين'),
                    value: 'all',
                    groupValue: _recipientType,
                    onChanged: (value) {
                      setState(() {
                        _recipientType = value!;
                        _selectedUserId = null;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('لمستخدم واحد'),
                    value: 'single',
                    groupValue: _recipientType,
                    onChanged: (value) {
                      setState(() => _recipientType = value!);
                    },
                  ),
                ),
              ],
            ),
            if (_recipientType == 'single')
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  var users = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedUserId,
                    hint: const Text('اختر المستخدم'),
                    onChanged: (userId) {
                      setState(() => _selectedUserId = userId);
                    },
                    items: users.map((user) {
                      return DropdownMenuItem(
                        value: user.id,
                        child: Text(user['username']),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              child: _isSending
                  ? const CircularProgressIndicator()
                  : const Text('إرسال الإشعار'),
            ),
          ],
        ),
      ),
    );
  }
}