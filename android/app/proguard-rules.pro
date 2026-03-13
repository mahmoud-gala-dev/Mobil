# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# MyFatoorah SDK rules
-keep class com.myfatoorah.** { *; }
-dontwarn com.myfatoorah.**

# WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Gson (if used by MyFatoorah)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
