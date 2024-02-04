import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          return null;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> updateIban(String iban, String? documentID) async {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(documentID)
        .update({"iban": iban});
  }

  bool checkIban(String iban) {
    // IBAN has to have 22 characters in germany, staying with german IBAN
    //for simplicity reasons.
    //Algoritm: https://en.wikipedia.org/wiki/International_Bank_Account_Number#Algorithms
    if (iban.length != 22) {
      return false;
    }

    //"Move the four initial characters to the end of the string"
    String moveIban = iban.substring(4) + iban.substring(0, 4);

    //"Replace each letter in the string with two digits, thereby expanding the string, where A = 10, B = 11, ..., Z = 35"
    String integerIban = moveIban.split('').map((char) {
      int code = char.codeUnitAt(0);
      return code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)
          ? (code - 'A'.codeUnitAt(0) + 10).toString()
          : char;
    }).join();

    // "Interpret the string as a decimal integer and compute the remainder of that number on division by 97"
    //Blöckeweise arbeiten, da Dart Integer Wertebereich nur von (-2^63) bis (2^63-1) geht
    int rest = 0;
    int blockSize = 9;
    for (int i = 0; i < integerIban.length; i += blockSize) {
      String block = rest.toString() +
          integerIban.substring(
              i,
              i + blockSize > integerIban.length
                  ? integerIban.length
                  : i + blockSize);
      rest = int.parse(block) % 97;
    }
    return rest == 1;
  }
}
