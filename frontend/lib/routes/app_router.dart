import 'package:go_router/go_router.dart';

// Screens imports

import '../presentation/screens/onboarding/landing_screen.dart';
import '../presentation/screens/onboarding/loading_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup/signup_screen.dart';
import '../presentation/screens/auth/signup/interest_stock_select_screen.dart';
// import '../presentation/screens/auth/signup/signup_complete_screen.dart';
// import '../presentation/screens/auth/withdrawal/withdrawal_password_screen.dart';
// import '../presentation/screens/auth/withdrawal/withdrawal_complete_screen.dart';
// import '../presentation/screens/main/main_screen.dart';
// import '../presentation/screens/company/company_detail_screen.dart';
// import '../presentation/screens/company/company_chart_screen.dart';
// import '../presentation/screens/company/news_list_screen.dart';
// import '../presentation/screens/company/news_detail_screen.dart';
// import '../presentation/screens/chat/chat_room_screen.dart';
// import '../presentation/screens/mypage/mypage_screen.dart';
// import '../presentation/screens/mypage/interest_stock_list_screen.dart';
// import '../presentation/screens/mypage/interest_stock_edit_screen.dart';
// import '../presentation/screens/mypage/password_change_screen.dart';
// import '../presentation/screens/mypage/ai_friend_change_screen.dart';

// Route Guards
import 'route_guards.dart';

/// 앱 전체 라우터 설정
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [

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
        builder: (context, state) => const LandingScreen(),
      ),

    //   /// 페르소나 소개
    //   GoRoute(
    //     path: '/persona-intro',
    //     name: 'persona-intro',
    //     builder: (context, state) => const PersonaIntroScreen(),
    //   ),
    //
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
    //   /// 관심 종목 선택
    //   GoRoute(
    //     path: '/signup/interest',
    //     name: 'signup-interest',
    //     builder: (context, state) => const InterestStockSelectScreen(),
    //   ),
    //
    //   /// 회원가입 완료
    //   GoRoute(
    //     path: '/signup/complete',
    //     name: 'signup-complete',
    //     builder: (context, state) => const SignupCompleteScreen(),
    //   ),
    //
    //   /// 회원탈퇴 - 비밀번호 확인
    //   GoRoute(
    //     path: '/withdrawal',
    //     name: 'withdrawal',
    //     builder: (context, state) => const WithdrawalPasswordScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 회원탈퇴 완료
    //   GoRoute(
    //     path: '/withdrawal/complete',
    //     name: 'withdrawal-complete',
    //     builder: (context, state) => const WithdrawalCompleteScreen(),
    //   ),
    //
    //   // ==================== MAIN ====================
    //
    //   /// 메인 화면 (탭 네비게이션)
    //   GoRoute(
    //     path: '/main',
    //     name: 'main',
    //     builder: (context, state) => const MainScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   // ==================== COMPANY ====================
    //
    //   /// 기업 상세 정보
    //   GoRoute(
    //     path: '/company/:id',
    //     name: 'company-detail',
    //     builder: (context, state) {
    //       final id = state.pathParameters['id']!;
    //       return CompanyDetailScreen(companyId: id);
    //     },
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 기업 차트
    //   GoRoute(
    //     path: '/company/:id/chart',
    //     name: 'company-chart',
    //     builder: (context, state) {
    //       final id = state.pathParameters['id']!;
    //       return CompanyChartScreen(companyId: id);
    //     },
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 뉴스 목록
    //   GoRoute(
    //     path: '/company/:id/news',
    //     name: 'news-list',
    //     builder: (context, state) {
    //       final id = state.pathParameters['id']!;
    //       return NewsListScreen(companyId: id);
    //     },
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 뉴스 상세
    //   GoRoute(
    //     path: '/news/:id',
    //     name: 'news-detail',
    //     builder: (context, state) {
    //       final id = state.pathParameters['id']!;
    //       return NewsDetailScreen(newsId: id);
    //     },
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   // ==================== CHAT ====================
    //
    //   /// 채팅방
    //   GoRoute(
    //     path: '/chat/:id',
    //     name: 'chat-room',
    //     builder: (context, state) {
    //       final id = state.pathParameters['id']!;
    //       return ChatRoomScreen(chatId: id);
    //     },
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   // ==================== MY PAGE ====================
    //
    //   /// 마이페이지 메인
    //   GoRoute(
    //     path: '/mypage',
    //     name: 'mypage',
    //     builder: (context, state) => const MyPageScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 관심 종목 리스트
    //   GoRoute(
    //     path: '/mypage/interest-stocks',
    //     name: 'interest-stocks',
    //     builder: (context, state) => const InterestStockListScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 관심 종목 수정
    //   GoRoute(
    //     path: '/mypage/interest-stocks/edit',
    //     name: 'interest-stocks-edit',
    //     builder: (context, state) => const InterestStockEditScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// 비밀번호 변경
    //   GoRoute(
    //     path: '/mypage/password-change',
    //     name: 'password-change',
    //     builder: (context, state) => const PasswordChangeScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    //
    //   /// AI 친구 변경
    //   GoRoute(
    //     path: '/mypage/ai-friend',
    //     name: 'ai-friend-change',
    //     builder: (context, state) => const AiFriendChangeScreen(),
    //     redirect: (context, state) => RouteGuards.requireAuth(context, state),
    //   ),
    ],
  );
}