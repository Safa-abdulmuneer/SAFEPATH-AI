import 'package:flutter/material.dart';

class Dropdown extends StatefulWidget {
  const Dropdown({super.key});

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
List<String> items = ['Male','Female','others'];
String selectedGender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:DropdownButton(
          value: selectedGender,
            items: items.map((e) {
          return DropdownMenuItem(
            value: e,
              child: Text(e));
        }).toList(), onChanged: (value){
            setState(() {
              selectedGender = value!;
            });
        })
      ),
    );
  }
}
