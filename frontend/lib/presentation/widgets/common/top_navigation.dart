import 'package:flutter/material.dart';

class TopNavigation extends StatelessWidget {
  final double w;
  final double h;
  final VoidCallback onProfileTap;

  const TopNavigation({
    super.key,
    required this.w,
    required this.h,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: h * 0.015, left: w * 0.06, right: w * 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// ✅ 로고
          Image.asset(
            "assets/images/logomini.png",
            width: w * 0.1,
          ),

          /// ✅ 가운데 탭
          Container(
            width: w * 0.42,
            height: h * 0.045,
            decoration: BoxDecoration(
              color: const Color(0xFFABCEEA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: w * 0.01,
                  top: h * 0.005,
                  child: Container(
                    width: w * 0.20,
                    height: h * 0.035,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: Text(
                        "기업분석",
                        style: TextStyle(
                          color: Color(0xFF60A4DA),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: w * 0.075,
                  top: h * 0.011,
                  child: const Text(
                    "채팅",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ✅ 프로필 아이콘
          GestureDetector(
            onTap: onProfileTap,
            child: Icon(
              Icons.person_outline,
              size: w * 0.085,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
