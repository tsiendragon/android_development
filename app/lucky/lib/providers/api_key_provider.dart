import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _openAiKeyKey = 'openai_api_key';
  
  String? _openAiApiKey;
  bool _isLoading = false;
  String? _error;
  
  String? get openAiApiKey => _openAiApiKey;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasApiKey => _openAiApiKey != null && _openAiApiKey!.isNotEmpty;
  
  // Load the API key from secure storage
  Future<void> loadApiKey() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _openAiApiKey = await _secureStorage.read(key: _openAiKeyKey);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载API密钥失败: $e';
      if (kDebugMode) {
        print('Error loading API key: $e');
      }
      notifyListeners();
    }
  }
  
  // Save the API key to secure storage
  Future<bool> saveApiKey(String apiKey) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _secureStorage.write(key: _openAiKeyKey, value: apiKey);
      _openAiApiKey = apiKey;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = '保存API密钥失败: $e';
      if (kDebugMode) {
        print('Error saving API key: $e');
      }
      notifyListeners();
      return false;
    }
  }
  
  // Delete the API key from secure storage
  Future<bool> deleteApiKey() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _secureStorage.delete(key: _openAiKeyKey);
      _openAiApiKey = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = '删除API密钥失败: $e';
      if (kDebugMode) {
        print('Error deleting API key: $e');
      }
      notifyListeners();
      return false;
    }
  }
  
  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
