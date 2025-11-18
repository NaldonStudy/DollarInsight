import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/etf_info_provider.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../../core/constants/app_spacing.dart';

/// ETF 설명 페이지
/// ETF에 대한 상세 정보를 표시
/// Provider 패턴으로 API 연결 가능하도록 구현
class ETFInfoScreen extends StatefulWidget {
  final String etfId;

  const ETFInfoScreen({
    super.key,
    required this.etfId,
  });

  @override
  State<ETFInfoScreen> createState() => _ETFInfoScreenState();
}

class _ETFInfoScreenState extends State<ETFInfoScreen> {
  bool isCompany = true; // 기업분석/채팅 토글 상태

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return ChangeNotifierProvider(
      create: (_) => EtfInfoProvider(etfId: widget.etfId),
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
                    ? _buildETFInfoBody(w, h)
                    : const ChatListScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ETF 설명 화면 바디
  Widget _buildETFInfoBody(double w, double h) {
    return Consumer<EtfInfoProvider>(
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
        if (provider.etfInfo == null) {
          return const Center(
            child: Text(
              'ETF 정보를 찾을 수 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final etfInfo = provider.etfInfo!;

        // 데이터 표시
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.big(context)),
              _buildETFHeader(w, etfInfo),
              SizedBox(height: AppSpacing.bottomLarge(context)),
              // 섹션 1: ETF 설명 + 통계 (1-3)
              _buildETFInfoSection(w, h, etfInfo),
              SizedBox(height: AppSpacing.medium(context)),
              // 섹션 2: 상위보유기업 (4-9)
              _buildTopHoldingsSection(w, h, etfInfo),
              SizedBox(height: AppSpacing.bottomLarge(context)),
            ],
          ),
        );
      },
    );
  }

  /// ETF 정보 헤더 (로고, ETF명, 업데이트 날짜)
  Widget _buildETFHeader(double w, etfInfo) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Row(
        children: [
          // ETF 로고
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: etfInfo.logoUrl != null
                ? ClipOval(
                    child: Image.asset(
                      etfInfo.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.small(context)),
          // ETF명 및 날짜
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etfInfo.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                if (etfInfo.lastUpdateDate != null)
                  Text(
                    etfInfo.lastUpdateDate!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 2.15,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 섹션 1: ETF 정보 (설명 + 통계)
  Widget _buildETFInfoSection(double w, double h, etfInfo) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ETF 설명 (3배 높이)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal(context),
              vertical: h * 0.06, // 3배 더 큰 높이
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: Color(0xFFE0E0E0),
                ),
              ),
            ),
            child: Text(
              etfInfo.description,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                height: 1.75,
              ),
            ),
          ),
          // 상위 10개 종목 비중
          if (etfInfo.top10HoldingsRatio != null)
            _buildInfoRow(
              label: '상위 10개 종목 비중',
              value: etfInfo.top10HoldingsRatio!,
            ),
          // 총 보유 종목 수
          if (etfInfo.totalStocks != null)
            _buildInfoRow(
              label: '총 보유 종목 수',
              value: etfInfo.totalStocks!,
            ),
        ],
      ),
    );
  }

  /// 섹션 2: 상위보유기업
  Widget _buildTopHoldingsSection(double w, double h, etfInfo) {
    if (etfInfo.topHoldings.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 상위보유기업 헤더
          _buildInfoRow(
            label: '상위보유기업',
            value: '',
            isHeader: true,
          ),
          // 상위 5개 보유 종목
          ...etfInfo.topHoldings.take(5).map((holding) {
            return _buildHoldingRow(
              companyName: holding.companyName,
              ratio: holding.ratio,
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 상위 보유 종목 카드
  Widget _buildTopHoldingsCard(double w, double h, etfInfo) {
    if (etfInfo.topHoldings.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: etfInfo.topHoldings.map<Widget>((holding) {
          return _buildHoldingRow(
            companyName: holding.companyName,
            ratio: holding.ratio,
          );
        }).toList(),
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isHeader = false,
  }) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isHeader)
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  /// 보유 종목 행 위젯
  Widget _buildHoldingRow({
    required String companyName,
    required String ratio,
  }) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              companyName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ratio,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
