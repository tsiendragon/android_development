import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lucky/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  int get meritPoints => _user?.meritPoints ?? 0;
  
  Future<void> loadUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_$userId');
      
      if (userData != null) {
        _user = User.fromJson(json.decode(userData));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user: $e');
      }
    }
  }
  
  Future<bool> saveUserInfo({
    required String id,
    required String name,
    required String gender,
    required DateTime birthDate,
    required String birthTime,
    required String birthPlace,
    required String authProvider,
    String? avatarUrl,
  }) async {
    try {
      final user = User(
        id: id,
        name: name,
        gender: gender,
        birthDate: birthDate,
        birthTime: birthTime,
        birthPlace: birthPlace,
        meritPoints: 0,
        avatarUrl: avatarUrl,
        authProvider: authProvider,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_$id', json.encode(user.toJson()));
      
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user: $e');
      }
      return false;
    }
  }
  
  Future<bool> updateMeritPoints(int points) async {
    if (_user == null) return false;
    
    try {
      final updatedUser = _user!.copyWith(
        meritPoints: _user!.meritPoints + points,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_${_user!.id}', json.encode(updatedUser.toJson()));
      
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating merit points: $e');
      }
      return false;
    }
  }
  
  Future<bool> updateUserInfo({
    String? name,
    String? gender,
    DateTime? birthDate,
    String? birthTime,
    String? birthPlace,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;
    
    try {
      final updatedUser = _user!.copyWith(
        name: name,
        gender: gender,
        birthDate: birthDate,
        birthTime: birthTime,
        birthPlace: birthPlace,
        avatarUrl: avatarUrl,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_${_user!.id}', json.encode(updatedUser.toJson()));
      
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user info: $e');
      }
      return false;
    }
  }
  
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
