import 'package:flutter/material.dart';
import '../../data/datasources/remote/user_api.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? user;

  /// ✅ 내 정보 불러오기
  Future<void> loadUser() async {
    user = await UserApi.fetchMe();
    notifyListeners();
  }

  /// ✅ 닉네임 변경
  Future<bool> changeNickname(String newNickname) async {
    final success = await UserApi.updateNickname(newNickname);

    if (success) {
      await loadUser(); // 닉네임 변경 후 다시 내 정보 로드
    }

    return success;
  }
}
