# 一、开发环境准备
1. 安装必备软件
• Flutter SDK: [官网下载](https://docs.flutter.dev/get-started/install/macos)
• Android Studio（含Android SDK）: [下载地址](https://developer.android.com/studio)
• Xcode（仅需安装Command Line Tools）: 通过App Store安装
• Visual Studio Code 或 Cursor: [Cursor下载](https://cursor.sh/)
• 推荐安装插件：
  - Flutter（提供Flutter开发支持）
  - Dart（提供Dart语言支持）
  - Firebase Tools（Firebase集成）
  - GitLens（Git历史管理）
  - Error Lens（实时错误提示）

2. 开发工具设置
• Cursor AI配置:
  - 在设置中启用自动补全
  - 配置API key（如果需要）
  - 熟悉快捷键：
    * `Cmd + K`: 生成代码
    * `Cmd + L`: AI补全
    * `Cmd + /`: 获取建议
    * `Cmd + Shift + P`: 命令面板

3. 配置环境变量
```bash
# 添加到 ~/.zshrc
export PATH="$PATH:[你的Flutter安装路径]/flutter/bin"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 验证安装
source ~/.zshrc
flutter doctor  # 检查并解决所有问题
```

4. Android开发准备
• 在Android Studio中:
  - 安装Android SDK 33或更高版本
  - 创建Android模拟器（建议Pixel 4 API 33）
  - 配置JDK环境（推荐版本17）

# 二、项目初始化
1. 创建Flutter项目
```bash
flutter create fortune_teller
cd fortune_teller
```

2. 配置Android
• 打开Android Studio → 配置最低SDK版本21
• 修改android/app/build.gradle中的applicationId

# 三、后端服务搭建（使用Firebase）
1. 创建Firebase项目
• 访问[Firebase Console](https://console.firebase.google.com/)
• 创建新项目步骤：
  1. 点击"创建项目"
  2. 输入项目名称
  3. 选择是否启用Google Analytics
  4. 选择Analytics账号

2. Firebase配置
• 启用认证服务：
  1. 在左侧菜单选择"Authentication"
  2. 点击"开始使用"
  3. 启用以下登录方式：
     - 邮箱/密码
     - Google登录
     - 微信登录（需要微信开放平台账号）

• 配置Firestore数据库：
  1. 选择"Firestore Database"
  2. 创建数据库
  3. 选择测试模式或生产模式
  4. 选择地理位置（建议asia-east1）

3. API安全性增强
```javascript
// 在Firebase Functions中实现API代理
exports.getLLMPrediction = functions.https.onCall(async (data, context) => {
  // 验证用户身份
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '需要登录');
  }

  // 验证请求频率
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  const lastRequestTime = userDoc.data()?.lastRequestTime?.toDate() || 0;
  const now = new Date();
  
  if (now - lastRequestTime < 60000) { // 1分钟限制
    throw new functions.https.HttpsError('resource-exhausted', '请求过于频繁');
  }

  // 从安全存储获取API密钥
  const apiKey = await admin.secretManager().getSecret('llm-api-key');

  try {
    const response = await axios.post('https://api.example.com/v1/predict', {
      user_data: data.birthInfo,
      timestamp: now.toISOString()
    }, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'X-Request-ID': context.auth.uid,
      }
    });

    // 更新用户最后请求时间
    await userDoc.ref.update({
      lastRequestTime: admin.firestore.FieldValue.serverTimestamp()
    });

    return response.data;
  } catch (error) {
    console.error('API调用失败:', error);
    throw new functions.https.HttpsError('internal', '预测服务暂时不可用');
  }
});
```

# 四、核心功能开发
1. 认证模块实现
```dart
// 实现Google登录
Future<UserCredential> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
  return await FirebaseAuth.instance.signInWithCredential(
    GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    ),
  );
}

// 微信登录需要额外配置（需使用插件flutter_wechat_auth）
```

2. 用户信息管理
```dart
// 上传头像
Future<void> uploadAvatar(File image) async {
  final ref = FirebaseStorage.instance
      .ref('avatars/${FirebaseAuth.instance.currentUser!.uid}');
  await ref.putFile(image);
  final url = await ref.getDownloadURL();
  await FirebaseFirestore.instance.collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .update({'avatarUrl': url});
}
```

3. 运势预测功能
```dart
Future<String> getFortunePrediction(BirthInfo birthInfo) async {
  final result = await FirebaseFunctions.instance
      .httpsCallable('getHoroscope')
      .call({
        'birthday': birthInfo.toJson(),
        // 其他必要参数...
      });
  return result.data['prediction'];
}
```

# 五、安全强化措施
1. API Token保护方案
• 使用Firebase的Security Rules控制数据库访问
• 实现Token轮换机制：
  ```javascript
  // 在Cloud Functions中实现
  exports.rotateApiToken = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const newToken = generateSecureToken();
    await admin.secretManager().updateSecret('llm-api-key', newToken);
  });
  ```

2. 应用安全配置
• 启用SSL证书固定（Certificate Pinning）
• 实现设备指纹验证
• 添加请求签名验证

3. 数据安全
• 实现端到端加密：
  ```dart
  // 使用 encrypt 包进行数据加密
  final encrypter = Encrypter(AES(key));
  final encrypted = encrypter.encrypt(sensitiveData, iv: iv);
  ```

• 敏感数据处理：
  ```dart
  // 使用 flutter_secure_storage 存储敏感信息
  final storage = FlutterSecureStorage();
  await storage.write(key: 'user_token', value: token);
  ```

# 六、测试与调试
1. 安卓设备测试
```bash
flutter run -d emulator-5554
```

2. 常用调试技巧
• 使用Flutter DevTools分析性能
• 添加--release标志进行生产环境测试
• 使用flutter_test包编写单元测试

# 七、发布准备
1. 构建APK
```bash
flutter build apk --release
```

2. Google Play发布流程
• 创建[开发者账号](https://play.google.com/console)
• 准备材料：
  • 512x512像素应用图标
  • 1024x500像素特色图片
  • 隐私政策声明（需包含用户数据处理说明）
  • 屏幕截图（至少2张）

3. 微信登录特别要求
• 需要提供微信开放平台的审核材料
• 配置应用签名（使用SHA-256证书指纹）

# 八、持续维护建议
1. 错误监控
• 集成Firebase Crashlytics:
  ```yaml
  # pubspec.yaml
  dependencies:
    firebase_crashlytics: ^latest_version
  ```
  ```dart
  // main.dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(MyApp());
  }
  ```

2. 性能监控
• 添加Firebase Performance Monitoring
• 实现自定义跟踪点
• 监控关键用户行为

3. 用户反馈收集
• 集成应用内反馈系统
• 实现崩溃报告自动收集
• 添加用户行为分析

4. 版本更新策略
• 实现强制更新机制
• 配置增量更新
• 建立更新通知系统

# 九、开发流程建议（适合新手）
1. 环境搭建（1-2天）
• 按照上述步骤完成所有工具安装
• 运行flutter doctor确保无错误
• 创建测试项目验证环境

2. 基础功能开发（3-5天）
• 完成用户界面设计
• 实现基础导航功能
• 集成Firebase基础服务

3. 认证系统（3-4天）
• 实现邮箱登录
• 添加社交媒体登录
• 完成用户信息管理

4. 核心功能（5-7天）
• 集成大模型API
• 实现运势预测逻辑
• 添加用户个性化功能

5. 测试与优化（3-4天）
• 进行单元测试
• 执行集成测试
• 性能优化

6. 发布准备（2-3天）
• 准备应用商店材料
• 完成隐私政策
• 构建发布版本

总计预估时间：约3周