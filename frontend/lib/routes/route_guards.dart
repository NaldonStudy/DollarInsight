import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 라우트 가드 - 페이지 접근 권한 체크
class RouteGuards {

  /// ✅ 디버깅 시 가드 비활성화 스위치
  /// debugDisableGuards = true → 모든 가드 무효
  /// 실제 배포 시 false 로 변경하면 정상 동작
  static const bool debugDisableGuards = true; // ✅ 디버그 중에는 true

  /// 로그인 필요 여부 체크
  static Future<String?> requireAuth(BuildContext context, GoRouterState state) async {
    // ✅ 디버그 모드: 가드 비활성화
    if (debugDisableGuards) return null;

    final isLoggedIn = await _checkLoginStatus();

    if (!isLoggedIn) {
      return '/login';
    }

    return null;
  }

  /// 로그인 상태 확인 (비로그인만 접근 가능)
  static Future<String?> requireGuest(BuildContext context, GoRouterState state) async {
    // ✅ 디버그 모드: 가드 비활성화
    if (debugDisableGuards) return null;

    final isLoggedIn = await _checkLoginStatus();

    if (isLoggedIn) {
      return '/main';
    }

    return null;
  }

  /// 실제 로그인 상태 확인 로직
  static Future<bool> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return false;
      }

      // TODO: 토큰 만료 확인 / 서버 검증

      return true;
    } catch (e) {
      print('로그인 상태 확인 실패: $e');
      return false;
    }
  }

  /// 권한 체크
  static Future<String?> requireRole(
      BuildContext context,
      GoRouterState state,
      String requiredRole,
      ) async {
    // ✅ 디버그 모드: 가드 비활성화
    if (debugDisableGuards) return null;

    final isLoggedIn = await _checkLoginStatus();
    if (!isLoggedIn) {
      return '/login';
    }

    final userRole = await _getUserRole();
    if (userRole != requiredRole) {
      return '/main';
    }

    return null;
  }

  /// 사용자 권한 가져오기
  static Future<String> _getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role') ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  /// 온보딩 체크
  static Future<String?> checkOnboarding(BuildContext context, GoRouterState state) async {
    // ✅ 디버그 모드: 가드 비활성화
    if (debugDisableGuards) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('completed_onboarding') ?? false;

      if (!hasCompletedOnboarding) {
        return '/landing';
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
