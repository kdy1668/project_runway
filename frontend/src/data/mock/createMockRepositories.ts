import { DataError } from '../errors';
import type {
  AuthSession,
  MusicSource,
  MusicState,
  PhoneCodeRequest,
  RecordSort,
  Repositories,
  RunRecordSummary,
  TodayCondition,
} from '../types';
import * as fixtures from './fixtures';

export type MockScenario =
  | 'default'
  // 2.P′ 신규 사용자: readiness still collecting.
  | 'newUser'
  | 'error'
  // 1.8 워치 연결 문제 and the 2.1 워치 미연결 state.
  | 'watchDisconnected'
  // The other 2.1 health data states.
  | 'staleHealth'
  | 'healthDenied'
  // 2.9b 알림 없음.
  | 'noNotifications'
  // 2.7S Spotify, 2.7a 미연결, 2.7b 연결 끊김, 2.8b 설치·권한 필요.
  | 'musicSpotify'
  | 'musicNotConnected'
  | 'musicDisconnected'
  | 'musicNeedsSetup'
  // 2.0N: after sunset.
  | 'night';

export type MockOptions = {
  scenario?: MockScenario;
  latencyMs?: number;
};

function respond<T>(
  value: T,
  { scenario = 'default', latencyMs = 300 }: MockOptions,
) {
  return new Promise<T>((resolve, reject) => {
    setTimeout(() => {
      if (scenario === 'error') {
        reject(new Error('목 데이터 오류 시나리오'));
      } else if (value === undefined) {
        resolve(value);
      } else {
        // A copy keeps screens from mutating the shared fixtures.
        resolve(JSON.parse(JSON.stringify(value)) as T);
      }
    }, latencyMs);
  });
}

function fail(error: DataError, { latencyMs = 300 }: MockOptions) {
  return new Promise<never>((_, reject) => {
    setTimeout(() => reject(error), latencyMs);
  });
}

function conditionFor(scenario: MockScenario = 'default'): TodayCondition {
  switch (scenario) {
    case 'newUser':
      return fixtures.collectingCondition;
    case 'staleHealth':
      return {
        ...fixtures.collectingCondition,
        readinessState: 'stale',
        lastAssessedDate: '2026-10-15',
      };
    case 'healthDenied':
      return {
        ...fixtures.collectingCondition,
        readinessState: 'permissionDenied',
      };
    case 'watchDisconnected':
      return {
        ...fixtures.collectingCondition,
        readinessState: 'watchDisconnected',
      };
    default:
      return fixtures.todayCondition;
  }
}

const recordOrder: Record<
  RecordSort,
  (a: RunRecordSummary, b: RunRecordSummary) => number
> = {
  recent: (a, b) => b.startedAt.localeCompare(a.startedAt),
  distance: (a, b) => b.distanceM - a.distanceM,
  pace: (a, b) => a.averagePaceSecPerKm - b.averagePaceSecPerKm,
};

// Picking a source swaps in that service's library; 음악 없음 clears the player.
function withSource(state: MusicState, source: MusicSource): MusicState {
  if (source === 'NONE') {
    return { ...state, source, nowPlaying: null, library: null };
  }
  const library = fixtures.musicLibraries[source];
  const first = library.liked[0] ?? null;
  return {
    ...state,
    source,
    library,
    nowPlaying: first ? { ...first, positionSec: 84, playing: true } : null,
  };
}

function musicFor(scenario: MockScenario = 'default'): MusicState {
  switch (scenario) {
    case 'musicSpotify':
      return {
        ...fixtures.musicState,
        source: 'SPOTIFY',
        services: { MELON: 'CONNECTED', SPOTIFY: 'CONNECTED' },
        library: fixtures.musicLibraries.SPOTIFY,
      };
    case 'musicNotConnected':
      return {
        ...fixtures.musicState,
        source: null,
        services: { MELON: 'LOGIN_REQUIRED', SPOTIFY: 'LOGIN_REQUIRED' },
        nowPlaying: null,
        library: null,
      };
    case 'musicDisconnected':
      return { ...fixtures.musicState, linked: false };
    case 'musicNeedsSetup':
      return {
        ...fixtures.musicState,
        services: { MELON: 'PERMISSION_REQUIRED', SPOTIFY: 'INSTALL_REQUIRED' },
      };
    default:
      return fixtures.musicState;
  }
}

