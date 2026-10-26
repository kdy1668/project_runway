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
- 화면을 구현하면 `RootNavigator.tsx`에서 그 이름의 자리 화면을 실제 컴포넌트로 바꾼다.

## 3. 디자인 토큰

- 색은 컴포넌트에 직접 쓰지 않고 `useTheme().colors`의 의미 이름(`text`, `accent`, `danger` 등)을 쓴다.
  원래 색 값은 `palette`에 있다. 디자인 1차 시안(S15P31E105-89)이 나오면 `tokens.ts`·`themes.ts`의 값만 바꾼다.
- 다크는 2.1 홈·6.0 그룹, 라이트는 2.1La·7.1 커뮤니티를 따른다. 기본값은 기기 설정이며
  8.1 설정의 화면 모드에서 바꿀 수 있다. 하단 탭 바는 프로토타입처럼 두 모드 모두 어두운 색이다.
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

## 6. 와이어프레임과 다른 점

- 유리 흐림(backdrop-filter)은 React Native 기본 기능에 없어 반투명 배경만 쓴다. 흐림이 필요하면 별도 라이브러리를 검토한다.
- 2.P의 하단 호를 끌어 넘기는 동작은 홈 화면 업무(S15P31E105-146)에서 구현한다. 지금은 아이콘을 눌러 이동한다.
- 프로토타입의 상단 상태 표시(12:45·87%)는 기기 상태 표시줄을 쓴다.
