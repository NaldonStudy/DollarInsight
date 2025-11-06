import 'package:flutter/material.dart';

/// 회원가입 - 관심 기업 선택 칩 위젯
class CompanyChip extends StatelessWidget {
  final String companyName;
  final String logoPath;
  final bool isSelected;
  final VoidCallback onTap;

  const CompanyChip({
    super.key,
    required this.companyName,
    required this.logoPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 원형 로고 컨테이너 (초록색 border)
          Container(
            width: 80,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF31C275) : Colors.transparent,
                width: 5,
              ),
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Image.asset(
                  logoPath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 로고 로드 실패 시 대체 아이콘
                    return const Icon(
                      Icons.business,
                      color: Color(0xFF757575),
                      size: 40,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 회사 이름
          SizedBox(
            width: 80,
            child: Text(
              companyName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 13,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: 0.39,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
