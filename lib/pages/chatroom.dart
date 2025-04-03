import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial_1/data/userdata.dart';
import 'package:trial_1/firebase_services/firebase_service.dart';
import 'package:get/get.dart';

class chatroom extends StatefulWidget {
  final String friendmail;

  chatroom({super.key, required this.friendmail});

  @override
  State<chatroom> createState() => _chatroomState();
}

class _chatroomState extends State<chatroom> {
  bool loading = true;
  late String friend_username = "Unknown";
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getFriendData();
  }

  Future<void> getFriendData() async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: widget.friendmail)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      final user = userSnapshot.docs.first.data();
      setState(() {
        friend_username = user['username'];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mails = [widget.friendmail, Userdata.email];
    mails.sort();
    final uid = mails.join();

    return loading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: Text(friend_username),
              backgroundColor: Colors.teal,
              elevation: 5,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await firebase_service.unfriend(widget.friendmail);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Unfriend',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chatroom')
                        .doc(uid)
                        .collection('messages')
                        .orderBy('at', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No messages yet"));
                      }

                      var msgCollection = snapshot.data!.docs;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        itemCount: msgCollection.length,
                        itemBuilder: (context, index) {
                          var msg = msgCollection[index].data()
                              as Map<String, dynamic>;

                          bool isSentByMe =
                              msg['From'].toString() == Userdata.username;

                          return Align(
                            alignment: isSentByMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? Colors.teal.shade600
                                    : Colors.teal.shade100,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isSentByMe
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                  bottomRight: isSentByMe
                                      ? Radius.zero
                                      : const Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                msg['message'],
                                style: TextStyle(
                                  color:
                                      isSentByMe ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_controller.text.trim().isNotEmpty) {
                            firebase_service.send_message(
                                _controller.text.trim(),
                                uid,
                                Userdata.username);
                            _controller.clear();
                            _scrollToBottom();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
