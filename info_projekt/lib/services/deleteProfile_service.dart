import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';

class DeleteProfile {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //Es gibt keinen Befehl alle Subcollections auf einmal zu löschen, deswegen muss man es kompliziert machen
  Future<bool> deleteUser(String? documentID, String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    bool result;
    String? documentID = await FirestoreService().getDocumentId();
    num balance = await FirestoreService().getUserBalance();

    AuthCredential credentials =
        EmailAuthProvider.credential(email: user!.email!, password: password);
    await user.reauthenticateWithCredential(credentials);

    List<String> subcollections = [
      'stock_transaction_history',
      'portfolio',
      'balance_history'
    ];

    if (balance == 0) {
      for (String subcollection in subcollections) {
        var collectionRef = _firestore
            .collection('Users')
            .doc(documentID)
            .collection(subcollection);
        var snapshots = await collectionRef.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();

          await _firestore.collection('Users').doc(documentID).delete();
        }
      }
      result = true;
    } else {
      result = false;
    }
    return result;
  }
}
