import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('스플래시페이지')),
      body: const Center(
        child: Text('TODO: 스플래시페이지'),
      ),
    );
  }
}
