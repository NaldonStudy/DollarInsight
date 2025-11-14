import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/company/watch_button.dart';
import '../../providers/all_stocks_list_provider.dart';

/// 전체 종목 보기 스크린
/// 미국 주식 + ETF 전체 목록
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
    return ChangeNotifierProvider(
      create: (_) => AllStocksListProvider(),
      child: Scaffold(
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
        body: Consumer<AllStocksListProvider>(
          builder: (context, provider, child) {
            // 로딩 중
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 에러 발생
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refresh(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            // 데이터 로드 완료
            final allAssets = provider.allAssets;

            if (allAssets.isEmpty) {
              return const Center(
                child: Text('종목이 없습니다'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontal(context),
                  vertical: AppSpacing.section(context),
                ),
                itemCount: allAssets.length,
                itemBuilder: (context, index) {
                  final asset = allAssets[index];
                  return _buildStockItem(
                    asset.ticker,
                    asset.ticker,
                    asset.isETF,
                  );
                },
              ),
            );
          },
        ),
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
