import 'dart:ui';
import 'package:flutter/material.dart';

class PersonaCard extends StatelessWidget {
  final String name;
  final String description;
  final String strengths;
  final String weaknesses;
  final String imageUrl;
  final Color circleColor;
  final int activeIndex;
  final int totalCount;
  final VoidCallback onNext;

  const PersonaCard({
    super.key,
    required this.name,
    required this.description,
    required this.strengths,
    required this.weaknesses,
    required this.imageUrl,
    required this.circleColor,
    required this.activeIndex,
    required this.totalCount,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      children: [
        SizedBox(height: h * 0.03),

        /// ✅ 캐릭터 + 블러 원 (정중앙 고정)
        SizedBox(
          height: h * 0.35,   // 전체 캐릭터 공간 (고정 비율)
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 흐린 원
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: w * 0.43,
                  height: w * 0.43,
                  decoration: BoxDecoration(
                    color: circleColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 캐릭터 이미지
              SizedBox(
                width: w * 0.6,
                height: w * 0.6,
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: h * 0.03),

        /// ✅ 이름
        Text(
          name,
          style: TextStyle(
            fontSize: w * 0.075,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF373737),
          ),
        ),

        SizedBox(height: h * 0.02),

        /// ✅ 설명 + 강점/약점 (모든 기기에서 동일한 간격)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.09),
          child: Column(
            children: [
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              SizedBox(height: h * 0.025),
              Text(
                "강점: $strengths",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.043,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              Text(
                "약점: $weaknesses",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.043,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
