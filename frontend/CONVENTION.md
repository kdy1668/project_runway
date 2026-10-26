# 모바일 앱 공통 구조

> 상태: 화면 구현 기준 · 관련 업무: [S15P31E105-144](https://ssafy.atlassian.net/browse/S15P31E105-144)
>
> React Native([ADR-0001](../docs/adr/0001-react-native-mobile-app.md)) 앱의 화면 이동 구조, 디자인 토큰,
> 공통 컴포넌트, 목 데이터 주입 방식을 정리한다. 기준 시안은 RUNWAY 프로토타입 v15(10/26)이고,
> 실행 명령은 [frontend README](README.md)를 따른다.

화면 구현 업무(S15P31E105-145~153)는 이 구조 위에서 각자의 자리 화면을 실제 화면으로 바꾼다.

## 1. 폴더

| 위치 | 내용 |
| --- | --- |
| `src/theme/` | 디자인 토큰(`tokens.ts`), 라이트·다크 색(`themes.ts`), `ThemeProvider`·`useTheme` |
| `src/components/` | 공통 컴포넌트. `src/components`에서 한 번에 가져온다 |
| `src/navigation/` | 화면 목록(`routes.ts`), 내비게이터, 하단 탭(`PillTabBar.tsx`) |
| `src/data/` | Repository 인터페이스(`types.ts`), 목 구현(`mock/`), `DataProvider`·`useResource` |
| `src/session/` | 로그인 여부. 토큰 저장은 인증 API 연동 업무에서 추가한다 |
| `src/screens/` | 화면. 아직 구현하지 않은 화면은 `PlaceholderScreen`이 대신한다 |
| `src/screens/onboarding/` | 1.x 시작·로그인·회원가입·초기 설정·워치 연결·비밀번호 찾기(S15P31E105-145) |
| `src/screens/home/` | 2.1 홈·2.9 알림(S15P31E105-146) |
| `src/screens/run/` | 2.0M 러닝 방식 선택·2.0F 자유 러닝·2.0 코스 러닝·2.7 음악 카드·2.8 음원 선택(S15P31E105-146) |
| `src/format.ts` | 날짜·페이스·거리·시간 표시 형식. 날짜는 기기 시간대와 관계없이 한국 시간으로 보여 준다 |
| `assets/fonts/` | Noto Sans KR(400·500·700·900), Barlow(400~700). 라이선스는 `assets/licenses/` |

## 2. 화면 이동

- 로그인 전에는 1.x 화면만, 로그인 후에는 하단 탭과 그 위에 쌓이는 화면만 등록한다.
  `SessionProvider`의 `signIn`·`signOut`이 두 묶음을 바꾼다.
- 하단 탭은 홈(2.1) · 러닝(2.0M) · 그룹(6.0) · 커뮤니티(7.1) 네 개다. 러닝 탭 안에서 2.0M·2.0F·2.0,
  그룹 탭 안에서 6.0·6.1이 이동하며 탭 바가 보인다. 그 밖의 화면은 탭 위에 쌓여 탭 바를 가린다.
- 화면 번호·이름·담당 업무·이동할 화면은 `src/navigation/routes.ts` 한 곳에 둔다. 새 화면을 만들면
  `routes`와 해당 목록(`authRoutes`·`mainRoutes`·`runTabRoutes`·`groupTabRoutes`)에 추가한다.
- 다른 화면으로 갈 때는 `navigateTo(navigation, 'RunMode')`를 쓴다. 탭 안 화면이면 탭을 거쳐 이동한다.
- 상태 화면(1.2r·2.1La·4.5F·6.2f 등)은 별도 화면으로 만들지 않고 해당 화면의 상태로 구현한다.
- 화면을 구현하면 `RootNavigator.tsx`의 `screens`에 실제 컴포넌트를 넣어 자리 화면을 바꾼다.
  1.x 화면은 `src/screens/onboarding/index.tsx`의 `onboardingScreens`로 한 번에 넣는다.
- 회원가입은 1.3 계정 → 1.4 동의 → 1.5 기본 프로필을 `SignUpDraftProvider`에 모은 뒤 1.5의 다음에서
  U15 회원가입을 한 번 호출한다. 1.6 러닝 프로필부터는 가입된 계정으로 저장하고, 1.6w 휴대폰만 또는
  1.7 시작하기에서 `signIn`으로 홈에 들어간다. 로그인한 계정의 `onboardingCompleted`가 false면 1.6부터 이어 간다.

## 3. 디자인 토큰

- 색은 컴포넌트에 직접 쓰지 않고 `useTheme().colors`의 의미 이름(`text`, `accent`, `danger` 등)을 쓴다.
  원래 색 값은 `palette`에 있다. 디자인 1차 시안(S15P31E105-89)이 나오면 `tokens.ts`·`themes.ts`의 값만 바꾼다.
- 다크는 2.1 홈·6.0 그룹, 라이트는 2.1La·7.1 커뮤니티를 따른다. 기본값은 기기 설정이며
  8.1 설정의 화면 모드에서 바꿀 수 있다. 하단 탭 바는 프로토타입처럼 두 모드 모두 어두운 색이다.
- 1.x 온보딩 화면은 프로토타입처럼 화면 모드와 관계없이 항상 다크다. 흰색 주 버튼(`inverse`)이 어두운 배경을 전제로 한다.
- 2.1 홈은 화면 모드를 따른다(다크 2.1, 라이트 2.1La). 지도가 있는 2.0·2.0F는 화면 모드와 관계없이 낮에는 라이트,
  일몰 후(약 17:40~06:30)에는 다크(2.0N)다. 2.7·2.8 음악 카드는 항상 다크다.
- 현재 시각은 `repositories.clock.now()`로 읽는다. 목 데이터는 프로토타입처럼 2026-10-19 12:45로 고정해 상대 시간·낮밤이 같게 나온다.
- 글자는 `AppText`의 `variant`(`display`·`heading`·`body`·`caption`·`metric` 등)로 고른다.
  Android는 굵기를 파일로 구분하므로 `fontWeight` 대신 variant의 `fontFamily`를 쓴다.
  숫자는 프로토타입의 Bahnschrift 대신 대체 글꼴인 Barlow를 쓴다.
- 간격은 `spacing`, 모서리는 `radius`(버튼·입력창은 `pill`), 높이는 `size`를 쓴다.

## 4. 공통 컴포넌트

| 컴포넌트 | 프로토타입 근거 |
| --- | --- |
| `Button` | primary(민트)·secondary(유리)·inverse(흰색, 1.2 로그인)·danger(코랄)·text, 로딩·비활성 |
| `TextField` | 알약 입력창, 포커스 민트 테두리, 성공·오류 안내(1.3·1.2s) |
| `Card` | glass·solid·muted·outline(6.0 곧 출발하는 그룹런) |
| `ScreenHeader`·`IconButton` | 원형 뒤로·알림·설정 버튼, 알림 점 |
| `BottomSheet` | 6.2x·6.4d·7.2b처럼 아래에서 올라오는 창 |
| `useToast` | 8.3 워치 연결 해제 토스트와 되돌리기 |
| `EmptyState` | 2.9b 알림 없음, 2.P′ 점선 빈 카드 |
| `Screen` | 안전 영역, 배경색, 탭 화면의 하단 여백 |
| `Icon` | 프로토타입이 쓰는 Lucide 선 아이콘 |

설정 > 개발용 > 공통 컴포넌트 미리보기에서 현재 모드로 모든 컴포넌트를 확인할 수 있다.
개발용 메뉴는 `src/config.ts`의 `developerMenu`로 켜고 끈다. 출시 전에 끈다.

## 5. 목 데이터 주입

백엔드 API가 준비되기 전에는 화면이 목 데이터를 쓰되, 나중에 API로 바꿀 때 화면 코드는 고치지 않는다.

1. 화면이 쓰는 데이터 모양과 조회 함수를 `src/data/types.ts`의 `Repositories`에 도메인별로 추가한다.
   필드 이름은 [API 명세](../docs/design/api/README.md)를 우선한다.
2. 목 값은 `src/data/mock/fixtures.ts`에 프로토타입의 예시 값으로 넣고, `createMockRepositories`에서 반환한다.
3. 화면은 `useResource`로 불러오고 `loading`·`ready`·`error` 세 상태를 모두 그린다.
   `load` 함수는 컴포넌트 밖에 두거나 `useCallback`으로 고정한다.

```tsx
const loadHome = (repositories: Repositories) => repositories.profile.getMe();

function Greeting() {
  const me = useResource(useCallback(loadHome, []));
  if (me.status !== 'ready') {
    return null;
  }
  return <AppText>{me.data.nickname}님</AppText>;
}
```

- 목 구현은 기본 300ms 지연 후 응답한다. `createMockRepositories({ scenario })`로 신규 사용자(`newUser`)와
  오류(`error`) 상태를 만들 수 있다. 테스트는 `latencyMs: 0`으로 만든 저장소를 `App`의 `repositories`에 넣는다.
- API 연동 업무에서는 같은 `Repositories`를 구현한 API 저장소를 만들고 `src/config.ts`의 `dataSource`와
  `createRepositories`에 추가한다. 화면은 바꾸지 않는다.
- 화면 안에 목 값을 직접 쓰지 않는다. 시연 버튼이 필요한 상태는 목 시나리오로 만든다.
- 오류에 따라 화면이 달라지는 호출은 `DataError`의 `code`(API 명세의 오류 코드)와 `failedCount`로 구분한다.

목 데이터로 1.x 화면을 확인할 때는 아래 값을 쓴다. 값은 `src/data/mock/fixtures.ts`에 있다.

| 상황 | 값 |
| --- | --- |
| 로그인 | 아이디 `minjun01` · 비밀번호 `runway123` (5회 틀리면 10분 제한) |
| 이미 사용 중인 아이디 | `minjun01`, `runner01` |
| 가입된 전화번호(비밀번호 찾기) | `010-2483-5917`. 그 밖의 번호는 1.2r 가입되지 않은 번호 |
| 인증번호 | `482913`. 그 밖의 값은 1.2s 인증번호 오류(5회 틀리면 다시 받기) |
| 1.8 워치 연결 문제 | `createMockRepositories({ scenario: 'watchDisconnected' })` |

2.x 화면의 다른 상태도 목 시나리오로 확인한다.

| 화면 상태 | 시나리오 |
| --- | --- |
| 2.1 준비도 — 수집 중 · 오래된 데이터 · 권한 거부 · 워치 미연결 | `newUser` · `staleHealth` · `healthDenied` · `watchDisconnected` |
| 2.9b 알림 없음 | `noNotifications` |
| 2.0N 밤 화면 | `night` (20:30) |
| 2.7S Spotify · 2.7a 미연결 · 2.7b 연결 끊김 · 2.8b 설치·권한 필요 | `musicSpotify` · `musicNotConnected` · `musicDisconnected` · `musicNeedsSetup` |

## 6. 와이어프레임과 다른 점

- 유리 흐림(backdrop-filter)은 React Native 기본 기능에 없어 반투명 배경만 쓴다. 흐림이 필요하면 별도 라이브러리를 검토한다.
- 2.P의 하단 호를 끌어 넘기는 동작은 구현하지 않았다. 2.P·2.P′은 프로토타입 진입용 화면이라 S15P31E105-146 범위에서 빠졌다. 탭을 눌러 이동한다.
- 프로토타입의 상단 상태 표시(12:45·87%)는 기기 상태 표시줄을 쓴다.
- 1.x 온보딩(S15P31E105-145)
  - 1.1·1.2의 흐린 러너 사진은 출처가 정해지지 않아 어두운 그라데이션으로 대신한다. 디자인 1차 시안(S15P31E105-89)에서 정한다.
  - 1.3 전화번호는 프로토타입에 인증 완료 상태만 있어 인증번호 받기 → 6자리 입력(3분) → 인증 완료 순서를 더했다.
  - 1.4 버튼 문구는 ‘동의하고 가입하기’ 그대로지만, U15가 닉네임·성별·생년월일을 함께 받아야 해서 계정은 1.5 다음에서 만든다.
    계정을 만든 뒤에는 1.5에서 뒤로 가지 않는다. 1.4의 ‘보기’는 약관 전문이 정해질 때까지 항목 설명만 보여 준다.
  - 1.5 생년월일 선택은 React Native에 드롭다운이 없어 아래에서 올라오는 목록으로 고른다.
  - 1.7·1.8 하단의 큰 호 손잡이는 가로 밀기 막대로 구현했다. 화면 낭독기에서는 두 번 탭으로 실행한다.
  - 프로토타입의 예시 아이디 `minjun_run`은 API 규칙(영문·숫자 4–16자)에 맞지 않아 목 계정은 `minjun01`이다.
  - 전화번호 인증·비밀번호 재설정 API는 아직 명세가 없어 `auth.requestPhoneCode`·`verifyPhoneCode`·`resetPassword`는
    화면에 필요한 모양으로 정했다. 로그인 실패 횟수(2/5)도 U01 오류 응답에 없어 `failedCount`가 있을 때만 표시한다.
- 2.x 홈·러닝 시작(S15P31E105-146)
  - 2.1의 배경 사진은 내 프로필 사진(`profileImageUrl`)이다. 사진이 없으면 1.1과 같은 그라데이션을 깔고,
    사진이 있으면 카드를 올릴수록 사진이 흐려진다. 배경은 `home.getBackdrop()`에서 화면 모드별로 받는다. 실제 API에서는 두 모드 모두
    프로필 사진이고, 목 데이터는 프로토타입처럼 다크에 인물 사진(`assets/images/mock-profile.jpg`), 라이트(2.1La)에 밝은 사진
    (`assets/images/mock-backdrop-light.jpg`)을 쓴다. 아바타는 두 모드 모두 프로필 사진이다.
    두 사진 모두 출처를 알 수 없는 외부 포스터 이미지라 출시 전에 반드시 교체하거나 삭제한다.
  - 2.1La는 같은 화면의 라이트 모드로 만들었다. 프로토타입 2.1La에만 있는 카드 구성(러닝 기록·분석, 지난 러닝 코스,
    프로필 요약, 워치 상태)은 2.1의 구성으로 통일했다.
  - 지도는 지도 SDK가 정해질 때까지(S15P31E105-180) 거리 모양을 그린 대체 지도(`MockMap`)에 현재 위치와 코스를 그린다.
    코스 좌표는 API처럼 GeoJSON [경도, 위도]를 넘기므로 SDK를 붙일 때 화면 데이터는 바꾸지 않는다.
  - 2.0 설명에 있는 ‘비교 기록’과 ‘내 코스에 저장’은 프로토타입 화면에 없어 이번에 넣지 않았다.
  - ‘러닝 시작’의 3초 카운트다운은 프로토타입에 화면이 없어 어두운 덮개 위 숫자로 만들었고, 누르면 취소된다.
  - 멜론·Spotify 표시는 단순한 원형 마크로 대신하고, 앨범 아트는 프로토타입처럼 색 사각형으로 둔다.
  - 2.8은 2.7 카드 위에 같은 크기로 겹쳐 열린다. 뒤로 가면 2.7로 돌아간다.
  - 목 날짜 2026-10-19는 월요일이라 날짜 칩이 ‘10월 19일 월요일’로 나온다(프로토타입은 일요일).
