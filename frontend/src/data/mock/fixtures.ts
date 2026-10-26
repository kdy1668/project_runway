import { Image } from 'react-native';
import type {
  AppNotification,
  CoursePlan,
  CurrentPlace,
  HomeBackdrop,
  MonthlyRunSummary,
  MusicLibrary,
  MusicState,
  RunRecordSummary,
  SavedCourse,
  TodayCondition,
  UserProfile,
  WatchConnection,
} from '../types';

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

// The profile photo behind 2.1 홈, taken from the prototype. It is a third-party poster kept only as
// mock data; replace it before release.
const mockProfilePhoto = require('../../../assets/images/mock-profile.jpg');
// 2.1La's brighter background photo, also a third-party poster from the prototype.
const mockLightBackdrop = require('../../../assets/images/mock-backdrop-light.jpg');

const assetUri = (asset: number) =>
  Image.resolveAssetSource(asset)?.uri ?? null;

// Sample values shown in prototype v15 2.1 홈.
export const me: UserProfile = {
  id: 'user-minjun',
  nickname: '민준',
  runningLevel: 'intermediate',
  profileImageUrl: assetUri(mockProfilePhoto),
};

// 2.1 dark uses the profile photo; 2.1La uses the brighter photo.
export const homeBackdrop: HomeBackdrop = {
  dark: assetUri(mockProfilePhoto),
  light: assetUri(mockLightBackdrop),
};

export const todayCondition: TodayCondition = {
  date: '2026-10-19',
  syncedAt: '2026-10-19T06:42:00+09:00',
  readinessState: 'ready',
  readinessScore: 82,
  condition: '보통',
  sleepMinutes: 432,
  restingHeartRate: 58,
  readinessSummary: '양호 · 계획한 강도로 달려도 좋아요',
  sleepLabel: '충분',
  restingHeartRateLabel: '평소 수준',
  weeklyLoad: '적정',
  weeklyLoadLabel: '과부하 없음',
  aiAdvice: '오늘은 5km를 6′00″ 페이스로 시작해도 좋아요.',
  lastAssessedDate: '2026-10-19',
};

// 2.P′ 신규 사용자: no score until enough health data is collected.
export const collectingCondition: TodayCondition = {
  ...todayCondition,
  syncedAt: null,
  readinessState: 'collecting',
  readinessScore: null,
  condition: null,
  readinessSummary: null,
  sleepLabel: null,
  restingHeartRateLabel: null,
  weeklyLoad: null,
  weeklyLoadLabel: null,
  aiAdvice: null,
  lastAssessedDate: null,
};

// 2.1 러닝 분석, October.
export const monthlySummary: MonthlyRunSummary = {
  month: '2026-10',
  runCount: 7,
  totalDistanceM: 34200,
  averagePaceSecPerKm: 352,
  weekdayRatios: [0.38, 0.04, 0.62, 0.48, 0.04, 0.8, 0.54],
  paceImprovementSec: 8,
};

const shapes: Record<string, [number, number][]> = {
  coast: [
    [0.05, 0.6],
    [0.3, 0.45],
    [0.55, 0.5],
    [0.8, 0.35],
    [0.95, 0.4],
  ],
  loop: [
    [0.2, 0.8],
    [0.15, 0.3],
    [0.5, 0.15],
    [0.85, 0.35],
    [0.7, 0.8],
    [0.2, 0.8],
  ],
  hill: [
    [0.05, 0.75],
    [0.35, 0.7],
    [0.5, 0.3],
    [0.7, 0.45],
    [0.95, 0.25],
  ],
  line: [
    [0.05, 0.55],
    [0.95, 0.45],
  ],
};

// 2.1 과거 러닝 기록, newest first.
export const recentRecords: RunRecordSummary[] = [
  {
    id: 'run-1015',
    title: '민락수변공원 출발',
    startedAt: '2026-10-15T06:30:00+09:00',
    distanceM: 5020,
    durationSec: 1781,
    averagePaceSecPerKm: 355,
    shape: shapes.coast,
  },
  {
    id: 'run-1013',
    title: '민락수변 왕복',
    startedAt: '2026-10-13T06:40:00+09:00',
    distanceM: 5400,
    durationSec: 1930,
    averagePaceSecPerKm: 357,
    shape: shapes.line,
  },
  {
    id: 'run-1009',
    title: '남천 해변 언덕길',
    startedAt: '2026-10-09T07:00:00+09:00',
    distanceM: 5200,
    durationSec: 1985,
    averagePaceSecPerKm: 382,
    shape: shapes.hill,
  },
  {
    id: 'run-1005',
    title: '해운대 백사장',
    startedAt: '2026-10-05T06:50:00+09:00',
    distanceM: 4100,
    durationSec: 1470,
    averagePaceSecPerKm: 358,
    shape: shapes.line,
  },
  {
    id: 'run-0930',
    title: '수영강 하천길',
    startedAt: '2026-09-30T06:35:00+09:00',
    distanceM: 4800,
    durationSec: 1740,
    averagePaceSecPerKm: 362,
    shape: shapes.loop,
  },
];

