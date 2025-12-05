import 'package:flutter/material.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/chat_model.dart';

class TestChatScreen extends StatefulWidget {
  const TestChatScreen({super.key});

  @override
  State<TestChatScreen> createState() => _TestChatScreenState();
}

class _TestChatScreenState extends State<TestChatScreen> {
  String _status = "테스트 대기 중...";
  String? _sessionId;
  final ChatRepository _chatRepository = ChatRepository();

  void _updateStatus(String newStatus) {
    setState(() {
      _status = newStatus;
    });
    print(newStatus); // 콘솔에도 출력
  }

  Future<void> _testCreateSession() async {
    try {
      _updateStatus("📝 세션 생성 중...");

      final response = await _chatRepository.createSession(
        topicType: TopicType.custom,
        title: "테스트 세션",
      );

      _sessionId = response.sessionUuid;
      _updateStatus("✅ 세션 생성 성공!\n🆔 UUID: ${response.sessionUuid}\n👥 Personas: ${response.personas.join(', ')}");

    } catch (e) {
      _updateStatus("❌ 세션 생성 실패: $e");
    }
  }

  Future<void> _testSendMessage() async {
    if (_sessionId == null) {
      _updateStatus("⚠️ 세션을 먼저 생성하세요");
      return;
    }

    try {
      _updateStatus("💬 메시지 전송 중...");

      final response = await _chatRepository.sendMessage(
        _sessionId!,
        "테슬라 주식에 대해 분석해주세요",
      );

      _updateStatus("✅ 메시지 전송 성공!\n📧 Message ID: ${response.messageId}");

    } catch (e) {
      _updateStatus("❌ 메시지 전송 실패: $e");
    }
  }

  Future<void> _testSSEStream() async {
    if (_sessionId == null) {
      _updateStatus("⚠️ 세션을 먼저 생성하세요");
      return;
    }

    try {
      _updateStatus("🔄 SSE 스트림 연결 중...");

      final stream = await _chatRepository.connectToSSEStream(_sessionId!);

      _updateStatus("✅ SSE 스트림 연결됨");

      stream.listen(
            (message) {
          _updateStatus("📨 SSE ${message.type}: ${message.data}");
        },
        onError: (error) {
          _updateStatus("❌ SSE 에러: $error");
        },
        onDone: () {
          _updateStatus("✅ SSE 스트림 완료");
        },
      );

    } catch (e) {
      _updateStatus("❌ SSE 연결 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat API Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 표시
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

            const SizedBox(height: 20),

            // 테스트 버튼들
            ElevatedButton(
              onPressed: _testCreateSession,
              child: const Text('1. 세션 생성 테스트'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _testSendMessage,
              child: const Text('2. 메시지 전송 테스트'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _testSSEStream,
              child: const Text('3. SSE 스트림 테스트'),
            ),

            const SizedBox(height: 20),

            // 전체 테스트
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _testCreateSession();
                await Future.delayed(const Duration(seconds: 1));
                await _testSendMessage();
                await Future.delayed(const Duration(seconds: 1));
                await _testSSEStream();
              },
              child: const Text('🚀 전체 테스트 실행'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatRepository.dispose();
    super.dispose();
  }
}