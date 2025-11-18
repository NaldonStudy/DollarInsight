import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../../core/constants/app_spacing.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WatchlistProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        appBar: AppBar(
          title: const Text('관심종목'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const _WatchlistBody(),
      ),
    );
  }
}

class _WatchlistBody extends StatelessWidget {
  const _WatchlistBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchlistProvider>(
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
                SizedBox(height: AppSpacing.medium(context)),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // 데이터 없음
        if (provider.watchlist.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: AppSpacing.medium(context)),
                Text(
                  '관심종목이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 데이터 로드 완료
        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            padding: EdgeInsets.all(AppSpacing.medium(context)),
            itemCount: provider.watchlist.length,
            itemBuilder: (context, index) {
              final item = provider.watchlist[index];
              return _WatchlistItemCard(item: item);
            },
          ),
        );
      },
    );
  }
}

class _WatchlistItemCard extends StatelessWidget {
  final dynamic item;

  const _WatchlistItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final changePct = item.changePct ?? 0.0;
    final isPositive = changePct > 0;
    final isNegative = changePct < 0;

    final changeColor = isPositive
        ? Colors.red
        : isNegative
            ? Colors.blue
            : Colors.grey;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.small(context)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.medium(context),
          vertical: AppSpacing.small(context),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.extraSmall(context)),
            Text(
              '${item.ticker} · ${item.exchange}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.lastPrice?.toStringAsFixed(2) ?? '-'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: AppSpacing.extraSmall(context)),
            Text(
              '${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%',
              style: TextStyle(
                color: changeColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: 종목 상세 페이지로 이동
        },
      ),
    );
  }
}
