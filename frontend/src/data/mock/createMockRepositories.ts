import { DataError } from '../errors';
import type {
  AuthSession,
  PhoneCodeRequest,
  Repositories,
} from '../types';
import * as fixtures from './fixtures';

export type MockScenario =
  | 'default'
  | 'newUser'
  | 'error'
  // 1.8 워치 연결 문제: the watch stays disconnected even after reconnecting.
  | 'watchDisconnected';

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
  const loginFailures = new Map<string, { count: number; lockedUntil: number }>();
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
      getTodayCondition: () =>
        respond(
          options.scenario === 'newUser'
            ? fixtures.collectingCondition
            : fixtures.todayCondition,
          options,
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
