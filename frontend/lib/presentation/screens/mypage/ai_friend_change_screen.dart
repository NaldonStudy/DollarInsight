import 'package:flutter/material.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_button.dart';
import 'package:go_router/go_router.dart';
import '../../../data/datasources/remote/user_api.dart';

class AiFriendChangeScreen extends StatefulWidget {
  const AiFriendChangeScreen({super.key});

  @override
  State<AiFriendChangeScreen> createState() => _AiFriendChangeScreenState();
}

class _AiFriendChangeScreenState extends State<AiFriendChangeScreen> {
  // ✅ API에서 가져온 전체 페르소나 목록
  List<Map<String, dynamic>> _allPersonas = [];

  // ✅ 각 AI 친구의 활성화 상태
  List<bool> _selected = [];
  bool _isLoading = true;

  // ✅ 코드 -> 한글 이름 매핑
  String _getNameByCode(String code) {
    final Map<String, String> nameMap = {
      'minji': '민지',
      'teo': '테오',
      'deoksu': '덕수',
      'heuyeol': '희열',
      'jiyul': '지율',
    };
    return nameMap[code.toLowerCase()] ?? code;
  }

  // ✅ 코드 -> 이미지 경로 매핑
  String _getImageByCode(String code) {
    final Map<String, String> imageMap = {
      'minji': 'assets/images/minji.webp',
      'teo': 'assets/images/teo.webp',
      'deoksu': 'assets/images/deoksu.webp',
      'heuyeol': 'assets/images/heuyeol.webp',
      'jiyul': 'assets/images/jiyul.webp',
    };
    return imageMap[code.toLowerCase()] ?? 'assets/images/heuyeol.webp';
  }

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  /// ✅ 페르소나 목록 로드
  Future<void> _loadPersonas() async {
    try {
      // 1. 전체 페르소나 목록 가져오기
      final allPersonas = await UserApi.fetchAllPersonas();
      // 2. 내 활성 페르소나 목록 가져오기
      final myPersonas = await UserApi.fetchMyPersonas();
      // 활성화된 페르소나 코드 리스트 추출
      final activeCodes = myPersonas
          .map((p) => (p['code'] as String).toLowerCase())
          .toList();
      setState(() {
        _allPersonas = allPersonas;
        _selected = List.filled(allPersonas.length, false);

        // 전체 페르소나 목록과 비교해서 선택 상태 설정
        for (int i = 0; i < _allPersonas.length; i++) {
          final code = (_allPersonas[i]['code'] as String).toLowerCase();
          _selected[i] = activeCodes.contains(code);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
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
                      child: _allPersonas.isEmpty
                          ? const Center(
                              child: Text('페르소나 정보를 불러올 수 없습니다.'),
                            )
                          : GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allPersonas.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: h * 0.005,
                                crossAxisSpacing: w * 0.09,
                                childAspectRatio: 0.9,
                              ),
                              itemBuilder: (context, index) {
                                final persona = _allPersonas[index];
                                final code = persona['code'] as String;
                                final name = _getNameByCode(code);
                                final image = _getImageByCode(code);

                                return _buildFriendItem(
                                  w: w,
                                  h: h,
                                  index: index,
                                  name: name,
                                  image: image,
                                );
                              },
                            ),
                    ),

                    SizedBox(height: h * 0.02),

                    /// ✅ 변경 버튼
                    CustomButton(
                      text: "변경",
                      onPressed: _savePersonas,
                    ),

                    SizedBox(height: h * 0.03),
                  ],
                ),
              ),
      ),
    );
  }

  /// ✅ 페르소나 변경 저장
  Future<void> _savePersonas() async {
    // 활성화된 페르소나의 코드만 추출 (소문자로 변환)
    final selectedCodes = <String>[];
    for (int i = 0; i < _allPersonas.length; i++) {
      if (_selected[i]) {
        final code = _allPersonas[i]['code'] as String;
        selectedCodes.add(code.toLowerCase()); // 소문자로 변환
      }
    }

    // 최소 1개는 선택되어야 함
    if (selectedCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("최소 1개의 AI 친구를 선택해주세요."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // API 호출
    final success = await UserApi.updatePersonas(selectedCodes);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI 친구가 변경되었습니다."),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI 친구 변경에 실패했습니다."),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          _selected[index] = !_selected[index]; // 선택 토글
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
                color: _selected[index] ? const Color(0xFF31C275) : Colors.transparent,
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
