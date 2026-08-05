# Hướng dẫn setup & sử dụng `Guard/` (iOS) — eKYC Biometrics Guard

> Module bảo mật eKYC cho iOS SDK. Port từ Android `com.example.ekycplugin.eykc.gaurd`.
> Điểm vào chính: **`SecurityGuard`** (facade cho mọi thứ).
> Đối chiếu đề xuất **SEC-BIO-01** (Ch. 4 Nhóm D, Ch. 9.7, Ch. 14.5).

---

## 0. Bản đồ module

| File / thư mục | Vai trò | Cần backend? |
|---|---|---|
| `SecurityGuard.swift` | **Facade chính** — gọi mọi thứ qua đây | tuỳ tính năng |
| `SecurityResult.swift` | `SecurityVerdict` + nhãn `[Jailbreak]`, `[HookFramework]`… | Không |
| `LayerA/JailbreakDetector.swift` | ★ Dò jailbreak (thay root của Android) | Không |
| `LayerA/HookDetector.swift` | Frida / Substrate / libhooker / ElleKit | Không |
| `LayerA/DebuggerDetector.swift` | Debugger attached (thay ADB/USB-debug) | Không |
| `LayerA/AppIntegrityChecker.swift` | Chống ký lại IPA (bundleID + code-sign flags) | Không |
| `LayerA/SimulatorDetector.swift` | Simulator (thay emulator) | Không |
| `LayerA/ScreenCaptureDetector.swift` | Screen record / mirror (thay overlay) | Không |
| `LayerA/VirtualCameraDetector.swift` | Camera ngoài / Continuity Camera | Không |
| `LayerA/CameraMonitor.swift` | Giám sát **thời-gian-thực** mỗi 3s trong phiên | Không |
| `LayerB/DeviceIntegrityGate.swift` | **App Attest / DeviceCheck** (Tầng B) | **Có** |
| `Native/SecurityGuardCore.m` + `SecurityGuardBridge.h` | ptrace/sysctl/csops ở tầng **C** (khó hook) | Không |
| `AntiInjection/` (6 file) | Chống camera injection — **roadmap v4** | Attestation cần |

**Ba tầng phòng thủ** (giống Android & đề xuất giải pháp):
- **Tầng A** (client, không cần mạng): `checkSecurity()` / `evaluate()` + `CameraMonitor`.
- **Tầng B** (cần Apple + backend ngân hàng): `requestDeviceIntegrity()` — App Attest.
- **Anti-injection** (session-time, **v4**): `AntiInjection/` — additive, chưa cam kết đợt này.

---

## 1. Setup TỐI THIỂU (1 dòng)

Gọi 1 lần lúc khởi động app:

```swift
SecurityGuard.initialize(expectedSigners: ["COM.YOURBANK.MOBILEAPP"])   // bundle identifier
```

- Entry **có dấu `.`** → coi là bundle identifier và được so khớp.
- Entry **không có dấu `.`** (vd Team ID) → **bỏ qua** khi so khớp (fail-open) vì Team ID
  không xác thực tin cậy được on-device; việc đó để **App Attest (Tầng B)** lo.
- **Không gọi** `initialize` → check chữ ký **fail-open** (bỏ qua) để SDK vẫn chạy khi tích hợp.
  **Production PHẢI cấu hình.**

> SDK **tự gọi** guard bên trong `CardValidateView` / `FaceValidateView` /
> `FaceAuthenticationView` / `FaceAuthentication3DView`. Chỉ cần `initialize(...)` là Tầng A chạy.
>
> **Tự động gồm 2 lớp** (host KHÔNG cần gọi tay, tránh gọi trùng):
> 1. **Pre-flight** `checkSecurity()` chạy khi view khởi tạo / mở camera.
> 2. **Real-time** `startCameraMonitoring()` chạy trong `startCamera()` và tự `stop()` trong
>    `stopCamera()` — bắt camera lạ / screen-record xuất hiện **giữa phiên** (re-check mỗi 3s).
>
> Host chỉ cần **lắng nghe 1 callback** trên view để xử lý UI khi bị chặn:
> ```swift
> faceView.onSecurityThreat = { message in
>     // message dạng: "[Jailbreak] ... \n[HookFramework] ..."
>     // SDK đã tự stopCamera(); host hiển thị thông báo / thoát luồng eKYC.
> }
> ```
> Các API ở §2.1–2.3 vẫn `public` để host chủ động gate thêm ngoài luồng camera (nếu muốn).

