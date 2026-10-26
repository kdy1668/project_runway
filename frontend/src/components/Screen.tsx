import React from 'react';
import {
  ScrollView,
  StatusBar,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { size, spacing, useTheme } from '../theme';

export function Screen({
  children,
  header,
  scroll = true,
  withTabBar = false,
  contentStyle,
}: {
  children: React.ReactNode;
  header?: React.ReactNode;
  scroll?: boolean;
  withTabBar?: boolean;
  contentStyle?: StyleProp<ViewStyle>;
}) {
  const { colors } = useTheme();
  // Tab screens leave room so the floating tab bar never covers the last item.
  const bottomRoom = withTabBar
    ? size.tabBar + size.tabBarInset * 2
    : spacing.xxxl;
  const content = [styles.content, { paddingBottom: bottomRoom }, contentStyle];
  return (
    <SafeAreaView
      edges={withTabBar ? ['top'] : ['top', 'bottom']}
      style={[styles.root, { backgroundColor: colors.background }]}
    >
      <StatusBar barStyle={colors.statusBar} />
      {header}
      {scroll ? (
        <ScrollView contentContainerStyle={content}>{children}</ScrollView>
      ) : (
        <View style={[styles.fill, content]}>{children}</View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  fill: { flex: 1 },
  content: {
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.md,
    gap: spacing.xl,
  },
});
