import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shecare/home_screen.dart';


class Set_emergency_number extends StatefulWidget {
  const Set_emergency_number({super.key, required this.title});

  final String title;

  @override
  State<Set_emergency_number> createState() => _Set_emergency_numberState();
}

class _Set_emergency_numberState extends State<Set_emergency_number> {
  TextEditingController nameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController relationController = TextEditingController();

  List<String> id_ = [];
  List<String> name_ = [];
  List<String> number_ = [];
  List<String> relation_ = [];

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String urls = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';
      String url = '$urls/myapp/user_view_emergency_number/';

      var response = await http.post(Uri.parse(url), body: {'lid': lid});
      var jsonData = json.decode(response.body);
      var data = jsonData['data'];

      List<String> id = [];
      List<String> name = [];
      List<String> number = [];
      List<String> relation = [];

      for (var contact in data) {
        id.add(contact['id'].toString());
        name.add(contact['name'].toString());
        number.add(contact['number'].toString());
        relation.add(contact['relation'].toString());
      }

      setState(() {
        id_ = id;
        name_ = name;
        number_ = number;
        relation_ = relation;
      });
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE3EC),
      appBar: AppBar(

        backgroundColor: const Color(0xFFFFE3EC),

        title: Text(widget.title,style: TextStyle(color: Colors.black),),
        leading: IconButton(onPressed: (){
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx)=>UserHome()));
        }, icon: Icon(Icons.arrow_back,color: Colors.black,)),
        elevation: 1,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
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
        child: id_.isEmpty
            ? const Center(
          child: Text(
            "No Contacts Found",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        )
            : ListView.builder(
          itemCount: id_.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.pinkAccent,
                  child: Text(
                    name_[index][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  name_[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Number: ${number_[index]}"),
                    Text("Relation: ${relation_[index]}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editContact(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteContact(id_[index]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
        onPressed: _addContact,
      ),
    );
  }

  void _addContact() {
    _showContactDialog(isAdd: true);
    nameController.clear();
    numberController.clear();
    relationController.clear();
  }

  void _editContact(int index) {
    nameController.text = name_[index];
    numberController.text = number_[index];
    relationController.text = relation_[index];
    _showContactDialog(id: id_[index],isAdd: false);
  }

  void _deleteContact(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';
    final response = await http.post(
        Uri.parse('$url/myapp/delete_emergency_number/'),
        body: {'id': id});
    if (response.statusCode == 200 && jsonDecode(response.body)['status'] == 'ok') {
      Fluttertoast.showToast(msg: 'Contact Deleted Successfully');
      fetchContacts();
    } else {
      Fluttertoast.showToast(msg: 'Failed to Delete Contact');
    }
  }

  void _showContactDialog({String? id, required bool isAdd} ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        initialChildSize: 0.6,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: scrollController, // attach scrollController
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8FB1), Color(0xFFFFC2D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Emergency Contact',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a new emergency contact',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildTextFieldWithIcon(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    hintText: 'Enter full name',
                  ),
                  const SizedBox(height: 16),
                  _buildTextFieldWithIcon(
                    controller: numberController,
                    label: 'Phone Number',
                    icon: Icons.phone_iphone_rounded,
                    hintText: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFieldWithIcon(
                    controller: relationController,
                    label: 'Relationship',
                    icon: Icons.people_outline_rounded,
                    hintText: 'e.g., Parent, Friend, Spouse',
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                      onPressed: () {
          if (isAdd) {
          _addNewContact();
          } else {
          _updateContact(id!);
          }
          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8FB1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Add Contact'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFFFF8FB1),
                size: 22,
              ),
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _addNewContact() async {
    _saveContact();
  }

  void _updateContact(String id) async {
    _saveContact(id: id);
  }

  void _saveContact({String? id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';
    String lid = prefs.getString('lid') ?? '';
    final response = await http.post(
      Uri.parse(
        id == null
            ? '$url/myapp/user_add_emergency_number/'
            : '$url/myapp/user_edit_emergency_number/',
      ),
      body: {
        'id': id ?? '',
        'name': nameController.text,
        'number': numberController.text,
        'relation': relationController.text,
        'lid': lid,
      },
    );

    if (response.statusCode == 200 && jsonDecode(response.body)['status'] == 'ok') {
      Fluttertoast.showToast(msg: id == null ? 'Contact Added' : 'Contact Updated');
      fetchContacts();
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Failed to Save Contact');
    }
  }
}
