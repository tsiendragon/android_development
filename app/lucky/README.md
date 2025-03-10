# 生辰八字运势 App

一个基于 Flutter 开发的生辰八字运势预测 App，可以根据用户的出生年月日时进行每日运势预测。

## 功能特点

- 支持输入个人出生年月日时信息
- 数据本地存储，无需重复输入
- 基于八字理论进行每日运势分析
- 支持实时刷新运势

## 开发环境要求

- Flutter SDK: ^3.7.0
- Dart SDK: ^3.7.0

## 依赖包

- provider: ^6.1.0 - 状态管理
- shared_preferences: ^2.2.2 - 本地数据存储
- intl: ^0.19.0 - 日期格式化
- lunar: ^1.6.1 - 农历和八字计算

## 安装和运行

1. 确保已安装 Flutter SDK 和配置好环境变量

2. 克隆项目并安装依赖：
```bash
flutter pub get
```

3. 运行项目：
```bash
flutter run
```

## 打包发布

### Android

1. 生成密钥库（如果还没有）：
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. 创建 `android/key.properties` 文件并配置签名信息：
```properties
storePassword=<密钥库密码>
keyPassword=<密钥密码>
keyAlias=key
storeFile=<密钥库文件的路径，例如：/Users/username/key.jks>
```

3. 确保在 `android/app/build.gradle` 文件中已配置签名设置：
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

4. 打包 APK：
```bash
flutter build apk --release
```
生成的 APK 文件位于 `build/app/outputs/flutter-apk/app-release.apk`

5. 打包 App Bundle（Google Play 推荐）：
```bash
flutter build appbundle --release
```
生成的 AAB 文件位于 `build/app/outputs/bundle/release/app-release.aab`

6. 安装到设备进行测试：
```bash
flutter install
```

### iOS

1. 打开 Xcode 项目：
```bash
cd ios
open Runner.xcworkspace
```

2. 在 Xcode 中配置签名信息

3. 打包 IPA：
```bash
flutter build ios --release
```

## 注意事项

- 首次使用需要输入个人信息
- 运势预测仅供参考，请理性对待
- 数据仅存储在本地，不会上传到服务器
