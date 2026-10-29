import React from 'react';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import { k1Gradient, useTheme } from '../theme';

// The K1 screen background (DESIGN.md 1-1): light blue-grey at the top fading to black at the bottom.
// The dark tone (maps, dark parts) draws nothing, so the plain dark background underneath shows.
export function Backdrop() {
  const { name } = useTheme();
  if (name === 'dark') {
    return null;
  }
  return (
    <Svg width="100%" height="100%">
      <Defs>
        <LinearGradient id="k1" x1="0" y1="0" x2="0" y2="1">
          {k1Gradient.colors.map((color, index) => (
            <Stop
              key={index}
              offset={k1Gradient.locations[index]}
              stopColor={color}
            />
          ))}
        </LinearGradient>
      </Defs>
      <Rect width="100%" height="100%" fill="url(#k1)" />
    </Svg>
  );
}
