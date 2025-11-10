import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/utils/device_id_manager.dart';
import 'package:frontend/data/datasources/local/token_storage.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ 디바이스 ID 생성
      final deviceId = await DeviceIdManager.getDeviceId();

      // ✅ 자동 로그인 체크
      await _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    final auth = context.read<AuthProvider>();

    // ✅ 저장된 토큰 가져오기
    final access = await TokenStorage.getAccessToken();
    final refresh = await TokenStorage.getRefreshToken();

    await Future.delayed(const Duration(seconds: 2)); // 스플래시 효과

    // ✅ 1) 토큰 없으면 → 로그인 필요
    if (access == null || refresh == null) {
      context.go('/landing');
      return;
    }

    // ✅ 2) AccessToken 유효한가?
    final isExpired = JwtDecoder.isExpired(access);

    if (!isExpired) {
      // ✅ 만료 안 됨 → 바로 메인 이동
      context.go('/main');
      return;
    }

    // ✅ 3) AccessToken 만료됨 → RefreshToken으로 갱신 시도
    try {
      await auth.refresh();
      // ✅ 갱신 성공 → 메인 이동
      context.go('/main');
    } catch (e) {
      // ✅ Refresh 실패 → 로그인 페이지로
      context.go('/landing');
    }
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
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FB),
        ),
        child: Stack(
          children: [
            Positioned(
              left: width * -0.26,
              top: height * 0.45,
              child: Container(
                width: width * 2.06,
                height: width * 2.06,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/onboard1.webp'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.094,
              top: height * 0.23,
              child: SizedBox(
                width: width * 0.81,
                height: height * 0.22,
                child: Image.asset(
                  'assets/images/logo.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
