import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../providers/user_provider.dart';
import '../../../data/datasources/remote/user_api.dart';
import '../../../data/datasources/remote/auth_api.dart';
import '../../../data/datasources/local/token_storage.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ 화면 진입 시 자동으로 내 정보 불러오기
    Future.microtask(() {
      context.read<UserProvider>().loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    final nickname = user?['nickname'] ?? '로딩중...';
    final updatedAt = user?['updatedAt']?.toString().substring(0, 10) ?? '-';

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
            padding: EdgeInsets.symmetric(horizontal: w * 0.09),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 프로필 박스
                Container(
                  width: double.infinity,
                  height: h * 0.11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(w * 0.02),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: w * 0.045,
                        top: h * 0.016,
                        child: CircleAvatar(
                          radius: w * 0.083,
                          backgroundColor: const Color(0xFFEFF8FF),
                        ),
                      ),

                      // ✅ 프로필 이미지
                      Positioned(
                        left: w * 0.025,
                        top: h * 0.006,
                        child: Container(
                          width: w * 0.208,
                          height: w * 0.208,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/onboard1.webp'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // ✅ 사용자 이름
                      Positioned(
                        left: w * 0.24,
                        top: h * 0.029,
                        child: Text(
                          '$nickname님 안녕하세요~',
                          style: TextStyle(
                            fontSize: w * 0.044,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // ✅ 최종 로그인
                      Positioned(
                        left: w * 0.24,
                        top: h * 0.056,
                        child: Text(
                          '최종 로그인: $updatedAt',
                          style: TextStyle(
                            fontSize: w * 0.033,
                            color: const Color(0xFF757575),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.04),
                _menuButton(
                  w: w,
                  h: h,
                  label: '닉네임 변경',
                  onTap: () => context.push('/mypage/nickname-change'),
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: '비밀번호 변경',
                  onTap: () => context.push('/mypage/password-change'),
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: 'AI 친구 변경',
                  onTap: () => context.push('/mypage/ai-friend'),
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: '관심 종목 변경',
                  onTap: () => context.push('/mypage/watchlist/edit'),
                ),
                _menuButton(
                  w: w,
                  h: h,
                  label: '로그아웃',
                  onTap: () async {
                    final status = await UserApi.logout();

                    if (status == 204 && context.mounted) {
                      context.go('/landing');
                    }
                  },
                ),

                _menuButton(
                  w: w,
                  h: h,
                  label: '탈퇴하기',
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text("정말 탈퇴하시겠습니까?"),
                          content: const Text("회원탈퇴를 진행하면 계정이 삭제됩니다."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text("취소"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                "탈퇴하기",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true && context.mounted) {
                      // 🔥 탈퇴 API 실행
                      final success = await AuthApi.deleteMe();

                      if (success) {
                        await TokenStorage.clearTokens();
                        context.go('/withdrawal/complete');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("회원탈퇴에 실패했습니다.")),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton({
    required double w,
    required double h,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.02),
      width: double.infinity,
      height: h * 0.077,
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
              fontSize: w * 0.05,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
