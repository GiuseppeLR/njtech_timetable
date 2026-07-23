# 南工课程表

南工课程表是一款面向南京工业大学学生的课程表管理工具，支持教务系统导入、XLS 导入、手动课程管理、课程提醒、课表分享、深色模式和课程冲突检测。
该程序由Dart语言编写，结合Kotlin和SwiftUI为iOS平台和Android平台提供支持。

## 功能

- 教务系统 WebView 导入课表
- XLS 文件导入课表
- 手动添加、编辑、删除课程
- 当前周和学期开始日期设置
- 课程开始前系统通知提醒
- 课表导入/导出，便于同学之间分享
- 深色模式，可跟随系统自动切换
- 课程冲突检测
- 导入前自动备份和备份恢复
- App 内反馈入口

## 截图

可以在这里放几张 App 截图：

```text
docs/screenshots/
```

## 下载

Android 安装包可以在 GitHub Release 页面下载。

如果你只是自己使用，也可以从源码编译：

```bash
flutter pub get
flutter build apk --release
```

生成文件：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## iOS 说明

iOS 版本需要 Apple 开发者签名。普通用户不能直接安装未签名 IPA。

如果你想自己编译：

```bash
flutter pub get
flutter build ipa --release
```

然后通过 Xcode Organizer 导出并安装。

## 开发环境

建议使用：

- Flutter 3.x
- Dart 3.x
- Android Studio
- Xcode 16.4 或更高版本
- Android Gradle Plugin 8.9.1
- Gradle 8.14
- Android NDK 28.2.13676358

## Android 构建

```bash
flutter clean
flutter pub get
flutter build apk --release
```

如果本地 NDK 版本识别异常，可以指定：

```bash
ANDROID_NDK_HOME=/Users/你的用户名/Library/Android/sdk/ndk/28.2.13676358 flutter build apk --release
```

## iOS 构建

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release
```

如果使用免费 Apple ID，只能用于个人设备测试；如果要通过 TestFlight 或 App Store 分发，需要 Apple Developer Program 账号。

## 项目结构

```text
lib/
  app.dart
  main.dart
  core/
  data/
  features/
    import/
    notifications/
    settings/
    timetable/
android/
ios/
macos/
```

## 隐私说明

本项目主要在本地保存课程信息和设置。课表数据不会上传到第三方服务器。

如果使用教务系统导入功能，登录过程发生在学校教务系统页面中，App 只解析课程数据用于本地课表展示。

## 反馈

如果你遇到问题或有建议，可以通过 App 内反馈入口联系开发者。

邮箱：

```text
yni501044@gmail.com
```

## 开源协议

本项目基于 Apache License 2.0 开源。
