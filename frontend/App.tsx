import React from 'react';
import { StatusBar, StyleSheet } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { HealthScreen } from './src/screens/HealthScreen';
import { provider } from './src/health/healthProvider';
export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={styles.root}>
        <HealthScreen provider={provider} />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#0B0C10' },
});
