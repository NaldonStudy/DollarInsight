import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        top: false, // ✅ 온보딩과 로고 위치를 동일하게 유지
        child: Stack(
          children: [
            /// ✅ 로고
            Positioned(
              left: width * 0.094, // (34 / 360)
              top: height * 0.23,  // (186 / 800)
              child: Container(
                width: width * 0.81, // (293 / 360)
                height: height * 0.22, // (176 / 800)
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            /// ✅ 로그인/회원가입 박스
            Positioned(
              left: 0,    // ✅ 여백 제거
              right: 0,   // ✅ 여백 제거
              bottom: 0,  // ✅ 화면 하단에 완전히 붙임
              child: Container(
                width: width,
                height: height * 0.41, // (330 / 800)
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 🔹 로그인 버튼
                    SizedBox(
                      width: width * 0.82,
                      height: height * 0.066, // (53 / 800)
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF143D60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {},
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
                    SizedBox(height: height * 0.02),

                    /// 🔹 회원가입 버튼
                    SizedBox(
                      width: width * 0.82,
                      height: height * 0.066,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60A4DA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {},
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
                    SizedBox(height: height * 0.04),

                    /// 🔹 구분선
                    Container(
                      width: width * 0.82,
                      height: 1,
                      color: Colors.black.withOpacity(0.1),
                    ),
                    SizedBox(height: height * 0.03),

                    /// 🔹 카카오 / 구글 로그인 아이콘
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/kakao.png',
                          width: width * 0.14,
                          height: width * 0.14,
                        ),
                        SizedBox(width: width * 0.1),
                        Image.asset(
                          'assets/images/google.png',
                          width: width * 0.14,
                          height: width * 0.14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}