import React from 'react';
import { StyleSheet, Text } from 'react-native';
import TestRenderer, { act } from 'react-test-renderer';
import App from '../App';
import { createMockRepositories } from '../src/data';
import {
  authRoutes,
  groupTabRoutes,
  mainRoutes,
  routes,
  runTabRoutes,
  isSessionAction,
  type RouteName,
} from '../src/navigation/routes';
import { darkTheme, lightTheme } from '../src/theme';

jest.mock(
  'react-native-safe-area-context',
  () => require('react-native-safe-area-context/jest/mock').default,
);
// The first React Native render loads lazy host components on this Windows runner.
jest.setTimeout(20000);

const repositories = createMockRepositories({ latencyMs: 0 });

function texts(screen: TestRenderer.ReactTestRenderer) {
  return screen.root
    .findAllByType(Text)
    .flatMap(node => [node.props.children].flat())
    .filter(child => typeof child === 'string' || typeof child === 'number')
    .join(' ');
}

function pressable(screen: TestRenderer.ReactTestRenderer, label: string) {
  const matches = screen.root.findAll(
    node =>
      node.props.accessibilityLabel === label &&
      typeof node.props.onPress === 'function',
  );
  if (matches.length === 0) {
    throw new Error(`No pressable labelled ${label}`);
  }
  // Stacks keep earlier screens mounted, so the newest match belongs to the top screen.
  return matches[matches.length - 1];
}

async function press(screen: TestRenderer.ReactTestRenderer, label: string) {
  await act(async () => {
    pressable(screen, label).props.onPress();
  });
}

async function render(props: React.ComponentProps<typeof App> = {}) {
  let screen: TestRenderer.ReactTestRenderer;
  await act(async () => {
    screen = TestRenderer.create(
      <App repositories={repositories} {...props} />,
    );
  });
  return screen!;
}

test('every prototype link points at a registered screen', () => {
  const registered = new Set<RouteName>([
    ...authRoutes,
    ...mainRoutes,
    ...runTabRoutes,
    ...groupTabRoutes,
    'Home',
    'Community',
  ]);
  expect(new Set(Object.keys(routes))).toEqual(registered);
  for (const route of Object.values(routes)) {
    for (const link of route.links) {
      expect(isSessionAction(link) || registered.has(link)).toBe(true);
    }
  }
});

test('signed-out users move from start through login into the home tab', async () => {
  const screen = await render();
  expect(texts(screen)).toContain('1.1');
  expect(
    screen.root.findAll(node => node.props.accessibilityRole === 'tablist'),
  ).toHaveLength(0);
  await press(screen, '1.2 로그인');
  expect(texts(screen)).toContain('비밀번호 찾기');
  await press(screen, '로그인 완료 → 2.1 홈');
  const home = texts(screen);
  expect(home).toContain('2.1');
  expect(home).toContain('민준');
  expect(home).toContain('오늘 달리기 좋은 날이에요');
  expect(home).toContain('82');
  for (const tab of ['홈', '러닝', '그룹', '커뮤니티']) {
    expect(pressable(screen, tab).props.accessibilityRole).toBe('tab');
  }
  expect(() => pressable(screen, '뒤로')).toThrow();
  await act(async () => screen.unmount());
});

test('sign-up flow reaches home through consent, profiles and watch choice', async () => {
  const screen = await render();
  for (const step of [
    '1.3 회원가입',
    '1.4 개인정보·데이터 이용 동의',
    '1.5 기본 프로필',
    '1.6 러닝 프로필',
    '1.6w 워치 사용 여부',
    '1.7 워치 연결',
  ]) {
    await press(screen, step);
    expect(texts(screen)).toContain(step.split(' ')[0]);
  }
  await press(screen, '로그인 완료 → 2.1 홈');
  const home = texts(screen);
  expect(home).toContain('오늘 달리기 좋은 날이에요');
  expect(home).not.toContain('S15P31E105-145');
  await act(async () => screen.unmount());
});

test('watch connection opened from settings returns home instead of signing in', async () => {
  const screen = await render({ initialSignedIn: true });
  await press(screen, '8.1 설정');
  await press(screen, '1.7 워치 연결');
  expect(texts(screen)).not.toContain('로그인 완료');
  await press(screen, '2.1 홈');
  expect(texts(screen)).toContain('오늘 달리기 좋은 날이에요');
  await act(async () => screen.unmount());
});

test('tabs and their inner screens follow the prototype flow', async () => {
  const screen = await render({ initialSignedIn: true });
  await press(screen, '러닝');
  expect(texts(screen)).toContain('러닝 방식 선택');
  await press(screen, '2.0F 자유 러닝');
  expect(texts(screen)).toContain('2.0F');
  await press(screen, '4.2 러닝 진행');
  await press(screen, '4.3 일시정지·종료');
  await press(screen, '4.5 러닝 결과');
  expect(texts(screen)).toContain('S15P31E105-148');
  await press(screen, '2.1 홈');
  await press(screen, '그룹');
  expect(texts(screen)).toContain('그룹 · 내 크루');
  await press(screen, '6.1 크루 모집');
  expect(texts(screen)).toContain('크루 모집');
  await press(screen, '커뮤니티');
  await press(screen, '7.2 게시물 상세');
  expect(texts(screen)).toContain('S15P31E105-152');
  await act(async () => screen.unmount());
});

test('settings switches light and dark themes and signs out', async () => {
  const screen = await render({ initialSignedIn: true, initialTheme: 'dark' });
  const backgrounds = () =>
    screen.root
      .findAll(node => node.props.edges !== undefined)
      .map(node => StyleSheet.flatten(node.props.style)?.backgroundColor);
  expect(backgrounds()).toContain(darkTheme.colors.background);
  await press(screen, '8.1 설정');
  await press(screen, '라이트');
  expect(backgrounds()).toContain(lightTheme.colors.background);
  expect(backgrounds()).not.toContain(darkTheme.colors.background);
  await press(screen, '다크');
  expect(backgrounds()).not.toContain(lightTheme.colors.background);
  await press(screen, '로그아웃 → 1.1 시작');
  expect(texts(screen)).toContain('1.1');
  await act(async () => screen.unmount());
});

test('developer menu opens the component gallery with sheet and toast', async () => {
  const screen = await render({ initialSignedIn: true });
  await press(screen, '8.1 설정');
  await press(screen, '공통 컴포넌트 미리보기');
  const gallery = texts(screen);
  for (const text of [
    '러닝 시작',
    '사용할 수 있는 아이디예요',
    '받은 알림이 없어요',
  ]) {
    expect(gallery).toContain(text);
  }
  await press(screen, '바텀시트 열기');
  expect(texts(screen)).toContain('정원이 가득 찼어요');
  await press(screen, '토스트 띄우기');
  expect(texts(screen)).toContain('워치 연결을 해제했어요');
  await act(async () => screen.unmount());
});

test('mock repositories cover new-user and error scenarios', async () => {
  const newUser = createMockRepositories({ scenario: 'newUser', latencyMs: 0 });
  await expect(newUser.home.getTodayCondition()).resolves.toMatchObject({
    readinessState: 'collecting',
    readinessScore: null,
  });
  const failing = createMockRepositories({ scenario: 'error', latencyMs: 0 });
  await expect(failing.profile.getMe()).rejects.toThrow('목 데이터 오류');
});
