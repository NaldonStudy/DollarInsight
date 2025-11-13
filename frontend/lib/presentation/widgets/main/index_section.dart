import 'package:flutter/material.dart';
import '../../../data/models/dashboard_model.dart';

class IndexSection extends StatelessWidget {
  final double w;
  final double h;
  final List<MajorIndex> majorIndices;

  const IndexSection({
    super.key,
    required this.w,
    required this.h,
    required this.majorIndices,
  });

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

        // ✅ 데이터가 없는 경우
        if (majorIndices.isEmpty)
          Container(
            height: h * 0.06,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: w * 0.045),
            child: const Center(
              child: Text(
                "주요 지수 정보가 없습니다",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          // ✅ 주요 지수 목록
          ...majorIndices.map((index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: h * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  child: Row(
                    children: [
                      Text(
                        index.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${index.changePct >= 0 ? '▲' : '▼'} ${index.close.toStringAsFixed(2)}  ${index.changePct >= 0 ? '+' : ''}${index.changePct.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: index.changePct >= 0
                              ? const Color(0xFFFF171B)
                              : const Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
