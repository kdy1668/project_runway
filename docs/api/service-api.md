# RunWay API 명세서

- 버전: v0.1 검토안
- 작성 기준일: 2026-10-14
- 기준 문서: [`docs/requirements/mvp.md`](../requirements/mvp.md)
- 대상: 모바일 앱·Galaxy Watch 연동 앱과 RunWay 백엔드 사이의 API

> 이 문서는 요구사항과 1차 MVP를 바탕으로 작성한 검토용 초안이다. Galaxy Watch에서 실제로 제공되는 필드, 지도 서비스, 인증 방식 및 AI 처리 시간은 기술 검증 후 확정한다.

## 1. 설계 가정

1. 일반 조회·등록·수정 기능은 REST API를 사용한다.
2. 러닝 중 데이터 및 그룹런 진행 정보는 WebSocket으로 전달하고, 기록 보존과 재전송을 위해 배치 REST API도 제공한다.
3. Galaxy Watch는 모바일 앱을 통해 서버와 통신하며, 모바일 앱이 워치 원본 데이터를 RunWay 표준 데이터 형식으로 변환한다.
4. 인증은 Bearer Access Token을 사용하는 것으로 가정한다.
5. 날짜와 시간은 ISO 8601 형식을 사용하며 서버 저장 기준은 UTC로 한다.
6. 리소스 ID는 UUID 형식의 문자열을 사용한다.
7. 코스 추천, 운동 준비도 및 페이스 분석은 백엔드가 AI 기능을 호출하고 클라이언트에는 하나의 API로 제공한다.

## 2. 공통 규칙

### 2.1 기본 정보

| 항목 | 값 |
| --- | --- |
| Base URL | `/api/v1` |
| 데이터 형식 | `application/json` |
| 인증 헤더 | `Authorization: Bearer {accessToken}` |
| 요청 추적 헤더 | `X-Request-Id` 선택 |

### 2.2 성공 응답

```json
{
  "data": {},
  "meta": {
    "requestId": "req_123"
  }
}
```

목록 응답은 커서 기반 페이지네이션을 사용한다.

```json
{
  "data": [],
  "meta": {
    "nextCursor": "next_cursor",
    "hasNext": true
  }
}
```

