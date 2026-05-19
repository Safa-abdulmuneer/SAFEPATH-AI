import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shecare/home_screen.dart';
import 'package:shecare/login.dart';


class IpPage extends StatefulWidget {
  const IpPage({super.key});

  @override
  State<IpPage> createState() => _IpPageState();
}

class _IpPageState extends State<IpPage> {
  TextEditingController ipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 100),

              // Header
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Configuration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your server IP address to connect',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Input Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IP Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: ipController,
                      decoration: const InputDecoration(
                        hintText: '192.168.1.100',
                        prefixIcon: Icon(Icons.dns_rounded, color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an IP address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    String ip = ipController.text.trim();
                    SharedPreferences sh =
                        await SharedPreferences.getInstance();

                    // ✅ Save URL
                    await sh.setString("url", "http://$ip:6520");

                    // Feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Settings saved successfully'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );

                    // ✅ Read login state
                    bool logged = sh.getBool('isLogged') ?? false;
                    String? type = sh.getString('type');

                    print("LOGGED: $logged");
                    print("TYPE: $type");

                    // ✅ Correct navigation logic
                    if (logged) {
                      if (type == 'user') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => UserHome()),
                        );
                      }

                      else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginPage()),
                        );
                      }
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Help Text
              const Center(
                child: Text(
                  'Make sure your server is running on port 8000',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
