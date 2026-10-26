export type ReadinessState =
  | 'ready'
  | 'collecting'
  | 'stale'
  | 'permissionDenied'
  | 'watchDisconnected';

export type UserProfile = {
  id: string;
  nickname: string;
  runningLevel: 'beginner' | 'intermediate' | 'advanced';
  // 2.1 홈 uses the profile photo as its background; null shows the default backdrop.
  profileImageUrl: string | null;
};

export type TodayCondition = {
  date: string;
  syncedAt: string | null;
  readinessState: ReadinessState;
  readinessScore: number | null;
  condition: string | null;
  sleepMinutes: number | null;
  restingHeartRate: number | null;
  // Labels under each 2.1 metric, plus the AI line. All null until a score exists.
  readinessSummary: string | null;
  sleepLabel: string | null;
  restingHeartRateLabel: string | null;
  weeklyLoad: string | null;
  weeklyLoadLabel: string | null;
  aiAdvice: string | null;
  // 2.P′ 오래된 데이터: when the last score was made.
  lastAssessedDate: string | null;
};

// 2.1 홈 배경. The real API returns the profile photo for both; the mock follows the prototype,
// which pairs the light mode (2.1La) with a brighter photo.
export type HomeBackdrop = { dark: string | null; light: string | null };

// 2.1 러닝 분석 card.
export type MonthlyRunSummary = {
  month: string;
  runCount: number;
  totalDistanceM: number;
  averagePaceSecPerKm: number | null;
  // Monday-first share of the busiest weekday, 0–1.
  weekdayRatios: number[];
  // Positive when this month is faster than last month.
  paceImprovementSec: number | null;
};

export type RecordSort = 'recent' | 'distance' | 'pace';

export type RunRecordSummary = {
  id: string;
  title: string;
  startedAt: string;
  distanceM: number;
  durationSec: number;
  averagePaceSecPerKm: number;
  // Shape of the run for the small thumbnail, as [x, y] points in a 0–1 box.
  shape: [number, number][];
};

export type SavedCourse = {
  id: string;
  name: string;
  // C09 myAlias: the nickname only I see (3.1c 카드 제목). null shows the course name.
  myAlias: string | null;
  distanceM: number;
  expectedMinutes: number;
  shape: [number, number][];
};

// U10 환경 코드 (3.1 환경 · 여러 개 선택).
export type EnvironmentType =
  | 'PARK'
  | 'RIVERSIDE'
  | 'URBAN'
  | 'BEACH'
  | 'TRACK';

export type Place = { name: string; position: [number, number] };

// C01 코스 추천 request, from 3.1 오늘의 러닝.
export type CourseSearch = {
  origin: Place;
  targetDistanceM: number;
  goalInputType: 'TIME' | 'PACE';
  targetDurationSec: number | null;
  targetPaceSecPerKm: number | null;
  environmentTypes: EnvironmentType[];
};

// One card of 3.1b 추천 코스; the back of the card is the course detail.
export type RecommendedCourse = {
  id: string;
  name: string;
  distanceM: number;
  estimatedDurationSec: number;
  // 순환 · 왕복 · 편도 순환
  shapeKind: string;
  environmentLabels: string[];
  elevationGainM: number;
  // Relative height of each tenth of the course, 0–100 (구간 고도).
  elevationProfile: number[];
  reason: string;
  route: [number, number][];
  saved: boolean;
};

export type NotificationKind =
  | 'GROUP_RUN_STARTING'
  | 'CREW_JOIN_APPROVED'
  | 'CREW_JOIN_REJECTED'
  | 'POST_COMMENT'
  | 'GROUP_RUN_CANCELED'
  | 'FOLLOW_REQUEST';

export type AppNotification = {
  id: string;
  kind: NotificationKind;
  message: string;
  createdAt: string;
  read: boolean;
};

export type GpsQuality = 'good' | 'weak' | 'none';

export type CurrentPlace = {
  name: string;
  gps: GpsQuality;
  // [longitude, latitude] as in GeoJSON.
  position: [number, number];
};

// 2.0 코스 러닝: the course split into 1km segments with a recommended pace each.
export type CoursePlan = {
  courseId: string;
  name: string;
  distanceM: number;
  route: [number, number][];
  segmentPacesSecPerKm: number[];
  strategy: string;
  targetPaceSecPerKm: number;
  expectedDurationSec: number;
  caution: string | null;
  // 경쟁 모드: the earlier run on this course to race against (4.2 기록 차이, 4.5 비교 결과).
  rival: { startedAt: string; durationSec: number } | null;
};

// One reading during a run, once a second (4.2 러닝 진행).
export type RunSample = {
  elapsedSec: number;
  distanceM: number;
  paceSecPerKm: number | null;
  // null without a watch (4.5F 워치가 없으면 ‘– –’).
  heartRate: number | null;
  cadence: number | null;
  // GPS position as [longitude, latitude]; null while the signal is lost.
  position: [number, number] | null;
};

// 4.2 길 안내 줄.
export type RunGuidance = { instruction: string; detail: string };

export type RunRecordDraft = {
  mode: 'FREE' | 'COURSE';
  courseId: string | null;
  startedAt: string;
  durationSec: number;
  distanceM: number;
  averagePaceSecPerKm: number | null;
  averageHeartRate: number | null;
  averageCadence: number | null;
};

export type MusicService = 'MELON' | 'SPOTIFY';
export type MusicSource = MusicService | 'NONE';
export type MusicServiceStatus =
  | 'CONNECTED'
  | 'LOGIN_REQUIRED'
  | 'PERMISSION_REQUIRED'
  | 'INSTALL_REQUIRED';

export type Track = {
  id: string;
  title: string;
  subtitle: string;
  durationSec: number;
};

