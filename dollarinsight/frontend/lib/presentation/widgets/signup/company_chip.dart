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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 사용 가능한 너비의 90%를 로고 크기로 사용
          final logoSize = (constraints.maxWidth * 0.9).clamp(60.0, 80.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 원형 로고 컨테이너 (초록색 border)
              Container(
                width: logoSize,
                height: logoSize,
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
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 로고 로드 실패 시 대체 아이콘
                        return Icon(
                          Icons.business,
                          color: const Color(0xFF757575),
                          size: logoSize * 0.5,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // 회사 이름
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    companyName.length > 12
                        ? '${companyName.substring(0, 12)}...'
                        : companyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: 0.36,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
