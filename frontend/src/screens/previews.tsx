import React, { useCallback } from 'react';
import { StyleSheet, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { AppText, Button, Card } from '../components';
import { appConfig } from '../config';
import { useResource, type Repositories } from '../data';
import { spacing, useThemeSettings, type ThemePreference } from '../theme';

const loadHome = (repositories: Repositories) =>
  Promise.all([
    repositories.profile.getMe(),
    repositories.home.getTodayCondition(),
  ]);

// Shows the mock data flow on 2.1 until S15P31E105-146 builds the real home.
export function HomePreview() {
  const resource = useResource(useCallback(loadHome, []));
  if (resource.status === 'loading') {
    return (
      <Card>
        <AppText tone="textSecondary">오늘 컨디션을 불러오는 중이에요</AppText>
      </Card>
    );
  }
  if (resource.status === 'error') {
    return (
      <Card>
        <AppText tone="danger">불러오지 못했어요</AppText>
        <Button
          title="다시 시도"
          variant="secondary"
          size="small"
          onPress={resource.reload}
        />
      </Card>
    );
  }
  const [me, today] = resource.data;
  return (
    <Card>
      <AppText variant="display">
        {me.nickname}님,{'\n'}오늘 달리기 좋은 날이에요
      </AppText>
      <AppText variant="caption" tone="textTertiary">
        오늘의 준비도
      </AppText>
      <View style={styles.score}>
        <AppText variant="metricHero">{today.readinessScore ?? '– –'}</AppText>
        <AppText variant="caption" tone="accentText">
          {today.condition ?? '데이터 모으는 중 · 점수 산출 전'}
        </AppText>
      </View>
    </Card>
  );
}

const preferences: { value: ThemePreference; label: string }[] = [
  { value: 'system', label: '기기 설정' },
  { value: 'dark', label: '다크' },
  { value: 'light', label: '라이트' },
];

export function SettingsPreview() {
  const navigation = useNavigation();
  const { preference, setPreference } = useThemeSettings();
  return (
    <>
      <Card>
        <AppText variant="bodyStrong">화면 모드</AppText>
        <View style={styles.row}>
          {preferences.map(option => (
            <Button
              key={option.value}
              title={option.label}
              size="small"
              variant={preference === option.value ? 'primary' : 'secondary'}
              onPress={() => setPreference(option.value)}
              style={styles.flex}
            />
          ))}
        </View>
      </Card>
      {appConfig.developerMenu ? (
        <Card>
          <AppText variant="bodyStrong">개발용</AppText>
          <Button
            title="공통 컴포넌트 미리보기"
            variant="secondary"
            size="medium"
            onPress={() => navigation.navigate('ComponentGallery')}
          />
          <Button
            title="건강 데이터 PoC"
            variant="secondary"
            size="medium"
            onPress={() => navigation.navigate('HealthPoc')}
          />
        </Card>
      ) : null}
    </>
  );
}

const styles = StyleSheet.create({
  score: { flexDirection: 'row', alignItems: 'flex-end', gap: spacing.xl },
  row: { flexDirection: 'row', gap: spacing.md },
  flex: { flex: 1 },
});
