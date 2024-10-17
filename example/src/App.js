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
} from 'liveness-rn';

const createFragment = viewId =>
  UIManager.dispatchViewManagerCommand(
    viewId,
    // we are calling the 'create' command
    UIManager?.LivenessViewManager?.Commands?.create.toString(),
    [viewId],
  );
const privateKey = ""

const publicKey = ""

export default function App() {
  const [status, setStatus] = useState(false);
  const [layout, setLayout] = useState({ width: 0, height: 0 });
  const ref = useRef(null);

  useEffect(() => {
    if (Platform.OS != 'ios' && status) {
      const viewId = findNodeHandle(ref?.current);
      if (viewId) {
        createFragment(viewId);
      }
    }
  }, [ref.current, status]);

  const onStartLiveNess = () => {
    setStatus(!status);
  };

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
            requestid={''}
            appId={''}
            baseUrl={''}
            privateKey={privateKey}
            publicKey={publicKey}
            debugging={true}
          />
        </View>
      )}
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
    height: 700,
    backgroundColor: 'transparent',
    marginBottom: 24,
  },
  view_liveness: {
    flex: 1,
    height: 700,
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
