import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/users.dart';
import 'package:weddingcheck/views/auth/loginscreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // digunakan untuk menampilkan dan menyembunyikan password
  bool isHidden1 = true;
  bool isHidden2 = true;

  // textediting controller untuk control text ketika di input
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // buat global key untuk form
  final formKey = GlobalKey<FormState>();

  final db = DatabaseHelper();

  Future<void> register() async {
    if (formKey.currentState!.validate()) {
      try {
        // Fetch the id_role for 'pegawai'
        var roleResult = await db.getRoleByName('pegawai');
        int id_role = roleResult != null
            ? roleResult['id_role']
            : 2; // Default to 2 if not found

        final response = await http.post(
          Uri.parse('${db.baseUrl}/register.php'),
          body: {
            'usrName': usernameController.text,
            'usrPassword': passwordController.text,
            'id_role': id_role.toString(),
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = _extractJson(response.body);
          if (data != null && data['success']) {
            _showSuccessDialog();
          } else {
            _showErrorDialog(data != null ? data['message'] : 'Unknown error');
          }
        } else {
          _showErrorDialog('Failed to connect to the server');
        }
      } catch (e) {
        print('Error during registration: $e');
        _showErrorDialog('An error occurred during registration');
      }
    }
  }

  Map<String, dynamic>? _extractJson(String responseBody) {
    try {
      final jsonStartIndex = responseBody.indexOf('{');
      if (jsonStartIndex != -1) {
        final jsonString = responseBody.substring(jsonStartIndex);
        return json.decode(jsonString);
      }
    } catch (e) {
      print('Error extracting JSON: $e');
    }
    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registration Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registration Successful'),
          content: Text(
              'Account created successfully. Please wait for admin verification.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(),
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.black : Colors.white;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'lib/assets/image/icon.png',
            ), // Background image
            fit: BoxFit.fitWidth, // Menyesuaikan lebar
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Form digunakan untuk controll textfield agar tidak kosong saat di input
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Text(
                        "REGISTER",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(
                        height: 35,
                      ),

                      // Username TextFormField
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Username tidak boleh kosong";
                          }
                          return null;
                        },
                        controller: usernameController,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Username",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          prefixIcon: Icon(Icons.person),
                          filled: true, // Set to true to enable filling color
                          fillColor: textColor.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                      ),

                      // Password TextFormField
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password tidak boleh kosong";
                          }
                          return null;
                        },
                        controller: passwordController,
                        autocorrect: false,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          labelText: "Password",
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  isHidden1 = !isHidden1;
                                },
                              );
                            },
                            icon: Icon(
                              isHidden1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          prefixIcon: Icon(Icons.vpn_key),
                          filled: true, // Set to true to enable filling color
                          fillColor: textColor.withOpacity(0.8),
                        ),
                        textInputAction: TextInputAction.next,
                        obscureText: isHidden1,
                      ),
                      SizedBox(
                        height: 18,
                      ),

                      // Confirm Password TextFormField
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Konfirmasi password tidak boleh kosong";
                          } else if (passwordController.text !=
                              confirmPasswordController.text) {
                            return "Password tidak sama";
                          }
                          return null;
                        },
                        controller: confirmPasswordController,
                        autocorrect: false,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          labelText: "Confirm Password",
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  isHidden2 = !isHidden2;
                                },
                              );
                            },
                            icon: Icon(
                              isHidden2
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          prefixIcon: Icon(Icons.lock),
                          filled: true, // Set to true to enable filling color
                          fillColor: textColor.withOpacity(0.8),
                        ),
                        textInputAction: TextInputAction.done,
                        obscureText: isHidden2,
                      ),
                      SizedBox(
                        height: 35,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                register();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              "Register",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Login(),
                                ),
                              );
                            },
                            child: Text("Login"),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
