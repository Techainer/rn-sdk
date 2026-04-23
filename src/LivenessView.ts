import { Platform, requireNativeComponent, type ViewProps } from 'react-native';

export interface MaskStyleOptions {
  maskBackgroundColorHex: string;
  ovalStrokeColorHex: string;
  textBackgroundColorHex: string;
  textColorHex: string;
  instructionMessageMap?: Record<number, string>;
}

export interface LivenessViewProps extends ViewProps {
  onEvent?: (...args: any[]) => void;
  isFlashCamera?: boolean;
  isDebug?: boolean;
  maskStyle?: MaskStyleOptions;
}

const LivenessView =
  Platform.OS === 'ios'
    ? requireNativeComponent<LivenessViewProps>('RCTLivenessView')
    : requireNativeComponent<LivenessViewProps>('LivenessViewManager');
export default LivenessView;
