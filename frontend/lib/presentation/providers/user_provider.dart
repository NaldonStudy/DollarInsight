import 'package:flutter/material.dart';
import '../../data/datasources/remote/user_api.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? user;

  Future<void> loadUser() async {
    user = await UserApi.fetchMe();
    notifyListeners();
  }
}
