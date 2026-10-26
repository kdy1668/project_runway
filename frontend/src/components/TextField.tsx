import React, { useState } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';
import { radius, size, spacing, typography, useTheme } from '../theme';
import { AppText } from './AppText';

export type FieldStatus = 'default' | 'success' | 'error';

export function TextField({
  label,
  helper,
  status = 'default',
  style,
  onFocus,
  onBlur,
  ...props
}: TextInputProps & {
  label?: string;
  helper?: string;
  status?: FieldStatus;
}) {
  const { colors } = useTheme();
  const [focused, setFocused] = useState(false);
  // 1.2: a focused field gets a mint border; 1.2s: a wrong code turns the border coral.
  const borderColor =
    status === 'error'
      ? colors.danger
      : focused || status === 'success'
      ? colors.accent
      : colors.inputBorder;
  const helperTone =
    status === 'error'
      ? 'danger'
      : status === 'success'
      ? 'accentText'
      : 'textTertiary';
  return (
    <View style={styles.wrapper}>
      {label ? (
        <AppText variant="captionStrong" tone="textSecondary">
          {label}
        </AppText>
      ) : null}
      <TextInput
        accessibilityLabel={props.accessibilityLabel ?? label}
        placeholderTextColor={colors.textTertiary}
        selectionColor={colors.accent}
        {...props}
        onFocus={event => {
          setFocused(true);
          onFocus?.(event);
        }}
        onBlur={event => {
          setFocused(false);
          onBlur?.(event);
        }}
        style={[
          styles.input,
          typography.input,
          {
            color: colors.text,
            backgroundColor: colors.inputBackground,
            borderColor,
          },
          style,
        ]}
      />
      {helper ? (
        <AppText variant="caption" tone={helperTone} style={styles.helper}>
          {status === 'success' ? `✓ ${helper}` : helper}
        </AppText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { gap: spacing.sm },
  input: {
    height: size.input,
    borderRadius: radius.pill,
    borderWidth: 1,
    paddingHorizontal: 20,
  },
  helper: { paddingHorizontal: spacing.md },
});