### 1.1. Info.plist (BẮT BUỘC để bật đủ tín hiệu jailbreak)

Thiếu mục này, iOS luôn trả `false` cho `canOpenURL` → mất 1 tín hiệu (an toàn nhưng yếu hơn):

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>cydia</string>
  <string>sileo</string>
  <string>zbra</string>
  <string>filza</string>
</array>
```

### 1.2. Anti-debug lúc khởi động (khuyến nghị, chỉ Release)

```swift
#if !DEBUG
sg_deny_debugger()      // ptrace(PT_DENY_ATTACH) — chặn gắn debugger vào tiến trình
#endif
```

---

## 2. Tầng A — kiểm tra thiết bị (không cần backend)

### 2.1. `checkSecurity` — gom TẤT CẢ lý do (dùng trước camera)

```swift
SecurityGuard.checkSecurity { isHack, message in
    if isHack {
        // huỷ phiên eKYC + hiện lỗi. message ví dụ: "[Jailbreak] ... \n[HookFramework] ..."
    }
}
```
> Callback bắn từ **background thread** → đụng UI phải `DispatchQueue.main.async`.

Nhận kết quả từ SDK view (đã auto-wire):
```swift
faceView.onSecurityThreat = { message in /* huỷ phiên + báo lỗi */ }
```

### 2.2. `evaluate` — có kiểu, dừng ở lỗi đầu tiên

```swift
let r = SecurityGuard.evaluate()          // gọi off main thread
if !r.isPassed { print(r.verdict, r.reason) }   // .failedJailbreak, .failedHookFramework, ...
```

Bản đồng bộ khác: `SecurityGuard.isCompromisedSync()`, `SecurityGuard.getCompromiseReason()`.

### 2.3. `startCameraMonitoring` — giám sát real-time (mỗi 3s)

```swift
let monitor = SecurityGuard.startCameraMonitoring { isHack, msg in if isHack { huyPhien(msg) } }
// ...
monitor.stop()      // gọi khi đóng màn camera
```

### 2.4. Rule opt-in (mặc định TẮT — có thể phạt nhầm máy cũ)

```swift
SecurityGuard.setRequireSecureEnclaveKey(true)
```

---

## 3. Tầng B — App Attest / DeviceCheck (CẦN backend ngân hàng)

Chốt chặn với **jailbreak đã che giấu** (Shadow/Liberty) mà Tầng A không thấy.

```swift
// 1) Lấy nonce dùng-một-lần từ SERVER NGÂN HÀNG
// 2) Xin chứng thực, gửi token về server để verify
SecurityGuard.requestDeviceIntegrity(nonce: nonceTuServer) { provider, token, error in
    if let token = token, let provider = provider {
        guiLenServer(provider, token)          // .appAttest hoặc .deviceCheck
    } else {
        // KHÔNG phải tấn công (iOS<14 / không hỗ trợ) → fallback Tầng A + chính sách nghiệp vụ
    }
}
```

**Client KHÔNG tự kết luận.** Server ngân hàng phải:
- Verify attestation object với **Apple App Attest root CA**;
- Kiểm `clientDataHash == SHA256(nonce)` (chống phát lại);
- Xác nhận khoá **hardware-backed** (Secure Enclave);
- Với DeviceCheck: validate token qua Apple DeviceCheck API.

---

## 4. Anti Camera Injection (roadmap **v4**, additive)

```swift
let g = SecurityGuard.newAntiInjectionGuard()
g.begin()                                        // khi mở camera
// g.metadataProbe().record(sampleBuffer)        // mỗi frame
// g.sensorDetector().updateFaceCentroid(cx, cy) // mỗi bounding box mặt
// FlashChallengeView + submitFaceReflectance(...)   (seed = nonce server)
HardwareAttestation.attest(challenge: nonceTuServer) { at in
    let v = AntiCameraInjectionGuard.aggregate(
        g.metadataProbe().evaluate(), g.sensorDetector().evaluate(), at.toAntiInjection())
    if v.verdict == .injectionDetected { huyPhien(v.reason) }
}
g.end()                                          // khi đóng camera
```
Ngưỡng đã port đúng Android: CV `0.002`/`0.003`, motion `0.06`/`0.004`, flash ratio `0.6`/`0.35`,
aggregate confidence `0.85`/`0.6`/`0.4`. **Không bao giờ block** khi `inconclusive`/`unavailable`.

---

## 5. Bảng: chống gì / gọi gì / cần gì

| Mối đe doạ (đề xuất giải pháp) | Gọi | Cần backend? |
|---|---|---|
| Jailbreak thường (unc0ver/Dopamine/checkra1n) | `checkSecurity` | Không |
| Jailbreak **che giấu** (Shadow/Liberty) | `requestDeviceIntegrity` (App Attest) | **Có** |
| Tweak / Frida / hook (Substrate, libhooker, ElleKit) | `checkSecurity` | Không |
| Ký lại IPA / phân phối ngoài App Store | `initialize` + `checkSecurity` (+ App Attest) | App Attest: Có |
| Debugger / instrumentation | `checkSecurity` (+ `sg_deny_debugger()`) | Không |
| Simulator | `checkSecurity` | Không |
| Screen record / mirror | `checkSecurity` + `startCameraMonitoring` | Không |
| Camera ngoài / Continuity | `startCameraMonitoring` | Không |
| Hardware camera injection | `AntiInjection/` (**v4**) | Attestation: Có |

---

## 6. Checklist tích hợp

- [ ] `SecurityGuard.initialize(expectedSigners: [...])` lúc khởi động.
- [ ] Thêm `LSApplicationQueriesSchemes` vào Info.plist.
- [ ] `sg_deny_debugger()` trong Release.
- [ ] Gán `onSecurityThreat` trên các SDK view → huỷ phiên + báo lỗi.
- [x] `startCameraMonitoring` — **SDK đã tự gọi** trong `startCamera()` và tự `stop()` trong
      `stopCamera()` của cả 4 view. Host không cần làm gì.
- [ ] (Tầng B) Bật App Attest trong Apple Developer account + dựng API nonce/verify ở server ngân hàng.

---

## 7. Giới hạn trung thực

- Tầng A chạy trên máy → **jailbreak che giấu chuyên nghiệp có thể lọt** ⇒ bắt buộc Tầng B cho
  giao dịch giá trị cao. Đây là **giới hạn vật lý**, không phải thiếu sót code (giống Shamiko/Android).
- `SecStaticCodeCheckValidity` / `SecCode` **không có trên iOS** → chống repackaging phía client chỉ
  nâng rào cản; chốt thật là App Attest.
- App Attest cần **iOS 14+** và Secure Enclave; máy cũ → `error` (fail-open, **đừng chặn user**).
- `ScreenCaptureDetector` **chỉ** dùng `isCaptured` (đang ghi/phát màn hình) và trả thông báo
  **hành động được** ("vui lòng tắt ghi màn hình rồi thử lại"). Các điều kiện gây báo nhầm
  (CarPlay / AirPlay / màn hình ngoài) **đã bị loại bỏ** — xem §10.
- `SensorFusion` trả `inconclusive` khi đặt bàn/tripod; `FlashChallenge` yếu khi nắng gắt.
- **Không có phần nào chống deepfake** — đó là việc của model liveness phía backend.

---

## 8. QA — đối chiếu Phụ lục B của SEC-BIO-01

| # | Kịch bản | Kỳ vọng |
|---|---|---|
| 18 | iOS jailbreak (unc0ver / Dopamine / checkra1n) | **Bị chặn** `[Jailbreak]` |
| 19 | iOS jailbreak **che giấu** (Shadow / Liberty Lite) | Client **không báo** (đúng thiết kế) → **App Attest FAIL** |
| 20 | Ký lại IPA / gắn Frida trên máy jailbreak | **Bị chặn** `[AppTampered]` / `[HookFramework]` |
| 21 | iOS máy thật, app cài từ **App Store** | **KHÔNG bị chặn** (không báo nhầm) |

Case 21 quan trọng ngang các case còn lại: nó kiểm chứng hệ thống không báo nhầm người dùng hợp lệ.

---

## 9. TỰ KIỂM CHỨNG khi KHÔNG có máy jailbreak

### 9.1 `diagnostics()` — chứng minh KHÔNG báo nhầm máy thật

Chạy 1 lần trên iPhone thường (bản TestFlight/Release):

```swift
print(SecurityGuard.diagnosticsReport())
```

Kỳ vọng trên máy thật sạch:

```
=== eKYC Guard diagnostics ===
signers configured: yes (1)
- AppTampered: clean
- Debugger: clean
- HookFramework: clean
- Jailbreak: clean
- NoSecureEnclave: clean
- ScreenCapture: clean
- Simulator: clean
- VirtualCamera: clean
RESULT: CLEAN
```

`diagnostics()` chạy **từng tín hiệu riêng lẻ và KHÔNG chặn gì** → an toàn để nhúng vào một
màn hình debug nội bộ. Nếu trên máy thật sạch có bất kỳ mục **khác `clean`** ⇒ đó là **bug
báo nhầm, phải báo lại ngay** (không được ship).

### 9.2 Ba tín hiệu test được NGAY, không cần jailbreak

| Tín hiệu | Cách dựng | Kỳ vọng |
|---|---|---|
| `[Simulator]` | Chạy app trên iOS Simulator | Bị chặn |
| `[Debugger]` | Build **Release** rồi attach debugger Xcode (Debug → Attach to Process) | Bị chặn |
| `[ScreenCapture]` | Bật Ghi màn hình (Control Center) rồi vào eKYC | Bị chặn, kèm thông báo tắt ghi màn hình |
| **Máy thật sạch** | iPhone thường, app TestFlight/App Store | **KHÔNG bị chặn** ← quan trọng nhất |

Ba tín hiệu còn lại (`Jailbreak`, `HookFramework`, `AppTampered`) cần máy jailbreak để dựng;
nếu không có thiết bị ⇒ dựa vào **Tầng B (App Attest)** làm lớp chốt, đúng như case 19.

### 9.3 Mức kiểm chứng đã thực hiện (compile-level, không phải runtime)

- **17 file Swift**: `swiftc -typecheck` với iOS SDK thật, `-target arm64-apple-ios13.0`,
  có import bridge ObjC → **0 lỗi, 0 warning**. Điều này xác nhận cả **availability gating**
  đúng (iOS 14 App Attest / iOS 17 external-camera không rò xuống deployment iOS 13).
- **`SecurityGuardCore.m`**: `clang -Wall -fsyntax-only` → 0 warning; compile ra object thật,
  export đủ 3 symbol `sg_is_debugged`, `sg_deny_debugger`, `sg_csops_status`.
- **CHƯA** kiểm chứng runtime trên máy thật / máy jailbreak (cần thiết bị) ⇒ dùng §9.1 + §9.2.

---

## 10. Thiết kế CHỐNG BÁO NHẦM — các check đã CHỦ ĐỘNG loại bỏ

| Check bị loại | Lý do loại |
|---|---|
| `/bin/sh` | **iOS gốc có sẵn `/bin/sh`** → nếu check sẽ chặn oan 100% máy thật. Vẫn giữ `/bin/bash` vì file này chỉ xuất hiện khi jailbreak. |
| `fork()` | Trên iOS, `fork()` **không bị sandbox chặn nhất quán** (nhiều bản trả pid hợp lệ trên máy KHÔNG jailbreak) → chặn oan; thêm nữa `fork()` trong app đa luồng có thể **deadlock** ở tiến trình con và là **rủi ro bị App Store từ chối**. |
| `UIScreen.screens.count > 1`, `mirrored != nil` | Bật `true` khi khách cắm **CarPlay / AirPlay / màn hình ngoài** → chặn oan khách thật. |
| `hw.machine == "arm64"` | App iOS chạy trên **Mac Apple Silicon** có thể trả `arm64`. Simulator thật đã bị bắt bởi cờ compile-time nên không mất độ phủ. |
| `csops`/`CS_VALID` **chặn** | Hạ xuống **chỉ log**: không thể xác nhận chắc chắn `CS_VALID` luôn bật trên mọi app App Store hợp lệ; nếu chặn thì rủi ro chặn oan toàn bộ khách. Chống ký lại IPA mạnh nhất là **App Attest**. |

> **Nguyên tắc xuyên suốt:** tín hiệu nào **không chắc chắn 100%** ⇒ **fail-open** (bỏ qua),
> không chặn. Thà bỏ sót một tín hiệu ở Tầng A (đã có **Tầng B** chốt phía server) còn hơn
> chặn oan một khách hàng thật.

### 10.1 Lưu ý khi submit App Store

`ptrace(PT_DENY_ATTACH)` và `csops` là **private API** → có rủi ro bị review từ chối.

- `sg_deny_debugger()` **SDK không tự gọi** — bạn hoàn toàn có thể **không gọi** để tránh rủi ro
  (đánh đổi: mất lớp chống attach debugger).
- `sg_csops_status` hiện được gọi nhưng **chỉ để log**. Nếu muốn tuyệt đối an toàn khi submit:
  xoá đoạn (2) trong `AppIntegrityChecker.check(...)` và bỏ khai báo khỏi
  `Guard/Native/SecurityGuardBridge.h` + `SecurityGuardCore.m`.

### 10.2 App Attest bị Apple giới hạn tần suất

Apple **throttle** `attestKey`. Chỉ gọi `requestDeviceIntegrity(nonce:)` **một lần cho mỗi phiên
eKYC**; không gọi trong vòng lặp hay retry dồn dập, tránh bị Apple trả lỗi và tưởng là tấn công.

---

## 11. Kỹ thuật bổ sung từ 2 dự án tham chiếu (MIT)

Đã hợp nhất các kỹ thuật tốt từ hai dự án mã nguồn mở, **cả hai đều giấy phép MIT** nên dùng
thương mại được. Ghi công:

- [SmileZXLee/ZXHookDetection](https://github.com/SmileZXLee/ZXHookDetection) — MIT
- [thii/DTTJailbreakDetection](https://github.com/thii/DTTJailbreakDetection) — MIT

| # | Kỹ thuật | Nguồn | File | Rủi ro báo nhầm |
|---|---|---|---|---|
| 6 | `isiOSAppOnMac` → thoát sớm, **không** coi là jailbreak | DTT | `JailbreakDetector` | 🟢 **Giảm** FP (macOS có sẵn `/bin/bash`, `/usr/sbin/sshd`) |
| 7 | `dlsym`+`dladdr` xác minh hàm C còn nằm trong `/usr/lib/` | ZX | `HookDetector` | 🟢 Thấp |
| 8 | `fopen()` — đường dò tệp **thứ ba** (ngoài FileManager & stat) | DTT | `JailbreakDetector` | 🟢 Không đổi (dùng lại danh sách path đã lọc) |
| 9 | Quét `.dylib` lạ trong bundle | ZX | `HookDetector` | 🔴 Cao → **mặc định chỉ log** |
| 10 | Team ID từ `embedded.mobileprovision` | ZX | `AppIntegrityChecker` | 🟡 Thấp (3 tầng fail-open) |

### 11.1 Những chỗ CỐ Ý làm khác bản gốc (để không báo nhầm)

- **#7:** ZX so **bằng nhau tuyệt đối** với chuỗi cứng `/usr/lib/system/libsystem_kernel.dylib`.
  Nếu Apple đổi layout dyld shared cache thì **báo nhầm toàn bộ máy thật**. Bản này chỉ báo khi
  hàm bị trỏ **ra ngoài `/usr/lib/`** → bảo thủ hơn, vẫn bắt được hook.
- **#9:** ZX báo **mọi** `.dylib` dưới `/var/containers/Bundle/Application` — nhưng app thật
  **có** framework hợp lệ (`ekyc_ios_sdk.framework`, MLKit, TensorFlowLite) ⇒ copy nguyên xi sẽ
  **chặn 100% máy thật**. Bản này: bỏ qua `<bundle>/Frameworks/` và binary chính, và
  **mặc định chỉ `print()` cảnh báo, KHÔNG chặn**.
- **#10:** App từ **App Store không có** `embedded.mobileprovision` ⇒ **bắt buộc fail-open**.
  Chỉ báo khi: file tồn tại **+** host đã khai Team ID **+** không khớp.

### 11.2 Bật chặn `BundleDylib` (tuỳ chọn, làm sau khi đã kiểm chứng)

```swift
// B1: chạy trên bản Release thật, xem mục "BundleDylib" trong báo cáo
print(SecurityGuard.diagnosticsReport())

// B2: CHỈ khi B1 cho kết quả "BundleDylib: clean" trên mọi thiết bị thử nghiệm
SecurityGuard.setStrictBundleDylibCheck(true)
```

> `diagnostics()` luôn hiển thị `BundleDylib` ở chế độ strict để bạn **soi trước**, kể cả khi
> công tắc chặn đang tắt. Đây là cách an toàn để quyết định có nên bật hay không.
