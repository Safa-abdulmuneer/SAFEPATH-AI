import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditIdeaPage extends StatefulWidget {
  final int ideaId;
  final String currentIdea;
  final String? currentImageUrl;

  const EditIdeaPage({
    super.key,
    required this.ideaId,
    required this.currentIdea,
    this.currentImageUrl,
  });

  @override
  State<EditIdeaPage> createState() => _EditIdeaPageState();
}

class _EditIdeaPageState extends State<EditIdeaPage> {
  late TextEditingController _ideaController;
  bool _isSubmitting = false;
  bool _imageChanged = false;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _ideaController = TextEditingController(text: widget.currentIdea);
    _currentImageUrl = widget.currentImageUrl;
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _imageChanged = true;
        _removeImage = false;
      });
    }
  }

  Future<void> _updateIdea() async {
    if (_ideaController.text.trim().isEmpty) {
      _showSnackBar("Please enter your updated idea", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String url = sp.getString('url') ?? "";
      String lid = sp.getString('lid') ?? "";

      if (url.isEmpty) {
        _showSnackBar("Backend URL missing", isError: true);
        return;
      }

      var uri = Uri.parse("$url/myapp/edit_idea/");
      var request = http.MultipartRequest("POST", uri);

      // Add text fields
      request.fields['lid'] = lid;
      request.fields['idea_id'] = widget.ideaId.toString();
      request.fields['idea'] = _ideaController.text.trim();

      // If user wants to remove existing image
      if (_removeImage) {
        request.fields['remove_image'] = 'true';
      }

      // Add new image if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ),
        );
      }
      // If no new image selected but we have existing image, keep it
      else if (_currentImageUrl != null && !_removeImage) {
        request.fields['keep_image'] = 'true';
      }

      var streamedResponse = await request.send();
      var responseBody = await streamedResponse.stream.bytesToString();
      print(responseBody);

      var jsonData = json.decode(responseBody);

      if (jsonData['status'] == 'ok') {
        _showSnackBar("Idea updated successfully!", isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
            jsonData['message'] ?? "Failed to update idea",
            isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection error: $e", isError: true);
      print("❌ Error: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
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

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Edit Your Idea",
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
            controller: _ideaController,
            maxLines: 5,
            minLines: 4,
            style: TextStyle(color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: "Describe your idea in detail...",
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
              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Update Image (Optional)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF880E4F),
          ),
        ),
        const SizedBox(height: 12),

        // Show selected new image or current image
        if (_selectedImage != null)
          _buildImagePreview(_selectedImage!, isNew: true)
        else if (_currentImageUrl != null && !_removeImage)
          _buildNetworkImagePreview()
        else
          _buildImagePicker(),

        // Image actions
        if (_selectedImage != null || (_currentImageUrl != null && !_removeImage))
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                // Change Image Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.camera_alt_outlined, size: 20),
                    label: Text(_selectedImage != null ? "Change Image" : "Update Image"),
                  ),
                ),
                const SizedBox(width: 12),

                // Remove Image Button
                if (!_removeImage)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _removeImage = true;
                          _selectedImage = null;
                          _imageChanged = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.delete_outline, size: 20),
                      label: Text("Remove"),
                    ),
                  ),

                // Restore Image Button (only if removed)
                if (_removeImage && _currentImageUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _removeImage = false;
                          _imageChanged = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFFE91E63),
                        side: BorderSide(color: Color(0xFFE91E63)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.undo_outlined, size: 20),
                      label: Text("Restore"),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
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
          gradient: LinearGradient(
            colors: [Colors.pink[50]!, Colors.pink[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: Color(0xFFE91E63),
            ),
            const SizedBox(height: 10),
            Text(
              "Tap to update image",
              style: TextStyle(
                color: Color(0xFFC2185B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Optional - Update with a better image",
              style: TextStyle(
                color: Colors.pink[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image, {bool isNew = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.file(
            image,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Text(
                isNew ? "NEW" : "CURRENT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(
            _currentImageUrl!,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 180,
                color: Colors.pink[50],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                color: Colors.pink[50],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.pink[300],
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: Colors.pink[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Text(
                "CURRENT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Idea",
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
                      "Update your idea",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Refine and improve your idea to make it even better for the community",
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
                      _buildTextField(),
                      const SizedBox(height: 24),

                      // Image Section
                      _buildImageSection(),

                      const SizedBox(height: 32),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _updateIdea,
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
                              Icon(Icons.check_circle_outline, size: 22),
                              SizedBox(width: 10),
                              Text("Update Idea"),
                            ],
                          ),
                        ),
                      ),

                      // Cancel Button
                      if (!_isSubmitting)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text("Cancel"),
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
                            "Your updated idea will be visible to the community immediately. You can update the image, remove it, or keep the current one.",
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
            ],
          ),
        ),
      ),
    );
  }
}