# HCI/HMI 강의 교재 (Typst)

반도체 장비를 위한 Human-Computer Interaction과 Human-Machine Interface 설계 및 구현 강의 교재입니다.

## 목차

### Part 1: C# WPF (Week 1-5)
- Week 1: HCI/HMI 이론 및 반도체 장비 적용
- Week 2: C# WPF 기초 및 반도체 HMI 프로젝트 구조
- Week 3: C# WPF 실시간 데이터 처리 및 차트
- Week 4: C# WPF 고급 UI 컨트롤 및 커스텀 컨트롤
- Week 5: C# WPF 테스트 및 배포

### Part 2: Python PySide6 (Week 6-9)
- Week 6: Python PySide6 기초 및 Qt Designer
- Week 7: Python 실시간 데이터 처리 및 PyQtGraph
- Week 8: Python 고급 기능 및 통신 (TCP, OPC UA, Modbus)
- Week 9: Python 패키징 및 배포

### Part 3: ImGui C++ (Week 10-13)
- Week 10: ImGui C++ 기초 및 OpenGL 통합
- Week 11: ImGui 고급 위젯 및 ImPlot
- Week 12: ImGui 스레딩, 통신 및 최적화
- Week 13: ImGui 통합 프로젝트

## 빌드 방법

### 요구사항
- Typst 0.10.0 이상

### 설치
```bash
# Linux/Mac (Homebrew)
brew install typst

# Linux (Cargo)
cargo install --git https://github.com/typst/typst

# Windows (Scoop)
scoop install typst
```

### PDF 생성
```bash
# 전체 교재 생성
typst compile main.typ output.pdf

# Watch 모드 (자동 재컴파일)
typst watch main.typ output.pdf
```

### 개별 챕터 컴파일
```bash
# 특정 챕터만 컴파일하려면 임시 파일 생성
echo '#include "chapters/week01-hci-hmi-theory.typ"' > temp.typ
typst compile temp.typ week01.pdf
```

## 폰트 설정

Typst는 한글 표시를 위해 "Noto Sans CJK KR" 폰트를 사용합니다.

### 폰트 설치
```bash
# Ubuntu/Debian
sudo apt install fonts-noto-cjk

# macOS
brew tap homebrew/cask-fonts
brew install --cask font-noto-sans-cjk-kr

# Windows
# https://fonts.google.com/noto/specimen/Noto+Sans+KR 에서 다운로드
```

## 프로젝트 구조

```
typst/
├── main.typ                 # 메인 파일
├── chapters/                # 챕터 파일들
│   ├── week01-hci-hmi-theory.typ
│   ├── week02-csharp-wpf-basics.typ
│   ├── week03-csharp-realtime-data.typ
│   ├── week04-csharp-advanced-ui.typ
│   ├── week05-csharp-test-deploy.typ
│   ├── week06-python-pyside6-basics.typ
│   ├── week07-python-realtime-data.typ
│   ├── week08-python-advanced-features.typ
│   ├── week09-python-deployment.typ
│   ├── week10-imgui-basics.typ
│   ├── week11-imgui-advanced.typ
│   ├── week12-imgui-advanced-features.typ
│   └── week13-imgui-integrated-project.typ
└── README.md               # 이 파일
```

## 기술 스택

본 교재에서 다루는 주요 기술:

### C# WPF
- C# 11, .NET 8
- WPF, XAML
- MVVM 패턴
- Reactive Extensions (Rx)
- LiveCharts2

### Python PySide6
- Python 3.11+
- PySide6 (Qt6)
- PyQtGraph
- Signal/Slot
- TCP, OPC UA, Modbus

### ImGui C++
- C++20
- ImGui
- ImPlot
- OpenGL, GLFW
- Asio
- Multi-threading

## 학습 목표

이 교재를 통해 다음을 학습할 수 있습니다:

1. **HCI 이론**: Miller's Law, Fitts' Law, 정보처리 모델, 신호탐지이론
2. **SEMI 표준**: SEMI E95 반도체 제조 장비 HMI 표준
3. **실무 스킬**: 3가지 주요 HMI 프레임워크 (WPF, PySide6, ImGui)
4. **실시간 시스템**: 데이터 수집, 차트, 알람 시스템
5. **통신 프로토콜**: TCP/IP, OPC UA, Modbus
6. **소프트웨어 공학**: 테스트, 배포, 문서화

## 대상 독자

- 반도체 장비 소프트웨어 개발자
- HMI/SCADA 설계자
- 산업용 UI/UX 엔지니어
- 실시간 시스템 개발자

## 라이선스

이 교재는 교육 목적으로 작성되었습니다.

## 기여

오탈자나 개선 사항이 있다면 이슈를 등록해 주세요.

## 참고 자료

- SEMI E95: Guide for Operator Interface in Semiconductor Manufacturing Equipment
- Human-Computer Interaction (Dix et al.)
- Microsoft WPF Documentation
- Qt Documentation
- Dear ImGui Documentation
