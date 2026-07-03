# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.zhuomostudio.** { *; }

# Riverpod / reflection
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes (serialization)
-keep class com.zhuomostudio.smart_classroom.models.** { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# pdfrx / pdfium
-keep class org.libpdftest.** { *; }
-keep class com.pdftron.** { *; }
