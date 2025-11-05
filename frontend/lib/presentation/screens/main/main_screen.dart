import 'package:flutter/material.dart';
import '../../widgets/main/live_chat_card.dart';
import '../../widgets/main/index_section.dart';
import '../../widgets/main/news_section.dart';
import '../../widgets/main/stock_section.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/common/scroll_fab_button.dart';
import 'package:go_router/go_router.dart';

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
      setState(() {
        showFab = _scrollController.offset > 40;
      });
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
            TopNavigation(
              w: w,
              h: h,
              onProfileTap: () => context.push("/mypage"),  // ✅ push로 스택 쌓기!
            ),
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

      floatingActionButton: ScrollFabButton(
        w: w,
        showFab: showFab,
        onTap: () {
          print("FAB Tapped!");
        },
      ),
    );
  }
}
