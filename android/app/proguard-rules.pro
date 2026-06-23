# Flutter ProGuard rules — keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase/network
-keep class org.postgresql.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Ignore Play Core missing classes (deferred components — not used)
-dontwarn com.google.android.play.core.**
-dontnote com.google.android.play.core.**

# Faster builds
-dontobfuscate
