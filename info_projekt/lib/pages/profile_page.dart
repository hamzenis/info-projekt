// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/services/iban_service.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:info_projekt/views/stock_transaction_history_view.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/deleteProfile_service.dart';
import 'package:info_projekt/services/updateEmail_service.dart';
import 'package:provider/provider.dart';
import 'package:info_projekt/widgets/password_input_widget.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';

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
                    if (oldPassword != null &&
                        newPassword1 != null &&
                        newPassword2 != null &&
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
                        // Handle error - show error message or log
                      }
                    } else {
                      showToast(
                          message: "Passwords do not match or are empty.");
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

    // Store the context before showDialog
    BuildContext dialogContext = context;

    await showDialog(
      context: dialogContext,
      builder: (BuildContext context) {
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
                  decoration: const InputDecoration(labelText: 'New Email:'),
                  onChanged: (value) => newEmail1 = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the Email dialog

                // Show password confirmation dialog
                String? password = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PasswordDialog();
                  },
                );

                FirebaseAuthService auth = FirebaseAuthService();
                bool correctPassword = await auth.reauthenticateUser(password);

                // Update Email to Firestore
                if (correctPassword) {
                  try {
                    await _user!.updateEmail(newEmail1!);

                    User? updatedUser = FirebaseAuth.instance.currentUser;
                    if (updatedUser != null && updatedUser.email == newEmail1) {
                      await updatedUser.sendEmailVerification();

                      String? documentID =
                          await firestoreService.getDocumentId();
                      await updateservice.updateEmailFirestore(
                          newEmail1!, documentID);

                      showToast(
                          message:
                              "Change successful, please verify your Email!");

                      await _auth.signOut();
                    } else {
                      showToast(message: "Update failed!");
                    }
                    Navigator.pushReplacementNamed(dialogContext, '/login');
                    print("Login");
                  } catch (e) {
                    print(e);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateIban(BuildContext context) async {
    String? iban;

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
                // Close the IBAN dialog
                Navigator.of(context).pop();

                // Check if IBAN is null
                if (iban == null || iban!.isEmpty) {
                  showToast(message: "IBAN cannot be empty.");
                  return;
                }

                // Show password confirmation dialog
                String? password = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PasswordDialog();
                  },
                );
                FirebaseAuthService auth = FirebaseAuthService();
                bool correctPassword = await auth.reauthenticateUser(password);

                // Write new IBAN to Firestore
                if (correctPassword) {
                  try {
                    String? documentID = await firestoreService.getDocumentId();
                    await ibanservice.updateIban(iban!, documentID);
                    showToast(message: "IBAN updated successfully!");
                  } catch (e) {
                    print('Error: $e'); // TODO: DEBUG Remove
                    showToast(message: "Error updating IBAN: $e");
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                      print('Error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
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
                      '${_email ?? "No email found!"}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    //const SizedBox(height: 10), // Adjust the height as needed

                    const Text(
                      'Registration Date:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_registrationDate ?? "No registration date found!"}',
                      style: const TextStyle(fontSize: 15),
                    ),

                    const Text(
                      'IBAN:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_iban ?? "No IBAN found!"}',
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OwnedStocksPage()),
                    );
                  },
                  child: const Text('Stock Transaction History'),
                ),
                ElevatedButton(
                  onPressed: () => updateIban(context),
                  child: const Text('Update IBAN'),
                ),
                ElevatedButton(
                  onPressed: () => updateEmail(context),
                  child: const Text('Update Email'),
                ),
                ElevatedButton(
                  onPressed: () => updatePassword(context),
                  child: const Text('Update Password'),
                ),
                ElevatedButton(
                  onPressed: () => deleteProfile(context),
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
