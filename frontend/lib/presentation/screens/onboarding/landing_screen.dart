import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/kakao_login_service.dart';
import '../../../core/services/google_login_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        top: false,
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Color(0xFFF7F8FB)),
          child: Stack(
            children: [
              /// 🦉 배경 부엉이 (로그인 박스 뒤)
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

              /// 💬 로고
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

              /// 🤍 로그인 박스 (SlideTransition 적용)
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: width,
                    height: height * 0.41,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        /// 🔹 로그인 버튼
                        Positioned(
                          left: width * 0.091,
                          top: height * 0.055, // ✅ 비율로 조정 (약 5.5%)
                          child: GestureDetector(
                            onTap: () => context.push('/login'),
                            child: Container(
                              width: width * 0.816,
                              height: height * 0.066,
                              decoration: BoxDecoration(
                                color: const Color(0xFF143D60),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '로그인',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.48,
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// 🔹 회원가입 버튼
                        Positioned(
                          left: width * 0.091,
                          top: height * 0.155, // ✅ 비율 조정 (로그인보다 약 10% 아래)
                          child: GestureDetector(
                            onTap: () => context.push('/signup'),
                            child: Container(
                              width: width * 0.816,
                              height: height * 0.066,
                              decoration: BoxDecoration(
                                color: const Color(0xFF60A4DA),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '회원가입',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.48,
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// 🔹 구분선
                        Positioned(
                          left: width * 0.091,
                          top: height * 0.255, // ✅ 이전보다 약간 아래로 비율 조정
                          child: Container(
                            width: width * 0.82,
                            height: height * 0.001, // ✅ 1px 대신 비율
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),

                        /// 🔹 소셜 로그인 아이콘들
                        /// 🔹 카카오 로그인 버튼
                        Positioned(
                          left: width * 0.266,
                          top: height * 0.305,
                          child: GestureDetector(
                            onTap: () async {
                              final success =
                                  await KakaoLoginService.loginWithKakao();

                              if (success && context.mounted) {
                                context.go('/main'); // ✅ 로그인 성공 시 메인으로 이동
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('카카오 로그인에 실패했습니다.'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Image.asset(
                              'assets/images/kakao.webp',
                              width: width * 0.136,
                              height: width * 0.136,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // 🔹 구글 로그인 버튼
                        Positioned(
                          left: width * 0.594,
                          top: height * 0.305,
                          child: GestureDetector(
                            onTap: () async {
                              final success =
                                  await GoogleLoginService.loginWithGoogle();

                              if (success && context.mounted) {
                                context.go('/main');
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('구글 로그인에 실패했습니다.'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Image.asset(
                              'assets/images/google.webp',
                              width: width * 0.139,
                              height: width * 0.139,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
