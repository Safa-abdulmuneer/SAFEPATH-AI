import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:shecare/home_screen.dart';
import 'package:shecare/sign_up.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final unamecontroller = TextEditingController();
  final passcontroller = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background image with dark overlay
          Positioned.fill(
            child: Image.asset(
              'assets/pink.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // ✅ Scrollable content to prevent layout overflow
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      const Text(
                        'Welcome to',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'SafePath',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your safety, our priority',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 80),

                      // ✅ Login form container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: unamecontroller,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.email,
                                      color: Colors.pink),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: passcontroller,
                                obscureText: _isObscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.lock,
                                      color: Colors.pink),
                                  // 👇 add this eye button here
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.pink,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscure = !_isObscure;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 3) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            _send_data();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MyMySignupPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                          color: Colors.pink,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Function to send data
  void _send_data() async {
    setState(() => _isLoading = true);

    String username = unamecontroller.text.trim();
    String password = passcontroller.text;

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    print("hhhhhhhhhhhh$url");
    if (url.isEmpty) {
      Fluttertoast.showToast(msg: 'Please configure server settings first');
      setState(() => _isLoading = false);
      return;
    }

    final urls = Uri.parse('$url/user_login/');

    try {
      final response = await http.post(urls, body: {
        'username': username,
        'password': password,
      });

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String status = data['status'];
        String type = data['type'].toString();

        if (status == 'ok') {
          String lid = data['lid'].toString();
          await sh.setString("lid", lid);

          sh.setBool("isLogged", true);
          // Redirect based on type
          if (type == "user") {
            sh.setBool("isLogged", true);
            sh.setString('type', 'user');

            // Start background location update
            Timer.periodic(const Duration(seconds: 5), (timer) {
              updateLoc(lid);
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserHome()),
            );
          }

          Fluttertoast.showToast(
            msg: 'Welcome!',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Invalid credentials',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Network error: ${response.statusCode}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      Fluttertoast.showToast(
        msg: 'Connection failed',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // ✅ Update location function
  void updateLoc(String lid) async {
    SharedPreferences sh = await SharedPreferences.getInstance();

    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        String lat = position.latitude.toString();
        String lon = position.longitude.toString();

        await sh.setString('lat', lat);
        await sh.setString('lon', lon);

        String url = sh.getString('url') ?? '';
        final urls = Uri.parse('$url/updatelocation/');

        final response = await http.post(urls, body: {
          'lid': lid,
          'lat': lat,
          'lon': lon,
        });

        if (response.statusCode != 200) {
          debugPrint('Location update failed');
        }
      } catch (e) {
        debugPrint('Location error: $e');
      }
    } else {
      debugPrint('Location permission denied');
    }
  }
}
