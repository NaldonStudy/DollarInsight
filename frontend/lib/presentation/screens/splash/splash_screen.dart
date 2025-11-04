import 'package:flutter/material.dart';
import '../auth/login_screen.dart'; // ✅ 로그인 화면 import (경로 맞게 수정!)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ 3초 후 로그인 화면으로 이동
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

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
