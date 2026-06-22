# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Google Play Core - Split Install
-keep class com.google.android.play.core.** { *; }
-keepclassmembers class com.google.android.play.core.** { *; }

# Google ML Kit - Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keepclassmembers class com.google.mlkit.vision.text.** { *; }

# Google ML Kit - Common
-keep class com.google.mlkit.common.** { *; }
-keepclassmembers class com.google.mlkit.common.** { *; }

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }

# Guava
-keep class com.google.common.** { *; }
-keepclassmembers class com.google.common.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Disable warnings
-dontwarn com.google.android.play.core.**
-dontwarn com.google.mlkit.**
-dontwarn org.tensorflow.lite.**

