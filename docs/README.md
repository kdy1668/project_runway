# RunWay 문서 안내

RunWay의 제품 범위, 기술 결정, 인터페이스 계약, 실험 결과와 개발 운영 문서를 목적별로 관리한다. 새 문서를 추가하거나 기존 문서를 이동할 때는 이 문서의 분류와 링크를 함께 갱신한다.

## 먼저 읽을 문서

1. [1차 MVP 기능](requirements/mvp.md)에서 구현할 기능 범위를 확인한다.
2. [상세 요구사항](requirements/detailed-requirements.md)에서 1·2차 MVP 요구사항 ID와 세부 조건을 확인한다.
3. [기술 결정 기록](adr/README.md)에서 현재 채택되거나 제안된 기술 결정을 확인한다.
4. [데이터 모델](architecture/data-model/README.md)에서 ERD 스키마를 확인하고, [1차 MVP API 명세](api/README.md)에서 인터페이스 초안의 현재 상태를 확인한다.
5. 작업 방식은 [개발 운영 문서](development/README.md), AI 작업 범위는 [AI 개발 문서](ai/README.md)를 따른다.

`requirements/mvp.md`와 `requirements/detailed-requirements.md`는 동일한 1차 MVP 범위를 유지해야 한다. 두 문서가 충돌하면 임의로 우선순위를 정하지 않고 제품 결정을 확인해 함께 수정한다. 데이터 모델 내부가 충돌하면 `architecture/data-model/schema.sql`을 우선하며, API 검토안은 확정된 계약으로 간주하지 않는다.

## 문서 구조

| 위치 | 역할 | 현재 기준 상태 |
| --- | --- | --- |
| [`requirements/`](requirements/) | MVP 기능 범위와 상세 요구사항 | `mvp.md`가 제품 범위의 기준 문서 |
| [`architecture/`](architecture/) | 시스템 개요와 데이터 모델 | `data-model/schema.sql`이 데이터 모델 기준 원본 |
| [`api/`](api/) | 서비스 및 실험용 인터페이스 계약 | 문서별 상태를 확인 |
| [`adr/`](adr/) | 기술 선택의 배경·대안·결과 | ADR 상태와 대체 관계가 기준 |
| [`experiments/`](experiments/) | PoC 실행 방법과 검증 범위 | 제품 계약이 아닌 실험 기록 |
| [`development/`](development/) | Git·Jira·GitLab 운영 방법 | 팀 개발 절차의 기준 문서 |
| [`ai/`](ai/) | 개발용 AI 도구 조사와 검증 기록 | 서비스 내부 AI 설계와 분리 |

## 상태와 관리 원칙

- 각 문서 상단에 상태, 기준일 또는 관련 Jira를 기록한다.
- 같은 내용을 여러 문서에 복사하지 않고 기준 문서를 링크한다.
- 아키텍처와 핵심 기술 선택은 [ADR 운영 규칙](adr/README.md)에 따라 기록한다.
- 실험 결과는 실제로 확인한 범위와 미검증 범위를 구분한다.
- 파일을 이동하거나 이름을 바꾸면 저장소 내부 링크와 자동화 스크립트의 안내 경로도 함께 수정한다.
- 인증정보가 포함된 `.env`와 `.env.*`는 문서, 로그, 예시에 포함하지 않는다.
