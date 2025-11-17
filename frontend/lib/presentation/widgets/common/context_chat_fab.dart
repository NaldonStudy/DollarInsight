import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../../data/models/chat_model.dart';

/// 컨텍스트 기반 채팅 FAB 타입
enum ChatFabType {
  news,     // 뉴스 채팅
  company,  // 기업 채팅
  custom,   // 일반 채팅
}

/// 컨텍스트 기반 채팅 생성 FAB
/// 
/// 현재 페이지의 컨텍스트(뉴스/기업/일반)에 따라
/// 적절한 타입의 채팅방을 생성하고 이동합니다.
class ContextChatFab extends StatelessWidget {
  final ChatFabType type;
  final String? title;
  final String? ticker;
  final String? newsId;
  final double? bottom;
  final double? right;

  const ContextChatFab({
    super.key,
    required this.type,
    this.title,
    this.ticker,
    this.newsId,
    this.bottom,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Positioned(
      right: right ?? w * 0.05,
      bottom: bottom ?? w * 0.05,
      child: GestureDetector(
        onTap: () => _handleChatCreation(context),
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
              "assets/images/main8.webp",
              width: w * 0.1,
            ),
          ),
        ),
      ),
    );
  }

  /// 채팅 생성 처리
  Future<void> _handleChatCreation(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // 로딩 표시
    _showLoadingDialog(context);

    try {
      CreateSessionResponse? response;
      String? autoMessage;

      switch (type) {
        case ChatFabType.news:
          // 뉴스 채팅 생성
          final newsTitle = title ?? '뉴스 관련 채팅';
          response = await chatProvider.createNewsChat(
            title: newsTitle,
            companyNewsId: newsId != null ? int.tryParse(newsId!) : null,
          );
          // 자동 메시지 설정
          autoMessage = '$newsTitle에 대해 분석해주세요';
          break;

        case ChatFabType.company:
          // 기업 채팅 생성
          final companyTitle = title ?? '기업 분석 채팅';
          response = await chatProvider.createCompanyChat(
            title: companyTitle,
            ticker: ticker,
          );
          // 자동 메시지 설정
          autoMessage = '$companyTitle에 대해 분석해주세요';
          break;

        case ChatFabType.custom:
          // 일반 채팅 생성
          response = await chatProvider.createCustomChat(
            title ?? '새로운 채팅',
          );
          autoMessage = null; // 일반 채팅은 자동 메시지 없음
          break;
      }

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 채팅방으로 이동
      if (response != null && context.mounted) {
        // autoMessage가 있으면 쿼리 파라미터로 전달
        final uri = Uri(
          path: '/chat/${response.sessionUuid}',
          queryParameters: autoMessage != null 
            ? {'autoMessage': autoMessage} 
            : null,
        );
        
        context.push(uri.toString());
      } else if (context.mounted) {
        _showErrorSnackBar(context, '채팅방 생성에 실패했습니다');
      }

    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 에러 표시
      if (context.mounted) {
        _showErrorSnackBar(context, '채팅방 생성 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  /// 로딩 다이얼로그 표시
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
