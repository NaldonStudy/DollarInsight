import 'package:flutter/material.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_button.dart';
import 'package:go_router/go_router.dart';

class AiFriendChangeScreen extends StatefulWidget {
  const AiFriendChangeScreen({super.key});

  @override
  State<AiFriendChangeScreen> createState() => _AiFriendChangeScreenState();
}

class _AiFriendChangeScreenState extends State<AiFriendChangeScreen> {
  // ✅ 5개 모두 선택된 상태로 시작
  List<bool> selected = [true, true, true, true, true];

  // ✅ 캐릭터 리스트 (이름 + 이미지 경로 설정)
  final List<Map<String, String>> friends = [
    {"name": "희열", "image": "assets/images/Heeyule.png"},
    {"name": "지율", "image": "assets/images/Jiyule.png"},
    {"name": "덕수", "image": "assets/images/Ducksu.png"},
    {"name": "테오", "image": "assets/images/Taeo.png"},
    {"name": "민지", "image": "assets/images/Minji.png"},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.091),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.02),

              /// ✅ 타이틀
              Text(
                "원하는 AI 친구를\n선택해주세요",
                style: TextStyle(
                  fontSize: w * 0.083, // 30px
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),

              SizedBox(height: h * 0.03),

              /// ✅ 캐릭터 Grid
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friends.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: h * 0.005,
                    crossAxisSpacing: w * 0.09,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    return _buildFriendItem(
                      w: w,
                      h: h,
                      index: index,
                      name: friends[index]["name"]!,
                      image: friends[index]["image"]!,
                    );
                  },
                ),
              ),

              SizedBox(height: h * 0.02),

              /// ✅ 변경 버튼
              CustomButton(
                text: "변경",
                onPressed: () {
                  context.go('/mypage');

                  Future.delayed(const Duration(milliseconds: 100), () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("AI 친구가 변경되었습니다."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                },
              ),

              SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ 캐릭터 1개 UI
  Widget _buildFriendItem({
    required double w,
    required double h,
    required int index,
    required String name,
    required String image,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected[index] = !selected[index]; // 선택 토글
        });
      },
      child: Column(
        children: [
          Container(
            width: w * 0.28,
            height: w * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected[index] ? const Color(0xFF31C275) : Colors.transparent,
                width: w * 0.015, // 반응형 테두리
              ),
            ),
            child: Container(
              margin: EdgeInsets.all(w * 0.015),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.015),

          /// ✅ 이름
          Text(
            name,
            style: TextStyle(
              fontSize: w * 0.038,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
