import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/watchlist_data.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/datasources/remote/watchlist_api.dart';
import '../../../../data/repositories/watchlist_repository.dart';
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

  // 로딩 상태
  bool _isLoading = false;

  // Repository 인스턴스
  late final WatchlistRepository _watchlistRepository;

  @override
  void initState() {
    super.initState();
    // TODO: 선택된 산업/기업 기반으로 카테고리 결정 (현재는 기술주 하드코딩)
    _recommendedCompanies = USWatchlistData.techStocks;

    // 초기값: 모든 추천 기업 선택
    _selectedUSCompanies = _recommendedCompanies.map((c) => c.name).toSet();

    // Repository 초기화
    _watchlistRepository = WatchlistRepository(WatchlistApi(ApiClient()));
  }

  @override
  void dispose() {
    _watchlistRepository.dispose();
    super.dispose();
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

  /// 선택된 관심종목들을 API에 등록
  Future<void> _registerWatchlist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 선택된 기업 이름들에 해당하는 ticker 추출
      final selectedTickers = _recommendedCompanies
          .where((company) => _selectedUSCompanies.contains(company.name))
          .map((company) => company.ticker)
          .toList();

      print('=== 관심종목 등록 시작 ===');
      print('선택된 기업: ${_selectedUSCompanies.toList()}');
      print('등록할 티커: $selectedTickers');

      // 각 ticker를 순차적으로 등록
      int successCount = 0;
      int failCount = 0;
      final List<String> failedTickers = [];

      for (final ticker in selectedTickers) {
        try {
          await _watchlistRepository.addToWatchlist(ticker, checkDuplicate: false);
          successCount++;
          print('✓ $ticker 등록 성공');
        } catch (e) {
          failCount++;
          failedTickers.add(ticker);
          print('✗ $ticker 등록 실패: $e');
          // 개별 실패는 무시하고 계속 진행
        }
      }

      print('=== 관심종목 등록 완료 ===');
      print('성공: $successCount개, 실패: $failCount개');
      if (failedTickers.isNotEmpty) {
        print('실패한 티커: $failedTickers');
      }

      setState(() {
        _isLoading = false;
      });

      // 등록 완료 후 다음 화면으로 이동
      if (mounted) {
        // 실패가 있어도 성공이 하나라도 있으면 진행
        if (successCount > 0) {
          context.push('/persona-intro');
        } else {
          // 모두 실패한 경우 에러 표시
          _showErrorDialog('관심종목 등록에 실패했습니다. 다시 시도해주세요.');
        }
      }
    } catch (e) {
      print('=== 관심종목 등록 중 오류 발생 ===');
      print('Error: $e');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showErrorDialog('관심종목 등록 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
                    '당신을 위한\n추천 종목이에요!',
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
                onTap: _isLoading ? null : _registerWatchlist,
                child: Container(
                  width: double.infinity,
                  height: 53,
                  decoration: ShapeDecoration(
                    color: _isLoading
                        ? const Color(0xFF143D60).withOpacity(0.6)
                        : const Color(0xFF143D60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
