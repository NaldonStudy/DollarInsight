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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FB),
        ),
        child: Stack(
          children: [
            /// ✅ 배경 원 이미지 (onboard1.png)
            Positioned(
              left: width * -0.26,     // (-94 / 360)
              top: height * 0.45,      // (362 / 800)
              child: Container(
                width: width * 2.06,   // (744 / 360)
                height: width * 2.06,  // 정사각형 유지
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/onboard1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            /// ✅ 중앙 로고 (logo.png)
            Positioned(
              left: width * 0.094,     // (34 / 360)
              top: height * 0.23,      // (186 / 800)
              child: Container(
                width: width * 0.81,   // (293 / 360)
                height: height * 0.22, // (176 / 800)
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
