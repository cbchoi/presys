= Week 7: Python 실시간 데이터 처리 및 PyQtGraph

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ QTimer를 활용한 주기적 데이터 수집
+ QThread를 활용한 백그라운드 작업
+ PyQtGraph를 사용한 실시간 차트
+ 데이터 버퍼링 및 최적화

== QTimer

=== 기본 사용법

```python
from PySide6.QtCore import QTimer

class DataCollector(QObject):
    def __init__(self):
        super().__init__()
        self.timer = QTimer()
        self.timer.timeout.connect(self.collect_data)

    def start(self):
        self.timer.start(100)  # 100ms 간격

    def stop(self):
        self.timer.stop()

    @Slot()
    def collect_data(self):
        # 데이터 수집
        data = self.read_sensor()
        print(f"Data: {data}")
```

=== 단발성 타이머

```python
# 1초 후 한 번만 실행
QTimer.singleShot(1000, self.delayed_action)
```

== QThread

=== 백그라운드 작업

```python
from PySide6.QtCore import QThread, Signal

class DataWorker(QThread):
    data_ready = Signal(object)
    error_occurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._running = False

    def run(self):
        self._running = True
        while self._running:
            try:
                data = self.collect_data()
                self.data_ready.emit(data)
                self.msleep(100)  # 100ms 대기
            except Exception as e:
                self.error_occurred.emit(str(e))
                self._running = False

    def stop(self):
        self._running = False
        self.wait()

    def collect_data(self) -> ProcessData:
        # 실제 데이터 수집 로직
        return ProcessData(
            timestamp=datetime.now(),
            temperature=450.0 + random.uniform(-5, 5),
            pressure=2.5 + random.uniform(-0.2, 0.2),
            flow_rate=100.0 + random.uniform(-10, 10)
        )

# 사용
worker = DataWorker()
worker.data_ready.connect(on_data_ready)
worker.error_occurred.connect(on_error)
worker.start()
```

=== QThreadPool

```python
from PySide6.QtCore import QRunnable, QThreadPool

class DataTask(QRunnable):
    def __init__(self, equipment_id: str):
        super().__init__()
        self.equipment_id = equipment_id

    def run(self):
        # 데이터 수집
        data = collect_data_from_equipment(self.equipment_id)
        # 결과 처리

# 사용
pool = QThreadPool.globalInstance()
pool.setMaxThreadCount(4)

for eq_id in ["CVD-01", "PVD-02", "ETCH-03"]:
    task = DataTask(eq_id)
    pool.start(task)
```

== PyQtGraph

=== 설치 및 기본 설정

```python
import pyqtgraph as pg

# 글로벌 설정
pg.setConfigOptions(antialias=True)
pg.setConfigOption('background', 'w')
pg.setConfigOption('foreground', 'k')
```

=== 실시간 라인 차트

```python
class RealtimeChart(QWidget):
    def __init__(self):
        super().__init__()
        self.setup_ui()

        # 데이터 버퍼
        self.time_data = []
        self.temp_data = []
        self.max_points = 100

    def setup_ui(self):
        layout = QVBoxLayout()

        # PyQtGraph 위젯
        self.plot_widget = pg.PlotWidget()
        self.plot_widget.setLabel('left', 'Temperature', units='°C')
        self.plot_widget.setLabel('bottom', 'Time', units='s')
        self.plot_widget.setTitle('Real-time Temperature')

        # 그리드
        self.plot_widget.showGrid(x=True, y=True, alpha=0.3)

        # 곡선 생성
        self.curve = self.plot_widget.plot(
            pen=pg.mkPen(color='#3498db', width=2)
        )

        layout.addWidget(self.plot_widget)
        self.setLayout(layout)

    def update_data(self, timestamp: float, temperature: float):
        self.time_data.append(timestamp)
        self.temp_data.append(temperature)

        # 최대 포인트 수 유지
        if len(self.time_data) > self.max_points:
            self.time_data = self.time_data[-self.max_points:]
            self.temp_data = self.temp_data[-self.max_points:]

        # 차트 업데이트
        self.curve.setData(self.time_data, self.temp_data)
```

