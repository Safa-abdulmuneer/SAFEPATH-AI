import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shecare/login.dart';

class UserChangePasswordPage extends StatefulWidget {
  const UserChangePasswordPage({super.key});

  @override
  State<UserChangePasswordPage> createState() => _UserChangePasswordPageState();
}

class _UserChangePasswordPageState extends State<UserChangePasswordPage> {
  TextEditingController oldCtrl = TextEditingController();
  TextEditingController newCtrl = TextEditingController();
  TextEditingController confirmCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _passwordMatch = true;

  @override
  void dispose() {
    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void _checkPasswordMatch() {
    if (newCtrl.text.isNotEmpty && confirmCtrl.text.isNotEmpty) {
      setState(() {
        _passwordMatch = newCtrl.text == confirmCtrl.text;
      });
    } else {
      setState(() {
        _passwordMatch = true;
      });
    }
  }

  Future<void> updatePassword() async {
    // Validate inputs
    if (oldCtrl.text.isEmpty) {
      showSnackBar("Please enter your current password");
      return;
    }

    if (newCtrl.text.isEmpty) {
      showSnackBar("Please enter a new password");
      return;
    }

    if (newCtrl.text.length < 6) {
      showSnackBar("New password must be at least 6 characters");
      return;
    }

    if (confirmCtrl.text.isEmpty) {
      showSnackBar("Please confirm your new password");
      return;
    }

    if (!_passwordMatch) {
      showSnackBar("New passwords don't match");
      return;
    }

    if (oldCtrl.text == newCtrl.text) {
      showSnackBar("New password must be different from old password");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String urls = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (urls.isEmpty) {
        showSnackBar("Backend URL missing");
        return;
      }

      var response = await http.post(
        Uri.parse("$urls/user_change_password/"),
        body: {
          'lid': lid,
          'old_password': oldCtrl.text,
          'new_password': newCtrl.text,
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        showSnackBar("Password changed successfully!", isError: false);
        // Clear form after successful update
        Future.delayed(const Duration(seconds: 1), () {
          oldCtrl.clear();
          newCtrl.clear();
          confirmCtrl.clear();
          setState(() {
            _passwordMatch = true;
          });
        });
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (ctx) => LoginPage()), (route) => false);
      } else {
        showSnackBar("Error: ${jsonData['message']}");
      }
    } catch (e) {
      showSnackBar("Connection error: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFE91E63),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Update your password",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose a strong password to keep your account secure",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.pink[100]!, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Current Password Field
                      _buildPasswordField(
                        controller: oldCtrl,
                        label: "Current Password",
                        hint: "Enter your current password",
                        isVisible: _showOldPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _showOldPassword = !_showOldPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // New Password Field
                      _buildPasswordField(
                        controller: newCtrl,
                        label: "New Password",
                        hint: "Enter new password",
                        isVisible: _showNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          "Must be at least 6 characters",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm New Password Field
                      _buildPasswordField(
                        controller: confirmCtrl,
                        label: "Confirm New Password",
                        hint: "Re-enter new password",
                        isVisible: _showConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                        onChanged: (_) => _checkPasswordMatch(),
                      ),
                      if (!_passwordMatch && confirmCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 14,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Passwords do not match",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_passwordMatch &&
                          newCtrl.text.isNotEmpty &&
                          confirmCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: Color(0xFFE91E63),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Passwords match",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            shadowColor: Colors.pink[200],
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_reset_outlined, size: 22),
                                    SizedBox(width: 10),
                                    Text("Update Password"),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Security Tips
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[50]!, Colors.purple[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink[100]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFFE91E63),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Password Security Tips",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF880E4F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip(
                      icon: Icons.check_circle_outline,
                      text: "Use at least 8 characters",
                      color: Color(0xFFE91E63),
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityTip(
                      icon: Icons.check_circle_outline,
                      text: "Include numbers and symbols",
                      color: Color(0xFFE91E63),
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityTip(
                      icon: Icons.check_circle_outline,
                      text: "Avoid common words or sequences",
                      color: Color(0xFFE91E63),
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityTip(
                      icon: Icons.check_circle_outline,
                      text: "Don't reuse old passwords",
                      color: Color(0xFFE91E63),
                    ),
                  ],
                ),
              ),

              // Note about logout
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFE91E63),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You may need to log in again on other devices after changing your password",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC2185B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF880E4F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.pink[50]!,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            onChanged: onChanged,
            style: TextStyle(color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                size: 22,
                color: Color(0xFFE91E63),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[500],
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
