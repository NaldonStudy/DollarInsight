import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/main/live_chat_card.dart';
import '../../widgets/main/stock_list_banner.dart';
import '../../widgets/main/index_section.dart';
import '../../widgets/main/news_section.dart';
import '../../widgets/main/stock_section.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../../data/datasources/remote/company_api.dart';
import '../../../data/models/dashboard_model.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isCompany = true; // ✅ 기업분석 / 채팅 상태 저장
  final ScrollController _scrollController = ScrollController();
  bool showFab = false;

  // ✅ Dashboard 데이터
  final CompanyApi _companyApi = CompanyApi();
  DashboardResponse? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });
    });

    // ✅ Dashboard 데이터 로드
    _loadDashboardData();
  }

  /// ✅ Dashboard 데이터 로드
  Future<void> _loadDashboardData() async {
    try {
      final response = await _companyApi.getDashboard();

      // ✅ API 응답이 {ok: true, data: {...}} 구조이므로 data 필드 추출
      final data = response['data'] as Map<String, dynamic>;

      final dashboardResponse = DashboardResponse.fromJson(data);

      setState(() {
        _dashboardData = dashboardResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _companyApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      /// ✅ MAIN BODY
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                /// ✅ Top Navigation
                TopNavigation(
                  w: w,
                  h: h,
                  isCompany: isCompany,
                  onTapCompany: () => setState(() => isCompany = true),
                  onTapChat: () => setState(() => isCompany = false),
                  onProfileTap: () => context.push('/mypage'),
                ),

                /// ✅ 기업분석일 때만 Navigation 아래 간격 추가
                if (isCompany)
                  SizedBox(height: AppSpacing.section(context)),

                /// ✅ 화면 스위칭 (화면 전체 전환 아님)
                Expanded(
                  child: isCompany
                      ? _buildCompanyBody(context, w, h)
                      : const ChatListScreen(),
                ),
              ],
            ),
            
            /// ✅ 채팅 생성 FAB (항상 표시)
            if (isCompany)
              Positioned(
                right: w * 0.05,
                bottom: w * 0.05,
                child: ScrollFabButton(
                  w: w,
                  showFab: true, // 항상 표시
                  actionType: FabActionType.chat,
                  chatType: ChatContextType.custom,
                  title: '새로운 채팅',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ✅ 기업분석 탭 화면 구성
  Widget _buildCompanyBody(BuildContext context, double w, double h) {
    // ✅ 로딩 중
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ✅ 에러 발생
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadDashboardData();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ 실시간 채팅 박스
          LiveChatCard(w: w, h: h),

          SizedBox(height: AppSpacing.small(context)),

          /// ✅ 기업 알아보기 배너
          StockListBanner(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 주요 지수
          IndexSection(
            w: w,
            h: h,
            majorIndices: _dashboardData?.majorIndices ?? [],
          ),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 뉴스 섹션
          NewsSection(
            w: w,
            h: h,
            recommendedNews: _dashboardData?.recommendedNews ?? [],
          ),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 데일리 픽 섹션
          StockSection(
            w: w,
            h: h,
            dailyPicks: _dashboardData?.dailyPick ?? [],
          ),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }
}
