import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/watchlist_data.dart';
import '../../../widgets/signup/company_chip.dart';

/// 회원가입 - 관심 종목 추천 결과 화면
class SignupWatchlistResultScreen extends StatefulWidget {
  final Set<String>? selectedIndustries;
  final Set<String>? selectedCompanies;

  const SignupWatchlistResultScreen({
    super.key,
    this.selectedIndustries,
    this.selectedCompanies,
  });

  @override
  State<SignupWatchlistResultScreen> createState() =>
      _SignupWatchlistResultScreenState();
}

class _SignupWatchlistResultScreenState
    extends State<SignupWatchlistResultScreen> {
  // 추천된 미국 기업 목록
  late List<USCompanyData> _recommendedCompanies;

  // 선택된 미국 기업 (초기값: 모두 선택)
  late Set<String> _selectedUSCompanies;

  @override
  void initState() {
    super.initState();
    // TODO: 선택된 산업/기업 기반으로 카테고리 결정 (현재는 기술주 하드코딩)
    _recommendedCompanies = USWatchlistData.techStocks;

    // 초기값: 모든 추천 기업 선택
    _selectedUSCompanies = _recommendedCompanies.map((c) => c.name).toSet();
  }

  /// 미국 기업 선택/해제 토글
  void _toggleUSCompany(String companyName) {
    setState(() {
      if (_selectedUSCompanies.contains(companyName)) {
        _selectedUSCompanies.remove(companyName);
      } else {
        _selectedUSCompanies.add(companyName);
      }
    });
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
                    '님을 위한\n추천 종목이에요!',
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
                  Text(
                    '${_recommendedCompanies.length}개의 미국 기업을 추천해드려요',
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: 0.48,
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
              ),
            ),

            // 추천 기업 그리드 섹션 (클릭 가능)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.builder(
                  itemCount: _recommendedCompanies.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final company = _recommendedCompanies[index];
                    return CompanyChip(
                      companyName: company.name,
                      logoPath: company.logoPath,
                      isSelected: _selectedUSCompanies.contains(company.name),
                      onTap: () => _toggleUSCompany(company.name),
                    );
                  },
                ),
              ),
            ),

            // 완료 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(33, 20, 33, 30),
              child: GestureDetector(
                onTap: () {
                  // API로 전송할 데이터
                  final apiData = {
                    'selectedIndustries': widget.selectedIndustries?.toList() ?? [],
                    'selectedKoreanCompanies': widget.selectedCompanies?.toList() ?? [],
                    'selectedUSCompanies': _selectedUSCompanies.toList(),
                  };

                  print('=== API 전송 데이터 ===');
                  print('선택 산업: ${apiData['selectedIndustries']}');
                  print('선택 한국 기업: ${apiData['selectedKoreanCompanies']}');
                  print('선택 미국 기업: ${apiData['selectedUSCompanies']}');
                  // print('==================');

                  // TODO: 백엔드 API 호출하여 데이터 저장
                  context.push('/persona-intro');
                },
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
                      '완료',
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
