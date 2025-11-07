import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_detail_provider.dart';
import '../../widgets/company/watch_button.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../../core/constants/app_spacing.dart';

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
  bool showFab = false;
  bool isCompany = true; // 기업분석/채팅 토글 상태

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });
    });
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
                    _buildChartTab(),
                    _buildIndicatorTab(provider),
                    _buildPredictionTab(),
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
  Widget _buildIndicatorTab(CompanyDetailProvider provider) {
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
                  // TODO: 전체 뉴스 페이지로 이동
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

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final url = news['url'];
            if (url != null && url.isNotEmpty) {
              // TODO: 뉴스 상세 페이지로 이동 또는 외부 링크 열기
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