export type Playlist = { id: string; title: string };

export type MusicLibrary = {
  likedCount: number;
  liked: Track[];
  recent: Playlist[];
  playlists: Playlist[];
  top100UpdatedAt: string | null;
  top100: Track[];
};

export type MusicState = {
  // null until the user picks a source in 2.8 (2.7a 미연결).
  source: MusicSource | null;
  services: Record<MusicService, MusicServiceStatus>;
  // 2.7b: the link between RunWay and the music app dropped.
  linked: boolean;
  nowPlaying: (Track & { positionSec: number; playing: boolean }) | null;
  library: MusicLibrary | null;
  // Spotify plays chosen tracks only with Premium (2.7S).
  premium: boolean;
};

// U01 로그인 · U15 회원가입 response.
export type AuthSession = {
  user: { id: number; loginId: string };
  accessToken: string;
  onboardingCompleted: boolean;
};

export type Gender = 'MALE' | 'FEMALE';

// ERD code for users.health_data_access, spelled as in the API spec.
export type HealthDataAccess = 'AGREEE' | 'DISAGREE';

export type SignUpRequest = {
  loginId: string;
  password: string;
  nickname: string;
  birthDate: string;
  gender: Gender;
  phoneNumber: string;
  healthDataAccess: HealthDataAccess;
};

export type BasicProfile = Pick<
  SignUpRequest,
  'nickname' | 'birthDate' | 'gender'
>;

export type LoginIdAvailability = {
  loginId: string;
  available: boolean;
  reason: 'DUPLICATED' | null;
};

// Phone verification has no API spec yet; these shapes cover 1.3 and 1.2q until it does.
export type PhoneVerificationPurpose = 'SIGN_UP' | 'PASSWORD_RESET';

export type PhoneCodeRequest = {
  phoneNumber: string;
  purpose: PhoneVerificationPurpose;
};

export type SelfReportedLevel = 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';

// U09 평소 러닝 정보.
export type RunningBaseline = {
  baselineDistanceM: number | null;
  baselineDurationSec: number | null;
  usualPaceSecPerKm: number;
};

export type WatchLinkState = 'connected' | 'denied' | 'disconnected';

// Read from the watch on the phone, not from the server.
export type WatchConnection = {
  status: 'connected' | 'disconnected';
  batteryPercent: number | null;
  permissions: Record<
    'heartRate' | 'location' | 'sleep' | 'activity',
    WatchLinkState
  >;
};

export type Repositories = {
  auth: {
    login: (request: {
      loginId: string;
      password: string;
    }) => Promise<AuthSession>;
    checkLoginId: (loginId: string) => Promise<LoginIdAvailability>;
    requestPhoneCode: (
      request: PhoneCodeRequest,
    ) => Promise<{ expiresInSec: number }>;
    verifyPhoneCode: (
      request: PhoneCodeRequest & { code: string },
    ) => Promise<{ verificationToken: string }>;
    signUp: (request: SignUpRequest) => Promise<AuthSession>;
    resetPassword: (request: {
      verificationToken: string;
      newPassword: string;
    }) => Promise<void>;
  };
  profile: {
    getMe: () => Promise<UserProfile>;
    updateBasic: (profile: BasicProfile) => Promise<void>;
    setRunningLevel: (level: SelfReportedLevel) => Promise<void>;
    setRunningBaseline: (baseline: RunningBaseline) => Promise<void>;
  };
  home: {
    getTodayCondition: () => Promise<TodayCondition>;
    getMonthlySummary: () => Promise<MonthlyRunSummary>;
    getBackdrop: () => Promise<HomeBackdrop>;
  };
  records: {
    getRecent: (sort: RecordSort, limit: number) => Promise<RunRecordSummary[]>;
  };
  courses: {
    getSaved: () => Promise<SavedCourse[]>;
    // 2.0's plan for the course picked last with choose(); a default course until then.
    getTodayPlan: () => Promise<CoursePlan>;
    getOrigins: () => Promise<Place[]>;
    recommend: (search: CourseSearch) => Promise<RecommendedCourse[]>;
    save: (courseId: string) => Promise<void>;
    unsave: (courseId: string) => Promise<void>;
    choose: (courseId: string) => Promise<void>;
    // 4.5F 내 코스에 저장: turns a free run's path into a saved course.
    saveFromRun: (run: {
      recordId: string;
      route: [number, number][];
      distanceM: number;
      durationSec: number;
    }) => Promise<{ courseId: string }>;
  };
  notifications: {
    list: () => Promise<AppNotification[]>;
    markAllRead: () => Promise<void>;
  };
  run: {
    getCurrentPlace: () => Promise<CurrentPlace>;
    // Starts reading GPS and the watch from where the run left off; returns a function that stops it.
    startTracking: (
      from: RunSample,
      // The course being run, so the mock can follow it; the real tracker ignores it and reads GPS.
      route: [number, number][] | null,
      onSample: (sample: RunSample, guidance: RunGuidance | null) => void,
    ) => () => void;
    // Saves the finished run (4.5 기록 저장 중 → 기록 저장됨 · 동기화 완료).
    saveRecord: (record: RunRecordDraft) => Promise<{ recordId: string }>;
  };
  music: {
    getState: () => Promise<MusicState>;
    selectSource: (source: MusicSource) => Promise<MusicState>;
    // Opens login, permission or install for a service (2.8 오른쪽 버튼).
    resolveService: (service: MusicService) => Promise<MusicState>;
    reconnect: () => Promise<MusicState>;
  };
  // The current time; mock data pins it to the prototype's 12:45 so relative times and day/night match.
  clock: {
    now: () => Date;
  };
  watch: {
    getConnection: () => Promise<WatchConnection>;
    reconnect: () => Promise<WatchConnection>;
  };
};
