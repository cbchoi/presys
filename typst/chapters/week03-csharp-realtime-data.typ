= Week 3: C\# 실시간 데이터 처리
== 학습 목표
본 챕터에서는 다음을 학습한다: + C\# 동시성 모델 이해 (Thread, Task, async/await)
+ 실시간 센서 데이터 처리 기법
+ Thread-safe 프로그래밍 패턴
+ Producer-Consumer 패턴 구현
+ 실시간 데이터 시각화
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *Week 2 MVVM 이해*: INotifyPropertyChanged, Command Pattern 구현 경험
- *멀티스레딩 기초*: 프로세스와 스레드의 차이, 동시성 개념
- *비동기 프로그래밍 개념*: 콜백, 이벤트 기반 프로그래밍
- *C\# 중급*: 제네릭, 람다 표현식, LINQ
- *권장사항*: 운영체제 기초 (스케줄링, 컨텍스트 스위칭)
== C\# 동시성 모델의 역사와 발전
=== Thread 기반 모델 (2000-2012)
초기 C\#은 .NET Framework의 Thread 클래스를 통해 멀티스레딩을 지원했다. 이는 운영체제 스레드를 직접 매핑한 low-level 접근이었다.
*한계점*:
- 스레드 생성 비용 높음 (1MB 스택 메모리)
- 스케줄링 오버헤드
- 복잡한 동기화 (lock, Monitor)
- 데드락 위험
*예제: Thread 방식 (구식)*:
```csharp
// 2000년대 방식 (권장하지 않음)
var thread = new Thread(() => {
    for (int i = 0; i < 100; i++) {
        Console.WriteLine($"Thread {i}");
        Thread.Sleep(100);
    }
});
thread.Start();
thread.Join();  // 완료 대기
```
=== Task 기반 비동기 패턴 (2010-현재)
.NET 4.0(2010)에서 Task Parallel Library (TPL)가 도입되며 혁신적 변화가 시작되었다.
*Task 장점*:
- Thread Pool 활용 (스레드 재사용)
- 취소 토큰 (CancellationToken)
- 예외 처리 개선
- Continuation 지원 (ContinueWith)
*예제: Task 방식*:
```csharp
// 2010년대 방식 (개선됨)
var task = Task.Run(() => {
    for (int i = 0; i < 100; i++) {
        Console.WriteLine($"Task {i}");
        Task.Delay(100).Wait();
    }
});
await task;  // 완료 대기
```
=== async/await 혁명 (2012-현재)
C\# 5.0(2012)에서 async/await 키워드가 도입되며 비동기 프로그래밍이 획기적으로 간소화되었다.
*async/await 장점*:
- 동기 코드처럼 읽기 쉬움 (콜백 지옥 해결)
- 컴파일러가 상태 머신 자동 생성
- 예외 처리가 자연스러움 (try-catch 사용 가능)
- UI 스레드 블로킹 방지
*예제: async/await 방식 (현대적)*:
```csharp
// 2012년 이후 권장 방식
public async Task ProcessDataAsync()
{
    for (int i = 0; i < 100; i++)
    {
        Console.WriteLine($"Async {i}");
        await Task.Delay(100);  // UI 스레드 블로킹 없음
    }
}
// 사용
await ProcessDataAsync();
```
=== .NET Thread Pool의 동작 원리
.NET의 Thread Pool은 스레드를 재사용하여 성능을 최적화한다.
```
┌─────────────────────────┐
│   Application Code      │
└──────────┬──────────────┘
           │ Task.Run()
           ↓
┌─────────────────────────┐
│     Task Scheduler      │  ← 작업 큐 관리
└──────────┬──────────────┘
           │
           ↓
┌─────────────────────────┐
│    Thread Pool          │
│  ┌────┐ ┌────┐ ┌────┐  │
│  │ T1 │ │ T2 │ │ T3 │  │  ← Worker Threads
│  └────┘ └────┘ └────┘  │
└─────────────────────────┘
```
*Thread Pool 특징*:
- 최소 스레드: CPU 코어 수
- 최대 스레드: 환경에 따라 다름 (수백 ~ 수천)
- 자동 확장/축소
- 작업 큐 기반 스케줄링
*모니터링*:
```csharp
ThreadPool.GetMaxThreads(out int workerThreads, out int ioThreads);
ThreadPool.GetAvailableThreads(out int availWorker, out int availIO);
Console.WriteLine($"Max: {workerThreads}, Available: {availWorker}");
```
=== C\# vs Python GIL 비교
Python의 Global Interpreter Lock (GIL)과 C\#의 차이점: #figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*Python (GIL)*], [*C\# (.NET)*], [멀티스레딩], [CPU-bound 작업 시 단일 코어만 사용], [모든 코어 완전 활용], [병렬 처리], [multiprocessing 필요], [Thread/Task로 자연스럽게 가능], [I/O-bound], [유리 (GIL 해제)], [async/await로 더 효율적], [동기화], [GIL로 일부 자동 보호], [명시적 lock 필요], ), caption: "C\# vs Python 멀티스레딩 비교")
*결론*: 반도체 HMI처럼 실시간 데이터 처리가 중요한 경우 C\#이 유리하다.
== 동시성 이론적 기반 (Concurrency Theory)
=== Concurrency vs Parallelism
동시성과 병렬성은 종종 혼동되지만 명확히 구분되는 개념이다.
*Concurrency (동시성)*:
- 정의: 여러 작업이 **논리적으로** 동시에 진행되는 것처럼 보이는 것
- 구현: Single Core에서 시분할(Time-Slicing)로 가능
- 목적: 응답성(Responsiveness) 향상
- 예시: UI 스레드가 버튼 클릭을 처리하면서 동시에 데이터 로딩
*Parallelism (병렬성)*:
- 정의: 여러 작업이 **물리적으로** 동시에 실행되는 것
- 구현: Multi-Core CPU 필수
- 목적: 처리량(Throughput) 향상
- 예시: 4개 코어에서 각각 다른 센서 데이터를 동시에 처리
```
Concurrency (동시성): Parallelism (병렬성):
Single Core                      Multi-Core
Time →                           Time →
┌────────────────┐              ┌────────────────┐
│ Task A │ Task B│              │ Task A │       │
│ Task B │ Task A│              ├────────┤       │
│ Task A │ Task B│              │ Task B │       │
└────────────────┘              ├────────┤       │
  (시분할 스위칭)                 │ Task C │       │
                                ├────────┤       │
                                │ Task D │       │
                                └────────────────┘
                                 (진정한 병렬)
```
*반도체 HMI 적용*:
- Concurrency: UI 업데이트와 네트워크 통신을 동시에 처리
- Parallelism: 여러 챔버의 센서 데이터를 각 코어에서 병렬 처리
=== Amdahl's Law (암달의 법칙)
Gene Amdahl(1967)이 제안한 병렬 처리의 이론적 한계를 설명하는 법칙이다.
*수식*: $ "Speedup" = 1 / ((1 - P) + P / N) $
- P: 병렬화 가능한 부분의 비율 (0 \< P \< 1)
- N: 프로세서 개수
- (1 - P): 순차적으로만 실행 가능한 부분
*예시 계산*: 프로그램의 75%가 병렬화 가능할 때 (P = 0.75): - 2 코어: Speedup = 1 / (0.25 + 0.75/2) = 1.6배
- 4 코어: Speedup = 1 / (0.25 + 0.75/4) = 2.3배
- 8 코어: Speedup = 1 / (0.25 + 0.75/8) = 2.9배
- 무한대 코어: Speedup = 1 / 0.25 = 4배 (한계)
```
Speedup vs. Number of Cores (P=0.75)
  4│                    ┌─────────
   │                 ┌──┘
   │              ┌──┘
  3│           ┌──┘
   │        ┌──┘
   │     ┌──┘
  2│  ┌──┘
   │ ┌┘
   │┌┘
  1├─────────────────────────────
   0  2   4   6   8  10  12  14
              Number of Cores
```
*핵심 교훈*:
- 순차적 부분(25%)이 전체 성능의 병목이 된다
- 코어를 무한정 추가해도 4배 이상 빨라질 수 없다
- 실무에서는 동기화 오버헤드로 실제 Speedup은 이론값보다 낮다
*반도체 HMI 최적화 전략*:
```csharp
// ❌ 나쁜 예: 순차적 처리 (P=0%)
var results = new List<double>();
foreach (var sensor in sensors)
{
    var data = await ReadSensorAsync(sensor);  // 각 센서 순차 처리
    results.Add(ProcessData(data));
}
// ✓ 좋은 예: 병렬 처리 (P≈95%)
var tasks = sensors.Select(async sensor =>
{
    var data = await ReadSensorAsync(sensor);
    return ProcessData(data);
});
var results = await Task.WhenAll(tasks);  // 모든 센서 병렬 처리
```
=== Critical Section과 Race Condition
*Critical Section (임계 영역)*:
- 정의: 공유 자원에 접근하는 코드 영역
- 특성: 한 번에 하나의 스레드만 실행되어야 함
- 보호 방법: lock, Mutex, Semaphore
*Race Condition (경쟁 조건)*:
- 정의: 여러 스레드가 공유 자원에 동시 접근하여 예측 불가능한 결과 발생
- 발생 조건: 1. 공유 자원 존재
  2. 최소 2개 스레드가 동시 접근
  3. 최소 1개 스레드가 쓰기 작업 수행
