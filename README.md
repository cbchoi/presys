# Presys - Presentation System

> Reveal.js 기반 범용 프레젠테이션 관리 시스템

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](package.json)
[![Node](https://img.shields.io/badge/node-%3E%3D20.19.0-brightgreen.svg)](package.json)
[![Reveal.js](https://img.shields.io/badge/reveal.js-5.2.1-orange.svg)](https://revealjs.com/)
[![Vite](https://img.shields.io/badge/vite-7.1.8-646cff.svg)](https://vitejs.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 📖 소개

Presys는 마크다운 기반의 범용 프레젠테이션 관리 시스템입니다. 강의, 세미나, 발표 등 다양한 목적의 슬라이드를 효율적으로 작성하고 PDF로 생성할 수 있습니다.

### ✨ 주요 기능

- 📝 **마크다운 기반**: 간편한 텍스트 편집으로 프레젠테이션 작성
- 🎨 **테마 시스템**: 한글 폰트 지원 및 PDF 최적화
- 📄 **PDF 생성**: Puppeteer 기반 고품질 PDF 자동 생성
- 🔄 **자동화**: 콘텐츠 추가 시 자동 감지 및 네비게이션 생성
- 🌐 **크로스 플랫폼**: Windows, Linux, macOS 지원
- 📦 **8가지 템플릿**: 표지, 섹션, 코드, 이미지 등 다양한 슬라이드 템플릿

## 🚀 빠른 시작

### 1. 시스템 요구사항

- **Node.js**: 20.19 이상
- **Python**: 3.9 이상
- **npm**: 최신 버전 권장

### 2. 설치

```bash
# 저장소 클론
git clone https://github.com/yourusername/presys.git
cd presys

# 의존성 설치
npm install

# 환경 설정 (Linux/Mac)
./scripts/setup-linux.sh

# 환경 설정 (Windows)
scripts\setup-windows.bat
```

### 3. 개발 서버 시작

```bash
# 개발 서버 실행
npm run dev

# 브라우저에서 http://localhost:5173 접속
```

## 📂 프로젝트 구조

```
presys/
├── .claude/                    # 프로젝트 문서
│   ├── instruction.system.md      # 시스템 관리자용 가이드
│   ├── specification.system.md    # 시스템 기술 명세
│   ├── acceptance.system.md       # 시스템 테스트 명세
│   ├── instruction.contents.md    # 콘텐츠 제작자용 가이드 (작성 예정)
│   ├── specification.contents.md  # 콘텐츠 기술 명세 (작성 예정)
│   └── acceptance.contents.md     # 콘텐츠 테스트 명세 (작성 예정)
├── slides/                     # 프레젠테이션 콘텐츠
│   ├── index.html                 # SPA 엔트리 포인트
│   └── css/                       # 스타일시트
├── template/                   # 슬라이드 템플릿 (8종)
│   ├── cover.md                   # 표지 슬라이드
│   ├── section-title.md           # 섹션 제목
│   ├── overview.md                # 목차
│   ├── code-1column.md            # 코드 (1열)
│   ├── code-2column.md            # 코드 (2열)
│   ├── image-2column.md           # 이미지 (2열)
│   ├── dual-image.md              # 이중 이미지
│   └── general-content.md         # 일반 콘텐츠
├── tools/                      # 개발 도구
│   ├── bootstrap.py               # 동적 인덱스 생성
│   ├── export-pdf.mjs             # PDF 생성 엔진
│   └── server.js                  # 프로덕션 서버
├── scripts/                    # 실행 스크립트
│   ├── setup-linux.sh             # Linux/Mac 환경 설정
│   ├── start-dev.sh/.bat          # 개발 서버 시작
│   ├── stop-dev.sh/.bat           # 개발 서버 종료
│   └── export-pdf.sh/.bat         # PDF 생성
├── config/                     # 설정 파일
│   └── vite.config.ts             # Vite 빌드 설정
└── package.json                # 프로젝트 메타데이터
```

## 📝 콘텐츠 작성하기

### 1단계: 토픽 폴더 생성

```bash
# slides 디렉토리에 새 토픽 폴더 생성
mkdir slides/my-presentation
cd slides/my-presentation
```

### 2단계: 마크다운 파일 작성

**`summary.md`** - 토픽 메타데이터:
```markdown
# My Presentation

## 학습 목표
- 목표 1
- 목표 2

## 주요 내용
- 내용 1
- 내용 2
```

**`slides.md`** - 슬라이드 콘텐츠:
```markdown
# My Presentation
> 부제목

---

## Introduction

내용 작성...

---

## Main Content

더 많은 내용...
```

### 3단계: 인덱스 생성

```bash
# 프로젝트 루트에서 실행
python3 tools/bootstrap.py
# 또는
npm run bootstrap
```

### 4단계: 확인

```bash
# 개발 서버에서 확인
npm run dev

# 브라우저에서 http://localhost:5173 접속
```

## 🎨 템플릿 사용하기

`template/` 디렉토리의 템플릿을 복사하여 사용하세요:

```bash
# 표지 슬라이드 템플릿 복사
cp template/cover.md slides/my-presentation/01-cover.md

# 코드 슬라이드 템플릿 복사
cp template/code-2column.md slides/my-presentation/02-code.md
```

### 사용 가능한 템플릿

| 템플릿 | 용도 | 파일명 |
|--------|------|--------|
| 📄 표지 | 프레젠테이션 시작 페이지 | `cover.md` |
| 📑 섹션 제목 | 섹션 구분 | `section-title.md` |
| 📋 목차 | 전체 내용 개요 | `overview.md` |
| 💻 코드 1열 | 코드 예제 (전체) | `code-1column.md` |
| 💻 코드 2열 | 코드 + 설명 | `code-2column.md` |
| 🖼️ 이미지 2열 | 이미지 + 설명 | `image-2column.md` |
| 🖼️ 이중 이미지 | 비교 이미지 | `dual-image.md` |
| 📝 일반 | 텍스트 중심 | `general-content.md` |

## 📄 PDF 생성

### 개별 토픽 PDF 생성

```bash
# Linux/Mac
./scripts/export-pdf.sh my-presentation

# Windows
scripts\export-pdf.bat my-presentation

# npm 스크립트 사용
npm run export-pdf -- my-presentation
```

### 모든 토픽 PDF 생성

```bash
node tools/export-pdf.mjs --all
```

생성된 PDF는 `pdf-exports/` 디렉토리에 저장됩니다.

## 🛠️ 개발

### 사용 가능한 명령어

```bash
# 개발 서버 시작
npm run dev

# 프로덕션 빌드
npm run build

# 프로덕션 미리보기
npm run preview

# PDF 생성
npm run export-pdf -- <topic-name>

# 인덱스 재생성
npm run bootstrap

# 프로덕션 서버 시작
npm run start
```

### 기술 스택

| 카테고리 | 기술 | 버전 |
|----------|------|------|
| **Frontend** | Reveal.js | 5.2.1 |
| **Build Tool** | Vite | 7.1.8 |
| **Runtime** | Node.js | 20.19+ |
| **PDF Engine** | Puppeteer | 24.23.0 |
| **CLI Tool** | Commander | 14.0.1 |
| **Server** | Express | 5.1.0 |
| **Scripting** | Python | 3.9+ |

## 📚 문서

### 시스템 관리자 / 개발자용

- **[instruction.system.md](.claude/instruction.system.md)** - 시스템 설치 및 운영 가이드
- **[specification.system.md](.claude/specification.system.md)** - 기술 아키텍처 및 구현 명세
- **[acceptance.system.md](.claude/acceptance.system.md)** - 시스템 기능 테스트

### 콘텐츠 제작자용 (작성 예정)

> ⚠️ **안내**: 아래 문서는 콘텐츠를 추가하는 사용자가 작성할 예정입니다.

- **`instruction.contents.md`** (미작성)
  - 콘텐츠 작성 및 관리 가이드
  - 마크다운 작성 규칙
  - 템플릿 활용 방법

- **`specification.contents.md`** (미작성)
  - 콘텐츠 구조 및 품질 기준
  - 메타데이터 표준
  - 스타일 가이드

- **`acceptance.contents.md`** (미작성)
  - 콘텐츠 품질 테스트
  - 검증 체크리스트
  - 리뷰 프로세스

### 문서 작성 가이드

콘텐츠 관련 문서를 작성할 때는 다음 구조를 참고하세요:

1. **instruction.contents.md**: 콘텐츠 제작자가 따라야 할 단계별 가이드
2. **specification.contents.md**: 콘텐츠 품질 기준 및 표준 정의
3. **acceptance.contents.md**: 콘텐츠 검증 및 승인 기준

## 🚢 배포

### Docker 배포

```dockerfile
FROM node:20-alpine

# 시스템 의존성
RUN apk add --no-cache \
    chromium \
    python3 \
    py3-pip

# 환경 변수
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "run", "start"]
```

### 전통적 배포

```bash
# 빌드
npm run build

# 정적 파일 서버 설정 (Nginx/Apache/Express)
# dist/ 디렉토리를 웹 서버로 서빙

# PM2로 프로세스 관리
pm2 start tools/server.js --name presys
```

## 🔧 문제 해결

### 일반적인 문제

**Q: PDF 생성이 실패합니다.**
```bash
# Chrome 의존성 설치 (Linux)
sudo apt install -y libnss3 libatk-bridge2.0-0 libdrm2 \
  libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libasound2

# 개발 서버가 실행 중인지 확인
npm run dev
```

**Q: 한글이 깨져서 보입니다.**
```bash
# 시스템 한글 폰트 설치 확인
# custom_theme.css에서 폰트 설정 확인
```

**Q: Vite 7.x 업그레이드 후 오류가 발생합니다.**
```bash
# node_modules 삭제 후 재설치
rm -rf node_modules package-lock.json
npm install

# Node.js 버전 확인
node --version  # 20.19 이상 필요
```

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### 기여 가이드라인

- 시스템 관련 개선: `specification.system.md` 참조
- 콘텐츠 템플릿 추가: `template/` 디렉토리에 추가
- 문서 개선: `.claude/` 디렉토리 문서 업데이트

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사의 말

- [Reveal.js](https://revealjs.com/) - 프레젠테이션 프레임워크
- [Vite](https://vitejs.dev/) - 빌드 도구
- [Puppeteer](https://pptr.dev/) - PDF 생성 엔진

## 📮 문의

프로젝트에 대한 질문이나 제안사항이 있으시면 이슈 트래커를 이용해 주세요.

---

**Made with ❤️ by Presys Contributors**
