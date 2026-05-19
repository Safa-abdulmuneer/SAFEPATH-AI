import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SendComplaintPage extends StatefulWidget {
  const SendComplaintPage({super.key});

  @override
  State<SendComplaintPage> createState() => _SendComplaintPageState();
}

class _SendComplaintPageState extends State<SendComplaintPage> {
  TextEditingController cmpCtrl = TextEditingController();
  String? selectedPolice;
  List policeList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = "";

  Future<void> loadPolice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String urls = prefs.getString('url') ?? '';

      if (urls.isEmpty) {
        setState(() {
          _errorMessage = "Backend URL missing";
          _isLoading = false;
        });
        return;
      }

      var resp = await http.get(Uri.parse("$urls/myapp/user_view_pink_police/"));
      var jsonData = json.decode(resp.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          policeList = jsonData['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load police list";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> sendComplaint() async {
    if (selectedPolice == null || selectedPolice!.isEmpty) {
      showSnackBar("Please select a police officer");
      return;
    }

    if (cmpCtrl.text.isEmpty) {
      showSnackBar("Please enter your complaint");
      return;
    }

    if (cmpCtrl.text.length < 10) {
      showSnackBar("Please provide more details (at least 10 characters)");
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
        Uri.parse("$urls/myapp/send_complaint/"),
        body: {
          'lid': lid,
          'police_id': selectedPolice!,
          'complaint': cmpCtrl.text,
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        showSnackBar("Complaint sent successfully!", isError: false);
        // Clear form after successful submission
        Future.delayed(const Duration(seconds: 1), () {
          cmpCtrl.clear();
          setState(() {
            selectedPolice = null;
          });
        });
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
  void initState() {
    super.initState();
    loadPolice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Send Complaint",
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
                      "File a Complaint",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Report issues or concerns directly to pink police officials for assistance",
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
                      // Police Selection
                      _buildPoliceDropdown(),
                      const SizedBox(height: 20),

                      // Complaint Field
                      _buildComplaintField(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${cmpCtrl.text.length}/500",
                            style: TextStyle(
                              fontSize: 12,
                              color: cmpCtrl.text.length > 500
                                  ? Colors.red[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : sendComplaint,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.report_outlined, size: 22),
                              SizedBox(width: 10),
                              Text("Submit Complaint"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Important Information
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
                child: Row(
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
                            "Important Information",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF880E4F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your complaint will be sent directly to the selected pink police officer. Provide clear and detailed information for better assistance. All complaints are confidential.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tips for Effective Complaint
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFE91E63),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Tips for Effective Complaints:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF880E4F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTip("Be specific about dates, times, and locations"),
                    _buildTip("Include relevant details and context"),
                    _buildTip("Remain factual and objective"),
                    _buildTip("Mention if there are any witnesses"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoliceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Pink Police Officer",
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
          child: _isLoading
              ? Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink[200]!, width: 1.5),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
              ),
            ),
          )
              : _errorMessage.isNotEmpty
              ? Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!, width: 1.5),
            ),
            child: Center(
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          )
              : InputDecorator(
            decoration: InputDecoration(
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
                Icons.person_pin_outlined,
                size: 22,
                color: Color(0xFFE91E63),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPolice,
                isExpanded: true,
                isDense: true,
                hint: Text(
                  "Choose an officer",
                  style: TextStyle(color: Colors.grey[400]),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_outlined,
                  color: Color(0xFFE91E63),
                ),
                items: policeList.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['id'].toString(),
                    child: Text(
                      p['officername'] ?? 'Unknown Officer',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPolice = value;
                  });
                },
              ),
            ),
          ),
        ),
        if (selectedPolice != null && policeList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Selected: ${policeList.firstWhere((p) => p['id'].toString() == selectedPolice, orElse: () => {})['officername'] ?? 'Unknown'}",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComplaintField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Complaint Details",
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
            controller: cmpCtrl,
            maxLines: 6,
            minLines: 4,
            maxLength: 500,
            style: TextStyle(color: Colors.grey[800]),
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Describe your complaint in detail...",
              hintStyle: TextStyle(color: Colors.grey[400], height: 1.4),
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
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFFE91E63),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}