= Week 9: Python 배포 및 패키징
== 학습 목표
본 챕터에서는 다음을 학습한다: + Python 배포 방식의 이론적 배경 이해
+ PyInstaller를 사용한 실행 파일 생성
+ 디자인 패턴을 활용한 배포 자동화
+ 크로스 플랫폼 배포 전략
+ 실전 배포 프로세스 구현
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *Python 프로젝트 구조*: 모듈, 패키지, `__init__.py`의 역할 이해
- *pip 사용법*: `pip install`, `pip freeze`, `requirements.txt` 작성
- *가상 환경*: venv 또는 conda 사용 경험
- *기본 Shell 명령어*: cd, ls, mkdir 등 터미널 사용
- *Python 기초*: 클래스, 함수, 예외 처리
- *권장사항*: Week 6-8 (Python PySide6) 학습 완료
== Python 배포의 역사와 언어 특징
=== Python 배포 방식의 발전
*초기 (1991-2000): *
- 소스 코드 직접 배포 (.py 파일)
- 사용자가 직접 Python 인터프리터 설치 필요
- Distutils (1998) 등장: 표준 배포 도구
*성장기 (2000-2010): *
- *setuptools* (2004): easy_install, egg 포맷
- *PyPI* (Python Package Index, 2003): 중앙 저장소
- *virtualenv* (2007): 독립적인 환경 구성
*현대 (2010-현재): *
- *pip* (2011): 표준 패키지 관리자
- *wheel* (2012): 바이너리 배포 포맷 (.whl)
- *PyInstaller* (2005, 활발한 개발 2010-): 독립 실행 파일
- *Poetry* (2018): 현대적인 의존성 관리
- *Docker* (2013): 컨테이너 기반 배포
=== Python 언어의 배포 특징
==== 인터프리터 언어의 특성
Python은 인터프리터 언어로, 실행 시 다음이 필요하다: ```
Python Application
  |
  v
Python Bytecode (.pyc)
  |
  v
Python Interpreter (python.exe)
  |
  v
Operating System
```
*장점*:
- 크로스 플랫폼 (같은 코드가 Windows/Linux/macOS에서 실행)
- 빠른 개발 및 디버깅
- 동적 타이핑, 리플렉션 등 유연한 기능
*단점*:
- 인터프리터 의존성 (사용자가 Python 설치 필요)
- 소스 코드 노출 위험
- C/C++보다 느린 실행 속도
==== 배포 방식 비교
#figure(table(columns: (auto, auto, auto, auto), align: left, [*방식*], [*장점*], [*단점*], [*사용 사례*], [소스 배포], [간단, 수정 용이], [인터프리터 필요, 노출], [오픈소스], [wheel], [빨른 설치, 바이너리], [인터프리터 필요], [라이브러리], [PyInstaller], [독립 실행, 배포 간편], [큰 크기 (50MB+)], [데스크톱 앱], [Docker], [환경 일관성], [Docker 필요, 큰 이미지], [서버 앱], ), caption: "Python 배포 방식 비교")
=== 반도체 HMI에서의 Python 배포 동향
==== 산업 현황
*채택 증가 추세*:
- Tokyo Electron: Python 기반 AI 최적화 도구
- Applied Materials: 데이터 분석 스크립트
- KLA: 검사 데이터 시각화
*배포 전략*:
- 내부 도구: 소스 배포 + 표준 Python 환경
- 고객 제공: PyInstaller로 독립 실행 파일
- 클라우드: Docker 컨테이너
==== 기술 트렌드
*현재 (2024): *
- PyInstaller/Nuitka를 통한 네이티브 배포
- Poetry/pipenv를 통한 의존성 관리 개선
- GitHub Actions/GitLab CI를 통한 자동 빌드
*미래 전망: *
- WebAssembly (WASM) 기반 배포
- Python 3.13의 GIL 제거로 성능 향상
- uv, rye 등 차세대 패키지 관리자
== Python 패키징 생태계 이론
=== Python Import System 심화
==== Import 메커니즘
Python의 import 시스템은 3단계로 동작한다.
*1. Finder (검색): *
```python
# sys.meta_path: Import Finder 리스트
import sys
print(sys.meta_path)
# [<class '_frozen_importlib.BuiltinImporter'>,
# <class '_frozen_importlib.FrozenImporter'>,
# <class '_frozen_importlib_external.PathFinder'>]
```
*Finder 종류: *
```
1. BuiltinImporter: 내장 모듈 (sys, math 등)
2. FrozenImporter: Frozen 모듈 (PyInstaller가 사용)
3. PathFinder: sys.path에서 검색
```
*2. Loader (로드): *
```python
# 모듈을 메모리에 로드
import importlib.util
spec = importlib.util.find_spec('numpy')
print(spec.loader)
# <_frozen_importlib_external.SourceFileLoader object>
```
*Loader 종류: *
```
- SourceFileLoader: .py 파일
- SourcelessFileLoader: .pyc 파일만
- ExtensionFileLoader: .pyd/.so (C 확장)
```
*3. Execution (실행): *
```python
# 모듈 코드 실행 및 sys.modules에 캐싱
import sys
# 첫 import
import numpy
print('numpy' in sys.modules) # True
# 두 번째 import는 캐시 사용
import numpy # sys.modules에서 즉시 반환
```
==== sys.path 우선순위
```
import 시 검색 순서: 1. sys.modules (이미 로드된 모듈 캐시)
  ↓ 없으면
2. Built-in modules (sys.builtin_module_names)
  ↓ 없으면
3. sys.path 순서대로: a. 현재 스크립트 디렉토리
  b. PYTHONPATH 환경 변수
  c. 표준 라이브러리 경로
  d. site-packages (pip 설치 경로)
```
*sys.path 확인: *
```python
import sys
import pprint
pprint.pprint(sys.path)
# ['/home/user/project', # 현재 디렉토리
# '/usr/lib/python311.zip', # 표준 라이브러리 (압축)
# '/usr/lib/python3.11', # 표준 라이브러리
# '/usr/lib/python3.11/lib-dynload', # 동적 로드 모듈
# '/home/user/venv/lib/python3.11/site-packages'] # pip 패키지
```
==== Bytecode 컴파일 과정
Python은 실행 시 소스 코드를 바이트코드로 컴파일한다.
*과정: *
```
1. .py 파일 읽기
  ↓
2. Lexical Analysis (어휘 분석)
  - 토큰 생성: KEYWORD, IDENTIFIER, OPERATOR, ...
  ↓
3. Parsing (구문 분석)
  - AST (Abstract Syntax Tree) 생성
  ↓
4. Compilation (컴파일)
  - Bytecode 생성 (CPython VM 명령어)
  ↓
5. .pyc 파일 저장 (__pycache__/ 디렉토리)
  ↓
6. Execution (실행)
  - CPython VM이 바이트코드 해석
```
*바이트코드 확인: *
```python
import dis
def add(a, b): return a + b
# 바이트코드 출력
dis.dis(add)
# 출력:
# 2  0 LOAD_FAST 0 (a)
# 2 LOAD_FAST 1 (b)
# 4 BINARY_ADD
# 6 RETURN_VALUE
```
*.pyc 파일 구조: *
```
.pyc 파일 포맷 (Python 3.11): ┌────────────────────────┐
│ Magic Number (4 bytes) │ ← Python 버전 식별 (3.11: 0x0a0d0000 + version)
├────────────────────────┤
│ Flags (4 bytes) │  ← 컴파일 옵션 (hash-based 등)
├────────────────────────┤
│ Timestamp (4 bytes) │  ← .py 파일 수정 시각
├────────────────────────┤
│ Source Size (4 bytes) │  ← .py 파일 크기
├────────────────────────┤
│ Marshalled Code Object │ ← 실제 바이트코드
└────────────────────────┘
```
*장점: *
- 재실행 시 컴파일 생략 (속도 향상)
- .pyc만 배포하면 소스 코드 보호 (완전하지 않음)
*단점: *
- Python 버전 의존 (3.10 .pyc ≠ 3.11 .pyc)
- 역컴파일 가능 (uncompyle6, decompyle3)
=== 가상 환경 이론
==== 가상 환경의 필요성
*문제 상황: *
```
시스템 Python (전역):
/usr/lib/python3.11/site-packages/
├─ numpy==1.24.0
├─ pandas==1.5.0
└─ scipy==1.10.0
프로젝트 A: numpy==1.20.0 필요
프로젝트 B: numpy==1.24.0 필요
→ 충돌! 하나의 Python 환경에서 두 버전 공존 불가
```
*해결책: 가상 환경*
```
각 프로젝트마다 독립된 site-packages: 프로젝트 A venv:
/home/user/projectA/venv/lib/python3.11/site-packages/
└─ numpy==1.20.0
프로젝트 B venv:
/home/user/projectB/venv/lib/python3.11/site-packages/
└─ numpy==1.24.0
→ 격리! 두 환경이 독립적으로 동작
```
==== venv 내부 구조
*생성 과정: *
```bash
python -m venv myenv
```
*디렉토리 구조: *
```
myenv/
├── bin/ (Linux/macOS) 또는 Scripts/ (Windows)
│ ├── python # Python 인터프리터 심볼릭 링크
│ ├── pip # pip 실행 파일
│ └── activate # 환경 활성화 스크립트
├── lib/
│ └── python3.11/
│ └── site-packages/ # 패키지 설치 디렉토리
├── include/ # C 헤더 파일 (C 확장 빌드용)
└── pyvenv.cfg # 설정 파일
```
*pyvenv.cfg: *
```ini
home = /usr/bin
include-system-site-packages = false
version = 3.11.5
```
*활성화 메커니즘: *
```bash
source myenv/bin/activate
```
*activate 스크립트 동작: *
```bash
# 1. PATH 환경 변수 수정
export PATH="/home/user/myenv/bin: $PATH"
# 2. VIRTUAL_ENV 설정
export VIRTUAL_ENV="/home/user/myenv"
# 3. 프롬프트 변경
export PS1="(myenv) $PS1"
# 4. 비활성화 함수 정의
deactivate() {
  export PATH="$_OLD_VIRTUAL_PATH"
  unset VIRTUAL_ENV
  export PS1="$_OLD_VIRTUAL_PS1"
}
```
*실제 동작: *
```python
# 활성화 전
import sys
print(sys.executable)
# /usr/bin/python3.11
print(sys.prefix)
# /usr
# 활성화 후
print(sys.executable)
# /home/user/myenv/bin/python
print(sys.prefix)
# /home/user/myenv
print(sys.path)
# ['/home/user/myenv/lib/python3.11/site-packages', ...]
```
==== virtualenv vs venv
#figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*venv (표준 라이브러리)*], [*virtualenv (3rd party)*], [도입 시기], [Python 3.3 (2012)], [2007년], [설치], [기본 포함], [pip install virtualenv], [속도], [느림 (전체 복사)], [빠름 (심볼릭 링크)], [Python 2 지원], [지원 안 함], [지원], [고급 기능], [기본 기능만], [더 많은 옵션], ), caption: "venv vs virtualenv 비교")
*권장: *
```
Python 3.3+: venv 사용 (표준이므로)
Python 2.7: virtualenv 사용
```
==== Conda 환경
Conda는 Python + 시스템 라이브러리까지 관리한다.
*venv vs Conda: *
```
venv:
- Python 패키지만 관리
- pip로 설치
- 가벼움
Conda:
- Python + C/C++ 라이브러리 관리
- 예: NumPy는 BLAS, LAPACK 등 C 라이브러리 의존
- conda install로 모든 의존성 자동 설치
- 무거움 (수 GB)
```
*사용 사례: *
```
반도체 HMI (PySide6, PyQtGraph):
→ venv 권장 (가볍고 충분)
과학 컴퓨팅 (NumPy, SciPy, CUDA):
→ Conda 권장 (복잡한 C 라이브러리 의존성)
```
=== 의존성 해결 (Dependency Resolution)
==== pip의 의존성 해결
*requirements.txt: *
```
PySide6>=6.5.0
pyqtgraph>=0.13.0
numpy>=1.20.0
```
*pip install 과정: *
```
1. requirements.txt 읽기
  ↓
2. PyPI에서 각 패키지 메타데이터 다운로드
  - PySide6: shiboken6>=6.5.0 필요
  - pyqtgraph: numpy>=1.8.0 필요
  ↓
3. 의존성 그래프 구축
  PySide6 → shiboken6
  pyqtgraph → numpy
  ↓
4. 버전 해결 (최신 호환 버전 선택)
  - numpy>=1.20.0 (requirements) ∩ numpy>=1.8.0 (pyqtgraph)
  → numpy==1.26.2 (최신) 설치
  ↓
5. 다운로드 및 설치 (의존성 우선)
  a. numpy==1.26.2
  b. shiboken6==6.6.0
  c. PySide6==6.6.0
  d. pyqtgraph==0.13.3
```
*문제: pip는 "최선의 노력" 해결*
```
# 충돌 시나리오
requirements.txt: PackageA==1.0 # numpy<1.20 필요
  PackageB==2.0 # numpy>=1.22 필요
pip install: - PackageA 설치 → numpy==1.19 설치
  - PackageB 설치 시도 → numpy>=1.22 필요
  → 오류 또는 numpy 업그레이드 (PackageA 깨짐!)
```
==== Poetry의 의존성 해결
Poetry는 SAT Solver로 완전한 의존성 해결을 한다.
*pyproject.toml: *
```toml
[tool.poetry.dependencies]
python = "^3.11"
PySide6 = "^6.5.0"
pyqtgraph = "^0.13.0"
numpy = "^1.20.0"
```
*poetry install 과정: *
```
1. pyproject.toml 읽기
  ↓
2. 의존성 트리 완전 탐색
  - 모든 가능한 버전 조합 검사
  - SAT (Boolean Satisfiability) Solver 사용
  ↓
3. 충돌 감지
  - 불가능한 조합 → 설치 전에 오류 보고
  ↓
4. poetry.lock 파일 생성 (정확한 버전 고정)
  numpy==1.26.2
  PySide6==6.6.0
  shiboken6==6.6.0
  pyqtgraph==0.13.3
  ↓
5. 설치 (lock 파일 기준, 재현 가능)
```
*poetry.lock 예시: *
```toml
[[package]]
name = "numpy"
version = "1.26.2"
description = "..."
category = "main"
python-versions = ">=3.9"
files = [
  {file = "numpy-1.26.2-cp311-cp311-win_amd64.whl", hash = "sha256: ..."},
]
[[package]]
name = "PySide6"
version = "6.6.0"
dependencies = [
  {name = "shiboken6", version = "6.6.0"},
]
```
*장점: *
```
1. 결정적 빌드 (Deterministic): - 팀원 모두 동일한 버전 설치
  - CI/CD 재현 가능
2. 의존성 충돌 사전 감지: - 설치 전에 오류 발견
3. 보안: - poetry.lock에 SHA256 해시 포함
  - 패키지 변조 감지
```
==== Semantic Versioning (SemVer)
Python 패키지는 대부분 SemVer를 따른다.
*포맷: *
```
MAJOR.MINOR.PATCH
예: 1.24.3
  │  │ └─ PATCH: 버그 수정 (하위 호환)
  │  └─ MINOR: 기능 추가 (하위 호환)
  └─ MAJOR: 호환성 깨지는 변경
```
*버전 지정자: *
```python
# requirements.txt
numpy==1.24.3 # 정확히 1.24.3만
numpy>=1.24.0 # 1.24.0 이상
numpy<2.0.0 # 2.0.0 미만
numpy>=1.24, <2.0 # 1.24 이상, 2.0 미만
numpy~=1.24.0 # >=1.24.0, <1.25.0 (PATCH만 증가)
numpy^1.24.0 # >=1.24.0, <2.0.0 (MINOR, PATCH 증가, Poetry)
```
*충돌 예시: *
```
프로젝트: numpy>=1.20.0
PackageA: numpy>=1.18.0, <1.23.0
해결 가능 범위: [1.20.0, 1.23.0)
→ numpy==1.22.4 설치
프로젝트: numpy>=1.24.0
PackageB: numpy<1.22.0
해결 불가능!
→ 오류: "Could not find a version that satisfies the requirement"
```
=== PyInstaller 심화 이론
==== Hidden Imports 문제
Python의 동적 import는 정적 분석으로 감지 불가능하다.
*문제 코드: *
```python
# app.py
plugin_name = "sensor_driver"
module = __import__(plugin_name) # 동적 import
# 또는
import importlib
module = importlib.import_module("sensor_driver")
```
PyInstaller는 이를 감지하지 못하여 `sensor_driver`를 포함하지 않는다.
*해결책 1: --hidden-import*
```bash
pyinstaller --hidden-import=sensor_driver app.py
```
*해결책 2: Spec 파일*
```python
hiddenimports=['sensor_driver', 'sensor_driver.usb']
```
*해결책 3: Hook 파일*
```python
# hook-app.py (PyInstaller hooks 디렉토리)
from PyInstaller.utils.hooks import collect_submodules
hiddenimports = collect_submodules('sensor_driver')
```
==== 실행 파일 크기 최적화
*기본 빌드 크기: *
```
최소 PySide6 앱:
- --onedir: 150-200MB
- --onefile: 80-100MB (압축)
주요 용량:
- PySide6: 50MB
- Qt 라이브러리: 40MB
- Python 표준 라이브러리: 30MB
- 애플리케이션 코드: 1-5MB
```
*최적화 전략: *
*1. 불필요한 모듈 제외: *
```python
excludes=[
  'matplotlib', # 30MB
  'scipy', # 50MB
  'IPython', # 10MB
  'tkinter', # 5MB
  'test', # 10MB
  'unittest', 'distutils',
]
```
*2. UPX 압축: *
```bash
# UPX 다운로드 (https: //upx.github.io/)
pyinstaller --upx-dir=/path/to/upx app.py
# 효과: 30-50% 크기 감소
# 전: 100MB → 후: 50-70MB
```
*주의: *
- 일부 안티바이러스가 UPX 압축 파일을 오탐
- 실행 속도 약간 느림 (압축 해제 시간)
*3. --onefile 대신 --onedir: *
```
--onefile:
- 단일 .exe 파일
- 실행 시 임시 디렉토리 추출 (~5초)
- 크기: 80MB
--onedir:
- 디렉토리 + 여러 파일
- 실행 즉시 시작 (~0.5초)
- 크기: 150MB (압축 안 됨)
반도체 HMI 권장: --onedir
- 빠른 시작 시간 (공정 모니터링)
- 사용자는 디렉토리 전체를 배포받음
```
==== Bootloader 내부 동작
Bootloader는 C로 작성된 네이티브 실행 파일이다.
*소스 코드 구조 (간소화): *
```c
// bootloader/src/pyi_main.c
int main(int argc, char **argv)
{
  // 1. 아카이브 추출
  char *tempdir = create_temp_dir(); // %TEMP%\_MEIxxxxxx
  extract_archive(tempdir);
  // 2. Python 인터프리터 초기화
  char python_dll[PATH_MAX];
  snprintf(python_dll, PATH_MAX, "%s/python311.dll", tempdir);
  HMODULE hPython = LoadLibrary(python_dll);
  // 3. Python C API 함수 포인터 획득
  typedef int (*Py_Main_t)(int, wchar_t **);
  Py_Main_t Py_Main = (Py_Main_t)GetProcAddress(hPython, "Py_Main");
  // 4. sys.path에 임시 디렉토리 추가
  add_to_syspath(tempdir);
  // 5. main 스크립트 실행
  wchar_t *script = L"main.py";
  int ret = Py_Main(1, &script);
  // 6. 정리
  cleanup_temp_dir(tempdir);
  return ret;
}
```
*실행 흐름: *
```
my_app.exe 실행
  ↓
Bootloader C 코드 시작
  ↓
아카이브 추출 (%TEMP%\_MEI123456)
├─ python311.dll
├─ _ssl.pyd
├─ PySide6.pyd
└─ main.pyc
  ↓
python311.dll 로드
  ↓
sys._MEIPASS = "C: \\Users\\...\\Temp\\_MEI123456"
sys.path.insert(0, sys._MEIPASS)
  ↓
main.pyc 실행 (Python 코드)
  ↓
종료 시 임시 디렉토리 삭제
```
==== --onefile vs --onedir 내부 차이
*--onefile: *
```
my_app.exe (단일 파일)
├─ Bootloader (C, 500KB)
└─ Embedded Archive (ZIP, 압축)
  ├─ python311.dll
  ├─ 표준 라이브러리
  └─ 애플리케이션 코드
실행 시:
1. 전체 아카이브를 %TEMP%에 추출 (~5초)
2. Python 실행
3. 종료 시 임시 파일 삭제
장점: 배포 간편 (단일 파일)
단점: 느린 시작, 디스크 I/O 많음
```
*--onedir: *
```
my_app/ (디렉토리)
├─ my_app.exe (Bootloader, 500KB)
├─ python311.dll
├─ _ssl.pyd
├─ PySide6/
│ └─ Qt6Core.dll
└─ 애플리케이션 코드
실행 시:
1. 현재 디렉토리에서 직접 DLL 로드 (~0.5초)
2. Python 실행
장점: 빠른 시작
단점: 많은 파일 (배포 복잡)
```
*성능 비교 (PySide6 앱): *
```
--onefile:
- 첫 실행: ~8초 (아카이브 추출 + Python 초기화)
- 두 번째 실행: ~5초 (아카이브 재추출, 임시 파일 삭제됨)
--onedir:
- 첫 실행: ~2초 (DLL 로드 + Python 초기화)
- 두 번째 실행: ~0.5초 (DLL 캐시)
반도체 HMI 권장: --onedir
- 실시간 모니터링은 빠른 시작이 중요
```
==== Cross-Compilation 제한
PyInstaller는 크로스 컴파일을 지원하지 않는다.
*이유: *
```
1. 바이너리 의존성: - PySide6는 플랫폼별 .pyd/.so/.dylib 포함
  - Windows에서 Linux .so 생성 불가능
2. Python 인터프리터: - python311.dll (Windows)
  - libpython3.11.so (Linux)
  - 각 플랫폼에서 빌드 필요
3. C 확장: - NumPy, Pillow 등은 C로 컴파일됨
  - 타겟 플랫폼에서 빌드 필요
```
*해결책: *
```
1. 가상 머신: - Windows 개발자 → Linux VM에서 빌드
2. Docker: - Docker로 Linux 환경 구성 후 빌드
  FROM python: 3.11-slim
  RUN pip install pyinstaller PySide6
  CMD ["pyinstaller", "app.py"]
3. CI/CD (GitHub Actions): - Windows, Linux, macOS runner에서 병렬 빌드
```
*GitHub Actions 예시: *
```yaml
jobs: build: runs-on: ${{ matrix.os }}
  strategy: matrix: os: [windows-latest, ubuntu-latest, macos-latest]
  steps: - uses: actions/checkout@v3
  - name: Build
  run: pyinstaller app.py
```
== 이론: Python 배포 방식
=== sdist (Source Distribution)
소스 코드를 압축하여 배포하는 방식이다.
*특징*:
- 소스 코드 그대로 배포 (.tar.gz, .zip)
- 설치 시 빌드 필요 (C 확장 등)
- 플랫폼 독립적
*생성 방법*:
```bash
python setup.py sdist
```
*구조*:
```
my_package-1.0.0.tar.gz
├── my_package/
│ ├── __init__.py
│ └── module.py
├── setup.py
├── README.md
└── LICENSE
```
=== bdist (Binary Distribution)
플랫폼별 바이너리를 배포하는 방식이다.
*특징*:
- 빌드 완료된 바이너리 포함
- 빠른 설치 (컴파일 불필요)
- 플랫폼 의존적
*종류*:
- bdist_wheel: 현대적인 표준 (.whl)
- bdist_egg: 구식 포맷 (deprecated)
- bdist_wininst: Windows 인스톨러
=== wheel 포맷
Python 표준 바이너리 배포 포맷이다 (PEP 427, 2012).
*포맷*:
```
{distribution}-{version}(-{build})?-{python}-{abi}-{platform}.whl
```
*예시*:
```
numpy-1.24.3-cp311-cp311-win_amd64.whl
└─┬─┘ └─┬──┘ └─┬─┘ └─┬─┘ └────┬────┘
  │ │  │  │  └─ 플랫폼 (Windows 64bit)
  │ │  │  └─ ABI (CPython 3.11)
  │ │  └─ Python 버전 (3.11)
  │ └─ 버전 (1.24.3)
  └─ 패키지명
```
*장점*:
- pip로 직접 설치 가능
- 빠른 설치 속도 (빌드 불필요)
- 메타데이터 포함 (의존성 정보)
=== PyInstaller 내부 구조
PyInstaller는 Python 애플리케이션을 독립 실행 파일로 변환한다.
==== 동작 원리
```
┌─────────────────────────────┐
│ 1. Analysis Phase │
│ - Import 문 파싱 │
│ - 의존성 그래프 구축 │
│ - Hidden imports 탐지 │
└──────────┬──────────────────┘
  |
┌──────────┴──────────────────┐
│ 2. Bundling Phase │
│ - Python 인터프리터 포함 │
│ - 모든 .pyc 파일 수집 │
│ - 바이너리 의존성 포함 │
└──────────┬──────────────────┘
  |
┌──────────┴──────────────────┐
│ 3. Bootloader 생성 │
│ - C로 작성된 네이티브 실행파일│
│ - 압축된 아카이브 추출 │
│ - Python 인터프리터 초기화 │
└──────────┬──────────────────┘
  |
┌──────────┴──────────────────┐
│ 4. Packaging │
│ - --onefile: 단일 실행 파일 │
│ - --onedir: 디렉토리 번들 │
└─────────────────────────────┘
```
==== 최종 실행 파일 구조 (--onefile)
```
my_app.exe (50MB+)
├─ Bootloader (C 코드, 500KB)
│ └─ 아카이브 추출 및 Python 초기화
└─ Embedded Archive (ZIP)
  ├─ python311.dll (4MB)
  ├─ 표준 라이브러리 (20MB)
  ├─ 3rd party 패키지 (10-30MB)
  ├─ 애플리케이션 코드 (1-5MB)
  └─ 리소스 파일
```
==== 실행 과정
```
1. my_app.exe 실행
2. Bootloader가 임시 디렉토리에 아카이브 추출
  (Windows: %TEMP%/_MEIxxxxxx)
3. python311.dll 로드
4. sys.path에 _MEIxxxxxx 추가
5. main.py 실행
6. 종료 시 임시 파일 삭제
```
=== Docker 컨테이너 배포
Docker는 애플리케이션과 환경을 함께 패키징한다.
==== Dockerfile 구조
```dockerfile
# Base image
FROM python: 3.11-slim
# 작업 디렉토리 설정
WORKDIR /app
# 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# 애플리케이션 복사
COPY . .
# 실행
CMD ["python", "main.py"]
```
==== 레이어 구조
```
Docker Image Layers:
┌────────────────────────┐
│ CMD ["python", "main.py"] │ (1KB)
├────────────────────────┤
│ COPY . . │ (10MB, 애플리케이션)
├────────────────────────┤
│ RUN pip install │ (50MB, 패키지)
├────────────────────────┤
│ COPY requirements.txt │ (1KB)
├────────────────────────┤
│ WORKDIR /app │ (100B)
├────────────────────────┤
│ python: 3.11-slim │ (150MB, base)
└────────────────────────┘
```
*장점*:
- 환경 일관성 (개발/테스트/배포 동일)
- 의존성 격리
- 쉬운 배포 및 확장
*단점*:
- Docker 필요
- 큰 이미지 크기 (200MB+)
- Windows GUI 앱에는 부적합
== 응용: 디자인 패턴
=== Builder Pattern (빌더 패턴)
복잡한 빌드 설정을 단계적으로 구성하는 패턴이다.
```python
# build_config.py
"""PyInstaller 빌드 설정을 단계적으로 구성하는 Builder Pattern"""
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional
@dataclass
class BuildConfig: """빌드 설정 데이터 클래스"""
  name: str
  script: Path
  onefile: bool = True
  windowed: bool = True
  icon: Optional[Path] = None
  hidden_imports: List[str] = field(default_factory=list)
  datas: List[tuple] = field(default_factory=list)
  excludes: List[str] = field(default_factory=list)
  upx: bool = False
  debug: bool = False
class PyInstallerBuilder: """PyInstaller 명령어를 단계적으로 구성하는 Builder"""
  def __init__(self, name: str, script: Path): self._config = BuildConfig(name=name, script=script)
  def set_onefile(self, enabled: bool = True) -> 'PyInstallerBuilder': """단일 파일 모드 설정"""
  self._config.onefile = enabled
  return self
  def set_windowed(self, enabled: bool = True) -> 'PyInstallerBuilder': """윈도우 모드 설정 (콘솔 숨김)"""
  self._config.windowed = enabled
  return self
  def set_icon(self, icon_path: Path) -> 'PyInstallerBuilder': """아이콘 설정"""
  self._config.icon = icon_path
  return self
  def add_hidden_import(self, module: str) -> 'PyInstallerBuilder': """Hidden import 추가"""
  self._config.hidden_imports.append(module)
  return self
  def add_data(self, source: str, dest: str) -> 'PyInstallerBuilder': """데이터 파일 추가"""
  self._config.datas.append((source, dest))
  return self
  def exclude_module(self, module: str) -> 'PyInstallerBuilder': """불필요한 모듈 제외"""
  self._config.excludes.append(module)
  return self
  def enable_upx(self, enabled: bool = True) -> 'PyInstallerBuilder': """UPX 압축 활성화"""
  self._config.upx = enabled
  return self
  def enable_debug(self, enabled: bool = True) -> 'PyInstallerBuilder': """디버그 모드 활성화"""
  self._config.debug = enabled
  return self
  def build_command(self) -> str: """최종 PyInstaller 명령어 생성"""
  cmd_parts = ["pyinstaller"]
  # 기본 옵션
  if self._config.onefile: cmd_parts.append("--onefile")
  if self._config.windowed: cmd_parts.append("--windowed")
  if self._config.icon: cmd_parts.append(f"--icon={self._config.icon}")
  # 이름 설정
  cmd_parts.append(f"--name={self._config.name}")
  # Hidden imports
  for module in self._config.hidden_imports: cmd_parts.append(f"--hidden-import={module}")
  # 데이터 파일
  for source, dest in self._config.datas: cmd_parts.append(f"--add-data={source}{';' if Path().resolve().drive else ': '}{dest}")
  # 제외 모듈
  for module in self._config.excludes: cmd_parts.append(f"--exclude-module={module}")
  # UPX
  if self._config.upx: cmd_parts.append("--upx-dir=upx")
  # 디버그
  if self._config.debug: cmd_parts.append("--debug=all")
  # 스크립트
  cmd_parts.append(str(self._config.script))
  return " ".join(cmd_parts)
  def get_config(self) -> BuildConfig: """설정 객체 반환"""
  return self._config
# 사용 예시
if __name__ == "__main__": # Fluent Interface를 통한 빌드 설정
  builder = PyInstallerBuilder("SemiconductorHMI", Path("main.py"))
  command = (builder
  .set_onefile(True)
  .set_windowed(True)
  .set_icon(Path("resources/icon.ico"))
  .add_hidden_import("PySide6.QtCore")
  .add_hidden_import("PySide6.QtWidgets")
  .add_data("resources/*", "resources")
  .add_data("config/*.json", "config")
  .exclude_module("matplotlib")
  .exclude_module("scipy")
  .enable_upx(True)
  .build_command())
  print("Generated command: ")
  print(command)
  # 실행
  import subprocess
  result = subprocess.run(command, shell=True, capture_output=True, text=True)
  if result.returncode == 0: print("\nBuild successful!")
  else: print(f"\nBuild failed: {result.stderr}")
```
*장점*:
- 복잡한 설정을 단계적으로 구성
- 가독성 높은 Fluent Interface
- 재사용 가능한 빌드 설정
=== Facade Pattern (파사드 패턴)
복잡한 배포 프로세스를 단순한 인터페이스로 제공한다.
```python
# deployment_facade.py
"""배포 프로세스를 단순화하는 Facade Pattern"""
import shutil
import subprocess
from pathlib import Path
from typing import Optional
class DeploymentFacade: """배포 프로세스를 단순화하는 Facade"""
  def __init__(self, project_root: Path): self.project_root = project_root
  self.dist_dir = project_root / "dist"
  self.build_dir = project_root / "build"
  self.spec_file = project_root / "SemiconductorHMI.spec"
  def deploy(self, clean: bool = True, test: bool = True) -> bool: """전체 배포 프로세스 실행"""
  print("=" * 60)
  print("Starting deployment process...")
  print("=" * 60)
  # 1. 정리
  if clean: if not self._clean(): return False
  # 2. 테스트
  if test: if not self._run_tests(): return False
  # 3. 빌드
  if not self._build(): return False
  # 4. 검증
  if not self._verify(): return False
  # 5. 패키징
  if not self._package(): return False
  print("\n" + "=" * 60)
  print("Deployment successful!")
  print("=" * 60)
  return True
  def _clean(self) -> bool: """빌드 디렉토리 정리"""
  print("\n[1/5] Cleaning build directories...")
  try: if self.dist_dir.exists(): shutil.rmtree(self.dist_dir)
  print(f" - Removed {self.dist_dir}")
  if self.build_dir.exists(): shutil.rmtree(self.build_dir)
  print(f" - Removed {self.build_dir}")
  if self.spec_file.exists(): self.spec_file.unlink()
  print(f" - Removed {self.spec_file}")
  print(" ✓ Clean completed")
  return True
  except Exception as e: print(f" ✗ Clean failed: {e}")
  return False
  def _run_tests(self) -> bool: """단위 테스트 실행"""
  print("\n[2/5] Running tests...")
  try: result = subprocess.run(["pytest", "tests/", "-v"], capture_output=True, text=True, cwd=self.project_root)
  if result.returncode == 0: print(" ✓ All tests passed")
  return True
  else: print(f" ✗ Tests failed: \n{result.stdout}")
  return False
  except FileNotFoundError: print(" ! pytest not found, skipping tests")
  return True
  def _build(self) -> bool: """PyInstaller 빌드"""
  print("\n[3/5] Building executable...")
  try: # Builder 패턴 사용
  from build_config import PyInstallerBuilder
  builder = PyInstallerBuilder("SemiconductorHMI", Path("main.py"))
  command = (builder
  .set_onefile(True)
  .set_windowed(True)
  .set_icon(Path("resources/icon.ico"))
  .add_hidden_import("PySide6.QtCore")
  .add_data("resources/*", "resources")
  .build_command())
  result = subprocess.run(command, shell=True, capture_output=True, text=True, cwd=self.project_root)
  if result.returncode == 0: print(" ✓ Build completed")
  return True
  else: print(f" ✗ Build failed: \n{result.stderr}")
  return False
  except Exception as e: print(f" ✗ Build failed: {e}")
  return False
  def _verify(self) -> bool: """실행 파일 검증"""
  print("\n[4/5] Verifying executable...")
  exe_path = self.dist_dir / "SemiconductorHMI.exe"
  if not exe_path.exists(): print(f" ✗ Executable not found: {exe_path}")
  return False
  size_mb = exe_path.stat().st_size / (1024 * 1024)
  print(f" - Executable size: {size_mb: .1f} MB")
  if size_mb > 200: print(" ! Warning: Executable size is large (>200MB)")
  print(" ✓ Verification completed")
  return True
  def _package(self) -> bool: """배포 패키지 생성"""
  print("\n[5/5] Creating deployment package...")
  try: # ZIP 파일 생성
  package_name = f"SemiconductorHMI_v1.0.0"
  shutil.make_archive(self.project_root / package_name, 'zip', self.dist_dir)
  print(f" ✓ Package created: {package_name}.zip")
  return True
  except Exception as e: print(f" ✗ Packaging failed: {e}")
  return False
# 사용 예시
if __name__ == "__main__": facade = DeploymentFacade(Path.cwd())
  # 단 한 줄로 전체 배포 프로세스 실행
  success = facade.deploy(clean=True, test=True)
  if success: print("\nDeployment package is ready for distribution.")
  else: print("\nDeployment failed. Please check the errors above.")
```
*장점*:
- 복잡한 배포 단계를 단순한 API로 제공
- 각 단계를 독립적으로 실행 가능
- 에러 처리 및 로깅 통합
== 완전한 작동 예제: PyInstaller Spec 파일 설정
```python
# SemiconductorHMI.spec
# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller Spec 파일 - 반도체 HMI 애플리케이션
이 파일은 PyInstaller가 실행 파일을 생성하는 방법을 정의한다.
커맨드라인 대신 spec 파일을 사용하면 복잡한 설정을 재사용할 수 있다.
사용법: pyinstaller SemiconductorHMI.spec
"""
import sys
from pathlib import Path
# 프로젝트 루트 경로
ROOT = Path.cwd()
block_cipher = None
# Analysis: 의존성 분석
a = Analysis(# 진입점 스크립트
  ['main.py'], # 추가 경로 (모듈 검색)
  pathex=[str(ROOT)], # 바이너리 파일 (DLL, SO 등)
  # 형식: [(source, destination), ...]
  binaries=[], # 데이터 파일 (리소스, 설정 등)
  # 형식: [(source, destination), ...]
  datas=[
  (str(ROOT / 'resources' / '*'), 'resources'), (str(ROOT / 'config' / '*.json'), 'config'), (str(ROOT / 'config' / '*.ini'), 'config'), ], # Hidden imports (동적 import로 자동 감지 안 되는 모듈)
  hiddenimports=[
  'PySide6.QtCore', 'PySide6.QtWidgets', 'PySide6.QtGui', 'pyqtgraph', 'numpy', 'pandas', ], # Hook 경로 (커스텀 hook)
  hookspath=[], # Hook 설정
  hooksconfig={}, # Runtime hook (실행 시 먼저 실행되는 스크립트)
  runtime_hooks=[], # 제외할 모듈 (크기 줄이기)
  excludes=[
  'matplotlib', # 사용하지 않으면 제외
  'scipy', 'IPython', 'jupyter', 'test', 'unittest', 'distutils', ], # Windows 설정
  win_no_prefer_redirects=False, win_private_assemblies=False, # 암호화 (None 또는 key)
  cipher=block_cipher, # 아카이브 생성 여부
  noarchive=False, )
# PYZ: Python 아카이브 생성
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
# EXE: 실행 파일 생성
exe = EXE(pyz, a.scripts, a.binaries, a.zipfiles, a.datas, [], # 실행 파일 이름
  name='SemiconductorHMI', # 디버그 모드 (False로 설정)
  debug=False, # Bootloader 옵션
  bootloader_ignore_signals=False, # 심볼 제거 (Linux/macOS)
  strip=False, # UPX 압축 활성화 (크기 30-50% 감소)
  upx=True, # UPX 제외 파일
  upx_exclude=[
  'vcruntime140.dll', # UPX로 압축하면 오류 발생 가능
  'python3.dll', ], # 런타임 임시 디렉토리
  runtime_tmpdir=None, # 콘솔 창 표시 (False: GUI 앱, True: 콘솔 앱)
  console=False, # Windows 트레이스백 비활성화
  disable_windowed_traceback=False, # macOS argv emulation
  argv_emulation=False, # 타겟 아키텍처 (None: 현재 시스템)
  target_arch=None, # macOS codesign identity
  codesign_identity=None, # macOS entitlements
  entitlements_file=None, # 아이콘 (플랫폼별)
  icon=str(ROOT / 'resources' / 'icon.ico') if sys.platform == 'win32' else None, )
# macOS용 .app 번들 (선택사항)
if sys.platform == 'darwin': app = BUNDLE(exe, name='SemiconductorHMI.app', icon=str(ROOT / 'resources' / 'icon.icns'), bundle_identifier='com.semiconductor.hmi', info_plist={
  'NSPrincipalClass': 'NSApplication', 'NSHighResolutionCapable': 'True', }, )
```
*사용 방법*: ```bash
# 1. Spec 파일로 빌드
pyinstaller SemiconductorHMI.spec
# 2. Clean 빌드
pyinstaller --clean SemiconductorHMI.spec
# 3. 결과 확인
ls dist/
# → SemiconductorHMI.exe (Windows)
# → SemiconductorHMI (Linux)
# → SemiconductorHMI.app (macOS)
```
*리소스 파일 경로 처리*: ```python
# utils/resource_path.py
"""PyInstaller 실행 파일에서 리소스 경로 처리"""
import sys
from pathlib import Path
def get_resource_path(relative_path: str) -> Path: """
  리소스 파일의 절대 경로 반환
  PyInstaller는 리소스를 임시 디렉토리(_MEIPASS)에 추출한다.
  이 함수는 개발 환경과 실행 파일 모두에서 동작한다.
  Args: relative_path: 리소스의 상대 경로 (예: 'config/settings.json')
  Returns: 리소스의 절대 경로
  """
  if hasattr(sys, '_MEIPASS'): # PyInstaller 실행 파일 환경
  base_path = Path(sys._MEIPASS)
  else: # 개발 환경
  base_path = Path(__file__).parent.parent
  return base_path / relative_path
# 사용 예시
if __name__ == "__main__": # 설정 파일 로드
  config_path = get_resource_path('config/settings.json')
  print(f"Config path: {config_path}")
  # 아이콘 로드
  icon_path = get_resource_path('resources/icon.ico')
  print(f"Icon path: {icon_path}")
```
== 가상 환경
=== venv
```bash
# 가상 환경 생성
python -m venv venv
# 활성화 (Linux/Mac)
source venv/bin/activate
# 활성화 (Windows)
venv\Scripts\activate
# 비활성화
deactivate
```
=== 의존성 관리
```bash
# requirements.txt 생성
pip freeze > requirements.txt
# 설치
pip install -r requirements.txt
```
=== Poetry
```bash
# Poetry 설치
curl -sSL https: //install.python-poetry.org | python3 -
# 프로젝트 초기화
poetry init
# 의존성 추가
poetry add PySide6 pyqtgraph
# 개발 의존성
poetry add --group dev pytest black
# 설치
poetry install
# 실행
poetry run python main.py
```
== 테스트
=== pytest
```bash
pip install pytest pytest-qt
```
```python
# test_equipment.py
import pytest
from PySide6.QtCore import Qt
from equipment import EquipmentViewModel
def test_temperature_update(): vm = EquipmentViewModel()
  vm.temperature = 450.0
  assert vm.temperature == 450.0
def test_temperature_signal(qtbot): vm = EquipmentViewModel()
  with qtbot.waitSignal(vm.temperature_changed, timeout=1000): vm.temperature = 450.0
@pytest.fixture
def equipment_view(qtbot): view = EquipmentView()
  qtbot.addWidget(view)
  return view
def test_button_click(equipment_view, qtbot): qtbot.mouseClick(equipment_view.start_button, Qt.LeftButton)
  assert equipment_view.is_running
```
=== 테스트 실행
```bash
# 모든 테스트
pytest
# 특정 파일
pytest test_equipment.py
# 커버리지
pytest --cov=. --cov-report=html
# 마커
pytest -m "slow"
```
== 로깅
=== 기본 설정
```python
import logging
from logging.handlers import RotatingFileHandler
def setup_logging(): # 로거 생성
  logger = logging.getLogger('SemiconductorHMI')
  logger.setLevel(logging.DEBUG)
  # 포맷터
  formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
  # 파일 핸들러 (로테이션)
  file_handler = RotatingFileHandler('hmi.log', maxBytes=10*1024*1024, # 10MB
  backupCount=5)
  file_handler.setLevel(logging.DEBUG)
  file_handler.setFormatter(formatter)
  # 콘솔 핸들러
  console_handler = logging.StreamHandler()
  console_handler.setLevel(logging.INFO)
  console_handler.setFormatter(formatter)
  # 핸들러 추가
  logger.addHandler(file_handler)
  logger.addHandler(console_handler)
  return logger
# 사용
logger = setup_logging()
logger.info("Application started")
logger.error("An error occurred", exc_info=True)
```
== 크로스 플랫폼 배포
=== Windows
```bash
# PyInstaller
pyinstaller --onefile --windowed \
  --icon=resources/icon.ico \
  main.py
# Inno Setup (installer.iss)
[Setup]
AppName=Semiconductor HMI
AppVersion=1.0
DefaultDirName={pf}\SemiconductorHMI
DefaultGroupName=Semiconductor HMI
OutputDir=output
OutputBaseFilename=SemiconductorHMI-Setup
[Files]
Source: "dist\SemiconductorHMI.exe"; DestDir: "{app}"
Source: "config\*"; DestDir: "{app}\config"
[Icons]
Name: "{group}\Semiconductor HMI"; Filename: "{app}\SemiconductorHMI.exe"
```
=== Linux
```bash
# AppImage
pip install python-appimage
python-appimage build app \
  --linux-tag manylinux2014_x86_64 \
  --python-version 3.11
# .deb 패키지 (debian/ 디렉토리 구성 필요)
dpkg-buildpackage -us -uc
```
=== macOS
```bash
# PyInstaller
pyinstaller --onefile --windowed \
  --icon=resources/icon.icns \
  main.py
# DMG 생성
hdiutil create -volname "Semiconductor HMI" \
  -srcfolder dist/SemiconductorHMI.app \
  -ov -format UDZO \
  SemiconductorHMI.dmg
```
== CI/CD
=== GitHub Actions
```yaml
# .github/workflows/build.yml
name: Build
on: push: branches: [ main ]
  pull_request: branches: [ main ]
jobs: build: runs-on: ${{ matrix.os }}
  strategy: matrix: os: [ubuntu-latest, windows-latest, macos-latest]
  python-version: ['3.11']
  steps: - uses: actions/checkout@v3
  - name: Set up Python
  uses: actions/setup-python@v4
  with: python-version: ${{ matrix.python-version }}
  - name: Install dependencies
  run: |
  python -m pip install --upgrade pip
  pip install -r requirements.txt
  pip install pyinstaller
  - name: Run tests
  run: pytest
  - name: Build with PyInstaller
  run: pyinstaller --onefile --windowed main.py
  - name: Upload artifact
  uses: actions/upload-artifact@v3
  with: name: SemiconductorHMI-${{ matrix.os }}
  path: dist/
```
== MCQ (Multiple Choice Questions)
=== 문제 1: Python 배포 방식 (기초)
PyInstaller로 생성한 실행 파일에 포함되지 않는 것은?
A. Python 인터프리터 \
B. 표준 라이브러리 \
C. 3rd party 패키지 \
D. 소스 코드 원본 (.py 파일)
*정답: D*
*해설*: PyInstaller는 .py 파일을 .pyc (바이트코드)로 컴파일하여 포함한다. 원본 소스 코드는 포함되지 않으므로 역공학이 어렵다.
---
=== 문제 2: wheel 포맷 (기초)
다음 wheel 파일명에서 플랫폼을 나타내는 부분은?
`numpy-1.24.3-cp311-cp311-win_amd64.whl`
A. numpy \
B. cp311 \
C. win_amd64 \
D. whl
*정답: C*
*해설*: `win_amd64`는 Windows 64bit 플랫폼을 의미한다. `cp311`은 CPython 3.11을 의미한다.
---
=== 문제 3: Builder Pattern (중급)
Builder Pattern의 주요 장점은?
A. 실행 속도 향상 \
B. 복잡한 객체 생성을 단계적으로 구성 \
C. 메모리 사용량 감소 \
D. 스레드 안전성 보장
*정답: B*
*해설*: Builder Pattern은 복잡한 객체의 생성 과정을 단계별로 나누어, 가독성과 유지보수성을 높인다.
---
=== 문제 4: PyInstaller --onefile (중급)
PyInstaller `--onefile` 모드의 실행 과정은?
A. 직접 실행 \
B. 임시 디렉토리에 추출 후 실행 \
C. 메모리에 로드 후 실행 \
D. 압축 해제 없이 실행
*정답: B*
*해설*: `--onefile`은 모든 파일을 하나의 실행 파일에 압축한다. 실행 시 임시 디렉토리(`_MEIxxxxxx`)에 추출한 후 실행된다.
---
=== 문제 5: Facade Pattern (중급)
Facade Pattern의 목적은?
A. 성능 최적화 \
B. 복잡한 서브시스템을 단순한 인터페이스로 제공 \
C. 객체 생성 최소화 \
D. 메모리 누수 방지
*정답: B*
*해설*: Facade Pattern은 복잡한 서브시스템의 세부사항을 숨기고, 사용하기 쉬운 단순한 인터페이스를 제공한다.
---
=== 문제 6: Docker 레이어 (고급)
Docker 이미지 빌드 시 레이어 캐싱을 위한 최선의 전략은?
A. 자주 변경되는 파일을 먼저 COPY \
B. 변경이 적은 파일을 먼저 COPY \
C. 모든 파일을 한번에 COPY \
D. 순서는 중요하지 않음
*정답: B*
*해설*: Docker는 레이어 캐싱을 사용한다. 변경이 적은 파일(예: requirements.txt)을 먼저 COPY하면, 애플리케이션 코드 변경 시 의존성 레이어는 재사용된다.
---
=== 문제 7: 코드 분석 - Resource Path (고급)
다음 코드의 목적은?
```python
if hasattr(sys, '_MEIPASS'): base_path = Path(sys._MEIPASS)
else: base_path = Path(__file__).parent
```
A. 성능 최적화 \
B. PyInstaller 실행 파일과 개발 환경 모두에서 리소스 경로 처리 \
C. 메모리 관리 \
D. 예외 처리
*정답: B*
*해설*: `sys._MEIPASS`는 PyInstaller가 설정하는 임시 디렉토리 경로이다. 이 코드는 실행 파일과 개발 환경에서 모두 올바른 리소스 경로를 반환한다.
---
=== 문제 8: pytest-qt (고급)
다음 pytest-qt 코드의 역할은?
```python
with qtbot.waitSignal(vm.temperature_changed, timeout=1000): vm.temperature = 450.0
```
A. 온도를 450으로 설정 \
B. Signal이 1초 내에 발생하는지 검증 \
C. 타이머 설정 \
D. 스레드 동기화
*정답: B*
*해설*: `qtbot.waitSignal()`은 지정된 시간(1000ms) 내에 Signal이 발생하는지 검증한다. Signal이 발생하지 않으면 테스트 실패이다.
---
=== 문제 9: UPX 압축 (고급)
PyInstaller에서 UPX 압축의 효과는?
A. 실행 속도 향상 \
B. 실행 파일 크기 30-50% 감소 \
C. 보안 강화 \
D. 의존성 자동 탐지
*정답: B*
*해설*: UPX (Ultimate Packer for eXecutables)는 실행 파일을 압축하여 크기를 30-50% 줄인다. 단, 일부 안티바이러스가 오탐할 수 있다.
---
=== 문제 10: CI/CD 전략 (도전)
GitHub Actions에서 matrix strategy의 장점은?
A. 빌드 속도 향상 \
B. 여러 플랫폼/버전에서 병렬 테스트 \
C. 비용 절감 \
D. 보안 강화
*정답: B*
*해설*: Matrix strategy는 여러 운영체제(Windows/Linux/macOS)와 Python 버전에서 병렬로 테스트를 실행하여, 크로스 플랫폼 호환성을 보장한다.
== 추가 학습 자료
=== 공식 문서
- *PyInstaller Manual*: https: //pyinstaller.org/en/stable/
- *Python Packaging Guide*: https: //packaging.python.org/
- *Poetry Documentation*: https: //python-poetry.org/docs/
- *Docker Documentation*: https: //docs.docker.com/
=== 참고 자료
- *PEP 427*: The Wheel Binary Package Format 1.0
- *PEP 517/518*: Build System Interface
- *SEMI E95*: Operator Interface Standards
=== 도구
- *Nuitka*: Python을 C로 컴파일 (PyInstaller 대안)
- *cx_Freeze*: 크로스 플랫폼 배포 도구
- *py2exe*: Windows 전용 배포 도구
== 요약
이번 챕터에서는 Python 배포를 학습했다: *이론 (Theory): *
- Python 배포 방식의 역사와 발전 (Distutils → pip → PyInstaller)
- 배포 방식 비교: sdist, bdist, wheel, PyInstaller, Docker
- PyInstaller 내부 구조: Analysis → Bundling → Bootloader → Packaging
- 반도체 산업 동향: 독립 실행 파일, 컨테이너 배포
*응용 (Application): *
- Builder Pattern: 복잡한 빌드 설정을 단계적으로 구성
- Facade Pattern: 배포 프로세스를 단순한 API로 제공
- 완전한 PyInstaller Spec 파일 예제 (주석 포함)
- 리소스 경로 처리 (개발 환경 + 실행 파일)
*성찰 (Reflections): *
- MCQ 10문제: 배포 방식, 패턴, 코드 분석, CI/CD
*핵심 포인트: *
1. PyInstaller는 Python 앱을 독립 실행 파일로 변환 (50MB+ 크기)
2. Spec 파일로 복잡한 빌드 설정을 재사용 가능
3. Builder/Facade 패턴으로 배포 자동화
4. GitHub Actions로 CI/CD 파이프라인 구축
다음 챕터에서는 ImGui C++ 기초를 학습한다.
#pagebreak()