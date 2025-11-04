import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로딩페이지')),
      body: const Center(
        child: Text('TODO: 로딩페이지'),
      ),
    );
  }
}
