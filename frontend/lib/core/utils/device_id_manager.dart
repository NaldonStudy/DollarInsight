import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdManager {
  static const _key = 'device_id';

  /// ✅ 디바이스 ID 조회 (없으면 생성)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);

    if (id != null) {
      return id;
    }

    /// ✅ 없는 경우 새 UUID 생성 후 저장
    id = Uuid().v4();
    await prefs.setString(_key, id);

    return id;
  }
}
