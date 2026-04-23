# Mask Style Prop RN Implementation Plan

> Execute with: @mobile-master

**Goal:** Expose native mask style configuration to React Native through a single `maskStyle` prop, including custom instruction messages.
**Platform(s):** React Native, Android, iOS
**Architecture:** Keep the JS surface small and platform-agnostic with one typed object prop. Parse the prop once in each native bridge, convert it to the SDK-specific mask style object, and apply it to the live face-auth view so future updates are reflected without recreating the component.
**Tech Stack:** TypeScript, React Native view props, Kotlin `@ReactProp`, Swift `RCT_EXPORT_VIEW_PROPERTY`, native SDK mask style APIs

---

### Task 1: Extend RN prop surface

**Files:**
- Modify: `src/LivenessView.ts`
- Modify: `README.md`
- Modify: `example/src/App.js`
- Modify: `example/src/Liveness.js`

**Step 1 — RED: Update types and usage examples**
- Add a `maskStyle` prop type with `instructionMessageMap`.

**Step 2 — GREEN: Keep the native component signature aligned**
- Wire the prop through the typed native component declaration.

**Step 3 — REFACTOR: Document the object shape**
- Show a minimal example for React Native consumers.
- Status: completed.

### Task 2: Bridge `maskStyle` on Android and iOS

**Files:**
- Modify: `android/src/main/java/com/livenessrn/LivenessViewManager.kt`
- Modify: `android/src/main/java/com/livenessrn/LivenessView.kt`
- Modify: `ios/LivenessView.swift`
- Modify: `ios/LivenessView.m`

**Step 1 — RED: Preserve config in the bridge layer**
- Parse incoming JS map/dictionary into native config data.

**Step 2 — GREEN: Apply config to the face auth view**
- Call the SDK `setMaskStyle(...)` API with the provided colors and instruction map.

**Step 3 — REFACTOR: Support late prop updates**
- Re-apply the config if the prop changes after the view is mounted.
- Status: completed.

### Task 3: Validate

**Files:**
- No code changes

**Step 1 — Run validation**
- Run TypeScript/lint checks for the RN package.

**Step 2 — Inspect results**
- Fix any type or syntax regressions from the bridge changes.
- Status: completed. `npm run typecheck` passes; `npm run lint` is still blocked by a missing `@react-native/babel-preset` in the repo environment.
