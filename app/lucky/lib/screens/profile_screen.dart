import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/providers/auth_provider.dart';
import 'package:lunar/lunar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 计算八字信息
    final lunar = Lunar.fromDate(user.birthDate);
    final heavenlyStem = lunar.getYearGan(); // 天干
    final earthlyBranch = lunar.getYearZhi(); // 地支
    final monthGan = lunar.getMonthGan(); // 月干
    final monthZhi = lunar.getMonthZhi(); // 月支
    final dayGan = lunar.getDayGan(); // 日干
    final dayZhi = lunar.getDayZhi(); // 日支

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户头像和基本信息卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child:
                        user.avatarUrl != null
                            ? ClipOval(
                              child: Image.network(
                                user.avatarUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '功德值: ${user.meritPoints}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            // 详细信息卡片
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context, '基本信息', [
                    _buildInfoRow('性别', user.gender),
                    _buildInfoRow(
                      '出生日期',
                      DateFormat('yyyy年MM月dd日').format(user.birthDate),
                    ),
                    _buildInfoRow('出生时辰', user.birthTime),
                    _buildInfoRow('出生地点', user.birthPlace),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard(context, '八字信息', [
                    _buildInfoRow('年柱', '$heavenlyStem$earthlyBranch'),
                    _buildInfoRow('月柱', '$monthGan$monthZhi'),
                    _buildInfoRow('日柱', '$dayGan$dayZhi'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard(context, '账号信息', [
                    _buildInfoRow(
                      '登录方式',
                      user.authProvider == 'gmail' ? 'Gmail' : '微信',
                    ),
                    _buildInfoRow(
                      '注册时间',
                      DateFormat('yyyy年MM月dd日').format(user.birthDate),
                    ),
                  ]),
                ],
              ),
            ),
            // 退出登录按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('退出登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
