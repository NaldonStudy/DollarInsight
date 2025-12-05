import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/company/watch_button.dart';
import '../../providers/company_search_provider.dart';
import '../../../data/models/search_result_model.dart';

/// 기업 검색 화면
/// 관심종목 추가를 위한 검색 기능 제공
class CompanySearchScreen extends StatefulWidget {
  const CompanySearchScreen({super.key});

  @override
  State<CompanySearchScreen> createState() => _CompanySearchScreenState();
}

class _CompanySearchScreenState extends State<CompanySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompanySearchProvider(),
      child: Scaffold(
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
      body: Consumer<CompanySearchProvider>(
        builder: (context, provider, child) {
          return Column(
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
                            hintText: '티커, 기업명 검색',
                            hintStyle: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 15,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (query) => provider.search(query),
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
                            provider.clearSearch();
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
                child: provider.isSearching
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : provider.searchResults.isEmpty && provider.currentQuery.isNotEmpty
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
                        : provider.searchResults.isEmpty
                            ? const Center(
                                child: Text(
                                  '티커 또는 기업명을 검색하세요',
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
                                itemCount: provider.searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = provider.searchResults[index];
                                  return _buildSearchResultItem(provider, result);
                                },
                              ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  /// 검색 결과 아이템
  Widget _buildSearchResultItem(CompanySearchProvider provider, SearchResult searchResult) {
    final isWatching = provider.isWatching(searchResult.ticker);

    return GestureDetector(
      onTap: () {
        // 기업 또는 ETF 상세 페이지로 이동
        if (searchResult.isETF) {
          context.push('/etf/${searchResult.ticker}');
        } else {
          context.push('/company/${searchResult.ticker}');
        }
      },
      child: _buildSearchResultCard(searchResult, isWatching, provider),
    );
  }

  /// 검색 결과 카드 UI
  Widget _buildSearchResultCard(SearchResult searchResult, bool isWatching, CompanySearchProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 로고 (기본 아이콘)
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business,
              color: Color(0xFF757575),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // 기업명 + 티커
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 한글명 + 티커 배지
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        searchResult.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: searchResult.isETF
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        searchResult.ticker,
                        style: TextStyle(
                          color: searchResult.isETF
                              ? const Color(0xFF1976D2)
                              : const Color(0xFF7B1FA2),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 영문명 + 거래소
                Text(
                  '${searchResult.nameEng} · ${searchResult.exchange}',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 관심종목 버튼
          WatchButton(
            isWatching: isWatching,
            onTap: () async {
              try {
                await provider.toggleWatchlist(searchResult.ticker);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.isWatching(searchResult.ticker)
                          ? '${searchResult.name}이(가) 관심종목에 추가되었습니다.'
                          : '${searchResult.name}이(가) 관심종목에서 제거되었습니다.',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            size: 28,
          ),
        ],
      ),
    );
  }
}