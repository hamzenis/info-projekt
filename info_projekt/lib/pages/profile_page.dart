// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/iban_service.dart';
import 'package:info_projekt/views/stock_transaction_history_view.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/deleteProfile_service.dart';
import 'package:info_projekt/services/updateEmail_service.dart';

//this is the class that shows the contents of the user profile
//in the user profile, the user can change his IBAN, password and email,
//delete his profile and view his transaction history.
//it is also the place where the user can logout of the application.

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
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

//fetch information about the user from the database
  Future<void> _getUserInfo() async {
    _user = firebaseAuth.currentUser;

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

//exchange the old password with a new password
//new password can't be old password or empty, has to be 8 characters long
//contain uppercase and lowercase letters, at least one special character and a number
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
                    //new password can't be the same as old password or empty/null,
                    //must contain: uppercase and lowercase characters, special character, number
                    //must at least be 8 characters long
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
                            await firebaseAuth.signInWithEmailAndPassword(
                          email: _user!.email!,
                          password: oldPassword!,
                        );

                        User? user = userCredential.user;
                        if (user != null) {
                          await user.updatePassword(newPassword1!);
                          await firebaseAuth.signOut();

                          showToast(message: "Password changed successfully!");

                          Navigator.of(scaffoldKey.currentContext!).pop();
                          Navigator.of(scaffoldKey.currentContext!)
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

//exchange current email with a new email adress
//new email has to be confirmed via confirmation link (equivalent to sign in)
  Future<void> updateEmail(BuildContext context) async {
    String? newEmail;
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
                      onChanged: (value) => newEmail = value,
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

                      if (_user!.email == newEmail) {
                        showToast(
                            message:
                                "Old Email can't be the same as new Email");
                        return;
                      }

                      if (newEmail!.isEmpty) {
                        showToast(message: "Please provide a new Email");
                      }

                      AuthCredential credentials =
                          firestoreService.getCredentials(password!);
                      await _user!.reauthenticateWithCredential(credentials);

                      await _user!.updateEmail(newEmail!);

                      User? updatedUser = FirebaseAuth.instance.currentUser;
                      if (updatedUser != null &&
                          updatedUser.email == newEmail) {
                        await updatedUser.sendEmailVerification();

                        String? documentID =
                            await firestoreService.getDocumentId();
                        await updateservice.updateEmailFirestore(
                            newEmail!, documentID);

                        showToast(
                            message:
                                "Change successful, please verify your Email!");
                        await firebaseAuth.signOut();

                       
                        Navigator.of(scaffoldKey.currentContext!)
                            .pop(); 
                        Navigator.of(scaffoldKey.currentContext!)
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
                      showToast(message: "An error occurred: $e");
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

//save a new IBAN or update your current IBAN for wallet-operations
  Future<void> updateIban(BuildContext context) async {
    String? iban;
    bool passwordVisible = false;
    String? password;

    ibanservice.fetchIban().then((currentIban) async {
      if (currentIban == null || currentIban.isEmpty) {
        showToast(message: "Current IBAN cannot be fetched");
        return;
      }

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

                  Navigator.of(context).pop();

                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: const Text('Confirm with Password'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  /*const Text(
                                      'Please enter your current password to proceed:'),*/
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
                                  Navigator.of(context).pop();

                                  if (password == null || password!.isEmpty) {
                                    showToast(
                                        message: "Password cannot be empty");
                                    return;
                                  }

                                  try {
                                    User? user =
                                        FirebaseAuth.instance.currentUser;

                                    String? documentID =
                                        await firestoreService.getDocumentId();
                                    if (documentID == null) {
                                      showToast(message: "User Doc not found");
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
                                        message: "IBAN updated successfully");
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

//delete the user profile
//also deletes all data from the database (authentification and firestore)
  Future<void> deleteProfile(BuildContext context) async {
    bool deleteConf = false;
    String? password;
    bool passwordVisible = false;
    String? documentID = await firestoreService.getDocumentId();

    Future<bool> DeleteConf() async {
      return await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    title: const Text('Confirm with Password'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Are you sure?'),
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

    deleteConf = await DeleteConf();

    if (deleteConf == true) {
      try {
        bool userDeleted =
            await deleteservice.deleteUser(documentID, password!);
        if (userDeleted == true) {
          User? user = FirebaseAuth.instance.currentUser;
          await user!.delete();

          Navigator.of(scaffoldKey.currentContext!).pop();
          Navigator.of(scaffoldKey.currentContext!)
              .pushReplacementNamed('/login');
          showToast(message: "Profile deleted succesfully!");
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
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      fixedSize: const Size(140, 40),
      backgroundColor: const Color.fromARGB(255, 222, 214, 214),
      foregroundColor: const Color.fromARGB(255, 148, 32, 121),
    );

    // Placeholder text for the password
    //actual length should not be shown due to it being information about the length of the password
    String passwordPlaceholder = '********';

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 148, 32, 121),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _getUserInfo();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
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
                    const Spacer(),
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
            const SizedBox(height: 20),
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

            // Registration Date- and Delete Profile -Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today, color: Color(0xFFC33764)),
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
  if (iban == null ||
      iban.length < 4 ||
      iban.isEmpty ||
      iban == "No IBAN provided") {
    return 'No IBAN provided!';
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
