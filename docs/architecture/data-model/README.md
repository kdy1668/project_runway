# 데이터 모델 문서

확정된 ERD와 스키마 자료를 다음 형태로 관리한다.

- [`schema.sql`](schema.sql): PostgreSQL 15+ 및 PostGIS 3+ 기준 스키마 원본
- [`erd.md`](erd.md): 테이블 역할, 컬럼, 관계와 제약 설명
- `schema.dbml`, `erd.drawio` 또는 `erd.png`: 필요할 때 추가하는 시각화 자료

테이블·컬럼·관계·제약이 충돌하면 `schema.sql`을 우선한다. 설명 문서는 스키마 변경과 함께 갱신한다.
