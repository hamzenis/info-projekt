import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/common/toast.dart';
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
      DocumentSnapshot userInfo =
          await _firestore.collection('Users').doc(_user!.uid).get();
      String registrationDate =
          await firestoreService.fetchRegistrationDate(_user!.uid);
      //if (userInfo.exists) {
      setState(() {
        _email = _user!.email;
        _registrationDate = registrationDate;
      });
    } // else {
    setState(() {
      _email = _user!.email;
      _registrationDate = 'No registration date found';
      //});
      //}
    });
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
                        SnackBar(
                          content: const Text('Password changed succesfully!'),
                          duration: const Duration(seconds: 3),
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
                  decoration: const InputDecoration(labelText: 'Old Email'),
                  onChanged: (value) => oldEmail = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'New Email'),
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
                      title: const Text('Confirm With Password'),
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
    String? password;
    bool _passwordVisible = true;

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
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile deleted succesfully'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

/*
  Future<void> _deleteProfileDialog(BuildContext context) async {
    bool deleteConfirmed = false;
    String? password;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm With Password'),
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
                  if (_user != null && password != null) {
                    // Create a credential using the user's email and password
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: _user!.email!,
                      password: password!,
                    );

                    // Re-authenticate the user using the credential
                    await _user!.reauthenticateWithCredential(credential);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Your profile has been deleted succesfully.'),
                        duration: Duration(seconds: 3),
                      ),
                    );

                    await _auth.signOut();

                    Navigator.of(context)
                        .pop(); // Close password confirmation dialog
                    Navigator.pushReplacementNamed(context, '/login');
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
  }
*/
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
                SizedBox(height: 40), // Spacing between buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                  ),
                  icon: Icon(Icons.arrow_back, size: 32),
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

/*
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
*/

/*

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => ProfilePage(),
      '/login': (context) => LoginPage(),
    },
  ));
}
*/

/*
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
*/
