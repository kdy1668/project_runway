import React from 'react';
import Svg, { Path } from 'react-native-svg';
import { useTheme } from '../theme';
import { logoPath, logoViewBox } from './logoPath';

// The RUNWAY wordmark in the text color: white on dark screens, ink on light ones.
export function Logo({ width }: { width: number }) {
  const { colors } = useTheme();
  const { width: w, height: h } = logoViewBox;
  return (
    <Svg
      width={width}
      height={(width * h) / w}
      viewBox={`0 0 ${w} ${h}`}
      accessibilityRole="image"
      accessibilityLabel="RUNWAY"
    >
      <Path d={logoPath} fill={colors.text} fillRule="evenodd" />
    </Svg>
  );
}
