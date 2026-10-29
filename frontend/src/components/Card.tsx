import React from 'react';
import {
  Pressable,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import Svg, {
  Defs,
  LinearGradient,
  RadialGradient,
  Rect,
  Stop,
} from 'react-native-svg';
import { k1, radius, spacing, ThemeProvider, useTheme } from '../theme';

// Kit boxes (DESIGN.md 2-7). glass: white see-through card, solid: plain card, muted: chip-colored box,
// outline: pinned card (6.0 곧 출발), deep: dark glass, vignette: dark center brightening to the edge.
export type CardVariant =
  | 'glass'
  | 'solid'
  | 'muted'
  | 'outline'
  | 'deep'
  | 'vignette';

type DarkVariant = Extract<CardVariant, 'deep' | 'vignette'>;

// The two dark boxes are drawn with SVG, since React Native views have no gradient fill.
function DarkFill({ variant }: { variant: DarkVariant }) {
  return (
    <Svg style={StyleSheet.absoluteFill}>
      <Defs>
        {variant === 'deep' ? (
          <LinearGradient id="fill" x1="0.4" y1="0" x2="0.6" y2="1">
            <Stop offset="0" stopColor={k1.mid} stopOpacity={0.66} />
            <Stop offset="1" stopColor={k1.night} stopOpacity={0.9} />
          </LinearGradient>
        ) : (
          <RadialGradient id="fill" cx="0.5" cy="0.55" r="0.62">
            <Stop offset="0.32" stopColor={k1.black} stopOpacity={0.96} />
            <Stop offset="0.58" stopColor={k1.night} stopOpacity={0.92} />
            <Stop offset="0.86" stopColor={k1.deep} stopOpacity={0.82} />
            <Stop offset="1" stopColor={k1.mid} stopOpacity={0.7} />
          </RadialGradient>
        )}
      </Defs>
      <Rect width="100%" height="100%" fill="url(#fill)" />
    </Svg>
  );
}

export function Card({
  children,
  variant = 'glass',
  onPress,
  accessibilityLabel,
  style,
}: {
  children: React.ReactNode;
  variant?: CardVariant;
  onPress?: () => void;
  accessibilityLabel?: string;
  style?: StyleProp<ViewStyle>;
}) {
  const { colors } = useTheme();
  const look = {
    glass: { backgroundColor: colors.surface, borderColor: 'transparent' },
    solid: { backgroundColor: colors.surfaceRaised, borderColor: 'transparent' },
    muted: { backgroundColor: colors.surfaceMuted, borderColor: 'transparent' },
    outline: { backgroundColor: colors.surface, borderColor: colors.accent },
    deep: { backgroundColor: 'transparent', borderColor: darkEdge },
    vignette: { backgroundColor: 'transparent', borderColor: darkEdge },
  }[variant];
  const dark = variant === 'deep' || variant === 'vignette';
  // Content in a dark box reads the dark tone, so its text and buttons turn light by themselves.
  const content = dark ? (
    <>
      <DarkFill variant={variant} />
      <ThemeProvider tone="dark">{children}</ThemeProvider>
    </>
  ) : (
    children
  );
  if (!onPress) {
    return (
      <View style={[styles.card, look, dark && styles.clip, style]}>
        {content}
      </View>
    );
  }
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onPress={onPress}
      style={({ pressed }) => [
        styles.card,
        look,
        dark && styles.clip,
        pressed && styles.pressed,
        style,
      ]}
    >
      {content}
    </Pressable>
  );
}

// A faint light edge keeps a dark box from melting into the black lower part.
const darkEdge = 'rgba(255,255,255,0.14)';

const styles = StyleSheet.create({
  card: {
    borderRadius: radius.card,
    borderWidth: 1,
    paddingHorizontal: 20,
    paddingVertical: 18,
    gap: spacing.xl,
  },
  // The gradient is a square layer; clipping keeps it inside the rounded corners.
  clip: { overflow: 'hidden' },
  // DESIGN.md 2-1: a pressed box shrinks to 96%.
  pressed: { transform: [{ scale: 0.96 }] },
});
