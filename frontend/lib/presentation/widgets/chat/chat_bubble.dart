import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String imagePath;
  final double w;
  final double h;

  const ChatBubble({
    super.key,
    required this.text,
    required this.imagePath,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ✅ 캐릭터 이미지
        Container(
          width: w * 0.12,
          height: w * 0.12,
          margin: EdgeInsets.only(right: w * 0.03),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),

        /// ✅ 말풍선
        Expanded(
          child: Container(
            padding: EdgeInsets.all(w * 0.035),   // ✅ 반응형 padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),

              /// ✅ 연한 테두리 추가
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: w * 0.038,  // ✅ (약 14~15px)
                height: 1.5,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
