import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 라우트 가드 - 페이지 접근 권한 체크
class RouteGuards {
  /// 로그인 필요 여부 체크
  /// 로그인이 필요한 페이지에서 사용
  static Future<String?> requireAuth(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await _checkLoginStatus();

    if (!isLoggedIn) {
      // 로그인되지 않은 경우 로그인 페이지로 리다이렉트
      return '/login';
    }

    // 로그인된 경우 null 반환 (정상 진행)
    return null;
  }

  /// 로그인 상태 확인 (미로그인 시에만 접근 가능)
  /// 로그인 페이지, 회원가입 페이지 등에서 사용
  static Future<String?> requireGuest(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await _checkLoginStatus();

    if (isLoggedIn) {
      // 이미 로그인된 경우 메인 페이지로 리다이렉트
      return '/main';
    }

    // 미로그인 상태면 null 반환 (정상 진행)
    return null;
  }

  /// 실제 로그인 상태 확인 로직
  static Future<bool> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // SharedPreferences에서 토큰 확인
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        return false;
      }

      // TODO: 추가 검증 로직
      // - 토큰 만료 시간 확인
      // - 서버에 토큰 유효성 검증 요청

      return true;
    } catch (e) {
      print('로그인 상태 확인 실패: $e');
      return false;
    }
  }

  /// 특정 권한 필요 여부 체크
  /// 예: 관리자 전용 페이지
  static Future<String?> requireRole(
      BuildContext context,
      GoRouterState state,
      String requiredRole,
      ) async {
    final isLoggedIn = await _checkLoginStatus();

    if (!isLoggedIn) {
      return '/login';
    }

    // TODO: 사용자 권한 확인 로직
    final userRole = await _getUserRole();

    if (userRole != requiredRole) {
      // 권한이 없는 경우 메인 페이지로
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

  /// 온보딩 완료 여부 체크
  static Future<String?> checkOnboarding(BuildContext context, GoRouterState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('completed_onboarding') ?? false;

      if (!hasCompletedOnboarding) {
        // 온보딩 미완료 시 랜딩 페이지로
        return '/landing';
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}