### 2.3 오류 응답

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "요청 값을 확인해 주세요.",
    "details": [
      {
        "field": "targetDistanceMeters",
        "reason": "must_be_positive"
      }
    ],
    "requestId": "req_123"
  }
}
```

| HTTP 상태 | 사용 기준 |
| --- | --- |
| `200 OK` | 조회·수정 성공 |
| `201 Created` | 리소스 생성 성공 |
| `202 Accepted` | 비동기 분석·추천 작업 접수 |
| `204 No Content` | 삭제·취소 성공 |
| `400 Bad Request` | 형식 또는 입력값 오류 |
| `401 Unauthorized` | 인증 실패 |
| `403 Forbidden` | 접근 권한 없음 |
| `404 Not Found` | 리소스 없음 |
| `409 Conflict` | 중복 참여, 상태 충돌 등 |
| `422 Unprocessable Entity` | 분석에 필요한 데이터 부족 등 |

## 3. 인증 API

| Method | Endpoint | 설명 | 인증 |
| --- | --- | --- | --- |
| POST | `/auth/signup` | 회원가입 | 불필요 |
| POST | `/auth/login` | 로그인 및 토큰 발급 | 불필요 |
| POST | `/auth/refresh` | Access Token 갱신 | Refresh Token |
| POST | `/auth/logout` | 로그아웃 및 토큰 폐기 | 필요 |

### 3.1 회원가입

`POST /auth/signup`

```json
{
  "email": "runner@example.com",
  "password": "string",
  "nickname": "runway"
}
```

### 3.2 로그인 응답

```json
{
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "expiresInSeconds": 3600,
    "user": {
      "id": "uuid",
      "nickname": "runway"
    }
  }
}
```

## 4. 사용자·러닝 프로필 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| GET | `/users/me` | 내 기본 프로필 조회 |
| PATCH | `/users/me` | 내 기본 프로필 수정 |
| GET | `/users/me/running-profile` | 러닝 수준·선호 정보 조회 |
| PUT | `/users/me/running-profile` | 러닝 수준·선호 정보 설정 |
| GET | `/users/me/running-goal` | 현재 러닝 목표 조회 |
| PUT | `/users/me/running-goal` | 러닝 목표 설정·수정 |
| GET | `/users/me/privacy-settings` | 공개 범위 조회 |
| PATCH | `/users/me/privacy-settings` | 공개 범위 수정 |

### 4.1 러닝 프로필 설정

`PUT /users/me/running-profile`

```json
{
  "runningLevel": "BEGINNER",
  "preferredEnvironments": ["PARK", "RIVERSIDE"],
  "preferredRoadTypes": ["PEDESTRIAN_PATH", "TRACK"]
}
```

### 4.2 러닝 목표 설정

`PUT /users/me/running-goal`

```json
{
  "targetDistanceMeters": 10000,
  "targetDurationSeconds": 3600,
  "targetPaceSecondsPerKm": 360
}
```

목표 항목은 일부만 설정할 수 있다. 항목 간 값이 충돌할 때 어떤 값을 우선할지는 정책 확정이 필요하다.

## 5. Galaxy Watch 및 건강 데이터 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/watch/connections` | 워치 연결 정보 등록 |
| GET | `/watch/connections/current` | 현재 워치 연결 상태 조회 |
| DELETE | `/watch/connections/current` | 워치 연결 해제 |
| POST | `/watch/health-data/batches` | 수면·활동·심박 데이터 일괄 동기화 |
| POST | `/watch/workout-data/batches` | 오프라인 운동 데이터 일괄 동기화 |

### 5.1 워치 연결 등록

`POST /watch/connections`

```json
{
  "deviceId": "client-generated-device-id",
  "deviceModel": "Galaxy Watch",
  "appVersion": "1.0.0",
  "healthDataProvider": "TBD"
}
```

### 5.2 건강 데이터 동기화

`POST /watch/health-data/batches`

```json
{
  "deviceId": "device-id",
  "batchId": "unique-batch-id",
  "syncedAt": "2026-10-14T01:00:00Z",
  "sleepRecords": [
    {
      "startedAt": "2026-10-13T14:30:00Z",
      "endedAt": "2026-10-13T22:00:00Z",
      "durationMinutes": 450
    }
  ],
  "dailyActivities": [
    {
      "date": "2026-10-13",
      "steps": 8200,
      "activeMinutes": 65,
      "activeCaloriesKcal": 410
    }
  ],
  "heartRateSummaries": [
    {
      "date": "2026-10-13",
      "restingHeartRateBpm": 58,
      "minimumHeartRateBpm": 49,
      "maximumHeartRateBpm": 171
    }
  ]
}
```

> `sleepRecords`, `dailyActivities`, `heartRateSummaries`의 세부 필드와 제공 가능 여부는 Galaxy Watch 연동 기술 검증 후 확정한다. `batchId`는 재전송 시 중복 저장을 방지하기 위한 값이다.

## 6. 운동 준비도 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/readiness/analyses` | 최신 데이터 기반 준비도 분석 요청 |
| GET | `/readiness/latest` | 최근 운동 준비도 조회 |
| GET | `/readiness` | 준비도 이력 조회 |

### 6.1 준비도 분석 요청

`POST /readiness/analyses`

```json
{
  "subjectiveCondition": "NORMAL"
}
```

### 6.2 준비도 결과

