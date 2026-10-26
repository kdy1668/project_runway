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

export type Repositories = {
  profile: {
    getMe: () => Promise<UserProfile>;
  };
  home: {
    getTodayCondition: () => Promise<TodayCondition>;
  };
};
