# API 명세 — 커뮤니티

[API 명세 색인](./README.md)으로 돌아가기. 공통 규약은 [README.md](./README.md#공통-규약)를 따른다.

| ID | 이름 | Method | Endpoint | 단계 | 인증 |
|---|---|---|---|---|---|
| [CMT01](#cmt01-게시물-작성) | 게시물 작성 | POST | `/posts` | 1차 MVP | 회원 |
| [CMT02](#cmt02-게시물-목록) | 게시물 목록 | GET | `/posts` | 1차 MVP | 회원 |
| [CMT03](#cmt03-게시물-상세) | 게시물 상세 | GET | `/posts/{postId}` | 1차 MVP | 회원 |
| [CMT04](#cmt04-게시물-수정) | 게시물 수정 | PATCH | `/posts/{postId}` | 1차 MVP | 회원 |
| [CMT05](#cmt05-게시물-삭제) | 게시물 삭제 | DELETE | `/posts/{postId}` | 1차 MVP | 회원 |
| [CMT06](#cmt06-댓글-목록) | 댓글 목록 | GET | `/posts/{postId}/comments` | 1차 MVP | 회원 |
| [CMT07](#cmt07-댓글-작성) | 댓글 작성 | POST | `/posts/{postId}/comments` | 1차 MVP | 회원 |
| [CMT08](#cmt08-댓글-수정) | 댓글 수정 | PATCH | `/comments/{commentId}` | 1차 MVP | 회원 |
| [CMT09](#cmt09-댓글-삭제) | 댓글 삭제 | DELETE | `/comments/{commentId}` | 1차 MVP | 회원 |
| [CMT10](#cmt10-반응-등록-변경) | 반응 등록·변경 | PUT | `/posts/{postId}/reactions/me` | 1차 MVP | 회원 |
| [CMT11](#cmt11-반응-취소) | 반응 취소 | DELETE | `/posts/{postId}/reactions/me` | 1차 MVP | 회원 |

## CMT01 게시물 작성

`POST` `/api/v1/posts`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

일반 게시글·러닝 기록·코스 공유 구분, 연결 리소스 소유권 확인.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postType` | string (제안) | O | GENERAL/RUNNING_RECORD/COURSE |
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |

```json
{
  "postType": "GENERAL",
  "body": "오늘 5km를 달렸어요."
}
```

### Response

`201 Created (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `postType` | string (제안) | X | GENERAL/RUNNING_RECORD/COURSE |
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `authorId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `createdAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 RESOURCE_PRIVATE`
- `422 INVALID_POST`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 일반 게시글·러닝 기록·코스 공유 구분, 연결 리소스 소유권 확인.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정

## CMT02 게시물 목록

`GET` `/api/v1/posts`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

삭제된 게시물 제외, 연결 기록 비공개 시 접근 제한.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

없음

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postType` | string (제안) | X | GENERAL/RUNNING_RECORD/COURSE |
| `cursor` | string / object (확인 필요) | X | 서버 발급 불투명 페이지 커서 |
| `limit` | number | X | 조회 결과 최대 개수(최대값 미정) |

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `400 INVALID_FILTER`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 삭제된 게시물 제외, 연결 기록 비공개 시 접근 제한.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT03 게시물 상세

`GET` `/api/v1/posts/{postId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

연결 기록·코스의 현재 공개 범위 검사.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `postType` | string (제안) | X | GENERAL/RUNNING_RECORD/COURSE |
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `authorId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `sessionId` | string (UUID) | X | 러닝 세션 UUID |
| `courseId` | string (UUID) | X | 선택한 코스 식별자. 개인·그룹 자유러닝은 null/생략 가능 |
| `createdAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `reactionCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `commentCount` | number | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `myReaction` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 POST_NOT_FOUND`
- `403 LINKED_RESOURCE_PRIVATE`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 연결 기록·코스의 현재 공개 범위 검사.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT04 게시물 수정

`PATCH` `/api/v1/posts/{postId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 글만 수정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `title` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_AUTHOR`
- `404 POST_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 본인 글만 수정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT05 게시물 삭제

`DELETE` `/api/v1/posts/{postId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

soft delete.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `success` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `deletedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_AUTHOR`
- `404 POST_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- soft delete.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT06 댓글 목록

`GET` `/api/v1/posts/{postId}/comments`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

삭제 댓글 제외.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `cursor` | string / object (확인 필요) | X | 서버 발급 불투명 페이지 커서 |
| `limit` | number | X | 조회 결과 최대 개수(최대값 미정) |

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `items` | array | X | 수집된 이벤트/측정 배치 목록. 상세 타입별 구성 미정 |
| `page` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 POST_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 삭제 댓글 제외.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT07 댓글 작성

`POST` `/api/v1/posts/{postId}/comments`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

공백만 있는 댓글 거부.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `body` | string / object (확인 필요) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{
  "body": "오늘 5km를 달렸어요."
}
```

### Response

`201 Created (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `postId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `authorId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `createdAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `422 EMPTY_COMMENT`
- `404 POST_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 공백만 있는 댓글 거부.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT08 댓글 수정

`PATCH` `/api/v1/comments/{commentId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

본인 댓글만 수정.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `commentId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `body` | string / object (확인 필요) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

```json
{
  "body": "오늘 5km를 달렸어요."
}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `id` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `body` | string / object (확인 필요) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `updatedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_AUTHOR`
- `404 COMMENT_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 본인 댓글만 수정.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT09 댓글 삭제

`DELETE` `/api/v1/comments/{commentId}`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

soft delete.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `commentId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `success` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `deletedAt` | string (ISO 8601) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `403 NOT_AUTHOR`
- `404 COMMENT_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- soft delete.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT10 반응 등록·변경

`PUT` `/api/v1/posts/{postId}/reactions/me`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

사용자당 게시물 반응 1개, LIKE 타입.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `reactionType` | string (제안) | O | LIKE |

```json
{
  "reactionType": "LIKE"
}
```

### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `userId` | string (UUID) | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |
| `reactionType` | string (제안) | X | LIKE |

### 오류 응답

- `404 POST_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 사용자당 게시물 반응 1개, LIKE 타입.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정


## CMT11 반응 취소

`DELETE` `/api/v1/posts/{postId}/reactions/me`

| 항목 | 값 |
|---|---|
| 단계 | 1차 MVP |
| 인증 | 회원 |
| 관련 요구사항 | COM-001~004 |
| 미정 사항 | 있음 |
| 비고 | API 요청/응답 필드와 값 제한은 검토용 제안 |

### 설명

기존 반응 없어도 성공 가능한 멱등 처리.

### 인증 및 권한

- 로그인 사용자 본인 또는 서비스 리소스 접근 권한 검사.
- 건강정보·실시간 위치·타인 기록 조회 시 동의 상태 및 공개 범위가 우선한다.

### Path Parameters

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `postId` | string (UUID) | O | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### Query Parameters

없음

### Request Body

없음


### Response

`200 OK (제안)`

```json
{}
```

응답 필드 정의(상세 객체는 미정 정책 확정 후 보완):

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `reacted` | boolean | X | ERD 및 화면 요구사항을 기준으로 확정 필요 |

### 오류 응답

- `404 POST_NOT_FOUND`
- 공통 인증 오류 `401 UNAUTHORIZED`, 권한 오류 `403 FORBIDDEN`, 요청 형식 오류 `400 VALIDATION_ERROR` (해당 시).

### 처리 규칙

- 기존 반응 없어도 성공 가능한 멱등 처리.
- 사용자 소유권·그룹 참가 권한·상태 전이·재요청 여부를 검증한다(적용 범위는 API별로 결정).
- 예시는 **명세 구조를 보여주는 가상 값**이며, 확정되지 않은 제한·동기화 주기·AI 호출 주기를 의미하지 않는다.

### 상태값

- PUBLIC / PRIVATE 또는 기능별 ERD CHECK 값, 해당 없으면 별도 상태 없음.

### 미정 사항

- [ ] 요청·응답의 세부 필드 타입, 허용 범위, nullable 규칙 및 실제 JSON 구조 검토
- [ ] HTTP 성공 코드 및 각 예외의 오류 코드 최종 확정
- [ ] 접근 권한과 데이터 정합성의 구체적인 처리 조건 확정
