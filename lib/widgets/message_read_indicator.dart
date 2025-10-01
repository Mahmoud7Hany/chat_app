import 'package:flutter/material.dart';

class MessageReadIndicator extends StatelessWidget {
  final bool isRead;
  
  const MessageReadIndicator({
    Key? key,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 16,
      color: isRead ? Colors.blue : Colors.grey,
    );
  }
}