=== 다중 곡선

```python
class MultiCurveChart(QWidget):
    def __init__(self):
        super().__init__()
        self.setup_ui()

    def setup_ui(self):
        self.plot_widget = pg.PlotWidget()
        self.plot_widget.addLegend()

        # 여러 곡선
        self.temp_curve = self.plot_widget.plot(
            pen=pg.mkPen(color='#e74c3c', width=2),
            name='Temperature'
        )
        self.pressure_curve = self.plot_widget.plot(
            pen=pg.mkPen(color='#3498db', width=2),
            name='Pressure'
        )
        self.flow_curve = self.plot_widget.plot(
            pen=pg.mkPen(color='#2ecc71', width=2),
            name='Flow Rate'
        )

        layout = QVBoxLayout()
        layout.addWidget(self.plot_widget)
        self.setLayout(layout)
```

=== ViewBox와 축 연결

```python
# 왼쪽/오른쪽 Y축 사용
plot_widget = pg.PlotWidget()
view_box2 = pg.ViewBox()
plot_widget.scene().addItem(view_box2)
plot_widget.getAxis('right').linkToView(view_box2)
view_box2.setXLink(plot_widget)

# 첫 번째 곡선 (왼쪽 축)
curve1 = plot_widget.plot(pen='r')

# 두 번째 곡선 (오른쪽 축)
curve2 = pg.PlotCurveItem(pen='b')
view_box2.addItem(curve2)
```

== 데이터 버퍼링

=== 순환 버퍼

```python
from collections import deque

class CircularBuffer:
    def __init__(self, maxlen: int):
        self.buffer = deque(maxlen=maxlen)

    def append(self, data):
        self.buffer.append(data)

    def get_all(self):
        return list(self.buffer)

    def get_last_n(self, n: int):
        return list(self.buffer)[-n:]
```

=== NumPy 버퍼

```python
import numpy as np

class NumpyBuffer:
    def __init__(self, maxlen: int):
        self.maxlen = maxlen
        self.data = np.zeros(maxlen)
        self.index = 0
        self.full = False

    def append(self, value: float):
        self.data[self.index] = value
        self.index += 1

        if self.index >= self.maxlen:
            self.index = 0
            self.full = True

    def get_all(self):
        if self.full:
            # 순서 재정렬
            return np.roll(self.data, -self.index)
        else:
            return self.data[:self.index]
```

== 통합 예제

=== 실시간 모니터링 시스템

