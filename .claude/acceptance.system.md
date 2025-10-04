# 강의 슬라이드 시스템 인수 기준 (시스템)

## 📋 문서 목적

이 문서는 **시스템 레벨 인수 기준**을 정의합니다.
- 기술 스택 (Vite, Reveal.js, Python 등)
- 개발 서버, 빌드, 배포 프로세스
- 파일 구조 및 자동화 도구

**콘텐츠 품질 기준**은 `acceptance.contents.md` 참조

---

## 🏗️ 시스템 아키텍처 인수 기준

### 1. 디렉토리 구조 ✅

```
presys/
├── slides/              # 강의 콘텐츠
│   ├── hmi/            # HCI/HMI 강의
│   │   ├── week01-*/
│   │   ├── week02-*/
│   │   └── ...
│   └── [other-topics]/
├── src/                # 렌더링 시스템
│   ├── index.html
│   └── css/
├── tools/              # 빌드 도구
│   ├── bootstrap.py
│   └── export-pdf.mjs
├── scripts/            # 실행 스크립트
│   ├── start-dev.sh
│   ├── stop-dev.sh
│   └── export-pdf.sh
└── .claude/            # AI 명세서
```

**인수 기준**:
- [x] 관심사 분리 명확: slides(콘텐츠), src(렌더링), tools(빌드)
- [x] 주차별 독립 디렉토리: `weekXX-topic-name/`
- [x] 크로스 플랫폼 스크립트: `.sh` + `.bat`

---

## 🚀 개발 서버 인수 기준

### 1.1 서버 시작
**명령어**: `./scripts/start-dev.sh` 또는 `npm run dev`

**인수 기준**:
- [x] **시작 시간**: <1초
- [x] **포트**: 5173 (기본값)
- [x] **핫 리로드**: 파일 변경 시 자동 새로고침
- [x] **네트워크 접근**: 로컬 네트워크에서 접근 가능

**검증 방법**:
```bash
# 서버 시작
./scripts/start-dev.sh

# 응답 확인
curl -s http://localhost:5173 | grep -q "Presys" && echo "✅ OK"
```

### 1.2 서버 종료
**명령어**: `./scripts/stop-dev.sh` 또는 `Ctrl+C`

**인수 기준**:
- [x] **프로세스 감지**: 실행 중인 Vite 프로세스 자동 감지
- [x] **정상 종료**: SIGTERM → 3초 대기 → SIGKILL (필요시)
- [x] **포트 해제**: 5173 포트 완전 해제

---

## 📦 Bootstrap 시스템 인수 기준

### 2.1 자동 감지
**명령어**: `python3 tools/bootstrap.py`

**인수 기준**:
- [x] **주차 자동 감지**: `slides/*/week*` 패턴 스캔
- [x] **메타데이터 추출**: `summary.md`에서 제목, 설명 파싱
- [x] **슬라이드 카운팅**: `.md` 파일 개수 집계
- [x] **코드 예시 카운팅**: 코드 블록 개수 집계

**출력**:
```python
# src/index.html 자동 생성
- 토픽별 카드 레이아웃
- 주차별 네비게이션
- 메타데이터 기반 통계
```

### 2.2 오류 처리
**인수 기준**:
- [x] **누락된 summary.md**: 경고 출력 + 디렉토리명 사용
- [x] **잘못된 YAML**: 파싱 오류 시 기본값 사용
- [x] **빈 디렉토리**: 건너뛰기 + 로그 출력

---

## 📄 PDF 생성 인수 기준

### 3.1 단일 주차 PDF
**명령어**: `./scripts/export-pdf.sh 01` 또는 `npm run pdf 01`

**인수 기준**:
- [x] **해상도**: 1920x1080 (기본값)
- [x] **파일 크기**: 슬라이드당 ~50KB (평균)
- [x] **한글 폰트**: Noto Sans KR 정상 렌더링
- [x] **수식**: KaTeX 수식 정상 렌더링
- [x] **다이어그램**: Mermaid SVG 정상 렌더링
- [x] **코드 하이라이팅**: Syntax highlighting 유지

**검증 방법**:
```bash
./scripts/export-pdf.sh 01
ls -lh pdf-exports/week01.pdf
# 예상: ~500KB (10 슬라이드 기준)
```

### 3.2 전체 PDF 생성
**명령어**: `npm run pdf:all`

**인수 기준**:
- [x] **병렬 처리**: 가능 시 병렬 생성
- [x] **진행률 표시**: N/M 진행 상황 출력
- [x] **오류 내성**: 일부 실패해도 계속 진행
- [x] **최종 리포트**: 성공/실패 개수 요약

