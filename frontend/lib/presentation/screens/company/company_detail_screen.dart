import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_detail_provider.dart';
import '../../widgets/company/watch_button.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../../core/constants/app_spacing.dart';
import 'package:go_router/go_router.dart';
import 'company_chart_screen.dart';
import 'company_news_list_screen.dart';
import 'company_news_detail_screen.dart';

/// 기업 상세 페이지
/// Provider를 사용하여 데이터 로직과 UI 로직 분리
/// TopNavigation 포함 (기업분석/채팅 토글)
/// 차트, 종목지표, 주가예측 탭으로 구성
/// 하단에 기업별 뉴스 리스트 표시
class CompanyDetailScreen extends StatefulWidget {
  /// 기업 코드 또는 ID (API 호출용)
  final String companyId;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final PageController _chartPageController = PageController(); // 차트 탭 내부 페이지
  final PageController _scorePageController = PageController(); // 종목점수 탭 내부 페이지

  bool showFab = false;
  bool isCompany = true; // 기업분석/채팅 토글 상태
  int chartPageIndex = 0; // 차트 탭 페이지 인덱스 (0: 주가그래프, 1: 주가예측)
  int scorePageIndex = 0; // 종목정보 탭 페이지 인덱스 (0: 투자지표, 1: 주식점수)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2개 탭으로 변경

    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });
    });

    // 차트 페이지 인디케이터
    _chartPageController.addListener(() {
      final page = _chartPageController.page;
      if (page != null) {
        setState(() {
          chartPageIndex = page.round();
        });
      }
    });

    // 종목정보 페이지 인디케이터
    _scorePageController.addListener(() {
      final page = _scorePageController.page;
      if (page != null) {
        setState(() {
          scorePageIndex = page.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _chartPageController.dispose();
    _scorePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return ChangeNotifierProvider(
      create: (_) => CompanyDetailProvider(companyId: widget.companyId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        floatingActionButton: ScrollFabButton(
          w: w,
          showFab: showFab,
          onTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: Column(
            children: [
              /// TopNavigation (기업분석/채팅 토글)
              TopNavigation(
                w: w,
                h: h,
                isCompany: isCompany,
                onTapCompany: () => setState(() => isCompany = true),
                onTapChat: () => setState(() => isCompany = false),
                onProfileTap: () {
                  // TODO: 마이페이지로 이동
                  // context.push('/mypage');
                },
              ),

              /// 화면 전환 (기업분석 / 채팅)
              Expanded(
                child: isCompany
                    ? _buildCompanyAnalysisBody(w, h)
                    : const ChatListScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 기업분석 화면 바디
  Widget _buildCompanyAnalysisBody(double w, double h) {
    return Consumer<CompanyDetailProvider>(
      builder: (context, provider, child) {
        // 에러 처리
        if (provider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.error!)),
            );
            provider.clearError();
          });
        }

        // 로딩 중
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 데이터 표시
        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              SizedBox(height: AppSpacing.medium(context)),
              _buildCompanyHeader(w, provider),
              SizedBox(height: AppSpacing.section(context)),
              _buildTabBar(),
              SizedBox(
                height: h * 0.5, // 화면 높이의 50%
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChartTabWithPages(w, h),
                    _buildScoreTabWithPages(w, h, provider),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.section(context)),
              _buildNewsSection(w, provider),
              SizedBox(height: AppSpacing.bottomLarge(context)),
            ],
          ),
        );
      },
    );
  }

  /// 기업 정보 헤더 (로고, 기업명, 현재가, 관심 버튼)
  Widget _buildCompanyHeader(double w, CompanyDetailProvider provider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Row(
        children: [
          // 기업 로고
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: provider.logoUrl != null
                ? ClipOval(
                    child: Image.network(
                      provider.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.small(context)),
          // 기업명 및 현재가
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.companyName ?? '',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 2.15,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: provider.currentPrice ?? '',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.40,
                          letterSpacing: 0.54,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: provider.currentPriceUsd ?? '',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.40,
                          letterSpacing: 0.36,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 관심 버튼
          WatchButton(
            isWatching: provider.isWatching,
            onTap: () async {
              try {
                await provider.toggleWatchlist();
              } catch (e) {
                // Provider에서 에러를 던지면 여기서 처리
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('관심종목 설정에 실패했습니다: $e')),
                  );
                }
              }
            },
            size: 24,
          ),
        ],
      ),
    );
  }

  /// 탭바 (차트 / 종목점수)
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.black,
        indicatorWeight: 3,
        labelColor: Colors.black,
        unselectedLabelColor: const Color(0xFF49454F),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: '차트'),
          Tab(text: '종목정보'),
        ],
      ),
    );
  }

  /// 차트 탭 (PageView로 주가그래프와 주가예측 스와이프)
  Widget _buildChartTabWithPages(double w, double h) {
    return Column(
      children: [
        // PageView
        Expanded(
          child: PageView(
            controller: _chartPageController,
            children: [
              _buildStockChartPage(), // 주가 그래프
              _buildPredictionPage(), // 주가 예측
            ],
          ),
        ),
        // 회색 인디케이터
        SizedBox(height: AppSpacing.small(context)),
        _buildPageIndicator(chartPageIndex, 2),
        SizedBox(height: AppSpacing.medium(context)),
      ],
    );
  }

  /// 주가 그래프 페이지 (MVP: 일봉)
  Widget _buildStockChartPage() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
        vertical: AppSpacing.small(context),
      ),
      padding: EdgeInsets.all(AppSpacing.medium(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'TODO: 주가 그래프 (일봉)\n백엔드 API에서 차트 데이터 받아오기',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
      ),
    );
  }

  /// 주가 예측 페이지
  Widget _buildPredictionPage() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
        vertical: AppSpacing.small(context),
      ),
      padding: EdgeInsets.all(AppSpacing.medium(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'TODO: 주가예측 그래프\n백엔드 API에서 예측 데이터 받아오기',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
      ),
    );
  }

  /// 종목정보 탭 (PageView로 투자지표와 주식점수 스와이프)
  Widget _buildScoreTabWithPages(double w, double h, CompanyDetailProvider provider) {
    return Column(
      children: [
        // PageView
        Expanded(
          child: PageView(
            controller: _scorePageController,
            children: [
              _buildIndicatorsPage(provider), // 투자지표
              _buildStockScorePage(), // 주식점수
            ],
          ),
        ),
        // 회색 인디케이터
        SizedBox(height: AppSpacing.small(context)),
        _buildPageIndicator(scorePageIndex, 2),
        SizedBox(height: AppSpacing.medium(context)),
      ],
    );
  }

  /// 투자지표 페이지
  Widget _buildIndicatorsPage(CompanyDetailProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
        vertical: AppSpacing.small(context),
      ),
      padding: EdgeInsets.all(AppSpacing.medium(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '투자지표',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.87,
            ),
          ),
          SizedBox(height: AppSpacing.small(context)),
          Expanded(child: _buildIndicatorGrid(provider)),
        ],
      ),
    );
  }

  /// 주식점수 페이지
  Widget _buildStockScorePage() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
        vertical: AppSpacing.small(context),
      ),
      padding: EdgeInsets.all(AppSpacing.medium(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'TODO: 주식점수 안내\n백엔드 API에서 점수 데이터 받아오기',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
      ),
    );
  }

  /// 투자지표 그리드
  Widget _buildIndicatorGrid(CompanyDetailProvider provider) {
    if (provider.indicators == null || provider.indicators!.isEmpty) {
      return const Center(
        child: Text(
          '투자지표 데이터가 없습니다.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

    final List<MapEntry<String, String>> indicatorList =
        provider.indicators!.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1,
      ),
      itemCount: indicatorList.length,
      itemBuilder: (context, index) {
        final item = indicatorList[index];
        return _buildIndicatorCard(item.key, item.value);
      },
    );
  }

  /// 개별 투자지표 카드
  Widget _buildIndicatorCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFD9E2EA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 10,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              height: 1.40,
              letterSpacing: 0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 2.15,
            ),
          ),
        ],
      ),
    );
  }

  /// 주가예측 탭
  Widget _buildPredictionTab() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
        vertical: AppSpacing.small(context),
      ),
      padding: EdgeInsets.all(AppSpacing.medium(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'TODO: 주가예측 그래프 구현\n백엔드 API에서 예측 데이터 받아오기',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
      ),
    );
  }

  /// 뉴스 섹션
  Widget _buildNewsSection(double w, CompanyDetailProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뉴스 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '뉴스',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.40,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // 전체 뉴스 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyNewsListScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x0060A4DA),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    '전체보기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA9A9A9),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.40,
                      letterSpacing: 0.36,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.medium(context)),
          // 뉴스 리스트
          Container(
            padding: EdgeInsets.all(AppSpacing.medium(context)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: provider.newsList.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.medium(context)),
                    child: const Center(
                      child: Text(
                        '뉴스가 없습니다.',
                        style: TextStyle(color: Color(0xFF757575)),
                      ),
                    ),
                  )
                : Column(
                    children: provider.newsList.map((news) {
                      return _buildNewsItem(news, provider.newsList);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  /// 개별 뉴스 아이템 (클릭 시 링크 연결)
  Widget _buildNewsItem(
      Map<String, String> news, List<Map<String, String>> newsList) {
    final index = newsList.indexOf(news);
    final isLast = index == newsList.length - 1;
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // 뉴스 상세 페이지로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompanyNewsDetailScreen(
                  companyId: widget.companyId,
                  newsId: news['id'] ?? '1',
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: h * 0.018,
            ),
            child: Text(
              news['title'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
      ],
    );
  }

  /// 회색 인디케이터 dots (페이지 표시)
  Widget _buildPageIndicator(int currentIndex, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? const Color(0xFF5A5A5A) // 현재 페이지 (진한 회색)
                : const Color(0xFFD9D9D9), // 다른 페이지 (연한 회색)
          ),
        );
      }),
    );
  }
}
