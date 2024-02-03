// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/services/iban_service.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:info_projekt/views/stock_transaction_history_view.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/deleteProfile_service.dart';
import 'package:info_projekt/services/updateEmail_service.dart';
import 'package:provider/provider.dart';

import 'package:info_projekt/services/firebase_auth_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
                    if (newPassword1 == newPassword2 &&
                        newPassword1 != oldPassword &&
                        newPassword1 != null &&
                        newPassword1!.isNotEmpty &&
                        newPassword1!.contains(RegExp(r'[A-Z]')) &&
                        newPassword1!.contains(RegExp(r'[0-9]')) &&
                        newPassword1!.contains(RegExp(r'[a-z]')) &&
                        newPassword1!
                            .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) &&
                        newPassword1!.length >= 8) {
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

                          Navigator.of(_scaffoldKey.currentContext!).pop();
                          Navigator.of(_scaffoldKey.currentContext!)
                              .pushReplacementNamed('/login');
                        }
                      } catch (e) {
                        showToast(message: "Current password is wrong");
                      }
                    } else {
                      if (newPassword1 != newPassword2) {
                        showToast(message: "Passwords do not match");
                      } else if (newPassword1!.isEmpty) {
                        showToast(message: "Please provide a new password");
                      } else if (oldPassword!.isEmpty) {
                        showToast(message: "Please provide your old password");
                      } else if (newPassword1 == oldPassword) {
                        showToast(
                            message:
                                "New password can't be the same as old password");
                      } else {
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

                        // Use the current context from the scaffold key
                        Navigator.of(_scaffoldKey.currentContext!)
                            .pop(); // Close the dialog
                        Navigator.of(_scaffoldKey.currentContext!)
                            .pushReplacementNamed('/login');
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
                            title: const Text('Confirm With Password!'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                      'Please enter your current password to proceed:'),
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
                                    User? user =
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
                                            email: user!.email!,
                                            password: password!);

                                    await user.reauthenticateWithCredential(
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

    // Function to show the confirmation dialog
    Future<bool> showDeleteConfirmationDialog() async {
      return await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return StatefulBuilder(
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
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  );
                },
              );
            },
          ) ??
          false;
    }

    // Show the dialog and get the confirmation result
    deleteConfirmed = await showDeleteConfirmationDialog();

    // If delete is confirmed, proceed with the deletion logic
    if (deleteConfirmed) {
      try {
        bool userDeleted =
            await deleteservice.deleteUser(documentID, password!);
        if (userDeleted) {
          User? user = FirebaseAuth.instance.currentUser;
          await user!.delete();

          // Use the current context from the scaffold key
          Navigator.of(_scaffoldKey.currentContext!).pop(); // Close the dialog
          Navigator.of(_scaffoldKey.currentContext!)
              .pushReplacementNamed('/login');
          showToast(message: "Profile deletion successful!");
        } else {
          showToast(
              message:
                  "Profile not deleted. Check balance and open transactions.");
        }
      } catch (e) {
        showToast(message: "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Button style for uniform size
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      fixedSize: const Size(140, 40),
      backgroundColor: const Color(
          0xFF1D2671), // Deep blue from the credit card as button color
      foregroundColor: Colors.white, // Text color on the button for contrast
    );

    // Placeholder text for the password
    String passwordPlaceholder = '********';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title:
            const Text('User Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1D2671),
        iconTheme: const IconThemeData(
            color: Colors.white), // Deep blue from the credit card
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _getUserInfo();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100], // Light background color for contrast
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // Changed to ListView for better scrolling experience
          children: [
            // IBAN-Line (Credit Card Display)
            Container(
              margin: const EdgeInsets.only(
                  bottom: 20), // Adjusted margin for alignment
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D2671), Color(0xFFC33764)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 4,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacer(),
                    Text(
                      maskIban(_iban),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'IBAN Number',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () => updateIban(context),
              child: const Text('Update IBAN'),
            ),

            // Transaction-History-Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFFC33764)),
                    SizedBox(width: 8),
                    Text(
                      'Transaction History',
                      style: TextStyle(fontSize: 15, color: Color(0xFF1D2671)),
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

            //Email-Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email, color: Color(0xFFC33764)),
                    const SizedBox(width: 8),
                    Text(
                      maskEmail(_email),
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1D2671)),
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

            // Passwort-Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, color: Color(0xFFC33764)),
                    const SizedBox(width: 8),
                    Text(
                      passwordPlaceholder,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1D2671)),
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

            // Registration Date- und Profil-löschen-Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Color(
                                  0xFFC33764)), // Calendar icon for registration date
                          SizedBox(width: 8),
                          Text(
                            'Date of Registration:',
                            style: TextStyle(
                                fontSize: 15, color: Color(0xFF1D2671)),
                          ),
                        ],
                      ),
                      Text(
                        '        $_registrationDate',
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFF1D2671)),
                      ),
                    ],
                  ),
                  // Reset the PortfolioValueNotifier
                  // var portfolioValueNotifier =
                  //     Provider.of<PortfolioValueNotifier>(context,
                  //         listen: false);
                  // portfolioValueNotifier.reset();
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
                backgroundColor: const Color(0xFFC33764),
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    "/login", (Route<dynamic> route) => false);
                showToast(message: "Successfully signed out");
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Method to mask the IBAN number with dots and display the last 4 digits
String maskIban(String? iban) {
  if (iban == null || iban.length < 4) {
    return 'No IBAN found!';
  } else {
    String lastFourDigits = iban.substring(iban.length - 4);
    return '.. $lastFourDigits';
  }
}

// Method to mask the email with dots and display the last 9 characters
String maskEmail(String? email) {
  if (email == null) {
    return 'No email found!';
  } else if (email.length <= 25) {
    return email;
  } else {
    String firstFour = email.substring(0, 5);
    String lastNine = email.substring(email.length - 10);
    return '$firstFour...$lastNine';
  }
}
