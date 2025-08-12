-keep class com.shopify.** { *; }
-keep class io.flutter.** { *; }
-dontwarn okio.**
-dontwarn org.conscrypt.**
 
## Keep Google Play Core (deferred components referenced by Flutter)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
