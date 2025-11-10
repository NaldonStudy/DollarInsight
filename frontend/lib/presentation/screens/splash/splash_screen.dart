import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/utils/device_id_manager.dart';  // ✅ 경로 맞춰줘야 함

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
      // ✅ 디바이스 ID 생성 또는 기존 ID 가져오기
      final deviceId = await DeviceIdManager.getDeviceId();
      debugPrint("✅ 생성된 Device ID: $deviceId");

      // ✅ 3초 뒤 이동
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go('/landing');
        }
      });
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
              child: Container(
                width: width * 0.81,
                height: height * 0.22,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.webp'),
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
