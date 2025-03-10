import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lucky/models/user_model.dart';
import 'package:lucky/models/merit_history_model.dart';
import 'package:lucky/models/merit_achievement_model.dart';
import 'package:uuid/uuid.dart';
import 'package:lucky/models/user_question_model.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  List<MeritHistory> _meritHistory = [];
  List<MeritAchievement> _achievements = [];
  List<UserQuestion> _questions = [];

  User? get user => _user;
  int get meritPoints => _user?.meritPoints ?? 0;
  List<MeritHistory> get meritHistory => _meritHistory;
  List<MeritAchievement> get achievements => _achievements;
  List<UserQuestion> get questions => _questions;

  Future<void> loadUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_$userId');
      final historyData = prefs.getString('merit_history_$userId');
      final achievementsData = prefs.getString('achievements_$userId');

      if (userData != null) {
        _user = User.fromJson(json.decode(userData));
      }

      if (historyData != null) {
        final List<dynamic> historyJson = json.decode(historyData);
        _meritHistory =
            historyJson.map((json) => MeritHistory.fromJson(json)).toList();
      }

      if (achievementsData != null) {
        final List<dynamic> achievementsJson = json.decode(achievementsData);
        _achievements =
            achievementsJson
                .map((json) => MeritAchievement.fromJson(json))
                .toList();
      } else {
        // 初始化默认成就
        _initializeAchievements();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  void _initializeAchievements() {
    _achievements = [
      MeritAchievement(
        id: 'first_merit',
        title: '初入佛门',
        description: '获得第一个功德点',
        requiredPoints: 1,
        icon: '🎯',
      ),
      MeritAchievement(
        id: 'daily_wooden_fish',
        title: '木鱼达人',
        description: '完成每日木鱼敲击',
        requiredPoints: 108,
        icon: '🔨',
      ),
      MeritAchievement(
        id: 'merit_master',
        title: '功德大师',
        description: '累计获得1000功德点',
        requiredPoints: 1000,
        icon: '🌟',
      ),
      MeritAchievement(
        id: 'reflection_master',
        title: '自省大师',
        description: '完成10次自省',
        requiredPoints: 360,
        icon: '📝',
      ),
    ];
    _saveAchievements();
  }

  Future<void> _saveAchievements() async {
    if (_user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = _achievements.map((a) => a.toJson()).toList();
      await prefs.setString(
        'achievements_${_user!.id}',
        json.encode(achievementsJson),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving achievements: $e');
      }
    }
  }

  Future<void> _saveMeritHistory() async {
    if (_user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _meritHistory.map((h) => h.toJson()).toList();
      await prefs.setString(
        'merit_history_${_user!.id}',
        json.encode(historyJson),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving merit history: $e');
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

  Future<bool> updateMeritPoints(
    int points, {
    required String type,
    String? description,
    String? category,
  }) async {
    if (_user == null) return false;

    try {
      final updatedUser = _user!.copyWith(
        meritPoints: _user!.meritPoints + points,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_${_user!.id}',
        json.encode(updatedUser.toJson()),
      );

      // 添加功德历史记录
      final history = MeritHistory(
        id: const Uuid().v4(),
        date: DateTime.now(),
        points: points,
        type: type,
        description: description,
        category: category,
      );
      _meritHistory.insert(0, history);
      await _saveMeritHistory();

      // 检查并更新成就
      _checkAchievements(updatedUser.meritPoints);

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

  void _checkAchievements(int currentPoints) {
    bool hasUpdates = false;

    for (var i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      if (!achievement.isUnlocked &&
          currentPoints >= achievement.requiredPoints) {
        _achievements[i] = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      _saveAchievements();
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
      await prefs.setString(
        'user_${_user!.id}',
        json.encode(updatedUser.toJson()),
      );

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
    _meritHistory = [];
    _achievements = [];
    _questions = [];
    notifyListeners();
  }

  Future<void> addQuestion(UserQuestion question) async {
    _questions.add(question);
    notifyListeners();
  }
}
