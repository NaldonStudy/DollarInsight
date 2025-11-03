import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:frontend/routes/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';


void main() {
  usePathUrlStrategy();
=======
import 'presentation/screens/splash/splash_screen.dart'; // ✅ 스플래시 화면 임포트

void main() {
>>>>>>> 487e6b0f435a6fb9eab41bd51294aefef5609e44
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
=======
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 🔹 우측 상단 Debug 배너 제거
      title: 'Dollar Insight', // 🔹 앱 이름
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      ),
      home: const SplashScreen(), // ✅ 앱 실행 시 가장 먼저 뜨는 화면
>>>>>>> 487e6b0f435a6fb9eab41bd51294aefef5609e44
    );
  }
}
