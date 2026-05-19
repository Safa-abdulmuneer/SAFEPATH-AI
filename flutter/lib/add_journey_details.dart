import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AddJourneyPage extends StatefulWidget {
  const AddJourneyPage({super.key});

  @override
  State<AddJourneyPage> createState() => _AddJourneyPageState();
}

class _AddJourneyPageState extends State<AddJourneyPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63), // Pink
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63), // Pink
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _saveJourney() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        throw Exception('Server configuration missing');
      }

      // Format date and time
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      String formattedTime = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';

      var response = await http.post(
        Uri.parse('$baseUrl/add_user_journey/'),
        body: {
          'fromplace': fromCtrl.text.trim(),
          'toplace': toCtrl.text.trim(),
          'date': formattedDate,
          'time': formattedTime,
          'lid': lid,
        },
      ).timeout(const Duration(seconds: 10));

      print('Response: ${response.body}');
      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journey added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Clear form
        fromCtrl.clear();
        toCtrl.clear();
        setState(() {
          selectedDate = null;
          selectedTime = null;
        });

        // Optional: Go back to previous page
        Navigator.pop(context, true);
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to add journey');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Journey',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.route_outlined,
                        size: 40,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Plan Your Journey',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your travel details for safety monitoring',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // From Place
                  _buildTextField(
                    controller: fromCtrl,
                    label: 'From Place',
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter starting point';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // To Place
                  _buildTextField(
                    controller: toCtrl,
                    label: 'To Place',
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter destination';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  _buildPickerField(
                    label: 'Journey Date',
                    icon: Icons.calendar_today_outlined,
                    value: selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(selectedDate!)
                        : null,
                    hint: 'Select date',
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 20),

                  // Time Picker
                  _buildPickerField(
                    label: 'Journey Time',
                    icon: Icons.access_time_outlined,
                    value: selectedTime != null
                        ? selectedTime!.format(context)
                        : null,
                    hint: 'Select time',
                    onTap: _selectTime,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveJourney,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Save Journey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              prefixIcon: Icon(icon, color: const Color(0xFFE91E63)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(color: Colors.pink[200]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFE91E63), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_outlined,
                  color: const Color(0xFFE91E63),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}