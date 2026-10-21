# 모바일 건강 데이터 검증 앱

관련 업무: [S15P31E105-60](https://ssafy.atlassian.net/browse/S15P31E105-60), [ADR 제안](adr/0005-health-connect-mobile-read.md).

`frontend/`의 React Native 앱은 OS를 자동 감지해 Android에서는 Samsung Health Data SDK1.1.0 우선·Health Connect 보완, iOS에서는 HealthKit을 읽는다. 서버·FastAPI 없이 수집 가능 여부를 확인하는 PoC다. 건강 기록을 서버로 보내거나 별도로 저장하지 않는다. 로그에 원본 건강값을 출력하지 않는다. [ADR0006 제안](adr/0006-samsung-health-direct-read.md)을 따른다.

| 항목 | Android | iOS |
| --- | --- | --- |
| 수면 | 삼성 SDK 제공 수면 시간·점수(있는 경우)·단계, HC 보완 | Apple 건강 SleepAnalysis |
| 일반 심박 | HeartRate의 개별 샘플 | HeartRate |
| 안정 시 심박 | 삼성 출처 우선, 성공한 빈 결과일 때만 다른 HC 출처 | RestingHeartRate |
| HRV | RMSSD, ms | SDNN, ms |
| 걸음 | 삼성 출처 플랫폼 집계 | HealthKit 집계 |
| 운동 | 삼성 운동 세션 | HealthKit 운동 기록 |
| 거리 | 직접 SDK: 실제 운동 세션 거리 / HC 보완: 최근 거리 구간 (기간 총거리 아님) | 기간 내 걷기/달리기 거리 집계 |

HRV 두 방식은 같은 값으로 비교하거나 환산하지 않는다. 안정 시 심박을 일반 심박에서 추정하지 않는다. 다른 출처가 선택되면 원래 앱 이름/식별자를 표시한다. 입력 방식이 제공되는 HC/HealthKit 기록은 직접 입력 여부를 상세 화면에서 표시한다. 삼성 직접 SDK에는 입력 방식 필드가 없어 임의 판정하지 않는다.

오늘/최근 7일은 기기 현지 날짜의 자정부터 현재까지다(걸음수 주간 평균 기간은 아래 별도 안내). 수면은 자정을 넘긴 세션을 찾기 위해 양쪽에서 시작 시각을 36시간 앞서 조회하고, 원래 세션 경계를 보존한다. 삼성 SDK DURATION을 시간·분으로 표시하며, 최근7일은 선택 기간(오늘 포함)의 완료된 수면을 현지 깬 날짜별로 묶어 하루 평균을 표시한다. 같은 날의 겹치지 않는 기록은 합치며, 누락/미확인일은0으로 넣지 않고 계산 일수를 표시한다. 겹친 기록은 단계로 중복을 제거할 수 있을 때만 계산한다. SLEEP_SCORE가 제공되면 평균 점수가 아닌 최근 수면 점수임을 구분해 표시한다. 수면 점수만 있으면 점수를 표시한다. 기록별 시간과 점수는 상세에서 확인한다. 원본 시간 없이 점수에서 시간을 추정하거나 침대에 있던 전체 시간을 수면으로 대체하지 않는다. SDK 제공 시간이 없을 때만 완전한 수면 단계로 시간을 계산한다. HealthKit의 개별 단계는 같은 출처·입력 방식에서 서로 맞닿거나 겹치는 구간만 묶는다. 누락된 단계를 수면으로 추정하지 않는다. 과거 기간 조회는 전경에서만 실행한다.

## Android 사용

1. 삼성 헬스에 워치 기록이 동기화됐는지 확인한다.
2. PoC 직접 조회는 삼성 헬스 설정 → 삼성 헬스 정보 → 버전 10회 누르기 → Developer mode (Samsung Health Data SDK) → 안내 확인 → Developer Mode for Data Read를 활성화한다. 일반 사용자 배포 절차가 아니며 공개 배포에는 파트너 등록이 필요하다.
3. 삼성 헬스 설정의 Health Connect 공유도 허용하고 RunwayHealth의 **읽기 권한 요청**에서 삼성 SDK와 HC 권한을 각각 선택한다.
4. **다시 조회** 후 카드를 눌러 원본 시각·출처·단계를 확인한다.
5. **삼성 헬스 열기**로 삼성 앱 설정을 확인하거나 **Health Connect 권한 설정**으로 HC 접근을 변경한다. 설정에서 돌아오면 기존 값을 지우고 재조회한다.

Android 10(API29) 이상이 필요하며 Health Connect 자체 가용성은 기기에서 확인한다. 삼성 SDK 지원 항목의 정상 빈 결과와 미지원만 HC로 보완한다. 권한·정책·조회 오류는 보완 성공으로 숨기지 않는다. HC에 삼성 안정 시 심박이 공유되지 않았고 다른 앱 기록도 없다면 빈 기록이 정상이다. 독립 안정 시 심박·HRV는 SDK에 없으므로 HC를 사용한다. 두 경로 값을 합산하지 않으며 원래 출처와 조회 경로를 표시한다. SDK 걸음수는 선택 기간 집계이며 기간 경계를 실측 시각으로 보지 않는다.

## iPhone 사용

별도 워치 페어링 화면 없이 Apple 건강의 기존 기록을 읽는다. 아이폰 자체가 7개 항목을 모두 측정하는 것은 아니다. 심박·HRV·수면 등은 기존 기기/앱 기록 또는 사용자 입력이 있어야 한다.

**읽기 권한 요청** 완료 후 기록을 조회한다. HealthKit은 읽기 허용 여부를 앱에 공개하지 않는다. 빈 결과를 권한 거부로 확정하거나 요청 완료를 읽기 허용으로 표시하지 않는다. 건강 앱 → 프로필 → 앱 → RunwayHealth에서 항목별 접근을 확인한다. 앱 재실행 시에도 요청 버튼을 먼저 눌러 조회 단계를 시작한다.

## 개발 및 빌드

고정 의존성은 `frontend/package.json`과 `pnpm-lock.yaml`을 따른다. Node 22.11 이상, pnpm 11, Android 빌드에는 JDK17을 사용한다. `pnpm-workspace.yaml`의 hoisted 설정을 유지한다.

```powershell
cd frontend
pnpm install --frozen-lockfile
pnpm test --runInBand
pnpm typecheck
pnpm lint
```

Android SDK 경로는 Git 제외된 `frontend/android/local.properties`의 `sdk.dir` 또는 `ANDROID_HOME`으로 설정한다. SDK36/Build Tools36, NDK27.1.12297006이 필요하다.

공식 [Samsung Health Data SDK1.1.0](https://developer.samsung.com/health/data/process.html)을 약관 확인 후 다운로드한다. AAR은 Git에 포함하지 않는다. 저장소 기준 `tmp/samsung-sdk/1.1.0/1.1.0/libs/samsung-health-data-api-1.1.0.aar`에 두거나 Gradle 옵션 `-PsamsungHealthSdk=C:/absolute/path/samsung-health-data-api-1.1.0.aar`를 지정한다. 라이선스/파트너 조건은 공개 배포 전 별도로 확인한다.

```powershell
cd android
.\gradlew.bat assembleDebug --console=plain -PreactNativeArchitectures=arm64-v8a
```

빌드 결과는 `frontend/android/app/build/outputs/apk/debug/app-debug.apk`다. arm64 휴대폰용 검증 빌드이며 JS가 APK에 포함돼 Metro 연결 없이 실행한다. 다른 ABI가 필요하면 빌드 옵션을 바꾼다. 표준 개발용 서명이며 배포용 서명이 아니다.

Gradle9.3.1 템플릿은 포함된 foojay0.5와 충돌하므로 8.14.3으로 고정했다. [Gradle 플러그인의 호환성 설명](https://github.com/gradle/foojay-toolchains), [AGP8.12 최소 Gradle8.13](https://developer.android.com/build/releases/agp-8-12-0-release-notes)을 참고했다. 시스템 Java25로 빌드하지 않는다.

iOS는 macOS/Xcode와 서명 가능한 Apple 개발 환경에서 실행한다.

```sh
cd frontend
bundle install
cd ios && bundle exec pod install
open RunwayHealth.xcworkspace
```

Xcode의 RunwayHealth 타깃에서 본인 팀/서명, HealthKit capability와 포함된 entitlement를 확인한 뒤 실제 iPhone에서 빌드한다. 읽기 목적 문구는 Info.plist에 있다. 백그라운드 전달/쓰기 권한은 요청하지 않는다. Windows에서 CocoaPods·Xcode 컴파일·HealthKit 실기기 동작을 검증한 것으로 간주하지 않는다.

## 검증과 배포 범위

[이번 실행의 검증 기록](../frontend/verification/S15P31E105-60.md)을 확인한다. 테스트 통과와 실제 삼성/Apple 건강 데이터 수집 성공은 별개다. 사용자 본인이 권한과 화면 값을 확인해야 하며, 건강 원본을 채팅이나 로그에 전달할 필요는 없다.

공개 배포 전에는 Google Play 건강 데이터 정책·Health Connect 사용 목적/데이터 보안 신고, Apple HealthKit 사용 목적·개인정보 처리방침·App Store 심사와 서명을 별도로 준비한다. 이번 PoC는 배포 승인을 받은 상태가 아니다. GPS 경로·운동 센서 스트리밍·칼로리·산소포화도·체중·모델 점수/서버 연동은 포함하지 않는다.

## 걸음수 주간 표시

오늘은 오늘 자정~현재 누적을 표시한다. 최근7일의 걸음수 카드는 오늘을 제외한 완료된7일을 날짜별 플랫폼 집계로 조회해 기록이 반환된 날의 하루 평균(걸음/일)을 표시한다. 기록 없음은0으로 채우지 않으며 실제 반환된0집계는 포함한다. 기록 일수(n/7일), 별도 걸음수 기간, 상세의 날짜별 상태·걸음수와 확인된 날의 합계를 함께 표시한다. 일부 날짜가 권한/조회 오류면 정상 누락일로 제외하지 않고 평균을 표시하지 않는다. 다른 건강 항목은 기존 선택 기간(오늘 포함)을 유지한다.


수면 중복은 ID가 달라도 출처·시각·제공 시간·점수·입력 방식·단계가 같은 기록이면 요약에서 먼저 제거한다. 날짜를 나누기 전에 전체 기록의 겹침을 해결하고, 해결된 구간은 최종 깬 날짜에 한 번만 배정한다. 서로 다른 겹친 기록을 확정할 단계가 부족하면 관여한 날짜를 미확인으로 제외해 부분합이 평균에 섞이지 않도록 한다. 원본 상세 기록은 변경하지 않는다.
