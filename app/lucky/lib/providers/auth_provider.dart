import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthStatus { initial, authenticated, unauthenticated }
enum AuthType { gmail, wechat }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _userId;
  String? _authType;
  bool _isProfileComplete = false;
  
  // Keeping the secure storage for future implementation
  // but marking it as unused for now
  // ignore: unused_field
  final _secureStorage = const FlutterSecureStorage();
  
  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get authType => _authType;
  bool get isProfileComplete => _isProfileComplete;
  
  AuthProvider() {
    _checkCurrentAuth();
  }
  
  Future<void> _checkCurrentAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdFromPrefs = prefs.getString('userId');
      final authTypeFromPrefs = prefs.getString('authType');
      final isProfileCompleteFromPrefs = prefs.getBool('isProfileComplete') ?? false;
      
      if (userIdFromPrefs != null && authTypeFromPrefs != null) {
        _userId = userIdFromPrefs;
        _authType = authTypeFromPrefs;
        _isProfileComplete = isProfileCompleteFromPrefs;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }
  
  // Mock sign in with Gmail
  Future<bool> signInWithGmail() async {
    try {
      // In a real app, this would integrate with Firebase Auth or other OAuth provider
      // For MVP, we'll simulate a successful login
      final mockUserId = 'gmail_user_${DateTime.now().millisecondsSinceEpoch}';
      
      await _saveAuthData(mockUserId, 'gmail');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Gmail sign in error: $e');
      }
      return false;
    }
  }
  
  // Mock sign in with WeChat
  Future<bool> signInWithWeChat() async {
    try {
      // In a real app, this would integrate with WeChat SDK
      // For MVP, we'll simulate a successful login
      final mockUserId = 'wechat_user_${DateTime.now().millisecondsSinceEpoch}';
      
      await _saveAuthData(mockUserId, 'wechat');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('WeChat sign in error: $e');
      }
      return false;
    }
  }
  
  Future<void> _saveAuthData(String userId, String authType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('authType', authType);
    
    _userId = userId;
    _authType = authType;
    _status = AuthStatus.authenticated;
    
    notifyListeners();
  }
  
  Future<void> setProfileComplete(bool isComplete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isProfileComplete', isComplete);
    
    _isProfileComplete = isComplete;
    notifyListeners();
  }
  
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authType');
    await prefs.remove('isProfileComplete');
    
    _userId = null;
    _authType = null;
    _isProfileComplete = false;
    _status = AuthStatus.unauthenticated;
    
    notifyListeners();
  }
}
