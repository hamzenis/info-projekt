import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _user;

  String? _email;
  String? _registrationDate;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userInfo =
          await _firestore.collection('Users').doc(_user!.uid).get();
      if (userInfo.exists) {
        setState(() {
          _email = _user!.email;
          _registrationDate = userInfo['date'];
        });
      } else {
        setState(() {
          _email = _user!.email;
          _registrationDate = 'No registration date found';
        });
      }
    }
  }

  //PASSWORTVERWALTUNG FUNKTIONIERT! =)

  Future<void> _changePasswordDialog(BuildContext context) async {
    String? oldPassword;
    String? newPassword1;
    String? newPassword2;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Old Password'),
                  onChanged: (value) => oldPassword = value,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'New Password'),
                  onChanged: (value) => newPassword1 = value,
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Confirm New Password'),
                  onChanged: (value) => newPassword2 = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (oldPassword != null &&
                    newPassword1 != null &&
                    newPassword2 != null &&
                    newPassword1 == newPassword2) {
                  try {
                    UserCredential userCredential =
                        await _auth.signInWithEmailAndPassword(
                      email: _user!.email!,
                      password: oldPassword!, // Replace with user's password
                    );

                    User? user = userCredential.user;
                    if (user != null) {
                      await user.updatePassword(newPassword1!);
                      await _auth.signOut();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password changed succesfully!'),
                          duration: Duration(seconds: 3),
                        ),
                      );

                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } catch (e) {
                    print('Error: $e');
                    // Handle error - show error message or log
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Passwords do not match or are empty'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

//Emailverwaltung funktioniert noch nicht, im letzten Schritt gibt es Probleme;
//Die Aktion sei nicht zulässig in Firebase
  Future<void> _changeEmailDialog(BuildContext context) async {
    String? oldEmail;
    String? newEmail1;
    String? newEmail2;
    String? password;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Old Email'),
                  onChanged: (value) => oldEmail = value,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'New Email'),
                  onChanged: (value) => newEmail1 = value,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Confirm New Email'),
                  onChanged: (value) => newEmail2 = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (oldEmail != null &&
                    newEmail1 != null &&
                    newEmail2 != null &&
                    newEmail1 == newEmail2) {
                  // Close the first dialog
                  Navigator.of(context).pop();

                  // Show password confirmation dialog
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm With Password'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  'Please enter your current password to proceed:'),
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Password'),
                                obscureText: true,
                                onChanged: (value) => password = value,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close password confirmation dialog
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                if (_user != null && password != null) {
                                  // Create a credential using the user's email and password
                                  AuthCredential credential =
                                      EmailAuthProvider.credential(
                                    email: _user!.email!,
                                    password: password!,
                                  );

                                  // Re-authenticate the user using the credential
                                  await _user!
                                      .reauthenticateWithCredential(credential);

                                  // If re-authentication succeeds, update the email
                                  await _user!.updateEmail(newEmail1!);
                                  await _user!.sendEmailVerification();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Email changed successfully, please verify!'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );

                                  await _auth.signOut();

                                  Navigator.of(context)
                                      .pop(); // Close password confirmation dialog
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
                                }
                              } catch (e) {
                                print('Error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Emails do not match or are empty'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfileDialog(BuildContext context) async {
    bool deleteConfirmed = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Profile'),
          content: Text('Are you sure you want to delete your profile?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Delete profile logic here
                  await _firestore.collection('Users').doc(_user!.uid).delete();
                  await _user!.delete();
                  setState(() {
                    _email = null;
                    _registrationDate = null;
                  });
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  print('Error: $e');
                  // Handle error - show error message or log
                }
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_email ?? "Loading..."}',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 10), // Adjust the height as needed

                    Text(
                      'Registration Date:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_registrationDate ?? "Loading..."}',
                      style: TextStyle(fontSize: 15),
                    )
                  ],
                ),
                /*ElevatedButton(
                  onPressed: () => _changeEmailDialog(context),
                  child: Text('Change Email'),
                ),*/
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => _changeEmailDialog(context),
                  child: Text('Change Email'),
                ),
                ElevatedButton(
                  onPressed: () => _changePasswordDialog(context),
                  child: Text('Change Password'),
                ),
                ElevatedButton(
                  onPressed: () => _deleteProfileDialog(context),
                  child: Text('Delete Profile'),
                  //Hier muss generell noch eine Prüfung rein, ob offene Transaktionen o. Ä. bestehen
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Text('Login Page'),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => ProfilePage(),
      '/login': (context) => LoginPage(),
    },
  ));
}

//import 'dart:js_interop';
/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> accessCreationDate() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      await getUserCreationDate(userId);
    }
  }

  Future<void> getUserCreationDate(String userId) async {
    // Your logic to retrieve creation date from Firestore
    // ... (similar to the previous code provided)
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;
    String? userEmail = currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.blue, // Example color for the top section
            child: const Text(
              'User Profile: Work in Progress hihi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userEmail ?? 'Email not available',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/

//import 'dart:js_interop';
/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> accessCreationDate() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      await getUserCreationDate(userId);
    }
  }

  Future<void> getUserCreationDate(String userId) async {
    // Your logic to retrieve creation date from Firestore
    // ... (similar to the previous code provided)
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;
    String? userEmail = currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.blue, // Example color for the top section
            child: const Text(
              'User Profile: Work in Progress hihi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userEmail ?? 'Email not available',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
