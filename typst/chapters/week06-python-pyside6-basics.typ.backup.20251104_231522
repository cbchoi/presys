= Week 6: Python PySide6 기초 및 Qt Designer

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ Python 3.11+ 고급 기능
+ PySide6 아키텍처와 Signal/Slot
+ Qt Designer를 활용한 UI 설계
+ MVC 패턴 적용

== Python 3.11+ 주요 기능

=== Type Hints

```python
from typing import Protocol

class Equipment(Protocol):
    id: str
    name: str
    temperature: float

def monitor_equipment(eq: Equipment) -> dict[str, float]:
    return {
        "temp": eq.temperature,
        "pressure": get_pressure(eq)
    }
```

=== Dataclasses

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass
class ProcessData:
    timestamp: datetime
    temperature: float
    pressure: float
    flow_rate: float

    def is_normal(self) -> bool:
        return (
            400 \<= self.temperature \<= 480 and
            2.0 \<= self.pressure \<= 3.0
        )
```

=== Pattern Matching

```python
def handle_alarm(severity: str, message: str):
    match severity:
        case "CRITICAL":
            stop_equipment()
            send_notification(message)
        case "WARNING":
            log_warning(message)
        case "INFO":
            log_info(message)
        case _:
            pass
```

== PySide6 설치 및 설정

=== 설치

```bash
pip install PySide6
pip install pyqtgraph  # 차트용
pip install qtawesome  # 아이콘용
```

=== 기본 애플리케이션

```python
import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget
from PySide6.QtCore import Qt

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Semiconductor HMI")
        self.setGeometry(100, 100, 1200, 800)

        # Central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
```

== Signal과 Slot

=== 기본 Signal/Slot

```python
from PySide6.QtCore import Signal, Slot, QObject

class TemperatureSensor(QObject):
    temperature_changed = Signal(float)

    def __init__(self):
        super().__init__()
        self._temperature = 0.0

    @property
    def temperature(self) -> float:
        return self._temperature

    @temperature.setter
    def temperature(self, value: float):
        if self._temperature != value:
            self._temperature = value
            self.temperature_changed.emit(value)

# 사용
sensor = TemperatureSensor()

@Slot(float)
def on_temperature_changed(temp: float):
    print(f"Temperature: {temp}°C")

sensor.temperature_changed.connect(on_temperature_changed)
sensor.temperature = 450.0  # Signal 발생
```

=== 커스텀 Signal

```python
class Equipment(QObject):
    started = Signal()
    stopped = Signal()
    alarm_triggered = Signal(str, str)  # severity, message

    def start(self):
        self.started.emit()

    def stop(self):
        self.stopped.emit()

    def check_status(self):
        if self.temperature > 480:
            self.alarm_triggered.emit("CRITICAL", "Temperature too high")
```

== Qt Designer

=== UI 파일 생성

Qt Designer에서 `.ui` 파일 생성 후 Python으로 변환:

```bash
pyside6-uic mainwindow.ui -o ui_mainwindow.py
```

=== UI 파일 사용

```python
from ui_mainwindow import Ui_MainWindow

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

        # Signal 연결
        self.ui.startButton.clicked.connect(self.on_start)
        self.ui.stopButton.clicked.connect(self.on_stop)

    @Slot()
    def on_start(self):
        print("Start button clicked")

    @Slot()
    def on_stop(self):
        print("Stop button clicked")
```

== 레이아웃

=== QVBoxLayout

```python
from PySide6.QtWidgets import QVBoxLayout, QLabel, QPushButton

layout = QVBoxLayout()
layout.addWidget(QLabel("Temperature:"))
layout.addWidget(QLabel("450.0°C"))
layout.addWidget(QPushButton("Start"))

widget = QWidget()
widget.setLayout(layout)
```

=== QHBoxLayout

```python
from PySide6.QtWidgets import QHBoxLayout

layout = QHBoxLayout()
layout.addWidget(QPushButton("Start"))
layout.addWidget(QPushButton("Stop"))
layout.addWidget(QPushButton("Reset"))
```

=== QGridLayout

```python
from PySide6.QtWidgets import QGridLayout

layout = QGridLayout()
layout.addWidget(QLabel("Temperature:"), 0, 0)
layout.addWidget(QLabel("450.0°C"), 0, 1)
layout.addWidget(QLabel("Pressure:"), 1, 0)
layout.addWidget(QLabel("2.5 Torr"), 1, 1)
```

== 위젯

=== QPushButton

```python
button = QPushButton("Start")
button.setMinimumSize(100, 40)
button.setStyleSheet("""
    QPushButton {
        background-color: #3498db;
        color: white;
        border: none;
        border-radius: 5px;
        font-size: 14px;
    }
    QPushButton:hover {
        background-color: #2980b9;
    }
    QPushButton:pressed {
        background-color: #21618c;
    }
""")
button.clicked.connect(on_start)
```

=== QLabel

```python
label = QLabel("Temperature: 450.0°C")
label.setStyleSheet("""
    QLabel {
        font-size: 16px;
        color: #2c3e50;
        padding: 10px;
    }
""")
label.setAlignment(Qt.AlignCenter)
```

=== QLineEdit

```python
line_edit = QLineEdit()
line_edit.setPlaceholderText("Enter setpoint...")
line_edit.textChanged.connect(on_text_changed)

@Slot(str)
def on_text_changed(text: str):
    print(f"Text: {text}")
