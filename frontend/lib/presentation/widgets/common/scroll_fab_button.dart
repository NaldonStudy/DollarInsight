import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../../data/models/chat_model.dart';

/// 스크롤 FAB 버튼 타입
enum FabActionType {
  scroll,   // 스크롤 업
  chat,     // 채팅 생성
}

/// 채팅 컨텍스트 타입
enum ChatContextType {
  news,     // 뉴스 채팅
  company,  // 기업 채팅
  custom,   // 일반 채팅
}

class ScrollFabButton extends StatelessWidget {
  final bool showFab;
  final double w;
  final VoidCallback? onTap;
  
  // 채팅 기능 관련 파라미터
  final FabActionType actionType;
  final ChatContextType? chatType;
  final String? title;
  final String? ticker;
  final String? newsId;

  const ScrollFabButton({
    super.key,
    required this.showFab,
    required this.w,
    this.onTap,
    this.actionType = FabActionType.scroll,
    this.chatType,
    this.title,
    this.ticker,
    this.newsId,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: showFab ? 1 : 0,
      duration: const Duration(milliseconds: 230),
      child: AnimatedOpacity(
        opacity: showFab ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: () => _handleTap(context),
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
      ),
    );
  }

  /// 탭 처리
  void _handleTap(BuildContext context) {
    if (actionType == FabActionType.scroll) {
      // 스크롤 업
      if (onTap != null) {
        onTap!();
      }
    } else if (actionType == FabActionType.chat) {
      // 채팅 생성
      _handleChatCreation(context);
    }
  }

  /// 채팅 생성 처리
  Future<void> _handleChatCreation(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // 로딩 표시
    _showLoadingDialog(context);

    try {
      CreateSessionResponse? response;
      String? autoMessage;

      switch (chatType) {
        case ChatContextType.news:
          // 뉴스 채팅 생성
          final newsTitle = title ?? '뉴스 관련 채팅';
          response = await chatProvider.createNewsChat(
            title: newsTitle,
            companyNewsId: newsId != null ? int.tryParse(newsId!) : null,
          );
          // 자동 메시지 설정
          autoMessage = '$newsTitle에 대해 분석해주세요';
          break;

        case ChatContextType.company:
          // 기업 채팅 생성
          final companyTitle = title ?? '기업 분석 채팅';
          response = await chatProvider.createCompanyChat(
            title: companyTitle,
            ticker: ticker,
          );
          // 자동 메시지 설정
          autoMessage = '$companyTitle에 대해 분석해주세요';
          break;

        case ChatContextType.custom:
          // 일반 채팅 생성
          response = await chatProvider.createCustomChat(
            title ?? '새로운 채팅',
          );
          autoMessage = null; // 일반 채팅은 자동 메시지 없음
          break;

        default:
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
