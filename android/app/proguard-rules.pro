# Flutter 混淆规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保持原生方法名
-keepclassmembers class * {
    native <methods>;
}

# 保留 Google Play Core 的类
-keep class com.google.android.play.** { *; } 