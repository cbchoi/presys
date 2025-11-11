= Week 7: Python 실시간 데이터 처리 및 PyQtGraph
== 학습 목표
본 챕터에서는 다음을 학습한다: + Python 동시성 모델과 GIL의 영향
+ QThread를 활용한 백그라운드 데이터 수집
+ 디자인 패턴 적용 (Producer-Consumer, Worker Thread, Thread-safe Singleton)
+ PyQtGraph를 사용한 실시간 차트 시각화
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *Python threading 기초*: Thread, Lock, Event 개념
- *Qt Signal/Slot*: Week 6에서 학습한 Signal/Slot 메커니즘
- *기초 자료구조*: Queue, Deque 사용법
- *NumPy 기초*: 배열 생성, 인덱싱, 슬라이싱
- *권장사항*: Week 6 PySide6 기초 학습 완료
== Python 동시성 이론
=== Python 동시성 모델의 종류
Python은 세 가지 주요 동시성 모델을 제공한다: #figure(table(columns: (auto, auto, auto, auto), align: left, [*모델*], [*모듈*], [*GIL 영향*], [*사용 사례*], [Threading], [`threading`], [높음], [I/O-bound 작업], [Multiprocessing], [`multiprocessing`], [없음], [CPU-bound 작업], [Async/Await], [`asyncio`], [낮음], [대량 I/O 작업], ), caption: "Python 동시성 모델 비교")
=== GIL (Global Interpreter Lock) 심화
==== GIL의 동작 원리
GIL은 CPython 인터프리터에서 한 번에 하나의 스레드만 Python 바이트코드를 실행하도록 보장하는 뮤텍스이다.
```
[Thread 1]          [GIL]          [Thread 2]
    │                 │                 │
    ├─→ 요청 GIL ────→│                 │
    │                 ├─→ 획득           │
    ├─→ 실행 (100 틱)  │                 │
    │                 │                 │
    ├─→ GIL 해제 ─────→│                 │
    │                 │←── 요청 GIL ────┤
    │                 ├─→ 획득           │
    │                 │                 ├─→ 실행
    │                 │                 │
```
*GIL 해제 시점: *
- I/O 작업 (파일, 네트워크, time.sleep())
- C 확장 함수 내부 (NumPy, OpenCV 등)
- sys.setswitchinterval() 간격마다 (기본값: 5ms)
==== GIL의 영향 실험
```python
import threading
import time
# CPU-bound 작업
def cpu_bound(n): total = 0
    for i in range(n): total += i * i
    return total
# 단일 스레드
start = time.time()
cpu_bound(10_000_000)
cpu_bound(10_000_000)
single_time = time.time() - start
# 멀티 스레드
start = time.time()
t1 = threading.Thread(target=cpu_bound, args=(10_000_000, ))
t2 = threading.Thread(target=cpu_bound, args=(10_000_000, ))
t1.start()
t2.start()
t1.join()
t2.join()
multi_time = time.time() - start
print(f"Single: {single_time: .2f}s")
print(f"Multi: {multi_time: .2f}s")
# 결과: Multi가 오히려 느릴 수 있음 (컨텍스트 스위칭 오버헤드)
```
=== Python Threading vs Multiprocessing
```python
# Threading 예제 (I/O-bound)
import threading
import requests
def download(url): response = requests.get(url)  # GIL 해제됨
    return len(response.content)
threads = [threading.Thread(target=download, args=(url, )) for url in urls]
for t in threads: t.start()
for t in threads: t.join()
# Multiprocessing 예제 (CPU-bound)
import multiprocessing
def compute(data): return sum(x * x for x in data)
with multiprocessing.Pool(4) as pool: results = pool.map(compute, datasets)
```
=== Qt Threading 모델
==== Qt의 스레딩 철학
Qt는 "스레드 친화성(Thread Affinity)"을 기반으로 한다. 각 QObject는 생성된 스레드에 속하며, 해당 스레드에서만 직접 호출되어야 한다.
```
[Main Thread]               [Worker Thread]
     │                            │
     ├─→ QObject 생성             │
     │   (affinity: Main)         │
     │                            │
     │                            ├─→ QObject 생성
     │                            │   (affinity: Worker)
     │                            │
     │←──── Signal ──────────────┤ (자동으로 큐잉됨)
     ├─→ Slot 실행 (Main)         │
     │                            │
```
*주요 원칙: *
- UI 업데이트는 오직 메인 스레드에서만 가능
- Signal/Slot은 자동으로 스레드 경계를 넘음 (Qt: :QueuedConnection)
- `QThread: :moveToThread()`로 객체의 스레드 친화성 변경 가능
==== QThread 내부 구조
```
QThread 생성
    │
    ↓
start() 호출
    │
    ↓
새 OS 스레드 생성
    │
    ↓
run() 메서드 실행
    │
    ├─→ exec() 호출 (이벤트 루프 시작)
    │       │
    │       ├─→ 이벤트 처리
    │       ├─→ Signal/Slot 처리
    │       └─→ quit() 시 종료
    │
    ↓
finished Signal 발생
```
=== Python threading vs Qt QThread 비교
#figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*Python threading*], [*Qt QThread*], [생성 방법], [`Thread(target=func)`], [`QThread` 상속], [시작], [`start()`], [`start()`], [종료], [`join()`], [`wait()`], [이벤트 루프], [없음], [`exec()` 호출 시], [Signal/Slot], [미지원], [지원], [UI 통신], [수동 (queue, lock)], [자동 (Signal)], [GIL], [영향받음], [영향받음 (Python 코드)], ), caption: "Python threading vs Qt QThread 비교")
*반도체 HMI 권장사항: *
- UI 통신이 필요한 경우: QThread + Signal (권장)
- 순수 CPU 계산: multiprocessing.Pool
- 대량 센서 읽기: QThread + QTimer
== Python 동시성 모델 심화
Python은 동시성 문제를 해결하기 위해 세 가지 주요 모델을 제공한다. 각 모델의 이론적 기반과 적용 시나리오를 이해하는 것이 critical하다.
=== asyncio - 이벤트 루프 기반 동시성
*asyncio의 이론적 기반*: asyncio는 **단일 스레드**에서 **비선점형 멀티태스킹 (Cooperative Multitasking)** 을 구현한다. 이는 Node.js의 이벤트 루프와 유사한 아키텍처이다.
```
┌────────────────────────────────────────────────────────┐
│               asyncio Event Loop                       │
└────────────────────────────────────────────────────────┘
Task Queue:
┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
│ T1  │→│ T2  │→│ T3  │→│ T4  │→ ...
└─────┘  └─────┘  └─────┘  └─────┘
Event Loop Cycle:
1. Task 선택
2. await까지 실행 (CPU 점유)
3. I/O 대기 → 다음 Task로 전환
4. I/O 완료 → Task Queue에 다시 추가
5. 반복
```
*asyncio 내부 동작*: ```python
import asyncio
import time
async def sensor_read(sensor_id: int): print(f"[{time.time(): .2f}] Sensor {sensor_id}: Start")
  await asyncio.sleep(1) # ← 여기서 제어권 반환
  print(f"[{time.time(): .2f}] Sensor {sensor_id}: Done")
  return sensor_id * 100
# 순차 실행 (3초 소요)
async def sequential(): start = time.time()
  r1 = await sensor_read(1)
  r2 = await sensor_read(2)
  r3 = await sensor_read(3)
  print(f"Sequential: {time.time() - start: .2f}s")
  # 출력: Sequential: 3.00s
# 동시 실행 (1초 소요)
async def concurrent(): start = time.time()
  results = await asyncio.gather(sensor_read(1), sensor_read(2), sensor_read(3))
  print(f"Concurrent: {time.time() - start: .2f}s")
  # 출력: Concurrent: 1.00s
# 실행
asyncio.run(concurrent())
```
*asyncio의 장단점*: #figure(table(columns: (auto, auto), align: left, [*장점*], [*단점*], [단일 스레드 (GIL 영향 없음)], [CPU-bound 작업 불가], [메모리 효율적 (스레드 생성 불필요)], [라이브러리 지원 제한 (`async` 필요)], [대량 I/O 작업에 최적], [디버깅 어려움], [Context switching 빠름], [Blocking 코드 혼용 시 문제], ), caption: "asyncio 장단점")
*반도체 산업 적용*: - 대량 네트워크 센서 폴링 (100+ 센서)
- SECS/GEM 통신 (비동기 메시지 처리)
- 실시간 로그 집계
```python
# 100개 센서 비동기 읽기 예시
async def read_all_sensors(): sensors = range(1, 101)
  tasks = [sensor_read(s) for s in sensors]
  results = await asyncio.gather(*tasks)
  return results
# 100개 센서를 1초 안에 읽기 가능 (순차 실행 시 100초)
```
=== threading vs multiprocessing 비교 이론
*메모리 모델 차이*: ```
┌──────────────────────────────────────────────────────┐
│               threading (공유 메모리)                 │
└──────────────────────────────────────────────────────┘
Process (PID: 1234)
│
├─ Thread 1 ─┐
├─ Thread 2 ─┼─→ 공유 메모리 (Heap, Global Variables)
├─ Thread 3 ─┘
│
└─ GIL (한 번에 1개 스레드만 Python 실행)
┌──────────────────────────────────────────────────────┐
│            multiprocessing (독립 메모리)              │
└──────────────────────────────────────────────────────┘
Process 1 (PID: 1234) → 독립 메모리 1
Process 2 (PID: 1235) → 독립 메모리 2
Process 3 (PID: 1236) → 독립 메모리 3
각 프로세스는 독립적인 GIL 보유
→ 진정한 병렬 실행 가능
```
*성능 비교 실험*: ```python
import time
import threading
import multiprocessing
def cpu_bound_task(n): """CPU-bound: 순수 계산"""
  total = 0
  for i in range(n): total += i ** 2
  return total
def io_bound_task(url): """I/O-bound: 네트워크 요청"""
  import requests
  response = requests.get(url)
  return len(response.content)
# === CPU-bound 비교 ===
# 순차 실행
start = time.time()
for _ in range(4): cpu_bound_task(10_000_000)
print(f"Sequential: {time.time() - start: .2f}s")
# 출력: Sequential: 4.80s
# threading (GIL로 인해 효과 없음)
start = time.time()
threads = [threading.Thread(target=cpu_bound_task, args=(10_000_000, ))
  for _ in range(4)]
for t in threads: t.start()
for t in threads: t.join()
print(f"Threading: {time.time() - start: .2f}s")
# 출력: Threading: 4.90s (오히려 느림!)
# multiprocessing (진정한 병렬 실행)
start = time.time()
with multiprocessing.Pool(4) as pool: pool.map(cpu_bound_task, [10_000_000] * 4)
print(f"Multiprocessing: {time.time() - start: .2f}s")
# 출력: Multiprocessing: 1.25s (4배 빠름!)
# === I/O-bound 비교 ===
urls = ["https: //example.com"] * 10
# 순차 실행
start = time.time()
for url in urls: io_bound_task(url)
print(f"Sequential: {time.time() - start: .2f}s")
# 출력: Sequential: 5.20s
# threading (GIL 해제되어 효과 있음)
start = time.time()
threads = [threading.Thread(target=io_bound_task, args=(url, ))
  for url in urls]
for t in threads: t.start()
for t in threads: t.join()
print(f"Threading: {time.time() - start: .2f}s")
# 출력: Threading: 0.85s (6배 빠름!)
```
*선택 가이드*: #figure(table(columns: (auto, auto, auto, auto), align: left, [*작업 유형*], [*threading*], [*multiprocessing*], [*asyncio*], [CPU-bound], [❌ 느림 (GIL)], [✓ 빠름 (병렬)], [❌ 불가능], [I/O-bound], [✓ 빠름], [△ 오버헤드], [✓ 매우 빠름], [메모리 공유], [✓ 쉬움], [❌ IPC 필요], [✓ 쉬움], [디버깅], [△ 어려움], [❌ 매우 어려움], [△ 어려움], [오버헤드], [낮음], [높음 (프로세스 생성)], [매우 낮음], ), caption: "Python 동시성 모델 선택 가이드")
=== Qt QThread 내부 아키텍처
*QThread와 OS 스레드 관계*: QThread는 플랫폼별 OS 스레드의 추상화 레이어이다.
```
┌────────────────────────────────────────────────────────┐
│ Qt QThread │
└────────────────────────────────────────────────────────┘
Python Layer: class DataWorker(QThread): def run(self): ...
↓ (PySide6 바인딩)
C++ Layer: class QThread : public QObject {
  void start();
  void run();
  void quit();
  };
↓ (플랫폼별 구현)
OS Layer: Linux: pthread_create()
  Windows: CreateThread()
  macOS: pthread_create()
```
*QThread 생명주기*: ```
[Created]
    │
    ↓ start() 호출
[Starting]
    │
    ↓ OS 스레드 생성
[Running]
    │
    ├─→ run() 실행
    │   │
    │   ├─→ exec() 호출 시
    │   │   ↓
    │   │   [Event Loop Running]
    │   │   ├─→ Signal/Slot 처리
    │   │   ├─→ QTimer 이벤트 처리
    │   │   └─→ quit() 호출 시 종료
    │   │
    │   └─→ exec() 미호출 시
    │       ↓
    │       run() 종료 시 스레드 종료
    │
    ↓ run() 종료
[Finished] → finished Signal 발생
    │
    ↓ wait() 또는 자동 정리
[Terminated]
```
*QThread Event Loop 상세*: ```python
from PySide6.QtCore import QThread, QTimer, Signal, Slot
class TimerWorker(QThread): tick = Signal(int)
  def __init__(self): super().__init__()
  self.counter = 0
  def run(self): # 이벤트 루프 시작 전 타이머 설정
  timer = QTimer()
  timer.timeout.connect(self.on_timeout)
  timer.start(1000) # 1초마다
  # 이벤트 루프 시작 (블로킹)
  self.exec() # ← quit() 호출 시까지 여기서 대기
  # 이벤트 루프 종료 후 정리
  timer.stop()
  print("Event loop exited")
  @Slot()
  def on_timeout(self): self.counter += 1
  self.tick.emit(self.counter)
  if self.counter >= 10: self.quit() # 이벤트 루프 종료
# 사용
worker = TimerWorker()
worker.tick.connect(lambda n: print(f"Tick: {n}"))
worker.start()
worker.wait() # 스레드 종료 대기
```
*QThread Connection Types*: Qt Signal/Slot은 스레드 경계를 넘을 때 자동으로 연결 타입을 결정한다.
#figure(table(columns: (auto, auto, auto), align: left, [*Connection Type*], [*동작*], [*사용 시나리오*], [Auto (기본값)], [같은 스레드: Direct, 다른 스레드: Queued], [대부분의 경우], [Direct], [Slot을 즉시 호출 (함수 호출)], [같은 스레드, 빠른 응답], [Queued], [이벤트 큐에 추가 후 호출], [스레드 간 통신], [BlockingQueued], [Queued + 완료까지 대기], [동기식 호출 필요 시], ), caption: "Qt Signal Connection Types")
```python
from PySide6.QtCore import Qt
# 명시적 연결 타입 지정
sensor.data_changed.connect(view.update_display, Qt.QueuedConnection # ← 명시적 Queued)
# Direct Connection (빠르지만 스레드 안전하지 않음)
sensor.data_changed.connect(local_handler, Qt.DirectConnection)
```
== PyQtGraph 아키텍처 이론
PyQtGraph는 NumPy 배열을 직접 처리하여 Qt의 Graphics View Framework 위에서 고성능 렌더링을 제공한다.
=== PyQtGraph vs Matplotlib 비교
#figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*PyQtGraph*], [*Matplotlib*], [렌더링 백엔드], [Qt Graphics View], [다양 (Qt, Tk, Web)], [실시간 성능], [매우 빠름 (60 FPS)], [느림 (10 FPS)], [메모리 사용], [낮음], [높음], [데이터 타입], [NumPy 배열 직접], [리스트/NumPy 변환], [인터랙션], [빠름 (줌, 패닝)], [느림], [출판 품질], [낮음], [높음 (벡터)], [사용 사례], [실시간 모니터링], [정적 그래프, 논문], ), caption: "PyQtGraph vs Matplotlib 비교")
=== PyQtGraph 렌더링 파이프라인
```
┌────────────────────────────────────────────────────────┐
│ PyQtGraph Rendering Pipeline │
└────────────────────────────────────────────────────────┘
1. Data Update (Python)
  ↓
  curve.setData(x_array, y_array) # NumPy 배열
  ↓
2. Data Validation (C/NumPy)
  ↓
  - 타입 검사 (ndarray인가?)
  - 길이 검사 (x와 y 길이 동일?)
  ↓
3. Path Generation (Qt QPainterPath)
  ↓
  - 데이터 포인트 → 벡터 경로 변환
  - 다운샘플링 적용 (옵션)
  ↓
4. Graphics Item Update (QGraphicsItem)
  ↓
  - Bounding box 계산
  - Dirty region 표시
  ↓
5. Scene Rendering (QGraphicsScene)
  ↓
  - View transform 적용 (줌, 패닝)
  - Clipping (보이는 영역만)
  ↓
6. GPU Rendering (Optional: OpenGL)
  ↓
  - Hardware acceleration
  - Shader pipeline
  ↓
[화면 출력]
```
*성능 최적화 기법*: ```python
import pyqtgraph as pg
import numpy as np
# 1. OpenGL 활성화 (10배 빠름)
pg.setConfigOptions(useOpenGL=True)
# 2. 안티앨리어싱 비활성화 (2배 빠름)
pg.setConfigOptions(antialias=False)
# 3. 다운샘플링 (데이터 포인트 > 1000일 때)
plot_widget = pg.PlotWidget()
plot_widget.setDownsampling(auto=True)
plot_widget.setClipToView(True)
# 4. NumPy 배열 직접 사용 (리스트 변환 오버헤드 제거)
x = np.arange(10000)
y = np.sin(x / 100)
curve.setData(x, y)  # ✓ 빠름
# ❌ 느림: 리스트 사용
curve.setData(list(x), list(y))
# 5. Update 빈도 제한 (UI 스레드 부하 감소)
from PySide6.QtCore import QTimer
class ThrottledChart(pg.PlotWidget): def __init__(self): super().__init__()
        self._pending_data = None
        self._update_timer = QTimer()
        self._update_timer.timeout.connect(self._flush_update)
        self._update_timer.start(16)  # 60 FPS (16ms)
    def update_data(self, x, y): # 즉시 업데이트하지 않고 펜딩
        self._pending_data = (x, y)
    def _flush_update(self): if self._pending_data: x, y = self._pending_data
            self.curve.setData(x, y)
            self._pending_data = None
```
=== PyQtGraph Graphics Item Hierarchy
```
QGraphicsView (PyQtGraph의 PlotWidget)
    │
    ├─→ QGraphicsScene
    │       │
    │       ├─→ PlotItem (축, 타이틀, 레이블)
    │       │     │
    │       │     ├─→ AxisItem (X축, Y축)
    │       │     ├─→ LabelItem (타이틀)
    │       │     └─→ ViewBox (데이터 영역)
    │       │           │
    │       │           ├─→ PlotDataItem (곡선 1)
    │       │           ├─→ PlotDataItem (곡선 2)
    │       │           ├─→ ScatterPlotItem (산점도)
    │       │           └─→ ImageItem (히트맵)
    │       │
    │       └─→ LegendItem (범례)
```
*커스텀 Graphics Item 예시*: ```python
from pyqtgraph import GraphicsObject
from PySide6.QtGui import QPainter, QPen
from PySide6.QtCore import QRectF
import numpy as np
class CustomBarItem(GraphicsObject): """커스텀 막대 그래프"""
  def __init__(self, x, y): super().__init__()
  self.x = np.array(x)
  self.y = np.array(y)
  self.generatePicture()
  def generatePicture(self): # QPicture: 렌더링 명령을 캐싱 (성능 향상)
  self.picture = QPicture()
  painter = QPainter(self.picture)
  painter.setPen(QPen('#3498db'))
  width = 1.0
  for i in range(len(self.x)): painter.drawRect(QRectF(self.x[i] - width/2, 0, width, self.y[i]))
  painter.end()
  def paint(self, painter, option, widget): # 캐싱된 그림을 그림 (매우 빠름)
  painter.drawPicture(0, 0, self.picture)
  def boundingRect(self): return QRectF(self.picture.boundingRect())
# 사용
plot_widget = pg.PlotWidget()
bar_item = CustomBarItem(x=[1, 2, 3, 4], y=[10, 20, 15, 25])
plot_widget.addItem(bar_item)
```
=== 대용량 데이터 처리 전략
*문제*: 100, 000개 이상의 데이터 포인트를 실시간으로 표시하면 렌더링 성능 저하
*해결책*: 1. **Downsampling (Peak Mode)**: ```python
# 10만 포인트를 화면 픽셀 수에 맞춰 다운샘플링
plot_widget.setDownsampling(mode='peak')  # min/max 유지
plot_widget.setClipToView(True)  # 보이는 영역만 렌더링
# 결과: 100, 000 포인트 → 1, 000 포인트로 감소
# 시각적 차이 거의 없음, 렌더링 10배 빠름
```
2. **Rolling Window**: ```python
from collections import deque
class RollingBuffer: def __init__(self, maxlen=10000): self.x = deque(maxlen=maxlen)
  self.y = deque(maxlen=maxlen)
  def append(self, x_val, y_val): self.x.append(x_val)
  self.y.append(y_val)
  def get_arrays(self): return np.array(self.x), np.array(self.y)
# 최근 10, 000개만 유지
buffer = RollingBuffer(maxlen=10000)
for i in range(100000): buffer.append(i, np.sin(i / 100))
x, y = buffer.get_arrays()
curve.setData(x, y) # 10, 000개만 렌더링
```
3. **LOD (Level of Detail)**: ```python
# 줌 레벨에 따라 다른 해상도 표시
class LODChart: def __init__(self): self.full_data = None  # 전체 데이터
        self.decimated_data = {}  # {level: (x, y)}
    def set_data(self, x, y): self.full_data = (x, y)
        # 여러 해상도 생성
        self.decimated_data[1] = (x[: :10], y[: :10])  # 1/10
        self.decimated_data[2] = (x[: :100], y[: :100])  # 1/100
    def update_view(self, zoom_level): if zoom_level > 0.9: x, y = self.full_data
        elif zoom_level > 0.5: x, y = self.decimated_data[1]
        else: x, y = self.decimated_data[2]
        self.curve.setData(x, y)
```
== QTimer 기반 주기적 데이터 수집
=== QTimer 기본 사용법
```python
from PySide6.QtCore import QTimer, QObject, Slot
class DataCollector(QObject): def __init__(self): super().__init__()
        self.timer = QTimer()
        self.timer.timeout.connect(self.collect_data)
    def start(self, interval_ms: int = 100): self.timer.start(interval_ms)
    def stop(self): self.timer.stop()
    @Slot()
    def collect_data(self): # 데이터 수집 로직
        data = self.read_sensor()
        print(f"Data: {data}")
```
=== 단발성 타이머
```python
# 1초 후 한 번만 실행
QTimer.singleShot(1000, self.delayed_action)
# 람다 사용
QTimer.singleShot(500, lambda: print("Hello"))
```
== QThread를 활용한 백그라운드 작업
=== Worker Thread Pattern
```python
from PySide6.QtCore import QThread, Signal
from dataclasses import dataclass
from datetime import datetime
import random
@dataclass
class ProcessData: timestamp: datetime
    temperature: float
    pressure: float
    flow_rate: float
class DataWorker(QThread): data_ready = Signal(object)
    error_occurred = Signal(str)
    def __init__(self): super().__init__()
        self._running = False
    def run(self): """스레드 메인 루프"""
        self._running = True
        while self._running: try: data = self.collect_data()
                self.data_ready.emit(data)
                self.msleep(100)  # 100ms 대기
            except Exception as e: self.error_occurred.emit(str(e))
                self._running = False
    def stop(self): self._running = False
        self.wait()  # 스레드 종료 대기
    def collect_data(self) -> ProcessData: # 실제 센서 읽기 시뮬레이션
        return ProcessData(timestamp=datetime.now(), temperature=450.0 + random.uniform(-5, 5), pressure=2.5 + random.uniform(-0.2, 0.2), flow_rate=100.0 + random.uniform(-10, 10))
# 사용
worker = DataWorker()
worker.data_ready.connect(on_data_ready)
worker.error_occurred.connect(on_error)
worker.start()
```
=== Producer-Consumer Pattern
```python
from PySide6.QtCore import QThread, Signal, QMutex, QWaitCondition
from queue import Queue
import threading
class Producer(QThread): """데이터 생산자"""
    data_produced = Signal(object)
    def __init__(self, data_queue: Queue): super().__init__()
        self.data_queue = data_queue
        self._running = False
    def run(self): self._running = True
        while self._running: data = self.generate_data()
            self.data_queue.put(data)
            self.data_produced.emit(data)
            self.msleep(50)
    def generate_data(self): return {
            'timestamp': datetime.now(), 'value': random.uniform(0, 100)
        }
class Consumer(QThread): """데이터 소비자"""
    data_consumed = Signal(object)
    def __init__(self, data_queue: Queue): super().__init__()
        self.data_queue = data_queue
        self._running = False
    def run(self): self._running = True
        while self._running: if not self.data_queue.empty(): data = self.data_queue.get()
                self.process_data(data)
                self.data_consumed.emit(data)
            else: self.msleep(10)
    def process_data(self, data): # 데이터 처리 (예: 저장, 분석)
        pass
# 사용
data_queue = Queue(maxsize=100)
producer = Producer(data_queue)
consumer = Consumer(data_queue)
producer.start()
consumer.start()
```
=== Thread-safe Singleton Pattern
```python
import threading
from typing import List
class DataManager: """멀티스레드 환경에서 안전한 싱글톤"""
    _instance = None
    _lock = threading.Lock()
    def __new__(cls): if cls._instance is None: with cls._lock: if cls._instance is None: cls._instance = super().__new__(cls)
                    cls._instance._init_once()
        return cls._instance
    def _init_once(self): self._data_lock = threading.Lock()
        self._history: List[ProcessData] = []
        self._max_size = 1000
    def add_data(self, data: ProcessData): """Thread-safe 데이터 추가"""
        with self._data_lock: self._history.append(data)
            if len(self._history) > self._max_size: self._history.pop(0)
    def get_data(self) -> List[ProcessData]: """Thread-safe 데이터 읽기"""
        with self._data_lock: return self._history.copy()
    def get_latest(self, n: int = 10) -> List[ProcessData]: """최근 N개 데이터 반환"""
        with self._data_lock: return self._history[-n: ]
```
== PyQtGraph 실시간 차트
=== PyQtGraph 설치 및 기본 설정
```python
import pyqtgraph as pg
# 글로벌 설정
pg.setConfigOptions(antialias=True)
pg.setConfigOption('background', 'w')
pg.setConfigOption('foreground', 'k')
```
=== 실시간 라인 차트
```python
from PySide6.QtWidgets import QWidget, QVBoxLayout
import pyqtgraph as pg
from collections import deque
class RealtimeChart(QWidget): def __init__(self, max_points=100): super().__init__()
        self.max_points = max_points
        self.time_data = deque(maxlen=max_points)
        self.temp_data = deque(maxlen=max_points)
        self.setup_ui()
    def setup_ui(self): layout = QVBoxLayout()
        # PyQtGraph 위젯
        self.plot_widget = pg.PlotWidget()
        self.plot_widget.setLabel('left', 'Temperature', units='°C')
        self.plot_widget.setLabel('bottom', 'Time', units='s')
        self.plot_widget.setTitle('Real-time Temperature')
        # 그리드
        self.plot_widget.showGrid(x=True, y=True, alpha=0.3)
        # 곡선 생성
        self.curve = self.plot_widget.plot(pen=pg.mkPen(color='#e74c3c', width=2))
        layout.addWidget(self.plot_widget)
        self.setLayout(layout)
    def update_data(self, timestamp: float, temperature: float): self.time_data.append(timestamp)
        self.temp_data.append(temperature)
        # 차트 업데이트
        self.curve.setData(list(self.time_data), list(self.temp_data))
```
=== 다중 곡선 차트
```python
class MultiCurveChart(QWidget): def __init__(self, max_points=100): super().__init__()
        self.max_points = max_points
        self.setup_ui()
        self.init_data_buffers()
    def setup_ui(self): layout = QVBoxLayout()
        self.plot_widget = pg.PlotWidget()
        self.plot_widget.addLegend()
        # 여러 곡선
        self.temp_curve = self.plot_widget.plot(pen=pg.mkPen(color='#e74c3c', width=2), name='Temperature')
        self.pressure_curve = self.plot_widget.plot(pen=pg.mkPen(color='#3498db', width=2), name='Pressure')
        self.flow_curve = self.plot_widget.plot(pen=pg.mkPen(color='#2ecc71', width=2), name='Flow Rate')
        layout.addWidget(self.plot_widget)
        self.setLayout(layout)
    def init_data_buffers(self): self.time_buffer = deque(maxlen=self.max_points)
        self.temp_buffer = deque(maxlen=self.max_points)
        self.pressure_buffer = deque(maxlen=self.max_points)
        self.flow_buffer = deque(maxlen=self.max_points)
    def update_data(self, data: ProcessData): timestamp = data.timestamp.timestamp()
        self.time_buffer.append(timestamp)
        self.temp_buffer.append(data.temperature)
        self.pressure_buffer.append(data.pressure)
        self.flow_buffer.append(data.flow_rate)
        time_list = list(self.time_buffer)
        self.temp_curve.setData(time_list, list(self.temp_buffer))
        self.pressure_curve.setData(time_list, list(self.pressure_buffer))
        self.flow_curve.setData(time_list, list(self.flow_buffer))
```
== 데이터 버퍼링
=== Circular Buffer (순환 버퍼)
```python
from collections import deque
class CircularBuffer: def __init__(self, maxlen: int): self.buffer = deque(maxlen=maxlen)
    def append(self, data): self.buffer.append(data)
    def get_all(self): return list(self.buffer)
    def get_last_n(self, n: int): return list(self.buffer)[-n: ]
    def clear(self): self.buffer.clear()
```
=== NumPy 버퍼
```python
import numpy as np
class NumpyBuffer: def __init__(self, maxlen: int): self.maxlen = maxlen
        self.data = np.zeros(maxlen)
        self.index = 0
        self.full = False
    def append(self, value: float): self.data[self.index] = value
        self.index += 1
        if self.index >= self.maxlen: self.index = 0
            self.full = True
    def get_all(self): if self.full: # 순서 재정렬
            return np.roll(self.data, -self.index)
        else: return self.data[: self.index]
    def get_mean(self) -> float: return np.mean(self.get_all())
    def get_std(self) -> float: return np.std(self.get_all())
```
== 완전한 예제: 실시간 모니터링 시스템
다음은 QThread, Producer-Consumer 패턴, PyQtGraph를 모두 적용한 완전한 실행 가능 예제이다.
=== realtime_monitor.py
```python
#!/usr/bin/env python3
"""
반도체 실시간 모니터링 시스템
QThread + Producer-Consumer + PyQtGraph
"""
import sys
import random
from datetime import datetime
from dataclasses import dataclass
from collections import deque
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel, QGroupBox, QGridLayout)
from PySide6.QtCore import QThread, Signal, Slot, Qt
import pyqtgraph as pg
# ============== Data Model ==============
@dataclass
class ProcessData: """공정 데이터 모델"""
    timestamp: datetime
    temperature: float
    pressure: float
    flow_rate: float
    def is_normal(self) -> bool: return (400 <= self.temperature <= 480 and
            2.0 <= self.pressure <= 3.0 and
            80 <= self.flow_rate <= 120)
# ============== Worker Thread ==============
class DataWorker(QThread): """백그라운드 데이터 수집 워커"""
    data_ready = Signal(object)
    error_occurred = Signal(str)
    def __init__(self): super().__init__()
        self._running = False
    def run(self): """스레드 메인 루프"""
        self._running = True
        # 초기 데이터
        current_temp = 450.0
        current_pressure = 2.5
        current_flow = 100.0
        while self._running: try: # 센서 데이터 시뮬레이션 (연속성 있는 변화)
                current_temp += random.uniform(-3, 3)
                current_pressure += random.uniform(-0.1, 0.1)
                current_flow += random.uniform(-5, 5)
                # 범위 제한
                current_temp = max(100, min(550, current_temp))
                current_pressure = max(0.5, min(5.5, current_pressure))
                current_flow = max(50, min(150, current_flow))
                data = ProcessData(timestamp=datetime.now(), temperature=current_temp, pressure=current_pressure, flow_rate=current_flow)
                self.data_ready.emit(data)
                self.msleep(100)  # 100ms 간격
            except Exception as e: self.error_occurred.emit(str(e))
                self._running = False
    def stop(self): """워커 정지"""
        self._running = False
        self.wait()  # 스레드 종료 대기
# ============== Chart Widget ==============
class RealtimeChartWidget(QWidget): """실시간 차트 위젯"""
    def __init__(self, max_points=100): super().__init__()
        self.max_points = max_points
        self.start_time = None
        self.init_data_buffers()
        self.setup_ui()
    def init_data_buffers(self): """데이터 버퍼 초기화"""
        self.time_buffer = deque(maxlen=self.max_points)
        self.temp_buffer = deque(maxlen=self.max_points)
        self.pressure_buffer = deque(maxlen=self.max_points)
        self.flow_buffer = deque(maxlen=self.max_points)
    def setup_ui(self): """UI 설정"""
        layout = QVBoxLayout()
        # PyQtGraph 설정
        pg.setConfigOptions(antialias=True)
        # Temperature Chart
        self.temp_plot = pg.PlotWidget(title="Temperature")
        self.temp_plot.setLabel('left', 'Temperature', units='°C')
        self.temp_plot.setLabel('bottom', 'Time', units='s')
        self.temp_plot.showGrid(x=True, y=True, alpha=0.3)
        self.temp_curve = self.temp_plot.plot(pen=pg.mkPen(color='#e74c3c', width=2))
        layout.addWidget(self.temp_plot)
        # Pressure & Flow Chart
        self.multi_plot = pg.PlotWidget(title="Pressure & Flow Rate")
        self.multi_plot.setLabel('left', 'Pressure', units='Torr')
        self.multi_plot.setLabel('bottom', 'Time', units='s')
        self.multi_plot.showGrid(x=True, y=True, alpha=0.3)
        self.multi_plot.addLegend()
        self.pressure_curve = self.multi_plot.plot(pen=pg.mkPen(color='#3498db', width=2), name='Pressure')
        self.flow_curve = self.multi_plot.plot(pen=pg.mkPen(color='#2ecc71', width=2), name='Flow Rate')
        layout.addWidget(self.multi_plot)
        self.setLayout(layout)
    def update_data(self, data: ProcessData): """차트 데이터 업데이트"""
        if self.start_time is None: self.start_time = data.timestamp
        # 상대 시간 (초 단위)
        elapsed = (data.timestamp - self.start_time).total_seconds()
        # 버퍼 업데이트
        self.time_buffer.append(elapsed)
        self.temp_buffer.append(data.temperature)
        self.pressure_buffer.append(data.pressure)
        self.flow_buffer.append(data.flow_rate)
        # 차트 업데이트
        time_list = list(self.time_buffer)
        self.temp_curve.setData(time_list, list(self.temp_buffer))
        self.pressure_curve.setData(time_list, list(self.pressure_buffer))
        self.flow_curve.setData(time_list, list(self.flow_buffer))
# ============== Status Widget ==============
class StatusWidget(QWidget): """상태 표시 위젯"""
    def __init__(self): super().__init__()
        self.setup_ui()
    def setup_ui(self): group = QGroupBox("Current Values")
        layout = QGridLayout()
        # Temperature
        layout.addWidget(QLabel("Temperature: "), 0, 0)
        self.temp_label = QLabel("-- °C")
        self.temp_label.setStyleSheet("font-size: 16px; font-weight: bold;")
        layout.addWidget(self.temp_label, 0, 1)
        # Pressure
        layout.addWidget(QLabel("Pressure: "), 1, 0)
        self.pressure_label = QLabel("-- Torr")
        self.pressure_label.setStyleSheet("font-size: 16px; font-weight: bold;")
        layout.addWidget(self.pressure_label, 1, 1)
        # Flow Rate
        layout.addWidget(QLabel("Flow Rate: "), 2, 0)
        self.flow_label = QLabel("-- sccm")
        self.flow_label.setStyleSheet("font-size: 16px; font-weight: bold;")
        layout.addWidget(self.flow_label, 2, 1)
        # Status
        layout.addWidget(QLabel("Status: "), 3, 0)
        self.status_label = QLabel("STOPPED")
        self.status_label.setStyleSheet("font-size: 16px; font-weight: bold; color: gray;")
        layout.addWidget(self.status_label, 3, 1)
        group.setLayout(layout)
        main_layout = QVBoxLayout()
        main_layout.addWidget(group)
        self.setLayout(main_layout)
    def update_data(self, data: ProcessData): """상태 업데이트"""
        self.temp_label.setText(f"{data.temperature: .1f} °C")
        self.pressure_label.setText(f"{data.pressure: .2f} Torr")
        self.flow_label.setText(f"{data.flow_rate: .1f} sccm")
        if data.is_normal(): self.status_label.setText("NORMAL")
            self.status_label.setStyleSheet("font-size: 16px; font-weight: bold; color: green;")
        else: self.status_label.setText("WARNING")
            self.status_label.setStyleSheet("font-size: 16px; font-weight: bold; color: red;")
# ============== Main Window ==============
class MainWindow(QMainWindow): """메인 윈도우"""
    def __init__(self): super().__init__()
        self.setWindowTitle("Realtime Semiconductor Monitor")
        self.setGeometry(100, 100, 1400, 900)
        # Worker 초기화
        self.worker = DataWorker()
        self.worker.data_ready.connect(self.on_data_ready)
        self.worker.error_occurred.connect(self.on_error)
        # 데이터 카운터
        self.data_count = 0
        self.setup_ui()
    def setup_ui(self): central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QHBoxLayout()
        # 왼쪽: 차트
        chart_layout = QVBoxLayout()
        header = QLabel("CVD Equipment Realtime Monitor")
        header.setStyleSheet("font-size: 24px; font-weight: bold;")
        header.setAlignment(Qt.AlignCenter)
        chart_layout.addWidget(header)
        self.chart_widget = RealtimeChartWidget(max_points=100)
        chart_layout.addWidget(self.chart_widget)
        layout.addLayout(chart_layout, stretch=3)
        # 오른쪽: 상태 & 컨트롤
        right_layout = QVBoxLayout()
        # 상태 표시
        self.status_widget = StatusWidget()
        right_layout.addWidget(self.status_widget)
        # 버튼
        button_group = QGroupBox("Control")
        button_layout = QVBoxLayout()
        self.start_button = QPushButton("Start Monitoring")
        self.start_button.setMinimumHeight(50)
        self.start_button.clicked.connect(self.on_start)
        self.stop_button = QPushButton("Stop Monitoring")
        self.stop_button.setMinimumHeight(50)
        self.stop_button.setEnabled(False)
        self.stop_button.clicked.connect(self.on_stop)
        button_layout.addWidget(self.start_button)
        button_layout.addWidget(self.stop_button)
        button_group.setLayout(button_layout)
        right_layout.addWidget(button_group)
        # 통계
        stats_group = QGroupBox("Statistics")
        stats_layout = QVBoxLayout()
        self.count_label = QLabel("Samples: 0")
        self.count_label.setStyleSheet("font-size: 14px;")
        stats_layout.addWidget(self.count_label)
        stats_group.setLayout(stats_layout)
        right_layout.addWidget(stats_group)
        right_layout.addStretch()
        layout.addLayout(right_layout, stretch=1)
        central_widget.setLayout(layout)
        # 스타일시트
        self.apply_stylesheet()
    def apply_stylesheet(self): stylesheet = """
        QMainWindow {
            background-color: #ecf0f1;
        }
        QPushButton {
            background-color: #3498db;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 14px;
        }
        QPushButton: hover {
            background-color: #2980b9;
        }
        QPushButton: pressed {
            background-color: #21618c;
        }
        QPushButton: disabled {
            background-color: #95a5a6;
        }
        QGroupBox {
            border: 2px solid #bdc3c7;
            border-radius: 5px;
            margin-top: 10px;
            font-weight: bold;
            padding-top: 15px;
        }
        QGroupBox: :title {
            subcontrol-origin: margin;
            left: 10px;
            padding: 0 5px;
        }
        """
        self.setStyleSheet(stylesheet)
    @Slot()
    def on_start(self): """모니터링 시작"""
        self.worker.start()
        self.start_button.setEnabled(False)
        self.stop_button.setEnabled(True)
        self.data_count = 0
        print("Monitoring started")
    @Slot()
    def on_stop(self): """모니터링 정지"""
        self.worker.stop()
        self.start_button.setEnabled(True)
        self.stop_button.setEnabled(False)
        print(f"Monitoring stopped. Total samples: {self.data_count}")
    @Slot(object)
    def on_data_ready(self, data: ProcessData): """데이터 수신"""
        self.data_count += 1
        self.chart_widget.update_data(data)
        self.status_widget.update_data(data)
        self.count_label.setText(f"Samples: {self.data_count}")
    @Slot(str)
    def on_error(self, error: str): """에러 처리"""
        print(f"Error: {error}")
    def closeEvent(self, event): """종료 시 워커 정리"""
        if self.worker.isRunning(): self.worker.stop()
        event.accept()
# ============== Main ==============
def main(): app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
if __name__ == "__main__": main()
```
*실행 방법: *
1. 위 코드를 `realtime_monitor.py`로 저장
2. `pip install PySide6 pyqtgraph` 실행
3. `python realtime_monitor.py` 실행
*기능: *
- Start Monitoring: QThread 기반 백그라운드 데이터 수집 (100ms 간격)
- Stop Monitoring: 워커 스레드 안전하게 종료
- 실시간 차트: 온도, 압력, 유량을 PyQtGraph로 표시
- 상태 모니터링: 현재 값과 NORMAL/WARNING 상태 표시
- 통계: 수집된 샘플 수 카운팅
== MCQ (Multiple Choice Questions)
=== 문제 1: GIL 기초 (기초)
GIL로 인해 성능 향상을 기대할 수 없는 작업은?
A. 파일 읽기 \
B. 네트워크 요청 \
C. 수학 계산 (순수 Python) \
D. time.sleep()
*정답: C*
*해설*: GIL은 CPU-bound 작업(순수 Python 계산)에서 멀티스레드 효과를 제한한다. I/O 작업은 GIL이 해제되므로 멀티스레드 효과가 있다.
---
=== 문제 2: QThread vs threading (기초)
QThread가 Python threading.Thread보다 유리한 점은?
A. 더 빠른 실행 속도 \
B. Signal/Slot을 통한 UI 통신 \
C. GIL 영향 없음 \
D. 메모리 사용량 적음
*정답: B*
*해설*: QThread는 Signal/Slot 메커니즘으로 메인 스레드(UI)와 안전하게 통신할 수 있다. threading.Thread는 수동으로 큐나 락을 사용해야 한다.
---
=== 문제 3: QTimer 사용법 (중급)
다음 코드의 출력은?
```python
timer = QTimer()
timer.setSingleShot(True)
timer.timeout.connect(lambda: print("Hello"))
timer.start(1000)
timer.start(1000)
```
A. "Hello" 1번 출력 \
B. "Hello" 2번 출력 \
C. 오류 발생 \
D. 출력 없음
*정답: A*
*해설*: `setSingleShot(True)`는 타이머를 한 번만 실행하도록 설정한다. `start()`를 두 번 호출해도 첫 번째 타이머는 취소되고 새로 시작되므로 1번만 출력된다.
---
=== 문제 4: Worker Thread Pattern (중급)
QThread의 `run()` 메서드에서 UI를 직접 업데이트하면?
A. 정상 동작 \
B. UI가 업데이트되지 않음 \
C. 프로그램 크래시 가능 \
D. 성능 저하
*정답: C*
*해설*: Qt는 UI 업데이트를 오직 메인 스레드에서만 허용한다. 워커 스레드에서 UI를 직접 업데이트하면 크래시하거나 예측 불가능한 동작을 한다. Signal을 사용해야 한다.
---
=== 문제 5: Producer-Consumer Pattern (중급)
Producer-Consumer 패턴에서 Queue의 역할은?
A. 데이터 생성 \
B. 데이터 처리 \
C. 생산자와 소비자 간 버퍼 \
D. UI 업데이트
*정답: C*
*해설*: Queue는 생산자와 소비자 사이의 버퍼 역할을 하여, 생산 속도와 소비 속도가 달라도 안정적으로 동작하도록 한다.
---
=== 문제 6: Thread-safe Singleton (고급)
다음 Singleton 구현에서 `_lock`의 역할은?
```python
class Manager: _instance = None
    _lock = threading.Lock()
    def __new__(cls): if cls._instance is None: with cls._lock: if cls._instance is None: cls._instance = super().__new__(cls)
        return cls._instance
```
A. 성능 최적화 \
B. 멀티스레드 환경에서 중복 생성 방지 \
C. 메모리 절약 \
D. UI 업데이트 동기화
*정답: B*
*해설*: Double-checked locking 패턴이다. `_lock`은 동시에 두 스레드가 인스턴스를 생성하는 것을 방지한다.
---
=== 문제 7: PyQtGraph 성능 (고급)
대량의 데이터 포인트를 실시간 차트에 표시할 때 성능 향상 방법은?
A. 더 빠른 CPU 사용 \
B. 데이터 다운샘플링 또는 OpenGL 활성화 \
C. 메모리 증설 \
D. 스레드 증가
*정답: B*
*해설*: PyQtGraph는 `setDownsampling(auto=True)`나 `useOpenGL(True)`로 성능을 향상시킬 수 있다.
---
=== 문제 8: 코드 분석 - QThread (고급)
다음 코드의 문제점은?
```python
class Worker(QThread): def run(self): while True: data = collect_data()
            self.data_ready.emit(data)
            time.sleep(0.1)
```
A. 문법 오류 \
B. 스레드를 종료할 방법이 없음 \
C. GIL로 인한 성능 문제 \
D. Signal이 발생하지 않음
*정답: B*
*해설*: `while True`는 무한 루프로 스레드를 종료할 방법이 없다. `self._running` 플래그를 사용하여 종료 가능하도록 해야 한다.
---
=== 문제 9: Circular Buffer (고급)
`deque(maxlen=100)`의 장점은?
A. 빠른 검색 \
B. 자동으로 오래된 데이터 제거 \
C. 무한 용량 \
D. 정렬 기능
*정답: B*
*해설*: `deque`의 `maxlen` 파라미터는 최대 크기를 설정하여, 새 데이터 추가 시 자동으로 가장 오래된 데이터를 제거한다.
---
=== 문제 10: Python 동시성 선택 (도전)
반도체 HMI에서 100개 센서를 주기적으로 읽어야 할 때 최적의 방법은?
A. 100개 QThread 생성 \
B. 1개 QThread + QTimer로 순차 읽기 \
C. multiprocessing.Pool(100) \
D. asyncio로 비동기 처리
*정답: B*
*해설*: 센서 읽기는 대부분 I/O-bound 작업이므로, 1개 QThread에서 QTimer로 순차 읽기가 가장 효율적이다. 100개 스레드는 오버헤드가 크고, multiprocessing은 센서 I/O에 부적합하다.
== 추가 학습 자료
=== 공식 문서
- *QThread Documentation*: https: //doc.qt.io/qt-6/qthread.html
- *PyQtGraph Documentation*: https: //pyqtgraph.readthedocs.io/
- *Python threading*: https: //docs.python.org/3/library/threading.html
- *Python multiprocessing*: https: //docs.python.org/3/library/multiprocessing.html
=== 참고 서적
- "Python Concurrency with asyncio" by Matthew Fowler
- "Qt5 Python GUI Programming Cookbook" by B.M. Harwani
- "Effective Python" by Brett Slatkin (Item 53-58: Concurrency)
=== 온라인 자료
- Real Python Threading Tutorial: https: //realpython.com/intro-to-python-threading/
- PyQtGraph Examples: https: //pyqtgraph.readthedocs.io/en/latest/getting_started/examples.html
== 요약
이번 챕터에서는 Python 실시간 데이터 처리를 학습했다: *이론 (Theory): *
- Python 동시성 모델: threading, multiprocessing, asyncio
- GIL 심화: 동작 원리, 성능 영향, 해제 시점
- Qt Threading 모델: 스레드 친화성, 이벤트 루프, Signal/Slot
- Python threading vs Qt QThread 비교
*응용 (Application): *
- Worker Thread Pattern: 백그라운드 데이터 수집
- Producer-Consumer Pattern: 생산자-소비자 분리
- Thread-safe Singleton: 멀티스레드 환경 데이터 관리
- PyQtGraph 실시간 차트: 단일/다중 곡선, 데이터 버퍼링
- 완전한 실행 가능 예제: 실시간 모니터링 시스템 (400+ 줄)
*성찰 (Reflections): *
- MCQ 10문제: GIL, QThread, 패턴, PyQtGraph, 코드 분석
*핵심 포인트: *
1. GIL은 CPU-bound 작업에만 영향을 미치며, I/O-bound는 멀티스레드 효과가 있음
2. QThread + Signal/Slot은 UI 통신에 안전하고 편리함
3. Producer-Consumer 패턴으로 데이터 생성과 처리를 분리하여 안정성 향상
4. PyQtGraph는 실시간 차트에 최적화되어 있으며, 다운샘플링과 OpenGL로 성능 향상 가능
다음 챕터에서는 Python 고급 UI 및 차트 라이브러리를 학습한다.
#pagebreak()