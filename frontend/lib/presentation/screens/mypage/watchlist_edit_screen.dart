import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/signup/company_chip.dart';
import '../../providers/watchlist_provider.dart';
import '../../../data/models/watchlist_model.dart';
import '../../../core/utils/ticker_logo_mapper.dart';

/// 마이페이지 - 관심 종목 수정 화면
class WatchlistEditScreen extends StatefulWidget {
  const WatchlistEditScreen({super.key});

  @override
  State<WatchlistEditScreen> createState() => _WatchlistEditScreenState();
}

class _WatchlistEditScreenState extends State<WatchlistEditScreen> {
  // 백엔드에서 불러온 현재 관심 종목
  List<WatchlistItem> _currentWatchlist = [];

  // 유지할 종목 ticker (초기값: 모두 유지)
  Set<String> _selectedTickers = {};

  // 로딩 상태
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  /// API에서 현재 관심 종목 불러오기
  Future<void> _loadWatchlist() async {
    final provider = context.read<WatchlistProvider>();

    setState(() {
      _isLoading = true;
    });

    await provider.loadWatchlist(forceRefresh: true);

    if (mounted) {
      setState(() {
        _currentWatchlist = provider.watchlist;
        // 초기값: 모든 종목 선택 (유지)
        _selectedTickers = _currentWatchlist.map((item) => item.ticker).toSet();
        _isLoading = false;
      });
    }
  }

  /// 종목 선택/해제 토글 (선택 = 유지, 해제 = 삭제)
  void _toggleTicker(String ticker) {
    setState(() {
      if (_selectedTickers.contains(ticker)) {
        _selectedTickers.remove(ticker);
      } else {
        _selectedTickers.add(ticker);
      }
    });
  }

  /// 검색 화면으로 이동
  void _openSearchModal() async {
    await context.push('/mypage/company-search');

    // 검색 화면에서 기업 추가 후 돌아올 때 관심종목 리스트 새로고침
    _loadWatchlist();
  }

  /// 삭제할 종목들을 API로 삭제
  Future<void> _deleteWatchlistItems() async {
    // 삭제할 ticker 리스트 (선택되지 않은 것들)
    final tickersToRemove = _currentWatchlist
        .where((item) => !_selectedTickers.contains(item.ticker))
        .map((item) => item.ticker)
        .toList();

    if (tickersToRemove.isEmpty) {
      // 삭제할 것이 없으면 그냥 돌아가기
      if (mounted) {
        context.pop();
      }
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final provider = context.read<WatchlistProvider>();
    int successCount = 0;
    int failCount = 0;

    // 각 ticker를 순차적으로 삭제
    for (final ticker in tickersToRemove) {
      final success = await provider.removeFromWatchlist(ticker);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    setState(() {
      _isDeleting = false;
    });

    if (mounted) {
      // 이전 화면으로 돌아가기
      context.pop();

      // 결과 메시지
      String message;
      if (failCount == 0) {
        message = '관심 종목 ${successCount}개가 삭제되었습니다.';
      } else if (successCount == 0) {
        message = '관심 종목 삭제에 실패했습니다.';
      } else {
        message = '${successCount}개 삭제 성공, ${failCount}개 실패';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: failCount == 0 ? null : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),

                  // 검색창 (클릭 시 모달 열림)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: _openSearchModal,
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
                            const Expanded(
                              child: Text(
                                '기업을 검색해 추가하세요',
                                style: TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 15,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
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

                  // 관심종목이 없을 때
                  if (_currentWatchlist.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '등록된 관심 종목이 없습니다',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // 기업 그리드 (초록색 = 유지, 회색 = 삭제)
                  if (_currentWatchlist.isNotEmpty)
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
                            final item = _currentWatchlist[index];
                            final logoPath = TickerLogoMapper.getLogoPath(item.ticker);

                            return CompanyChip(
                              companyName: item.name,
                              logoPath: logoPath,
                              isSelected: _selectedTickers.contains(item.ticker),
                              onTap: () => _toggleTicker(item.ticker),
                            );
                          },
                        ),
                      ),
                    ),

                  // 변경 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 20, 26, 30),
                    child: GestureDetector(
                      onTap: _isDeleting ? null : _deleteWatchlistItems,
                      child: Container(
                        width: double.infinity,
                        height: 53,
                        decoration: ShapeDecoration(
                          color: _isDeleting
                              ? const Color(0xFF757575)
                              : const Color(0xFF143D60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: _isDeleting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
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
