// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// صفحه حظر المستخدم منعه من الكتابه
class AdminBanUserPage extends StatefulWidget {
  final String userId;

  const AdminBanUserPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AdminBanUserPage> createState() => _AdminBanUserPageState();
}

class _AdminBanUserPageState extends State<AdminBanUserPage> {
  final _reasonController = TextEditingController();
  final _daysController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  bool _isPermanent = false;

  bool _isValidBanAction() {
    if (_isPermanent) {
      return _reasonController.text.isNotEmpty;
    } else {
      int days = int.tryParse(_daysController.text) ?? 0;
      int hours = int.tryParse(_hoursController.text) ?? 0;
      int minutes = int.tryParse(_minutesController.text) ?? 0;
      int seconds = int.tryParse(_secondsController.text) ?? 0;

      return _reasonController.text.isNotEmpty ||
          days > 0 ||
          hours > 0 ||
          minutes > 0 ||
          seconds > 0;
    }
  }

  void _banUser() async {
    if (!_isValidBanAction()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إدخال سبب أو تحديد مدة الحظر.')),
      );
      return;
    }

    DateTime? banUntil;
    if (!_isPermanent) {
      int days = int.tryParse(_daysController.text) ?? 0;
      int hours = int.tryParse(_hoursController.text) ?? 0;
      int minutes = int.tryParse(_minutesController.text) ?? 0;
      int seconds = int.tryParse(_secondsController.text) ?? 0;

      banUntil = DateTime.now().add(Duration(
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      ));
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'isBanned': true,
      'banReason': _reasonController.text.isEmpty
          ? 'تم منعك من ارسال الرسائل'
          : _reasonController.text,
      'banUntil': _isPermanent ? null : banUntil,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حظر المستخدم بنجاح.')),
    );
  }

  void _unbanUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'isBanned': false,
      'banReason': null,
      'banUntil': null,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفع الحظر عن المستخدم.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحظر'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الحظر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isPermanent,
                  onChanged: (value) {
                    setState(() {
                      _isPermanent = value!;
                    });
                  },
                ),
                const Text('حظر دائم'),
              ],
            ),
            if (!_isPermanent)
              Column(
                children: [
                  const SizedBox(height: 16),
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأيام',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الساعات',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الدقائق',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الثواني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _banUser,
                  child: const Text('تأكيد الحظر'),
                ),
                ElevatedButton(
                  onPressed: _unbanUser,
                  child: const Text('إلغاء الحظر'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
