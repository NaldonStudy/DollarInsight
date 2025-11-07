import 'package:flutter/material.dart';
import '../../widgets/company/watch_button.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../../core/constants/app_spacing.dart';

/// 기업 상세 페이지
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
  bool showFab = false;
  bool isCompany = true; // 기업분석/채팅 토글 상태
  bool isWatching = false;
  bool isLoading = true;

  // 기업 정보 (API로 받아올 데이터)
  String? companyName;
  String? currentPrice;
  String? currentPriceUsd;
  String? logoUrl;
  Map<String, String>? indicators; // 투자지표 데이터
  List<Map<String, String>> newsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });
    });

    // API 호출
    _loadCompanyData();
  }

  /// 기업 데이터 로드 (API 연결 지점)
  Future<void> _loadCompanyData() async {
    setState(() => isLoading = true);

    try {
      // TODO: 백엔드 API 연결
      // 1. 기업 기본 정보 API 호출
      // final companyInfo = await companyRepository.getCompanyInfo(widget.companyId);

      // 2. 투자지표 API 호출
      // final indicatorData = await companyRepository.getIndicators(widget.companyId);

      // 3. 기업 뉴스 API 호출
      // final newsData = await newsRepository.getCompanyNews(widget.companyId);

      // 4. 관심종목 상태 확인
      // final watchStatus = await userRepository.checkWatchlist(widget.companyId);

      // 임시 더미 데이터 (API 연결 후 삭제)
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        companyName = '엔비디아';
        currentPrice = '293,027원';
        currentPriceUsd = '\$204.32';
        logoUrl = null;
        isWatching = false;

        indicators = {
          '시가총액': '7000억원',
          '배당수익률': '0.02%',
          'PBR': '48.8배',
          'PER': '56.4배',
          'ROE': '109.4%',
          'PSR': '29.6배',
        };

        newsList = [
          {
            'title': '[GAM]스텔란티스-엔비디아-우버-폭스콘, 로보택시 공동 개발',
            'url': 'https://example.com/news/1'
          },
          {
            'title': '투자자들, 연준·기술주 실적에 대비하면서 AI 낙관론에 주가 상승',
            'url': 'https://example.com/news/2'
          },
          {
            'title': '트럼프, 엔비디아 \'슈퍼-듀퍼\' 블랙웰 칩에 中 시진핑과 논의할 수도',
            'url': 'https://example.com/news/3'
          },
          {
            'title': '엔비디아, 美 에너지부에 AI 슈퍼컴 7대 구축… 6G 인프라 구축도 추진',
            'url': 'https://example.com/news/4'
          },
          {
            'title': '[오늘의 뉴욕증시 무버] 노키아, 엔비디아 10억 달러 투자 소식에 22.85%↑',
            'url': 'https://example.com/news/5'
          },
        ];

        isLoading = false;
      });
    } catch (e) {
      // 에러 처리
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  /// 관심종목 추가/삭제 (API 연결 지점)
  Future<void> _toggleWatchlist() async {
    try {
      // TODO: 백엔드 API 연결
      // if (isWatching) {
      //   await userRepository.removeFromWatchlist(widget.companyId);
      // } else {
      //   await userRepository.addToWatchlist(widget.companyId);
      // }

      setState(() {
        isWatching = !isWatching;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('관심종목 설정에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
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
    );
  }

  /// 기업분석 화면 바디
  Widget _buildCompanyAnalysisBody(double w, double h) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          SizedBox(height: AppSpacing.medium(context)),
          _buildCompanyHeader(w),
          SizedBox(height: AppSpacing.section(context)),
          _buildTabBar(),
          SizedBox(
            height: h * 0.5, // 화면 높이의 50%
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChartTab(),
                _buildIndicatorTab(),
                _buildPredictionTab(),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.section(context)),
          _buildNewsSection(w),
          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }

  /// 기업 정보 헤더 (로고, 기업명, 현재가, 관심 버튼)
  Widget _buildCompanyHeader(double w) {
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
            child: logoUrl != null
                ? ClipOval(
                    child: Image.network(
                      logoUrl!,
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
                  companyName ?? '',
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
                        text: currentPrice ?? '',
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
                        text: currentPriceUsd ?? '',
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
            isWatching: isWatching,
            onTap: _toggleWatchlist,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// 탭바 (차트 / 종목지표 / 주가예측)
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
          Tab(text: '종목지표'),
          Tab(text: '주가예측'),
        ],
      ),
    );
  }

  /// 차트 탭
  Widget _buildChartTab() {
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
          'TODO: 차트 구현\n백엔드 API에서 차트 데이터 받아오기',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
      ),
    );
  }

  /// 종목지표 탭
  Widget _buildIndicatorTab() {
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
          Expanded(child: _buildIndicatorGrid()),
        ],
      ),
    );
  }

  /// 투자지표 그리드
  Widget _buildIndicatorGrid() {
    if (indicators == null || indicators!.isEmpty) {
      return const Center(
        child: Text(
          '투자지표 데이터가 없습니다.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

    final List<MapEntry<String, String>> indicatorList =
        indicators!.entries.toList();

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
  Widget _buildNewsSection(double w) {
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
                  // TODO: 전체 뉴스 페이지로 이동
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => AllNewsListScreen(
                  //       companyId: widget.companyId,
                  //     ),
                  //   ),
                  // );
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
            child: newsList.isEmpty
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
                    children: newsList.map((news) {
                      return _buildNewsItem(news);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  /// 개별 뉴스 아이템 (클릭 시 링크 연결)
  Widget _buildNewsItem(Map<String, String> news) {
    final index = newsList.indexOf(news);
    final isLast = index == newsList.length - 1;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final url = news['url'];
            if (url != null && url.isNotEmpty) {
              // TODO: 뉴스 상세 페이지로 이동 또는 외부 링크 열기
              // 방법 1: 웹뷰로 열기
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => NewsDetailScreen(url: url),
              //   ),
              // );

              // 방법 2: 외부 브라우저로 열기 (url_launcher 패키지)
              // launchUrl(Uri.parse(url));

              debugPrint('뉴스 클릭: $url');
            }
          },
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.small(context)),
            child: Text(
              news['title'] ?? '',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (!isLast)
          Container(
            height: 0.7,
            color: const Color(0xFFE4E4E4),
          ),
      ],
    );
  }
}
