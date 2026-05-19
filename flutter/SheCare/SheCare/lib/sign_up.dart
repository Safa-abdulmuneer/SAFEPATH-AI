import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shecare/login.dart';
import 'package:intl/intl.dart';

class MyMySignupPage extends StatefulWidget {
  const MyMySignupPage({super.key});

  @override
  State<MyMySignupPage> createState() => _MyMySignupPageState();
}

class _MyMySignupPageState extends State<MyMySignupPage> {
  String gender = "Male";
  File? uploadimage;
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController postController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  DateTime? selectedDob;

  // Validation error messages
  Map<String, String> validationErrors = {};

  @override
  void initState() {
    super.initState();

    // Add listeners to focus nodes to scroll when keyboard appears
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        // Delay to ensure keyboard is fully open
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    });

    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        // Delay to ensure keyboard is fully open
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for at least one uppercase
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }



  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) {
      return 'Blood group is required';
    }
    final validBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    if (!validBloodGroups.contains(value.toUpperCase())) {
      return 'Please enter a valid blood group (A+, A-, B+, B-, AB+, AB-, O+, O-)';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    if (selectedDob == null) {
      return 'Please select a valid date of birth';
    }
    final now = DateTime.now();
    final age = now.difference(selectedDob!).inDays ~/ 365;
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    if (age > 100) {
      return 'Please enter a valid date of birth';
    }
    return null;
  }

  bool _validateForm() {
    validationErrors.clear();

    // Validate all fields
    final nameError = _validateName(nameController.text);
    if (nameError != null) validationErrors['name'] = nameError;


    final phoneError = _validatePhone(phoneController.text);
    if (phoneError != null) validationErrors['phone'] = phoneError;

    final emailError = _validateEmail(emailController.text);
    if (emailError != null) validationErrors['email'] = emailError;

    final placeError = _validateRequiredField(placeController.text, 'Place');
    if (placeError != null) validationErrors['place'] = placeError;

    final postError = _validateRequiredField(postController.text, 'Post');
    if (postError != null) validationErrors['post'] = postError;

    final districtError =
        _validateRequiredField(districtController.text, 'District');
    if (districtError != null) validationErrors['district'] = districtError;

    final stateError = _validateRequiredField(pinController.text, 'PinCode');
    if (stateError != null) validationErrors['pin'] = stateError;




    final passwordError = _validatePassword(passwordController.text);
    if (passwordError != null) validationErrors['password'] = passwordError;

    final confirmPasswordError =
        _validateConfirmPassword(confirmpController.text);
    if (confirmPasswordError != null)
      validationErrors['confirmp'] = confirmPasswordError;



    setState(() {}); // Refresh UI to show validation errors

    return validationErrors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(children: [
            // Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFE3EC),
                      Color(0xFFFFC2D6),
                      Color(0xFFFF8FB1),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "SAFE PATH",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Welcome Text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Account,',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
                            'JOIN SAFE PATH!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your safety journey starts here',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Image with validation error
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: validationErrors.containsKey('photo')
                                        ? Colors.red
                                        : const Color(0xFFFF8FB1),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),

                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8FB1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),

                                ),
                              ),
                            ],
                          ),
                          if (validationErrors.containsKey('photo'))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                validationErrors['photo']!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'Add Profile Photo',
                      style: TextStyle(
                        color: const Color(0xFFFF8FB1),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildSectionHeader("Personal Information"),
                              _buildTextField(
                                  nameController, "Name", Icons.person, 'name'),

                              const SizedBox(height: 10),
                              _buildTextField(phoneController, "Phone Number",
                                  Icons.phone, 'phone'),
                              _buildTextField(emailController, "Email",
                                  Icons.email, 'email'),

                              _buildSectionHeader("Address Information"),
                              _buildTextField(placeController, "Place",
                                  Icons.location_on, 'place'),
                              _buildTextField(postController, "Post",
                                  Icons.local_post_office, 'post'),
                              _buildTextField(districtController, "District",
                                  Icons.map, 'district'),
                              _buildTextField(pinController, "Pincode",
                                  Icons.pin, 'pin'),

                              _buildSectionHeader("Security"),
                              _buildPasswordField(
                                  passwordController,
                                  "Password",
                                  Icons.lock,
                                  _passwordFocusNode,
                                  'password'),
                              _buildPasswordField(
                                  confirmpController,
                                  "Confirm Password",
                                  Icons.lock_outline,
                                  _confirmPasswordFocusNode,
                                  'confirmp'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Sign Up & Login
                    Container(
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _send_data,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8FB1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.2),
                              ),
                              child: const Text(
                                "SIGN UP",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginPage()),
                                  );
                                },
                                child: Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Add extra space at the bottom when keyboard is open
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? 300
                            : 0),
                  ],
                ),
              ),
            ),
          ]),
        ));
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      IconData icon, FocusNode focusNode, String fieldKey) {
    bool _obscureText = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: _obscureText,
                onChanged: (value) {
                  // Clear validation error when user starts typing
                  if (validationErrors.containsKey(fieldKey)) {
                    setState(() {
                      validationErrors.remove(fieldKey);
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Color(0xFFFF8FB1)),
                  prefixIcon: Icon(icon, color: const Color(0xFFFF8FB1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: validationErrors.containsKey(fieldKey)
                          ? Colors.red
                          : const Color(0xFFFF8FB1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: validationErrors.containsKey(fieldKey)
                          ? Colors.red
                          : const Color(0xFFFF8FB1),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: validationErrors.containsKey(fieldKey)
                          ? Colors.red
                          : const Color(0xFFFF8FB1),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFFFF8FB1),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              if (validationErrors.containsKey(fieldKey))
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    validationErrors[fieldKey]!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFFFF8FB1).withOpacity(0.3), width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFF8FB1),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, String fieldKey,
      {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: isPassword,
            onChanged: (value) {
              // Clear validation error when user starts typing
              if (validationErrors.containsKey(fieldKey)) {
                setState(() {
                  validationErrors.remove(fieldKey);
                });
              }
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Color(0xFFFF8FB1)),
              prefixIcon: Icon(icon, color: const Color(0xFFFF8FB1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: validationErrors.containsKey(fieldKey)
                      ? Colors.red
                      : const Color(0xFFFF8FB1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: validationErrors.containsKey(fieldKey)
                      ? Colors.red
                      : const Color(0xFFFF8FB1),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: validationErrors.containsKey(fieldKey)
                      ? Colors.red
                      : const Color(0xFFFF8FB1),
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (validationErrors.containsKey(fieldKey))
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                validationErrors[fieldKey]!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderRadio(String genderValue, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio(
        value: genderValue,
        groupValue: gender,
        onChanged: (value) {
          setState(() {
            gender = value.toString();
          });
        },
        activeColor: const Color(0xFFFF8FB1),
      ),
      title: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF8FB1)),
          const SizedBox(width: 5),
          Text(genderValue, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _send_data() async {
    // Validate form before sending data
    if (!_validateForm()) {
      return;
    }

    String uname = nameController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String place = placeController.text;
    String post = postController.text;
    String district = districtController.text;
    String pin = pinController.text;
    String password = passwordController.text;
    String confirmp = confirmpController.text;

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();

    final urls = Uri.parse('$url/user_registration');
    try {
      final response = await http.post(urls, body: {

        "name": uname,
        "phone": phone,
        "email": email,
        "place": place,
        "post": post,
        "district": district,
        "pin": pin,
        "password": password,
        "confirmp": confirmp,
      });

      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          Fluttertoast.showToast(
            msg: 'Registration Successful',
            backgroundColor: const Color(0xFFFF8FB1),
            textColor: Colors.white,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Registration Failed',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Network Error',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }


}
