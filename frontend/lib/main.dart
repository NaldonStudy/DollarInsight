import 'package:flutter/material.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/watchlist_provider.dart';

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // ✅ 반드시 추가

  // ✅ 환경변수 로드
  await dotenv.load(fileName: ".env");

  // ✅ 한국어 날짜/시간 포맷 초기화 (필수)
  await initializeDateFormatting('ko_KR', null);

  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',
  );

  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // ✅ 로그인/회원가입 Provider 주입
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()), // 채팅
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
      ],
      child: const MyApp(),
    ),
  );
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