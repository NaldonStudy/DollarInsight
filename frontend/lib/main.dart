import 'package:flutter/material.dart';
import 'presentation/screens/splash/splash_screen.dart'; // ✅ 스플래시 화면 임포트

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 🔹 우측 상단 Debug 배너 제거
      title: 'Dollar Insight', // 🔹 앱 이름
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      ),
      home: const SplashScreen(), // ✅ 앱 실행 시 가장 먼저 뜨는 화면
    );
  }
}
