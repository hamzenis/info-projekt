import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/iban_service.dart';
import 'package:info_projekt/views/stock_transaction_history_view.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/deleteProfile_service.dart';
import 'package:info_projekt/services/updateEmail_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirestoreService firestoreService = FirestoreService();
  DeleteProfile deleteservice = DeleteProfile();
  UpdateEmail updateservice = UpdateEmail();
  IbanService ibanservice = IbanService();

  late User? _user;
  String? _email;
  String? _registrationDate;
  String? _iban;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    _user = _auth.currentUser;

    if (_user != null) {
      String? registrationDate = await firestoreService.fetchRegistrationDate();
      String? iban = await ibanservice.fetchIban();
      setState(() {
        _email = _user!.email;
        _registrationDate = registrationDate;
        _iban = iban;
      });
    }
  }

  Future<void> updatePassword(BuildContext context) async {
    String? oldPassword;
    String? newPassword1;
    String? newPassword2;
    bool oldPasswordVisible = false;
    bool newPassword1Visible = false;
    bool newPassword2Visible = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Update password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Old password:',
                        suffixIcon: IconButton(
                          icon: Icon(
                            oldPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              oldPasswordVisible = !oldPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !oldPasswordVisible,
                      onChanged: (value) => oldPassword = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'New password:',
                        suffixIcon: IconButton(
                          icon: Icon(
                            newPassword1Visible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              newPassword1Visible = !newPassword1Visible;
                            });
                          },
                        ),
                      ),
                      obscureText: !newPassword1Visible,
                      onChanged: (value) => newPassword1 = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Confirm new password:',
                        suffixIcon: IconButton(
                          icon: Icon(
                            newPassword2Visible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              newPassword2Visible = !newPassword2Visible;
                            });
                          },
                        ),
                      ),
                      obscureText: !newPassword2Visible,
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
                    if (newPassword1!.contains(RegExp(r'[A-Z]')) &&
                        newPassword1!.contains(RegExp(r'[0-9]')) &&
                        newPassword1!.contains(RegExp(r'[a-z]')) &&
                        newPassword1!
                            .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) &&
                        newPassword1!.length >= 8 &&
                        oldPassword != null &&
                        newPassword1 != null &&
                        newPassword2 != null &&
                        oldPassword != newPassword1 &&
                        newPassword1 == newPassword2) {
                      try {
                        UserCredential userCredential =
                            await _auth.signInWithEmailAndPassword(
                          email: _user!.email!,
                          password: oldPassword!,
                        );

                        User? user = userCredential.user;
                        if (user != null) {
                          await user.updatePassword(newPassword1!);
                          await _auth.signOut();

                          showToast(message: "Password changed successfully!");

                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      } catch (e) {
                        showToast(message: "Current password is wrong");
                      }
                    } else {
                      if (newPassword1 != newPassword2) {
                        showToast(message: "Passwords do not match");
                      }
                      if (newPassword1!.isEmpty) {
                        showToast(message: "Please provide a new password");
                      }

                      if (newPassword2!.isEmpty) {
                        showToast(message: "Please repeat the new password");
                      }

                      if (oldPassword!.isEmpty) {
                        showToast(message: "Please provide your old password");
                      }

                      if ((newPassword1 == newPassword2) &&
                          (newPassword1 == oldPassword)) {
                        showToast(
                            message:
                                "New password can't be the same as old password");
                      }

                      if (!(newPassword1!.contains(RegExp(r'[A-Z]')) &&
                          newPassword1!.contains(RegExp(r'[0-9]')) &&
                          newPassword1!.contains(RegExp(r'[a-z]')) &&
                          newPassword1!
                              .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))) {
                        showToast(
                            message:
                                "Password must be at least 8 characters long and include at least one uppercase letter, one number, and one special character");
                      }
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateEmail(BuildContext context) async {
    String? newEmail1;
    String? password;
    bool passwordVisible = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Align(
                alignment: Alignment.center,
                child: Text('Update Email'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'New Email:'),
                      onChanged: (value) => newEmail1 = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !passwordVisible,
                      onChanged: (value) => password = value,
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
                    try {
                      if (password == null || password!.isEmpty) {
                        showToast(message: "Password cannot be empty");
                        return;
                      }

                      if (_user!.email == newEmail1) {
                        showToast(
                            message:
                                "Old Email can't be the same as new Email");
                        return;
                      }

                      if (newEmail1!.isEmpty) {
                        showToast(message: "Please provide a new Email");
                      }

                      AuthCredential credentials =
                          firestoreService.getCredentials(password!);
                      await _user!.reauthenticateWithCredential(credentials);

                      await _user!.updateEmail(newEmail1!);

                      User? updatedUser = FirebaseAuth.instance.currentUser;
                      if (updatedUser != null &&
                          updatedUser.email == newEmail1) {
                        await updatedUser.sendEmailVerification();

                        String? documentID =
                            await firestoreService.getDocumentId();
                        await updateservice.updateEmailFirestore(
                            newEmail1!, documentID);

                        showToast(
                            message:
                                "Change successful, please verify your Email!");

                        await _auth.signOut();

                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'wrong-password') {
                        showToast(
                            message: "Incorrect password, please try again");
                      } else {
                        showToast(message: "An error occurred: ${e.message}");
                      }
                    } catch (e) {
                      showToast(message: "An unexpected error occurred: $e");
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateIban(BuildContext context) async {
    String? iban;
    bool passwordVisible = false;
    String? password;

    ibanservice.fetchIban().then((currentIban) async {
      // Perform your IBAN checks here
      if (currentIban == null || currentIban.isEmpty) {
        showToast(message: "Current IBAN not available");
        return;
      }

      // Show the dialog
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update IBAN'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'New IBAN:'),
                    onChanged: (value) => iban = value,
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
                  if (iban == null || iban!.isEmpty) {
                    showToast(message: "IBAN cannot be empty");
                    return;
                  }

                  if (iban == currentIban) {
                    showToast(
                        message: "New IBAN can't be the same as old IBAN");
                    return;
                  }

                  if (!ibanservice.checkIban(iban!)) {
                    showToast(message: "IBAN is not valid");
                    return;
                  }

                  // Close the IBAN dialog
                  Navigator.of(context).pop();

                  // Show password confirmation dialog
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: const Text('Confirm With Password'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          passwordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            passwordVisible = !passwordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    obscureText: !passwordVisible,
                                    onChanged: (value) => password = value,
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
// Close the password confirmation dialog
                                  Navigator.of(context).pop();
// Check if password is null or empty
                                  if (password == null || password!.isEmpty) {
                                    showToast(
                                        message: "Password cannot be empty.");
                                    return;
                                  }

                                  try {
                                    // Assuming _user is a valid Firebase User instance
                                    User? _user =
                                        FirebaseAuth.instance.currentUser;

                                    // Assuming firestoreService and ibanservice are defined and properly initialized
                                    String? documentID =
                                        await firestoreService.getDocumentId();
                                    if (documentID == null) {
                                      showToast(
                                          message: "User document not found.");
                                      return;
                                    }

                                    AuthCredential credentials =
                                        EmailAuthProvider.credential(
                                            email: _user!.email!,
                                            password: password!);

                                    await _user.reauthenticateWithCredential(
                                        credentials);
                                    await ibanservice.updateIban(
                                        iban!, documentID);
                                    showToast(
                                        message: "IBAN updated successfully!");
                                  } catch (e) {
                                    showToast(
                                        message: "Error updating IBAN: $e");
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          );
                        },
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
    }).catchError((error) {
      showToast(message: "Error fetching IBAN: $error");
    });
  }

  Future<void> deleteProfile(BuildContext context) async {
    bool deleteConfirmed = false;
    String? password;
    bool passwordVisible = false;
    String? documentID = await firestoreService.getDocumentId();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to manage state inside the dialog
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Confirm With Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Are you sure you want to delete your profile? If so, enter your password:'),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !passwordVisible,
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
                      bool userDeleted =
                          await deleteservice.deleteUser(documentID, password!);
                      if (userDeleted) {
                        await _user!.delete();
                        setState(() {
                          _email = null;
                          _registrationDate = null;
                        });
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/login');
                        showToast(message: "Profile deletetion succesfully!");
                        /*ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile deleted'),
                            duration: Duration(seconds: 3),
                          ),
                        ); */
                      } else {
                        // Handle the case when the user is not deleted
                        showToast(
                            message:
                                "Profile not deleted. Check balance and open transactions.");
                        /*ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Profile could not be deleted, check Balance and Open Transactions'),
                            duration: Duration(seconds: 3),
                          ),
                        ); */
                      }
                    } catch (e) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Button style for uniform size
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      fixedSize: const Size(140, 40), // Set your desired width and height
    );

    // Placeholder for password representation. Adjust the number of asterisks as needed.
    String passwordPlaceholder = '********';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction History and Show Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history), // Transaction History icon
                    SizedBox(width: 8),
                    Text(
                      'Transaction History',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OwnedStocksPage()),
                    );
                  },
                  child: const Text('Show'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email and Update Email Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email), // Email icon
                    const SizedBox(width: 8),
                    Text(
                      _email ?? 'No email found!',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => updateEmail(context),
                  child: const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Password and Update Password Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock), // Password icon
                    const SizedBox(width: 8),
                    Text(
                      passwordPlaceholder,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => updatePassword(context),
                  child: const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // IBAN and Update IBAN Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet), // IBAN icon
                    const SizedBox(width: 8),
                    Text(
                      _iban ?? 'No IBAN found!',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => updateIban(context),
                  child: const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Registration Date with "Delete Profile" Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons
                              .calendar_today), // Calendar icon for registration date
                          SizedBox(width: 8),
                          Text(
                            'Date of Registration:',
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      Text(
                        '        ' +
                            (_registrationDate ??
                                "No registration date found!"),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => deleteProfile(context),
                  child: const Text('Delete Profile'),
                ),
              ],
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, "/login");
                showToast(message: "Successfully signed out");
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
