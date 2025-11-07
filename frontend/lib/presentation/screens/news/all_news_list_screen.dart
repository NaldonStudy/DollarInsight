import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';

class AllNewsListScreen extends StatefulWidget {
  const AllNewsListScreen({super.key});

  @override
  State<AllNewsListScreen> createState() => _AllNewsListScreenState();
}

class _AllNewsListScreenState extends State<AllNewsListScreen> {
  bool isCompany = true; // 상단 탭: 기업분석 / 채팅 선택 상태

  // 뉴스 목록 (더미 데이터 기반)
  List<String> newsList = [];

  // 각 뉴스의 펼침 여부 상태값 (index 1:1 매칭)
  List<bool> isOpen = [];

  // 스크롤 컨트롤러 (무한 스크롤 감지용)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 초기 뉴스 15개 세팅
    _addNews(List.generate(
        15, (i) => "더미 뉴스 ${i + 1}입니다. 클릭해서 펼쳐보세요."));

    // 스크롤 끝 근처(200px) 도착 시 → 다음 뉴스 자동 로드
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreNews();
      }
    });
  }

  // 새로운 뉴스 데이터가 들어올 때
  // 1) 뉴스 리스트에 추가
  // 2) 펼침 여부 리스트(isOpen)도 같은 길이만큼 false로 추가
  //    → '펼침 상태' 관리용 데이터 동기화
  void _addNews(List<String> items) {
    newsList.addAll(items);
    isOpen.addAll(List<bool>.filled(items.length, false));
    setState(() {});
  }

  // 무한 스크롤 시 추가로 10개씩 뉴스 생성
  void _loadMoreNews() {
    final moreItems = List.generate(
      10,
          (i) => "더미 뉴스 (추가) ${newsList.length + i + 1}",
    );
    _addNews(moreItems);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 (기업분석 / 채팅 탭 포함)
            TopNavigation(
              w: w,
              h: h,
              isCompany: isCompany,
              onTapCompany: () => setState(() => isCompany = true),
              onTapChat: () => setState(() => isCompany = false),
              onProfileTap: () => context.push('/mypage'),
            ),

            if (isCompany) SizedBox(height: AppSpacing.section(context)),

            // 탭 전환 (기업분석일 때 뉴스 리스트 표시 / 채팅 탭일 때 채팅 화면 표시)
            Expanded(
              child:
              isCompany ? _buildNewsBody(context, w, h) : const ChatListScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // 전체 뉴스 영역 UI
  Widget _buildNewsBody(BuildContext context, double w, double h) {
    return SingleChildScrollView(
      controller: _scrollController, // 스크롤 기반 무한 로딩
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 실시간 채팅 카드
          LiveChatCard(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          // 섹션 타이틀
          Text(
            "전체 뉴스",
            style: TextStyle(
              fontSize: w * 0.06,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: AppSpacing.small(context)),

          // 뉴스 리스트를 감싸는 카드 박스
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Column(
              children: List.generate(
                newsList.length,
                    (index) => Column(
                  children: [
                    // 개별 뉴스 아이템
                    _expandableNewsItem(
                      index: index,
                      w: w,
                      h: h,
                      text: newsList[index],
                    ),

                    // 뉴스 사이 구분선
                    if (index != newsList.length - 1) _divider(h),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }

  // 리스트 아이템 사이 구분선을 그리는 위젯
  Widget _divider(double h) => Container(
    height: h * 0.0012,
    color: const Color(0xFFE0E0E0),
  );

  // 개별 뉴스 아이템 UI
  // - 클릭 시 펼침 / 접힘
  // - 펼침 상태일 때 아래 버튼(요약 / 채팅) 노출
  Widget _expandableNewsItem({
    required int index,
    required double w,
    required double h,
    required String text,
  }) {
    return InkWell(
      onTap: () {
        // 뉴스 하나를 클릭하면 펼침 상태 토글(true <-> false)
        setState(() {
          isOpen[index] = !isOpen[index];
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.018,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 뉴스 제목 텍스트
            Text(
              text,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            // 아래 버튼(요약/채팅) 애니메이션 열림/닫힘 처리
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isOpen[index]
                  ? CrossFadeState.showSecond // 펼쳐진 상태
                  : CrossFadeState.showFirst, // 접힌 상태
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: h * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // AI 요약 버튼 → 상세 페이지 이동
                    _actionButton(
                      label: "AI 요약",
                      bgColor: const Color(0xFF143D60),
                      w: w,
                      h: h,
                      onTap: () {
                        context.push('/news/$index'); // 뉴스 상세로 이동
                      },
                    ),

                    // AI 채팅 버튼
                    _actionButton(
                      label: "채팅하기",
                      bgColor: const Color(0xFFAEC6F7),
                      w: w,
                      h: h,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  공통 버튼 UI ("AI 요약", "채팅하기" 버튼)
  Widget _actionButton({
    required String label,
    required Color bgColor,
    required double w,
    required double h,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.08,
          vertical: h * 0.012,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(w * 0.12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: w * 0.04,
          ),
        ),
      ),
    );
  }
}
