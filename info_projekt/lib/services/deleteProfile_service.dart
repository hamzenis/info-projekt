import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';

class DeleteProfile {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//Delete the user from the database (authentification and firestore)
//ince there is no option to delete all subcollections at once, they all need to be deleted
//seperately one after another

  Future<bool> deleteUser(String? documentID, String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    String? userEmail = user.email;
    if (userEmail == null) {
      return false;
    }

    AuthCredential credentials =
        EmailAuthProvider.credential(email: userEmail, password: password);
    await user.reauthenticateWithCredential(credentials);

    documentID ??= await FirestoreService().getDocumentId();
    if (documentID == null) {
      return false;
    }

    num balance = await FirestoreService().getUserBalance();

    var portfolioCollectionRef =
        _firestore.collection('Users').doc(documentID).collection('portfolio');
    var portfolioSnapshot = await portfolioCollectionRef.get();
    if (portfolioSnapshot.docs.isNotEmpty) {
      return false;
    }

    if (balance == 0) {
      List<String> subcollections = [
        'stock_transaction_history',
        'portfolio',
        'balance_history',
        'watchlist'
      ];
      for (String subcollection in subcollections) {
        var collectionRef = _firestore
            .collection('Users')
            .doc(documentID)
            .collection(subcollection);
        var snapshots = await collectionRef.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }
      }

      await _firestore.collection('Users').doc(documentID).delete();
      return true;
    } else {
      return false;
    }
  }
}
