# RunWay 워치 앱

Android Studio에서 **이 `wear/` 폴더**를 프로젝트로 연다. 하나의 Gradle 프로젝트에 모듈 두 개가 있다.

| 모듈 | 폴더 | 내용 | applicationId |
| ---- | ---- | ---- | ------------- |
| `:app` | [`app/`](app/) | 제품 워치 앱. 공통 UI·화면 이동 구조(S15P31E105-264)부터 화면·기능을 더한다 | `com.runway.health` (폰 앱과 같아야 Data Layer로 연결된다) |
| `:demo` | [`demo/`](demo/) | 기존 BPM 실험·운동 데이터 수집 앱(S15P31E105-53). [실험 앱 안내](demo/README.md) | `com.runway.watchdemo` |

applicationId가 달라 두 앱을 한 기기에 함께 설치할 수 있다. 제품 기능은 `:app`에만 추가하고 `:demo`는 실험 용도로만 유지한다.

## 제품 앱 구조 (`app/`)

| 패키지 | 역할 |
| ------ | ---- |
| `run` | 운동 상태(READY·RUNNING·PAUSED·COMPLETED·CANCELLED·INTERRUPTED), 측정값, 사용자 요청(`RunIntent`), 실행 제어 인터페이스(`RunControl`) |
| `navigation` | 화면 이동 규칙. 화면은 **확정된 운동 상태**로 정해지고, 화면 이동은 운동을 시작·종료하지 않는다 |
| `ui/theme` | 색·글꼴. 모바일 디자인 기준([frontend/DESIGN.md](../frontend/DESIGN.md) 1-1·2-5)을 따른다 |
| `ui/component` | 공통 UI: 원형 화면(`RoundScreen`), 버튼, 측정값·단위, 상태 줄, 칩, 쪽 표시, 가장자리 링, 안내 화면 |
| `ui/format` | 값·단위·미수신(`– –`) 표시. 심박수(`♥ 152`)와 리듬 BPM(`♪ 172 BPM`)을 구분한다 |
| `ui` | 앱 화면 틀(`WatchApp`). 9.1~9.4 화면의 공통 뼈대이며 각 화면 업무(265~269, 256, 257)가 채운다 |
| `ui/screen` | 분리한 화면. `ResultScreen`(9.4, S15P31E105-269): 종료 처리 중·서버 저장 확인/미확인·분석 준비/중/실패/완료를 구분하고, 분석 READY에서만 서버 요약값과 목표 평가를 표시한다. 상태 값은 `run/RunResult.kt` |

화면 구성·흐름은 v15 와이어프레임 9.x, 색·글꼴은 모바일 디자인 기준을 따른다.

- 하단 버튼(뒤로): 러닝 중·일시정지·종료 확인에서는 앱을 닫거나 운동을 끝내지 않는다. 종료 확인에서는 일시정지 화면으로, 러닝 페이지에서는 첫 페이지로 돌아간다.
- 오른쪽으로 쓸어 넘겨 닫기: 대기·연결 문제·결과 화면에서만 앱을 닫는다. 러닝 중·일시정지·종료 확인에서는 좌우 넘기기 페이지와 겹치거나 실수로 닫히지 않도록 막는다(시스템 스와이프 닫기는 끄고 앱에서 화면별로 켠다).
- debug 빌드는 합성 데이터로 상태를 바로 바꾸는 `SimulatedRunControl`로 화면을 확인한다. 앱을 열 때마다 새 러닝으로 시작하므로 결과 화면에서 뒤로 버튼이나 오른쪽 쓸어 넘기기로 나간 뒤 다시 열면 대기 화면이 나온다. 실제 운동 제어는 S15P31E105-256에서 붙인다. release 빌드는 제어기가 없어 대기 화면만 보인다.

## 빠른 빌드

SDK 경로를 `local.properties` 또는 `ANDROID_HOME`으로 설정하고 Android Studio의 JBR을 사용한다. 아래 명령은 `wear/`에서 실행한다.

```powershell
# 제품 앱
.\gradlew.bat :app:testDebugUnitTest :app:lintDebug :app:assembleDebug
# 에뮬레이터·기기 연결 시 화면 이동 검증
.\gradlew.bat :app:connectedDebugAndroidTest
# 실험 앱
.\gradlew.bat :demo:testDebugUnitTest :demo:lintDebug :demo:assembleDebug
```

설치 APK: `app/build/outputs/apk/debug/app-debug.apk`, `demo/build/outputs/apk/debug/demo-debug.apk`

로컬 설정·서명 키·빌드 결과·실제 실험 JSON은 Git에 넣지 않는다.