*예제: Race Condition 발생*: ```csharp
// ❌ Thread-unsafe: Race Condition 발생
public class UnsafeCounter
{
  private int _count = 0;
  public void Increment()
  {
  // 3단계로 나뉘어 실행됨: // 1. _count 값을 레지스터로 로드
  // 2. 레지스터 값을 +1
  // 3. 레지스터 값을 _count에 저장
  _count++; // 원자적 연산이 아님!
  }
  public int Count => _count;
}
// 2개 스레드가 동시 실행 시:
// Thread 1: Load(0) → Add(1) → [Context Switch]
// Thread 2: Load(0) → Add(1) → Store(1)
// Thread 1: Store(1) ← 결과: 2가 아닌 1!
```
*타임라인 분석*: ```
Time  Thread 1              Thread 2              _count
────────────────────────────────────────────────────────
  0   -                     -                     0
  1   Load _count (0)       -                     0
  2   Add 1 → result=1      -                     0
  3   [Context Switch] →    Load _count (0)       0
  4   -                     Add 1 → result=1      0
  5   -                     Store 1               1
  6   Store 1               -                     1  ← 잘못된 결과!
```
*해결책 1: lock 사용*: ```csharp
// ✓ Thread-safe: lock 사용
public class SafeCounter
{
  private int _count = 0;
  private readonly object _lock = new();
  public void Increment()
  {
  lock (_lock) // Critical Section 보호
  {
  _count++; // 한 번에 1개 스레드만 실행
  }
  }
  public int Count
  {
  get { lock (_lock) { return _count; } }
  }
}
```
*해결책 2: Interlocked 사용 (더 효율적)*: ```csharp
// ✓ Thread-safe: Lock-free 원자적 연산
public class LockFreeCounter
{
    private int _count = 0;
    public void Increment()
    {
        Interlocked.Increment(ref _count);  // CPU 명령어 수준 원자성
    }
    public int Count => Interlocked.CompareExchange(ref _count, 0, 0);  // 안전한 읽기
}
// 성능 비교 (1억 회 Increment):
// lock: ~2000ms
// Interlocked: ~500ms  (4배 빠름)
```
=== Deadlock (교착 상태)
*정의*: 두 개 이상의 스레드가 서로가 가진 자원을 기다리며 무한 대기하는 상태
*Deadlock 발생 4가지 필수 조건 (Coffman, 1971)*: 1. **Mutual Exclusion (상호 배제)**: 자원은 한 번에 1개 스레드만 사용
2. **Hold and Wait (보유 및 대기)**: 자원을 보유한 채 다른 자원 대기
3. **No Preemption (비선점)**: 자원을 강제로 빼앗을 수 없음
4. **Circular Wait (순환 대기)**: 스레드들이 원형으로 자원을 대기
*예제: Deadlock 발생*: ```csharp
// ❌ Deadlock 발생 가능
public class Equipment
{
  private readonly object _lock1 = new();
  private readonly object _lock2 = new();
  public void MethodA()
  {
  lock (_lock1) // 1. Thread 1이 lock1 획득
  {
  Thread.Sleep(100); // 시뮬레이션
  lock (_lock2) // 3. Thread 1이 lock2 대기 (Thread 2가 보유 중) → Deadlock!
  {
  Console.WriteLine("MethodA");
  }
  }
  }
  public void MethodB()
  {
  lock (_lock2) // 2. Thread 2가 lock2 획득
  {
  Thread.Sleep(100); // 시뮬레이션
  lock (_lock1) // 4. Thread 2가 lock1 대기 (Thread 1이 보유 중) → Deadlock!
  {
  Console.WriteLine("MethodB");
  }
  }
  }
}
// 실행:
var eq = new Equipment();
var t1 = Task.Run(() => eq.MethodA());
var t2 = Task.Run(() => eq.MethodB());
await Task.WhenAll(t1, t2); // 영원히 완료되지 않음!
```
*해결책 1: Lock Ordering (권장)*: ```csharp
// ✓ Deadlock 방지: 항상 같은 순서로 lock 획득
public class SafeEquipment
{
    private readonly object _lock1 = new();
    private readonly object _lock2 = new();
    public void MethodA()
    {
        lock (_lock1)  // 항상 lock1 먼저
        {
            lock (_lock2)  // 그 다음 lock2
            {
                Console.WriteLine("MethodA");
            }
        }
    }
    public void MethodB()
    {
        lock (_lock1)  // 여기도 lock1 먼저
        {
            lock (_lock2)  // 그 다음 lock2
            {
                Console.WriteLine("MethodB");
            }
        }
    }
}
```
*해결책 2: Monitor.TryEnter (Timeout)*: ```csharp
// ✓ Deadlock 방지: Timeout으로 감지 후 재시도
public void MethodWithTimeout()
{
  bool lock1Acquired = false;
  bool lock2Acquired = false;
  try
  {
  Monitor.TryEnter(_lock1, TimeSpan.FromSeconds(5), ref lock1Acquired);
  if (!lock1Acquired)
  throw new TimeoutException("Cannot acquire lock1");
  Monitor.TryEnter(_lock2, TimeSpan.FromSeconds(5), ref lock2Acquired);
  if (!lock2Acquired)
  throw new TimeoutException("Cannot acquire lock2");
  // Critical Section
  Console.WriteLine("Both locks acquired");
  }
  finally
  {
  if (lock2Acquired) Monitor.Exit(_lock2);
  if (lock1Acquired) Monitor.Exit(_lock1);
  }
}
```
== .NET Memory Model (메모리 모델)
=== Happens-Before 관계
.NET Memory Model은 멀티스레드 환경에서 메모리 연산의 순서를 정의한다.
*정의*: 연산 A가 연산 B보다 "happens-before" 관계에 있으면, A의 결과가 B에게 보장된다.
*Happens-Before 규칙*: 1. **Program Order**: 단일 스레드 내에서는 코드 순서대로 실행된 것처럼 보임
2. **Monitor Lock**: lock 해제는 다음 lock 획득보다 happens-before
3. **Volatile Read/Write**: volatile 쓰기는 이후 volatile 읽기보다 happens-before
4. **Thread Start/Join**: Start()는 새 스레드 시작보다, Join()은 스레드 종료보다 happens-before
*예제: Reordering 문제*: ```csharp
// ❌ 잘못된 예: Reordering으로 인한 문제
public class ReorderingProblem
{
    private int _value = 0;
    private bool _ready = false;
    public void Writer()  // Thread 1
    {
        _value = 42;      // 1. 값 설정
        _ready = true;    // 2. 플래그 설정
        // CPU/컴파일러가 최적화를 위해 순서를 바꿀 수 있음: // _ready = true;   (먼저 실행)
        // _value = 42;     (나중에 실행)
    }
    public int Reader()  // Thread 2
    {
        if (_ready)       // 3. 플래그 체크
            return _value; // 4. 값 읽기
        return 0;
        // Reordering으로 인해 _ready=true이지만 _value=0일 수 있음!
    }
}
```
*타임라인 (Reordering 발생 시)*: ```
Time Thread 1 (Writer) Thread 2 (Reader) 메모리 상태
────────────────────────────────────────────────────────────────
  0 -  -  _value=0, _ready=false
  1 _ready = true (재배치) -  _value=0, _ready=true
  2 -  if (_ready) → true _value=0, _ready=true
  3 -  return _value (0) ← 잘못된 값!
  4 _value = 42 (늦게 실행) - _value=42, _ready=true
```
*해결책: volatile 키워드*: ```csharp
// ✓ 올바른 예: volatile로 Reordering 방지
public class VolatileSolution
{
    private int _value = 0;
    private volatile bool _ready = false;  // volatile: 순서 보장
    public void Writer()
    {
        _value = 42;      // 1. 반드시 먼저 실행
        _ready = true;    // 2. 반드시 나중에 실행 (volatile 쓰기)
    }
    public int Reader()
    {
        if (_ready)       // volatile 읽기: _value 변경이 보장됨
            return _value; // 올바른 값 42 반환
        return 0;
    }
}
```
=== Memory Barrier (메모리 장벽)
*정의*: CPU와 컴파일러의 메모리 재배치를 방지하는 명령어
*종류*: 1. **Full Barrier**: 모든 읽기/쓰기 재배치 방지
2. **Acquire Barrier**: 이후 읽기/쓰기가 앞으로 이동 방지
3. **Release Barrier**: 이전 읽기/쓰기가 뒤로 이동 방지
*.NET에서의 Memory Barrier*: ```csharp
// 명시적 Memory Barrier
Thread.MemoryBarrier(); // Full Barrier
// lock은 자동으로 Memory Barrier 포함
lock (_lock) // Acquire Barrier (진입 시)
{
  // Critical Section
} // Release Barrier (탈출 시)
// volatile 읽기/쓰기도 자동으로 Barrier 포함
volatile bool _flag;
_flag = true; // Release Barrier (이전 모든 쓰기 완료 후 실행)
if (_flag) // Acquire Barrier (이후 모든 읽기 전에 실행)
```
*예제: Double-Checked Locking with volatile*: ```csharp
// Singleton Pattern의 Double-Checked Locking
public sealed class Singleton
{
    // volatile 없으면 Reordering으로 인해 생성자가 완료되기 전에
    // _instance가 null이 아닌 값을 가질 수 있음!
    private static volatile Singleton? _instance;
    private static readonly object _lock = new();
    private Singleton() { /* 생성자 */ }
    public static Singleton Instance
    {
        get
        {
            if (_instance == null)  // 1차 체크 (lock 없이)
            {
                lock (_lock)
                {
                    if (_instance == null)  // 2차 체크 (lock 내부)
                    {
                        _instance = new Singleton();  // volatile 쓰기
                    }
                }
            }
            return _instance;  // volatile 읽기
        }
    }
}
```
=== lock 구문의 내부 동작
C\#의 lock은 Monitor 클래스의 syntactic sugar다.
*컴파일러 변환*: ```csharp
// 원본 코드:
lock (_lock)
{
  _count++;
}
// 컴파일러가 변환한 코드 (의사코드):
bool lockTaken = false;
try
{
  Monitor.Enter(_lock, ref lockTaken); // Acquire Barrier
  _count++;
}
finally
{
  if (lockTaken)
  Monitor.Exit(_lock); // Release Barrier
}
```
*Monitor 내부 구조*: ```
Object Header (모든 .NET 객체):
┌────────────────────────────┐
│ Sync Block Index (4 bytes) │ ← Monitor가 사용
├────────────────────────────┤
│ Type Handle (4/8 bytes)    │
├────────────────────────────┤
│ Object Fields...           │
└────────────────────────────┘
Sync Block Table (전역):
┌─────────────────────────────────┐
│ Entry 0: Thread ID, Wait Queue  │
│ Entry 1: Thread ID, Wait Queue  │
│ Entry N: Thread ID, Wait Queue  │
└─────────────────────────────────┘
```
*lock 비용 분석*: ```csharp
// 성능 테스트 (1억 회 반복):
public void TestLockPerformance()
{
  var obj = new object();
  var sw = Stopwatch.StartNew();
  for (int i = 0; i < 100_000_000; i++)
  {
  lock (obj) { } // Empty lock
  }
  sw.Stop();
  Console.WriteLine($"Lock: {sw.ElapsedMilliseconds}ms");
  // 결과: 약 2500ms (1회당 25ns)
}
// 비교: Interlocked는 1회당 5ns (5배 빠름)
```
== Thread Pool 아키텍처 상세
=== Work Stealing Queue
.NET Thread Pool은 Work Stealing 알고리즘을 사용한다.
*구조*: ```
┌─────────────────────────────────────────────┐
│         Global Work Queue                    │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐               │
│  │ T1 │→│ T2 │→│ T3 │→│ T4 │→ ...          │ ← FIFO (먼저 들어온 것 먼저 처리)
│  └────┘ └────┘ └────┘ └────┘               │
└─────────────────────────────────────────────┘
         ↓ Enqueue (Task.Run)
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Worker 1     │  │ Worker 2     │  │ Worker 3     │
│ Local Queue  │  │ Local Queue  │  │ Local Queue  │
│ ┌─────────┐  │  │ ┌─────────┐  │  │ ┌─────────┐  │
│ │ Task A  │  │  │ │ Task D  │  │  │ │ Task G  │  │
│ ├─────────┤  │  │ ├─────────┤  │  │ ├─────────┤  │
│ │ Task B  │  │  │ │ Task E  │  │  │ │ Task H  │  │
│ ├─────────┤  │  │ ├─────────┤  │  │ ├─────────┤  │
│ │ Task C  │  │  │ │ Task F  │  │  │ │ Task I  │  │
│ └─────────┘  │  │ └─────────┘  │  │ └─────────┘  │
│   ↑ LIFO     │  │   ↑ LIFO     │  │   ↑ LIFO     │
│   (자신의 작업)│  │              │  │              │
│              │  │  ← Steal ───────┘              │
│              │  │  (다른 Worker의 작업 훔치기)      │
└──────────────┘  └──────────────┘  └──────────────┘
```
*Work Stealing 알고리즘*: 1. **자신의 작업**: Local Queue에서 LIFO로 꺼냄 (캐시 친화적)
2. **다른 Worker의 작업**: 다른 Worker의 Local Queue 끝에서 FIFO로 훔침
3. **Global Queue**: 모든 Local Queue가 비면 Global Queue에서 가져옴
*장점*:
- Lock Contention 감소 (각 Worker는 자신의 Queue 사용)
- 캐시 지역성 향상 (최근 작업을 LIFO로 처리)
- 부하 분산 자동화 (바쁜 Worker → 한가한 Worker로 작업 이동)
*예제 코드*: ```csharp
// Task.Run은 Global Queue에 추가
Task.Run(() => DoWork());
// Task.Factory.StartNew로 Local Queue 사용 가능
Task.Factory.StartNew(() => DoWork(), CancellationToken.None, TaskCreationOptions.None, // Global Queue
  TaskScheduler.Default);
// 중첩 Task는 Local Queue에 추가됨
Task.Run(() =>
{
  Task.Run(() => DoNestedWork()); // Local Queue 사용 (Work Stealing 대상)
});
```
=== ThreadPool.SetMinThreads의 중요성
Thread Pool은 초기에 최소 스레드만 생성하고, 필요 시 점진적으로 확장한다.
*기본 동작*: ```csharp
// 기본 설정 확인
ThreadPool.GetMinThreads(out int minWorker, out int minIO);
ThreadPool.GetMaxThreads(out int maxWorker, out int maxIO);
Console.WriteLine($"Min: Worker={minWorker}, IO={minIO}");  // 보통 CPU 코어 수
Console.WriteLine($"Max: Worker={maxWorker}, IO={maxIO}");  // 보통 수백~수천
```
*문제 상황*: ```csharp
// ❌ 문제: Thread Pool Starvation
// 100개 작업을 한꺼번에 시작하지만, 최소 스레드가 4개라면
// 처음 4개만 즉시 실행되고 나머지는 대기
var tasks = Enumerable.Range(0, 100)
  .Select(i => Task.Run(async () =>
  {
  await Task.Delay(1000); // 1초 대기
  return i;
  }))
  .ToArray();
await Task.WhenAll(tasks);
// 실행 시간: 약 25초 (100 / 4 = 25 batch)
```
*해결책*: ```csharp
// ✓ 해결: 최소 스레드 수 증가
ThreadPool.SetMinThreads(100, 100);  // Worker, IO 각각 100개로 설정
var tasks = Enumerable.Range(0, 100)
    .Select(i => Task.Run(async () =>
    {
        await Task.Delay(1000);
        return i;
    }))
    .ToArray();
await Task.WhenAll(tasks);
// 실행 시간: 약 1초 (모든 Task가 즉시 시작)
```
*주의사항*:
- SetMinThreads는 스레드를 즉시 생성하지 않고, 필요 시 빠르게 생성되도록 예약
- 너무 높게 설정하면 컨텍스트 스위칭 오버헤드 증가
- 반도체 HMI에서는 센서 개수 + 여유분(20%)으로 설정 권장
*실무 예제*: ```csharp
// 반도체 장비: 50개 센서 동시 모니터링
public class EquipmentController
{
  public EquipmentController()
  {
  // 최소 스레드를 센서 개수 + 20% 여유분으로 설정
  int sensorCount = 50;
  int minThreads = (int)(sensorCount * 1.2);
  ThreadPool.SetMinThreads(minThreads, minThreads);
  }
  public async Task StartMonitoringAsync(List<Sensor> sensors)
  {
  var tasks = sensors.Select(sensor =>
  Task.Run(() => MonitorSensorAsync(sensor)));
  await Task.WhenAll(tasks); // 모든 센서 동시 모니터링
  }
}
```
=== ThreadPool vs Dedicated Thread
*비교 표*: #figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*ThreadPool*], [*Dedicated Thread*], [생성 비용], [낮음 (재사용)], [높음 (new Thread)], [생명 주기], [.NET이 관리], [개발자가 직접 관리], [적용 분야], [짧은 작업 (ms~s)], [긴 작업 (min~h)], [우선순위 설정], [불가능], [가능 (ThreadPriority)], [취소], [CancellationToken], [Thread.Abort (위험)], ), caption: "ThreadPool vs Dedicated Thread")
*Dedicated Thread가 필요한 경우*: ```csharp
// 1. 장시간 실행 (예: 24시간 센서 모니터링)
public void StartLongRunningMonitoring()
{
    var thread = new Thread(() =>
    {
        while (true)
        {
            MonitorSensor();
            Thread.Sleep(100);
        }
    })
    {
        IsBackground = true, // 백그라운드 스레드 (메인 종료 시 자동 종료)
        Priority = ThreadPriority.AboveNormal  // 우선순위 설정
    };
    thread.Start();
}
// 2. Task 방식 (권장): TaskCreationOptions.LongRunning
public Task StartLongRunningTask()
{
    return Task.Factory.StartNew(() =>
    {
        while (true)
        {
            MonitorSensor();
            Thread.Sleep(100);
        }
    }, TaskCreationOptions.LongRunning);  // Thread Pool 사용 안함
}
```
== 반도체 산업에서의 실시간 데이터 처리 동향
=== 데이터 처리량 증가
*현대 반도체 장비 데이터 특성*:
- CVD/PVD: 100-1000 파라미터 동시 모니터링
- 샘플링 주기: 10ms - 100ms
- 데이터 처리량: 10, 000 - 100, 000 points/second
- 알람 응답 시간: \< 50ms (SEMI E95)
=== Edge Computing 트렌드
*장비 사이드 처리*:
- 원본 데이터는 장비에서 전처리
- 통계 정보만 MES로 전송
- 네트워크 부하 감소
- 실시간 응답 보장
=== 주요 장비사 접근 방식
*Applied Materials*:
- 멀티 챔버 동시 모니터링
- 고성능 데이터 수집 (DAQ)
- 실시간 SPC (Statistical Process Control)
*ASML*:
- 초고속 센서 데이터 (kHz 단위)
- FPGA 기반 전처리
- C\# HMI는 디스플레이만 담당
== 이론: C\# 동시성 모델
=== Thread vs Task vs async/await
#figure(table(columns: (auto, auto, auto, auto), align: left, [*방식*], [*생성 비용*], [*적용 분야*], [*코드 복잡도*], [Thread], [높음 (1MB/스레드)], [Long-running 작업], [높음], [Task], [낮음 (Thread Pool)], [CPU-bound 작업], [중간], [async/await], [매우 낮음], [I/O-bound 작업], [낮음], ), caption: "C\# 동시성 모델 비교")
=== async/await 내부 동작 원리
컴파일러가 async 메서드를 상태 머신으로 변환한다: *원본 코드*:
```csharp
public async Task<double> ReadTemperatureAsync()
{
    await Task.Delay(100);  // 센서 통신 시뮬레이션
    return 450.0;
}
```
*컴파일러 변환 (의사코드)*:
```csharp
// 컴파일러가 생성한 상태 머신 (간략화)
public Task<double> ReadTemperatureAsync()
{
    var stateMachine = new ReadTemperatureStateMachine();
    stateMachine.builder = AsyncTaskMethodBuilder<double>.Create();
    stateMachine.state = -1;
    stateMachine.builder.Start(ref stateMachine);
    return stateMachine.builder.Task;
}
struct ReadTemperatureStateMachine
{
    public int state;
    public AsyncTaskMethodBuilder<double> builder;
    private TaskAwaiter awaiter;
    public void MoveNext()
    {
        switch (state)
        {
            case 0: // 상태 0: await 전
                awaiter = Task.Delay(100).GetAwaiter();
                if (!awaiter.IsCompleted)
                {
                    state = 1;
                    builder.AwaitUnsafeOnCompleted(ref awaiter, ref this);
                    return;
                }
                goto case 1;
            case 1: // 상태 1: await 후
                awaiter.GetResult();
                builder.SetResult(450.0);
                return;
        }
    }
}
```
*핵심 개념*:
- async 메서드는 Task를 즉시 반환
- await 지점에서 상태 저장 후 스레드 반환
- 작업 완료 시 콜백으로 재개
- UI 스레드 블로킹 없음
== 응용: 디자인 패턴
=== Producer-Consumer Pattern
반도체 장비에서 센서 데이터를 수집(Producer)하고 처리(Consumer)하는 패턴: ```csharp
using System.Collections.Concurrent;
using System.Threading.Channels;
// Channel 기반 Producer-Consumer (현대적 방식)
public class SensorDataProcessor
{
  private readonly Channel<SensorData> _channel;
  public SensorDataProcessor()
  {
  // Bounded Channel (버퍼 크기 제한)
  _channel = Channel.CreateBounded<SensorData>(new BoundedChannelOptions(1000)
  {
  FullMode = BoundedChannelFullMode.DropOldest // 버퍼 가득 시 오래된 데이터 삭제
  });
  }
  // Producer: 센서 데이터 수집
  public async Task ProduceAsync(CancellationToken ct)
  {
  var random = new Random();
  while (!ct.IsCancellationRequested)
  {
  var data = new SensorData
  {
  Timestamp = DateTime.Now, Temperature = 450 + random.NextDouble() * 10, Pressure = 2.5 + random.NextDouble() * 0.5
  };
  await _channel.Writer.WriteAsync(data, ct);
  await Task.Delay(100, ct); // 100ms 주기
  }
  _channel.Writer.Complete();
  }
  // Consumer: 데이터 처리
  public async Task ConsumeAsync(CancellationToken ct)
  {
  await foreach (var data in _channel.Reader.ReadAllAsync(ct))
  {
  // 데이터 처리
  ProcessData(data);
  // 알람 체크
  if (data.Temperature > 480)
  {
  RaiseAlarm($"High Temperature: {data.Temperature: F1}°C");
  }
  }
  }
  private void ProcessData(SensorData data)
  {
  // UI 업데이트, 로깅 등
  Console.WriteLine($"[{data.Timestamp: HH: mm: ss}] Temp: {data.Temperature: F1}°C, Press: {data.Pressure: F2} Torr");
  }
  private void RaiseAlarm(string message)
  {
  Console.WriteLine($"⚠️ ALARM: {message}");
  }
}
public record SensorData
{
  public DateTime Timestamp { get; init; }
  public double Temperature { get; init; }
  public double Pressure { get; init; }
}
```
*사용 방법*:
```csharp
var processor = new SensorDataProcessor();
var cts = new CancellationTokenSource();
// Producer와 Consumer를 병렬 실행
var produceTask = Task.Run(() => processor.ProduceAsync(cts.Token));
var consumeTask = Task.Run(() => processor.ConsumeAsync(cts.Token));
// 10초 후 취소
await Task.Delay(10000);
cts.Cancel();
await Task.WhenAll(produceTask, consumeTask);
```
=== Thread-safe Singleton Pattern
데이터 관리 서비스를 Singleton으로 구현: ```csharp
public sealed class DataManager
{
    // Lazy<T>를 사용한 Thread-safe Singleton
    private static readonly Lazy<DataManager> _instance =
        new Lazy<DataManager>(() => new DataManager());
    public static DataManager Instance => _instance.Value;
    // Thread-safe 컬렉션
    private readonly ConcurrentQueue<SensorData> _dataQueue;
    private readonly ConcurrentDictionary<string, double> _latestValues;
    private readonly SemaphoreSlim _semaphore;
    private DataManager()
    {
        _dataQueue = new ConcurrentQueue<SensorData>();
        _latestValues = new ConcurrentDictionary<string, double>();
        _semaphore = new SemaphoreSlim(1, 1);  // Async lock
    }
    // Thread-safe 데이터 추가
    public void AddData(SensorData data)
    {
        _dataQueue.Enqueue(data);
        _latestValues["Temperature"] = data.Temperature;
        _latestValues["Pressure"] = data.Pressure;
        // 큐 크기 제한
        while (_dataQueue.Count > 1000)
        {
            _dataQueue.TryDequeue(out _);
        }
    }
    // Thread-safe 최신 값 조회
    public double GetLatestValue(string key)
    {
        return _latestValues.TryGetValue(key, out var value) ? value : 0.0;
    }
    // Async lock 사용 (중요한 작업)
    public async Task<List<SensorData>> GetSnapshotAsync()
    {
        await _semaphore.WaitAsync();
        try
        {
            return _dataQueue.ToList();
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
```
=== Observable Pattern (IObservable)
Reactive Extensions (Rx) 대신 간단한 Observable 직접 구현: ```csharp
using System;
using System.Collections.Generic;
// 간단한 Observable 구현
public class SensorObservable
{
  private readonly List<IObserver<SensorData>> _observers = new();
  private readonly Timer _timer;
  private readonly Random _random = new();
  public SensorObservable()
  {
  _timer = new Timer(GenerateData, null, TimeSpan.Zero, TimeSpan.FromMilliseconds(100));
  }
  public IDisposable Subscribe(IObserver<SensorData> observer)
  {
  if (!_observers.Contains(observer))
  _observers.Add(observer);
  return new Unsubscriber(_observers, observer);
  }
  private void GenerateData(object? state)
  {
  var data = new SensorData
  {
  Timestamp = DateTime.Now, Temperature = 450 + _random.NextDouble() * 10, Pressure = 2.5 + _random.NextDouble() * 0.5
  };
  // 모든 Observer에게 통지
  foreach (var observer in _observers)
  {
  observer.OnNext(data);
  }
  }
  private class Unsubscriber : IDisposable
  {
  private readonly List<IObserver<SensorData>> _observers;
  private readonly IObserver<SensorData> _observer;
  public Unsubscriber(List<IObserver<SensorData>> observers, IObserver<SensorData> observer)
  {
  _observers = observers;
  _observer = observer;
  }
  public void Dispose()
  {
  _observers.Remove(_observer);
  }
  }
}
// Observer 구현
public class SensorMonitor : IObserver<SensorData>
{
  private IDisposable? _unsubscriber;
  public void Subscribe(SensorObservable observable)
  {
  _unsubscriber = observable.Subscribe(this);
  }
  public void OnNext(SensorData data)
  {
  Console.WriteLine($"Received: Temp={data.Temperature: F1}°C, Press={data.Pressure: F2} Torr");
  // 알람 체크
  if (data.Temperature > 480)
  {
  Console.WriteLine("⚠️ High Temperature Alarm!");
  }
  }
  public void OnError(Exception error)
  {
  Console.WriteLine($"Error: {error.Message}");
  }
  public void OnCompleted()
  {
  Console.WriteLine("Monitoring completed");
  _unsubscriber?.Dispose();
  }
}
```
*사용 방법*:
```csharp
var observable = new SensorObservable();
var monitor = new SensorMonitor();
monitor.Subscribe(observable);
// 10초 동안 모니터링
await Task.Delay(10000);
```
== 완전한 실행 가능한 예제: 실시간 센서 데이터 수집
=== 요구사항
+ 3개 센서 동시 모니터링 (온도, 압력, 유량)
+ 100ms 주기 데이터 수집
+ Thread-safe 큐로 데이터 버퍼링
+ 알람 자동 감지
+ WPF UI 업데이트
=== Model: SensorData.cs
```csharp
using System;
namespace RealtimeHMI.Models
{
  public class SensorData
  {
  public DateTime Timestamp { get; init; }
  public double Temperature { get; init; }
  public double Pressure { get; init; }
  public double FlowRate { get; init; }
  public bool IsNormal =>
  Temperature >= 400 && Temperature <= 500 &&
  Pressure >= 2.0 && Pressure <= 3.0 &&
  FlowRate >= 90 && FlowRate <= 110;
  }
  public class Alarm
  {
  public DateTime Timestamp { get; init; }
  public string Message { get; init; } = string.Empty;
  public AlarmLevel Level { get; init; }
  }
  public enum AlarmLevel
  {
  Info, Warning, Critical
  }
}
```
=== Service: SensorService.cs
```csharp
using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;
using RealtimeHMI.Models;
namespace RealtimeHMI.Services
{
  public class SensorService
  {
  private readonly ConcurrentQueue<SensorData> _dataQueue;
  private readonly Random _random = new();
  private CancellationTokenSource? _cts;
  // 현재 값 (Thread-safe)
  private double _temperature = 450;
  private double _pressure = 2.5;
  private double _flowRate = 100;
  public event EventHandler<SensorData>? DataReceived;
  public event EventHandler<Alarm>? AlarmRaised;
  public SensorService()
  {
  _dataQueue = new ConcurrentQueue<SensorData>();
  }
  public async Task StartAsync()
  {
  _cts = new CancellationTokenSource();
  await Task.Run(() => CollectDataAsync(_cts.Token));
  }
  public void Stop()
  {
  _cts?.Cancel();
  }
  private async Task CollectDataAsync(CancellationToken ct)
  {
  while (!ct.IsCancellationRequested)
  {
  // 센서 데이터 시뮬레이션 (랜덤 워크)
  _temperature += _random.NextDouble() * 2 - 1; // ±1도
  _pressure += _random.NextDouble() * 0.1 - 0.05; // ±0.05 Torr
  _flowRate += _random.NextDouble() * 4 - 2; // ±2 sccm
  // 범위 제한
  _temperature = Math.Clamp(_temperature, 400, 550);
  _pressure = Math.Clamp(_pressure, 1.5, 3.5);
  _flowRate = Math.Clamp(_flowRate, 80, 120);
  var data = new SensorData
  {
  Timestamp = DateTime.Now, Temperature = _temperature, Pressure = _pressure, FlowRate = _flowRate
  };
  // 큐에 추가
  _dataQueue.Enqueue(data);
  while (_dataQueue.Count > 1000)
  {
  _dataQueue.TryDequeue(out _);
  }
  // 이벤트 발생
  DataReceived?.Invoke(this, data);
  // 알람 체크
  CheckAlarms(data);
  await Task.Delay(100, ct); // 100ms 주기
  }
  }
  private void CheckAlarms(SensorData data)
  {
  if (data.Temperature > 500)
  {
  AlarmRaised?.Invoke(this, new Alarm
  {
  Timestamp = DateTime.Now, Message = $"High Temperature: {data.Temperature: F1}°C", Level = AlarmLevel.Critical
  });
  }
  if (data.Pressure > 3.0)
  {
  AlarmRaised?.Invoke(this, new Alarm
  {
  Timestamp = DateTime.Now, Message = $"High Pressure: {data.Pressure: F2} Torr", Level = AlarmLevel.Warning
  });
  }
  if (data.FlowRate < 90 || data.FlowRate > 110)
  {
  AlarmRaised?.Invoke(this, new Alarm
  {
  Timestamp = DateTime.Now, Message = $"Flow Rate Out of Range: {data.FlowRate: F1} sccm", Level = AlarmLevel.Warning
  });
  }
  }
  public SensorData[] GetRecentData(int count)
  {
  return _dataQueue.ToArray().TakeLast(count).ToArray();
  }
  }
}
```
=== ViewModel: MainViewModel.cs
```csharp
using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;
using RealtimeHMI.Models;
using RealtimeHMI.Services;
namespace RealtimeHMI.ViewModels
{
  public class MainViewModel : INotifyPropertyChanged
  {
  private readonly SensorService _sensorService;
  private double _temperature;
  private double _pressure;
  private double _flowRate;
  private bool _isMonitoring;
  public ObservableCollection<Alarm> Alarms { get; } = new();
  public ObservableCollection<SensorData> RecentData { get; } = new();
  public double Temperature
  {
  get => _temperature;
  set { _temperature = value; OnPropertyChanged(); }
  }
  public double Pressure
  {
  get => _pressure;
  set { _pressure = value; OnPropertyChanged(); }
  }
  public double FlowRate
  {
  get => _flowRate;
  set { _flowRate = value; OnPropertyChanged(); }
  }
  public bool IsMonitoring
  {
  get => _isMonitoring;
  set
  {
  _isMonitoring = value;
  OnPropertyChanged();
  CommandManager.InvalidateRequerySuggested();
  }
  }
  public ICommand StartCommand { get; }
  public ICommand StopCommand { get; }
  public ICommand ClearAlarmsCommand { get; }
  public MainViewModel()
  {
  _sensorService = new SensorService();
  _sensorService.DataReceived += OnDataReceived;
  _sensorService.AlarmRaised += OnAlarmRaised;
  StartCommand = new RelayCommand(_ => Start(), _ => !IsMonitoring);
  StopCommand = new RelayCommand(_ => Stop(), _ => IsMonitoring);
  ClearAlarmsCommand = new RelayCommand(_ => Alarms.Clear());
  }
  private async void Start()
  {
  IsMonitoring = true;
  await _sensorService.StartAsync();
  }
  private void Stop()
  {
  _sensorService.Stop();
  IsMonitoring = false;
  }
  private void OnDataReceived(object? sender, SensorData data)
  {
  // UI 스레드에서 업데이트
  Application.Current.Dispatcher.Invoke(() =>
  {
  Temperature = data.Temperature;
  Pressure = data.Pressure;
  FlowRate = data.FlowRate;
  RecentData.Add(data);
  if (RecentData.Count > 100)
  {
  RecentData.RemoveAt(0);
  }
  });
  }
  private void OnAlarmRaised(object? sender, Alarm alarm)
  {
  Application.Current.Dispatcher.Invoke(() =>
  {
  Alarms.Insert(0, alarm); // 최신 알람을 위에
  if (Alarms.Count > 50)
  {
  Alarms.RemoveAt(Alarms.Count - 1);
  }
  });
  }
  public event PropertyChangedEventHandler? PropertyChanged;
  protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
  {
  PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
  }
  }
  // RelayCommand 구현
  public class RelayCommand : ICommand
  {
  private readonly Action<object?> _execute;
  private readonly Predicate<object?>? _canExecute;
  public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null)
  {
  _execute = execute;
  _canExecute = canExecute;
  }
  public event EventHandler? CanExecuteChanged
  {
  add => CommandManager.RequerySuggested += value;
  remove => CommandManager.RequerySuggested -= value;
  }
  public bool CanExecute(object? parameter) => _canExecute?.Invoke(parameter) ?? true;
  public void Execute(object? parameter) => _execute(parameter);
  }
}
```
=== View: MainWindow.xaml
```xml
<Window x: Class="RealtimeHMI.MainWindow"
  xmlns="http: //schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns: x="http: //schemas.microsoft.com/winfx/2006/xaml"
  xmlns: vm="clr-namespace: RealtimeHMI.ViewModels"
  Title="Realtime Sensor Monitoring" Height="600" Width="900">
  \<Window.DataContext>
  \<vm: MainViewModel/>
  \</Window.DataContext>
  \<Grid Margin="10">
  \<Grid.RowDefinitions>
  \<RowDefinition Height="Auto"/>
  \<RowDefinition Height="*"/>
  \<RowDefinition Height="200"/>
  \</Grid.RowDefinitions>
  \<!-- Header -->
  \<Border Grid.Row="0" Background="#2C3E50" Padding="15" Margin="0, 0, 0, 10">
  \<StackPanel Orientation="Horizontal">
  \<TextBlock Text="Realtime Sensor Monitoring"
  FontSize="24" Foreground="White" FontWeight="Bold"/>
  \<Button Content="Start" Command="{Binding StartCommand}"
  Width="100" Height="30" Margin="20, 0, 5, 0"/>
  \<Button Content="Stop" Command="{Binding StopCommand}"
  Width="100" Height="30" Margin="5, 0"/>
  \</StackPanel>
  \</Border>
  \<!-- Sensor Values -->
  \<Grid Grid.Row="1">
  \<Grid.ColumnDefinitions>
  \<ColumnDefinition Width="2*"/>
  \<ColumnDefinition Width="*"/>
  \</Grid.ColumnDefinitions>
  \<!-- Main Display -->
  \<Border Grid.Column="0" BorderBrush="Gray" BorderThickness="1" Padding="20">
  \<UniformGrid Rows="3">
  \<!-- Temperature -->
  \<Border BorderBrush="LightGray" BorderThickness="1" Margin="5" Padding="10">
  \<StackPanel>
  \<TextBlock Text="Temperature" FontSize="16" FontWeight="Bold"/>
  \<TextBlock FontSize="36" Margin="0, 10">
  \<Run Text="{Binding Temperature, StringFormat='{}{0: F1}'}"/>
  \<Run Text=" °C" FontSize="20"/>
  \</TextBlock>
  \</StackPanel>
  \</Border>
  \<!-- Pressure -->
  \<Border BorderBrush="LightGray" BorderThickness="1" Margin="5" Padding="10">
  \<StackPanel>
  \<TextBlock Text="Pressure" FontSize="16" FontWeight="Bold"/>
  \<TextBlock FontSize="36" Margin="0, 10">
  \<Run Text="{Binding Pressure, StringFormat='{}{0: F2}'}"/>
  \<Run Text=" Torr" FontSize="20"/>
  \</TextBlock>
  \</StackPanel>
  \</Border>
  \<!-- Flow Rate -->
  \<Border BorderBrush="LightGray" BorderThickness="1" Margin="5" Padding="10">
  \<StackPanel>
  \<TextBlock Text="Flow Rate" FontSize="16" FontWeight="Bold"/>
  \<TextBlock FontSize="36" Margin="0, 10">
  \<Run Text="{Binding FlowRate, StringFormat='{}{0: F1}'}"/>
  \<Run Text=" sccm" FontSize="20"/>
  \</TextBlock>
  \</StackPanel>
  \</Border>
  \</UniformGrid>
  \</Border>
  \<!-- Alarms -->
  \<Border Grid.Column="1" BorderBrush="Gray" BorderThickness="1" Padding="10">
  \<DockPanel>
  \<StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0, 0, 0, 10">
  \<TextBlock Text="Alarms" FontSize="16" FontWeight="Bold"/>
  \<Button Content="Clear" Command="{Binding ClearAlarmsCommand}"
  Width="60" Height="25" Margin="10, 0, 0, 0"/>
  \</StackPanel>
  \<ListBox ItemsSource="{Binding Alarms}">
  \<ListBox.ItemTemplate>
  \<DataTemplate>
  \<Border Padding="5" Margin="2" Background="#FFF9E6">
  \<StackPanel>
  \<TextBlock Text="{Binding Message}" FontWeight="Bold"/>
  \<TextBlock Text="{Binding Timestamp, StringFormat='HH: mm: ss'}"
  FontSize="10" Foreground="Gray"/>
  \</StackPanel>
  \</Border>
  \</DataTemplate>
  \</ListBox.ItemTemplate>
  \</ListBox>
  \</DockPanel>
  \</Border>
  \</Grid>
  \<!-- Recent Data -->
  \<Border Grid.Row="2" BorderBrush="Gray" BorderThickness="1" Padding="10" Margin="0, 10, 0, 0">
  \<DockPanel>
  \<TextBlock DockPanel.Dock="Top" Text="Recent Data" FontSize="14" FontWeight="Bold" Margin="0, 0, 0, 5"/>
  \<DataGrid ItemsSource="{Binding RecentData}" AutoGenerateColumns="False" IsReadOnly="True">
  \<DataGrid.Columns>
  \<DataGridTextColumn Header="Time" Binding="{Binding Timestamp, StringFormat='HH: mm: ss'}" Width="80"/>
  \<DataGridTextColumn Header="Temperature (°C)" Binding="{Binding Temperature, StringFormat='F1'}" Width="*"/>
  \<DataGridTextColumn Header="Pressure (Torr)" Binding="{Binding Pressure, StringFormat='F2'}" Width="*"/>
  \<DataGridTextColumn Header="Flow Rate (sccm)" Binding="{Binding FlowRate, StringFormat='F1'}" Width="*"/>
  \</DataGrid.Columns>
  \</DataGrid>
  \</DockPanel>
  \</Border>
  \</Grid>
</Window>
```
*실행 방법*:
1. Visual Studio 2022에서 새 WPF App (.NET 8.0) 프로젝트 생성
2. 프로젝트 구조: Models/, Services/, ViewModels/, Views/
3. 위 코드를 각 파일에 복사
4. F5로 실행
5. "Start" 버튼 클릭하여 모니터링 시작
*기능*:
- 3개 센서 값 실시간 업데이트 (100ms 주기)
- Thread-safe 데이터 수집
- 알람 자동 감지 및 표시
- 최근 100개 데이터 그리드 표시
- Dispatcher를 통한 안전한 UI 업데이트
== MCQ (Multiple Choice Questions)
=== 문제 1: async/await 개념 (기초)
async/await의 주요 장점은?
A. 코드 실행 속도 향상 \
B. UI 스레드 블로킹 방지 \
C. 메모리 사용량 감소 \
D. 컴파일 시간 단축
*정답: B*
*해설*: async/await는 비동기 작업이 완료될 때까지 UI 스레드를 블로킹하지 않고 반환하여, UI 응답성을 유지한다.
---
=== 문제 2: Thread Pool (기초)
.NET Thread Pool의 주요 목적은?
A. 스레드를 무한정 생성 \
B. 스레드를 재사용하여 성능 향상 \
C. UI 스레드 분리 \
D. 메모리 자동 해제
*정답: B*
*해설*: Thread Pool은 스레드 생성/파괴 비용을 줄이기 위해 스레드를 재사용한다.
---
=== 문제 3: Producer-Consumer (중급)
Channel<T>의 BoundedChannelFullMode.DropOldest는 무엇을 의미하는가?
A. 버퍼가 가득 차면 새 데이터를 버림 \
B. 버퍼가 가득 차면 오래된 데이터를 삭제하고 새 데이터 추가 \
C. 버퍼가 가득 차면 예외 발생 \
D. 버퍼 크기를 자동으로 확장
*정답: B*
*해설*: DropOldest는 큐가 가득 찰 때 가장 오래된 데이터를 삭제하고 새 데이터를 추가한다. 실시간 모니터링에서 최신 데이터가 더 중요할 때 유용하다.
---
=== 문제 4: ConcurrentQueue (중급)
ConcurrentQueue<T>가 일반 Queue<T>보다 유리한 점은?
A. 더 빠른 성능 \
B. Thread-safe 보장 \
C. 메모리 효율성 \
D. 간단한 API
*정답: B*
*해설*: ConcurrentQueue<T>는 여러 스레드에서 동시에 접근해도 안전하다. 내부적으로 lock-free 알고리즘을 사용한다.
---
=== 문제 5: Dispatcher (중급)
WPF에서 백그라운드 스레드에서 UI를 업데이트하려면?
A. 직접 속성 변경 \
B. Dispatcher.Invoke 사용 \
C. Task.Run 사용 \
D. Thread.Sleep 사용
*정답: B*
*해설*: WPF UI는 단일 스레드(UI 스레드)에서만 접근 가능하다. 백그라운드 스레드에서는 Dispatcher.Invoke를 통해 UI 스레드에 작업을 마샬링해야 한다.
---
=== 문제 6: 코드 분석 - async/await (고급)
다음 코드의 문제점은?
```csharp
public async Task ProcessDataAsync()
{
  var data = await GetDataAsync();
  Thread.Sleep(1000); // 1초 대기
  UpdateUI(data);
}
```
A. await 사용 오류 \
B. Thread.Sleep이 UI 스레드를 블로킹 \
C. 메모리 누수 \
D. 문제 없음
*정답: B*
*해설*: Thread.Sleep은 현재 스레드를 블로킹한다. async 메서드에서는 `await Task.Delay(1000)`을 사용해야 UI 스레드를 블로킹하지 않는다.
---
=== 문제 7: Singleton Pattern (고급)
다음 Singleton이 Thread-safe한 이유는?
```csharp
private static readonly Lazy<DataManager> _instance =
  new Lazy<DataManager>(() => new DataManager());
```
A. static 키워드 사용 \
B. Lazy<T>가 내부적으로 lock 사용 \
C. readonly 키워드 사용 \
D. 람다 표현식 사용
*정답: B*
*해설*: Lazy<T>는 기본적으로 LazyThreadSafetyMode.ExecutionAndPublication을 사용하여 thread-safe하다.
---
=== 문제 8: C\# vs Python GIL (고급)
Python GIL과 비교할 때 C\#의 장점은?
A. 간단한 문법 \
B. 모든 CPU 코어를 완전히 활용 가능 \
C. 메모리 사용량 적음 \
D. 더 빠른 컴파일 속도
*정답: B*
*해설*: Python GIL은 CPU-bound 작업 시 단일 코어만 사용하지만, C\#은 진정한 병렬 처리가 가능하여 모든 코어를 활용할 수 있다.
---
=== 문제 9: Channel vs Queue (고급)
Channel<T>이 ConcurrentQueue<T>보다 유리한 점은?
A. 더 빠른 성능 \
B. async/await 네이티브 지원 \
C. 더 적은 메모리 사용 \
D. 간단한 API
*정답: B*
*해설*: Channel<T>는 `await foreach`와 `WriteAsync` 등 async/await를 네이티브로 지원하여 비동기 프로그래밍에 더 적합하다.
---
=== 문제 10: 실시간 데이터 처리 (도전)
반도체 HMI에서 실시간 데이터 처리 시 가장 중요한 원칙은?
A. 모든 데이터를 저장 \
B. UI 스레드에서 데이터 처리 \
C. 백그라운드 스레드에서 데이터 수집, Dispatcher로 UI 업데이트 \
D. 동기 방식으로 처리
*정답: C*
*해설*: 실시간 데이터 수집은 백그라운드 스레드에서 수행하고, UI 업데이트만 Dispatcher를 통해 UI 스레드에서 실행해야 응답성과 성능을 모두 보장할 수 있다.
== 추가 학습 자료
=== 공식 문서
- *Asynchronous programming*: https: //learn.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/async/
- *Task Parallel Library*: https: //learn.microsoft.com/en-us/dotnet/standard/parallel-programming/task-parallel-library-tpl
- *Threading in C\#*: https: //learn.microsoft.com/en-us/dotnet/standard/threading/
=== 참고 서적
- "Concurrency in C\# Cookbook" by Stephen Cleary
- "C\# 11 and .NET 7" by Mark J. Price (Chapter 12: Multitasking)
- "Pro Asynchronous Programming with .NET" by Richard Blewett
== 요약
이번 챕터에서는 C\# 실시간 데이터 처리를 학습했다: *이론 (Theory): *
- C\# 동시성 모델의 역사: Thread → Task → async/await
- .NET Thread Pool 동작 원리
- C\# vs Python GIL 비교: 진정한 병렬 처리
- 반도체 산업 데이터 처리 요구사항 (100, 000 points/sec)
*응용 (Application): *
- Producer-Consumer Pattern (Channel<T> 사용)
- Thread-safe Singleton Pattern (Lazy<T>)
- Observable Pattern (IObservable<T> 직접 구현)
- 완전한 실행 가능한 센서 모니터링 시스템
*성찰 (Reflections): *
- MCQ 10문제: async/await, Thread Pool, 디자인 패턴
*핵심 포인트: *
1. async/await는 UI 스레드 블로킹을 방지하여 응답성 보장
2. Thread Pool은 스레드 재사용으로 성능 최적화
3. ConcurrentQueue, Channel 등 Thread-safe 컬렉션 필수
4. Dispatcher로 백그라운드 스레드에서 안전하게 UI 업데이트
다음 챕터에서는 C\# 고급 UI 컨트롤과 커스텀 컨트롤 개발을 학습한다.
#pagebreak()