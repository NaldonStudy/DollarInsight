import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../widgets/common/custom_back_button.dart';
import '../../providers/chat_provider.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../core/utils/persona_mapper.dart';

class ChatRoomScreen extends StatefulWidget {
  final String sessionId;
  final String? autoMessage; // 자동 전송 메시지 파라미터 추가

  const ChatRoomScreen({
    super.key,
    required this.sessionId,
    this.autoMessage, // 생성자에 추가
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatRepository _chatRepository;

  List<ChatMessage> _messages = [];
  SessionItem? _sessionInfo;
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  bool _isSending = false;
  String? _error;

  StreamSubscription<SSEMessage>? _sseSubscription;
  bool _isStreaming = false;
  bool _isStreamReady = false; // AI 서비스 스트림 준비 완료 여부
  ChatMessage? _currentAIMessage; // 각 페르소나 발언을 별도 메시지로 처리하기 위한 멤버 변수
  Timer? _scrollDebounceTimer; // 스크롤 디바운스용 타이머

  @override
  void initState() {
    super.initState();
    _chatRepository = context.read<ChatProvider>().chatRepository;
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _stopSSEStreamSafely();
    _scrollDebounceTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _stopSSEStreamSafely() async {
    if (_sseSubscription != null) {
      await _sseSubscription!.cancel();
      _sseSubscription = null;
    }
    if (_isStreaming) {
      try {
        await _chatRepository.stopStream(widget.sessionId);
        debugPrint('SSE 스트림 중단 완료');
      } catch (e) {
        debugPrint('SSE 스트림 중단 실패: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  Future<void> _initializeChatRoom() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chatProvider = context.read<ChatProvider>();
      _sessionInfo = chatProvider.sessions.firstWhere(
            (session) => session.sessionUuid == widget.sessionId,
        orElse: () => SessionItem(
          sessionUuid: widget.sessionId,
          topicType: TopicType.custom,
          title: '채팅',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await _loadChatHistory();

      // 채팅방 입장 시에는 세션만 확인하고 스트림은 연결하지 않음
      // 스트림은 사용자가 메시지를 입력할 때 생성됨
      setState(() {
        _isLoading = false;
      });

      // autoMessage가 있으면 메시지 자동 전송
      if (widget.autoMessage != null && widget.autoMessage!.isNotEmpty) {
        // 위젯 빌드가 완료된 후에 메시지를 전송하도록 예약
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _sendMessage(autoMessage: widget.autoMessage);
          }
        });
      }

    } catch (e) {
      setState(() {
        _error = '채팅방을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoadingHistory = true;
      });

      final historyItems = await _chatRepository.getChatHistory(
        widget.sessionId,
        limit: 50,
      );

      if (!mounted) return;

      final messages = historyItems.map((item) {
        // speaker 정보는 item.speaker에서 직접 가져옴
        final speaker = item.speaker;

        // speaker 코드를 한글 이름으로 변환
        final koreanName = PersonaMapper.getKoreanName(speaker);

        return ChatMessage(
          role: item.role == 'user' ? MessageRole.user : MessageRole.assistant,
          content: item.content,
          timestamp: item.ts,
          personaCode: item.role == 'assistant' ? (speaker ?? 'AI') : null,
          personaName: item.role == 'assistant' ? koreanName : null,
        );
      }).toList();

      setState(() {
        _messages = messages;
        _isLoadingHistory = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('히스토리 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _sendMessage({String? autoMessage}) async {
    final messageText = autoMessage ?? _controller.text.trim();
    
    debugPrint('🔵 _sendMessage 호출됨');
    debugPrint('📝 메시지 내용: "$messageText"');
    debugPrint('📊 현재 _isSending 상태: $_isSending');
    
    if (messageText.isEmpty) {
      debugPrint('⚠️ 메시지가 비어있어 전송 취소');
      return;
    }
    
    if (_isSending) {
      debugPrint('⚠️ 이미 전송 중이므로 취소');
      return;
    }

    if (autoMessage == null) {
      _controller.clear();
    }

    final userMessage = ChatMessage.user(
      content: messageText,
      timestamp: DateTime.now(),
    );

    debugPrint('✅ 사용자 메시지를 로컬에 추가');
    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    _scrollToBottom();

    // 1단계: 스트림 생성 요청 (GET /stream) - 먼저 준비
    // 백엔드 ↔ 프론트엔드 스트림, 백엔드 ↔ AI 서비스 스트림 모두 준비
    if (!_isStreaming || _sseSubscription == null) {
      debugPrint('🔌 1단계: SSE 스트림 생성 요청 (GET /sessions/{sid}/stream)...');
      await _connectToSSEStream();
      debugPrint('✅ 1단계: SSE 스트림 생성 완료 (백엔드 ↔ 프론트, 백엔드 ↔ AI 연결 준비)');
    } else {
      debugPrint('🔌 기존 SSE 스트림 연결 유지');
    }

    // 1.5단계: AI 서비스 스트림 ready 이벤트 대기
    // 모든 스트림이 준비될 때까지 대기 (최대 10초)
    if (!_isStreamReady) {
      debugPrint('⏳ AI 서비스 스트림 ready 이벤트 대기 중...');
      int waitCount = 0;
      const maxWait = 100; // 10초 (100 * 100ms)
      while (!_isStreamReady && waitCount < maxWait) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (!_isStreamReady) {
        debugPrint('⚠️ AI 서비스 ready 이벤트를 10초 내에 받지 못함 (메시지 전송 계속 진행)');
      } else {
        debugPrint('✅ AI 서비스 스트림 ready 이벤트 확인됨');
      }
    }

    // 2단계: 메시지 전송 (POST /messages)
    // 모든 스트림이 준비된 후 메시지 전송 (AI 서비스 세션 생성 및 응답 수신 가능)
    try {
      debugPrint('📤 2단계: 메시지 전송 시작 (모든 스트림 준비 완료 후)...');
      final response = await _chatRepository.sendMessage(widget.sessionId, messageText);
      debugPrint('✅ 2단계: 메시지 전송 완료 - messageId: ${response.messageId}');
    } catch (e, stackTrace) {
      debugPrint('❌ 메시지 전송 실패: $e');
      debugPrint('📍 스택 트레이스: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _connectToSSEStream({bool forceReconnect = false}) async {
    if (_isStreaming && _sseSubscription != null && !forceReconnect) {
      debugPrint('⚠️ 이미 SSE 스트림이 연결되어 있어 재연결하지 않습니다.');
      return;
    }

    try {
      if (_sseSubscription != null) {
        await _sseSubscription!.cancel();
        _sseSubscription = null;
      }

      setState(() {
        _isStreaming = true;
        _isStreamReady = false; // 스트림 재연결 시 ready 상태 초기화
      });

      final sseStream = await _chatRepository.connectToSSEStream(widget.sessionId);

      _sseSubscription = sseStream.listen(
            (sseMessage) {
          if (!mounted) return;

          // 디버깅: SSE 메시지 전체 출력
          debugPrint('📨 SSE 메시지 수신:');
          debugPrint('  - type: ${sseMessage.type}');
          debugPrint('  - id: ${sseMessage.id}');
          debugPrint('  - data: ${sseMessage.data}');
          debugPrint('  - speaker: ${sseMessage.speaker}');
          debugPrint('  - turn: ${sseMessage.turn}');
          debugPrint('  - tsMs: ${sseMessage.tsMs}');
          debugPrint('  - sessionId: ${sseMessage.sessionId}');
          debugPrint('  - raw: ${sseMessage.raw}');

          print('🔥 [SSE RAW] type=${sseMessage.type}, data=${sseMessage.data}');
          try {
            switch (sseMessage.type) {
              case SSEEventType.message:
                // 각 페르소나의 발언을 별도의 메시지로 처리
                // 백엔드에서 이미 content만 추출해서 보내므로, 각 메시지는 완성된 발언임
                // speaker 코드를 한글 이름으로 변환
                final koreanName = PersonaMapper.getKoreanName(sseMessage.speaker);

                final aiMessage = ChatMessage.assistant(
                  content: sseMessage.data,
                  timestamp: DateTime.now(),
                  personaCode: sseMessage.speaker ?? 'AI',
                  personaName: koreanName,
                  isStreaming: false, // 이미 완성된 메시지이므로 스트리밍 아님
                );
                if (mounted) {
                  setState(() {
                    _messages.add(aiMessage);
                  });
                  _scrollToBottomDebounced();
                }
                break;

              case SSEEventType.ready:
                // AI 서비스 스트림 준비 완료
                debugPrint('✅ AI 서비스 스트림 준비 완료 (ready 이벤트 수신)');
                if (mounted) {
                  setState(() {
                    _isStreamReady = true;
                  });
                }
                break;

              case SSEEventType.done:
                // done 이벤트는 스트림 종료를 의미하지만, 채팅방을 나가기 전까지는 스트림 유지
                // done 이벤트를 무시하고 스트림을 계속 유지
                debugPrint('ℹ️ done 이벤트 수신 (스트림 유지)');
                break;

              case SSEEventType.error:
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('스트림 에러: ${sseMessage.data}')),
                  );
                  setState(() {
                    _isStreaming = false;
                    _isSending = false;
                    _currentAIMessage = null;
                  });
                }
                break;
            }
          } catch (e, stackTrace) {
            debugPrint('SSE 메시지 처리 오류: $e');
            debugPrint('스택 트레이스: $stackTrace');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('메시지 처리 오류: $e'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        onError: (error, stackTrace) {
          debugPrint('SSE 스트림 에러: $error');
          debugPrint('스택 트레이스: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('SSE 스트림 연결 오류: $error'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            setState(() {
              _isStreaming = false;
              _isSending = false;
              _currentAIMessage = null;
            });
          }
        },
        onDone: () {
          debugPrint('SSE 스트림 종료');
          if (mounted) {
            setState(() {
              _isStreaming = false;
              _isSending = false;
              _currentAIMessage = null;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('SSE 스트림 연결 실패: $e');
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _isSending = false;
          _currentAIMessage = null;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 스크롤 디바운스: 메시지가 빠르게 들어올 때 성능 최적화
  void _scrollToBottomDebounced() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('a h:mm', 'ko_KR').format(time);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(date);
  }

  /// 캐릭터 이름에 따른 이미지 경로 반환
  /// PersonaMapper를 사용하여 한글/영어 모두 지원
  String _getCharacterImagePath(String? speaker) {
    return PersonaMapper.getImagePath(speaker);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _stopSSEStreamSafely();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FB),
          elevation: 0,
          leading: CustomBackButton(
            iconColor: Colors.black87,
            onPressed: () async {
              await _stopSSEStreamSafely();
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Column(
            children: [
              Text(
                _sessionInfo?.title ?? '채팅',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7E909A),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            if (_sessionInfo?.topicType != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildTopicTypeChip(_sessionInfo!.topicType),
              ),
            if (_isStreaming)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 12,
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildChatArea(),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeChatRoom,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoadingHistory ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (_isLoadingHistory && index == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (index == (_isLoadingHistory ? 1 : 0)) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildStartMessage(),
          );
        }

        final messageIndex = index - (_isLoadingHistory ? 2 : 1);
        final message = _messages[messageIndex];

        if (message.role == MessageRole.user) {
          return _buildMyBubble(
            text: message.content,
            time: _formatTime(message.timestamp),
          );
        } else {
          return _buildAIBubble(
            name: message.personaName ?? 'AI',
            personaCode: message.personaCode,
            text: message.content,
            time: _formatTime(message.timestamp),
            isStreaming: message.isStreaming,
          );
        }
      },
    );
  }

  Widget _buildTopicTypeChip(TopicType topicType) {
    Color chipColor;
    String label;

    switch (topicType) {
      case TopicType.company:
        chipColor = Colors.blue;
        label = '기업';
        break;
      case TopicType.news:
        chipColor = Colors.orange;
        label = '뉴스';
        break;
      case TopicType.custom:
        chipColor = Colors.purple;
        label = '일반';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
    );
  }

  Widget _buildStartMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _messages.isEmpty ? "채팅이 시작되었습니다." : "이전 대화를 불러왔습니다.",
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMyBubble({required String text, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(width: 6),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E2F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9BA9B0), width: 0.5),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Color(0xFF21272A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble({
    required String name,
    String? personaCode,
    required String text,
    required String time,
    bool isStreaming = false,
  }) {
    final imagePath = _getCharacterImagePath(personaCode ?? name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지 로드 실패 시 기본 아이콘 표시
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.blue,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 이름 + 말풍선 + 시간
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7E909A),
                  ),
                ),
                const SizedBox(height: 4),

                // 말풍선
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF9BA9B0),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          text.isEmpty ? '...' : text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF21272A),
                          ),
                        ),
                      ),
                      if (isStreaming) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 시간 (아래 왼쪽)
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageInput() {
    return Container(
      color: const Color(0xFFF7F8FB),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                enabled: !_isSending,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "메시지 입력",
                ),
              ),
            ),
            if (_isStreaming)
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.red),
                onPressed: _stopSSEStreamSafely,
                tooltip: '스트림 중단',
              )
            else
              IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: Color(0xFF757575)),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
          ],
        ),
      ),
    );
  }
}
