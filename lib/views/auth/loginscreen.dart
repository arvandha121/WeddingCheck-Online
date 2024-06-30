import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/users.dart';
import 'package:weddingcheck/app/provider/provider.dart';
import 'package:weddingcheck/views/homepage.dart';
import 'package:weddingcheck/views/auth/registerscreen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // digunakan untuk menampilkan dan menyembunyikan password
  bool isChecked = false;
  bool isHidden = true;
  bool isLogin = false; // Digunakan untuk login
  String loginErrorMessage = ""; // Pesan kesalahan login

  // textediting controller untuk control text ketika di input
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // buat global key untuk form
  final formKey = GlobalKey<FormState>();

  final db = DatabaseHelper();

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Login Error'),
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
          title: Text('Login Successful'),
          content: Text('Login berhasil'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
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

  // Function ini digunakan untuk button login
  login() async {
    if (formKey.currentState!.validate()) {
      var user = await db.login(
        Users(
          usrName: usernameController.text,
          usrPassword: passwordController.text,
          role: '',
        ),
      );

      if (user != null) {
        if (user.isVerified == 1) {
          Provider.of<UiProvider>(context, listen: false).setRole(user.role);

          // Jika checklist remember me then setRememberMe is true
          if (Provider.of<UiProvider>(context, listen: false).isChecked) {
            Provider.of<UiProvider>(context, listen: false).setRememberMe();
          }

          // Jika login berhasil maka akan menampilkan dialog sukses
          setState(() {
            _showSuccessDialog();
          });
        } else {
          setState(() {
            if (user.role == 'pegawai') {
              // Set error message for pegawai
              loginErrorMessage =
                  'Akun anda belum diverifikasi. Silakan hubungi admin.';
            } else {
              // Set general error message
              loginErrorMessage =
                  'Your account has not been verified by an admin. Please contact the admin for verification.';
            }
            isLogin = true;
            _showErrorDialog(loginErrorMessage);
          });
        }
      } else {
        // Jika salah, akan memunculkan message "Username atau Password salah"
        setState(() {
          loginErrorMessage = "Username atau Password salah";
          isLogin = true;
          _showErrorDialog(loginErrorMessage);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.black : Colors.white;
    Color fillColor = isDarkMode ? Colors.grey : Colors.grey;
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
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(
                        height: 35,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Username tidak boleh kosong";
                          }
                          return null;
                        },
                        controller: usernameController,
                        autocorrect: isHidden,
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
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password tidak boleh kosong";
                          }
                          return null;
                        },
                        controller: passwordController,
                        autocorrect: true,
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
                                  isHidden = !isHidden;
                                },
                              );
                            },
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          prefixIcon: Icon(Icons.vpn_key),
                          filled: true, // Set to true to enable filling color
                          fillColor: textColor.withOpacity(0.8),
                        ),
                        textInputAction: TextInputAction.done,
                        obscureText: isHidden,
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Consumer<UiProvider>(builder: (
                        context,
                        UiProvider notifier,
                        child,
                      ) {
                        return Row(
                          children: [
                            Checkbox(
                              value: notifier.isChecked,
                              onChanged: (value) => notifier.toggleCheck(),
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return fillColor; // Use appropriate color for dark mode
                                }
                                return fillColor.withOpacity(0.9);
                              }),
                              checkColor: isDarkMode
                                  ? Colors.white
                                  : Colors.white, // color of tick Mark
                            ),
                            Text(
                              'remember me?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        );
                      }),
                      SizedBox(
                        height: 15,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: Consumer<UiProvider>(builder: (
                            context,
                            UiProvider notifier,
                            child,
                          ) {
                            return ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Text(
                                "Login",
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Register(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              side: BorderSide(
                                color: Colors.green, // Warna outline
                              ),
                              backgroundColor:
                                  Colors.white, // Warna latar belakang
                            ),
                            child: Text(
                              "Register",
                              style: TextStyle(
                                color: Colors.green, // Warna teks
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),

                      // Digunakan untuk mentriger user dan password ketika salah masukkan users
                      isLogin ? const SizedBox() : const SizedBox(),
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
