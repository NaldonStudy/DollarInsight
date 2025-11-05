import 'package:flutter/material.dart';

class IndexSection extends StatelessWidget {
  final double w;
  final double h;

  const IndexSection({super.key, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "주요 지수",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: h * 0.008),
        Container(
          height: h * 0.06,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: w * 0.045),
          child: Row(
            children: const [
              Text("S&P 500", style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(width: 10),
              Text(
                "(더미)▲ 6,875.16  +83.47(1.2%)",
                style: TextStyle(color: Color(0xFFFF171B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
