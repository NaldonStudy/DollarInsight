import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/watchlist_data.dart';
import '../../widgets/company/watch_button.dart';

/// 기업 검색 화면
/// 관심종목 추가를 위한 검색 기능 제공
class CompanySearchScreen extends StatefulWidget {
  const CompanySearchScreen({super.key});

  @override
  State<CompanySearchScreen> createState() => _CompanySearchScreenState();
}

class _CompanySearchScreenState extends State<CompanySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<USCompanyData> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // 초기 더미 데이터 (테슬라)
    _searchResults = [
      const USCompanyData(
        name: '테슬라',
        logoPath: 'assets/images/company/tesla.webp', // TODO: 로고 추가
        category: '자동차',
      ),
    ];
  }

  /// 검색어 변경 시 호출
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [
          const USCompanyData(
            name: '테슬라',
            logoPath: 'assets/images/company/tesla.webp',
            category: '자동차',
          ),
        ];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // TODO: 백엔드 API 호출
    // final results = await companyApi.searchCompanies(query);
    // setState(() {
    //   _searchResults = results;
    //   _isSearching = false;
    // });

    // 더미: 프론트 필터링
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchResults = [
            const USCompanyData(
              name: '테슬라',
              logoPath: 'assets/images/company/tesla.webp',
              category: '자동차',
            ),
          ].where((c) => c.name.contains(query)).toList();
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '기업 검색',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search,
                    color: Color(0xFF757575),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '기업명 검색',
                        hintStyle: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 15,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF757575),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final company = _searchResults[index];
                          return _buildSearchResultItem(company);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 검색 결과 아이템
  Widget _buildSearchResultItem(USCompanyData company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 로고
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  company.logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business,
                      color: Color(0xFF757575),
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 기업명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company.category,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 추가 버튼
          WatchButton(
            isWatching: false, // 검색 결과는 항상 미추가 상태
            onTap: () {
              // TODO: 백엔드 API로 관심종목 추가
              // await watchlistApi.addCompany(company.name);

              print('관심종목 추가: ${company.name}');

              // 성공 메시지
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${company.name}이(가) 관심종목에 추가되었습니다.'),
                  duration: const Duration(seconds: 2),
                ),
              );

              // 이전 화면으로 돌아가기
              context.pop();
            },
            size: 28,
          ),
        ],
      ),
    );
  }
}