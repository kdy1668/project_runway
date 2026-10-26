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
};

export type TodayCondition = {
  date: string;
  syncedAt: string | null;
  readinessState: ReadinessState;
  readinessScore: number | null;
  condition: string | null;
  sleepMinutes: number | null;
  restingHeartRate: number | null;
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
  };
  watch: {
    getConnection: () => Promise<WatchConnection>;
    reconnect: () => Promise<WatchConnection>;
  };
};