// 2.1 저장한 코스: five saved, three shown.
export const savedCourses: SavedCourse[] = [
  {
    id: 'course-minrak',
    name: '민락수변공원 출발',
    distanceM: 5000,
    expectedMinutes: 30,
    shape: shapes.loop,
  },
  {
    id: 'course-minrak-round',
    name: '민락수변 왕복',
    distanceM: 5400,
    expectedMinutes: 33,
    shape: shapes.coast,
  },
  {
    id: 'course-suyeong',
    name: '수영강 하천길',
    distanceM: 4800,
    expectedMinutes: 29,
    shape: shapes.hill,
  },
  {
    id: 'course-namcheon',
    name: '남천 해변 언덕길',
    distanceM: 5200,
    expectedMinutes: 33,
    shape: shapes.hill,
  },
  {
    id: 'course-haeundae',
    name: '해운대 백사장',
    distanceM: 4100,
    expectedMinutes: 25,
    shape: shapes.line,
  },
];

// 2.9 알림, newest first. 2.9b uses an empty list.
export const notifications: AppNotification[] = [
  {
    id: 'noti-1',
    kind: 'GROUP_RUN_STARTING',
    message: '‘토요일 아침, 함께 5km’ 그룹런이 곧 시작해요',
    createdAt: '2026-10-19T12:42:00+09:00',
    read: false,
  },
  {
    id: 'noti-2',
    kind: 'CREW_JOIN_APPROVED',
    message: '‘민락 야경 러너스’ 가입이 승인됐어요',
    createdAt: '2026-10-19T12:33:00+09:00',
    read: false,
  },
  {
    id: 'noti-3',
    kind: 'POST_COMMENT',
    message: '서연님이 내 게시물에 댓글을 남겼어요: 페이스 좋네요!',
    createdAt: '2026-10-19T11:45:00+09:00',
    read: false,
  },
  {
    id: 'noti-4',
    kind: 'GROUP_RUN_CANCELED',
    message: '이번 주 ‘수요일 저녁 회복런’ 그룹런이 취소됐어요',
    createdAt: '2026-10-17T09:00:00+09:00',
    read: true,
  },
  {
    id: 'noti-5',
    kind: 'CREW_JOIN_REJECTED',
    message: '‘수영강 하프 크루’ 가입이 거절됐어요',
    createdAt: '2026-10-16T09:00:00+09:00',
    read: true,
  },
];

// The mock clock for relative times: 2026-10-19 12:45, as on every prototype screen.
export const now = '2026-10-19T12:45:00+09:00';
export const nightNow = '2026-10-19T20:30:00+09:00';

// 2.0F 현재 위치 near 민락수변공원.
export const currentPlace: CurrentPlace = {
  name: '민락수변공원 입구',
  gps: 'good',
  position: [129.1318, 35.1543],
};

// 2.0 코스 러닝: a 5km loop from 민락수변공원 with one recommended pace per km.
export const todayPlan: CoursePlan = {
  courseId: 'course-minrak',
  name: '민락수변공원 출발',
  distanceM: 5000,
  route: [
    [129.1318, 35.1543],
    [129.1352, 35.1561],
    [129.1384, 35.1592],
    [129.1402, 35.1631],
    [129.1376, 35.1662],
    [129.1331, 35.1668],
    [129.1289, 35.1651],
    [129.1271, 35.1614],
    [129.1282, 35.1578],
    [129.1318, 35.1543],
  ],
  segmentPacesSecPerKm: [365, 375, 360, 350, 350],
  strategy: '초반 안정 → 오르막 절제 → 후반 가속',
  targetPaceSecPerKm: 360,
  expectedDurationSec: 1800,
  caution: '2km 오르막 주의',
};

const melonLibrary: MusicLibrary = {
  likedCount: 128,
  liked: [
    {
      id: 'track-sea',
      title: '바다 쪽으로 달리기',
      subtitle: '아침 러닝 믹스',
      durationSec: 221,
    },
    {
      id: 'track-uphill',
      title: '오르막 끝에서',
      subtitle: '템포 업',
      durationSec: 192,
    },
  ],
  recent: [
    { id: 'pl-180', title: '페이스 유지 180' },
    { id: 'pl-recovery', title: '회복 조깅' },
    { id: 'pl-10k', title: '지난 주 10K' },
  ],
  playlists: [
    { id: 'pl-dawn', title: '광안리 새벽' },
    { id: 'pl-interval', title: '인터벌 데이' },
    { id: 'pl-long', title: '롱런 90분' },
  ],
  top100UpdatedAt: '2026-10-19T12:00:00+09:00',
  top100: [
    {
      id: 'top-1',
      title: 'TOP100 1위 곡',
      subtitle: '멜론 차트',
      durationSec: 200,
    },
    {
      id: 'top-2',
      title: 'TOP100 2위 곡',
      subtitle: '멜론 차트',
      durationSec: 210,
    },
  ],
};

const spotifyLibrary: MusicLibrary = {
  likedCount: 0,
  liked: [],
  recent: [],
  playlists: [
    { id: 'sp-dawn', title: '광안리 새벽' },
    { id: 'sp-interval', title: '인터벌 데이' },
    { id: 'sp-long', title: '롱런 90분' },
    { id: 'sp-tempo', title: '템포 런' },
    { id: 'sp-recovery', title: '회복 조깅' },
    { id: 'sp-weekend', title: '주말 15K' },
  ],
  top100UpdatedAt: null,
  top100: [],
};

export const musicLibraries = { MELON: melonLibrary, SPOTIFY: spotifyLibrary };

// 2.7 멜론 연결됨, playing at 1:24 of 3:41.
export const musicState: MusicState = {
  source: 'MELON',
  services: { MELON: 'CONNECTED', SPOTIFY: 'LOGIN_REQUIRED' },
  linked: true,
  nowPlaying: { ...melonLibrary.liked[0], positionSec: 84, playing: true },
  library: melonLibrary,
  premium: false,
};
