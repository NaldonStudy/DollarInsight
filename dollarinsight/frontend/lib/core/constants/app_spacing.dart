import 'package:flutter/material.dart';

/// 앱 전체 여백을 통일해서 관리하는 클래스
class AppSpacing {
  /// ✅ 좌우 기본 여백 (전체 앱 동일)
  static double horizontal(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.07; // 7%
  }

  /// ✅ 기본 섹션 간격(기업분석/뉴스/지수 등)
  static double section(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.03; // 3%
  }

  /// ✅ 매우 작은 여백 (아이콘/텍스트 바로 옆)
  static double extraSmall(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.008; // 0.8%
  }

  /// ✅ 작은 여백 (텍스트/이미지 사이)
  static double small(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.015; // 1.5%
  }

  /// ✅ 중간 여백
  static double medium(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.02; // 2%
  }

  /// ✅ 큰 여백 (예: LiveChatCard → 이미지)
  static double big(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.06; // 6%
  }

  /// ✅ 맨 아래 큰 여백
  static double bottomLarge(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.05; // 5%
  }
}
