import 'package:flutter/material.dart';

class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('차트상세')),
      body: const Center(
        child: Text('차트상세'),
      ),
    );
  }
}