```json
{
  "data": {
    "id": "uuid",
    "status": "COMPLETED",
    "score": 78,
    "level": "READY",
    "summary": "가벼운 러닝에 적합한 상태입니다.",
    "factors": [
      {
        "type": "SLEEP",
        "status": "GOOD",
        "description": "수면 시간이 충분합니다."
      }
    ],
    "analyzedAt": "2026-10-14T01:05:00Z"
  }
}
```

상태값: `PENDING`, `COMPLETED`, `INSUFFICIENT_DATA`, `FAILED`

## 7. 러닝 코스 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/course-recommendation-requests` | 코스 생성·추천 요청 |
| GET | `/course-recommendation-requests/{requestId}` | 추천 작업 상태 및 결과 조회 |
| GET | `/courses/{courseId}` | 코스 상세 조회 |
| GET | `/users/me/saved-courses` | 저장 코스 목록 조회 |
| POST | `/users/me/saved-courses` | 코스 저장 |
| DELETE | `/users/me/saved-courses/{courseId}` | 저장 코스 삭제 |

### 7.1 코스 추천 요청

`POST /course-recommendation-requests`

```json
{
  "startLocation": {
    "latitude": 37.5665,
    "longitude": 126.978
  },
  "targetDistanceMeters": 5000,
  "courseShape": "LOOP",
  "preferredEnvironments": ["PARK"],
  "preferredRoadTypes": ["PEDESTRIAN_PATH"],
  "avoidSteepSlopes": true
}
```

응답은 `202 Accepted`이며 `requestId`를 반환한다. 추천이 완료되면 조회 API에서 코스 목록을 반환한다.

### 7.2 코스 요약 모델

```json
{
  "id": "uuid",
  "name": "한강 5km 순환 코스",
  "distanceMeters": 5120,
  "estimatedDurationSeconds": 1860,
  "elevationGainMeters": 24,
  "roadTypes": ["PEDESTRIAN_PATH"],
  "safetySummary": "보행로 중심",
  "recommendationReasons": ["선호 환경과 일치", "목표 거리와 유사"]
}
```

코스 상세의 경로는 GeoJSON `LineString` 형식을 우선 검토한다.

## 8. 페이스 전략 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/pace-strategies` | 러닝 시작 전 페이스 전략 생성 |
| GET | `/pace-strategies/{strategyId}` | 페이스 전략 조회 |
| POST | `/runs/{runId}/pace-strategy/recalculations` | 러닝 중 페이스 전략 재계산 요청 |
| GET | `/runs/{runId}/guidance/current` | 현재 페이스·BPM 가이드 조회 |

### 8.1 페이스 전략 생성

`POST /pace-strategies`

```json
{
  "courseId": "uuid",
  "targetDistanceMeters": 10000,
  "targetDurationSeconds": 3600
}
```

```json
{
  "data": {
    "id": "uuid",
    "targetPaceSecondsPerKm": 360,
    "segments": [
      {
        "fromDistanceMeters": 0,
        "toDistanceMeters": 1000,
        "targetPaceSecondsPerKm": 370,
        "targetBpm": 168
      }
    ],
    "explanation": "초반 오버페이스 방지를 위해 첫 구간을 완만하게 설정했습니다."
  }
}
```

`targetBpm`은 음악의 박자 또는 메트로놈 안내 속도를 의미하며 심박수 BPM과 구분한다.

## 9. 개인 러닝 세션 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/runs` | 러닝 세션 생성 및 시작 |
| GET | `/runs` | 내 러닝 기록 목록 조회 |
| GET | `/runs/{runId}` | 러닝 세션·기록 상세 조회 |
| POST | `/runs/{runId}/pause` | 러닝 일시정지 |
| POST | `/runs/{runId}/resume` | 러닝 재개 |
| POST | `/runs/{runId}/finish` | 러닝 종료 |
| POST | `/runs/{runId}/telemetry/batches` | 실시간 데이터 배치 저장·재전송 |
| GET | `/runs/{runId}/analysis` | 러닝 결과 분석 조회 |

