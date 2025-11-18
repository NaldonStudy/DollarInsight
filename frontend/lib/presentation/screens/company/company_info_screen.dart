import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_info_provider.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../../core/constants/app_spacing.dart';

/// 기업 설명 페이지
/// 기업에 대한 상세 정보를 표시
/// Provider 패턴으로 API 연결 가능하도록 구현
class CompanyInfoScreen extends StatefulWidget {
  final String companyId;

  const CompanyInfoScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  bool isCompany = true; // 기업분석/채팅 토글 상태

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return ChangeNotifierProvider(
      create: (_) => CompanyInfoProvider(companyId: widget.companyId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        body: SafeArea(
          child: Column(
            children: [
              /// TopNavigation (기업분석/채팅 토글)
              TopNavigation(
                w: w,
                h: h,
                isCompany: isCompany,
                onTapCompany: () => setState(() => isCompany = true),
                onTapChat: () => setState(() => isCompany = false),
                onProfileTap: () {
                  // TODO: 마이페이지로 이동
                  // context.push('/mypage');
                },
              ),

              /// 화면 전환 (기업분석 / 채팅)
              Expanded(
                child: isCompany
                    ? _buildCompanyInfoBody(w, h)
                    : const ChatListScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 기업 설명 화면 바디
  Widget _buildCompanyInfoBody(double w, double h) {
    return Consumer<CompanyInfoProvider>(
      builder: (context, provider, child) {
        // 에러 처리
        if (provider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.error!)),
            );
            provider.clearError();
          });
        }

        // 로딩 중
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 데이터가 없는 경우
        if (provider.companyInfo == null) {
          return const Center(
            child: Text(
              '기업 정보를 찾을 수 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final companyInfo = provider.companyInfo!;

        // 데이터 표시
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: h * 0.07),
              _buildCompanyHeader(w, companyInfo),
              SizedBox(height: AppSpacing.section(context)),
              _buildInfoCard(w, h, companyInfo),
              SizedBox(height: AppSpacing.bottomLarge(context)),
            ],
          ),
        );
      },
    );
  }

  /// 기업 정보 헤더 (로고, 기업명)
  Widget _buildCompanyHeader(double w, companyInfo) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Row(
        children: [
          // 기업 로고
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: companyInfo.logoUrl != null
                ? ClipOval(
                    child: Image.asset(
                      companyInfo.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.small(context)),
          // 기업명
          Expanded(
            child: Text(
              companyInfo.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 기업 정보 카드
  Widget _buildInfoCard(double w, double h, companyInfo) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 기업 설명
          _buildInfoRow(
            label: null,
            value: companyInfo.description,
            isDescription: true,
          ),
          // 기업명
          _buildInfoRow(
            label: '기업명',
            value: companyInfo.name,
          ),
          // 홈페이지
          if (companyInfo.homepage != null)
            _buildInfoRow(
              label: '홈페이지',
              value: companyInfo.homepage!,
            ),
          // 대표이사
          if (companyInfo.ceo != null)
            _buildInfoRow(
              label: '대표이사',
              value: companyInfo.ceo!,
            ),
          // 설립연도
          if (companyInfo.foundedYear != null)
            _buildInfoRow(
              label: '설립연도',
              value: companyInfo.foundedYear!,
            ),
          // 상장일
          if (companyInfo.listingDate != null)
            _buildInfoRow(
              label: '상장일',
              value: companyInfo.listingDate!,
            ),
        ],
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow({
    String? label,
    required String value,
    bool isDescription = false,
  }) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Container(
      width: double.infinity,
      padding: isDescription
          ? EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal(context),
              vertical: h * 0.075, // 3배 더 큰 높이
            )
          : EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal(context),
              vertical: h * 0.018,
            ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: isDescription
          ? Text(
              value,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                height: 1.75,
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    label ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
