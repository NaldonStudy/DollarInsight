import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 날짜 포맷팅 유틸리티
class DateFormatter {
  /// ISO 8601 UTC 시간을 한국 시간으로 변환 후 포맷팅
  ///
  /// 예시:
  /// - 입력: "2025-11-13T01:20:07Z"
  /// - 출력: "2025년 11월 13일 10:20"
  static String formatToKorean(String? isoDateString) {
    if (isoDateString == null || isoDateString.isEmpty) {
      return '날짜 정보 없음';
    }

    try {
      // UTC 시간 파싱
      final utcDateTime = DateTime.parse(isoDateString);

      // 한국 시간으로 변환 (UTC+9)
      final koreaDateTime = utcDateTime.toLocal();

      // 한국어 포맷으로 변환
      return DateFormat('yyyy년 MM월 dd일 HH:mm').format(koreaDateTime);
    } catch (e) {
      // 디버그 모드에서 에러 로깅
      if (kDebugMode) {
        print('[DateFormatter] 날짜 파싱 실패: $isoDateString, 에러: $e');
      }
      // 사용자에게는 친화적인 메시지 표시
      return '날짜 정보 없음';
    }
  }

  /// 간단한 날짜 포맷 (년-월-일)
  ///
  /// 예시: "2025.11.13"
  static String formatToSimple(String? isoDateString) {
    if (isoDateString == null || isoDateString.isEmpty) {
      return '-';
    }

    try {
      final utcDateTime = DateTime.parse(isoDateString);
      final koreaDateTime = utcDateTime.toLocal();

      return DateFormat('yyyy.MM.dd').format(koreaDateTime);
    } catch (e) {
      if (kDebugMode) {
        print('[DateFormatter] 날짜 파싱 실패: $isoDateString, 에러: $e');
      }
      return '-';
    }
  }

  /// 상대 시간 표시 (몇 분 전, 몇 시간 전 등)
  ///
  /// 예시: "10분 전", "2시간 전", "3일 전"
  static String formatToRelative(String? isoDateString) {
    if (isoDateString == null || isoDateString.isEmpty) {
      return '-';
    }

    try {
      final utcDateTime = DateTime.parse(isoDateString);
      final koreaDateTime = utcDateTime.toLocal();
      final now = DateTime.now();
      final difference = now.difference(koreaDateTime);

      if (difference.inSeconds < 60) {
        return '방금 전';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return formatToSimple(isoDateString);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DateFormatter] 날짜 파싱 실패: $isoDateString, 에러: $e');
      }
      return '-';
    }
  }
}
