import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';

class DeleteProfile {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//Es gibt keinen Befehl alle Subcollections auf einmal zu löschen, deswegen muss man es kompliziert machen
// und jede einzeln löschen
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
        'balance_history'
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

/*
  
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
  */
}
