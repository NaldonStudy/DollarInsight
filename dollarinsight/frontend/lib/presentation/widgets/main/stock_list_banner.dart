import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 전체 종목 보기로 이동하는 배너 위젯
class StockListBanner extends StatelessWidget {
  final double w;
  final double h;

  const StockListBanner({super.key, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 전체 종목 보기 스크린으로 이동
        context.push('/stocks/all');
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned(
              left: w * 0.05,
              top: 15,
              child: const Text(
                "기업 알아보기",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            Positioned(
              right: w * 0.06,
              top: 5,
              child: Image.asset(
                "assets/images/main8.webp",
                width: w * 0.14,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
