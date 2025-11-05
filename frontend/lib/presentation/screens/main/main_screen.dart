import 'package:flutter/material.dart';
import '../../widgets/main/live_chat_card.dart';
import '../../widgets/main/index_section.dart';
import '../../widgets/main/news_section.dart';
import '../../widgets/main/stock_section.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  bool showFab = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.offset > 40 && !showFab) {
        setState(() => showFab = true);
      }
      if (_scrollController.offset <= 40 && showFab) {
        setState(() => showFab = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(w, h),
            SizedBox(height: h * 0.02),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: w * 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LiveChatCard(w: w, h: h),
                    SizedBox(height: h * 0.03),

                    IndexSection(w: w, h: h),
                    SizedBox(height: h * 0.03),

                    NewsSection(w: w, h: h),
                    SizedBox(height: h * 0.03),

                    StockSection(w: w, h: h),
                    SizedBox(height: h * 0.25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: AnimatedScale(
        scale: showFab ? 1 : 0,
        duration: const Duration(milliseconds: 230),
        child: AnimatedOpacity(
          opacity: showFab ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            width: w * 0.15,
            height: w * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF8FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/images/main8.png",
                width: w * 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Top Navigation
  Widget _buildTopNavigation(double w, double h) {
    return Padding(
      padding: EdgeInsets.only(top: h * 0.015, left: w * 0.06, right: w * 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset("assets/images/logomini.png", width: w * 0.1),

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

          SizedBox(width: w * 0.08),
        ],
      ),
    );
  }
}
