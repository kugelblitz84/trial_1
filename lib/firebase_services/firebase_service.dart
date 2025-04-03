import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial_1/data/userdata.dart';

class firebase_service {
  static Future<String> create_user(
      String email, String password, String username, FirebaseAuth auth) async {
    try {
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'username': username,
        'email': email,
        'contacts': [],
        'active-status': true,
        'pending-requests': [],
      });

      print("userdata set for new user");
      await auth.signInWithEmailAndPassword(email: email, password: password);
      print('Userlogged in');
      return 'ok';
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  static Future<String> login_user(
      String email, String password, dynamic auth) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      print('user login called');
      //final n_auth = FirebaseAuth.instance.currentUser;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      print('user log-in called uid collected: ${uid}');
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'active-status': true});

      return 'ok';
      //Get.off(() => ChatPage());
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }

  static Future<void> logout(dynamic auth) async {
    try {
      final uid = await FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'active-status': false});
      await FirebaseAuth.instance.signOut();
      print("user logged out");
    } on FirebaseAuthException catch (e) {
      print("error occured while logging out ${e}");
    }
  }

  static Future<void> set_userdata() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    final me = snapshot.data();

    if (me != null) {
      Userdata.username = me['username'] ?? 'no Data';
      Userdata.contacts = List<String>.from(me['contacts'] ?? []);
      Userdata.pending_requests =
          List<String>.from(me['pending-requests'] ?? []);
      Userdata.email = me['email'] ?? 'no Data';
      Userdata.img = 'pending';
      Userdata.uid = uid;
    } else {
      print('User document does not exist');
    }
  }

  static Future<void> add_user(String email) async {
    //print('ad user called');
    final userSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: email)
        .get();
    if (userSnapshot.docs.isNotEmpty) {
      final docId = userSnapshot.docs.first.id;
      final user = userSnapshot.docs.first.data();
      if (!user['pending-requests'].contains(Userdata.email)) {
        await FirebaseFirestore.instance.collection('Users').doc(docId).update({
          'pending-requests': FieldValue.arrayUnion([Userdata.email]),
        });
      }

      print('sent request successfully!');
    } else {
      print('User not found');
    }
  }

  static Future<void> accept_req(String req_email) async {
    //remove senders email from the pending requests and add it to the contacts.
    final my_uid = Userdata.uid;
    final my_email = Userdata.email;
    await FirebaseFirestore.instance.collection('Users').doc(my_uid).update({
      'pending-requests': FieldValue.arrayRemove([req_email])
    });
    await FirebaseFirestore.instance.collection('Users').doc(my_uid).update({
      'contacts': FieldValue.arrayUnion([req_email])
    });
    // add my email to the contacts of the user that sent the request,
    final snap = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: req_email)
        .get(); //finding the user with the email that sent the request
    final req_uid = snap.docs.first.id;
    await FirebaseFirestore.instance.collection('Users').doc(req_uid).update({
      'contacts': FieldValue.arrayUnion([my_email])
    }); //adding my_email to the contacts of the request sender;
    //creating a chatroom after accepting request
    final mails = [req_email, Userdata.email];
    mails.sort();
    final uid = mails.join();
    await FirebaseFirestore.instance
        .collection('chatroom')
        .doc(uid)
        .collection('messages')
        .add({
      'message': 'Communication available',
      'From': 'system',
      'at': FieldValue.serverTimestamp()
    });
  }

  static Future<void> send_message(String msg, String uid, String from) async {
    await FirebaseFirestore.instance
        .collection('chatroom')
        .doc(uid)
        .collection('messages')
        .add(
            {'message': msg, 'From': from, 'at': FieldValue.serverTimestamp()});
  }

  static Future<void> unfriend(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: email)
        .get(); //finding the user with the email that need to unfriend
    final req_uid = snap.docs.first.id;
    await FirebaseFirestore.instance.collection('Users').doc(req_uid).update({
      'contacts': FieldValue.arrayRemove([Userdata.email])
    });
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(Userdata.uid)
        .update({
      'contacts': FieldValue.arrayRemove([email])
    });
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';

// class ChatroomService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// Searches for a chatroom that contains exactly the provided emails as participants.
//   /// Returns the chatroom document ID if found, otherwise returns null.
//   Future<String?> findChatroomByParticipants(List<String> emails) async {
//     // Sort emails to ensure consistent comparison regardless of order
//     final List<String> sortedEmails = [...emails]..sort();
    
//     try {
//       // Get all chatroom documents
//       final QuerySnapshot chatroomSnapshot = 
//           await _firestore.collection('chatroom').get();
      
//       // Iterate through each chatroom document
//       for (final DocumentSnapshot chatroomDoc in chatroomSnapshot.docs) {
//         // Get the participants document inside this chatroom
//         final DocumentSnapshot participantsDoc = 
//             await _firestore.collection('chatroom')
//                   .doc(chatroomDoc.id)
//                   .collection('participants')
//                   .doc('participants')
//                   .get();
        
//         // Check if participants document exists and contains data
//         if (participantsDoc.exists && participantsDoc.data() != null) {
//           // Extract emails from the participants document
//           final Map<String, dynamic> data = participantsDoc.data() as Map<String, dynamic>;
          
//           // If data contains an array of emails
//           if (data.containsKey('emails') && data['emails'] is List) {
//             List<String> chatroomEmails = List<String>.from(data['emails']);
//             chatroomEmails.sort();
            
//             // Check if the emails list matches our search criteria
//             if (listEquals(chatroomEmails, sortedEmails)) {
//               return chatroomDoc.id;
//             }
//           }
//         }
//       }
      
//       // No matching chatroom found
//       return null;
//     } catch (e) {
//       print('Error searching for chatroom: $e');
//       return null;
//     }
//   }
  
//   /// Helper method to compare two lists for equality
//   bool listEquals<T>(List<T> list1, List<T> list2) {
//     if (list1.length != list2.length) return false;
    
//     for (int i = 0; i < list1.length; i++) {
//       if (list1[i] != list2[i]) return false;
//     }
    
//     return true;
//   }
// }

// // Example usage
// void searchForChatroom() async {
//   final ChatroomService chatroomService = ChatroomService();
  
//   // Emails to search for
//   final List<String> searchEmails = [
//     'user1@example.com',
//     'user2@example.com',
//     'user3@example.com'
//   ];
  
//   final String? chatroomId = await chatroomService.findChatroomByParticipants(searchEmails);
  
//   if (chatroomId != null) {
//     print('Found chatroom with ID: $chatroomId');
//     // You can navigate to this chatroom or perform other actions
//   } else {
//     print('No chatroom found with these participants. You may want to create a new one.');
//   }
// }