### 9.1 러닝 시작

`POST /runs`

```json
{
  "courseId": "uuid",
  "paceStrategyId": "uuid",
  "groupRunId": null,
  "source": "GALAXY_WATCH"
}
```

### 9.2 실시간 운동 데이터 배치

`POST /runs/{runId}/telemetry/batches`

```json
{
  "deviceId": "device-id",
  "batchId": "unique-batch-id",
  "samples": [
    {
      "sequence": 101,
      "measuredAt": "2026-10-14T01:30:10Z",
      "heartRateBpm": 152,
      "cadenceSpm": 174,
      "latitude": 37.5665,
      "longitude": 126.978,
      "altitudeMeters": 32.4,
      "gpsAccuracyMeters": 8.0,
      "distanceMeters": 2530,
      "speedMetersPerSecond": 2.82
    }
  ]
}
```

워치 제공 필드가 확정되기 전까지 다음 원칙을 적용한다.

- 각 샘플은 `measuredAt`과 `sequence`를 반드시 가진다.
- 지원되지 않거나 측정되지 않은 센서 값은 필드 자체를 생략한다.
- `batchId`와 `sequence`를 이용해 재전송 데이터의 중복 여부를 판별한다.
- 페이스는 필요하면 거리·시간·속도를 바탕으로 서버에서 계산한다.

### 9.3 러닝 결과 분석 모델

```json
{
  "data": {
    "runId": "uuid",
    "distanceMeters": 10030,
    "durationSeconds": 3580,
    "averagePaceSecondsPerKm": 357,
    "averageHeartRateBpm": 158,
    "averageCadenceSpm": 174,
    "goalAchievement": {
      "achieved": true,
      "timeDifferenceSeconds": -20
    },
    "paceConsistency": {
      "level": "GOOD",
      "summary": "후반까지 목표 페이스를 안정적으로 유지했습니다."
    },
    "segments": []
  }
}
```

## 10. 그룹런 API