type Account = {
  password: string;
  phoneNumber: string;
  onboardingCompleted: boolean;
};

type PendingCode = { expiresAt: number; failures: number };

export function createMockRepositories(
  options: MockOptions = {},
): Repositories {
  // Each repository set keeps its own accounts and attempt counts, so tests do not share state.
  const accounts = new Map<string, Account>(
    fixtures.takenLoginIds.map(loginId => [
      loginId,
      {
        password: fixtures.account.password,
        phoneNumber:
          loginId === fixtures.account.loginId
            ? fixtures.account.phoneNumber
            : '01000000000',
        onboardingCompleted: true,
      },
    ]),
  );
  let notifications = fixtures.notifications;
  let music = musicFor(options.scenario);
  const loginFailures = new Map<
    string,
    { count: number; lockedUntil: number }
  >();
  const pendingCodes = new Map<string, PendingCode>();
  const verifiedPhones = new Map<string, string>();
  let nextUserId = 101;

  const session = (loginId: string, account: Account): AuthSession => ({
    user: { id: nextUserId++, loginId },
    accessToken: `mock-token-${loginId}`,
    onboardingCompleted: account.onboardingCompleted,
  });
  const isRegistered = (phoneNumber: string) =>
    [...accounts.values()].some(account => account.phoneNumber === phoneNumber);
  const codeKey = ({ phoneNumber, purpose }: PhoneCodeRequest) =>
    `${purpose}:${phoneNumber}`;

  return {
    auth: {
      login: ({ loginId, password }) => {
        const now = Date.now();
        const failures = loginFailures.get(loginId) ?? {
          count: 0,
          lockedUntil: 0,
        };
        if (failures.lockedUntil > now) {
          return fail(
            new DataError('LOGIN_LOCKED', '로그인 제한', fixtures.maxAttempts),
            options,
          );
        }
        const account = accounts.get(loginId);
        if (!account || account.password !== password) {
          const count = failures.lockedUntil ? 1 : failures.count + 1;
          const locked = count >= fixtures.maxAttempts;
          loginFailures.set(loginId, {
            count,
            lockedUntil: locked ? now + fixtures.loginLockMs : 0,
          });
          return fail(
            locked
              ? new DataError('LOGIN_LOCKED', '로그인 제한', count)
              : new DataError('INVALID_CREDENTIALS', '로그인 실패', count),
            options,
          );
        }
        loginFailures.delete(loginId);
        return respond(session(loginId, account), options);
      },
      checkLoginId: loginId =>
        respond(
          {
            loginId,
            available: !accounts.has(loginId),
            reason: accounts.has(loginId) ? ('DUPLICATED' as const) : null,
          },
          options,
        ),
      requestPhoneCode: request => {
        const registered = isRegistered(request.phoneNumber);
        if (request.purpose === 'PASSWORD_RESET' && !registered) {
          return fail(
            new DataError('PHONE_NOT_REGISTERED', '가입되지 않은 전화번호'),
            options,
          );
        }
        if (request.purpose === 'SIGN_UP' && registered) {
          return fail(
            new DataError('PHONE_ALREADY_REGISTERED', '이미 가입된 전화번호'),
            options,
          );
        }
        pendingCodes.set(codeKey(request), {
          expiresAt: Date.now() + fixtures.verificationExpiresInSec * 1000,
          failures: 0,
        });
        return respond(
          { expiresInSec: fixtures.verificationExpiresInSec },
          options,
        );
      },
      verifyPhoneCode: ({ code, ...request }) => {
        const pending = pendingCodes.get(codeKey(request));
        if (!pending || pending.expiresAt < Date.now()) {
          return fail(
            new DataError('VERIFICATION_EXPIRED', '인증 시간 만료'),
            options,
          );
        }
        if (code !== fixtures.verificationCode) {
          pending.failures += 1;
          if (pending.failures >= fixtures.maxAttempts) {
            pendingCodes.delete(codeKey(request));
            return fail(
              new DataError(
                'VERIFICATION_ATTEMPTS_EXCEEDED',
                '인증 시도 초과',
                pending.failures,
              ),
              options,
            );
          }
          return fail(
            new DataError(
              'VERIFICATION_CODE_MISMATCH',
              '인증번호 불일치',
              pending.failures,
            ),
            options,
          );
        }
        pendingCodes.delete(codeKey(request));
        const verificationToken = `mock-verified-${codeKey(request)}`;
        verifiedPhones.set(verificationToken, request.phoneNumber);
        return respond({ verificationToken }, options);
      },
      signUp: request => {
        if (accounts.has(request.loginId)) {
          return fail(
            new DataError('LOGIN_ID_DUPLICATED', '이미 사용 중인 아이디'),
            options,
          );
        }
        const account = {
          password: request.password,
          phoneNumber: request.phoneNumber,
          onboardingCompleted: false,
        };
        accounts.set(request.loginId, account);
        return respond(session(request.loginId, account), options);
      },
      resetPassword: ({ verificationToken, newPassword }) => {
        const phoneNumber = verifiedPhones.get(verificationToken);
        const account = [...accounts.values()].find(
          candidate => candidate.phoneNumber === phoneNumber,
        );
        if (!account) {
          return fail(
            new DataError('VERIFICATION_EXPIRED', '인증 시간 만료'),
            options,
          );
        }
        account.password = newPassword;
        verifiedPhones.delete(verificationToken);
        return respond(undefined, options);
      },
    },
    profile: {
      getMe: () => respond(fixtures.me, options),
      updateBasic: () => respond(undefined, options),
      setRunningLevel: () => respond(undefined, options),
      setRunningBaseline: () => respond(undefined, options),
    },
    home: {
      getTodayCondition: () => respond(conditionFor(options.scenario), options),
      getMonthlySummary: () => respond(fixtures.monthlySummary, options),
      getBackdrop: () => respond(fixtures.homeBackdrop, options),
    },
    records: {
      getRecent: (sort, limit) =>
        respond(
          [...fixtures.recentRecords].sort(recordOrder[sort]).slice(0, limit),
          options,
        ),
    },
    courses: {
      getSaved: () => respond(fixtures.savedCourses, options),
      getTodayPlan: () => respond(fixtures.todayPlan, options),
    },
    notifications: {
      list: () =>
        respond(
          options.scenario === 'noNotifications' ? [] : notifications,
          options,
        ),
      markAllRead: () => {
        notifications = notifications.map(item => ({ ...item, read: true }));
        return respond(undefined, options);
      },
    },
    run: {
      getCurrentPlace: () => respond(fixtures.currentPlace, options),
    },
    music: {
      getState: () => respond(music, options),
      selectSource: source => {
        music = withSource(music, source);
        return respond(music, options);
      },
      resolveService: service => {
        music = {
          ...music,
          services: { ...music.services, [service]: 'CONNECTED' },
        };
        return respond(music, options);
      },
      reconnect: () => {
        music = { ...music, linked: true };
        return respond(music, options);
      },
    },
    clock: {
      now: () =>
        new Date(
          options.scenario === 'night' ? fixtures.nightNow : fixtures.now,
        ),
    },
    watch: {
      getConnection: () =>
        respond(
          options.scenario === 'watchDisconnected'
            ? fixtures.disconnectedWatch
            : fixtures.connectedWatch,
          options,
        ),
      reconnect: () =>
        respond(
          options.scenario === 'watchDisconnected'
            ? fixtures.disconnectedWatch
            : fixtures.connectedWatch,
          options,
        ),
    },
  };
}
