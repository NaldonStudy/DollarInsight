import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/company/watch_button.dart';

/// 전체 종목 보기 스크린
/// 미국 주식 36개 + ETF 14개 = 총 50개 종목
class AllStocksListScreen extends StatefulWidget {
  const AllStocksListScreen({super.key});

  @override
  State<AllStocksListScreen> createState() => _AllStocksListScreenState();
}

class _AllStocksListScreenState extends State<AllStocksListScreen> {
  // TODO: 실제 관심 종목 데이터로 교체 필요
  final Set<String> _favoriteStocks = {};

  void _toggleFavorite(String ticker) {
    setState(() {
      if (_favoriteStocks.contains(ticker)) {
        _favoriteStocks.remove(ticker);
      } else {
        _favoriteStocks.add(ticker);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '전체 종목 보기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontal(context),
          vertical: AppSpacing.section(context),
        ),
        itemCount: 8, // 임시로 8개 (5개 기업 + 3개 ETF)
        itemBuilder: (context, index) {
          // 임시 데이터
          final isETF = index >= 5;
          final name = isETF ? 'TIGER 미국S&P500' : '테슬라';
          final ticker = isETF ? 'SPY${index - 5}' : 'TSLA$index';
          return _buildStockItem(name, ticker, isETF);
        },
      ),
    );
  }

  Widget _buildStockItem(String name, String ticker, bool isETF) {
    final isFavorite = _favoriteStocks.contains(ticker);

    return GestureDetector(
      onTap: () {
        // 기업 또는 ETF 상세 페이지로 이동
        if (isETF) {
          context.push('/etf/$ticker');
        } else {
          context.push('/company/$ticker');
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.small(context)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 로고
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business,
                color: Color(0xFF757575),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // 기업명
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 관심종목 버튼
            WatchButton(
              isWatching: isFavorite,
              onTap: () => _toggleFavorite(ticker),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
