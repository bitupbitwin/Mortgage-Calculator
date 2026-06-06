# Flutter 相关 keep 规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# 保留原生方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留注解
-keepattributes *Annotation*
