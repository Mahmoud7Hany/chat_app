// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PrivateChatPage.dart';

// الصفحة الشخصية
class ProfilePage extends StatelessWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  // دالة لإنشاء معرف فريد للدردشة الخاصة بناءً على معرفي المستخدمين
  String _generateChatId(String uid1, String uid2) {
    return (uid1.compareTo(uid2) < 0) ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    // استخدام ألوان الثيم الخاص بالتطبيق مع إضافة لون ثانوي لتدرج أنيق
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final gradientColors = [primaryColor, accentColor];

    return Scaffold(
      extendBodyBehindAppBar:
          true, // تأثير عصري بتمديد الخلفية خلف شريط العنوان
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String username = userData['username'] ?? 'مستخدم مجهول';
          String? profilePic = userData['profilePic'];
          bool isAdmin = userData['isAdmin'] ?? false;
          bool isVerified = userData['isVerified'] ?? false;

          return SingleChildScrollView(
            child: Column(
              children: [
                // هيدر بتدرج لوني مع حواف منحنية أسفل الصفحة
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    // صورة الملف الشخصي مع تأثير الظل وحواف منحنية وإضافة بادج يظهر أول حرف من اسم المستخدم
                    Positioned(
                      bottom:
                          -50, // رفع الصورة للأعلى قليلاً مقارنةً بالتصميم السابق
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            // حاوية للصورة مع تأثير حدود متدرجة لإضفاء لمسة جمالية
                            Container(
                              padding: const EdgeInsets.all(4), // سمك الحدود
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.orange, Colors.pink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.white,
                                backgroundImage: profilePic != null
                                    ? NetworkImage(profilePic)
                                    : null,
                                // في حالة عدم وجود صورة، يتم عرض أول حرف من اسم المستخدم بخط واضح
                                child: profilePic == null
                                    ? Text(
                                        username.isNotEmpty
                                            ? username[0].toUpperCase()
                                            : "",
                                        style: TextStyle(
                                          fontSize: 70,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            // بادج دائري صغير يظهر أول حرف من اسم المستخدم (حتى وإن كانت الصورة موجودة)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border:
                                      Border.all(color: primaryColor, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : "",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    height:
                        70), // تعديل المسافة بعد الصورة لتناسب التصميم المحدث
                // تفاصيل المستخدم مع مؤشرات التوثيق والصلاحيات
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isVerified)
                            Row(
                              children: const [
                                Icon(Icons.verified,
                                    color: Colors.blue, size: 24),
                                SizedBox(width: 4),
                                Text(
                                  'مُوثق',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          if (isAdmin)
                            Row(
                              children: const [
                                SizedBox(width: 10),
                                Icon(Icons.admin_panel_settings,
                                    color: Colors.orange, size: 24),
                                SizedBox(width: 4),
                                Text(
                                  'مشرف',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                        ],
                      ),
                      const SizedBox(height: 40),
                      // زر إرسال رسالة بتصميم عصري مع تأثير الرفع
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        onPressed: () async {
                          // الحصول على معرف المستخدم الحالي وإنشاء معرف الدردشة الخاصة
                          String currentUserId =
                              FirebaseAuth.instance.currentUser!.uid;
                          String chatId =
                              _generateChatId(currentUserId, userId);
                          DocumentReference chatDoc = FirebaseFirestore.instance
                              .collection('private_chats')
                              .doc(chatId);
                          DocumentSnapshot chatSnapshot = await chatDoc.get();
                          if (!chatSnapshot.exists) {
                            await chatDoc.set({
                              'users': [currentUserId, userId],
                              'lastMessage': '',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                          }
                          // الانتقال إلى صفحة الدردشة الخاصة
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateChatPage(
                                  chatId: chatId, otherUserId: userId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message, size: 28),
                        label: const Text(
                          "إرسال رسالة",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
