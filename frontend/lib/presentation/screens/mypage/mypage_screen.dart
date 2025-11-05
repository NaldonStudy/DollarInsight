import 'package:flutter/material.dart';
import '../../widgets/common/custom_back_button.dart';

class MypageScreen extends StatelessWidget {
  const
  MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      // ✅ 로그인 화면과 동일한 AppBar 사용
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),

      body: SafeArea(
        child: SingleChildScrollView( // ← 스크롤 대비
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 33),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ✅ 프로필 박스
                Container(
                  width: w * 0.82,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // 배경 원
                      const Positioned(
                        left: 16,
                        top: 13,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFEFF8FF),
                        ),
                      ),

                      // ✅ 프로필 이미지
                      Positioned(
                        left: 9,
                        top: 5,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/onboard1.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // ✅ 이름
                      const Positioned(
                        left: 86,
                        top: 21,
                        child: Text(
                          '김싸피님 안녕하세요~',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // ✅ 최종 로그인
                      const Positioned(
                        left: 86,
                        top: 43,
                        child: Text(
                          '최종 로그인 : 2025.10.28 00:00',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                _menuButton(label: '비밀번호 변경', onTap: () {}),
                _menuButton(label: 'AI 친구 변경', onTap: () {}),
                _menuButton(label: '관심 종목 변경', onTap: () {}),
                _menuButton(label: '탈퇴하기', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 메뉴 버튼 공통 위젯
  Widget _menuButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 19, top: 17),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
