# Agora RTC — optional screen-capture / MediaProjection refs (not bundled when agora-special-full is excluded)
-dontwarn io.agora.base.VideoFrame$Buffer
-dontwarn io.agora.base.VideoFrame$I420Buffer
-dontwarn io.agora.base.VideoFrame$TextureBuffer$ContextType
-dontwarn io.agora.base.VideoFrame$TextureBuffer$Type
-dontwarn io.agora.base.VideoFrame$TextureBuffer
-dontwarn io.agora.base.VideoFrame
-dontwarn io.agora.base.internal.CalledByNative
-dontwarn io.agora.base.internal.ContextUtils
-dontwarn io.agora.base.internal.Logging
-dontwarn io.agora.base.internal.ThreadUtils$ThreadChecker
-dontwarn io.agora.base.internal.ThreadUtils
-dontwarn io.agora.base.internal.video.EglBase$Context
-dontwarn io.agora.base.internal.video.TimerSurfaceTextureHelper
-dontwarn io.agora.base.internal.video.VideoSink
-dontwarn io.agora.rtc2.gl.EglBaseProvider
-dontwarn io.agora.rtc2.extensions.**

-keep class io.agora.** { *; }
-keep class io.agora.rtc.** { *; }

# Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.razorpay.**

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
