import React, { useEffect, useState, useRef } from 'react';

import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  Platform,
  PixelRatio,
  UIManager,
  findNodeHandle,
} from 'react-native';


import {
  LivenessView,
  registerFace,
  setConfigSDK,
  getDeviceId,
} from 'liveness-rn';

import imageData from './Imagetest'

const createFragment = viewId =>
  UIManager.dispatchViewManagerCommand(
    viewId,
    // we are calling the 'create' command
    UIManager?.LivenessViewManager?.Commands?.create.toString(),
    [viewId],
  );

const appId = ""
const baseUrl = ""
const privateKey = ""
const publicKey = ""

export default function App() {
  const [status, setStatus] = useState(false);
  const [clientTransactionId, setClientTransactionId] = useState('');
  const [layout, setLayout] = useState({ width: 0, height: 0 });
  const ref = useRef(null);

  useEffect(() => {
    if (Platform.OS != 'ios') {
      const viewId = findNodeHandle(ref?.current);
      if (viewId) {
        createFragment(viewId);
      }
    }
  }, [ref.current, status]);

  useEffect(() => {
    setConfigSDK(appId, clientTransactionId, baseUrl, publicKey, privateKey)
  }, [clientTransactionId]);

  const onStartLiveNess = () => {
    setStatus(!status);
  };

  const onRegisterFace = () => {
    registerFace(imageData, data => {
      console.log('onRegisterFace', data);
      if (data?.status == '200') {
        setClientTransactionId(data?.data)
      } else {
        // log error
      }
    });
  };

  const onGetDeviceId = () => {
    getDeviceId(data => {
      console.log('getDeviceId', data);
    })
  }

  const handleLayout = e => {
    const { height, width } = e.nativeEvent.layout;
    if (
      layout.width === width &&
      layout.height === height
    ) {
      return;
    }
    setLayout({width, height})
  }

  return (
    <View style={styles.container}>
        {status && (
        <View style={styles.view_camera} onLayout={handleLayout}>
          <LivenessView
            ref={ref}
            style={
              Platform.OS === 'ios' ? styles.view_liveness :
              {
                // converts dpi to px, provide desired height
                height: PixelRatio.getPixelSizeForLayoutSize(layout.height),
                // converts dpi to px, provide desired width
                width: PixelRatio.getPixelSizeForLayoutSize(layout.width),
              }
            }
            onEvent={(data) => {
              console.log('===sendEvent===', data.nativeEvent?.data);
            }}
            requestid={clientTransactionId}
            appId={appId}
            baseUrl={baseUrl}
            privateKey={privateKey}
            publicKey={publicKey}
            debugging={true}
          />
        </View>
      )}
      <TouchableOpacity onPress={onGetDeviceId} style={styles.btn_liveness}>
        <Text>Get DeviceId</Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={onRegisterFace} style={styles.btn_liveness}>
        <Text>Start register face</Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={onStartLiveNess} style={styles.btn_liveness}>
        <Text>Start LiveNess</Text>
      </TouchableOpacity>
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
    width: '100%',
    height: 400,
    backgroundColor: 'red',
    marginBottom: 24,
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
});
