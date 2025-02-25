import 'dart:async';
import 'package:flutter/material.dart';

class BanCountdownWidget extends StatefulWidget {
  final DateTime banUntil;
  final String? banReason;
  final VoidCallback onBanEnd;

  const BanCountdownWidget({
    Key? key,
    required this.banUntil,
    required this.onBanEnd,
    this.banReason,
  }) : super(key: key);

  @override
  State<BanCountdownWidget> createState() => _BanCountdownWidgetState();
}

class _BanCountdownWidgetState extends State<BanCountdownWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // مؤقت لتحديث واجهة العداد كل ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (DateTime.now().isAfter(widget.banUntil)) {
        // عند انتهاء الوقت، استدعاء دالة رفع الحظر
        widget.onBanEnd();
        timer.cancel();
      } else {
        // تحديث واجهة هذا الويجت فقط
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // حساب الوقت المتبقي
    final remaining = widget.banUntil.difference(DateTime.now());
    return Container(
      width: double.infinity,
      color: Colors.red[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تم حظرك من ارسال الرسائل.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          if (widget.banReason != null)
            Text(
              'السبب: ${widget.banReason}',
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            ),
          Text(
            'مدة الحظر المتبقية: ${_formatDuration(remaining)}',
            style: TextStyle(fontSize: 14, color: Colors.red[700]),
          ),
        ],
      ),
    );
  }
}
