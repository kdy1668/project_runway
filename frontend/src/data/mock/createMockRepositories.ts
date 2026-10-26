import type { Repositories } from '../types';
import * as fixtures from './fixtures';

export type MockScenario = 'default' | 'newUser' | 'error';

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
      } else {
        // A copy keeps screens from mutating the shared fixtures.
        resolve(JSON.parse(JSON.stringify(value)) as T);
      }
    }, latencyMs);
  });
}

export function createMockRepositories(
  options: MockOptions = {},
): Repositories {
  return {
    profile: {
      getMe: () => respond(fixtures.me, options),
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
  };
}
