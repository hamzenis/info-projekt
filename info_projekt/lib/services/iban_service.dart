import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';

class IbanService {
  Future<String?> fetchIban() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDocument = querySnapshot.docs.first;
          String? iban = userDocument.get('iban');
          return iban;
        } else {
          print('No matching document found for the current user.');
          return null;
        }
      } catch (e) {
        print('Error fetching iban: $e');
        return null;
      }
    }
  }

  User? user = FirebaseAuth.instance.currentUser;

  Future<void> updateIban(String iban, String? documentID) async {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(documentID)
        .update({"iban": iban});
  }
}
