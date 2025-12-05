// persona_mapper.dart
// AI 페르소나의 영어 코드를 한글 이름 및 이미지와 매핑하는 유틸리티

class PersonaMapper {
  // 영어 speaker 코드를 한글 이름으로 매핑
  static const Map<String, String> _speakerToKoreanName = {
    'heuyeol': '희열',
    'jiyul': '지율',
    'minji': '민지',
    'deoksu': '덕수',
    'teo': '테오',
  };

  // 한글 이름을 이미지 경로로 매핑
  static const Map<String, String> _nameToImagePath = {
    '희열': 'assets/images/heuyeol.webp',
    '지율': 'assets/images/jiyul.webp',
    '민지': 'assets/images/minji.webp',
    '덕수': 'assets/images/deoksu.webp',
    '테오': 'assets/images/teo.webp',
  };

  /// 영어 speaker 코드를 한글 이름으로 변환
  ///
  /// 예: 'heuyeol' -> '희열'
  static String getKoreanName(String? speakerCode) {
    if (speakerCode == null) return 'AI 어시스턴트';

    final lowerCode = speakerCode.toLowerCase();
    return _speakerToKoreanName[lowerCode] ?? 'AI 어시스턴트';
  }

  /// 한글 이름 또는 영어 코드를 받아 이미지 경로 반환
  ///
  /// 예: '희열' -> 'assets/images/heuyeol.webp'
  ///     'heuyeol' -> 'assets/images/heuyeol.webp'
  static String getImagePath(String? nameOrCode) {
    if (nameOrCode == null) return 'assets/images/deoksu.webp'; // 기본값

    // 먼저 한글 이름으로 직접 찾기
    if (_nameToImagePath.containsKey(nameOrCode)) {
      return _nameToImagePath[nameOrCode]!;
    }

    // 영어 코드인 경우 한글로 변환 후 이미지 경로 찾기
    final koreanName = getKoreanName(nameOrCode);
    return _nameToImagePath[koreanName] ?? 'assets/images/deoksu.webp';
  }

  /// speaker 코드가 유효한지 확인
  static bool isValidSpeaker(String? speakerCode) {
    if (speakerCode == null) return false;
    return _speakerToKoreanName.containsKey(speakerCode.toLowerCase());
  }

  /// 모든 페르소나의 한글 이름 목록 반환
  static List<String> getAllKoreanNames() {
    return _speakerToKoreanName.values.toList();
  }

  /// 모든 페르소나의 영어 코드 목록 반환
  static List<String> getAllSpeakerCodes() {
    return _speakerToKoreanName.keys.toList();
  }
}
