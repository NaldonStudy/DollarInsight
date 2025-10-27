# MongoDB 변경사항 요약

## 변경일: 2025-10-27
## 작성자: B205팀

---

## 주요 변경사항

### ✅ 완료된 작업

1. **docker-compose.yml**
   - ElasticSearch 서비스 제거
   - MongoDB 서비스 추가
   - 모든 서비스의 ElasticSearch 의존성 → MongoDB로 변경

2. **env.template**
   - ElasticSearch 환경변수 제거
   - MongoDB 환경변수 추가 (MONGO_USER, MONGO_PASSWORD)

3. **문서 작성**
   - README.MD: 프로젝트 전체 가이드
   - MONGODB_MIGRATION_GUIDE.md: 완벽한 마이그레이션 가이드

---

## 변경 이유

- 메모리 최적화 (2GB → 500MB)
- 개발 복잡도 감소
- 뉴스 데이터 저장/조회 용도에 적합

---

## 다음 단계 (TODO)

### Backend
- [ ] build.gradle 의존성 변경
- [ ] application.yml MongoDB 설정
- [ ] Entity & Repository 구현

### AI Service  
- [ ] requirements.txt 업데이트
- [ ] MongoDB 연결 구현
- [ ] CRUD 함수 작성

---

자세한 내용은 **MONGODB_MIGRATION_GUIDE.md** 참조
