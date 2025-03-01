// ignore_for_file: file_names, library_private_types_in_public_api, use_super_parameters

import 'package:chat/pages/chatPrivate/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// صفحه عرض جميع المستخدمين علشان اقدر اتواصل معهم خاص
class AllUsersPage extends StatefulWidget {
  const AllUsersPage({Key? key}) : super(key: key);

  @override
  _AllUsersPageState createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع المستخدمين'),
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'ابحث عن مستخدم...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.where((doc) {
                  var username =
                      (doc['username'] ?? '').toString().toLowerCase();
                  return username.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index].data() as Map<String, dynamic>;
                    var userId = users[index].id;
                    bool isAdmin = user['isAdmin'] ?? false;
                    bool isVerified = user['isVerified'] ?? false;
                    String username = user['username'] ?? 'مستخدم مجهول';
                    String? profilePic = user['profilePic'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profilePic != null
                            ? NetworkImage(profilePic)
                            : null,
                        child: profilePic == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(username,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (isVerified)
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 16),
                          if (isAdmin)
                            const Icon(Icons.admin_panel_settings,
                                color: Colors.orange, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(userId: userId)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
