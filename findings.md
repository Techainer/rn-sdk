# Findings

## 2026-04-23
- The iOS SDK exposes `FaceAuthenticationView.MaskStyle` and `setMaskStyle(...)` only on `FaceAuthenticationView`, not on `FaceAuthentication3DView`.
- React Native object keys for `instructionMessageMap` arrive as strings on Android/iOS, so native code must convert them to `Int`.
- The RN surface currently uses `requireNativeComponent`, so adding a typed `maskStyle` prop on `src/LivenessView.ts` is enough for JS consumers.
- The native bridge does not need a custom `MaskStyleConfig`; it can parse the RN object and instantiate the SDK's nested `FaceAuthenticationView.MaskStyle` directly.
