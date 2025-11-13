import 'package:intl/intl.dart';

/// 날짜 포맷팅 유틸리티
class DateFormatter {
  /// ISO 8601 UTC 시간을 한국 시간으로 변환 후 포맷팅
  ///
  /// 예시:
  /// - 입력: "2025-11-13T01:20:07Z"
  /// - 출력: "2025년 11월 13일 10:20"
  static String formatToKorean(String isoDateString) {
    try {
      // UTC 시간 파싱
      final utcDateTime = DateTime.parse(isoDateString);

      // 한국 시간으로 변환 (UTC+9)
      final koreaDateTime = utcDateTime.toLocal();

      // 한국어 포맷으로 변환
      return DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR').format(koreaDateTime);
    } catch (e) {
      // 파싱 실패 시 원본 반환
      return isoDateString;
    }
  }

  /// 간단한 날짜 포맷 (년-월-일)
  ///
  /// 예시: "2025.11.13"
  static String formatToSimple(String isoDateString) {
    try {
      final utcDateTime = DateTime.parse(isoDateString);
      final koreaDateTime = utcDateTime.toLocal();

      return DateFormat('yyyy.MM.dd').format(koreaDateTime);
    } catch (e) {
      return isoDateString;
    }
  }

  /// 상대 시간 표시 (몇 분 전, 몇 시간 전 등)
  ///
  /// 예시: "10분 전", "2시간 전", "3일 전"
  static String formatToRelative(String isoDateString) {
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
      return isoDateString;
    }
  }
}
