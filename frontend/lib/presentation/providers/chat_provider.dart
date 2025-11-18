// chat_provider.dart
// 채팅 관련 상태 관리를 담당하는 Provider

import 'package:flutter/foundation.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/chat_model.dart';

/// 채팅 상태 열거형
enum ChatListState {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

/// 채팅 Provider
/// 채팅 세션 목록 및 관련 상태를 관리
class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  ChatProvider({ChatRepository? chatRepository}) 
      : _chatRepository = chatRepository ?? ChatRepository();

  // ChatRepository에 접근할 수 있는 public getter 추가
  ChatRepository get chatRepository => _chatRepository;

  // 상태 관리
  ChatListState _state = ChatListState.initial;
  List<SessionItem> _sessions = [];
  String? _errorMessage;
  
  // 페이지네이션 관련
  int _currentPage = 0;
  int _pageSize = 20;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Getters
  ChatListState get state => _state;
  List<SessionItem> get sessions => _sessions;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _isLoadingMore;
  bool get isEmpty => _sessions.isEmpty && _state == ChatListState.loaded;

  /// 세션 목록 초기 로드
  Future<void> loadSessions({bool refresh = false}) async {
    if (refresh) {
      _setState(ChatListState.refreshing);
      _currentPage = 0;
      _hasMoreData = true;
      _sessions.clear();
    } else if (_state == ChatListState.loading) {
      return; // 이미 로딩 중이면 무시
    } else {
      _setState(ChatListState.loading);
    }

    _clearError();

    try {
      final response = await _chatRepository.getSessionList(
        page: _currentPage,
        size: _pageSize,
      );

      _sessions = response.items;
      _hasMoreData = response.hasNext;
      _setState(ChatListState.loaded);

    } catch (e) {
      _setError('채팅 목록을 불러오는데 실패했습니다: ${e.toString()}');
    }
  }

  /// 더 많은 세션 로드 (무한 스크롤)
  Future<void> loadMoreSessions() async {
    if (_isLoadingMore || !_hasMoreData || _state == ChatListState.loading) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _chatRepository.getSessionList(
        page: _currentPage + 1,
        size: _pageSize,
      );

      _sessions.addAll(response.items);
      _currentPage++;
      _hasMoreData = response.hasNext;

    } catch (e) {
      _setError('추가 채팅 목록을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 새로운 세션 생성 후 목록 새로고침
  Future<CreateSessionResponse?> createSession({
    required TopicType topicType,
    String? title,
    String? ticker,
    int? companyNewsId,
    bool? companyValid,
  }) async {
    try {
      final response = await _chatRepository.createSession(
        topicType: topicType,
        title: title,
        ticker: ticker,
        companyNewsId: companyNewsId,
        companyValid: companyValid,
      );

      // 세션 생성 성공 시 목록 새로고침
      await loadSessions(refresh: true);
      
      return response;
    } catch (e) {
      _setError('세션 생성에 실패했습니다: ${e.toString()}');
      return null;
    }
  }

  /// 일반 채팅 생성 (채팅 리스트에서)
  Future<CreateSessionResponse?> createCustomChat(String title) async {
    return await createSession(
      topicType: TopicType.custom,
      title: title,
    );
  }

  /// 기업 분석 채팅 생성 (기업 분석 페이지에서)
  Future<CreateSessionResponse?> createCompanyChat({
    required String title,
    String? ticker,
  }) async {
    return await createSession(
      topicType: TopicType.company,
      title: title,
      ticker: ticker,
    );
  }

  /// 뉴스 관련 채팅 생성 (뉴스 페이지에서)
  Future<CreateSessionResponse?> createNewsChat({
    required String title,
    int? companyNewsId,
  }) async {
    return await createSession(
      topicType: TopicType.news,
      title: title,
      companyNewsId: companyNewsId,
    );
  }

  /// 특정 세션 삭제 (향후 구현을 위한 준비)
  Future<void> deleteSession(String sessionUuid) async {
    // TODO: 세션 삭제 API가 구현되면 여기에 추가
    try {
      // await _chatRepository.deleteSession(sessionUuid);
      
      // 로컬에서 임시로 제거
      _sessions.removeWhere((session) => session.sessionUuid == sessionUuid);
      notifyListeners();
      
    } catch (e) {
      _setError('세션 삭제에 실패했습니다: ${e.toString()}');
    }
  }

  /// 세션 제목 업데이트 (향후 구현을 위한 준비)
  void updateSessionTitle(String sessionUuid, String newTitle) {
    final index = _sessions.indexWhere((session) => session.sessionUuid == sessionUuid);
    if (index != -1) {
      // SessionItem은 immutable이므로 새로운 객체를 생성해야 함
      // 현재는 copyWith 메소드가 없으므로 전체 목록 새로고침으로 대체
      loadSessions(refresh: true);
    }
  }

  /// 상태 변경 헬퍼
  void _setState(ChatListState newState) {
    _state = newState;
    notifyListeners();
  }

  /// 에러 설정 헬퍼
  void _setError(String error) {
    _errorMessage = error;
    _setState(ChatListState.error);
  }

  /// 에러 클리어 헬퍼
  void _clearError() {
    _errorMessage = null;
  }

  /// 에러 상태 클리어 (사용자가 수동으로 에러를 닫을 때)
  void clearError() {
    _clearError();
    _setState(ChatListState.loaded);
  }

  /// 수동 새로고침
  Future<void> refresh() async {
    await loadSessions(refresh: true);
  }

  /// Provider 정리
  @override
  void dispose() {
    _chatRepository.dispose();
    super.dispose();
  }
}
