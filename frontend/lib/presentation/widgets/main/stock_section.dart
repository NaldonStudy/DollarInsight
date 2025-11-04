import 'package:flutter/material.dart';

class StockSection extends StatelessWidget {
  final double w;
  final double h;

  const StockSection({super.key, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("추천 관심종목",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(
              "전체보기",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA9A9A9),
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.01),
        Container(
          height: h * 0.55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
