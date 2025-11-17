import 'package:go_router/go_router.dart';

// Screens imports
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/splash/loading_screen.dart';
import '../presentation/screens/onboarding/landing_screen.dart';
import '../presentation/screens/onboarding/persona_intro_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup/signup_screen.dart';
import '../presentation/screens/auth/signup/signup_watchlist_industry_screen.dart';
import '../presentation/screens/auth/signup/signup_watchlist_company_screen.dart';
import '../presentation/screens/auth/signup/signup_watchlist_result_screen.dart';
import '../presentation/screens/auth/signup/signup_complete_screen.dart';
import '../presentation/screens/auth/withdrawal/withdrawal_password_screen.dart';
import '../presentation/screens/auth/withdrawal/withdrawal_complete_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/company/company_detail_screen.dart';
import '../presentation/screens/company/company_chart_screen.dart';
import '../presentation/screens/company/company_news_list_screen.dart';
import '../presentation/screens/company/company_news_detail_screen.dart';
import '../presentation/screens/company/all_stocks_list_screen.dart';
import '../presentation/screens/etf/etf_detail_screen.dart';
import '../presentation/screens/news/all_news_list_screen.dart';
import '../presentation/screens/news/all_news_detail_screen.dart';
import '../presentation/screens/chat/chat_list_screen.dart';
import '../presentation/screens/chat/chat_room_screen.dart';
import '../presentation/screens/mypage/mypage_screen.dart';
import '../presentation/screens/mypage/watchlist_screen.dart';
import '../presentation/screens/mypage/watchlist_edit_screen.dart';
import '../presentation/screens/mypage/company_search_screen.dart';
import '../presentation/screens/mypage/password_change_screen.dart';
import '../presentation/screens/mypage/password_change_new_screen.dart';
import '../presentation/screens/mypage/ai_friend_change_screen.dart';
import '../presentation/screens/mypage/nickname_change.dart';
import '../presentation/screens/test_chat_screen.dart';

// Route Guards
import 'route_guards.dart';

