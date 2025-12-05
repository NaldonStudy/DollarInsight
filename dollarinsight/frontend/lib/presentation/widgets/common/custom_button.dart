import 'package:flutter/material.dart';

/// 재사용 가능한 커스텀 버튼 위젯
/// ElevatedButton 기반으로 구현하여 접근성, 시각적 피드백(물결 효과), 일관된 스타일링 제공
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF143D60),
    this.textColor = Colors.white,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.borderRadius = 30,
    this.width,
    this.height = 56, // Material Design 가이드라인 기본 높이
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0, // 플랫한 디자인
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
