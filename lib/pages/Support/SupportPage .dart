import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// صفحه الدعم
class SupportPage extends StatelessWidget {
  final String email = "chatapp2245@gmail.com";

  const SupportPage({super.key}); // بريد الدعم

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=Support Request&body=Please describe your issue here', // نص مسبق للموضوع والجسم
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'لم نتمكن من إرسال البريد الإلكتروني';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تواصل مع الدعم'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان رئيسي
            const Text(
              'هل تحتاج إلى مساعدة؟',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'إذا واجهت أي مشكلات، فلا تتردد في التواصل معنا. نحن هنا لمساعدتك!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // بطاقة للتواصل
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.email,
                  color: Colors.blue,
                  size: 30,
                ),
                title: const Text(
                  'الدعم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('chatapp2245@gmail.com'),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: _sendEmail,
              ),
            ),

            const Spacer(),

            // زر آخر للتأكيد
            ElevatedButton.icon(
              onPressed: _sendEmail,
              icon: const Icon(Icons.email_outlined),
              label: const Text('إرسال البريد الإلكتروني الآن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
