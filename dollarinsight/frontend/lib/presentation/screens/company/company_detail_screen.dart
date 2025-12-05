import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_detail_provider.dart';
import '../../widgets/company/watch_button.dart';
import '../../widgets/company/stock_price_chart.dart';
import '../../widgets/company/stock_score_chart.dart';
import '../../widgets/company/stock_prediction_chart.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/ticker_logo_mapper.dart';
import 'package:go_router/go_router.dart';
import 'company_chart_screen.dart';
import 'company_news_list_screen.dart';
import 'company_news_detail_screen.dart';
import 'company_info_screen.dart';

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
  final PageController _scorePageController = PageController(); // 종목정보 탭 내부 페이지
  late CompanyDetailProvider _provider; // Provider를 State 변수로 관리

  bool showFab = false;
  bool isCompany = true; // 기업분석/채팅 토글 상태
  int scorePageIndex = 0; // 종목정보 탭 페이지 인덱스 (0: 투자지표, 1: 주식점수)

  @override
  void initState() {
    super.initState();
    _provider = CompanyDetailProvider(companyId: widget.companyId); // Provider 한 번만 생성
    _tabController = TabController(length: 3, vsync: this); // 3개 탭 (차트, 종목정보, 주가예측)

    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });
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
    _provider.dispose(); // Provider dispose
    _tabController.dispose();
    _scrollController.dispose();
    _scorePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return ChangeNotifierProvider.value(
      value: _provider, // 이미 생성된 Provider 전달
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  /// TopNavigation (기업분석/채팅 토글)
                  TopNavigation(
                    w: w,
                    h: h,
                    isCompany: isCompany,
                    onTapCompany: () => setState(() => isCompany = true),
                    onTapChat: () => setState(() => isCompany = false),
                    onProfileTap: () {
                      context.push('/mypage');
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
              
              /// ✅ 채팅 생성 FAB (항상 표시)
              if (isCompany)
                Positioned(
                  right: w * 0.05,
                  bottom: w * 0.05,
                  child: Consumer<CompanyDetailProvider>(
                    builder: (context, provider, child) {
                      return ScrollFabButton(
                        w: w,
                        showFab: true, // 항상 표시
                        actionType: FabActionType.chat,
                        chatType: ChatContextType.company,
                        title: provider.companyName,
                        ticker: widget.companyId,
                      );
                    },
                  ),
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
                    _buildChartTab(provider),
                    _buildScoreTabWithPages(w, h, provider),
                    _buildPredictionTab(provider),
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
            child: TickerLogoMapper.hasLogo(widget.companyId)
                ? ClipOval(
                    child: Image.asset(
                      TickerLogoMapper.getLogoPath(widget.companyId),
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
          // + 버튼 (기업 설명)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF757575),
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyInfoScreen(companyId: widget.companyId),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // 관심 버튼
          WatchButton(
            isWatching: provider.isWatching,
            onTap: () async {
              final wasWatching = provider.isWatching;
              try {
                await provider.toggleWatchlist();
                // 성공 메시지 표시
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(wasWatching ? '관심종목에서 제거되었습니다' : '관심종목에 추가되었습니다'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Provider에서 에러를 던지면 여기서 처리
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('관심종목 설정에 실패했습니다: $e'),
                      duration: const Duration(seconds: 2),
                    ),
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

  /// 탭바 (차트 / 종목정보 / 주가예측)
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
          Tab(text: '주가예측'),
        ],
      ),
    );
  }

  /// 차트 탭 (주가그래프만 표시)
  Widget _buildChartTab(CompanyDetailProvider provider) {
    return _buildStockChartPage(provider);
  }

  /// 주가 그래프 페이지 (일봉)
  Widget _buildStockChartPage(CompanyDetailProvider provider) {
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
      child: StockPriceChart(
        dailyData: provider.dailyPriceData,
      ),
    );
  }

  /// 주가예측 탭 (1주/1달 모두 표시)
  Widget _buildPredictionTab(CompanyDetailProvider provider) {
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
      child: StockPredictionChart(
        weekPrediction: provider.weekPrediction,
        monthPrediction: provider.monthPrediction,
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
              _buildStockScorePage(provider), // 주식점수
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
          SizedBox(height: AppSpacing.bottomLarge(context)),
          Expanded(child: _buildIndicatorGrid(provider)),
          const SizedBox(height: 8),
          const Text(
            '일부 지표는 적자·데이터 부족으로 표시되지 않을 수 있어요.',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 10,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 주식점수 페이지
  Widget _buildStockScorePage(CompanyDetailProvider provider) {
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
      child: StockScoreChart(
        scores: provider.stockScores,
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
    // null 값인지 확인 (–로 표시된 경우)
    final isNull = value == '–';

    // 툴팁 메시지 설정
    String? tooltipMessage;
    if (isNull && label == 'PER') {
      tooltipMessage = '적자인 종목은 PER 계산이 어려워\n표시되지 않아요.';
    }

    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isNull
            ? const Color(0xFFF5F5F5)
            : const Color(0xFFD9E2EA),
        borderRadius: BorderRadius.circular(6),
        border: isNull
            ? Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isNull ? const Color(0xFF9E9E9E) : const Color(0xFF595959),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              height: 1.40,
              letterSpacing: 0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isNull ? const Color(0xFF9E9E9E) : Colors.black,
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );

    // 툴팁이 있는 경우 GestureDetector로 감싸기
    if (tooltipMessage != null) {
      final message = tooltipMessage; // null이 아님을 보장
      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                ),
              ),
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
        child: cardContent,
      );
    }

    return cardContent;
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
                      builder: (context) => CompanyNewsListScreen(
                        companyId: widget.companyId,
                      ),
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
