import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/signup/industry_chip.dart';

/// 회원가입 - 관심 산업 선택 화면
class SignupWatchlistIndustryScreen extends StatefulWidget {
  const SignupWatchlistIndustryScreen({super.key});

  @override
  State<SignupWatchlistIndustryScreen> createState() =>
      _SignupWatchlistIndustryScreenState();
}

class _SignupWatchlistIndustryScreenState
    extends State<SignupWatchlistIndustryScreen> {
  // 산업 카테고리 목록
  final List<String> _industries = [
    '기술',
    '커머스',
    '항공',
    '자동차',
    '엔터',
    '결제',
    '산업/물류',
    '리테일',
    '금융(은행)',
    '금융(IB)',
    '보험',
    '소비재',
  ];

  // 선택된 산업 목록
  final Set<String> _selectedIndustries = {};

  /// 산업 선택/해제 토글
  void _toggleIndustry(String industry) {
    setState(() {
      if (_selectedIndustries.contains(industry)) {
        _selectedIndustries.remove(industry);
      } else {
        _selectedIndustries.add(industry);
      }
    });
  }

  /// 다음 버튼 클릭 처리
  void _onNextPressed() {
    if (_selectedIndustries.isEmpty) {
      // 선택된 산업이 없을 경우 경고
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 산업을 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 선택된 산업 데이터를 다음 화면으로 전달
    print('선택된 산업: $_selectedIndustries');
    context.push('/signup/watchlist-company', extra: _selectedIndustries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(39, 40, 39, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '관심 종목 추천을 위한\n간단한 설문을 진행할게요!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.40,
                      letterSpacing: 0.72,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '현재 어떤 산업에 관심이 있나요?',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 20,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: 0.60,
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
              ),
            ),

            // 산업 선택 칩 섹션
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 33),
                child: Wrap(
                  spacing: 7, // 가로 간격
                  runSpacing: 10, // 세로 간격
                  children: _industries.map((industry) {
                    return IndustryChip(
                      label: industry,
                      isSelected: _selectedIndustries.contains(industry),
                      onTap: () => _toggleIndustry(industry),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 다음 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(33, 20, 33, 30),
              child: GestureDetector(
                onTap: _onNextPressed,
                child: Container(
                  width: double.infinity,
                  height: 53,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF143D60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '다음',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        height: 1.40,
                        letterSpacing: 0.48,
                      ),
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