```

=== QComboBox

```python
combo = QComboBox()
combo.addItems(["CVD", "PVD", "ETCH", "CMP"])
combo.currentTextChanged.connect(on_selection_changed)

@Slot(str)
def on_selection_changed(text: str):
    print(f"Selected: {text}")
```

== MVC 패턴

=== Model

```python
class EquipmentModel(QObject):
    data_changed = Signal()

    def __init__(self):
        super().__init__()
        self._data = ProcessData(
            timestamp=datetime.now(),
            temperature=0.0,
            pressure=0.0,
            flow_rate=0.0
        )

    @property
    def data(self) -> ProcessData:
        return self._data

    def update_data(self, data: ProcessData):
        self._data = data
        self.data_changed.emit()
```

=== View

```python
class EquipmentView(QWidget):
    def __init__(self, model: EquipmentModel):
        super().__init__()
        self.model = model

        # UI 구성
        self.temp_label = QLabel()
        self.pressure_label = QLabel()

        layout = QVBoxLayout()
        layout.addWidget(self.temp_label)
        layout.addWidget(self.pressure_label)
        self.setLayout(layout)

        # Model 연결
        self.model.data_changed.connect(self.update_display)
        self.update_display()

    @Slot()
    def update_display(self):
        data = self.model.data
        self.temp_label.setText(f"Temperature: {data.temperature:.1f}°C")
        self.pressure_label.setText(f"Pressure: {data.pressure:.2f} Torr")
```

=== Controller

```python
class EquipmentController:
    def __init__(self, model: EquipmentModel):
        self.model = model
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_data)

    def start(self):
        self.timer.start(100)  # 100ms

    def stop(self):
        self.timer.stop()

    @Slot()
    def update_data(self):
        # 데이터 수집 (시뮬레이션)
        data = ProcessData(
            timestamp=datetime.now(),
            temperature=450.0 + random.uniform(-5, 5),
            pressure=2.5 + random.uniform(-0.2, 0.2),
            flow_rate=100.0 + random.uniform(-10, 10)
        )
        self.model.update_data(data)
```

== 스타일시트

=== QSS (Qt Style Sheets)

```python
stylesheet = """
QMainWindow {
    background-color: #ecf0f1;
}

QPushButton {
    background-color: #3498db;
    color: white;
    border: none;
    border-radius: 5px;
    padding: 10px;
    font-size: 14px;
}

QPushButton:hover {
    background-color: #2980b9;
}

QPushButton:pressed {
    background-color: #21618c;
}

QLabel {
    color: #2c3e50;
    font-size: 14px;
}

QGroupBox {
    border: 2px solid #bdc3c7;
    border-radius: 5px;
    margin-top: 10px;
    font-weight: bold;
}

QGroupBox::title {
    subcontrol-origin: margin;
    left: 10px;
    padding: 0 5px;
}
"""

app.setStyleSheet(stylesheet)
```

== 실습: 기본 HMI 애플리케이션

=== 요구사항

+ 메인 윈도우 with 메뉴바
+ 장비 선택 콤보박스
+ 실시간 파라미터 표시
+ 시작/정지 버튼

=== 구현

```python
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Semiconductor Equipment HMI")
        self.setGeometry(100, 100, 1200, 800)

        # Model & Controller
        self.model = EquipmentModel()
        self.controller = EquipmentController(self.model)

        # UI 구성
        self.setup_ui()
        self.setup_menu()

    def setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        layout = QVBoxLayout()

        # Header
        header = QLabel("Semiconductor Equipment HMI")
        header.setStyleSheet("font-size: 24px; font-weight: bold;")
        layout.addWidget(header)

        # Equipment selector
        self.equipment_combo = QComboBox()
        self.equipment_combo.addItems(["CVD-01", "PVD-02", "ETCH-03"])
        layout.addWidget(self.equipment_combo)

        # View
        self.view = EquipmentView(self.model)
        layout.addWidget(self.view)

        # Buttons
        button_layout = QHBoxLayout()
        self.start_button = QPushButton("Start")
        self.stop_button = QPushButton("Stop")
        self.start_button.clicked.connect(self.controller.start)
        self.stop_button.clicked.connect(self.controller.stop)
        button_layout.addWidget(self.start_button)
        button_layout.addWidget(self.stop_button)
        layout.addLayout(button_layout)

        central_widget.setLayout(layout)

    def setup_menu(self):
        menubar = self.menuBar()

        # File menu
        file_menu = menubar.addMenu("File")
        exit_action = file_menu.addAction("Exit")
        exit_action.triggered.connect(self.close)

        # View menu
        view_menu = menubar.addMenu("View")
        view_menu.addAction("Dashboard")
        view_menu.addAction("Alarms")
```

== 실습 과제

=== 과제 1: Qt Designer UI

+ Qt Designer로 메인 윈도우 설계
+ 레이아웃 및 위젯 배치
+ Python 코드로 변환 및 연결

=== 과제 2: Signal/Slot 활용

+ 커스텀 Signal 5개 이상 정의
+ Slot 함수 구현
+ Signal/Slot 연결

=== 과제 3: MVC 패턴 구현

+ Model, View, Controller 분리
+ 실시간 데이터 업데이트
+ 사용자 입력 처리

== 요약

이번 챕터에서는 PySide6 기초를 학습했습니다:

- Python 3.11+ 고급 기능
- PySide6 아키텍처
- Signal과 Slot
- Qt Designer
- 레이아웃과 위젯
- MVC 패턴
- 스타일시트

다음 챕터에서는 실시간 데이터 처리를 학습합니다.

#pagebreak()
