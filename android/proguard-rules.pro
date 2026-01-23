# Keep LivenessViewManager and its members to ensure React Native can find it and call its methods (including @ReactProp)
-keep class com.livenessrn.LivenessViewManager { *; }

# Keep the View class
-keep class com.livenessrn.LivenessView { *; }

# Keep the Fragment
-keep class com.livenessrn.LivenessFragment { *; }

# Keep React Native standard classes usually needed
-keep class com.facebook.react.** { *; }
-keep class com.facebook.jni.** { *; }
-dontwarn com.facebook.react.**

# Ensure RCTDeviceEventEmitter is kept so getJSModule works
-keep class com.facebook.react.modules.core.DeviceEventManagerModule$RCTDeviceEventEmitter { *; }

# Keep standard Android Fragment/Activity classes if necessary (usually kept by default, but good to be safe for library modules)
-keep class androidx.fragment.app.** { *; }