```python
class MonitoringSystem(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Real-time Monitoring System")
        self.setGeometry(100, 100, 1400, 900)

        # 데이터 워커
        self.worker = DataWorker()
        self.worker.data_ready.connect(self.on_data_ready)

        # 버퍼
        self.time_buffer = CircularBuffer(maxlen=100)
        self.temp_buffer = CircularBuffer(maxlen=100)
        self.pressure_buffer = CircularBuffer(maxlen=100)

        self.setup_ui()

    def setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        layout = QVBoxLayout()

        # Header
        header_layout = QHBoxLayout()
        header_label = QLabel("Real-time Monitoring")
        header_label.setStyleSheet("font-size: 24px; font-weight: bold;")
        header_layout.addWidget(header_label)

        self.start_button = QPushButton("Start")
        self.stop_button = QPushButton("Stop")
        self.start_button.clicked.connect(self.start_monitoring)
        self.stop_button.clicked.connect(self.stop_monitoring)
        header_layout.addWidget(self.start_button)
        header_layout.addWidget(self.stop_button)

        layout.addLayout(header_layout)

        # 차트
        chart_layout = QGridLayout()

        # Temperature chart
        self.temp_chart = pg.PlotWidget(title="Temperature")
        self.temp_chart.setLabel('left', 'Temperature', units='°C')
        self.temp_curve = self.temp_chart.plot(pen='r')
        chart_layout.addWidget(self.temp_chart, 0, 0)

        # Pressure chart
        self.pressure_chart = pg.PlotWidget(title="Pressure")
        self.pressure_chart.setLabel('left', 'Pressure', units='Torr')
        self.pressure_curve = self.pressure_chart.plot(pen='b')
        chart_layout.addWidget(self.pressure_chart, 0, 1)

        layout.addLayout(chart_layout)

        # 상태 표시
        self.status_label = QLabel("Ready")
        layout.addWidget(self.status_label)

        central_widget.setLayout(layout)

    @Slot()
    def start_monitoring(self):
        self.worker.start()
        self.status_label.setText("Monitoring...")

    @Slot()
    def stop_monitoring(self):
        self.worker.stop()
        self.status_label.setText("Stopped")

    @Slot(object)
    def on_data_ready(self, data: ProcessData):
        # 버퍼에 추가
        timestamp = data.timestamp.timestamp()
        self.time_buffer.append(timestamp)
        self.temp_buffer.append(data.temperature)
        self.pressure_buffer.append(data.pressure)

        # 차트 업데이트
        time_data = self.time_buffer.get_all()
        temp_data = self.temp_buffer.get_all()
        pressure_data = self.pressure_buffer.get_all()

        self.temp_curve.setData(time_data, temp_data)
        self.pressure_curve.setData(time_data, pressure_data)

        # 알람 체크
        if data.temperature > 480:
            self.show_alarm("Temperature too high!")
```

== 성능 최적화

=== 다운샘플링

```python
# PyQtGraph 다운샘플링
curve.setDownsampling(auto=True, method='peak')
```

=== 클리핑

```python
# 보이는 영역만 그리기
plot_widget.setClipToView(True)
```

=== OpenGL 가속

```python
# OpenGL 활성화
plot_widget.useOpenGL(True)
```

== 데이터 저장

=== CSV 저장

```python
import csv

class DataLogger:
    def __init__(self, filename: str):
        self.filename = filename
        self.file = open(filename, 'w', newline='')
        self.writer = csv.writer(self.file)
        self.writer.writerow(['Timestamp', 'Temperature', 'Pressure', 'FlowRate'])

    def log(self, data: ProcessData):
        self.writer.writerow([
            data.timestamp.isoformat(),
            data.temperature,
            data.pressure,
            data.flow_rate
        ])

    def close(self):
        self.file.close()
```

=== HDF5 저장

```python
import h5py
import numpy as np

class HDF5Logger:
    def __init__(self, filename: str):
        self.file = h5py.File(filename, 'w')
        self.datasets = {
            'timestamp': self.file.create_dataset(
                'timestamp', (0,), maxshape=(None,), dtype='f8'
            ),
            'temperature': self.file.create_dataset(
                'temperature', (0,), maxshape=(None,), dtype='f8'
            )
        }

    def log(self, data: ProcessData):
        for key, dataset in self.datasets.items():
            dataset.resize(dataset.shape[0] + 1, axis=0)
            dataset[-1] = getattr(data, key)

    def close(self):
        self.file.close()
```

== 실습 과제

=== 과제 1: 실시간 차트 구현

+ 3개 파라미터 실시간 차트
+ 자동 스크롤링
+ 범위 자동 조정

=== 과제 2: 멀티스레드 데이터 수집

+ QThread를 사용한 백그라운드 수집
+ 여러 장비 동시 모니터링
+ 에러 처리

=== 과제 3: 데이터 로깅

+ CSV/HDF5 로깅
+ 실시간 파일 쓰기
+ 데이터 재생 기능

== 요약

이번 챕터에서는 실시간 데이터 처리를 학습했습니다:

- QTimer 주기적 작업
- QThread 백그라운드 처리
- PyQtGraph 실시간 차트
- 데이터 버퍼링
- 성능 최적화
- 데이터 저장

다음 챕터에서는 고급 기능을 학습합니다.

#pagebreak()
