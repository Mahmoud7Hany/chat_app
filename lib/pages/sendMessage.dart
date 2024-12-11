// // ignore_for_file: file_names

// import 'package:cloud_firestore/cloud_firestore.dart';

// // Firestore إرسال بيانات
// void sendMessage(
//     String messageContent, String senderName, String senderId) async {
//   CollectionReference messages =
//       FirebaseFirestore.instance.collection('messages');
//   await messages.add({
//     'message': messageContent,
//     'senderName': senderName,
//     'senderId': senderId,
//     'createdAt': FieldValue.serverTimestamp(),
//   });
// }
