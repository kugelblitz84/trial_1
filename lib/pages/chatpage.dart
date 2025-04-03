import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trial_1/firebase_services/firebase_service.dart';
import 'package:trial_1/pages/chatroom.dart';
import 'package:trial_1/pages/login.dart';
import 'package:trial_1/pages/search_delegate.dart';
import 'package:trial_1/pages/pending_requests.dart';
import 'package:trial_1/data/userdata.dart';
import 'package:get/get.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final auth = FirebaseAuth.instance;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      await firebase_service.set_userdata();
    } catch (e) {
      print('Error loading user data: $e');
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 210, 245, 243),
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                "App Menu",
                style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.teal),
              title: const Text('FRIEND REQUESTS'),
              onTap: () {
                Get.back();
                Get.to(pending_requests_page());
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('LOG-OUT'),
              onTap: () async {
                firebase_service.logout(auth);
                Get.off(login());
              },
            )
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Chats", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: MySearchDelegate());
            },
          ),
        ],
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(Userdata.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("Add users to start"));
                  }

                  var userData = snapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null || !userData.containsKey('contacts')) {
                    return const Center(child: Text("Add users to start"));
                  }

                  List<String> contacts =
                      List<String>.from(userData['contacts']);
                  if (contacts.isEmpty) {
                    return Text('No users yet, ${Userdata.email}');
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          tileColor: Colors.teal.shade100,
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Colors.teal),
                          ),
                          title: Text(
                            contacts[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing:
                              const Icon(Icons.message, color: Colors.teal),
                          onTap: () {
                            Get.to(chatroom(friendmail: contacts[index]));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
