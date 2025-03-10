import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucky/providers/api_key_provider.dart';
import 'package:lucky/providers/theme_provider.dart';
import 'package:lucky/utils/version.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKeyProvider = Provider.of<ApiKeyProvider>(context, listen: false);
    await apiKeyProvider.loadApiKey();
    if (apiKeyProvider.openAiApiKey != null) {
      _apiKeyController.text = apiKeyProvider.openAiApiKey!;
    }
  }

  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      final apiKeyProvider = Provider.of<ApiKeyProvider>(
        context,
        listen: false,
      );
      final success = await apiKeyProvider.saveApiKey(
        _apiKeyController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('API密钥已保存')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiKeyProvider.error ?? '保存API密钥失败')),
          );
        }
      }
    }
  }

  Future<void> _deleteApiKey() async {
    final apiKeyProvider = Provider.of<ApiKeyProvider>(context, listen: false);
    final success = await apiKeyProvider.deleteApiKey();

    if (mounted) {
      if (success) {
        _apiKeyController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('API密钥已删除')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiKeyProvider.error ?? '删除API密钥失败')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyProvider = Provider.of<ApiKeyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme settings section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '主题设置',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('跟随系统'),
                      leading: const Icon(Icons.brightness_auto),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.system,
                        groupValue: themeProvider.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('浅色模式'),
                      leading: const Icon(Icons.light_mode),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: themeProvider.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('深色模式'),
                      leading: const Icon(Icons.dark_mode),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: themeProvider.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // API Key section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.key,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OpenAI API密钥',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '设置您的OpenAI API密钥以获取更准确的运势预测。您的API密钥将安全地存储在设备上，不会发送到任何服务器。',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API密钥',
                          hintText: 'sk-...',
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscureApiKey
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureApiKey = !_obscureApiKey;
                                  });
                                },
                              ),
                              if (apiKeyProvider.hasApiKey)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: _deleteApiKey,
                                ),
                            ],
                          ),
                        ),
                        obscureText: _obscureApiKey,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入API密钥';
                          }
                          if (!value.trim().startsWith('sk-')) {
                            return 'API密钥格式不正确，应以sk-开头';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            apiKeyProvider.isLoading ? null : _saveApiKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            apiKeyProvider.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('保存'),
                      ),
                    ),
                    if (apiKeyProvider.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        apiKeyProvider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App info section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '应用信息',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('版本', AppVersion.version),
                    _buildInfoRow('构建号', AppVersion.buildNumber.toString()),
                    _buildInfoRow('发布日期', AppVersion.releaseDate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Version history section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '版本历史',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...AppVersion.versionHistory.map(
                      (version) => _buildVersionHistoryItem(
                        '${version['version']} (${version['date']}): ${version['changes']}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildVersionHistoryItem(String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text('• $version'),
    );
  }
}
