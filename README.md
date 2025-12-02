# Liveness SDK - React Native

A comprehensive React Native SDK for face liveness detection supporting both Flash and 3D depth detection methods.

## Requirements

### iOS
- iOS Deployment Target: 13.0 or higher
- Xcode 14 or newer
- Swift 5
- iPhone X or newer (for 3D depth detection)

### Android
- minSdkVersion: 24
- compileSdkVersion: 33
- targetSdkVersion: 33

### React Native
- React Native version < 0.73

## Installation

### NPM Installation

Add to your `package.json`:

**From GitHub:**
```json
{
  "dependencies": {
    "liveness-rn": "https://github.com/Techainer/rn-sdk.git#{tag_version}"
  }
}
```

**From local path:**
```json
{
  "dependencies": {
    "liveness-rn": "file://{path_to_folder_clone}/rn-sdk"
  }
}
```

Then run:
```bash
npm install
# or
yarn install
```

## Platform Configuration

### Android Setup

#### 1. Configure Gradle Repositories

In your root `android/build.gradle`, add:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

#### 2. Add Dependencies

In `android/app/build.gradle`, add:

```gradle
dependencies {
    implementation("com.facebook.react:react-android")
    implementation('androidx.appcompat:appcompat:1.4.1')
    implementation('androidx.constraintlayout:constraintlayout:2.1.3')

    // ML Kit & Camera
    implementation('com.google.mlkit:face-detection:16.1.5')
    implementation('com.otaliastudios:cameraview:2.7.2')

    // Security & Encryption
    implementation('org.bouncycastle:bcpkix-jdk18on:1.73')
    implementation('com.nimbusds:nimbus-jose-jwt:9.31')
    implementation('commons-codec:commons-codec:1.16.0')
}
```

#### 3. Configure Java Compatibility

In `android/app/build.gradle`, add:

```gradle
android {
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

#### 4. Gradle Plugin Versions

In your root `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.2.1'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

### iOS Setup

#### 1. Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

#### 2. Add Required Frameworks

Download the required frameworks folder and add to your iOS project:
[Download Frameworks](https://drive.google.com/file/d/1c6eE8M5KP4MGEhoroREixskUhqmnjFQY/view?usp=share_link)

After downloading, drag the frameworks folder into your `ios/` directory in Xcode.

#### 3. Configure Podfile

Add the following to your `ios/Podfile`:

```ruby
use_frameworks!

target 'YourApp' do
  # ... other pods

  pod 'ObjectMapper', '4.2'
  pod 'Alamofire', '5.8.1'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # Enable module stability
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

        # Set minimum deployment target
        if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
        end
      end
    end
  end
end
```

#### 4. Configure Info.plist Permissions

Add the following permissions to your `ios/YourApp/Info.plist`:

```xml
<key>LSRequiresIPhoneOS</key>
<true/>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>

<key>NSCameraUsageDescription</key>
<string>Camera access is required for face liveness detection</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access may be required for verification</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app does not use the microphone</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app does not save photos to your library</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app does not access your photo library</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arm64</string>
</array>
```

## Usage

### Basic Implementation

See complete examples in the `example/src/App.js` file.

```javascript
import React, { useRef, useState } from 'react';
import { LivenessView } from 'liveness-rn';

function App() {
  const livenessRef = useRef(null);
  const [isFlashCamera, setIsFlashCamera] = useState(true);

  const handleEvent = (data) => {
    const eventData = data.nativeEvent?.data;

    // Handle camera type detection callback
    if (eventData?.isFlash !== null && eventData?.isFlash !== undefined) {
      setIsFlashCamera(eventData.isFlash);
      return;
    }

    // Handle liveness success
    if (isFlashCamera) {
      // Flash camera mode - returns color image and original image
      const originalImage = eventData?.livenessOriginalImage; // base64
      const colorImage = eventData?.livenessColorImage; // base64
      const color = eventData?.color; // random color: 'r3', 'g3', or 'b3'

      processFlashLiveness({ originalImage, colorImage, color });
    } else {
      // 3D depth camera mode - returns original and thermal images
      const originalImage = eventData?.livenessOriginalImage; // base64
      const thermalImage = eventData?.livenessThermalImage; // base64

      process3DLiveness({ originalImage, thermalImage });
    }
  };

  return (
    <LivenessView
      ref={livenessRef}
      style={{ width: '100%', height: '100%' }}
      onEvent={handleEvent}
      isFlashCamera={isFlashCamera}
    />
  );
}
```

### Detection Modes

The SDK supports two detection modes:

#### 1. Flash Camera Mode (All Devices)

**Configuration:**
```javascript
isFlashCamera={true}
```

**Returns:**
- `livenessOriginalImage`: Original photo (base64)
- `livenessColorImage`: Color-tinted liveness photo (base64)
- `color`: Random color code used ('r3', 'g3', or 'b3')

**Use case:** Works on all Android and iOS devices

#### 2. 3D Depth Camera Mode (iPhone X and newer)

**Configuration:**
```javascript
isFlashCamera={false}
```

**Returns:**
- `livenessOriginalImage`: Original photo (base64)
- `livenessThermalImage`: Depth/thermal image (base64)

**Use case:** iPhone X or newer with depth camera support

**Auto-fallback:** If no response is received within 10 seconds on 3D mode, the SDK automatically switches to Flash mode.

### Component Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `style` | StyleProp | No | Component styles (recommended: `width: '100%', height: '100%'`) |
| `onEvent` | Function | Yes | Event callback handler |
| `isFlashCamera` | Boolean | Yes | Detection mode: `true` for Flash, `false` for 3D |

### Event Handling

```javascript
onEvent={(data) => {
  const eventData = data.nativeEvent?.data;

  // Camera type detection
  if (eventData?.isFlash !== null && eventData?.isFlash !== undefined) {
    console.log('Camera type:', eventData.isFlash ? 'Flash' : '3D');
    setIsFlashCamera(eventData.isFlash);
    return;
  }

  // Liveness detection success
  console.log('Liveness completed');
  if (isFlashCamera) {
    handleFlashMode(eventData);
  } else {
    handle3DMode(eventData);
  }
}}
```

### Best Practices

1. **Layout:** Set `LivenessView` to full screen for best user experience:
   ```javascript
   style={{ width: '100%', height: '100%' }}
   ```

2. **Camera Mode:** The SDK handles smooth transitions between Flash and 3D modes automatically. You only need to update the `isFlashCamera` prop.

3. **Device Compatibility:**
   - Use 3D mode (`isFlashCamera={false}`) only on iPhone X or newer
   - Android devices automatically use Flash mode
   - The SDK includes auto-fallback for incompatible devices

4. **Do NOT include these deprecated parameters:**
   - `requestid`
   - `appId`
   - `baseUrl`
   - `privateKey`
   - `publicKey`
   - `debugging`
   - `key` prop (the SDK handles smooth transitions internally)

## Troubleshooting

### iOS Build Issues
- Ensure frameworks are properly linked in Xcode
- Verify `use_frameworks!` is in your Podfile
- Check deployment target is set to iOS 12.0 or higher

### Android Build Issues
- Verify all Maven repositories are accessible
- Check Java compatibility settings
- Ensure minSdkVersion is 24 or higher

### Camera Detection Issues
- Verify camera permissions are granted
- Check Info.plist has correct permission descriptions
- For 3D mode, ensure device is iPhone X or newer

## Example Project

For a complete working example, see the `example/` folder in this repository.

```bash
cd example
npm install
# iOS
cd ios && pod install && cd ..
npx react-native run-ios
# Android
npx react-native run-android
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
