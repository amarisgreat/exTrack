import 'package:flutter/material.dart';

class ReadSms extends StatefulWidget {
  ReadSms({super.key});
  @override
  State<ReadSms> createState() => _ReadSmsState();
}

class _ReadSmsState extends State<ReadSms> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: Text("Read SMS"),),
    );

  }
}
