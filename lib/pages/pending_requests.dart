import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial_1/data/userdata.dart';
import 'package:trial_1/firebase_services/firebase_service.dart';

class pending_requests_page extends StatefulWidget {
  const pending_requests_page({super.key});

  @override
  State<pending_requests_page> createState() => _pending_requests_pageState();
}

class _pending_requests_pageState extends State<pending_requests_page> {
  Set<String> acceptedRequests = {}; // Track accepted requests

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pending Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(Userdata.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNoRequests();
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null || !userData.containsKey('pending-requests')) {
            return _buildNoRequests();
          }

          List<String> requests =
              List<String>.from(userData['pending-requests']);

          if (requests.isEmpty) {
            return _buildNoRequests();
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              String requestUser = requests[index];

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade300,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    requestUser,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: acceptedRequests.contains(requestUser)
                        ? Icon(Icons.check_circle,
                            color: Colors.green, key: ValueKey(1))
                        : IconButton(
                            key: ValueKey(2),
                            icon: Icon(Icons.person_add, color: Colors.teal),
                            onPressed: () {
                              firebase_service.accept_req(requestUser);
                              setState(() {
                                acceptedRequests.add(requestUser);
                              });
                            },
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoRequests() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 60, color: Colors.grey.shade500),
          SizedBox(height: 10),
          Text(
            "No pending requests",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
