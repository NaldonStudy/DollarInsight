import 'package:flutter/material.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';


void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          // Headline styles
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),

          // Title styles
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),

          // Body styles
          bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.5),

          // Label styles
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),

        ),
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// 사용 방법
//
//
//   Text(
//     '제목',
//     style: Theme.of(context).textTheme.headlineMedium,
//   )
//
//   Text(
//     '본문 내용',
//     style: Theme.of(context).textTheme.bodyMedium,
//   )