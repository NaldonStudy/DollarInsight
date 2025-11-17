import java.net.HttpURLConnection;
import java.net.URL;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * Backend를 통한 SSE 통신 전체 플로우 테스트 클라이언트
 *
 * 테스트 플로우:
 * 1. 세션 생성 (POST /api/chat/sessions)
 * 2. 사용자 메시지 전송 (POST /api/chat/sessions/{sid}/messages)
 * 3. SSE 스트림 연결 (GET /api/chat/sessions/{sid}/stream)
 * 4. AI 응답 수신 및 출력
 */
public class BackendSSETestClient {
    // Backend 서버 URL (환경에 맞게 수정)
    private static final String BACKEND_URL = "http://localhost:8080";

    // 테스트용 인증 토큰 (실제 토큰으로 교체 필요)
    private static String ACCESS_TOKEN = null;

    // 테스트용 디바이스 ID
    private static final String DEVICE_ID = UUID.randomUUID().toString();

    public static void main(String[] args) {
        System.out.println("=== Backend SSE 통신 전체 플로우 테스트 ===\n");
        System.out.println("디바이스 ID: " + DEVICE_ID);

        try {
            // 0. 토큰 설정 (환경변수 또는 인자로 받기)
            if (args.length > 0) {
                ACCESS_TOKEN = args[0];
                System.out.println("✅ 인증 토큰 설정됨\n");
            } else {
                System.out.println("⚠️  인증 토큰이 없습니다. 로그인이 필요한 경우 테스트가 실패할 수 있습니다.");
                System.out.println("   사용법: java BackendSSETestClient <ACCESS_TOKEN>\n");
            }

            // 1. 세션 생성
            System.out.println("1️⃣  세션 생성 중...");
            String sessionUuid = createSession();
            System.out.println("✅ 세션 생성 완료: " + sessionUuid + "\n");

            // 2. 사용자 메시지 전송
            System.out.println("2️⃣  사용자 메시지 전송 중...");
            String userMessage = "테슬라 주식에 대해 토론해주세요";
            sendMessage(sessionUuid, userMessage);
            System.out.println("✅ 메시지 전송 완료: \"" + userMessage + "\"\n");

            // 3. SSE 스트림 연결 및 수신
            System.out.println("3️⃣  SSE 스트림 연결 중...");
            System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
            connectSSEStream(sessionUuid);

            System.out.println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            System.out.println("\n=== 테스트 완료 ===");

        } catch (Exception e) {
            System.err.println("\n❌ 테스트 실패: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 1. 세션 생성
     */
    private static String createSession() throws IOException {
        String endpoint = "/api/chat/sessions";
        String requestBody = "{\"topicType\":\"CUSTOM\",\"title\":\"테슬라 투자 토론\"}";

        String response = sendPostRequest(endpoint, requestBody);

        // JSON 파싱 (간단하게 문자열 처리)
        // 실제로는 JSON 라이브러리 사용 권장
        String sessionUuid = extractJsonField(response, "sessionUuid");
        if (sessionUuid == null) {
            throw new RuntimeException("세션 UUID를 찾을 수 없습니다: " + response);
        }

        return sessionUuid;
    }

    /**
     * 2. 사용자 메시지 전송
     */
    private static void sendMessage(String sessionUuid, String message) throws IOException {
        String endpoint = "/api/chat/sessions/" + sessionUuid + "/messages";
        String requestBody = "{\"content\":\"" + message + "\"}";

        sendPostRequest(endpoint, requestBody);
    }

    /**
     * 3. SSE 스트림 연결 및 수신
     */
    private static void connectSSEStream(String sessionUuid) throws IOException {
        String endpoint = "/api/chat/sessions/" + sessionUuid + "/stream?device_id=" + DEVICE_ID;
        URL url = new URL(BACKEND_URL + endpoint);

        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setRequestProperty("Accept", "text/event-stream");
        conn.setRequestProperty("Cache-Control", "no-cache");
        conn.setRequestProperty("X-Device-Id", DEVICE_ID);

        if (ACCESS_TOKEN != null) {
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
        }

        conn.setConnectTimeout(10000);
        conn.setReadTimeout(0); // SSE는 장시간 연결이므로 타임아웃 없음

        int responseCode = conn.getResponseCode();
        if (responseCode != 200) {
            String errorMsg = readErrorStream(conn);
            throw new RuntimeException("SSE 연결 실패 (" + responseCode + "): " + errorMsg);
        }

        System.out.println("✅ SSE 스트림 연결 성공!\n");

        // SSE 메시지 수신
        BufferedReader reader = new BufferedReader(
            new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)
        );

        String currentEvent = null;
        String currentId = null;
        StringBuilder currentData = new StringBuilder();
        int messageCount = 0;

        String line;
        while ((line = reader.readLine()) != null) {
            if (line.isEmpty()) {
                // 빈 줄 = 이벤트 완료
                if (currentEvent != null || currentData.length() > 0) {
                    String eventType = currentEvent != null ? currentEvent : "message";
                    String data = currentData.toString();

                    if ("message".equals(eventType)) {
                        messageCount++;
                        System.out.println("📨 메시지 #" + messageCount);
                        System.out.println("   ID: " + (currentId != null ? currentId : "N/A"));
                        System.out.println("   내용: " + data);
                        System.out.println();

                    } else if ("done".equals(eventType) || "close".equals(eventType)) {
                        System.out.println("🏁 스트림 종료 신호 수신");
                        break;

                    } else if ("error".equals(eventType)) {
                        System.out.println("❌ 에러 발생: " + data);
                        break;

                    } else if ("ping".equals(eventType)) {
                        System.out.println("💓 Keep-alive ping");
                    }
                }

                // 리셋
                currentEvent = null;
                currentId = null;
                currentData = new StringBuilder();

            } else if (line.startsWith("id:")) {
                currentId = line.substring(3).trim();

            } else if (line.startsWith("event:")) {
                currentEvent = line.substring(6).trim();

            } else if (line.startsWith("data:")) {
                if (currentData.length() > 0) {
                    currentData.append("\n");
                }
                currentData.append(line.substring(5).trim());

            } else if (line.startsWith(":")) {
                // 주석 (하트비트) - 무시
            }
        }

        reader.close();
        conn.disconnect();

        System.out.println("\n📊 총 " + messageCount + "개의 메시지를 수신했습니다.");
    }

    /**
     * POST 요청 전송
     */
    private static String sendPostRequest(String endpoint, String jsonBody) throws IOException {
        URL url = new URL(BACKEND_URL + endpoint);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        conn.setRequestProperty("X-Device-Id", DEVICE_ID);

        if (ACCESS_TOKEN != null) {
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
        }

        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);

        // Request body 전송
        try (OutputStream os = conn.getOutputStream()) {
            byte[] input = jsonBody.getBytes(StandardCharsets.UTF_8);
            os.write(input, 0, input.length);
        }

        int responseCode = conn.getResponseCode();
        if (responseCode >= 200 && responseCode < 300) {
            return readInputStream(conn.getInputStream());
        } else {
            String errorMsg = readErrorStream(conn);
            throw new RuntimeException("HTTP " + responseCode + ": " + errorMsg);
        }
    }

    /**
     * InputStream 읽기
     */
    private static String readInputStream(InputStream inputStream) throws IOException {
        BufferedReader reader = new BufferedReader(
            new InputStreamReader(inputStream, StandardCharsets.UTF_8)
        );

        StringBuilder response = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            response.append(line);
        }
        reader.close();

        return response.toString();
    }

    /**
     * Error Stream 읽기
     */
    private static String readErrorStream(HttpURLConnection conn) {
        try {
            InputStream errorStream = conn.getErrorStream();
            if (errorStream != null) {
                return readInputStream(errorStream);
            }
        } catch (IOException e) {
            // 무시
        }
        return "알 수 없는 오류";
    }

    /**
     * JSON 필드 추출 (간단 버전)
     * 실제로는 JSON 라이브러리 사용 권장
     */
    private static String extractJsonField(String json, String fieldName) {
        String searchKey = "\"" + fieldName + "\":\"";
        int startIdx = json.indexOf(searchKey);
        if (startIdx == -1) return null;

        startIdx += searchKey.length();
        int endIdx = json.indexOf("\"", startIdx);
        if (endIdx == -1) return null;

        return json.substring(startIdx, endIdx);
    }
}
