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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Stack(
      children: [
        // 흐림 원 (위로 조정)
        Positioned(
          left: width * 0.29,
          top: height * 0.14, // 기존 0.30 → 0.12 (상단으로 이동)
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: width * 0.42,
              height: width * 0.42,
              decoration: BoxDecoration(
                color: circleColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // 캐릭터 이미지 (원보다 약간 위)
        Positioned(
          left: width * 0.20,
          top: height * 0.11, // 기존 0.22 → 0.04
          child: SizedBox(
            width: width * 0.60,
            height: width * 0.60,
            child: Image.asset(imageUrl, fit: BoxFit.contain),
          ),
        ),

        // 이름
        Positioned(
          left: 0,
          right: 0,
          top: height * 0.47, // 캐릭터 아래쪽 여백 확보
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF373737),
              fontSize: width * 0.07,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // 설명, 강점, 약점
        Positioned(
          left: width * 0.09,
          right: width * 0.09,
          top: height * 0.55,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$description\n\n',
                  style: TextStyle(
                    color: const Color(0xFF757575),
                    fontSize: width * 0.045,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '강점: $strengths\n약점: $weaknesses',
                  style: TextStyle(
                    color: const Color(0xFF757575),
                    fontSize: width * 0.045,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
