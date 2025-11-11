import java.net.HttpURLConnection;
import java.net.URL;
import java.io.*;
import java.nio.charset.StandardCharsets;

public class AITestClient {
    private static final String BASE_URL = "http://localhost:8000";
    
    public static void main(String[] args) {
        System.out.println("=== AI Service 통신 테스트 ===\n");
        
        try {
            // 1. 헬스 체크
            System.out.println("1. 헬스 체크 테스트...");
            String healthResponse = sendGetRequest("/health");
            System.out.println("응답: " + healthResponse + "\n");
            
            // 2. 세션 시작
            System.out.println("2. 세션 시작 테스트...");
            String sessionId = "test-java-" + System.currentTimeMillis();
            String startRequest = String.format(
                "{\"session_id\":\"%s\",\"user_input\":\"테슬라 주식에 대해 토론해주세요\",\"pace_ms\":3000}",
                sessionId
            );
            String startResponse = sendPostRequest("/start", startRequest);
            System.out.println("응답: " + startResponse + "\n");
            
            // 3. 세션 목록 확인
            System.out.println("3. 세션 목록 확인...");
            String sessionsResponse = sendGetRequest("/sessions");
            System.out.println("응답: " + sessionsResponse + "\n");
            
            // 4. 사용자 입력 전송
            System.out.println("4. 사용자 입력 전송...");
            String inputRequest = String.format(
                "{\"session_id\":\"%s\",\"user_input\":\"애플은 어떨까요?\"}",
                sessionId
            );
            String inputResponse = sendPostRequest("/input", inputRequest);
            System.out.println("응답: " + inputResponse + "\n");
            
            // 5. SSE 스트림 테스트
            System.out.println("5. SSE 스트림 테스트 (10초간 메시지 수신 대기)...");
            System.out.println("   세션이 시작되었으므로 AI 응답 메시지가 올 수 있습니다.\n");
            testSSEStream(sessionId, 10); // 10초간 테스트
            
            // 6. 세션 제어 (일시정지)
            System.out.println("\n6. 세션 제어 (일시정지)...");
            String controlRequest = String.format(
                "{\"session_id\":\"%s\",\"action\":\"STOP\"}",
                sessionId
            );
            String controlResponse = sendPostRequest("/control", controlRequest);
            System.out.println("응답: " + controlResponse + "\n");
            
            System.out.println("=== 모든 테스트 완료 ===");
            
        } catch (Exception e) {
            System.err.println("에러 발생: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private static String sendGetRequest(String endpoint) throws IOException {
        URL url = new URL(BASE_URL + endpoint);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        
        int responseCode = conn.getResponseCode();
        InputStream inputStream = responseCode >= 200 && responseCode < 300
            ? conn.getInputStream()
            : conn.getErrorStream();
        
        BufferedReader reader = new BufferedReader(
            new InputStreamReader(inputStream, StandardCharsets.UTF_8)
        );
        
        StringBuilder response = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            response.append(line);
        }
        reader.close();
        conn.disconnect();
        
        return response.toString();
    }
    
    private static String sendPostRequest(String endpoint, String jsonBody) throws IOException {
        URL url = new URL(BASE_URL + endpoint);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        conn.setDoOutput(true);
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        
        // Request body 전송
        try (OutputStream os = conn.getOutputStream()) {
            byte[] input = jsonBody.getBytes(StandardCharsets.UTF_8);
            os.write(input, 0, input.length);
        }
        
        int responseCode = conn.getResponseCode();
        InputStream inputStream = responseCode >= 200 && responseCode < 300
            ? conn.getInputStream()
            : conn.getErrorStream();
        
        BufferedReader reader = new BufferedReader(
            new InputStreamReader(inputStream, StandardCharsets.UTF_8)
        );
        
        StringBuilder response = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            response.append(line);
        }
        reader.close();
        conn.disconnect();
        
        return response.toString();
    }
    
    private static void testSSEStream(String sessionId, int durationSeconds) {
        try {
            URL url = new URL(BASE_URL + "/stream?session_id=" + sessionId);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Accept", "text/event-stream");
            conn.setRequestProperty("Cache-Control", "no-cache");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout((durationSeconds + 5) * 1000); // 테스트 시간 + 여유
            
            int responseCode = conn.getResponseCode();
            if (responseCode != 200) {
                System.out.println("   SSE 연결 실패: " + responseCode);
                return;
            }
            
            System.out.println("   SSE 연결 성공! 메시지 수신 대기 중...\n");
            
            BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)
            );
            
            long startTime = System.currentTimeMillis();
            long endTime = startTime + (durationSeconds * 1000);
            int messageCount = 0;
            String currentEvent = null;
            String currentId = null;
            StringBuilder currentData = new StringBuilder();
            
            String line;
            while (System.currentTimeMillis() < endTime && (line = reader.readLine()) != null) {
                if (line.isEmpty()) {
                    // 빈 줄 = 메시지 완료
                    if (currentEvent != null && currentData.length() > 0) {
                        messageCount++;
                        String data = currentData.toString().trim();
                        
                        if ("message".equals(currentEvent)) {
                            System.out.println("   [메시지 #" + messageCount + "]");
                            System.out.println("   ID: " + (currentId != null ? currentId : "N/A"));
                            System.out.println("   데이터: " + data);
                            
                            // JSON 파싱 시도
                            if (data.startsWith("{")) {
                                try {
                                    // 간단한 JSON 파싱 (speaker, text 추출)
                                    if (data.contains("\"speaker\"")) {
                                        int speakerStart = data.indexOf("\"speaker\":\"") + 11;
                                        int speakerEnd = data.indexOf("\"", speakerStart);
                                        String speaker = data.substring(speakerStart, speakerEnd);
                                        
                                        int textStart = data.indexOf("\"text\":\"") + 8;
                                        int textEnd = data.indexOf("\"", textStart);
                                        if (textEnd > textStart) {
                                            String text = data.substring(textStart, Math.min(textEnd, textStart + 100));
                                            System.out.println("   → [" + speaker + "] " + text + (textEnd > textStart + 100 ? "..." : ""));
                                        }
                                    }
                                } catch (Exception e) {
                                    // 파싱 실패는 무시
                                }
                            }
                            System.out.println();
                        } else if ("close".equals(currentEvent)) {
                            System.out.println("   [스트림 종료 신호 수신]\n");
                            break;
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
                } else if (line.startsWith("retry:")) {
                    // retry 정보는 무시
                } else if (line.startsWith(":")) {
                    // 하트비트 (주석) 무시
                }
            }
            
            reader.close();
            conn.disconnect();
            
            if (messageCount > 0) {
                System.out.println("   ✅ SSE 테스트 성공! 총 " + messageCount + "개의 메시지를 수신했습니다.");
            } else {
                System.out.println("   ⚠️  SSE 연결은 성공했지만 메시지를 받지 못했습니다.");
                System.out.println("      (AI 응답이 아직 생성되지 않았을 수 있습니다)");
            }
            
        } catch (java.net.SocketTimeoutException e) {
            System.out.println("   ⚠️  타임아웃 (정상 - 테스트 시간 종료)");
        } catch (Exception e) {
            System.out.println("   ❌ SSE 테스트 실패: " + e.getMessage());
            e.printStackTrace();
        }
    }
}

