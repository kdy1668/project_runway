import type { TodayCondition, UserProfile } from '../types';

// Sample values shown in prototype v15 2.1 홈.
export const me: UserProfile = {
  id: 'user-minjun',
  nickname: '민준',
  runningLevel: 'intermediate',
};

export const todayCondition: TodayCondition = {
  date: '2026-10-19',
  syncedAt: '2026-10-19T06:42:00+09:00',
  readinessState: 'ready',
  readinessScore: 82,
  condition: '보통',
  sleepMinutes: 432,
  restingHeartRate: 58,
};

// 2.P′ 신규 사용자: no score until enough health data is collected.
export const collectingCondition: TodayCondition = {
  ...todayCondition,
  syncedAt: null,
  readinessState: 'collecting',
  readinessScore: null,
  condition: null,
};
