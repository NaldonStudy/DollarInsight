import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../data/models/dashboard_model.dart';

class IndexSection extends StatefulWidget {
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
  State<IndexSection> createState() => _IndexSectionState();
}

class _IndexSectionState extends State<IndexSection> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 5초마다 다음 지수로 자동 넘김
    if (widget.majorIndices.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_currentPage < widget.majorIndices.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "주요 지수",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: widget.h * 0.008),

        // ✅ 데이터가 없는 경우
        if (widget.majorIndices.isEmpty)
          Container(
            height: widget.h * 0.06,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: widget.w * 0.045),
            child: const Center(
              child: Text(
                "주요 지수 정보가 없습니다",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
        // ✅ PageView로 하나씩 표시
          SizedBox(
            height: widget.h * 0.06,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              // 위로 넘어가기
              itemCount: widget.majorIndices.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final majorIndex = widget.majorIndices[index];
                final numberFormatter = NumberFormat('#,##0.00');
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: widget.w * 0.045),
                  child: Row(
                    children: [
                      Text(
                        majorIndex.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${majorIndex.changePct >= 0 ? '▲' : '▼'} ${numberFormatter.format(majorIndex.close)}  ${majorIndex.changePct >= 0 ? '+' : ''}${majorIndex.changePct.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: majorIndex.changePct >= 0
                              ? const Color(0xFFFF171B)
                              : const Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}