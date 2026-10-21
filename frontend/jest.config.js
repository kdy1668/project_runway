process.env.TZ = 'Asia/Seoul';
module.exports = {
  preset: '@react-native/jest-preset',
  cacheDirectory: '<rootDir>/.cache/jest',
  transformIgnorePatterns: [
    'node_modules/(?!(\\.pnpm|react-native|@react-native|@react-native-community|react-native-safe-area-context)/)',
  ],
};
