= Week 9: Python 패키징 및 배포

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ PyInstaller를 사용한 실행 파일 생성
+ 가상 환경 및 의존성 관리
+ 테스트 및 디버깅
+ 크로스 플랫폼 배포

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
curl -sSL https://install.python-poetry.org | python3 -

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

== PyInstaller

=== 설치

```bash
pip install pyinstaller
```

=== 단일 파일 생성

```bash
# 기본
pyinstaller main.py

# 단일 파일
pyinstaller --onefile main.py

# 윈도우 없음 (GUI)
pyinstaller --onefile --windowed main.py

# 이름 지정
pyinstaller --onefile --name SemiconductorHMI main.py
```

=== Spec 파일

```python
# SemiconductorHMI.spec
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('resources/*', 'resources'),
        ('config/*.json', 'config')
    ],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='SemiconductorHMI',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='resources/icon.ico'
)
```

```bash
# Spec 파일로 빌드
pyinstaller SemiconductorHMI.spec
```

=== 리소스 파일 포함

```python
import sys
from pathlib import Path

def get_resource_path(relative_path: str) -> Path:
    """리소스 파일 경로 반환"""
    if hasattr(sys, '_MEIPASS'):
        # PyInstaller 실행 파일
        base_path = Path(sys._MEIPASS)
    else:
        # 개발 환경
        base_path = Path(__file__).parent

    return base_path / relative_path

# 사용
config_path = get_resource_path('config/settings.json')
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

def test_temperature_update():
    vm = EquipmentViewModel()
    vm.temperature = 450.0
    assert vm.temperature == 450.0

def test_temperature_signal(qtbot):
    vm = EquipmentViewModel()

    with qtbot.waitSignal(vm.temperature_changed, timeout=1000):
        vm.temperature = 450.0

@pytest.fixture
def equipment_view(qtbot):
    view = EquipmentView()
    qtbot.addWidget(view)
    return view

def test_button_click(equipment_view, qtbot):
    qtbot.mouseClick(equipment_view.start_button, Qt.LeftButton)
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

def setup_logging():
    # 로거 생성
    logger = logging.getLogger('SemiconductorHMI')
    logger.setLevel(logging.DEBUG)

    # 포맷터
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # 파일 핸들러 (로테이션)
    file_handler = RotatingFileHandler(
        'hmi.log',
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
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

=== 구조화된 로깅

```python
import structlog

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ]
)

logger = structlog.get_logger()
logger.info("data_collected",
            equipment_id="CVD-01",
            temperature=450.0,
            pressure=2.5)
```

== 설정 관리

=== Config 클래스

```python
from dataclasses import dataclass
import json
from pathlib import Path

@dataclass
class EquipmentConfig:
    host: str
    port: int
    timeout: int

@dataclass
class AlarmConfig:
    temperature_max: float
    pressure_max: float

@dataclass
class AppConfig:
    equipment: EquipmentConfig
    alarms: AlarmConfig

    @classmethod
    def from_json(cls, path: Path) -> 'AppConfig':
        with open(path) as f:
            data = json.load(f)

        return cls(
            equipment=EquipmentConfig(**data['equipment']),
            alarms=AlarmConfig(**data['alarms'])
        )

    def to_json(self, path: Path):
        data = {
            'equipment': self.equipment.__dict__,
            'alarms': self.alarms.__dict__
        }
        with open(path, 'w') as f:
            json.dump(data, f, indent=2)

# 사용
config = AppConfig.from_json(Path('config/settings.json'))
print(f"Host: {config.equipment.host}")
```

== 에러 처리

=== 전역 예외 핸들러

```python
import sys
import traceback
from PySide6.QtWidgets import QMessageBox

def exception_hook(exctype, value, tb):
    # 로그 기록
    logger.error("Uncaught exception",
                 exc_info=(exctype, value, tb))

    # 트레이스백
    tb_str = ''.join(traceback.format_exception(exctype, value, tb))

    # 사용자에게 표시
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Critical)
    msg.setWindowTitle("Error")
    msg.setText("An unexpected error occurred")
    msg.setDetailedText(tb_str)
    msg.exec()

# 설치
sys.excepthook = exception_hook
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

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.11']

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

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
      with:
        name: SemiconductorHMI-${{ matrix.os }}
        path: dist/
```

== 업데이트 메커니즘

=== 버전 체크

```python
import requests
from packaging import version

class UpdateChecker:
    def __init__(self, current_version: str):
        self.current_version = current_version
        self.update_url = "https://example.com/api/version"

    def check_for_updates(self) -> tuple[bool, str | None]:
        try:
            response = requests.get(self.update_url, timeout=5)
            data = response.json()
            latest_version = data['version']

            if version.parse(latest_version) > version.parse(self.current_version):
                return True, latest_version

            return False, None
        except Exception as e:
            logger.error(f"Update check failed: {e}")
            return False, None

# 사용
checker = UpdateChecker("1.0.0")
has_update, new_version = checker.check_for_updates()
if has_update:
    print(f"New version available: {new_version}")
```

== 실습 과제

=== 과제 1: 실행 파일 생성

+ PyInstaller로 실행 파일 생성
+ 리소스 파일 포함
+ 아이콘 설정

=== 과제 2: 테스트 작성

+ pytest로 단위 테스트 10개 이상
+ pytest-qt로 UI 테스트
+ 커버리지 80% 이상

=== 과제 3: 인스톨러 생성

+ Windows: Inno Setup
+ Linux: AppImage 또는 .deb
+ 사용자 가이드 작성

== 요약

이번 챕터에서는 배포를 학습했습니다:

- 가상 환경과 의존성 관리
- PyInstaller 실행 파일 생성
- pytest 테스트
- 로깅 및 에러 처리
- 크로스 플랫폼 배포
- CI/CD

다음 챕터에서는 ImGui C++를 학습합니다.

#pagebreak()
