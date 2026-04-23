# Progress Log

## 2026-04-23
- Started implementation for exposing mask style configuration from React Native to native Android/iOS views.
- Confirmed iOS SDK already exposes `FaceAuthenticationView.MaskStyle` with `instructionMessageMap`.
- Confirmed Android bridge currently creates `FaceAuthenticationView` directly and needs a prop-based config path.
- Added a typed RN `maskStyle` prop surface, wired it into example usage and README, and implemented native parsing/application on Android and iOS.
- Removed the extra `MaskStyleConfig` wrapper and now use the SDK's nested `FaceAuthenticationView.MaskStyle` directly in native code.
- Verified `npm run typecheck` passes after the final rename.