/// 앱 전체 라우터 설정
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/test-chat',
        builder: (context, state) => const TestChatScreen(),
      ),

      // ==================== SPLASH & ONBOARDING ====================

      /// 스플래시 화면
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      /// 로딩 화면
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),

      /// 랜딩 페이지
      GoRoute(
        path: '/landing',
        name: 'landing',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LandingScreen(),
        ),
      ),

      /// 페르소나 소개
      GoRoute(
        path: '/persona-intro',
        name: 'persona-intro',
        builder: (context, state) => const PersonaIntroScreen(),
      ),

      //   // ==================== AUTH ====================
    //
    //   /// 로그인
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
    //
    //   /// 회원가입
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
    //
      /// 관심 종목 산업 선택
      GoRoute(
        path: '/signup/watchlist-industry',
        name: 'signup-watchlist-industry',
        builder: (context, state) => const SignupWatchlistIndustryScreen(),
      ),

      /// 관심 종목 기업 선택
      GoRoute(
        path: '/signup/watchlist-company',
        name: 'signup-watchlist-company',
        builder: (context, state) {
          final selectedIndustries = state.extra as Set<String>?;
          return SignupWatchlistCompanyScreen(
            selectedIndustries: selectedIndustries,
          );
        },
      ),

      /// 관심 종목 선택 결과
      GoRoute(
        path: '/signup/watchlist-result',
        name: 'signup-watchlist-result',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return SignupWatchlistResultScreen(
            selectedIndustries: data?['selectedIndustries'] as Set<String>?,
            selectedCompanies: data?['selectedCompanies'] as Set<String>?,
          );
        },
      ),

      // 닉네임 변경
      GoRoute(
        path: '/mypage/nickname-change',
        builder: (context, state) => const NicknameChangeScreen(),
      ),


      /// 회원가입 완료
      GoRoute(
        path: '/signup/complete',
        name: 'signup-complete',
        builder: (context, state) => const SignupCompleteScreen(),
      ),

      /// 회원탈퇴 - 비밀번호 확인
      GoRoute(
        path: '/withdrawal',
        name: 'withdrawal',
        builder: (context, state) => const WithdrawalPasswordScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 회원탈퇴 완료
      GoRoute(
        path: '/withdrawal/complete',
        name: 'withdrawal-complete',
        builder: (context, state) => const WithdrawalCompleteScreen(),
      ),

      // ==================== MAIN ====================

      /// 메인 화면 (탭 네비게이션)
      GoRoute(
        path: '/main',
        name: 'main',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainScreen(),
        ),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      // ==================== NEWS ====================

      /// 전체 뉴스 목록
      GoRoute(
        path: '/news',
        name: 'all-news-list',
        builder: (context, state) => const AllNewsListScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 전체 뉴스 상세 (추천 뉴스 상세)
      GoRoute(
        path: '/news/:id',
        name: 'all-news-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AllNewsDetailScreen(newsId: id);
        },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),
      // ==================== COMPANY ====================

      /// 전체 종목 보기 (미국 주식 + ETF)
      GoRoute(
        path: '/stocks/all',
        name: 'all-stocks-list',
        builder: (context, state) => const AllStocksListScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 기업 상세 정보 (차트/종목지표/주가예측 포함)
      GoRoute(
        path: '/company/:companyId',
        name: 'company-detail',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId']!;
          return CompanyDetailScreen(companyId: companyId);
        },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 기업 차트
      GoRoute(
        path: '/company/:companyId/chart',
        name: 'company-chart',
        builder: (context, state) => const CompanyChartScreen(),
        //param 데이터 주어질 때 이걸로 바꾸세요
        // builder: (context, state) {
        //   final companyId = state.pathParameters['companyId']!;
        //   return CompanyChartScreen(companyId: companyId);
        // },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 기업별 뉴스 목록
      GoRoute(
        path: '/company/:companyId/news',
        name: 'company-news-list',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId']!;
          return CompanyNewsListScreen(companyId: companyId);
        },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 기업별 뉴스 상세
      GoRoute(
        path: '/company/:companyId/news/:newsId',
        name: 'company-news-detail',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId']!;
          final newsId = state.pathParameters['newsId']!;
          return CompanyNewsDetailScreen(
            companyId: companyId,
            newsId: newsId,
          );
        },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      // ==================== ETF ====================

      /// ETF 상세 정보 (차트/종목정보/주가예측 포함)
      GoRoute(
        path: '/etf/:etfId',
        name: 'etf-detail',
        builder: (context, state) {
          final etfId = state.pathParameters['etfId']!;
          return ETFDetailScreen(etfId: etfId);
        },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      // ==================== CHAT ====================

      /// ✅ 채팅 목록 페이지
      GoRoute(
        path: '/chat',
        name: 'chat-list',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ChatListScreen(),
        ),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// ✅ 채팅방
      GoRoute(
        path: '/chat/:id',
        name: 'chat-room',
        builder: (context, state) {
          final sessionId = state.pathParameters['id']!;
          final autoMessage = state.uri.queryParameters['autoMessage'];
          return ChatRoomScreen(
            sessionId: sessionId,
            autoMessage: autoMessage,
          );
        },
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      // ==================== MY PAGE ====================

      /// 마이페이지 메인
      GoRoute(
        path: '/mypage',
        name: 'mypage',
        builder: (context, state) => const MypageScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 관심 종목 리스트
      GoRoute(
        path: '/mypage/watchlist',
        name: 'watchlist',
        builder: (context, state) => const WatchlistScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 관심 종목 수정
      GoRoute(
        path: '/mypage/watchlist/edit',
        name: 'watchlist-edit',
        builder: (context, state) => const WatchlistEditScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 기업 검색
      GoRoute(
        path: '/mypage/company-search',
        name: 'company-search',
        builder: (context, state) => const CompanySearchScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),

      /// 비밀번호 변경
      GoRoute(
        path: '/mypage/password-change',
        name: 'password-change',
        builder: (context, state) => const PasswordChangeScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),
      /// 비밀번호 변경
      GoRoute(
        path: '/mypage/password-change/password-change-new',
        name: 'password-change-new',
        builder: (context, state) => const PasswordChangeNewScreen(),
        // redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),
      /// AI 친구 변경
      GoRoute(
        path: '/mypage/ai-friend',
        name: 'ai-friend-change',
        builder: (context, state) => const AiFriendChangeScreen(),
        redirect: (context, state) => RouteGuards.requireAuth(context, state),
      ),
    ],
  );
}