import type { TodayCondition, UserProfile, WatchConnection } from '../types';

// Mock sign-in for 1.2 로그인. The prototype shows `minjun_run`, but the API allows only letters and digits.
export const account = {
  loginId: 'minjun01',
  password: 'runway123',
  phoneNumber: '01024835917',
};

// Login IDs already taken, for 1.3's duplicate check.
export const takenLoginIds = [account.loginId, 'runner01'];

// Every mock SMS sends this code (1.2q 482913).
export const verificationCode = '482913';
export const verificationExpiresInSec = 180;

// Matches the policy shown on 1.2 and 1.2s.
export const maxAttempts = 5;
export const loginLockMs = 10 * 60 * 1000;

// 1.7 워치 연결 — 연결됨.
export const connectedWatch: WatchConnection = {
  status: 'connected',
  batteryPercent: 82,
  permissions: {
    heartRate: 'connected',
    location: 'connected',
    sleep: 'connected',
    activity: 'connected',
  },
};

// 1.8 워치 연결 문제: location comes from the phone GPS, so it stays connected.
export const disconnectedWatch: WatchConnection = {
  status: 'disconnected',
  batteryPercent: null,
  permissions: {
    heartRate: 'denied',
    location: 'connected',
    sleep: 'disconnected',
    activity: 'disconnected',
  },
};

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
