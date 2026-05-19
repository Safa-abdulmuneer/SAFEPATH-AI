import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddIdeaPage extends StatefulWidget {
  const AddIdeaPage({super.key});

  @override
  State<AddIdeaPage> createState() => _AddIdeaPageState();
}

class _AddIdeaPageState extends State<AddIdeaPage> {
  TextEditingController ideaCtr = TextEditingController();
  File? selectedImage;
  bool _isSubmitting = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> submitIdea() async {
    if (ideaCtr.text.isEmpty) {
      showSnackBar("Please enter your idea");
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

      var uri = Uri.parse("$urls/myapp/add_idea/");
      var request = http.MultipartRequest("POST", uri);

      // text fields
      request.fields['lid'] = lid;
      request.fields['idea'] = ideaCtr.text;

      // image file
      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            selectedImage!.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      print(responseBody);

      var jsonData = json.decode(responseBody);

      if (jsonData['status'] == 'ok') {
        showSnackBar("Idea added successfully!", isError: false);
        // Clear form after successful submission
        Future.delayed(const Duration(seconds: 1), () {
          ideaCtr.clear();
          setState(() {
            selectedImage = null;
          });
          Navigator.pop(context); // Return to previous screen
        });
      } else {
        showSnackBar("Error: ${jsonData['message']}");
      }
    } catch (e) {
      showSnackBar("Connection error: $e");
      print("❌ Error: $e");
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
        backgroundColor: isError ? Colors.redAccent : Color(0xFFE91E63), // Pink for success
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
          "Share Your Idea",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFE91E63), // Pink app bar
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
                      "Share your thoughts",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F), // Dark pink
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Share innovative ideas, suggestions, or improvements to help our community grow",
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
                      // Idea Text Field
                      _buildTextField(
                        controller: ideaCtr,
                        label: "Your Idea",
                        hint: "Describe your idea in detail...",
                        icon: Icons.lightbulb_outline,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),

                      // Image Upload Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add Supporting Image (Optional)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF880E4F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.pink[200]!,
                                  width: 1.5,
                                ),
                                color: Colors.pink[50],
                                gradient: selectedImage == null
                                    ? LinearGradient(
                                  colors: [Colors.pink[50]!, Colors.pink[100]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                    : null,
                              ),
                              child: selectedImage == null
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 36,
                                    color: Color(0xFFE91E63),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Tap to add image",
                                    style: TextStyle(
                                      color: Color(0xFFC2185B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Supports better understanding",
                                    style: TextStyle(
                                      color: Colors.pink[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                                  : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          if (selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => selectedImage = null),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Remove image",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
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
                          onPressed: _isSubmitting ? null : submitIdea,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE91E63), // Pink button
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
                              Icon(Icons.upload_outlined, size: 22),
                              SizedBox(width: 10),
                              Text("Share Idea"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info Note
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
                        Icons.info_outline,
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
                            "Note:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF880E4F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your ideas will be shared with the community to foster innovation and collaboration. All suggestions are valuable and help us improve together!",
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

              // Additional Tips
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
                      Icons.tips_and_updates_outlined,
                      color: Color(0xFFE91E63),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tip: Adding a clear image makes your idea easier to understand",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
        const SizedBox(height: 10),
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
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 4,
            style: TextStyle(color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], height: 1.4),
              prefixIcon: maxLines == 1
                  ? Icon(icon, size: 22, color: Color(0xFFE91E63))
                  : null,
              prefixIconConstraints: maxLines == 1
                  ? null
                  : const BoxConstraints(minWidth: 0, minHeight: 0),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: maxLines == 1 ? 16 : 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}