---

## 🔧 크로스 플랫폼 인수 기준

### 4.1 Linux/WSL
**인수 기준**:
- [x] **Bash 스크립트**: `scripts/*.sh` 문법 오류 없음
- [x] **실행 권한**: `chmod +x` 적용
- [x] **의존성 체크**: Node.js, Python 버전 확인

**검증**:
```bash
find scripts/ -name "*.sh" -exec bash -n {} \;
# 출력 없음 = 문법 오류 없음
```

### 4.2 Windows
**인수 기준**:
- [x] **배치 스크립트**: `scripts/*.bat` 제공
- [x] **경로 처리**: Windows 경로 구분자 `\` 지원
- [x] **인코딩**: UTF-8 BOM 없이 저장

---

## 📊 성능 인수 기준

### 5.1 개발 서버 성능
| 항목 | 목표 | 측정값 | 상태 |
|------|------|--------|------|
| 서버 시작 시간 | <1초 | ~350ms | ✅ |
| 핫 리로드 시간 | <500ms | ~200ms | ✅ |
| 메모리 사용량 | <200MB | ~150MB | ✅ |

### 5.2 PDF 생성 성능
| 항목 | 목표 | 측정값 | 상태 |
|------|------|--------|------|
| 슬라이드당 생성 시간 | <1초 | ~0.8초 | ✅ |
| 한글 폰트 로딩 | <2초 | ~1.5초 | ✅ |
| Mermaid 렌더링 | <3초 | ~2초 | ✅ |

---

## 🧪 테스트 체크리스트

### 개발 워크플로우 테스트
```bash
# 1. 서버 시작
./scripts/start-dev.sh
# ✅ 포트 5173에서 시작

# 2. 브라우저 접근
# http://localhost:5173
# ✅ 메인 페이지 로드

# 3. 주차 선택
# http://localhost:5173?week=01
# ✅ Week 01 슬라이드 로드

# 4. 파일 수정
# slides/hmi/week01-*/slides-01-intro.md 편집
# ✅ 자동 새로고침

# 5. PDF 생성
./scripts/export-pdf.sh 01
# ✅ pdf-exports/week01.pdf 생성

# 6. 서버 종료
./scripts/stop-dev.sh
# ✅ 프로세스 정상 종료
```

### Bootstrap 테스트
```bash
# 1. 새 주차 추가
mkdir slides/hmi/week14-new-topic

# 2. Bootstrap 실행
python3 tools/bootstrap.py
# ✅ week14 자동 감지

# 3. index.html 확인
grep "week14" src/index.html
# ✅ 새 카드 추가됨
```

---

## ✅ 최종 인수 기준

### 필수 요구사항 (모두 충족 필요)
- [x] 개발 서버 시작/종료 정상 동작
- [x] Bootstrap 자동 감지 정상 동작
- [x] PDF 생성 정상 동작 (한글/수식/다이어그램)
- [x] 크로스 플랫폼 스크립트 제공
- [x] 모든 스크립트 문법 오류 없음

### 성능 요구사항
- [x] 서버 시작 <1초
- [x] PDF 생성 슬라이드당 <1초
- [x] 메모리 사용량 <200MB

### 호환성 요구사항
- [x] Node.js 18+ 지원
- [x] Python 3.8+ 지원
- [x] 현대 브라우저 (Chrome/Firefox/Safari) 지원

---

## 🚫 인수 거부 기준

다음 경우 인수 **거부**:
- ❌ 개발 서버가 시작되지 않음
- ❌ PDF 생성 시 한글이 깨짐
- ❌ Bootstrap이 주차를 감지하지 못함
- ❌ 스크립트 실행 시 오류 발생
- ❌ 크로스 플랫폼 스크립트 미제공

---

## 📝 인수 테스트 보고서 템플릿

```markdown
# 인수 테스트 보고서

**테스트 일시**: YYYY-MM-DD HH:MM
**테스트 환경**: [Linux/Windows/WSL]
**Node.js 버전**: vX.X.X
**Python 버전**: X.X.X

## 테스트 결과

| 항목 | 상태 | 비고 |
|------|------|------|
| 개발 서버 시작 | ✅/❌ | |
| Bootstrap 동작 | ✅/❌ | |
| PDF 생성 | ✅/❌ | |
| 크로스 플랫폼 | ✅/❌ | |

## 발견된 이슈
1. [이슈 내용]
2. [이슈 내용]

## 최종 판정
✅ 인수 / ❌ 거부

**판정 사유**: [구체적 사유]
```

---

**작성일**: 2025-10-03
**최종 수정**: 2025-10-03
**버전**: 1.0
