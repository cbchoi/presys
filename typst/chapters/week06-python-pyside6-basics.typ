= Week 6: Python PySide6 기초
== 학습 목표
본 챕터에서는 다음을 학습한다: + Python 언어 특징과 Qt 프레임워크 역사
+ PySide6 아키텍처와 Signal/Slot 메커니즘
+ 디자인 패턴 적용 (Observer, MVC, Singleton)
+ 실행 가능한 센서 모니터링 애플리케이션 개발
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *Python 기초*: 변수, 함수, 클래스, 상속, 예외 처리
- *객체지향 프로그래밍*: 클래스, 상속, 캡슐화, 다형성 개념
- *이벤트 기반 프로그래밍*: 콜백 함수, 이벤트 핸들러 개념
- *개발 환경*: Python 3.11+ 설치, pip 패키지 관리자 사용법
- *권장사항*: Week 1 HCI 이론 학습 완료
== Python 언어의 특징과 역사
=== Python 언어의 탄생
Python은 Guido van Rossum이 1991년에 발표한 고수준 프로그래밍 언어이다. "배우기 쉽고, 읽기 쉬운" 철학을 바탕으로 설계되었으며, 현재 가장 인기 있는 프로그래밍 언어 중 하나이다.
*주요 이정표: *
- *1991년*: Python 0.9.0 발표 (Guido van Rossum)
- *2000년*: Python 2.0 - 리스트 컴프리헨션, 가비지 컬렉션
- *2008년*: Python 3.0 - print 함수, Unicode 기본 지원
- *2015년*: Type Hints 도입 (PEP 484)
- *2019년*: Python 3.8 - Assignment Expression (Walrus Operator `: =`)
- *2021년*: Python 3.10 - Pattern Matching (match/case)
- *2022년*: Python 3.11 - 성능 개선 (10-60% 빠름)
- *2023년*: Python 3.12 - f-string 개선, Per-Interpreter GIL
=== Python 언어의 핵심 특징
==== 1. 동적 타입 (Dynamic Typing)
Python은 변수 선언 시 타입을 명시하지 않으며, 런타임에 타입이 결정된다: ```python
# 동적 타입 - 타입 선언 불필요
temperature = 450 # int
temperature = 450.5 # float로 자동 변경
temperature = "450°C" # str로 자동 변경
# Type Hints (3.5+): 선택적 타입 힌트
def monitor_temperature(temp: float) -> str: return f"{temp}°C"
```
*장점*:
- 빠른 프로토타이핑
- 코드 간결성
- 유연한 함수 설계
*단점*:
- 런타임 타입 오류 가능
- IDE 지원이 C\#/Java보다 약함
- 대규모 프로젝트에서 유지보수 어려움
==== 2. GIL (Global Interpreter Lock)
CPython(표준 Python 구현)은 GIL을 사용하여 한 번에 하나의 스레드만 Python 바이트코드를 실행한다: ```python
import threading
import time
# CPU-bound 작업: GIL로 인해 멀티스레드 효과 없음
def cpu_intensive(): total = 0
    for i in range(10_000_000): total += i
    return total
# I/O-bound 작업: GIL 영향 적음
def io_intensive(): time.sleep(1)  # GIL 해제됨
    return "Done"
```
*GIL 영향: *
- CPU-bound: 멀티스레드 효과 없음 → multiprocessing 사용
- I/O-bound: 멀티스레드 효과 있음 (네트워크, 파일 I/O)
- GUI: Qt의 이벤트 루프는 GIL과 협력 동작
==== 3. CPython vs 다른 구현체
#figure(table(columns: (auto, auto, auto, auto), align: left, [*구현체*], [*설명*], [*GIL*], [*사용 사례*], [CPython], [표준 구현 (C)], [있음], [일반적 사용], [PyPy], [JIT 컴파일러], [있음], [성능 최적화], [Jython], [Java 기반], [없음], [Java 통합], [IronPython], [.NET 기반], [없음], [.NET 통합], ), caption: "Python 구현체 비교")
반도체 HMI에서는 CPython + PySide6가 가장 일반적이다.
==== 4. Duck Typing
"오리처럼 걷고 꽥꽥거리면 오리다" - 타입보다 인터페이스(메서드/속성)를 중시: ```python
# Duck Typing 예제
class Sensor: def read(self): return 450.0
class MockSensor: def read(self): return 999.0
def monitor(sensor): # sensor의 타입을 검사하지 않음
  # read() 메서드만 있으면 동작
  return sensor.read()
monitor(Sensor()) # 450.0
monitor(MockSensor()) # 999.0
```
=== Qt 프레임워크의 역사
==== Qt의 탄생 (1995)
Qt는 노르웨이 Trolltech(현재 The Qt Company)에서 개발한 크로스 플랫폼 GUI 프레임워크이다.
*주요 이정표: *
- *1995년*: Qt 1.0 발표
- *2001년*: Qt 3.0 - 크로스 플랫폼 강화
- *2005년*: Qt 4.0 - Graphics View Framework
- *2012년*: Qt 5.0 - QML, Qt Quick 도입
- *2020년*: Qt 6.0 - CMake 기본, C++17 필수
- *2023년*: Qt 6.6 - Qt Graphs, 성능 개선
==== PyQt vs PySide 비교
#figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*PyQt*], [*PySide*], [라이선스], [GPL / 상용], [LGPL (무료)], [개발사], [Riverbank Computing], [Qt Company], [API], [거의 동일], [거의 동일], [신호/슬롯], [`pyqtSignal`], [`Signal`], [산업 사용], [초기에 많음], [최근 증가 (무료)], ), caption: "PyQt vs PySide 비교")
*반도체 산업 선택: *
- 상용 제품: PySide6 (라이선스 비용 없음)
- 사내 도구: PyQt5/6 (GPL 허용)
- 권장: PySide6 (Qt Company 공식 지원)
=== 반도체 산업에서의 Python 채택 동향
==== 주요 사용 사례
*Applied Materials*:
- 데이터 분석 및 시각화
- 테스트 자동화 스크립트
- Python + Qt for 프로토타이핑
*ASML*:
- 알고리즘 개발 (이미지 처리)
- 시뮬레이션 도구
- 내부 도구 개발
*Samsung/SK Hynix*:
- 공정 데이터 분석 (pandas, numpy)
- 머신러닝 모델 (TensorFlow, PyTorch)
- HMI 프로토타이핑
==== 산업 동향
*장점*:
- 빠른 개발 속도 (C++/C\#보다 2-3배 빠름)
- 풍부한 라이브러리 (NumPy, Pandas, Matplotlib)
- AI/ML 통합 용이 (TensorFlow, PyTorch)
- 배우기 쉬움 (운영자 교육 용이)
*단점*:
- C++보다 느린 실행 속도
- GIL로 인한 멀티코어 활용 제한
- 대규모 프로젝트 유지보수 어려움
- 타입 안전성 부족
*미래 전망: *
- 프로토타이핑 및 데이터 분석에 Python 지배적
- 실시간 제어는 여전히 C++/C\#
- 하이브리드 접근 증가 (C++ 백엔드 + Python 프론트엔드)
== Python 타입 시스템 이론
Python의 타입 시스템은 다른 주류 언어들과 근본적으로 다른 철학을 가지고 있다. 이 절에서는 타입 시스템의 이론적 기반과 실무적 함의를 탐구한다.
=== Duck Typing vs Nominal Typing
*Duck Typing (구조적 타입)*: "오리처럼 걷고 꽥꽥거리면 오리다" - 객체의 타입보다 **인터페이스**(메서드와 속성)를 중시하는 타입 시스템이다.
```python
# Duck Typing: 타입 선언 없이 인터페이스만 일치하면 동작
def process_sensor(sensor): # sensor의 타입을 검사하지 않음
  # read() 메서드만 있으면 동작
  return sensor.read()
class TemperatureSensor: def read(self): return 450.0
class PressureSensor: def read(self): return 2.5
class MockSensor: def read(self): return 999.0
# 모두 동작함 (같은 인터페이스)
process_sensor(TemperatureSensor()) # 450.0
process_sensor(PressureSensor()) # 2.5
process_sensor(MockSensor()) # 999.0
```
*Nominal Typing (명목적 타입 - C\#/Java)*: 타입의 **이름**과 **명시적 상속 관계**를 중시하는 타입 시스템이다.
```csharp
// C#: 명시적 인터페이스 선언 필요
interface ISensor
{
  double Read();
}
class TemperatureSensor : ISensor // ← 명시적 구현
{
  public double Read() => 450.0;
}
void ProcessSensor(ISensor sensor) // ← 타입 명시 필수
{
  return sensor.Read();
}
```
*비교 분석*: #figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*Duck Typing (Python)*], [*Nominal Typing (C\#)*], [타입 검사], [런타임], [컴파일 타임], [인터페이스], [암묵적], [명시적], [유연성], [매우 높음], [낮음], [안전성], [낮음 (런타임 오류)], [높음 (컴파일 오류)], [개발 속도], [빠름], [느림], [리팩토링], [어려움 (IDE 지원 약함)], [쉬움 (타입 추적)], [테스트], [Mock 객체 쉬움], [인터페이스 필요], ), caption: "Duck Typing vs Nominal Typing 비교")
=== Type Hints (PEP 484, 2015)
Python 3.5부터 도입된 Type Hints는 Duck Typing의 유연성을 유지하면서 **선택적 정적 타입 검사**를 가능하게 한다.
*Type Hints 역사*: - *2015년*: PEP 484 - Type Hints 기본 개념 (Guido van Rossum, Jukka Lehtosalo)
- *2016년*: PEP 526 - Variable Annotations
- *2017년*: PEP 563 - Postponed Evaluation of Annotations
- *2019년*: PEP 585 - Generic Alias (Python 3.9+, `list[int]` 지원)
- *2020년*: PEP 604 - Union Operator (`int | str` 지원)
*Type Hints 사용법*: ```python
from typing import Protocol, TypeVar, Generic
# 1. 기본 타입 힌트
def monitor_temperature(temp: float) -> str: return f"{temp}°C"
# 2. 복합 타입 (Python 3.9+)
def get_sensors() -> list[str]: return ["Sensor1", "Sensor2"]
def get_config() -> dict[str, int]: return {"timeout": 1000, "retry": 3}
# 3. Union 타입 (Python 3.10+)
def process(value: int | float | None) -> str: if value is None: return "No data"
    return f"Value: {value}"
# 4. Protocol (구조적 서브타이핑)
class Sensor(Protocol): """센서 인터페이스 정의 (암묵적)"""
    def read(self) -> float: ...
    def reset(self) -> None: ...
def monitor(sensor: Sensor) -> float: # sensor는 read()와 reset()만 있으면 됨
    sensor.reset()
    return sensor.read()
# 5. Generic (제네릭 타입)
T = TypeVar('T')
class DataBuffer(Generic[T]): def __init__(self): self._data: list[T] = []
    def add(self, item: T) -> None: self._data.append(item)
    def get_all(self) -> list[T]: return self._data.copy()
# 사용
buffer = DataBuffer[float]()
buffer.add(450.0)
buffer.add(2.5)
# buffer.add("invalid")  # ← mypy 오류
```
*Type Hints 검사 도구*: ```bash
# mypy: 정적 타입 검사기
pip install mypy
mypy sensor_monitor.py
# 출력 예시:
# sensor_monitor.py: 42: error: Argument 1 to "monitor_temperature" has
# incompatible type "str"; expected "float"
```
*Type Hints 장점*: - IDE 자동완성 향상 (VSCode, PyCharm)
- 리팩토링 안전성 증가
- 문서화 효과 (타입이 명시됨)
- 대규모 프로젝트 유지보수 용이
*Type Hints 한계*: - **런타임에는 검사되지 않음** (실행 시 타입 오류 가능)
- 기존 코드와 호환성 문제
- 복잡한 타입 표현 어려움
=== GIL 심화 (Global Interpreter Lock)
GIL은 CPython의 가장 논란이 많은 설계 결정으로, 멀티코어 시대의 성능 병목이다.
==== GIL의 역사와 설계 이유
*1991년 GIL 도입 배경*: CPython은 **Reference Counting** 방식의 가비지 컬렉션을 사용한다. GIL 없이 멀티스레드에서 Reference Count를 안전하게 증가/감소시키려면 **모든 객체에 락**이 필요하다.
```python
# Reference Counting 예시
a = [] # refcount = 1
b = a # refcount = 2 (증가)
c = a # refcount = 3 (증가)
del b # refcount = 2 (감소)
del c # refcount = 1 (감소)
del a # refcount = 0 → 메모리 해제
```
*GIL의 설계 결정*: - **단일 글로벌 락**: 모든 객체에 락 대신 **인터프리터 전체에 하나의 락**
- **장점**: 구현 단순, C 확장 모듈 작성 쉬움, 싱글스레드 성능 우수
- **단점**: 멀티코어 활용 불가 (CPU-bound 작업)
==== GIL 내부 동작 메커니즘
```
┌────────────────────────────────────────────────────────┐
│ Python Interpreter │
│ ┌──────────────────────────────────────────────────┐ │
│ │  GIL (Global Lock) │  │
│ └──────────────────────────────────────────────────┘ │
│ ↑  ↑  │
│ │  │  │
│ Thread 1 Thread 2 │
│ [대기 중] [실행 중] │
│ │
│ GIL 보유: Thread 2 │
│ GIL 대기: Thread 1 │
└────────────────────────────────────────────────────────┘
GIL 스위칭 조건:
1. I/O 작업 시작 (네트워크, 파일)
2. 100번의 바이트코드 실행 (Python 3.2 이전)
3. 5ms 경과 (Python 3.2 이후)
```
*GIL 획득/해제 코드 분석*: ```c
// CPython 내부 (간소화)
// Python/ceval.c
PyObject* PyEval_EvalFrameEx(PyFrameObject *f, int throwflag)
{
    // GIL 획득
    PyThread_acquire_lock(interpreter_lock, WAIT_LOCK);
    for (;;) {
        // 바이트코드 실행
        opcode = NEXTOP();
        // 주기적으로 GIL 해제 기회 부여
        if (--gil_drop_request == 0) {
            // GIL 해제
            PyThread_release_lock(interpreter_lock);
            // 다른 스레드에게 기회
            // GIL 재획득
            PyThread_acquire_lock(interpreter_lock, WAIT_LOCK);
        }
        // I/O 작업 시 GIL 해제
        if (opcode == CALL_FUNCTION && is_io_call) {
            Py_BEGIN_ALLOW_THREADS  // GIL 해제
            result = io_operation();
            Py_END_ALLOW_THREADS    // GIL 재획득
        }
    }
}
```
*GIL 영향 실험*: ```python
import threading
import time
# CPU-bound 작업
def cpu_intensive(n): total = 0
  for i in range(n): total += i ** 2
  return total
# 싱글스레드
start = time.time()
cpu_intensive(10_000_000)
cpu_intensive(10_000_000)
print(f"Single thread: {time.time() - start: .2f}s")
# 출력: Single thread: 1.20s
# 멀티스레드 (GIL로 인해 효과 없음)
start = time.time()
t1 = threading.Thread(target=cpu_intensive, args=(10_000_000, ))
t2 = threading.Thread(target=cpu_intensive, args=(10_000_000, ))
t1.start()
t2.start()
t1.join()
t2.join()
print(f"Multi thread: {time.time() - start: .2f}s")
# 출력: Multi thread: 1.25s (오히려 느림! GIL 경쟁 오버헤드)
```
*I/O-bound 작업에서는 GIL 영향 적음*: ```python
import requests
import threading
import time
def fetch_url(url): response = requests.get(url)  # GIL 해제됨
    return len(response.content)
urls = ["https: //example.com"] * 10
# 순차 실행
start = time.time()
for url in urls: fetch_url(url)
print(f"Sequential: {time.time() - start: .2f}s")
# 출력: Sequential: 5.20s
# 멀티스레드 (I/O 중 GIL 해제되어 효과 있음)
start = time.time()
threads = [threading.Thread(target=fetch_url, args=(url, )) for url in urls]
for t in threads: t.start()
for t in threads: t.join()
print(f"Multi thread: {time.time() - start: .2f}s")
# 출력: Multi thread: 0.85s (6배 빠름!)
```
==== GIL 우회 전략
#figure(table(columns: (auto, auto, auto, auto), align: left, [*방법*], [*적용 대상*], [*장점*], [*단점*], [`multiprocessing`], [CPU-bound], [진정한 병렬 실행], [프로세스 생성 오버헤드, IPC 복잡], [`threading`], [I/O-bound], [가벼움, 공유 메모리], [CPU-bound에 효과 없음], [NumPy/Pandas], [수치 계산], [GIL 해제, C 레벨 병렬], [특정 작업만 가능], [Cython/C 확장], [핫스팟], [GIL 해제 가능], [C 코드 작성 필요], [`asyncio`], [I/O-bound], [효율적 I/O], [CPU-bound 불가], ), caption: "GIL 우회 전략 비교")
*multiprocessing 예시*: ```python
from multiprocessing import Pool
def cpu_intensive(n): return sum(i ** 2 for i in range(n))
# 4개 프로세스로 병렬 실행 (GIL 영향 없음)
with Pool(4) as pool: results = pool.map(cpu_intensive, [10_000_000] * 4)
# 4코어에서 약 4배 빠름 (GIL 없음)
```
==== GIL-free Python (PEP 703, 2023)
*Sam Gross의 제안*: 2023년 Meta의 Sam Gross가 **No-GIL CPython** 구현을 제안했다 (PEP 703).
*주요 변경사항*: 1. **Biased Reference Counting**: 로컬 참조는 카운트 안 함
2. **Deferred Reference Counting**: 참조 카운트 갱신 지연
3. **Immortal Objects**: `None`, `True`, `False` 등은 불멸 (refcount 무한대)
*성능 영향*: - 싱글스레드: **7-9% 느림** (Reference Counting 오버헤드)
- 멀티스레드: **CPU-bound는 N배 빠름** (N = 코어 수)
*현재 상태 (2024)*: - Python 3.13 (2024년 10월): **실험적으로 포함**
- `--disable-gil` 빌드 옵션으로 활성화 가능
- 기본값은 여전히 GIL 활성화
```bash
# GIL-free Python 빌드
./configure --disable-gil
make
./python --version
# Python 3.13.0 experimental free-threading build
```
*반도체 산업 영향*: - 실시간 데이터 처리에서 멀티코어 활용 가능
- 기존 C 확장 모듈 호환성 문제 가능
- 2030년쯤 안정화 예상
== Qt Meta-Object System 이론
Qt의 Signal/Slot 메커니즘은 **Meta-Object Compiler (MOC)** 에 기반한다. 이는 C++에 **런타임 리플렉션**을 추가하는 독특한 시스템이다.
=== Meta-Object Compiler (MOC)
*MOC의 역할*: C++은 기본적으로 **컴파일 타임 언어**로, 런타임 리플렉션(메서드 이름 조회, 동적 호출)이 불가능하다. Qt는 **MOC라는 전처리기**로 이를 구현한다.
```
┌─────────────────────────────────────────────────────────┐
│ Qt 빌드 과정 │
└─────────────────────────────────────────────────────────┘
  sensor.h (Q_OBJECT 포함)
  │
  ↓
  ┌────────────┐
  │  MOC │  (Meta-Object Compiler)
  └────────────┘
  │
  ↓
  moc_sensor.cpp (생성됨)
  │
  ↓  (컴파일)
  ┌────────────┐
  │  g++ │
  └────────────┘
  │
  ↓
  sensor.o + moc_sensor.o
  │
  ↓  (링크)
  libsensor.so
```
*MOC 생성 코드 예시*: ```cpp
// sensor.h (원본)
class TemperatureSensor : public QObject
{
    Q_OBJECT  // ← MOC 매크로
public: explicit TemperatureSensor(QObject *parent = nullptr);
signals: void temperatureChanged(double value);
public slots: void reset();
private: double m_temperature;
};
```
*MOC가 생성한 코드 (moc_sensor.cpp, 간소화)*: ```cpp
// MOC가 자동 생성한 메타 정보
static const QMetaObject: :StaticMetaObject staticMetaObject = {
  {
  &QObject: :staticMetaObject, // 부모 클래스
  qt_meta_stringdata_TemperatureSensor.data, qt_meta_data_TemperatureSensor, // ...
  }
};
// 메타 데이터 테이블
static const uint qt_meta_data_TemperatureSensor[] = {
  // Signal: temperatureChanged(double)
  QMetaMethod: :Signal, // 메서드 타입
  1, // 메서드 인덱스
  // Slot: reset()
  QMetaMethod: :Slot, 2, // ...
};
// Signal 발생 함수
void TemperatureSensor: :temperatureChanged(double value)
{
  // 모든 연결된 Slot 호출
  QMetaObject: :activate(this, &staticMetaObject, 0, &value);
}
```
*Python에서의 MOC*: PySide6는 **Python 클래스에서 동적으로** 메타 정보를 생성한다.
```python
from PySide6.QtCore import QObject, Signal
class TemperatureSensor(QObject): # Signal 정의 시 내부적으로 메타 정보 생성
  temperatureChanged = Signal(float)
  def __init__(self): super().__init__()
  # QObject 초기화 시 메타 정보 등록
# 내부적으로 발생하는 일 (간소화):
# 1. Signal(float) → SignalInstance 생성
# 2. __init__ 호출 → QObject 초기화
# 3. QMetaObject에 메타 정보 등록
```
=== Signal/Slot 내부 메커니즘
*Signal/Slot 연결 과정*: ```python
sensor = TemperatureSensor()
sensor.temperatureChanged.connect(on_temp_changed)
# 내부적으로 발생하는 일:
# 1. sensor의 QMetaObject 조회
# 2. "temperatureChanged" Signal의 메타 정보 찾기
# 3. 연결 정보 저장 (해시 테이블)
#    Key: (sender, signal_index)
#    Value: [(receiver, slot_index), ...]
```
*Signal 발생 과정*: ```python
sensor.temperatureChanged.emit(450.0)
# 내부적으로 발생하는 일:
# 1. QMetaObject: :activate() 호출
# 2. 연결 정보 조회 (해시 테이블)
# 3. 모든 연결된 Slot 순차 호출
# - on_temp_changed(450.0)
# - view.update_display(450.0)
# - logger.log(450.0)
```
*연결 정보 저장 구조*: ```
┌────────────────────────────────────────────────────────┐
│             QObject Connection Table                   │
└────────────────────────────────────────────────────────┘
Sender: sensor (TemperatureSensor)
Signal: temperatureChanged (index=0)
   │
   ├─→ Receiver 1: view (EquipmentView)
   │   Slot: update_display (index=5)
   │   Type: Auto Connection
   │
   ├─→ Receiver 2: logger (DataLogger)
   │   Slot: log (index=2)
   │   Type: Queued Connection
   │
   └─→ Receiver 3: lambda (anonymous)
       Slot: (Python callable)
       Type: Direct Connection
```
=== QObject 메모리 관리
Qt는 **부모-자식 관계**로 메모리를 자동 관리한다.
*Qt 메모리 모델*: ```python
# C++에서의 메모리 관리
MainWindow *window = new MainWindow(); // 부모
QPushButton *btn = new QPushButton(window); // 자식
// window 삭제 시 btn도 자동 삭제
delete window; // ← btn도 함께 삭제됨 (재귀적 삭제)
# Python에서는?
window = MainWindow()
btn = QPushButton(window)
# Python GC가 window 삭제 시 Qt도 btn 삭제
del window # ← btn도 삭제됨
```
*QObject 소유권 규칙*: ```python
from PySide6.QtWidgets import QWidget, QPushButton
# 1. 부모 지정: Qt가 메모리 관리
btn = QPushButton("Start", parent=window)
# window 삭제 시 btn도 자동 삭제
# 2. 부모 미지정: Python GC가 관리
btn = QPushButton("Start")
# Python refcount가 0이 되면 삭제
# 3. Layout에 추가: Layout이 부모 됨
layout = QVBoxLayout()
btn = QPushButton("Start")
layout.addWidget(btn)  # ← layout이 btn의 부모
widget.setLayout(layout)  # ← widget이 layout의 부모
# widget 삭제 시 layout → btn 순으로 삭제
```
*메모리 누수 방지*: ```python
# ❌ 나쁜 예: 부모 없는 위젯 반복 생성
def update_ui(): for i in range(1000): label = QLabel(f"Label {i}") # 부모 없음
  # label이 삭제되지 않음 → 메모리 누수!
# ✓ 좋은 예: 부모 지정 또는 명시적 삭제
def update_ui(parent_widget): for i in range(1000): label = QLabel(f"Label {i}", parent=parent_widget)
  # parent_widget 삭제 시 모든 label도 삭제됨
```
*Signal/Slot 연결과 메모리*: ```python
# Signal/Slot 연결은 약한 참조 (weak reference) 사용
sensor = TemperatureSensor()
view = EquipmentView()
sensor.temperatureChanged.connect(view.update_display)
# view 삭제 시 자동으로 연결 해제
del view  # ← Qt가 자동으로 연결 해제 (댕글링 포인터 방지)
```
=== Qt Event Loop와 GIL의 협력
Qt의 이벤트 루프는 Python GIL과 **협력적으로** 동작한다.
```python
from PySide6.QtWidgets import QApplication
app = QApplication([])
window = MainWindow()
window.show()
app.exec()  # ← 이벤트 루프 시작
# 내부 동작:
# 1. GIL 획득
# 2. Qt 이벤트 처리 (마우스 클릭, 타이머 등)
# 3. Python Slot 호출 시 GIL 유지
# 4. I/O 대기 시 GIL 해제
# 5. 반복
```
*GIL과 Qt Timer*: ```python
from PySide6.QtCore import QTimer
timer = QTimer()
timer.timeout.connect(expensive_computation)
timer.start(100) # 100ms마다
# expensive_computation()이 GIL을 오래 잡으면?
# → UI 프리징 발생!
# 해결: QThread로 분리 또는 asyncio 사용
```
== Python 3.11+ 주요 기능
=== Type Hints
```python
from typing import Protocol
class Equipment(Protocol): id: str
  name: str
  temperature: float
def monitor_equipment(eq: Equipment) -> dict[str, float]: return {
  "temp": eq.temperature, "pressure": get_pressure(eq)
  }
```
=== Dataclasses
```python
from dataclasses import dataclass
from datetime import datetime
@dataclass
class ProcessData: timestamp: datetime
  temperature: float
  pressure: float
  flow_rate: float
  def is_normal(self) -> bool: return (400 <= self.temperature <= 480 and
  2.0 <= self.pressure <= 3.0)
```
=== Pattern Matching
```python
def handle_alarm(severity: str, message: str): match severity: case "CRITICAL": stop_equipment()
  send_notification(message)
  case "WARNING": log_warning(message)
  case "INFO": log_info(message)
  case _: pass
```
== PySide6 설치 및 설정
=== 설치
```bash
pip install PySide6
pip install pyqtgraph # 차트용
pip install qtawesome # 아이콘용
```
=== 기본 애플리케이션
```python
import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget
from PySide6.QtCore import Qt
class MainWindow(QMainWindow): def __init__(self): super().__init__()
  self.setWindowTitle("Semiconductor HMI")
  self.setGeometry(100, 100, 1200, 800)
  # Central widget
  central_widget = QWidget()
  self.setCentralWidget(central_widget)
if __name__ == "__main__": app = QApplication(sys.argv)
  window = MainWindow()
  window.show()
  sys.exit(app.exec())
```
== Signal과 Slot (Observer Pattern)
=== Observer Pattern 개요
Signal/Slot은 Qt의 핵심 메커니즘으로, Observer 패턴의 구현이다.
```
┌──────────────┐ emit signal ┌──────────────┐
│ Subject │──────────────→│ Observer │
│ (센서) │  │  (UI) │
└──────────────┘ └──────────────┘
  │  │
  │ temperature_changed │ update_display()
  ↓  ↓
  [450.0°C] [UI 갱신]
```
=== 기본 Signal/Slot
```python
from PySide6.QtCore import Signal, Slot, QObject
class TemperatureSensor(QObject): # Signal 정의
  temperature_changed = Signal(float)
  def __init__(self): super().__init__()
  self._temperature = 0.0
  @property
  def temperature(self) -> float: return self._temperature
  @temperature.setter
  def temperature(self, value: float): if self._temperature != value: self._temperature = value
  self.temperature_changed.emit(value) # 관찰자에게 통지
# 사용
sensor = TemperatureSensor()
@Slot(float)
def on_temperature_changed(temp: float): print(f"Temperature: {temp}°C")
sensor.temperature_changed.connect(on_temperature_changed)
sensor.temperature = 450.0 # Signal 발생 → Slot 호출
```
=== 커스텀 Signal
```python
class Equipment(QObject): started = Signal()
  stopped = Signal()
  alarm_triggered = Signal(str, str) # severity, message
  def start(self): self.started.emit()
  def stop(self): self.stopped.emit()
  def check_status(self): if self.temperature > 480: self.alarm_triggered.emit("CRITICAL", "Temperature too high")
```
== MVC 패턴
=== MVC 아키텍처
```
┌─────────────────┐
│ Controller │  (사용자 입력 처리, 타이머 제어)
│ - start() │
│ - stop() │
└────────┬────────┘
  │
  ↓
┌─────────────────┐ data_changed ┌─────────────────┐
│ Model │───────────────→│ View │
│ - ProcessData │  │ - UI 표시 │
│ - update_data() │ │ - update() │
└─────────────────┘ └─────────────────┘
```
=== Model
```python
from PySide6.QtCore import QObject, Signal
from dataclasses import dataclass
from datetime import datetime
@dataclass
class ProcessData: timestamp: datetime
  temperature: float
  pressure: float
  flow_rate: float
class EquipmentModel(QObject): data_changed = Signal()
  def __init__(self): super().__init__()
  self._data = ProcessData(timestamp=datetime.now(), temperature=0.0, pressure=0.0, flow_rate=0.0)
  @property
  def data(self) -> ProcessData: return self._data
  def update_data(self, data: ProcessData): self._data = data
  self.data_changed.emit()
```
=== View
```python
from PySide6.QtWidgets import QWidget, QVBoxLayout, QLabel
from PySide6.QtCore import Slot
class EquipmentView(QWidget): def __init__(self, model: EquipmentModel): super().__init__()
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
  def update_display(self): data = self.model.data
  self.temp_label.setText(f"Temperature: {data.temperature: .1f}°C")
  self.pressure_label.setText(f"Pressure: {data.pressure: .2f} Torr")
```
=== Controller
```python
from PySide6.QtCore import QTimer, Slot
import random
class EquipmentController: def __init__(self, model: EquipmentModel): self.model = model
  self.timer = QTimer()
  self.timer.timeout.connect(self.update_data)
  def start(self): self.timer.start(100) # 100ms
  def stop(self): self.timer.stop()
  @Slot()
  def update_data(self): # 데이터 수집 (시뮬레이션)
  data = ProcessData(timestamp=datetime.now(), temperature=450.0 + random.uniform(-5, 5), pressure=2.5 + random.uniform(-0.2, 0.2), flow_rate=100.0 + random.uniform(-10, 10))
  self.model.update_data(data)
```
== Singleton Pattern
=== Thread-safe Singleton 구현
```python
import threading
class DataManager: _instance = None
  _lock = threading.Lock()
  def __new__(cls): if cls._instance is None: with cls._lock: if cls._instance is None: # Double-checked locking
  cls._instance = super().__new__(cls)
  cls._instance._initialized = False
  return cls._instance
  def __init__(self): if self._initialized: return
  self._initialized = True
  self._equipments = []
  @classmethod
  def get_instance(cls): if cls._instance is None: cls()
  return cls._instance
  def add_equipment(self, equipment): self._equipments.append(equipment)
  @property
  def equipments(self): return self._equipments.copy()
# 사용
manager1 = DataManager.get_instance()
manager2 = DataManager.get_instance()
assert manager1 is manager2 # True (같은 인스턴스)
```
== 레이아웃
=== QVBoxLayout
```python
from PySide6.QtWidgets import QVBoxLayout, QLabel, QPushButton
layout = QVBoxLayout()
layout.addWidget(QLabel("Temperature: "))
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
layout.addWidget(QLabel("Temperature: "), 0, 0)
layout.addWidget(QLabel("450.0°C"), 0, 1)
layout.addWidget(QLabel("Pressure: "), 1, 0)
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
  QPushButton: hover {
  background-color: #2980b9;
  }
  QPushButton: pressed {
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
def on_text_changed(text: str): print(f"Text: {text}")
```
=== QComboBox
```python
combo = QComboBox()
combo.addItems(["CVD", "PVD", "ETCH", "CMP"])
combo.currentTextChanged.connect(on_selection_changed)
@Slot(str)
def on_selection_changed(text: str): print(f"Selected: {text}")
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
QPushButton: hover {
  background-color: #2980b9;
}
QPushButton: pressed {
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
QGroupBox: :title {
  subcontrol-origin: margin;
  left: 10px;
  padding: 0 5px;
}
"""
app.setStyleSheet(stylesheet)
```
== 완전한 예제: 센서 모니터링 시스템
다음은 MVC 패턴, Observer 패턴, Singleton 패턴을 모두 적용한 완전한 실행 가능 예제이다.
=== sensor_monitor.py
```python
#!/usr/bin/env python3
"""
반도체 센서 모니터링 시스템
MVC + Observer + Singleton 패턴 적용
"""
import sys
import random
from datetime import datetime
from dataclasses import dataclass
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, QGroupBox, QGridLayout)
from PySide6.QtCore import QObject, Signal, Slot, QTimer, Qt
# ============== Model ==============
@dataclass
class ProcessData: """공정 데이터 모델"""
  timestamp: datetime
  temperature: float
  pressure: float
  flow_rate: float
  def is_normal(self) -> bool: return (400 <= self.temperature <= 480 and
  2.0 <= self.pressure <= 3.0 and
  80 <= self.flow_rate <= 120)
class EquipmentModel(QObject): """장비 데이터 모델 (Observer Pattern Subject)"""
  data_changed = Signal()
  def __init__(self): super().__init__()
  self._data = ProcessData(timestamp=datetime.now(), temperature=450.0, pressure=2.5, flow_rate=100.0)
  @property
  def data(self) -> ProcessData: return self._data
  def update_data(self, data: ProcessData): self._data = data
  self.data_changed.emit()
# ============== View ==============
class EquipmentView(QWidget): """장비 모니터링 뷰 (Observer Pattern Observer)"""
  def __init__(self, model: EquipmentModel): super().__init__()
  self.model = model
  self.setup_ui()
  # Model 연결
  self.model.data_changed.connect(self.update_display)
  self.update_display()
  def setup_ui(self): layout = QVBoxLayout()
  # 데이터 표시 그룹
  data_group = QGroupBox("Process Parameters")
  data_layout = QGridLayout()
  # 온도
  data_layout.addWidget(QLabel("Temperature: "), 0, 0)
  self.temp_label = QLabel()
  self.temp_label.setStyleSheet("font-size: 18px; font-weight: bold;")
  data_layout.addWidget(self.temp_label, 0, 1)
  # 압력
  data_layout.addWidget(QLabel("Pressure: "), 1, 0)
  self.pressure_label = QLabel()
  self.pressure_label.setStyleSheet("font-size: 18px; font-weight: bold;")
  data_layout.addWidget(self.pressure_label, 1, 1)
  # 유량
  data_layout.addWidget(QLabel("Flow Rate: "), 2, 0)
  self.flow_label = QLabel()
  self.flow_label.setStyleSheet("font-size: 18px; font-weight: bold;")
  data_layout.addWidget(self.flow_label, 2, 1)
  data_group.setLayout(data_layout)
  layout.addWidget(data_group)
  # 상태 표시
  status_group = QGroupBox("Status")
  status_layout = QVBoxLayout()
  self.status_label = QLabel()
  self.status_label.setStyleSheet("font-size: 16px; font-weight: bold;")
  self.status_label.setAlignment(Qt.AlignCenter)
  status_layout.addWidget(self.status_label)
  status_group.setLayout(status_layout)
  layout.addWidget(status_group)
  # 타임스탬프
  self.timestamp_label = QLabel()
  self.timestamp_label.setStyleSheet("font-size: 10px; color: gray;")
  layout.addWidget(self.timestamp_label)
  self.setLayout(layout)
  @Slot()
  def update_display(self): data = self.model.data
  # 데이터 표시
  self.temp_label.setText(f"{data.temperature: .1f} °C")
  self.pressure_label.setText(f"{data.pressure: .2f} Torr")
  self.flow_label.setText(f"{data.flow_rate: .1f} sccm")
  self.timestamp_label.setText(f"Last Update: {data.timestamp.strftime('%H: %M: %S')}")
  # 상태 색상
  if data.is_normal(): self.status_label.setText("NORMAL")
  self.status_label.setStyleSheet("font-size: 16px; font-weight: bold; color: green;")
  else: self.status_label.setText("WARNING")
  self.status_label.setStyleSheet("font-size: 16px; font-weight: bold; color: red;")
# ============== Controller ==============
class EquipmentController: """장비 제어 컨트롤러"""
  def __init__(self, model: EquipmentModel): self.model = model
  self.timer = QTimer()
  self.timer.timeout.connect(self.update_data)
  self.is_running = False
  def start(self): if not self.is_running: self.is_running = True
  self.timer.start(1000) # 1초마다 갱신
  def stop(self): if self.is_running: self.is_running = False
  self.timer.stop()
  @Slot()
  def update_data(self): # 센서 데이터 시뮬레이션
  current = self.model.data
  data = ProcessData(timestamp=datetime.now(), temperature=current.temperature + random.uniform(-5, 5), pressure=current.pressure + random.uniform(-0.2, 0.2), flow_rate=current.flow_rate + random.uniform(-10, 10))
  # 범위 제한
  data.temperature = max(100, min(550, data.temperature))
  data.pressure = max(0.5, min(5.5, data.pressure))
  data.flow_rate = max(50, min(150, data.flow_rate))
  self.model.update_data(data)
# ============== Singleton 데이터 관리자 ==============
class DataManager: """싱글톤 데이터 관리자"""
  _instance = None
  def __new__(cls): if cls._instance is None: cls._instance = super().__new__(cls)
  cls._instance._initialized = False
  return cls._instance
  def __init__(self): if self._initialized: return
  self._initialized = True
  self._history = []
  def add_data(self, data: ProcessData): self._history.append(data)
  if len(self._history) > 100: # 최대 100개 유지
  self._history.pop(0)
  @property
  def history(self): return self._history.copy()
# ============== Main Window ==============
class MainWindow(QMainWindow): """메인 윈도우"""
  def __init__(self): super().__init__()
  self.setWindowTitle("Semiconductor Sensor Monitor")
  self.setGeometry(100, 100, 600, 500)
  # MVC 초기화
  self.model = EquipmentModel()
  self.controller = EquipmentController(self.model)
  self.data_manager = DataManager()
  # 데이터 저장 연결
  self.model.data_changed.connect(self.save_data)
  self.setup_ui()
  def setup_ui(self): central_widget = QWidget()
  self.setCentralWidget(central_widget)
  layout = QVBoxLayout()
  # 헤더
  header = QLabel("CVD Equipment Monitor")
  header.setStyleSheet("font-size: 24px; font-weight: bold;")
  header.setAlignment(Qt.AlignCenter)
  layout.addWidget(header)
  # 뷰
  self.view = EquipmentView(self.model)
  layout.addWidget(self.view)
  # 버튼
  button_layout = QHBoxLayout()
  self.start_button = QPushButton("Start Monitoring")
  self.start_button.setMinimumHeight(40)
  self.start_button.clicked.connect(self.on_start)
  self.stop_button = QPushButton("Stop Monitoring")
  self.stop_button.setMinimumHeight(40)
  self.stop_button.setEnabled(False)
  self.stop_button.clicked.connect(self.on_stop)
  button_layout.addWidget(self.start_button)
  button_layout.addWidget(self.stop_button)
  layout.addLayout(button_layout)
  central_widget.setLayout(layout)
  # 스타일시트 적용
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
  padding-top: 10px;
  }
  QGroupBox: :title {
  subcontrol-origin: margin;
  left: 10px;
  padding: 0 5px;
  }
  """
  self.setStyleSheet(stylesheet)
  @Slot()
  def on_start(self): self.controller.start()
  self.start_button.setEnabled(False)
  self.stop_button.setEnabled(True)
  print("Monitoring started")
  @Slot()
  def on_stop(self): self.controller.stop()
  self.start_button.setEnabled(True)
  self.stop_button.setEnabled(False)
  print("Monitoring stopped")
  print(f"Total records: {len(self.data_manager.history)}")
  @Slot()
  def save_data(self): self.data_manager.add_data(self.model.data)
# ============== Main ==============
def main(): app = QApplication(sys.argv)
  window = MainWindow()
  window.show()
  sys.exit(app.exec())
if __name__ == "__main__": main()
```
*실행 방법: *
1. 위 코드를 `sensor_monitor.py`로 저장
2. `pip install PySide6` 실행
3. `python sensor_monitor.py` 실행
*기능: *
- Start Monitoring: 1초마다 센서 데이터 업데이트 (시뮬레이션)
- Stop Monitoring: 모니터링 중지 및 히스토리 출력
- 정상 범위 벗어나면 "WARNING" 빨간색 표시
- Singleton DataManager가 최대 100개 히스토리 유지
== MCQ (Multiple Choice Questions)
=== 문제 1: Python 동적 타입 (기초)
Python의 동적 타입 시스템의 특징은?
A. 변수 선언 시 타입을 반드시 명시해야 함 \
B. 런타임에 타입이 결정됨 \
C. 컴파일 타임에 타입 오류를 발견함 \
D. C++과 동일한 타입 시스템
*정답: B*
*해설*: Python은 동적 타입 언어로, 변수의 타입이 런타임에 결정된다. 이는 빠른 개발을 가능하게 하지만, 런타임 타입 오류의 위험이 있다.
---
=== 문제 2: GIL의 영향 (기초)
GIL(Global Interpreter Lock)로 인해 성능 향상이 없는 작업은?
A. 네트워크 I/O \
B. 파일 읽기/쓰기 \
C. CPU-bound 계산 \
D. time.sleep()
*정답: C*
*해설*: GIL은 한 번에 하나의 스레드만 Python 바이트코드를 실행하도록 제한한다. CPU-bound 작업은 멀티스레드 효과가 없으며, multiprocessing을 사용해야 한다.
---
=== 문제 3: PyQt vs PySide (중급)
PySide6가 PyQt6보다 반도체 산업에서 선호되는 이유는?
A. 더 빠른 성능 \
B. LGPL 라이선스 (상용 무료) \
C. 더 많은 기능 \
D. 더 오래된 역사
*정답: B*
*해설*: PySide6는 LGPL 라이선스로 상용 제품에도 무료로 사용할 수 있다. PyQt는 GPL 또는 상용 라이선스가 필요하다.
---
=== 문제 4: Signal/Slot (중급)
다음 코드의 출력은?
```python
class Sensor(QObject): data = Signal(int)
sensor = Sensor()
sensor.data.connect(lambda x: print(x * 2))
sensor.data.emit(10)
```
A. 10 \
B. 20 \
C. 오류 발생 \
D. 출력 없음
*정답: B*
*해설*: Signal에 연결된 lambda가 인자 10을 받아 `10 * 2 = 20`을 출력한다.
---
=== 문제 5: MVC 패턴 (중급)
MVC 패턴에서 사용자 입력을 처리하는 것은?
A. Model \
B. View \
C. Controller \
D. Signal
*정답: C*
*해설*: Controller는 사용자 입력(버튼 클릭, 타이머 등)을 처리하고 Model을 업데이트한다.
---
=== 문제 6: Singleton Pattern (고급)
다음 Singleton 구현의 문제점은?
```python
class Manager: _instance = None
  def __new__(cls): if cls._instance is None: cls._instance = super().__new__(cls)
  return cls._instance
```
A. 문법 오류 \
B. Thread-safe하지 않음 \
C. 여러 인스턴스 생성 가능 \
D. 메모리 누수
*정답: B*
*해설*: 멀티스레드 환경에서 동시에 두 스레드가 `if cls._instance is None`을 통과하면 두 개의 인스턴스가 생성될 수 있다. `threading.Lock()`이 필요하다.
---
=== 문제 7: Observer Pattern (고급)
다음 코드에서 `update_display`가 몇 번 호출되는가?
```python
model.data_changed.connect(view.update_display)
model.update_data(data1)
model.update_data(data2)
model.update_data(data3)
```
A. 1번 \
B. 2번 \
C. 3번 \
D. 0번
*정답: C*
*해설*: `update_data()`가 호출될 때마다 `data_changed` Signal이 emit되어 `update_display()`가 3번 호출된다.
---
=== 문제 8: Qt Layout (고급)
다음 중 위젯을 세로로 배치하는 레이아웃은?
A. QHBoxLayout \
B. QVBoxLayout \
C. QGridLayout \
D. QFormLayout
*정답: B*
*해설*: QVBoxLayout은 위젯을 수직(세로)으로 배치한다. QHBoxLayout은 수평(가로) 배치이다.
---
=== 문제 9: 코드 분석 - Dataclass (고급)
다음 코드의 출력은?
```python
@dataclass
class Data: temp: float
  pressure: float
  def is_normal(self) -> bool: return 400 <= self.temp <= 500
d = Data(temp=450, pressure=2.5)
print(d.is_normal())
```
A. True \
B. False \
C. None \
D. 오류 발생
*정답: A*
*해설*: `temp=450`은 400~500 범위 내에 있으므로 `is_normal()`은 True를 반환한다.
---
=== 문제 10: Python vs C\# (도전)
반도체 HMI 개발 시 Python 대신 C\#을 선택해야 하는 경우는?
A. 빠른 프로토타이핑이 필요할 때 \
B. 실시간 제어 및 높은 성능이 필요할 때 \
C. 데이터 분석이 주 목적일 때 \
D. AI/ML 통합이 필요할 때
*정답: B*
*해설*: Python은 GIL과 인터프리터 오버헤드로 실시간 제어에 적합하지 않다. 실시간 제어와 높은 성능이 필요한 경우 C++이나 C\#이 더 적합하다.
== 추가 학습 자료
=== 공식 문서
- *PySide6 문서*: https: //doc.qt.io/qtforpython-6/
- *Qt Documentation*: https: //doc.qt.io/
- *Python 공식 문서*: https: //docs.python.org/3/
=== 참고 서적
- "Python GUI Programming with PySide6 & Qt6" by Martin Fitzpatrick
- "Fluent Python" by Luciano Ramalho (Python 고급 기법)
- "Design Patterns in Python" by Brandon Rhodes
=== 온라인 자료
- Qt for Python Examples: https: //doc.qt.io/qtforpython-6/examples/index.html
- Real Python (PySide6 튜토리얼): https: //realpython.com/
- PyQt5/PySide2 Tutorial (Zetcode): https: //zetcode.com/gui/pyqt5/
== 요약
이번 챕터에서는 Python PySide6 기초를 학습했다: *이론 (Theory): *
- Python 언어의 역사와 특징: 동적 타입, GIL, CPython
- Qt 프레임워크 역사: Qt 1.0 (1995) → Qt 6.6 (2023)
- PyQt vs PySide 비교: 라이선스 차이, 산업 채택 동향
- 반도체 산업 Python 채택: 프로토타이핑, 데이터 분석, AI/ML 통합
*응용 (Application): *
- Observer Pattern: Signal/Slot 메커니즘
- MVC Pattern: Model, View, Controller 분리
- Singleton Pattern: Thread-safe 데이터 관리자
- 완전한 실행 가능 예제: 센서 모니터링 시스템 (300+ 줄)
*성찰 (Reflections): *
- MCQ 10문제: Python 기초, Qt 개념, 패턴 이해, 코드 분석
*핵심 포인트: *
1. Python은 빠른 개발과 풍부한 라이브러리가 장점이지만 GIL로 인한 제약이 있음
2. Signal/Slot은 Observer 패턴의 우아한 구현으로 UI와 로직을 분리함
3. MVC 패턴으로 코드의 재사용성과 테스트 가능성을 높임
4. Singleton으로 전역 상태를 thread-safe하게 관리함
다음 챕터에서는 Python 실시간 데이터 처리와 멀티스레딩을 학습한다.
#pagebreak()