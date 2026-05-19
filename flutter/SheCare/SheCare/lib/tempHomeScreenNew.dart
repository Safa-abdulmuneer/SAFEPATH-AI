import 'package:flutter/material.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body:Center(child: Text("HomePage"),)
    );
  }
}