공개 모집과 실제 그룹런 세션은 하나의 `GroupRun` 리소스로 관리한다. `status=RECRUITING`인 공개 그룹런은 참가자 모집 목록에 노출한다.

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/group-runs` | 그룹런 생성·참가자 모집 등록 |
| GET | `/group-runs` | 공개 그룹런 검색·목록 조회 |
| GET | `/group-runs/{groupRunId}` | 그룹런 상세 조회 |
| POST | `/group-runs/{groupRunId}/participants` | 그룹런 참여 |
| DELETE | `/group-runs/{groupRunId}/participants/me` | 그룹런 참여 취소·종료 |
| POST | `/group-runs/{groupRunId}/start` | 그룹런 시작 |
| POST | `/group-runs/{groupRunId}/finish` | 그룹런 종료 |
| GET | `/group-runs/{groupRunId}/live-status` | 참가자 진행 현황 조회 |
| GET | `/group-runs/{groupRunId}/result` | 그룹런 결과 조회 |

### 10.1 그룹런 생성

`POST /group-runs`

```json
{
  "title": "토요일 한강 5km",
  "description": "초보자 환영",
  "scheduledAt": "2026-10-17T00:00:00Z",
  "meetingLocation": {
    "name": "여의나루역 2번 출구",
    "latitude": 37.527,
    "longitude": 126.932
  },
  "targetDistanceMeters": 5000,
  "targetPaceSecondsPerKm": 390,
  "capacity": 10,
  "visibility": "PUBLIC"
}
```

### 10.2 그룹런 실시간 상태

```json
{
  "data": {
    "groupRunId": "uuid",
    "recommendedGroupPaceSecondsPerKm": 395,
    "participants": [
      {
        "userId": "uuid",
        "nickname": "runner1",
        "distanceMeters": 2200,
        "currentPaceSecondsPerKm": 400,
        "progressPercent": 44,
        "guidanceBpm": 166
      }
    ],
    "updatedAt": "2026-10-14T01:30:10Z"
  }
}
```

## 11. 러닝 메이트·크루 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| GET | `/running-mates/recommendations` | 유사 페이스·수준·목표 기반 메이트 추천 |
| GET | `/users/search` | 조건 기반 러닝 사용자 탐색 |
| POST | `/crews` | 크루 생성 |
| GET | `/crews` | 크루 검색·목록 조회 |
| GET | `/crews/{crewId}` | 크루 상세 조회 |
| POST | `/crews/{crewId}/join-requests` | 크루 가입 신청 |
| DELETE | `/crews/{crewId}/join-requests/me` | 가입 신청 취소 |
| GET | `/crews/{crewId}/join-requests` | 관리자의 가입 신청 목록 조회 |
| PATCH | `/crews/{crewId}/join-requests/{requestId}` | 가입 신청 승인·거절 |

### 11.1 러닝 메이트 추천 조건

`GET /running-mates/recommendations?cursor={cursor}&limit=20`

```json
{
  "data": [
    {
      "userId": "uuid",
      "nickname": "runner2",
      "runningLevel": "INTERMEDIATE",
      "typicalPaceSecondsPerKm": 365,
      "commonGoals": ["10KM_FINISH"],
      "matchReasons": ["평균 페이스 유사", "목표 거리 일치"]
    }
  ]
}
```

공개 가능한 프로필 필드만 응답에 포함한다.

## 12. 커뮤니티 API

| Method | Endpoint | 설명 |
| --- | --- | --- |
| POST | `/posts` | 게시물 작성 |
| GET | `/posts` | 게시물 목록 조회 |
| GET | `/posts/{postId}` | 게시물 상세 조회 |
| PATCH | `/posts/{postId}` | 게시물 수정 |
| DELETE | `/posts/{postId}` | 게시물 삭제 |
| POST | `/posts/{postId}/comments` | 댓글 작성 |
| GET | `/posts/{postId}/comments` | 댓글 목록 조회 |
| PATCH | `/comments/{commentId}` | 댓글 수정 |
| DELETE | `/comments/{commentId}` | 댓글 삭제 |
| PUT | `/posts/{postId}/reaction` | 게시물 반응 등록·변경 |
| DELETE | `/posts/{postId}/reaction` | 게시물 반응 취소 |

### 12.1 게시물 작성

`POST /posts`

```json
{
  "category": "RUNNING_EXPERIENCE",
  "title": "첫 10km 완주 후기",
  "content": "오늘 목표를 달성했습니다.",
  "sharedCourseId": null,
  "sharedRunId": "uuid",
  "visibility": "PUBLIC"
}
```

공유 코스와 러닝 기록은 작성자가 소유하고 공개를 허용한 리소스만 첨부할 수 있다.

## 13. WebSocket 실시간 API

### 13.1 연결

```text
GET /ws/v1?accessToken={token}
```

실제 운영 환경에서는 URL에 토큰을 노출하지 않는 인증 방식으로 변경할 수 있다.

### 13.2 공통 메시지 형식

```json
{
  "event": "run.telemetry.publish",
  "eventId": "uuid",
  "occurredAt": "2026-10-14T01:30:10Z",
  "data": {}
}
```

### 13.3 클라이언트 → 서버 이벤트

| 이벤트 | 설명 | 주요 데이터 |
| --- | --- | --- |
| `run.telemetry.publish` | 러닝 중 센서 데이터 전송 | `runId`, `sequence`, `measuredAt`, 센서 값 |
| `run.status.change` | 일시정지·재개·종료 요청 | `runId`, `status` |
| `group-run.subscribe` | 그룹런 실시간 채널 구독 | `groupRunId` |
| `group-run.unsubscribe` | 그룹런 채널 구독 해제 | `groupRunId` |

### 13.4 서버 → 클라이언트 이벤트

| 이벤트 | 설명 | 주요 데이터 |
| --- | --- | --- |
| `run.guidance.updated` | 개인 페이스·BPM 가이드 갱신 | `runId`, 목표 페이스, BPM, 안내 메시지 |
| `run.state-alert.created` | 오버페이스·부담·이상 패턴 알림 | `runId`, 알림 유형, 심각도, 메시지 |
| `run.prediction.updated` | 예상 완주 기록·달성 가능성 갱신 | `runId`, 예상 기록, 가능성 |
| `group-run.progress.updated` | 그룹원 진행 현황 갱신 | `groupRunId`, 참가자별 거리·페이스·진행률 |
| `group-run.pace.updated` | 공동 페이스 및 개인 BPM 변경 | `groupRunId`, 공동 페이스, 참가자별 BPM |
| `group-run.gap.detected` | 참가자 간 격차 알림 | `groupRunId`, 대상 참가자, 안내 메시지 |

## 14. 주요 열거형

| 이름 | 값 |
| --- | --- |
| `RunningLevel` | `BEGINNER`, `INTERMEDIATE`, `ADVANCED` |
| `RunStatus` | `READY`, `RUNNING`, `PAUSED`, `FINISHED`, `CANCELED` |
| `GroupRunStatus` | `RECRUITING`, `READY`, `RUNNING`, `FINISHED`, `CANCELED` |
| `Visibility` | `PUBLIC`, `CREW_ONLY`, `PRIVATE` |
| `ReadinessLevel` | `REST`, `LIGHT`, `READY`, `HIGH` |
| `EnvironmentType` | `PARK`, `RIVERSIDE`, `URBAN`, `TRACK`, `TRAIL` |
| `RoadType` | `PEDESTRIAN_PATH`, `RUNNING_TRACK`, `SIDEWALK`, `TRAIL` |
| `ReactionType` | `LIKE` |

열거형 명칭과 단계 수는 화면 기획과 정책 확정 후 조정할 수 있다.

## 15. 요구사항 추적

| 요구사항 영역 | API 영역 |
| --- | --- |
| 사용자 및 러닝 프로필 | `/users/me`, `/users/me/running-profile`, `/users/me/running-goal` |
| AI 운동 준비도 | `/watch/health-data/batches`, `/readiness` |
| AI 코스 추천·생성 | `/course-recommendation-requests`, `/courses` |
| AI 페이스 분석·예측 | `/pace-strategies`, `/runs/{runId}/pace-strategy` |
| 실시간 운동 상태 분석 | 러닝 telemetry API, `run.state-alert.created` |
| 개인화 BPM | 페이스 전략 API, `run.guidance.updated` |
| 러닝 기록 분석 | `/runs`, `/runs/{runId}/analysis` |
| 그룹런 및 그룹 페이스 | `/group-runs`, 그룹런 WebSocket 이벤트 |
| Galaxy Watch 연동 | `/watch`, 러닝 telemetry API |
| 러닝 메이트·크루 | `/running-mates`, `/crews`, 공개 `/group-runs` |
| 러닝 커뮤니티 | `/posts`, `/comments` |

## 16. 검토 후 확정이 필요한 항목

1. Galaxy Watch 연동 SDK 및 실제 제공 데이터 필드
2. 워치가 모바일 앱을 거치지 않고 서버와 직접 통신해야 하는지 여부
3. 실시간 센서 데이터의 수집·전송 주기
4. 지도·경로·고도·안전 데이터 제공자
5. 자체 로그인과 소셜 로그인 지원 범위
6. 코스 및 AI 분석 요청의 동기·비동기 처리 방식
7. 그룹런 참여 승인 방식과 크루 권한 체계
8. 위치·건강·러닝 기록의 공개 범위와 보관 정책
9. 준비도 점수, 목표 달성 가능성 및 페이스 조정 결과의 표현 방식
10. 이미지 업로드 기능과 저장 방식
