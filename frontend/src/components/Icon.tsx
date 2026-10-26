import React from 'react';
import Svg, { Circle, Path, Polygon } from 'react-native-svg';

// Outline icons used by the prototype (Lucide, ISC license).
const icons = {
  home: (
    <>
      <Path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8" />
      <Path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
    </>
  ),
  run: (
    <>
      <Path d="M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z" />
      <Path d="M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z" />
      <Path d="M16 17h4" />
      <Path d="M4 13h4" />
    </>
  ),
  group: (
    <>
      <Circle cx="8" cy="4.5" r="2" />
      <Path d="M6.5 21l2-6-2.5-2 1.5-4.5L10 10l2 1" />
      <Path d="M8.5 15l2.5 2v4" />
      <Circle cx="17" cy="5.5" r="1.8" />
      <Path d="M15.5 21l1.6-5-2-1.6 1.2-4 2 1.6 1.7.9" />
      <Path d="M17.1 16l2 1.7V21" />
    </>
  ),
  community: <Path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z" />,
  bell: (
    <>
      <Path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" />
      <Path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" />
    </>
  ),
  settings: (
    <>
      <Path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
      <Circle cx="12" cy="12" r="3" />
    </>
  ),
  back: <Path d="m15 18-6-6 6-6" />,
  forward: <Path d="m9 18 6-6-6-6" />,
  close: (
    <>
      <Path d="M18 6 6 18" />
      <Path d="m6 6 12 12" />
    </>
  ),
  check: <Path d="M20 6 9 17l-5-5" />,
  alert: (
    <>
      <Circle cx="12" cy="12" r="10" />
      <Path d="M12 8v4" />
      <Path d="M12 16h.01" />
    </>
  ),
  bookmark: <Path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />,
  plus: (
    <>
      <Path d="M5 12h14" />
      <Path d="M12 5v14" />
    </>
  ),
  more: (
    <>
      <Circle cx="12" cy="12" r="1" />
      <Circle cx="19" cy="12" r="1" />
      <Circle cx="5" cy="12" r="1" />
    </>
  ),
  play: <Polygon points="6 4 20 12 6 20 6 4" />,
  inbox: (
    <>
      <Path d="M22 12h-6l-2 3h-4l-2-3H2" />
      <Path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" />
    </>
  ),
} as const;

export type IconName = keyof typeof icons;

const filled: ReadonlySet<IconName> = new Set<IconName>(['play']);

export function Icon({
  name,
  color,
  size = 22,
  strokeWidth = 1.8,
}: {
  name: IconName;
  color: string;
  size?: number;
  strokeWidth?: number;
}) {
  const fill = filled.has(name);
  return (
    <Svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={fill ? color : 'none'}
      stroke={fill ? 'none' : color}
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {icons[name]}
    </Svg>
  );
}
