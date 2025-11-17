import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/persona/persona_card.dart';

class PersonaIntroScreen extends StatefulWidget {
  const PersonaIntroScreen({super.key});

  @override
  State<PersonaIntroScreen> createState() => _PersonaIntroScreenState();
}

class _PersonaIntroScreenState extends State<PersonaIntroScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  final List<Map<String, dynamic>> personas = [
    {
      'title': 'AI 친구소개',
      'subtitle': '욱하는 추진력, 단타러',
      'name': '희열',
      'description': '열정가득 승부사',
      'strengths': '단기 수익실현',
      'weaknesses': '과열 투자, 근거 빈약, 유행민감',
      'image': 'assets/images/heuyeol.webp',
      'color': const Color(0x4CFD0000),
    },
    {
      'title': 'AI 친구소개',
      'subtitle': '전통 - 관록중시 투자자',
      'name': '덕수',
      'description': '거시적 관점으로 시장의 본질을 꿰뚫다',
      'strengths': '거시적 사이클 중시, 안정적 투자',
      'weaknesses': '과도한 보수성',
      'image': 'assets/images/deoksu.webp',
      'color': const Color(0x4CFD6900),
    },
    {
      'title': 'AI 친구소개',
      'subtitle': '비율 · 논리 중시자',
      'name': '지율',
      'description': '수치, 자료로 시장을 읽다',
      'strengths': '밸류에이션·현금흐름·리스크 관리',
      'weaknesses': '모멘텀 저평가, 타이밍 느림',
      'image': 'assets/images/jiyul.webp',
      'color': const Color(0xFFC8E1F5),
    },
    {
      'title': 'AI 친구소개',
      'subtitle': '테크 AI 매니아',
      'name': '테오',
      'description': '한발 앞서 미래 기술을 내다보다',
      'strengths': '빅데이터·미래기술 특화',
      'weaknesses': '단기 실적 둔감',
      'image': 'assets/images/teo.webp',
      'color': const Color(0x7C32C375),
    },
    {
      'title': 'AI 친구소개',
      'subtitle': '밈 분석가',
      'name': '민지',
      'description': '시장의 유행과 밈을 중계하다',
      'strengths': '밈/시장심리 급류 포착',
      'weaknesses': '본질 약함, 수명 짧음',
      'image': 'assets/images/minji.webp',
      'color': const Color(0x4CDF00FD),
    },
  ];

  void nextPage() {
    if (currentIndex < personas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.push('/signup/complete'); // ✅ 회원가입 완료 화면으로 이동
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final p = personas[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            /// 본문 구조
            Column(
              children: [
                // 상단 고정 제목/부제목
                Padding(
                  padding: EdgeInsets.only(left: w * 0.09, top: h * 0.05),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title'],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: w * 0.083,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: h * 0.008),
                        Text(
                          p['subtitle'],
                          style: TextStyle(
                            color: const Color(0xFF757575),
                            fontSize: w * 0.055,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 슬라이드 영역
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => currentIndex = i),
                    itemCount: personas.length,
                    itemBuilder: (context, i) {
                      final pi = personas[i];
                      return PersonaCard(
                        name: pi['name'],
                        description: pi['description'],
                        strengths: pi['strengths'],
                        weaknesses: pi['weaknesses'],
                        imageUrl: pi['image'],
                        circleColor: pi['color'],
                        activeIndex: i,
                        totalCount: personas.length,
                        onNext: nextPage,
                      );
                    },
                  ),
                ),

                SizedBox(height: h * 0.1), // 인디케이터와 버튼 공간 확보
              ],
            ),

            /// 하단 인디케이터 + 버튼 (고정)
            Positioned(
              bottom: h * 0.12, // 버튼 바로 위 위치
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(personas.length, (i) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: w * 0.014),
                    width: w * 0.028,
                    height: w * 0.028,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? const Color(0xFF5A5A5A)
                          : const Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),

            Positioned(
              bottom: h * 0.04, // 인디케이터보다 아래쪽
              left: w * 0.09,
              right: w * 0.09,
              child: GestureDetector(
                onTap: nextPage,
                child: Container(
                  height: h * 0.065,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF143D60),
                    borderRadius: BorderRadius.circular(w * 0.08),
                  ),
                  child: Text(
                    currentIndex == personas.length - 1 ? '완료' : '다음',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
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
