import 'package:flutter/material.dart';

/// 재사용 가능한 관심종목 추가/삭제 버튼 위젯
/// 관심종목 수정, 기업 상세 페이지 등에서 사용
class WatchButton extends StatelessWidget {
  final bool isWatching;
  final VoidCallback onTap;
  final double size;

  const WatchButton({
    super.key,
    required this.isWatching,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        isWatching ? Icons.favorite : Icons.favorite_border,
        color: isWatching ? const Color(0xFFFF5252) : const Color(0xFF757575),
        size: size,
      ),
    );
  }
}
