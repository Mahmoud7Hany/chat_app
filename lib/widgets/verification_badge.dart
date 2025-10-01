import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.verified,
        size: 16,
        color: Colors.blue,
      ),
    );
  }
}
