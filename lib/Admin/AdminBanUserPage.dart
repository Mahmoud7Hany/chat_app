import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBanUserPage extends StatefulWidget {
  final String userId;
  const AdminBanUserPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AdminBanUserPage> createState() => _AdminBanUserPageState();
}

class _AdminBanUserPageState extends State<AdminBanUserPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  bool _isPermanent = false;
  bool _canViewMessages = true;

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

  Future<void> _banUser() async {
    if (!_isValidBanAction()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يجب إدخال سبب الحظر أو تحديد مدة الحظر.')),
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
      'canViewMessages': _canViewMessages,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حظر المستخدم بنجاح.')),
    );
  }

  Future<void> _unbanUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'isBanned': false,
      'banReason': null,
      'banUntil': null,
      'canViewMessages': true, // إعادة تمكين مشاهدة الرسائل افتراضيًا
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
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('المستخدم غير موجود.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          bool isBanned = userData['isBanned'] ?? false;
          String banReason = userData['banReason'] ?? 'لا يوجد سبب محدد';

          // إذا كان المستخدم محظورًا:
          if (isBanned) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'المستخدم محظور حالياً',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'سبب الحظر:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banReason,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _unbanUser,
                        icon: const Icon(Icons.lock_open),
                        label: const Text('إلغاء الحظر'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // إذا لم يكن محظورًا: (عرض خصائص الحظر)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'حظر المستخدم',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'سبب الحظر',
                        border: OutlineInputBorder(),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isPermanent,
                          onChanged: (value) {
                            setState(() => _isPermanent = value!);
                          },
                        ),
                        const Text('حظر دائم'),
                      ],
                    ),
                    if (!_isPermanent) ...[
                      const SizedBox(height: 16),
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
                              textDirection: TextDirection.rtl,
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
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minutesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'دقائق',
                                border: OutlineInputBorder(),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _secondsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'ثواني',
                                border: OutlineInputBorder(),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('السماح بمشاهدة الرسائل'),
                            value: _canViewMessages,
                            onChanged: (value) {
                              setState(() => _canViewMessages = value);
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _banUser,
                          icon: const Icon(Icons.block),
                          label: const Text('تأكيد الحظر'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('إلغاء'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
