# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# uCrop / image_cropper rules (fix missing okhttp3 references)
-dontwarn com.yalantis.ucrop**
-dontwarn com.yalantis.ucrop.**
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }
