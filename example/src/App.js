// import { createStackNavigator } from '@react-navigation/stack';
// import { NavigationContainer } from '@react-navigation/native';
// import HomeScreen from './HomeScreen';
// import Liveness from './Liveness';

// const Stack = createStackNavigator();

// export default function App() {
//   return (
//     <NavigationContainer>
//       <Stack.Navigator initialRouteName="Home">
//         <Stack.Screen name="Home" component={HomeScreen} />
//         <Stack.Screen name="Liveness" component={Liveness} />
//       </Stack.Navigator>
//     </NavigationContainer>
//   );
// }


// "@react-navigation/native": "^7.0.0",
// "@react-navigation/stack": "^7.0.0",
// "react-native-gesture-handler": "^2.20.2",
// "react-native-safe-area-context": "^4.14.0",
// "react-native-screens": "^4.0.0",
// "react-native-skia": "^0.0.1"



import React, { useEffect, useState, useRef } from 'react';

import {
  Dimensions,
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  Platform,
  PixelRatio,
  UIManager,
  findNodeHandle,
  TextInput,
  AppState,
} from 'react-native';

import DeviceInfo from 'react-native-device-info';
const { width: windowWidth } = Dimensions.get("window");

import SimpleModal from './SimpleModal';

import RNFS from "react-native-fs";
import { Buffer } from 'buffer';


import {
  LivenessView,
} from 'liveness-rn';

const createFragment = viewId =>
  UIManager.dispatchViewManagerCommand(
    viewId,
    // we are calling the 'create' command
    UIManager?.LivenessViewManager?.Commands?.create.toString(),
    [viewId],
  );
const privateKey = `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCiOMdedNfAhAdI
M1YmUd2hheu2vDMmFHjCfWHon8wv0doubYPY6/uhMcUERpPiFddWqe+Dfr/XwCsa
EaPOa27ghyUQ8HjdzAxcZ1yTWrgWttGruHlrHoXDPaov3QqvJTUrBclsH8p3ufPp
gmBC0HrFD0Pl4+vEpki4VvCDJFEGuBaSAqFe7JqUuaOVRG9mBBZWslkNi8XNkAQT
/Es+zReMf4EXIO2+wMo3aPIhe+sSZ3e3VqFL/10EJqNhurOT5ijUwReMlNb9wcxu
drfSKjLOgW1n+ZLjo16GdS2ye68B7ZaA0J3DPuDdRXJ5YuoW4UQd8o6CyezIHWpP
vH1tWFABAgMBAAECggEAB485yy8Kts/wPu8Vfqel+lbxSwyuHYIqtnV9UIfRzhCr
aCp2UG9+xF47Xh2j2o9F/6XfoXMQoY808vwLdB0Rh6kEkyuBlmRh1xSB/ePmXDic
wLHSBqnfdd+zxJM6YjsLpTuZzU4V80pZEXKf5b0tW22Arn/Whs1w6hYzEwloNTXf
4K974i+st1E5/0JjufTBTOTlBtwbphwN9ia/Xs2EY3D6kuJhYZ5lCWDocD21xYWd
NPM2CWqVXjJYEaqDTIWGwNGb2hkwNG5t/9MnN2On6BR7kgOWU4XxXHoLD3XoErwB
M3J8QAXGZwb+wRtkzRCVgojA6AQXfu9/QyPjyHW4oQKBgQDYMEC+LuNtjrNju8yF
LHMFbYbSfBQITE+kJn7iemezkwJw25NuKWl0pcxPe+NtpaHNFDmHnTVrlICTh90c
qrtge1vsqtgEoaZfdYqkUVvl1jJWBJ+VqQNO2Nxos/6fM0ARDC/9YXHoDWKC4WeS
PvYJ55MkMHseddpKIUGrZ1xO5QKBgQDAGGFxC9xWhG/CEm/JAFul+uyp9ncG6ro/
47Tw75M5+2K9wsP2R2c0uoXZtQHFvvi9CADaQkSYrzY3wCqgjDhsR+3psN1R+Pkw
bgMf3Rt6bMrYemPaGOe9qZ+Dpw/2GnLZfmCcJfKoRfY73YsxlL4/0Zf1va/qZnbp
pGh4IlvO7QKBgD87teQq0Mi9wYi9aG/XdXkz9Qhh1HYs4+qOe/SAew6SRFeAUhoZ
sMe2qxDgmr/6f139uWoKOJLT59u/FJSK962bx2JtAiwwn/ox5jBzv551TVnNlmPv
AJGyap2RcDtegTG7T9ocA3YtXBAOH/4tvkddXbNrHsflDsk5+vxIij5lAoGAFli/
vS7sCwSNG76ZUoDAKKbwMTWC00MrN5N90SmNrwkXi4vE0DmuP+wS9iigdCirNxJf
RwS+hiSb4hBw5Qxq4+3aN31jwc18761cn7BRKgTN9DEIvK55Bw9chyxAJxkck0Co
bIHdoMXCx2QWdUYge7weOXA/rr0MyFFf9dnJZGECgYEAuhJrRoxLdyouTd6X9+R1
8FWY0XGfsBp+PkN/nnPuK6IJR/IeI+cdiorfm45l4ByF0XEBCDz2xXQ6MVBNz3zF
MjEQ61dTFRfiTW2ZDqhMTtZH4R4T5NLWf+3ItjkAkOdStszplhHy0bUQIYgptYXd
5Sw/UvMv83CmlztVC5tGG9o=
-----END PRIVATE KEY-----
`

const publicKey = `
-----BEGIN CERTIFICATE-----
MIIE8jCCA9qgAwIBAgIQVAESDxKv/JtHV15tvtt1UjANBgkqhkiG9w0BAQsFADAr
MQ0wCwYDVQQDDARJLUNBMQ0wCwYDVQQKDARJLUNBMQswCQYDVQQGEwJWTjAeFw0y
MzA2MDcwNjU1MDNaFw0yNjA2MDkwNjU1MDNaMIHlMQswCQYDVQQGEwJWTjESMBAG
A1UECAwJSMOgIE7hu5lpMRowGAYDVQQHDBFRdeG6rW4gSG/DoG5nIE1haTFCMEAG
A1UECgw5Q8OUTkcgVFkgQ1AgROG7ikNIIFbhu6QgVsOAIEPDlE5HIE5HSOG7hiBT
4buQIFFVQU5HIFRSVU5HMUIwQAYDVQQDDDlDw5RORyBUWSBDUCBE4buKQ0ggVuG7
pCBWw4AgQ8OUTkcgTkdI4buGIFPhu5AgUVVBTkcgVFJVTkcxHjAcBgoJkiaJk/Is
ZAEBDA5NU1Q6MDExMDE4ODA2NTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBAJO6JDU+kNEUIiO6m75LOfgHkwGExYFv0tILHInS9CkK2k0FjmvU8VYJ0cQA
sGGabpHIwfh07llLfK3TUZlhnlFZYRrYvuexlLWQydjHYPqT+1c3iYaiXXcOqEjm
OupCj71m93ThFrYzzI2Zx07jccRptAAZrWMjI+30vJN7SDxhYsD1uQxYhUkx7psq
MqD4/nOyaWzZHLU94kTAw5lhAlVOMu3/6pXhIltX/097Wji1eyYqHFu8w7q3B5yW
gJYugEZfplaeLLtcTxok4VbQCb3cXTOSFiQYJ3nShlBd89AHxaVE+eqJaMuGj9z9
rdIoGr9LHU/P6KF+/SLwxpsYgnkCAwEAAaOCAVUwggFRMAwGA1UdEwEB/wQCMAAw
HwYDVR0jBBgwFoAUyCcJbMLE30fqGfJ3KXtnXEOxKSswgZUGCCsGAQUFBwEBBIGI
MIGFMDIGCCsGAQUFBzAChiZodHRwczovL3Jvb3RjYS5nb3Yudm4vY3J0L3ZucmNh
MjU2LnA3YjAuBggrBgEFBQcwAoYiaHR0cHM6Ly9yb290Y2EuZ292LnZuL2NydC9J
LUNBLnA3YjAfBggrBgEFBQcwAYYTaHR0cDovL29jc3AuaS1jYS52bjA0BgNVHSUE
LTArBggrBgEFBQcDAgYIKwYBBQUHAwQGCisGAQQBgjcKAwwGCSqGSIb3LwEBBTAj
BgNVHR8EHDAaMBigFqAUhhJodHRwOi8vY3JsLmktY2Eudm4wHQYDVR0OBBYEFE6G
FFM4HXne9mnFBZInWzSBkYNLMA4GA1UdDwEB/wQEAwIE8DANBgkqhkiG9w0BAQsF
AAOCAQEAH5ifoJzc8eZegzMPlXswoECq6PF3kLp70E7SlxaO6RJSP5Y324ftXnSW
0RlfeSr/A20Y79WDbA7Y3AslehM4kbMr77wd3zIij5VQ1sdCbOvcZXyeO0TJsqmQ
b46tVnayvpJYW1wbui6smCrTlNZu+c1lLQnVsSrAER76krZXaOZhiHD45csmN4dk
Y0T848QTx6QN0rubEW36Mk6/npaGU6qw6yF7UMvQO7mPeqdufVX9duUJav+WBJ/I
Y/EdqKp20cAT9vgNap7Bfgv5XN9PrE+Yt0C1BkxXnfJHA7L9hcoYrknsae/Fa2IP
99RyIXaHLJyzSTKLRUhEVqrycM0UXg==
-----END CERTIFICATE-----
`


// Function to calculate the size of a Base64 string in MB
function getBase64SizeInMB(base64String) {
  // Ensure the input is not empty or invalid
  if (!base64String || typeof base64String !== 'string') {
    console.error("Invalid Base64 string");
    return 0;
  }

  try {
    // Convert the Base64 string to a buffer (binary data)
    const buffer = Buffer.from(base64String, 'base64');

    // Get the size in bytes
    const sizeInBytes = buffer.length;

    // Convert bytes to MB (1 MB = 1024 * 1024 bytes)
    const sizeInMB = sizeInBytes / (1024 * 1024);

    // Return the size in MB with 2 decimal places
    return sizeInMB.toFixed(2);  // Rounds the result to 2 decimal places
  } catch (error) {
    console.error("Error decoding Base64 string:", error);
    return 0;
  }
}

const saveBase64ToFile = async (base64Data, fileName) => {
  try {
    const path = `${RNFS.ExternalDirectoryPath}/${fileName}`;
    await RNFS.writeFile(path, base64Data, 'utf8');
    console.log(`File saved at: ${path}`);
    return path;
  } catch (error) {
    console.error('Error saving file:', error);
    return null;
  }
};


const loginFaceId = ({ filePath, livenessPath, livenessThermalPath, color, userId }) => {
  // console.log(filePath)
  const data = new FormData();
  data.append("image", filePath);
  // data.append("image", {
  //   uri: `file://${filePath}`,
  //   type: "image/png",
  //   name: "image.png",
  // });
  // data.append("sdk_thermal_image", livenessThermalPath ? {
  //   uri: `file://${livenessThermalPath}`,
  //   type: "image/png",
  //   name: "image.png",
  // } : "");
  if (livenessThermalPath) {
    data.append("sdk_thermal_image", livenessThermalPath ?? "");
  }
  // data.append("sdk_liveness_image", livenessPath ? {
  //   uri: `file://${livenessPath}`,
  //   type: "image/png",
  //   name: "image.png",
  // } : "");
  if (livenessPath) {
    data.append("sdk_liveness_image", livenessPath);
  }
  // data.append("user_id", "thuthuy");
  data.append("user_id", userId);
  if (color) {
    data.append("sdk_color", color);
  }
  // data.append("user_id", '68');
  data.append("threshold", 0.8);
  data.append("check_liveness", "True");
  data.append("source", "test_search");
  const url = "https://ekyc-pvcombank-dev.tunnel.techainer.com/api/v1/verify/verify_user_face_liveness_match/";
  return new Promise(async function (resolve, reject) {
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "multipart/form-data",
        Authorization: "Token 92fdcde95745b7efeee9345dcff9a02ee5a549fc",
        Accept: "application/json",
      },
      body: data,
    })
      .then((response) => response.json())
      .then((res) => {
        resolve(res);
      })
      .catch((error) => {
        reject(error);
      });
  });
};

const isIphoneXOrLater = (model) => {
  const iPhoneXModels = [
    'iPhone X',
    'iPhone XS',
    'iPhone XS Max',
    'iPhone XR',
    'iPhone 11',
    'iPhone 11 Pro',
    'iPhone 11 Pro Max',
    'iPhone 12',
    'iPhone 12 Mini',
    'iPhone 12 Pro',
    'iPhone 12 Pro Max',
    'iPhone 13',
    'iPhone 13 Mini',
    'iPhone 13 Pro',
    'iPhone 13 Pro Max',
    'iPhone 14',
    'iPhone 14 Plus',
    'iPhone 14 Pro',
    'iPhone 14 Pro Max',
    'iPhone 15',
    'iPhone 15 Plus',
    'iPhone 15 Pro',
    'iPhone 15 Pro Max',
    'iPhone 16',
    'iPhone 16 Plus',
    'iPhone 16 Pro',
    'iPhone 16 Pro Max'
  ];

  return iPhoneXModels.includes(model);
};

var isIphoneX = false

const checkDevice = async () => {
  const model = DeviceInfo.getModel();
  isIphoneX = isIphoneXOrLater(model);
};

export default function App() {
  const [status, setStatus] = useState(false);
  const [isFlashCamera, setIsFlashCamera] = useState(false);
  const [layout, setLayout] = useState({ width: 0, height: 0 });
  const ref = useRef(null);

  const [loginError, setLoginError] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  const [appStateVisible, setAppStateVisible] = useState(AppState.currentState);
  const appState = useRef(AppState.currentState);
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (Platform.OS === 'ios') {
        // iOS handling
        if (appState.current === 'active' &&
          nextAppState.match(/inactive|background/)) {
          console.log('App has gone to background');
          setStatus(false);
          clear();
        }

        if (appState.current.match(/inactive|background/) &&
          nextAppState === 'active') {
          console.log('App has come to foreground');
        }
      }

      setAppStateVisible(nextAppState);
      appState.current = nextAppState;
    });

    return () => {
      subscription.remove();
    };
  }, [isActive]);

  useEffect(() => {
    if (Platform.OS !== 'ios' && status) {
      const viewId = findNodeHandle(ref?.current);
      if (viewId) {
        createFragment(viewId);
      }
    }
  }, [ref.current, status]);

  useEffect(() => {
    checkDevice();
  }, []);

  const [text, setText] = useState('');
  const timeoutRef = useRef(null);
  const innerTimeoutRef = useRef(null);

  const onStartLiveNess = () => {
    // Clear any existing timeouts
    setIsFlashCamera(null);
    clear();

    setStatus(prev => !prev);

    if (isIphoneX) {
      setIsFlashCamera(false);
      timeoutRef.current = setTimeout(() => {
        console.log('changed timeout');
        if (!isFlashCamera) {
          setIsFlashCamera(true);
          // setStatus(false);
          // innerTimeoutRef.current = setTimeout(() => {
          //   setStatus(true);
          // }, 2);
        }
      }, 5000);
    } else {
      setIsFlashCamera(true);
    }
  };

  // Cleanup timeouts when component unmounts
  useEffect(() => {
    return () => {
      clear();
    };
  }, []);

  function clear() {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
    if (innerTimeoutRef.current) {
      clearTimeout(innerTimeoutRef.current);
      innerTimeoutRef.current = null;
    }
  }

  const handleLayout = e => {
    const { height, width } = e.nativeEvent.layout;
    if (layout.width === width && layout.height === height) {
      return;
    }
    setLayout({ width, height });
  };

  const onCheckFaceId = async ({ filePath, fileLiveness, livenessThermalPath, color }) => {
    try {
      const res = await loginFaceId({
        filePath: filePath,
        livenessPath: fileLiveness,
        livenessThermalPath: livenessThermalPath,
        color: color,
        userId: text,
      });
      console.log(res);
      setErrorMessage(JSON.stringify(res));
      setLoginError(true);
    } catch (error) {
      console.log("🚀 ~ handleLoginFaceId ~ error:", error);
    }
  };

  return (
    <View style={styles.container}>
      {status && (
        <View style={[styles.view_camera, { width: isFlashCamera ? '100%' : '100%' }]} onLayout={handleLayout}>
          <LivenessView
            ref={ref}
            key={isFlashCamera == null ? 'null' : isFlashCamera == false ? 'flash' : 'normal'}
            style={
              Platform.OS === 'ios' ? styles.view_liveness :
                {
                  height: PixelRatio.getPixelSizeForLayoutSize(layout.height),
                  width: PixelRatio.getPixelSizeForLayoutSize(layout.width),
                }
            }
            onEvent={(data) => {
              console.log('===sendEvent===', data.nativeEvent?.data);
              if (data.nativeEvent?.data?.isFlash == null) {
                console.log("Original: ", getBase64SizeInMB(data.nativeEvent?.data?.livenessOriginalImage))
                console.log("liveness 2D: ", getBase64SizeInMB(data.nativeEvent?.data?.livenessColorImage))
                console.log("liveness 3D: ", getBase64SizeInMB(data.nativeEvent?.data?.livenessThermalImage))
                // onCheckFaceId(data.nativeEvent?.data?.livenessOriginalImage, data.nativeEvent?.data?.livenessImage, data.nativeEvent?.data?.color);
                clear();
                if (isFlashCamera) {
                  // console.log("liveness: ", getBase64SizeInMB(data.nativeEvent?.data?.livenessColorImage))
                  onCheckFaceId({ filePath: data.nativeEvent?.data?.livenessOriginalImage, fileLiveness: data.nativeEvent?.data?.livenessColorImage, color: data.nativeEvent?.data?.color });
                } else {
                  // console.log("liveness: ", getBase64SizeInMB(data.nativeEvent?.data?.livenessThermalImage))
                  onCheckFaceId({ filePath: data.nativeEvent?.data?.livenessOriginalImage, livenessThermalPath: data.nativeEvent?.data?.livenessThermalImage });
                }
              } else {
                if (data.nativeEvent?.data?.isFlash) {
                  // Clear hết timeout
                  // clear();
                  setIsFlashCamera(true);
                } else {
                  // Clear hết timeout
                  // clear();
                  setIsFlashCamera(false);
                }
              }
            }}
            requestid={'sdfsdfsdfsdf'}
            appId={'com.pvcb'}
            baseUrl={'https://ekyc-sandbox.eidas.vn/face-matching'}
            privateKey={privateKey}
            publicKey={publicKey}
            debugging={false}
            isFlashCamera={isFlashCamera}
          />
        </View>
      )}
      {!status && <TextInput
        style={styles.input}
        placeholder="User Id"
        value={text}
        onChangeText={(newText) => setText(newText)}
      />}
      {!status &&(<View style={{ position: 'absolute', width: '40%', zIndex: 1000, bottom: 20, left: (windowWidth / 3) }}>
        <TouchableOpacity onPress={onStartLiveNess} style={styles.btn_liveness}>
          <Text>Start LiveNess</Text>
        </TouchableOpacity>
      </View>)}
      {status &&(<View style={{ position: 'absolute', width: '40%', zIndex: 1000, top: 20, left: 30 }}>
        <TouchableOpacity onPress={onStartLiveNess}>
          <Text style={{ fontSize: 35, color: 'white'}}> ← </Text>
        </TouchableOpacity>
      </View>)}
      <SimpleModal
        isOpen={loginError}
        setIsOpen={setLoginError}
        onConfirm={() => {
          setLoginError(false);
          setStatus(false);
        }}
        errorMessage={errorMessage}
      />
    </View>
  );
}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  view_camera: {
    height: '100%',
    // height: Platform.OS == 'android' ? windowWidth * 1.7 : '100%',
    backgroundColor: 'transparent',
  },
  view_liveness: {
    flex: 1,
  },
  btn_liveness: {
    padding: 10,
    backgroundColor: '#c0c0c0',
    width: '90%',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 12,
    marginBottom: 24,
    zIndex: 1000,
  },
  btn_register_face: {
    padding: 10,
    backgroundColor: '#c0c0c0',
    width: '90%',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 12,
    marginBottom: 24,
  },
  input: {
    height: 40,
    borderColor: 'gray',
    borderWidth: 1,
    paddingHorizontal: 10,
    marginBottom: 20,
    color: 'black',
  },
});
