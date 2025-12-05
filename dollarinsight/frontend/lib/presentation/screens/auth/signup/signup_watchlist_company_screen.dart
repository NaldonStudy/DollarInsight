import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/watchlist_data.dart';
import '../../../widgets/signup/company_chip.dart';

/// 회원가입 - 관심 기업 선택 화면
class SignupWatchlistCompanyScreen extends StatefulWidget {
  final Set<String>? selectedIndustries;

  const SignupWatchlistCompanyScreen({
    super.key,
    this.selectedIndustries,
  });

  @override
  State<SignupWatchlistCompanyScreen> createState() =>
      _SignupWatchlistCompanyScreenState();
}

class _SignupWatchlistCompanyScreenState
    extends State<SignupWatchlistCompanyScreen> {
  // 선택된 기업 목록
  final Set<String> _selectedCompanies = {};

  // 표시할 기업 목록 (선택된 산업의 대표 기업들)
  late List<CompanyData> _displayCompanies;

  @override
  void initState() {
    super.initState();
    // 항상 12개 기업 전체를 표시 (선택한 기업에서 산업 매핑)
    _displayCompanies = WatchlistData.getAllCompanies();
  }

  /// 기업 선택/해제 토글
  void _toggleCompany(String companyName) {
    setState(() {
      if (_selectedCompanies.contains(companyName)) {
        _selectedCompanies.remove(companyName);
      } else {
        _selectedCompanies.add(companyName);
      }
    });
  }

  /// 다음 버튼 클릭 처리
  void _onNextPressed() {
    if (_selectedCompanies.isEmpty) {
      // 선택된 기업이 없을 경우 경고
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 기업을 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 선택된 산업과 기업 데이터를 다음 화면으로 전달
    print('선택된 산업: ${widget.selectedIndustries}');
    print('선택된 기업: $_selectedCompanies');

    final data = {
      'selectedIndustries': widget.selectedIndustries,
      'selectedCompanies': _selectedCompanies,
    };

    context.push('/signup/watchlist-result', extra: data);
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
                    '현재 어떤 기업에 관심이 있나요?',
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

            // 기업 선택 그리드 섹션
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.builder(
                  itemCount: _displayCompanies.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75, // 0.9에서 0.75로 변경하여 높이 확보
                  ),
                  itemBuilder: (context, index) {
                    final company = _displayCompanies[index];
                    return CompanyChip(
                      companyName: company.name,
                      logoPath: company.logoPath,
                      isSelected: _selectedCompanies.contains(company.name),
                      onTap: () => _toggleCompany(company.name),
                    );
                  },
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
