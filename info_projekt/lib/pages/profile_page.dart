import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:intl/intl.dart';
//import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirestoreService firestoreService = FirestoreService();

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
      String? registrationDate = await firestoreService.fetchRegistrationDate();
      //if (userInfo.exists) {
      setState(() {
        _email = _user!.email;
        _registrationDate = registrationDate;
      });
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
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Old Password'),
                  onChanged: (value) => oldPassword = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'New Password'),
                  onChanged: (value) => newPassword1 = value,
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Confirm New Password'),
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
              child: const Text('Cancel'),
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
                        const SnackBar(
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
                    const SnackBar(
                      content: Text('Passwords do not match or are empty'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

//EMAILVERWALTUNG: FUNKTIONIERT!! =)

  Future<void> _changeEmailDialog(BuildContext context) async {
    String? oldEmail;
    String? newEmail1;
    String? password;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'New Email:'),
                  onChanged: (value) => newEmail1 = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Close the first dialog
                Navigator.of(context).pop();

                // Show password confirmation dialog
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                          'Confirm With Password! Be aware the change is permanent and you cannot log in with your old email anymore.'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                'Please enter your current password to proceed:'),
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Password'),
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
                          child: const Text('Cancel'),
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

                                String? documentID =
                                    await firestoreService.getDocumentId();

                                // Re-authenticate the user using the credential
                                await _user!
                                    .reauthenticateWithCredential(credential);

                                await firestoreService.updateEmailFirestore(
                                    newEmail1!, documentID);

                                // If re-authentication succeeds, update the email
                                await _user!.updateEmail(newEmail1!);
                                await _user!.sendEmailVerification();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
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
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfileDialog(BuildContext context) async {
    bool deleteConfirmed = false;
    String? password;
    bool _passwordVisible = true;
    String? documentID = await firestoreService.getDocumentId();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm With Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Are you sure you want to delete your profile? If so, enter your password:'),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await firestoreService.deleteUser(documentID);
                  await _user!.delete();
                  setState(() {
                    _email = null;
                    _registrationDate = null;
                  });
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/login');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile deleted'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('Error: $e');
                }
              },
              child: const Text('Save'),
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
        title: const Text('User Profile'),
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
                    const Text(
                      'Email:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_email',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 10), // Adjust the height as needed

                    const Text(
                      'Registration Date:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_registrationDate ?? "Loading..."}',
                      style: const TextStyle(fontSize: 15),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => _changeEmailDialog(context),
                  child: const Text('Change Email'),
                ),
                ElevatedButton(
                  onPressed: () => _changePasswordDialog(context),
                  child: const Text('Change Password'),
                ),
                ElevatedButton(
                  onPressed: () => _deleteProfileDialog(context),
                  child: const Text('Delete Profile'),
                ),
                const SizedBox(height: 40), // Spacing between buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 32),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 24),
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushNamed(context, "/login");
                    showToast(message: "Successfully signed out");
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
