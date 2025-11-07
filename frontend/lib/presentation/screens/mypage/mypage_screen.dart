import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/custom_back_button.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.09), // 33/360 ≈ 9%
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ✅ 프로필 박스
                Container(
                  width: double.infinity,
                  height: h * 0.11, // 86/800
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(w * 0.02),
                  ),
                  child: Stack(
                    children: [
                      // 배경 원
                      Positioned(
                        left: w * 0.045, // 16/360
                        top: h * 0.016,  // 13/800
                        child: CircleAvatar(
                          radius: w * 0.083, // 30/360
                          backgroundColor: const Color(0xFFEFF8FF),
                        ),
                      ),

                      // ✅ 프로필 이미지 (반응형)
                      Positioned(
                        left: w * 0.025, // 9/360
                        top: h * 0.006, // 5/800
                        child: Container(
                          width: w * 0.208, // 75/360
                          height: w * 0.208, // 항상 정사각형
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/onboard1.webp'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // ✅ 이름
                      Positioned(
                        left: w * 0.24,  // 86/360
                        top: h * 0.029, // 23/800
                        child: Text(
                          '김더미님 안녕하세요~',
                          style: TextStyle(
                            fontSize: w * 0.044, // 16px
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // ✅ 최종 로그인
                      Positioned(
                        left: w * 0.24,
                        top: h * 0.056, // 45/800
                        child: Text(
                          '최종 로그인 : 2025.10.28 00:00',
                          style: TextStyle(
                            fontSize: w * 0.033, // 12px
                            color: const Color(0xFF757575),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.04), // 30px → 반응형

                // ✅ 메뉴 버튼
                _menuButton(
                  w: w,
                  h: h,
                  label: '비밀번호 변경',
                  onTap: () {
                    context.push('/mypage/password-change');
                  },
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: 'AI 친구 변경',
                  onTap: () {
                    context.push('/mypage/ai-friend');
                  },
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: '관심 종목 변경',
                  onTap: () {
                    context.push('/mypage/watchlist/edit');
                  },
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: '탈퇴하기',
                  onTap: () {
                    context.push('/withdrawal');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 메뉴 버튼 (반응형)
  Widget _menuButton({
    required double w,
    required double h,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.02), // 16px
      width: double.infinity,
      height: h * 0.077, // 62/800
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.022),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(left: w * 0.053, top: h * 0.021),
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.05, // 20px
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
