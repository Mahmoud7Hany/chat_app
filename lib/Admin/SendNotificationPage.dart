// lib/Admin/SendNotificationPage.dart
// (ملف جديد)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final TextEditingController _messageController = TextEditingController();
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
        // يمكنك إضافة منطق لاحقاً لتحديد المدة (مثل يوم، أسبوع...)
        // على سبيل المثال، إشعار يدوم لمدة 24 ساعة
        expiryDate = DateTime.now().add(const Duration(days: 1));
      }

      if (_recipientType == 'all') {
        // إرسال لجميع المستخدمين
        // ستحتاج إلى جلب قائمة المستخدمين وإرسال إشعار لكل منهم
        // أو استخدام خاصية Recipients: 'all' إذا كان المنطق يسمح بذلك
        // للتبسيط، سنرسله لكل مستخدم باستثناء المسؤول
        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        for (var doc in usersSnapshot.docs) {
          if (doc.id != currentUser!.uid) { // لا ترسل لنفسك
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
        // إرسال لمستخدم واحد
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
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColorDark],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (واجهة المستخدم: حقل الرسالة، خيارات المدة، المستلمون)
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'نص الإشعار',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            // ... (Checkbox and Radio buttons for permanent/temporary and all/single recipient)
            SwitchListTile(
              title: const Text('إشعار دائم (لا يتم حذفه تلقائياً)'),
              value: _isPermanent,
              onChanged: (value) {
                setState(() => _isPermanent = value);
              },
            ),
            const SizedBox(height: 16),
            Text('المستلمون:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Radio<String>(
                  value: 'all',
                  groupValue: _recipientType,
                  onChanged: (value) {
                    setState(() {
                      _recipientType = value!;
                      _selectedUserId = null;
                    });
                  },
                ),
                const Text('لجميع المستخدمين'),
                Radio<String>(
                  value: 'single',
                  groupValue: _recipientType,
                  onChanged: (value) {
                    setState(() => _recipientType = value!);
                  },
                ),
                const Text('لمستخدم واحد'),
              ],
            ),
            if (_recipientType == 'single')
              // ... (FutureBuilder for user selection dropdown/search)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
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
              child: _isSending ? const CircularProgressIndicator() : const Text('إرسال الإشعار'),
            ),
          ],
        ),
      ),
    );
  }
}