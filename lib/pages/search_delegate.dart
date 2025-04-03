import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial_1/data/userdata.dart';
import 'package:trial_1/firebase_services/firebase_service.dart';
import 'package:get/get.dart';
import 'chatroom.dart';

class MySearchDelegate extends SearchDelegate<dynamic> {
  List<String> reqSent = [];

  @override
  String get searchFieldLabel => "Search user email...";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('Showing search results for: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text("Start typing to search users"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}z')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index].data() as Map<String, dynamic>;
            String username = user['username'].toString();
            String email = user['email'].toString();
            int ascii = username.isEmpty ? 0 : username.codeUnitAt(0);
            bool isAlreadyAdded = Userdata.contacts.contains(email) ||
                username == Userdata.username;
            bool isRequestSent = reqSent.contains(email);

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3, // Soft shadow effect
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 25, // Larger avatar
                    backgroundColor:
                        Colors.primaries[ascii % Colors.primaries.length],
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  title: Text(
                    Userdata.username == username
                        ? username + ' (Me)'
                        : username,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  subtitle: Text(
                    email,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: isAlreadyAdded
                      ? null
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: IconButton(
                            key: ValueKey(isRequestSent),
                            onPressed: () {
                              if (!isRequestSent) {
                                firebase_service.add_user(email);
                                reqSent.add(email);
                              }
                            },
                            icon: Icon(
                              isRequestSent
                                  ? Icons.check_circle
                                  : Icons.person_add,
                              color: isRequestSent
                                  ? Colors.green
                                  : Colors.blueAccent,
                              size: 28,
                            ),
                          ),
                        ),
                  onTap: () {
                    if (isAlreadyAdded && Userdata.email != email) {
                      Get.to(chatroom(friendmail: email));
                    } else {
                      close(context, user);
                    }
                  }),
            );
          },
        );
      },
    );
  }
}
