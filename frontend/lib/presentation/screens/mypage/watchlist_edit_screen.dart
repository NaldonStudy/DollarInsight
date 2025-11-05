import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/watchlist_data.dart';
import '../../widgets/signup/company_chip.dart';

/// 마이페이지 - 관심 종목 수정 화면
class WatchlistEditScreen extends StatefulWidget {
  const WatchlistEditScreen({super.key});

  @override
  State<WatchlistEditScreen> createState() => _WatchlistEditScreenState();
}

class _WatchlistEditScreenState extends State<WatchlistEditScreen> {
  // TODO: 백엔드에서 사용자의 현재 관심 종목 불러오기
  late List<USCompanyData> _currentWatchlist;

  // 유지할 기업 (초기값: 모두 유지)
  late Set<String> _selectedCompanies;

  @override
  void initState() {
    super.initState();
    // TODO: API에서 현재 관심 종목 불러오기 (현재는 더미 데이터)
    _currentWatchlist = USWatchlistData.techStocks;

    // 초기값: 모든 기업 선택 (유지)
    _selectedCompanies = _currentWatchlist.map((c) => c.name).toSet();
  }

  /// 기업 선택/해제 토글 (선택 = 유지, 해제 = 삭제)
  void _toggleCompany(String companyName) {
    setState(() {
      if (_selectedCompanies.contains(companyName)) {
        _selectedCompanies.remove(companyName);
      } else {
        _selectedCompanies.add(companyName);
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
            const SizedBox(height: 22),

            // 검색창
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Container(
                height: 40,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 9),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF757575),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '기업을 검색해 추가하세요',
                          hintStyle: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          // TODO: 검색 기능 구현
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 27),

            // 제목
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '삭제할 기업을\n선택해 주세요',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.17,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // 기업 그리드 (초록색 = 유지, 회색 = 삭제)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: GridView.builder(
                  itemCount: _currentWatchlist.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 25,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final company = _currentWatchlist[index];
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

            // 변경 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 30),
              child: GestureDetector(
                onTap: () {
                  // 삭제할 기업 리스트
                  final companiesToRemove = _currentWatchlist
                      .where((c) => !_selectedCompanies.contains(c.name))
                      .map((c) => c.name)
                      .toList();

                  // 유지할 기업 리스트
                  final companiesToKeep = _selectedCompanies.toList();

                  print('=== 관심종목 수정 ===');
                  print('삭제할 기업: $companiesToRemove');
                  print('유지할 기업: $companiesToKeep');

                  // TODO: 백엔드 API 호출하여 관심종목 업데이트
                  // await watchlistApi.updateWatchlist(companiesToKeep);

                  // 이전 화면으로 돌아가기
                  context.pop();

                  // 성공 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('관심 종목이 변경되었습니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
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
                      '변경',
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
