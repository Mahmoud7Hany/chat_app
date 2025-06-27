// lib/pages/chatPrivate/ProfilePage.dart
// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PrivateChatPage.dart';

// الصفحة الشخصية
class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  String? _initialUsername;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        _initialUsername = userData['username'];
        _usernameController.text = _initialUsername ?? '';
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتحديث اسم المستخدم في Firestore
  Future<void> _updateUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المستخدم لا يمكن أن يكون فارغاً.')),
      );
      return;
    }
    if (_usernameController.text.trim() == _initialUsername) {
      setState(() {
        _isEditing = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'username': _usernameController.text.trim(),
      });
      setState(() {
        _initialUsername = _usernameController.text.trim();
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث اسم المستخدم بنجاح!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحديث اسم المستخدم. الرجاء المحاولة لاحقاً.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتنسيق Timestamp إلى String
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'غير متوفر';
    DateTime dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // دالة لإنشاء معرف فريد للدردشة الخاصة
  String _generateChatId(String uid1, String uid2) {
    return (uid1.compareTo(uid2) < 0) ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final gradientColors = [primaryColor, accentColor];
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر التعديل / الحفظ
          if (widget.userId == currentUserId)
            _isEditing
                ? IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check, color: Colors.greenAccent),
                    onPressed: _isLoading ? null : _updateUsername,
                    tooltip: 'حفظ التغييرات',
                  )
                : IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    tooltip: 'تعديل الملف الشخصي',
                  ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String username = userData['username'] ?? 'مستخدم مجهول';
          String? profilePic = userData['profilePic'];
          bool isAdmin = userData['isAdmin'] ?? false;
          bool isVerified = userData['isVerified'] ?? false;
          bool isOnline = userData['isOnline'] ?? false;
          bool profileUserIsBanned = userData['isBanned'] ?? false;

          // معلومات خاصة لا تظهر إلا للمستخدم نفسه
          String? userEmail = userData['email'];
          Timestamp? createdAt = userData['createdAt'];
          
          return SingleChildScrollView(
            child: Column(
              children: [
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    (Theme.of(context).primaryColor is MaterialColor)
                                        ? (Theme.of(context).primaryColor as MaterialColor).shade200
                                        : Theme.of(context).primaryColor.withOpacity(0.6),
                                    (Theme.of(context).primaryColor is MaterialColor)
                                        ? (Theme.of(context).primaryColor as MaterialColor).shade400
                                        : Theme.of(context).primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 75,
                                backgroundColor: Colors.white,
                                backgroundImage: profilePic != null
                                    ? NetworkImage(profilePic)
                                    : null,
                                child: profilePic == null
                                    ? Text(
                                        username.isNotEmpty ? username[0].toUpperCase() : "U",
                                        style: TextStyle(
                                          fontSize: 70,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOnline ? Colors.greenAccent : Colors.grey,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: Center(
                                  child: Icon(
                                    isOnline ? Icons.circle : Icons.circle_outlined,
                                    color: Colors.white,
                                    size: 18,
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
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      // حقل اسم المستخدم القابل للتعديل
                      if (_isEditing && widget.userId == currentUserId)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            controller: _usernameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'أدخل اسم المستخدم',
                              border: const UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryColor, width: 3),
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 5,
                        children: [
                          if (isVerified)
                            Chip(
                              avatar: const Icon(Icons.verified, color: Colors.blue),
                              label: const Text(
                                'مُوثق',
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide(color: Colors.blue.shade200),
                            ),
                          if (isAdmin)
                            Chip(
                              avatar: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                              label: const Text(
                                'مشرف',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.orange.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide(color: Colors.orange.shade200),
                            ),
                          Chip(
                            avatar: Icon(isOnline ? Icons.online_prediction : Icons.do_not_disturb_on_total_silence,
                                color: isOnline ? Colors.green : Colors.red),
                            label: Text(
                              isOnline ? 'متصل الآن' : 'غير متصل',
                              style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide(color: isOnline ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // //////////////////////////////////////////////////////
                      // قسم المعلومات الخاصة (يظهر فقط للمستخدم نفسه)
                      if (widget.userId == currentUserId)
                        Column(
                          children: [
                            Card(
                              margin: const EdgeInsets.only(top: 10),
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      icon: Icons.email_outlined,
                                      label: 'البريد الإلكتروني',
                                      value: userEmail ?? 'غير متوفر',
                                    ),
                                    const SizedBox(height: 15),
                                    _buildInfoRow(
                                      icon: Icons.calendar_today,
                                      label: 'تاريخ الإنشاء',
                                      value: _formatTimestamp(createdAt),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20), // مسافة بعد البطاقة
                          ],
                        ),
                      // //////////////////////////////////////////////////////
                      
                      const SizedBox(height: 20),
                      if (widget.userId == currentUserId)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'هذا هو ملفك الشخصي.',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        )
                      else if (profileUserIsBanned)
                        Card(
                          elevation: 4,
                          color: Colors.red.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.block, color: Colors.red.shade700, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  'هذا المستخدم محظور ولا يمكن مراسلته.',
                                  style: TextStyle(fontSize: 16, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: primaryColor.withOpacity(0.5),
                          ),
                          onPressed: () async {
                            String chatId = _generateChatId(currentUserId, widget.userId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivateChatPage(
                                    chatId: chatId, otherUserId: widget.userId),
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
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget مساعد لبناء صفوف المعلومات
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}