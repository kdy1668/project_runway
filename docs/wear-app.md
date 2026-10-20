# RunWay 워치 실험 앱

담당자: 강현 · Jira: S15P31E105-53 · 대상: Galaxy Watch7 / Wear OS

자주 쓰는 절차: [빌드·페어링·업데이트 설치](#빌드와-실기기-설치) · [기록 추출](#기록-추출) · [연결 문제 해결](#연결-문제-해결)

## 목적과 범위

사용자가 설정한 BPM으로 소리·진동을 제공하고 달리는 동안 SPM, 속도, 거리, 걸음 수, 심박수, 보폭 데이터를 수집한다. 휴대폰 중계와 인터넷 없이 워치에 저장하고 운동 종료 후 JSON을 추출하거나 서버에 수동 전송한다.

Spring Boot 수신 API·서버 DB·운영 인증·자동 전송은 포함하지 않는다. 서버 구현과 데이터 분석은 [업로드 API 및 전체 JSON 필드 명세](wear-upload-api.md)를 기준으로 한다.

## 프로젝트와 개발 환경

Android Studio에서 저장소의 **`wear/` 폴더**를 프로젝트로 연다. Gradle 변경 안내가 나오면 **Sync Now**를 실행한다.

| 항목 | 설정 |
| --- | --- |
| 언어·화면 | Kotlin / Jetpack Compose |
| AGP / Kotlin | 9.4.1 / 2.2.10 |
| 최소 SDK | API 30 |
| compile / target SDK | API 37 |
| Java 런타임 | Android Studio의 JBR |
| 측정 | Wear OS Health Services |
| 기록 저장 | 앱 전용 SQLite `experiments.db` |

해당 SDK·Gradle 설정과 호환되는 Android Studio를 사용한다. SDK 경로는 Android Studio가 생성하는 `local.properties` 또는 `ANDROID_HOME`으로 설정한다.

## 화면과 사용 흐름

상단 BPM / 기록 / 전송 탭으로 이동한다. 주요 화면에는 세로 스크롤이 없고 참가자·서버 입력 및 상태·상세는 별도 화면으로 연다.

| 화면 | 기능 |
| --- | --- |
| BPM | 참가자 ID, 120·140·160 프리셋, ±5 조절, 소리·진동 개별 설정, 시작 |
| 기록 | SPM·심박·속도·보폭, 페이스·거리·걸음 수 페이지 전환, 측정 상태, 종료 |
| 종료된 기록 | 날짜·참가자 ID로 선택, 마지막 측정값·운동 시간 확인, 상세에서 전체 ID와 종료 사유 확인 |
| 전송 | 종료 기록 선택, 서버 전체 URL 설정, 수동 전송·재전송, JSON 파일 추출 |

- 참가자 ID는 실명·이메일 대신 영문·숫자·`_`·`-` 1~40자의 가명을 사용한다. 숫자 아래 ID를 눌러 변경한다.
- 신규 설치 기본값은 120BPM이며 업데이트 시 기존 저장 BPM을 유지한다. 조절 범위는 60~220이다. 프리셋은 실험 선택지이며 개인별 러닝 권장 빈도를 뜻하지 않는다.
- 한 박자는 왼발 또는 오른발의 한 걸음에 대응한다. 목표 BPM, 실제 SPM, 심박수의 bpm을 구분한다.
- 소리·진동은 기본으로 모두 켜져 있다. 소리는 미디어 음량을 따르고, 진동은 박자마다 22ms·최대 진폭 255를 요청한다. 실제 진폭 제어는 기기 지원에 따라 다르다.
- 기록 시작 시 신체 활동 권한은 필수다. 심박·위치 권한이 없으면 해당 기능을 제외한다. 다른 앱이 운동을 기록 중이면 먼저 그 앱에서 종료한다.
- 표시값은 평균이 아닌 마지막 수신값이다. 결측 셀은 권한 필요·미지원·측정 대기를 구분하고 15초 이상 지난 값은 이전 값으로 표시한다. 추정 보폭에는 추정 표시를 확인한다.
- 화면이 꺼져도 포그라운드 서비스가 측정과 박자 재생을 담당한다. 알림으로 복귀하거나 종료할 수 있다.
- 종료 시 마지막 센서 콜백을 처리하여 기록을 확정한다. 종료 처리 중 새 운동 시작과 미확정 기록 전송을 막는다.

색상과 둥근 버튼·카드는 팀 [노션 와이어프레임](https://www.notion.so/3fb66eca321580f09634d9fee0005cad)의 워치 시안을 참고했다.

## 코드 구조

```text
MainActivity → WatchScreens → RecordingService → SessionController
                                                 ├─ WatchCuePlayer: 소리·진동
                                                 ├─ HealthExerciseSource: 운동 데이터
                                                 └─ SqliteSessionStore: 기록 저장

저장된 종료 기록 → SessionJson → 파일 추출
저장된 종료 기록 → UploadCoordinator / SessionUploader → 서버 API
```

Kotlin 경로는 `wear/app/src/main/java/com/runway/watchdemo/` 기준이다.

| 파일 | 책임 |
| --- | --- |
| `presentation/MainActivity.kt` | 앱 초기화·권한·서비스 명령 연결 |
| `presentation/WatchScreens.kt` | 화면·사용자 입력·상태·기록 표시 |
| `presentation/WearTextInput.kt` | Wear OS RemoteInput 결과 처리 |
| `session/RecordingService.kt` | 알림·서비스·재생 및 측정 자원의 수명 |
| `session/SessionController.kt` | 시작·변경·종료 순서, 최종 콜백, 오류 처리 |
| `session/WatchRuntime.kt` | 프로세스 내 공유 상태와 작업 실행 범위 |
| `exercise/HealthExerciseSource.kt` | 지원 항목 조회, 측정 시작·종료, 원본 데이터 변환 |
| `cue/WatchCuePlayer.kt` | BPM별 소리·진동과 설정 적용 이벤트 |
| `session/SqliteSessionStore.kt` | 세션·측정값·BPM 이력 저장, 복구, 추출 |
| `session/SessionJson.kt` | schemaVersion 2 JSON 출력 및 기존 v1 기록 읽기 |
| `settings/WatchSettings.kt` | 참가자·BPM·소리·진동·서버 URL 설정 |
| `upload/SessionUploader.kt` | 전송 대상 확보, HTTP 요청·응답 확인, 전송 상태 갱신 |

측정·저장 제어는 전용 직렬 실행 경로, 네트워크는 별도 실행 경로로 처리하여 서버 대기가 측정·BPM 저장을 막지 않도록 한다. 화면의 메모리 상태와 DB 영속 기록은 구분한다.

## 주요 설계 결정

| 결정 | 이유와 처리 방식 |
| --- | --- |
| 워치 단독 측정·직접 업로드 | 휴대폰 중계 앱 없이 오프라인 실험 가능. 종료 후 일괄 전송 |
| SQLite 영속 저장 | 앱 재실행 후에도 원본 기록·BPM 이력 유지 |
| 단조 시간축 | 부팅 후 경과시간으로 측정과 BPM을 연결하고 고정 시작 UTC로 표시 시각 계산 |
| 원본 구간·품질 보존 | 콜백 도착 시각으로 덮어쓰거나 매초 동시 측정으로 채우지 않음 |
| 보폭 추정 구분 | 직접 지표가 미지원일 때만 같은 구간의 거리÷걸음 수 사용. 출처와 원본 품질 기록 |
| 세션 행을 쓰는 간단한 아웃박스 | 별도 테이블 없이 전송 상태를 지속 저장. 수동 재전송과 서버 중복 방지 사용 |

측정값의 단위·출처·품질 및 계산 기준은 [API 명세](wear-upload-api.md)의 데이터 품질 절을 따른다.

## 종료·복구·전송

운동 상태는 `STARTING → RUNNING → STOPPING → COMPLETED`이며 비정상 종료는 `INTERRUPTED` 또는 `FAILED`로 보존한다. DB 상태 저장 실패와 무관하게 소리·진동 및 센서 정지를 각각 시도하고 실패한 센서 정지는 정리 단계에서 재시도한다. 실패·중단 원인은 안내 화면과 기록 상세에서 확인한다.

프로세스 종료 후에는 미완성 세션을 중단 기록으로 복구하며 마지막 저장 이벤트 시각을 끝 시각으로 사용한다. 실제 정지 시각을 보증하지 않는다.

전송은 같은 SQLite 세션 행의 `PENDING / UPLOADING / UPLOADED / FAILED`를 사용한다. 상태 변경과 전송 데이터 읽기는 하나의 트랜잭션이며 읽기 실패 시 롤백한다. 앱 시작 시 결과가 불확실한 UPLOADING을 FAILED로 복구한다. 실패한 원본을 남기고 같은 sessionId로 수동 재전송한다.

자동 재시도는 하지 않는다. 서버는 sessionId로 중복을 방지해야 하며 요청·응답·시간 제한·인증 조건은 [API 명세](wear-upload-api.md)를 따른다.

## 빌드와 실기기 설치

Windows PowerShell에서 **아래 순서대로, 같은 창에서** 진행한다. 각 코드 블록을 복사해 실행하고 바로 아래의 정상 결과를 확인한 뒤 다음 단계로 넘어간다. 명령 앞에 목록 번호(`1.` 등)나 `PS C:\...>` 프롬프트는 붙이지 않는다.

이 안내의 기본 경로는 저장소 `C:\runway`, Android Studio `C:\Program Files\Android\Android Studio`, SDK `%LOCALAPPDATA%\Android\Sdk`다. 다른 위치에 설치했다면 1단계의 경로만 수정한다. IP·포트·파일명은 실행 중 물어보므로 명령 안에서 직접 수정할 필요가 없다.

### 1. PC 경로·Java 설정

PowerShell을 열고 다음 블록 전체를 실행한다. **새 PowerShell 창을 열 때마다 이 단계부터 다시 진행**한다.

```powershell
$repoPath = 'C:\runway'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'

Test-Path (Join-Path $repoPath 'wear\gradlew.bat')
Test-Path $adbPath
Test-Path (Join-Path $env:JAVA_HOME 'bin\java.exe')
```

**정상 결과:** `True`가 세 줄 나온다. 순서대로 저장소, ADB, Java 경로 확인이다. `False`가 나오면 해당 경로를 수정하고 이 블록을 다시 실행한다.

이어서 ADB와 Java 실행을 확인한다.

```powershell
& $adbPath version
& "$env:JAVA_HOME\bin\java.exe" -version
```

**정상 결과:** `Android Debug Bridge version ...`과 `openjdk version ...`이 출력된다. JAVA_HOME에 지정한 JBR을 사용하므로 Java를 별도로 설치하거나 PATH를 수정할 필요는 없다.

ADB 경로가 다르면 Android Studio의 Android SDK 설정에서 SDK 위치를 확인한다. PowerShell에서 실행 파일 경로를 변수로 호출할 때는 위 예시처럼 앞에 `&`를 붙인다.

### 2. 최신 소스로 APK 빌드

1단계를 마친 같은 PowerShell에서 실행한다. 현재 로컬 소스를 빌드하며, 이 명령이 원격 코드를 내려받지는 않는다.

```powershell
Set-Location (Join-Path $repoPath 'wear')
.\gradlew.bat :app:testDebugUnitTest :app:lintDebug :app:assembleDebug
```

**정상 결과:** 마지막에 `BUILD SUCCESSFUL`이 나온다. 경고가 있더라도 이 결과를 확인한다. `BUILD FAILED` 또는 `ERROR`로 끝나면 다음 단계로 넘어가지 않는다.

설치할 APK가 만들어졌는지 확인한다.

```powershell
$apkPath = Join-Path $repoPath 'wear\app\build\outputs\apk\debug\app-debug.apk'
Test-Path $apkPath
```

**정상 결과:** `True`.

### 3. 실제 워치 준비

1. PC와 실제 워치를 같은 Wi-Fi에 연결한다.
2. 처음 설정하는 워치는 **설정 → 워치 정보 → 소프트웨어 정보 → 소프트웨어 버전**을 5회 눌러 개발자 옵션을 활성화한다.
3. **설정 → 개발자 옵션**에서 **ADB 디버깅**과 **무선 디버깅**을 켠다. 네트워크 허용 확인이 나오면 현재 네트워크를 확인해 허용한다.
4. 무선 디버깅 기본 화면의 **IP 주소 및 포트**를 확인한다. 이후 `connect`와 `-s`에 사용하는 값이다.

| 값 | 확인 위치 | 사용 시점 |
| --- | --- | --- |
| 페어링용 IP·포트 | 무선 디버깅 → 새 기기 페어링 | `pair` 실행 |
| 페어링 코드 | 새 기기 페어링 화면 | `Enter pairing code:`가 나올 때 입력 |
| 연결용 IP·포트 | 무선 디버깅 기본 화면 | `connect`, 설치·추출 대상 지정 |

페어링은 PC를 등록하는 절차이고, 연결은 등록된 PC에서 현재 워치에 접속하는 절차다. **페어링 포트와 연결 포트는 다르다.** IP와 포트 사이는 콜론 하나(`:`)만 쓴다.

### 4. PC 페어링 — 처음이거나 등록이 없을 때만

워치 무선 디버깅의 **페어링된 기기 목록에 이 PC가 있으면 이 단계는 건너뛰고 5단계로 간다.** PC가 없으면 다음 절차로 등록한다.

워치의 **무선 디버깅 → 새 기기 페어링** 화면을 열어 둔다. 다음 블록을 실행하고 물어보는 IP와 포트를 각각 입력한다. IP 입력에는 포트나 콜론을 붙이지 않는다.

```powershell
$pairIp = Read-Host '새 기기 페어링 화면의 IP 주소만 입력'
$pairPort = Read-Host '같은 화면의 페어링 포트 숫자만 입력'
& $adbPath pair ('{0}:{1}' -f $pairIp.Trim(), $pairPort.Trim())
```

`Enter pairing code:`가 나오면 워치에 표시된 현재 코드를 입력한다. 앞자리가 0이어도 생략하지 않는다.

**정상 결과:** `Successfully paired to ...`. 이것은 PC 등록 완료이며, 아래 연결까지 진행해야 설치할 수 있다. 페어링 화면을 다시 열면 코드·포트가 바뀔 수 있으므로 이전 값을 재사용하지 않는다.

### 5. 워치 연결 — 매번 현재 주소 확인

워치에서 **새 기기 페어링 화면을 닫고 무선 디버깅 기본 화면으로 돌아간다.** 기본 화면의 IP·연결 포트를 보고 입력한다.

```powershell
$watchIp = Read-Host '무선 디버깅 기본 화면의 IP 주소만 입력'
$watchPort = Read-Host '기본 화면의 연결 포트 숫자만 입력'
$watchAddress = '{0}:{1}' -f $watchIp.Trim(), $watchPort.Trim()
& $adbPath connect $watchAddress
& $adbPath devices -l
```

**정상 결과:** `connected to ...` 또는 `already connected to ...`가 나오고, 기기 목록에서 입력한 실제 워치 주소 옆에 `device`가 표시된다. `offline`이나 에뮬레이터만 표시되면 6단계로 넘어가지 않는다.

Wi-Fi 변경 자체가 항상 재페어링을 요구하는 것은 아니다. PC 등록이 남아 있으면 4단계를 생략하고 현재 주소로 연결하면 된다. 네트워크 변경이나 무선 디버깅 재활성화 후에는 IP·연결 포트가 달라질 수 있다.

### 6. 새 앱 버전 설치

진행 중인 운동을 종료한 뒤 설치한다. 다음 명령은 `$watchAddress`로 지정한 실제 워치에 APK를 업데이트 설치한다.

```powershell
& $adbPath -s $watchAddress install -r $apkPath
```

**정상 결과:** `Success`가 나온다. 워치에서 RunWay 앱을 연다. `-s $watchAddress`가 실제 워치를 지정하므로 에뮬레이터가 함께 연결돼 있어도 해당 워치에 설치된다.

**같은 앱 ID·서명으로 `-r` 업데이트 설치하면 기존 앱 데이터를 유지한다.** 앱 삭제·데이터 초기화는 기존 기록을 지우므로 업데이트 절차에 포함하지 않는다. 서명 불일치 등으로 설치가 실패하면 앱을 삭제하기 전에 필요한 기존 기록을 추출·보관한다.

Android Studio에서 설치할 경우 실행 대상을 실제 워치로 선택한 뒤 **Run ▶**을 누른다. 워치와 에뮬레이터가 함께 연결돼 있으면 선택한 대상을 확인한다.

### 7. 설치 후 실기기 확인

1. 워치 날짜·시각을 확인한다. 잘못돼 있으면 아래 절차로 먼저 맞춘다.
2. 기존 기록이 있으면 기록 조회·파일 추출이 되는지 확인한다. 새 워치라 기록이 없다면 기존 기록 업데이트 호환은 미검증으로 남긴다.
3. 참가자 ID를 가명으로 설정하고 1~2분 기록한다. 운동 중 BPM을 한 번 변경하고 정상 종료한다.
4. **전송** 탭에서 종료한 기록을 선택하고 **파일 추출**을 누른다.
5. PC로 가져온 JSON에서 schemaVersion 2, 숫자 api·bootCount, Boolean synthetic과 BPM 변경 이력을 확인한다. bootCount 조회 불가 또는 과거 기록에 정보가 없는 경우의 null 규칙은 [API 명세](wear-upload-api.md)를 따른다. 센서 권한·지원 상태에 따라 결측이 있을 수 있다.

### 날짜·시각 맞추기

- 워치의 **설정 → 일반 → 날짜 및 시간**에서 자동 설정을 확인한다. 이미 켜져 있는데 시각이 틀리면 자동 설정을 껐다 켠 뒤 날짜·시각을 다시 확인한다. 이번 SM-L300 검증에서 이 방법으로 동기화했다.
- 휴대폰과 연결해 사용하는 경우에는 휴대폰의 자동 날짜·시간 설정과 Galaxy Wearable 연결 상태도 확인한다. 메뉴 제공 여부는 워치의 연결 상태·소프트웨어에 따라 다를 수 있다.
- 한국에서는 시간대도 **서울/GMT+09:00**인지 확인한다. 시각을 맞춘 뒤 새 운동을 시작한다. 이미 저장·추출한 기록의 시각은 자동으로 수정되지 않는다.
- 시각을 조정한 뒤 ADB가 끊겼다면 현재 무선 디버깅 주소로 다시 연결한다.

다음 사용 시에도 **1 → 2 → 3 → 5 → 6 → 7단계** 순서로 진행한다. PC 등록이 사라졌을 때만 4단계를 포함한다.

## 기록 추출

운동 중에는 DB에 저장하고 **파일 추출**을 누르면 `files/exports/<sessionId>.json`을 생성한다. 서버 전송 전에 파일을 추출할 필요는 없다. 앱 삭제·데이터 초기화 시 로컬 기록도 지워지므로 필요한 파일을 먼저 보관한다. 실제 실험 JSON은 Git에 넣지 않는다.

워치의 **파일 추출**은 워치 내부에 파일을 생성하는 동작이다. PC로 가져오려면 별도 복사가 필요하다. **워치에서 원하는 종료 기록을 선택해 파일 추출을 누른 뒤, 아래 블록 전체를 실행**한다. 파일명을 직접 찾거나 입력하지 않아도 된다.

앞에서 설정한 `$adbPath`·`$watchAddress`·`$repoPath`를 같은 PowerShell 창에서 사용하며 debug 빌드와 Python이 필요하다. 워치의 파일 수정 시각 기준으로 **가장 최근에 추출한 JSON 한 개**를 자동으로 가져온다. 가장 최근 운동과 가장 최근 추출은 다를 수 있으므로 원하는 기록에서 파일 추출을 누른 직후 실행한다.

```powershell
@'
from pathlib import Path
import subprocess
import sys

adb, device, repo = sys.argv[1:]
files = subprocess.check_output([
    adb, "-s", device, "shell", "run-as", "com.runway.watchdemo",
    "ls", "-t", "files/exports",
], text=True).splitlines()
filename = next((name.strip() for name in files if name.strip().endswith(".json")), None)
if filename is None:
    raise SystemExit("JSON file not found. Tap File export on the watch first.")
data = subprocess.check_output([
    adb, "-s", device, "exec-out", "run-as", "com.runway.watchdemo",
    "cat", f"files/exports/{filename}",
])
target = Path(repo) / "tmp" / "watch-records"
target.mkdir(parents=True, exist_ok=True)
output = target / filename
output.write_bytes(data)
print(output)
'@ | python - $adbPath $watchAddress $repoPath
```

**정상 결과:** 자동으로 선택한 파일의 `C:\runway\tmp\watch-records\<sessionId>.json` 경로가 출력된다. 저장된 폴더를 열어 파일을 확인한다.

```powershell
Invoke-Item (Join-Path $repoPath 'tmp\watch-records')
```

Windows PowerShell 5의 기본 리다이렉션은 UTF-16으로 바뀔 수 있어 원본 추출에는 위 방식을 사용한다. DB는 `databases/experiments.db`이며 실행 중 DB 파일 단독 복사보다 확정 JSON 추출을 권장한다.

## 연결 문제 해결

| 증상 | 확인·대응 |
| --- | --- |
| `failed to connect`, 연결 시간 초과 | 워치 Wi-Fi·무선 디버깅과 기본 화면의 현재 연결 주소 확인. 페어링용 포트를 사용하지 않았는지 확인 |
| `device offline` | 기존 연결을 해제한 뒤 현재 IP·연결 포트로 재연결. 아래 명령 참고 |
| `protocol fault` 등 페어링 실패 | 주소의 콜론이 하나인지, 새 기기 페어링 화면의 현재 포트·코드인지 확인. 해당 화면을 열어 둔 채 재시도 |
| 페어링된 기기 목록에 PC가 없음 | 최초 페어링 절차부터 진행 |
| `devices -l`에 에뮬레이터만 표시 | 실제 워치 연결이 아직 완료되지 않은 상태. 실제 주소로 연결 후 다시 확인 |
| `more than one device/emulator` | 설치·추출 명령에 `-s $watchAddress`를 넣어 실제 워치 지정 |
| PowerShell `ParserError` | `1.` 같은 목록 번호나 프롬프트를 명령에 포함했는지 확인 |
| `adb`를 찾을 수 없음 | PC 준비 단계의 `$adbPath`를 설정하고 `& $adbPath` 형식으로 실행. platform-tools 폴더에서는 `.\adb.exe`도 사용 가능 |
| `JAVA_HOME` 오류 | 1단계의 경로·Java 설정을 같은 PowerShell에서 다시 실행하고 `openjdk version ...` 출력 확인 후 2단계 진행 |
| `run-as` 실패 | 위 절차의 debug APK를 설치했는지, 실제 워치를 대상으로 지정했는지 확인 |

`offline`일 때는 `$watchAddress`를 바꾸기 전에 이전 연결을 해제하고, 워치 기본 화면의 현재 주소를 입력한다.

```powershell
& $adbPath disconnect $watchAddress
$watchIp = Read-Host '무선 디버깅 기본 화면의 현재 IP 주소만 입력'
$watchPort = Read-Host '기본 화면의 현재 연결 포트 숫자만 입력'
$watchAddress = '{0}:{1}' -f $watchIp.Trim(), $watchPort.Trim()
& $adbPath connect $watchAddress
& $adbPath devices -l
```

주소가 맞는데도 연결되지 않으면 워치의 무선 디버깅을 껐다 켜고 새 포트를 확인한다. 같은 Wi-Fi여도 기기 간 통신이 차단된 네트워크에서는 연결되지 않을 수 있다.

공식 안내: [삼성 Galaxy Watch와 Android Studio 연결](https://developer.samsung.com/sdp/blog/en/2024/04/30/connect-galaxy-watch-to-android-studio-over-wi-fi), [Android Wear OS 무선 디버깅](https://developer.android.com/training/wearables/get-started/debug-wifi), [삼성 워치 시간 설정](https://www.samsung.com/us/support/troubleshooting/TSG01003265/).

## 검증 결과

자동 테스트·독립 리뷰·실기기 확인 결과와 미검증 범위는 [S15P31E105-53 검증 보고서](../wear/verification/S15P31E105-53.md)를 참고한다.
