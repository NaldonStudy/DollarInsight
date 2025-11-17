import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopNavigation extends StatelessWidget {
  final double w;
  final double h;
  final bool isCompany;
  final VoidCallback onTapCompany;
  final VoidCallback onTapChat;
  final VoidCallback onProfileTap;

  const TopNavigation({
    super.key,
    required this.w,
    required this.h,
    required this.isCompany,
    required this.onTapCompany,
    required this.onTapChat,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: h * 0.015,
        left: w * 0.06,
        right: w * 0.06,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/main'),
            child: Image.asset("assets/images/logomini.webp", width: w * 0.1),
          ),

          // 토글
          SizedBox(
            width: w * 0.42,
            height: 36, // ✅ 고정 높이로 비율 문제 제거
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / 2;

                return Stack(
                  children: [
                    // 배경
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFABCEEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // ✅ 하이라이트(흰 박스): 터치 차단 + 비율 안정 + 한 번 탭에 즉시 이동
                    IgnorePointer(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        alignment: isCompany
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: segmentWidth,
                          height: 36,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // 탭 텍스트 (최상단 터치 레이어)
                    Row(
                      children: [
                        // 기업분석
                        GestureDetector(
                          behavior: HitTestBehavior.opaque, // ✅ 반쪽 전체가 터치 영역
                          onTap: onTapCompany,
                          child: SizedBox(
                            width: segmentWidth,
                            height: 36,
                            child: Center(
                              child: Text(
                                "기업분석",
                                style: TextStyle(
                                  color: isCompany
                                      ? const Color(0xFF60A4DA)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 채팅
                        GestureDetector(
                          behavior: HitTestBehavior.opaque, // ✅ 반쪽 전체가 터치 영역
                          onTap: onTapChat,
                          child: SizedBox(
                            width: segmentWidth,
                            height: 36,
                            child: Center(
                              child: Text(
                                "채팅",
                                style: TextStyle(
                                  color: !isCompany
                                      ? const Color(0xFF60A4DA)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          GestureDetector(
            onTap: onProfileTap,
            child: Icon(
              Icons.person_outline,
              size: w * 0.085,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
