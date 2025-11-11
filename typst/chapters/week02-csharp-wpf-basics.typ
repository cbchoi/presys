
= Week 2: C\# WPF 기초 및 반도체 HMI 프로젝트 구조
== 학습 목표
본 챕터에서는 다음을 학습한다: + C\# 11과.NET 8의 최신 기능 이해
+ WPF 아키텍처와 XAML 기초
+ MVVM 패턴을 활용한 HMI 설계
+ 반도체 장비 모니터링 UI 프로토타입 개발
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *객체지향 프로그래밍 기초*: 클래스, 상속, 인터페이스, 다형성
- *이벤트 기반 프로그래밍*: 이벤트, 델리게이트, 콜백 개념
- *XML 기초*: XML 문법 및 구조 (XAML 이해를 위해)
- *개발 환경*: Visual Studio 2022 이상 설치
- *권장사항*: Week 1 HCI 이론 학습 완료
== C\# 언어의 특징과 역사
=== C\# 언어의 탄생
C\#(C Sharp)은 Microsoft의 Anders Hejlsberg가 설계한 객체지향 프로그래밍 언어로, 2000년에 처음 발표되었다. Java의 영향을 받았지만, .NET Framework와 긴밀히 통합되어 Windows 플랫폼 개발에 최적화되었다.
*주요 이정표: *
- *2000년*: C\# 1.0 발표 (.NET Framework 1.0과 함께)
- *2005년*: C\# 2.0 - 제네릭(Generics) 도입
- *2007년*: C\# 3.0 - LINQ, 람다 표현식 추가
- *2010년*: C\# 4.0 - dynamic 타입 도입
- *2012년*: C\# 5.0 - async/await 도입 (비동기 프로그래밍 혁신)
- *2015년*: C\# 6.0 - Roslyn 컴파일러
- *2020년*: C\# 9.0 - 레코드(Records) 타입
- *2022년*: C\# 11.0 - Raw String Literals, Required Members
- *2023년*: C\# 12.0 - Primary Constructors
=== C\# 언어의 핵심 특징
==== 1. 타입 안전성 (Type Safety)
C\#은 강타입 언어로, 컴파일 타임에 타입 오류를 발견한다: ```csharp
// 컴파일 오류 발생
int temperature = "450"; // ❌ string을 int에 할당 불가
// 올바른 방법
int temperature = 450; // ✓
string tempStr = "450";
int temperature = int.Parse(tempStr); // ✓ 명시적 변환
```
*장점*:
- 실행 전 오류 발견 (런타임 크래시 감소)
- IDE의 자동완성 및 리팩토링 지원
- 성능 최적화 (컴파일러가 최적화 가능)
==== 2. 가비지 컬렉션 (Garbage Collection)
.NET의 자동 메모리 관리 시스템: ```csharp
// C#: 메모리 자동 해제
void ProcessData()
{
    var data = new byte[1000000];  // 1MB 할당
    // 사용...
}  // 자동으로 메모리 해제 (GC가 관리)
// C++: 수동 메모리 관리 필요
// void ProcessData() {
//     byte* data = new byte[1000000];
//     // 사용...
//     delete[] data;  // 수동으로 해제 필요
// }
```
*GC 세대 (Generations): *
- Gen 0: 단기 객체 (자주 수집)
- Gen 1: 중기 객체 (중간 빈도)
- Gen 2: 장기 객체 (드물게 수집)
==== 3. LINQ (Language Integrated Query)
데이터 질의를 언어 수준에서 지원: ```csharp
// 센서 데이터 필터링
var highTemp = sensorData
  .Where(s => s.Temperature > 400)
  .OrderBy(s => s.Timestamp)
  .Select(s => new { s.Id, s.Temperature });
// SQL과 유사한 문법도 지원
var highTemp = from s in sensorData
  where s.Temperature > 400
  orderby s.Timestamp
  select new { s.Id, s.Temperature };
```
==== 4. 람다 표현식과 함수형 프로그래밍
```csharp
// 간결한 함수 정의
Func<double, double> toCelsius = f => (f - 32) * 5 / 9;
// 이벤트 핸들러
button.Click += (sender, e) => {
  Temperature += 10;
};
// LINQ와 결합
var avg = temperatures.Average(t => t.Value);
```
== C\# 타입 시스템 심화
C\#의 타입 시스템은 안전성과 성능을 동시에 보장하기 위해 설계되었다. 반도체 HMI에서는 실시간 데이터 처리와 메모리 효율성이 중요하므로, 타입 시스템의 이해가 필수적이다.
=== Value Type vs Reference Type
C\#의 모든 타입은 Value Type 또는 Reference Type으로 분류된다.
*Value Type (값 타입): *
- 메모리 배치: 스택 (Stack)에 직접 저장
- 대표 타입: `int`, `double`, `struct`, `enum`
- 복사 방식: 값 전체를 복사 (Deep Copy)
- GC 대상: 아니오 (스택에서 자동 해제)
*Reference Type (참조 타입): *
- 메모리 배치: 힙 (Heap)에 저장, 스택에는 참조만 저장
- 대표 타입: `class`, `string`, `array`, `delegate`
- 복사 방식: 참조만 복사 (Shallow Copy)
- GC 대상: 예 (가비지 컬렉터가 관리)
```csharp
// Value Type 예제
struct SensorReading // struct는 Value Type
{
  public double Temperature;
  public DateTime Timestamp;
}
SensorReading r1 = new SensorReading { Temperature = 300, Timestamp = DateTime.Now };
SensorReading r2 = r1; // 값 전체가 복사됨
r2.Temperature = 400;
Console.WriteLine(r1.Temperature); // 300 (r1은 변경 안됨)
// Reference Type 예제
class SensorData // class는 Reference Type
{
  public double Temperature { get; set; }
  public DateTime Timestamp { get; set; }
}
SensorData d1 = new SensorData { Temperature = 300, Timestamp = DateTime.Now };
SensorData d2 = d1; // 참조만 복사됨
d2.Temperature = 400;
Console.WriteLine(d1.Temperature); // 400 (같은 객체를 가리킴)
```
*메모리 레이아웃: *
```
Stack (Value Type) Heap (Reference Type)
┌─────────────┐ ┌─────────────────────┐
│ r1: │ │ d1 객체: │
│ Temp: 300 │  │  Temperature: 400 │
│ Time: ... │  ┌─────>│ Timestamp: ... │
├─────────────┤ │  └─────────────────────┘
│ r2: │ │
│ Temp: 400 │  │
│ Time: ... │  │
├─────────────┤ │
│ d1: 0x1234 │─────┘ (힙 주소를 저장)
├─────────────┤ │
│ d2: 0x1234 │─────┘ (같은 주소)
└─────────────┘
```
*성능 영향 (반도체 HMI 관점): *
- 센서 데이터 1000개 처리 시: - Value Type: 스택 할당/해제 ~1μs (매우 빠름)
  - Reference Type: 힙 할당 ~10μs + GC 오버헤드
- 실시간 데이터 스트리밍: Value Type 선호 (GC Pause 최소화)
- 대용량 버퍼: Reference Type 선호 (스택 오버플로 방지)
=== Boxing과 Unboxing
Value Type을 Reference Type으로 변환하는 과정을 Boxing, 그 반대를 Unboxing이라 한다.
```csharp
// Boxing: Value Type → Reference Type
int temperature = 300;
object boxed = temperature; // int가 object로 boxing
// 내부 동작: 힙에 새 객체 할당 → 값 복사 → 참조 반환
// Unboxing: Reference Type → Value Type
int unboxed = (int)boxed; // object에서 int로 unboxing
// 내부 동작: 타입 검사 → 값 복사
// 성능 문제 예시
ArrayList list = new ArrayList();
for (int i = 0; i < 1000; i++)
{
  list.Add(i); // 1000번 Boxing 발생! (느림)
}
// 해결: 제네릭 사용 (Boxing 없음)
List<int> genericList = new List<int>();
for (int i = 0; i < 1000; i++)
{
  genericList.Add(i); // Boxing 없음 (빠름)
}
```
*성능 벤치마크: *
- Boxing 1회: ~20ns
- 1000개 센서 값 boxing: ~20μs + GC 압력
- 제네릭 사용 시: Boxing 0회, GC 압력 없음
*반도체 HMI 베스트 프랙티스: *
```csharp
// ❌ 나쁜 예: ArrayList 사용 (Boxing 발생)
ArrayList sensorValues = new ArrayList();
sensorValues.Add(300.5); // double → object (Boxing)
// ✓ 좋은 예: 제네릭 컬렉션 (Boxing 없음)
List<double> sensorValues = new List<double>();
sensorValues.Add(300.5); // Boxing 없음
```
=== 제네릭의 Reification
C\#의 제네릭은 Java와 달리 Reification을 지원한다. 즉, 런타임에도 타입 정보가 보존된다.
*C\# Reification (타입 보존): *
```csharp
// C#: 런타임에 T의 실제 타입을 알 수 있음
List<int> intList = new List<int>();
Console.WriteLine(intList.GetType()); // System.Collections.Generic.List`1[System.Int32]
// 타입 검사 가능
if (intList is List<int>) { /* ... */ }
// 리플렉션 가능
Type elementType = typeof(List<int>).GetGenericArguments()[0];
Console.WriteLine(elementType); // System.Int32
```
*Java Type Erasure (타입 소거) - 비교: *
```java
// Java: 런타임에 타입 정보 소실
List<Integer> intList = new ArrayList<>();
System.out.println(intList.getClass()); // class java.util.ArrayList (제네릭 정보 없음)
// 타입 검사 불가능
if (intList instanceof List<Integer>) { /* 컴파일 에러 */ }
```
*성능 및 메모리 영향: *
#figure(table(columns: (auto, auto, auto), align: left, [*항목*], [*C\# (Reification)*], [*Java (Type Erasure)*], [IL/바이트코드], [타입별 분리], [Object로 통합], [JIT 최적화], [타입별 최적화], [캐스팅 오버헤드], [메모리], [타입별 메타데이터], [메타데이터 적음], [런타임 타입 검사], [가능], [불가능], ), caption: "C# vs Java 제네릭 비교")
*반도체 HMI 활용 예: *
```csharp
// 런타임에 센서 타입 동적 처리
public void ProcessSensor<T>(List<T> readings) where T : struct
{
  Type type = typeof(T);
  if (type == typeof(double))
  {
  // double 특화 처리 (Boxing 없음)
  var values = readings as List<double>;
  double avg = values.Average();
  }
  else if (type == typeof(int))
  {
  // int 특화 처리
  var values = readings as List<int>;
  int sum = values.Sum();
  }
}
```
=== Nullable Reference Types (C\# 8.0+)
C\# 8.0부터 참조 타입도 null 가능 여부를 명시할 수 있다.
```csharp
// C# 8.0 이전: 모든 참조 타입이 null 가능
string name = null; // OK (컴파일러가 경고 안함)
// C# 8.0 이후: Nullable Reference Types 활성화 (#nullable enable)
#nullable enable
string name = null; // ⚠️ 경고: null을 non-nullable 참조에 할당
string? name = null; // ✓ OK (명시적으로 nullable)
void ProcessSensor(SensorData data)
{
  // data는 non-nullable이므로 null 체크 불필요
  Console.WriteLine(data.Temperature); // ✓ 안전
}
void ProcessOptionalSensor(SensorData? data)
{
  // data는 nullable이므로 null 체크 필요
  if (data != null)
  {
  Console.WriteLine(data.Temperature); // ✓ null 체크 후 안전
  }
  Console.WriteLine(data.Temperature); // ⚠️ 경고: null 가능성
}
```
*설계 철학: *
- "Billion-dollar mistake" (Tony Hoare, 2009) 해결
- NullReferenceException 런타임 오류를 컴파일 타임 경고로 전환
- 코드 의도 명확화 (null 허용 여부를 타입에 표현)
*반도체 HMI 적용: *
```csharp
// Critical 센서는 절대 null이면 안됨
public class EquipmentController
{
  private SensorData _criticalSensor; // non-nullable (null 불가)
  private SensorData? _optionalSensor; // nullable (null 가능)
  public EquipmentController(SensorData criticalSensor)
  {
  _criticalSensor = criticalSensor ?? throw new ArgumentNullException();
  }
  public void UpdateOptional(SensorData? sensor)
  {
  _optionalSensor = sensor; // null 허용
  }
}
```
== 가비지 컬렉션 이론 심화
=== Mark-and-Sweep 알고리즘
.NET의 GC는 Mark-and-Sweep 알고리즘을 기반으로 한다.
*동작 원리: *
1. **Mark Phase (표시 단계)**: - GC 루트에서 시작 (스택, 정적 변수, CPU 레지스터)
   - 도달 가능한 모든 객체를 재귀적으로 표시
   - 표시되지 않은 객체 = 가비지
2. **Sweep Phase (수거 단계)**: - 표시되지 않은 객체 메모리 해제
   - 메모리 조각 모음 (Compaction) 수행
```
GC 전:
Heap: [A] [B] [C (garbage)] [D] [E (garbage)] [F]
  ↑  ↑  ↑  ↑
  루트에서 도달 가능 도달 불가 도달 불가
Mark Phase:
[A*] [B*] [C] [D*] [E] [F*] (* = 표시됨)
Sweep Phase:
[A] [B] [_] [D] [_] [F] (_ = 해제됨)
Compaction:
[A] [B] [D] [F] [___free___]
```
=== Generational Hypothesis
.NET GC는 "대부분의 객체는 짧은 수명을 가진다"는 가설에 기반한다.
*3세대 구조: *
- **Gen 0**: 신규 객체 (수명 < 1초)
  - 크기: ~256KB - 4MB
  - 수집 빈도: 매우 자주 (ms 단위)
  - 생존률: ~10%
- **Gen 1**: 중기 객체 (1초 < 수명 < 10초)
  - 크기: Gen 0과 유사
  - 수집 빈도: 중간
  - 버퍼 역할 (Gen 0 → Gen 2 전환 완화)
- **Gen 2**: 장기 객체 (수명 > 10초)
  - 크기: 수 GB 가능
  - 수집 빈도: 드물게 (초 단위)
  - 생존률: ~90%
```csharp
// 객체 생성 및 세대 확인
var tempData = new byte[100]; // Gen 0에 할당
Console.WriteLine(GC.GetGeneration(tempData)); // 0
GC.Collect(); // 강제 GC (실무에서는 피해야 함)
Console.WriteLine(GC.GetGeneration(tempData)); // 1 (승격됨)
```
*통계 (Microsoft 벤치마크): *
- Gen 0 수집: ~1ms
- Gen 1 수집: ~10ms
- Gen 2 수집 (Full GC): ~100ms - 1초
*반도체 HMI 영향: *
- 실시간 센서 데이터: Gen 0에서 빠르게 수집 (OK)
- Full GC Pause: 100ms → 알람 응답 850ms 목표 위반 가능
- 해결책: GC 튜닝, 객체 풀링, Span<T> 사용
=== Large Object Heap (LOH)
85KB 이상의 대형 객체는 별도의 LOH에 할당된다.
*특징: *
- Compaction 미수행 (조각화 발생 가능)
- Gen 2로 즉시 승격
- 수집 빈도: Gen 2와 동일 (드묾)
```csharp
// 84KB: 일반 힙 (SOH - Small Object Heap)
byte[] small = new byte[84 * 1024]; // Gen 0
// 85KB: LOH
byte[] large = new byte[85 * 1024]; // LOH (즉시 Gen 2)
Console.WriteLine(GC.GetGeneration(large)); // 2
```
*조각화 문제: *
```
LOH 메모리:
[100KB used] [50KB free] [100KB used] [50KB free]
200KB 할당 요청 → 실패 (연속 공간 부족)
총 100KB free 공간이 있지만 조각화로 인해 할당 불가
```
*해결책: *
```csharp
// ❌ 나쁜 예: 반복적으로 대형 배열 생성
for (int i = 0; i < 1000; i++)
{
  byte[] buffer = new byte[1024 * 1024]; // 1MB, LOH 조각화 유발
  ProcessData(buffer);
}
// ✓ 좋은 예: ArrayPool 사용 (객체 재사용)
var pool = ArrayPool<byte>.Shared;
for (int i = 0; i < 1000; i++)
{
  byte[] buffer = pool.Rent(1024 * 1024);
  ProcessData(buffer);
  pool.Return(buffer); // 재사용
}
```
=== GC Pause와 실시간 시스템
*GC Pause 종류: *
1. **Concurrent GC** (기본값): - 애플리케이션 스레드와 병행 실행
   - Pause: ~1-10ms
   - 처리량: 낮음
2. **Background GC** (Server GC): - Gen 2 수집을 백그라운드에서 수행
   - Pause: ~1-50ms
   - 처리량: 높음
*반도체 HMI 설정: *
```xml
<!-- app.config 또는 .csproj -->
<PropertyGroup>
  <!-- Server GC: 처리량 우선 (다중 CPU 활용) -->
  <ServerGarbageCollection>true</ServerGarbageCollection>
  <!-- Concurrent GC: 낮은 지연 시간 -->
  <ConcurrentGarbageCollection>true</ConcurrentGarbageCollection>
</PropertyGroup>
```
*Workstation GC vs Server GC: *
#figure(table(columns: (auto, auto, auto), align: left, [*특징*], [*Workstation GC*], [*Server GC*], [힙 수], [1개], [CPU 코어 수], [GC 스레드], [1개], [코어 당 1개], [Pause 시간], [짧음 (1-10ms)], [중간 (10-50ms)], [처리량], [낮음], [높음], [메모리 사용], [적음], [많음], [용도], [UI 애플리케이션], [서버 / 데이터 처리], ), caption: "Workstation GC vs Server GC 비교")
*반도체 HMI 권장 설정: *
- 실시간 센서 표시: Workstation GC (낮은 지연)
- 대용량 데이터 분석: Server GC (높은 처리량)
=== WPF의 역사와 발전
==== WPF 탄생 배경
*Windows Forms의 한계: *
- GDI/GDI+ 기반 (래스터 그래픽, 확대 시 품질 저하)
- 디자이너와 개발자 협업 어려움
- 복잡한 UI 구현 시 성능 문제
- 하드웨어 가속 미지원
*WPF의 혁신 (2006): *
- DirectX 기반 하드웨어 가속
- 벡터 그래픽 (해상도 독립적)
- XAML을 통한 UI/로직 분리
- 데이터 바인딩 및 스타일링 강화
==== WPF vs 최신 대안
#figure(table(columns: (auto, auto, auto, auto), align: left, [*특징*], [*WPF*], [*WinUI 3*], [*Avalonia UI*], [출시연도], [2006], [2021], [2016], [플랫폼], [Windows only], [Windows only], [크로스 플랫폼], [렌더링], [DirectX], [DirectX], [Skia], [XAML], [지원], [지원], [지원], [성숙도], [매우 높음], [성장 중], [높음], ), caption: "WPF와 최신 UI 프레임워크 비교")
=== 반도체 산업에서의 C\# / WPF 채택
==== 주요 장비사 사용 현황
*Applied Materials*:
- 일부 차세대 장비에서 WPF 채택
- 기존 장비는 C++ / Qt 유지
*Lam Research*:
- Flex 플랫폼에서 WPF 활용
- .NET 기반 플러그인 아키텍처
*KLA Corporation*:
- 검사 장비 UI에 WPF 사용
- 데이터 시각화에 강점
==== 채택 이유
*장점*:
- Microsoft 생태계 통합 (Visual Studio, Azure)
- 풍부한 UI 컴포넌트 라이브러리
- 강력한 데이터 바인딩 (센서 데이터 표시에 유리)
- XAML 기반 디자이너 협업
*단점*:
- Windows 전용 (Linux 미지원)
- 초기 학습 곡선
- 대규모 프로젝트에서 성능 튜닝 필요
==== 산업 동향
*현재 (2024): *
- 신규 프로젝트는 WPF와 WinUI 3 병행
- 웹 기반 HMI (Blazor, React)로의 전환 시도
- 모바일 모니터링 요구 증가 (Xamarin, MAUI)
*미래 전망: *
- 하이브리드 접근 (Desktop WPF + Web Dashboard)
- AI 기반 UI 자동 생성
- AR/VR HMI 통합
== C\# 11 주요 기능
=== Raw String Literals
```csharp
string json = """
{
 "equipmentId": "CVD-01", "temperature": 450.5, "pressure": 2.5
}
""";
```
=== Required Members
```csharp
public class Equipment
{
 public required string Id { get; init; }
 public required string Name { get; init; }
 public double Temperature { get; set; }
}
```
=== Pattern Matching 개선
```csharp
public string GetStatus(Equipment eq) => eq switch
{
 { Temperature: > 500 } => "Too Hot", { Temperature: \< 200 } => "Too Cold", _ => "Normal"
};
```
== WPF 아키텍처
=== WPF 구조
#figure(table(columns: (auto, 1fr), align: left, [*계층*], [*설명*], [Presentation Layer], [XAML UI 정의], [Business Logic], [ViewModel (MVVM)], [Data Access], [Model/Service], [Hardware], [장비 통신], ), caption: "WPF 아키텍처 계층")
=== XAML 기초
XAML(eXtensible Application Markup Language)은 WPF UI를 선언적으로 정의하는 언어이다.
```xml
<Window x: Class="HMI.MainWindow"
 xmlns="http: //schemas.microsoft.com/winfx/2006/xaml/presentation"
 Title="반도체 장비 HMI" Height="800" Width="1200">
 \<Grid>
 \<TextBlock Text="{Binding Temperature}"
 FontSize="24"/>
 \</Grid>
</Window>
```
== MVVM 패턴
=== MVVM 아키텍처 개요
MVVM(Model-View-ViewModel) 패턴은 John Gossman(Microsoft, 2005)이 WPF와 Silverlight를 위해 고안한 아키텍처 패턴이다. MVC 패턴의 변형으로, UI와 비즈니스 로직의 분리를 강화한다.
==== 핵심 구성요소
```
┌─────────────────────────┐
│ View (XAML) │
│ - UI 레이아웃 │
│ - 사용자 입력 수신 │
└──────────┬──────────────┘
  │ ↕ Data Binding /
  │  Property Changed
┌──────────┴──────────────┐
│ ViewModel (C#) │
│ - INotifyPropertyChanged│
│ - Command 처리 │
└──────────┬──────────────┘
  │ ↕ Read Data /
  │  Update Data
┌──────────┴──────────────┐
│ Model (C#) │
│ - 도메인 데이터 │
│ - 비즈니스 로직 │
└─────────────────────────┘
```
_그림: MVVM 아키텍처 패턴 (↕는 양방향 통신)_
*Model*:
- 역할: 도메인 데이터 + 비즈니스 로직
- 책임: 데이터 검증, 영속성 관리
- 특징: View와 ViewModel을 알지 못함 (독립성)
- 예: Equipment 클래스, SensorData 클래스
*View*:
- 역할: 시각적 표현 (XAML)
- 책임: UI 레이아웃, 사용자 입력 수신
- 특징: 코드-비하인드 최소화
- 예: MainWindow.xaml, EquipmentControl.xaml
*ViewModel*:
- 역할: View와 Model 중개
- 책임: 데이터 변환, Command 처리, INotifyPropertyChanged 구현
- 특징: View 독립적 (테스트 가능)
- 예: EquipmentViewModel, MainViewModel
==== 데이터 바인딩 메커니즘
WPF의 데이터 바인딩은 Dependency Property와 INotifyPropertyChanged를 통해 동작한다: 1. *ViewModel → View* (source to target): ```
   ViewModel.Property 변경
   → OnPropertyChanged("Property") 호출
   → PropertyChanged 이벤트 발생
   → Binding Engine이 이벤트 수신
   → Dependency Property 업데이트
   → UI 렌더링 갱신
   ```
2. *View → ViewModel* (target to source): ```
  사용자 입력 (예: TextBox 편집)
  → Dependency Property 변경
  → Binding Engine이 변경 감지
  → ViewModel.Property setter 호출
  → 비즈니스 로직 실행
   ```
3. *Binding Mode*: - `OneWay`: ViewModel → View만 (읽기 전용 데이터)
   - `TwoWay`: 양방향 (입력 가능 데이터)
   - `OneTime`: 초기값만 (정적 데이터)
   - `OneWayToSource`: View → ViewModel만 (드물게 사용)
==== INotifyPropertyChanged 내부 동작
```csharp
public interface INotifyPropertyChanged
{
  event PropertyChangedEventHandler PropertyChanged;
}
public delegate void PropertyChangedEventHandler(object sender, PropertyChangedEventArgs e);
```
동작 원리:
1. ViewModel이 INotifyPropertyChanged 구현
2. 바인딩 엔진이 PropertyChanged 이벤트에 핸들러 등록
3. 속성 변경 시 `OnPropertyChanged()` 호출
4. 등록된 모든 핸들러에 통지
5. 바인딩 엔진이 해당 UI 요소 갱신
성능 고려사항:
- PropertyChanged 이벤트는 UI 스레드에서 발생해야 함
- 대량 속성 변경 시 일괄 갱신 고려 (CollectionChanged 등)
- 불필요한 통지 방지 (값이 실제 변경될 때만)
=== INotifyPropertyChanged 구현
```csharp
public class EquipmentViewModel : INotifyPropertyChanged
{
 private double _temperature;
 public double Temperature
 {
 get => _temperature;
 set
 {
 _temperature = value;
 OnPropertyChanged();
 }
 }
 public event PropertyChangedEventHandler? PropertyChanged;
 protected void OnPropertyChanged([CallerMemberName] string? name = null)
 {
 PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
 }
}
```
== 반도체 HMI 프로젝트 구조
=== 프로젝트 구조
```
SemiconductorHMI/
├── Models/
│ ├── Equipment.cs
│ └── ProcessData.cs
├── ViewModels/
│ ├── MainViewModel.cs
│ └── EquipmentViewModel.cs
├── Views/
│ ├── MainWindow.xaml
│ └── EquipmentView.xaml
├── Services/
│ └── DataService.cs
└── App.xaml
```
=== 주요 클래스
*Equipment Model*:
```csharp
public record Equipment
{
 public required string Id { get; init; }
 public required string Name { get; init; }
 public EquipmentType Type { get; init; }
 public EquipmentStatus Status { get; set; }
}
```
== 데이터 바인딩
=== 단방향 바인딩
```xml
<TextBlock Text="{Binding Temperature, Mode=OneWay}"/>
```
=== 양방향 바인딩
```xml
<TextBox Text="{Binding SetPoint, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>
```
=== 컬렉션 바인딩
```xml
<ListBox ItemsSource="{Binding Equipments}">
 \<ListBox.ItemTemplate>
 \<DataTemplate>
 \<TextBlock Text="{Binding Name}"/>
 \</DataTemplate>
 \</ListBox.ItemTemplate>
</ListBox>
```
== 레이아웃 컨트롤
=== Grid
```xml
<Grid>
 \<Grid.RowDefinitions>
 \<RowDefinition Height="Auto"/>
 \<RowDefinition Height="*"/>
 \</Grid.RowDefinitions>
 \<Grid.ColumnDefinitions>
 \<ColumnDefinition Width="2*"/>
 \<ColumnDefinition Width="*"/>
 \</Grid.ColumnDefinitions>
</Grid>
```
=== StackPanel
```xml
<StackPanel Orientation="Vertical" Spacing="10">
 \<TextBlock Text="Temperature"/>
 \<TextBox/>
</StackPanel>
```
=== DockPanel
```xml
<DockPanel>
 \<Menu DockPanel.Dock="Top"/>
 \<StatusBar DockPanel.Dock="Bottom"/>
 \<Grid/>
</DockPanel>
```
== 커맨드 패턴
=== ICommand 구현
```csharp
public class RelayCommand : ICommand
{
 private readonly Action<object?> _execute;
 private readonly Predicate<object?>? _canExecute;
 public event EventHandler? CanExecuteChanged
 {
 add => CommandManager.RequerySuggested += value;
 remove => CommandManager.RequerySuggested -= value;
 }
 public bool CanExecute(object? parameter)
 => _canExecute?.Invoke(parameter) ?? true;
 public void Execute(object? parameter)
 => _execute(parameter);
}
```
=== ViewModel에서 사용
```csharp
public ICommand StartCommand { get; }
public MainViewModel()
{
 StartCommand = new RelayCommand(_ => Start(), _ => CanStart());
}
private void Start() { /* 시작 로직 */ }
private bool CanStart() => Status == EquipmentStatus.Ready;
```
== 실습: 반도체 장비 모니터링 UI
=== 요구사항
+ 장비 목록 표시
+ 실시간 온도/압력 모니터링
+ 알람 표시
+ 시작/정지 버튼
=== MainWindow.xaml
```xml
<Window x: Class="SemiconductorHMI.MainWindow"
 Title="Semiconductor Equipment HMI"
 Height="800" Width="1200">
 \<Grid>
 \<Grid.RowDefinitions>
 \<RowDefinition Height="Auto"/>
 \<RowDefinition Height="*"/>
 \<RowDefinition Height="Auto"/>
 \</Grid.RowDefinitions>
 \<!-- Header -->
 \<Border Grid.Row="0" Background="#2C3E50" Padding="15">
 \<TextBlock Text="Semiconductor Equipment HMI"
 FontSize="24" Foreground="White"/>
 \</Border>
 \<!-- Content -->
 \<Grid Grid.Row="1" Margin="10">
 \<Grid.ColumnDefinitions>
 \<ColumnDefinition Width="2*"/>
 \<ColumnDefinition Width="*"/>
 \</Grid.ColumnDefinitions>
 \<!-- 장비 모니터링 -->
 \<Border Grid.Column="0" BorderBrush="Gray"
 BorderThickness="1" Padding="10">
 \<StackPanel>
 \<TextBlock Text="CVD-01" FontSize="20"/>
 \<TextBlock Text="{Binding Temperature, StringFormat='Temperature: {0: F1}°C'}"/>
 \<TextBlock Text="{Binding Pressure, StringFormat='Pressure: {0: F2} Torr'}"/>
 \</StackPanel>
 \</Border>
 \<!-- 알람 -->
 \<Border Grid.Column="1" BorderBrush="Gray"
 BorderThickness="1" Padding="10">
 \<ListBox ItemsSource="{Binding Alarms}"/>
 \</Border>
 \</Grid>
 \<!-- Status Bar -->
 \<StatusBar Grid.Row="2">
 \<TextBlock Text="{Binding Status}"/>
 \</StatusBar>
 \</Grid>
</Window>
```
== 디자인 패턴 적용
=== Observer Pattern (관찰자 패턴)
MVVM의 핵심은 Observer Pattern이다. INotifyPropertyChanged가 바로 이 패턴의 구현이다.
==== 패턴 구조
```
┌─────────────┐ ┌─────────────┐
│ Subject │◄─────────│ Observer │
│ (ViewModel) │ Notify │  (View) │
└─────────────┘ └─────────────┘
  │
  │ PropertyChanged
  ▼
  ┌─────────┐
  │ Update │
  │ UI │
  └─────────┘
```
==== 완전한 구현 예제
```csharp
// Observer Pattern 구현: ViewModel
using System.ComponentModel;
using System.Runtime.CompilerServices;
public class TemperatureSensor : INotifyPropertyChanged
{
  private double _temperature;
  private string _status = "Ready";
  // Subject: 변경 통지
  public event PropertyChangedEventHandler? PropertyChanged;
  // 관찰 대상 속성
  public double Temperature
  {
  get => _temperature;
  set
  {
  if (_temperature != value) // 변경 시에만 통지
  {
  _temperature = value;
  OnPropertyChanged(); // Observer들에게 통지
  // 연쇄 업데이트
  UpdateStatus();
  }
  }
  }
  public string Status
  {
  get => _status;
  private set
  {
  if (_status != value)
  {
  _status = value;
  OnPropertyChanged();
  }
  }
  }
  // 통지 메서드
  protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
  {
  PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
  }
  private void UpdateStatus()
  {
  Status = Temperature switch
  {
  > 500 => "High Temperature Warning", < 100 => "Low Temperature Warning", _ => "Normal"
  };
  }
}
```
*장점*:
- View와 ViewModel 간 느슨한 결합
- 하나의 속성 변경이 여러 UI 요소 업데이트
- 테스트 가능 (View 없이도 테스트)
=== Command Pattern (명령 패턴)
ICommand는 Command Pattern의 구현이다. 사용자 액션을 객체로 캡슐화한다.
==== 완전한 RelayCommand 구현
```csharp
using System;
using System.Windows.Input;
public class RelayCommand : ICommand
{
  private readonly Action<object?> _execute;
  private readonly Predicate<object?>? _canExecute;
  public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null)
  {
  _execute = execute ?? throw new ArgumentNullException(nameof(execute));
  _canExecute = canExecute;
  }
  // CanExecute 변경 통지
  public event EventHandler? CanExecuteChanged
  {
  add => CommandManager.RequerySuggested += value;
  remove => CommandManager.RequerySuggested -= value;
  }
  public bool CanExecute(object? parameter)
  {
  return _canExecute?.Invoke(parameter) ?? true;
  }
  public void Execute(object? parameter)
  {
  _execute(parameter);
  }
}
// 제네릭 버전
public class RelayCommand<T> : ICommand
{
  private readonly Action<T?> _execute;
  private readonly Predicate<T?>? _canExecute;
  public RelayCommand(Action<T?> execute, Predicate<T?>? canExecute = null)
  {
  _execute = execute ?? throw new ArgumentNullException(nameof(execute));
  _canExecute = canExecute;
  }
  public event EventHandler? CanExecuteChanged
  {
  add => CommandManager.RequerySuggested += value;
  remove => CommandManager.RequerySuggested -= value;
  }
  public bool CanExecute(object? parameter)
  {
  return _canExecute?.Invoke((T?)parameter) ?? true;
  }
  public void Execute(object? parameter)
  {
  _execute((T?)parameter);
  }
}
```
==== ViewModel에서 사용
```csharp
public class EquipmentViewModel : INotifyPropertyChanged
{
  private double _temperature;
  private bool _isRunning;
  public double Temperature
  {
  get => _temperature;
  set { _temperature = value; OnPropertyChanged(); }
  }
  public bool IsRunning
  {
  get => _isRunning;
  set
  {
  _isRunning = value;
  OnPropertyChanged();
  // Command의 CanExecute 재평가 요청
  CommandManager.InvalidateRequerySuggested();
  }
  }
  // Command 속성
  public ICommand StartCommand { get; }
  public ICommand StopCommand { get; }
  public ICommand ResetCommand { get; }
  public EquipmentViewModel()
  {
  // Command 초기화
  StartCommand = new RelayCommand(execute: _ => Start(), canExecute: _ => !IsRunning);
  StopCommand = new RelayCommand(execute: _ => Stop(), canExecute: _ => IsRunning);
  ResetCommand = new RelayCommand(execute: _ => Reset(), canExecute: _ => !IsRunning && Temperature != 0);
  }
  private void Start()
  {
  IsRunning = true;
  // 장비 시작 로직
  }
  private void Stop()
  {
  IsRunning = false;
  // 장비 정지 로직
  }
  private void Reset()
  {
  Temperature = 0;
  // 초기화 로직
  }
  public event PropertyChangedEventHandler? PropertyChanged;
  protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
  {
  PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
  }
}
```
=== Singleton Pattern (싱글톤 패턴)
데이터 서비스나 설정 관리에 Singleton을 사용한다.
==== Thread-safe Singleton 구현
```csharp
public sealed class DataManager
{
  private static readonly Lazy<DataManager> _instance =
  new Lazy<DataManager>(() => new DataManager());
  public static DataManager Instance => _instance.Value;
  private readonly List<Equipment> _equipments;
  // private 생성자
  private DataManager()
  {
  _equipments = new List<Equipment>();
  LoadEquipments();
  }
  public IReadOnlyList<Equipment> Equipments => _equipments.AsReadOnly();
  public void AddEquipment(Equipment equipment)
  {
  _equipments.Add(equipment);
  }
  private void LoadEquipments()
  {
  // 데이터 로드 로직
  }
}
// 사용
var manager = DataManager.Instance;
var equipments = manager.Equipments;
```
*Lazy<T> 장점*:
- Thread-safe (내부적으로 lock 사용)
- 실제 사용 시점에만 생성 (Lazy initialization)
- 성능 최적화
== 완전한 MVVM 예제: 센서 모니터링 시스템
=== Model: SensorData.cs
```csharp
using System;
namespace SemiconductorHMI.Models
{
  public class SensorData
  {
  public string SensorId { get; set; } = string.Empty;
  public double Temperature { get; set; }
  public double Pressure { get; set; }
  public DateTime Timestamp { get; set; }
  public bool IsNormal =>
  Temperature >= 100 && Temperature <= 500 &&
  Pressure >= 1.0 && Pressure <= 5.0;
  }
}
```
=== ViewModel: SensorViewModel.cs
```csharp
using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using System.Windows.Threading;
using SemiconductorHMI.Models;
namespace SemiconductorHMI.ViewModels
{
  public class SensorViewModel : INotifyPropertyChanged
  {
  private readonly DispatcherTimer _timer;
  private readonly Random _random = new();
  private SensorData _sensorData;
  private bool _isMonitoring;
  public SensorViewModel()
  {
  _sensorData = new SensorData
  {
  SensorId = "CVD-01", Temperature = 300, Pressure = 3.0, Timestamp = DateTime.Now
  };
  // 타이머 설정 (1초마다 갱신)
  _timer = new DispatcherTimer
  {
  Interval = TimeSpan.FromSeconds(1)
  };
  _timer.Tick += OnTimerTick;
  // Command 초기화
  StartMonitoringCommand = new RelayCommand(_ => StartMonitoring(), _ => !IsMonitoring);
  StopMonitoringCommand = new RelayCommand(_ => StopMonitoring(), _ => IsMonitoring);
  }
  // 바인딩 속성
  public string SensorId => _sensorData.SensorId;
  public double Temperature
  {
  get => _sensorData.Temperature;
  set
  {
  if (_sensorData.Temperature != value)
  {
  _sensorData.Temperature = value;
  OnPropertyChanged();
  OnPropertyChanged(nameof(StatusText));
  }
  }
  }
  public double Pressure
  {
  get => _sensorData.Pressure;
  set
  {
  if (_sensorData.Pressure != value)
  {
  _sensorData.Pressure = value;
  OnPropertyChanged();
  OnPropertyChanged(nameof(StatusText));
  }
  }
  }
  public string Timestamp => _sensorData.Timestamp.ToString("HH: mm: ss");
  public string StatusText => _sensorData.IsNormal ? "Normal" : "Warning";
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
  // Command
  public ICommand StartMonitoringCommand { get; }
  public ICommand StopMonitoringCommand { get; }
  private void StartMonitoring()
  {
  IsMonitoring = true;
  _timer.Start();
  }
  private void StopMonitoring()
  {
  IsMonitoring = false;
  _timer.Stop();
  }
  private void OnTimerTick(object? sender, EventArgs e)
  {
  // 센서 데이터 시뮬레이션
  Temperature += _random.NextDouble() * 10 - 5; // ±5도 변동
  Pressure += _random.NextDouble() * 0.2 - 0.1; // ±0.1 Torr 변동
  // 범위 제한
  Temperature = Math.Clamp(Temperature, 50, 550);
  Pressure = Math.Clamp(Pressure, 0.5, 5.5);
  _sensorData.Timestamp = DateTime.Now;
  OnPropertyChanged(nameof(Timestamp));
  }
  public event PropertyChangedEventHandler? PropertyChanged;
  protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
  {
  PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
  }
  }
}
```
=== View: MainWindow.xaml
```xml
<Window x: Class="SemiconductorHMI.MainWindow"
  xmlns="http: //schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns: x="http: //schemas.microsoft.com/winfx/2006/xaml"
  xmlns: vm="clr-namespace: SemiconductorHMI.ViewModels"
  Title="Semiconductor Sensor Monitor" Height="400" Width="600">
  \<Window.DataContext>
  \<vm: SensorViewModel/>
  \</Window.DataContext>
  \<Grid Margin="20">
  \<Grid.RowDefinitions>
  \<RowDefinition Height="Auto"/>
  \<RowDefinition Height="*"/>
  \<RowDefinition Height="Auto"/>
  \</Grid.RowDefinitions>
  \<!-- Header -->
  \<TextBlock Grid.Row="0" Text="CVD Equipment Sensor Monitor"
  FontSize="24" FontWeight="Bold" Margin="0, 0, 0, 20"/>
  \<!-- Sensor Data -->
  \<Grid Grid.Row="1">
  \<Grid.RowDefinitions>
  \<RowDefinition Height="Auto"/>
  \<RowDefinition Height="Auto"/>
  \<RowDefinition Height="Auto"/>
  \<RowDefinition Height="Auto"/>
  \</Grid.RowDefinitions>
  \<Grid.ColumnDefinitions>
  \<ColumnDefinition Width="150"/>
  \<ColumnDefinition Width="*"/>
  \</Grid.ColumnDefinitions>
  \<!-- Sensor ID -->
  \<TextBlock Grid.Row="0" Grid.Column="0" Text="Sensor ID: "
  VerticalAlignment="Center" Margin="0, 10"/>
  \<TextBlock Grid.Row="0" Grid.Column="1"
  Text="{Binding SensorId}"
  VerticalAlignment="Center" Margin="0, 10"
  FontWeight="Bold"/>
  \<!-- Temperature -->
  \<TextBlock Grid.Row="1" Grid.Column="0" Text="Temperature: "
  VerticalAlignment="Center" Margin="0, 10"/>
  \<TextBlock Grid.Row="1" Grid.Column="1"
  VerticalAlignment="Center" Margin="0, 10"
  FontSize="18" FontWeight="Bold">
  \<TextBlock.Text>
  \<MultiBinding StringFormat="{}{0: F1} °C">
  \<Binding Path="Temperature"/>
  \</MultiBinding>
  \</TextBlock.Text>
  \</TextBlock>
  \<!-- Pressure -->
  \<TextBlock Grid.Row="2" Grid.Column="0" Text="Pressure: "
  VerticalAlignment="Center" Margin="0, 10"/>
  \<TextBlock Grid.Row="2" Grid.Column="1"
  VerticalAlignment="Center" Margin="0, 10"
  FontSize="18" FontWeight="Bold">
  \<TextBlock.Text>
  \<MultiBinding StringFormat="{}{0: F2} Torr">
  \<Binding Path="Pressure"/>
  \</MultiBinding>
  \</TextBlock.Text>
  \</TextBlock>
  \<!-- Status -->
  \<TextBlock Grid.Row="3" Grid.Column="0" Text="Status: "
  VerticalAlignment="Center" Margin="0, 10"/>
  \<TextBlock Grid.Row="3" Grid.Column="1"
  Text="{Binding StatusText}"
  VerticalAlignment="Center" Margin="0, 10"
  FontSize="18" FontWeight="Bold">
  \<TextBlock.Style>
  \<Style TargetType="TextBlock">
  \<Trigger Property="Text" Value="Normal">
  \<Setter Property="Foreground" Value="Green"/>
  \</Trigger>
  \<Trigger Property="Text" Value="Warning">
  \<Setter Property="Foreground" Value="Red"/>
  \</Trigger>
  \</Style>
  \</TextBlock.Style>
  \</TextBlock>
  \</Grid>
  \<!-- Controls -->
  \<StackPanel Grid.Row="2" Orientation="Horizontal"
  HorizontalAlignment="Center" Margin="0, 20, 0, 0">
  \<Button Content="Start Monitoring" Width="150" Height="40"
  Command="{Binding StartMonitoringCommand}" Margin="5"/>
  \<Button Content="Stop Monitoring" Width="150" Height="40"
  Command="{Binding StopMonitoringCommand}" Margin="5"/>
  \</StackPanel>
  \<!-- Timestamp -->
  \<TextBlock Grid.Row="2" Text="{Binding Timestamp, StringFormat='Last Update: {0}'}"
  HorizontalAlignment="Right" VerticalAlignment="Bottom"
  FontSize="10" Foreground="Gray"/>
  \</Grid>
</Window>
```
*실행 방법*:
1. Visual Studio 2022에서 새 WPF App (.NET 8.0) 프로젝트 생성
2. 프로젝트 구조 생성: Models/, ViewModels/, Views/
3. 위 코드를 각 파일에 복사
4. F5로 실행
*기능*:
- Start Monitoring: 1초마다 센서 데이터 업데이트
- Stop Monitoring: 모니터링 중지
- 온도/압력이 정상 범위를 벗어나면 Status가 "Warning"으로 변경
- Command의 CanExecute에 의해 버튼 활성화/비활성화 자동 제어
== MCQ (Multiple Choice Questions)
=== 문제 1: C\# 타입 안전성 (기초)
다음 중 C\#에서 컴파일 오류가 발생하는 코드는?
A. `int x = 100;` \
B. `double y = 3.14;` \
C. `string s = 123;` \
D. `var z = "text";`
*정답: C*
*해설*: C\#은 강타입 언어로, int를 string에 직접 할당할 수 없다. 명시적 변환(`123.ToString()`)이 필요하다.
---
=== 문제 2: MVVM 패턴 구성요소 (기초)
MVVM 패턴에서 UI와 직접 상호작용하는 것은?
A. Model \
B. View \
C. ViewModel \
D. Controller
*정답: B*
*해설*: View(XAML)가 UI를 정의하고 사용자와 직접 상호작용한다. ViewModel은 View와 데이터 바인딩을 통해 간접적으로 통신한다.
---
=== 문제 3: INotifyPropertyChanged (중급)
INotifyPropertyChanged의 목적은?
A. UI 스레드에서 작업 실행 \
B. 속성 변경을 UI에 통지 \
C. 메모리 자동 해제 \
D. 예외 처리
*정답: B*
*해설*: INotifyPropertyChanged는 Observer 패턴의 구현으로, ViewModel의 속성 변경을 View에 통지하여 UI를 자동 업데이트한다.
---
=== 문제 4: 데이터 바인딩 모드 (중급)
TextBox의 입력값을 ViewModel에 즉시 반영하려면?
A. `{Binding Property, Mode=OneWay}` \
B. `{Binding Property, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}` \
C. `{Binding Property, Mode=OneTime}` \
D. `{Binding Property, Mode=OneWayToSource}`
*정답: B*
*해설*: TwoWay는 양방향 바인딩, UpdateSourceTrigger=PropertyChanged는 키 입력마다 즉시 ViewModel에 반영한다는 의미이다.
---
=== 문제 5: Command Pattern (중급)
ICommand의 CanExecute 메서드의 역할은?
A. 명령 실행 \
B. 명령 실행 가능 여부 반환 \
C. 이벤트 핸들러 등록 \
D. 데이터 바인딩
*정답: B*
*해설*: CanExecute는 현재 상태에서 명령을 실행할 수 있는지 bool 값을 반환한다. WPF는 이 값에 따라 버튼 등을 자동으로 활성화/비활성화한다.
---
=== 문제 6: 코드 분석 - PropertyChanged (고급)
다음 코드의 문제점은?
```csharp
public double Temperature
{
  get => _temperature;
  set
  {
  _temperature = value;
  OnPropertyChanged(); // 항상 호출
  }
}
```
A. 문법 오류 \
B. 값이 변경되지 않아도 통지 발생 (성능 낭비) \
C. 스레드 안전하지 않음 \
D. 메모리 누수
*정답: B*
*해설*: 값이 실제로 변경될 때만 OnPropertyChanged를 호출해야 한다. 불필요한 통지는 UI 갱신 오버헤드를 발생시킨다. 개선: `if (_temperature != value) { ... }`
---
=== 문제 7: Singleton Pattern (고급)
다음 Singleton 구현의 장점은?
```csharp
private static readonly Lazy<DataManager> _instance =
  new Lazy<DataManager>(() => new DataManager());
public static DataManager Instance => _instance.Value;
```
A. Thread-safe + Lazy initialization \
B. 빠른 초기화 \
C. 다중 인스턴스 가능 \
D. 메모리 절약
*정답: A*
*해설*: Lazy<T>는 thread-safe하며, 실제 사용 시점(Value 접근 시)에만 인스턴스를 생성한다(lazy initialization).
---
=== 문제 8: LINQ 코드 분석 (고급)
다음 코드의 출력은?
```csharp
var temps = new[] { 100, 200, 300, 400, 500 };
var avg = temps.Where(t => t > 250).Average();
Console.WriteLine($"{avg: F0}");
```
A. 300 \
B. 350 \
C. 400 \
D. 450
*정답: C*
*해설*: `Where(t => t > 250)`는 `[300, 400, 500]`을 반환. `Average()`는 `(300+400+500)/3 = 400`.
---
=== 문제 9: WPF vs WinForms (고급)
WPF가 WinForms보다 유리한 점은?
A. 간단한 문법 \
B. 하드웨어 가속 및 벡터 그래픽 \
C. 빠른 학습 곡선 \
D. 작은 배포 크기
*정답: B*
*해설*: WPF는 DirectX 기반 하드웨어 가속과 벡터 그래픽을 지원하여 해상도 독립적이고 성능이 우수하다.
---
=== 문제 10: MVVM 장점 (도전)
MVVM 패턴의 가장 핵심적인 장점은?
A. 코드 줄 수 감소 \
B. View와 ViewModel의 분리로 테스트 가능성 향상 \
C. 빠른 실행 속도 \
D. 메모리 사용량 감소
*정답: B*
*해설*: MVVM의 핵심 장점은 UI(View)와 로직(ViewModel)의 분리이다. ViewModel은 View 없이도 단위 테스트가 가능하며, UI 디자이너와 개발자가 독립적으로 작업할 수 있다.
== 실습 과제
=== 과제 1: 기본 HMI 프로젝트 생성
+ Visual Studio에서 WPF 프로젝트 생성
+ MVVM 구조 설정
+ 기본 UI 레이아웃 구성
=== 과제 2: 데이터 바인딩 구현
+ Equipment Model 생성
+ ViewModel 구현
+ 데이터 바인딩 연결
=== 과제 3: 커맨드 추가
+ 시작/정지 커맨드 구현
+ 버튼에 커맨드 바인딩
+ CanExecute 로직 구현
== 추가 학습 자료
=== 공식 문서
- *Microsoft WPF 문서*: https: //learn.microsoft.com/en-us/dotnet/desktop/wpf/
- *C\# 언어 가이드*: https: //learn.microsoft.com/en-us/dotnet/csharp/
- *.NET Documentation*: https: //learn.microsoft.com/en-us/dotnet/
=== 참고 서적
- "Pro WPF 4.5 in C\#" by Matthew MacDonald
- "C\# 11 and .NET 7" by Mark J. Price
- "MVVM Survival Guide" by Muhammad Shujaat Siddiqi
== 요약
이번 챕터에서는 C\# WPF의 기초를 학습했다: *이론 (Theory): *
- C\# 언어의 역사와 특징: 타입 안전성, GC, LINQ, 람다 표현식
- WPF의 발전: Windows Forms → WPF (2006) → WinUI 3
- 반도체 산업 채택 현황: Applied Materials, Lam Research, KLA
- 산업 동향: 하이브리드 접근, 웹 기반 HMI, AI 통합
*응용 (Application): *
- MVVM 패턴 완전한 구현 (Model, View, ViewModel)
- Observer Pattern (INotifyPropertyChanged)
- Command Pattern (ICommand, RelayCommand)
- Singleton Pattern (Lazy<T>)
- 실행 가능한 센서 모니터링 시스템 예제
*성찰 (Reflections): *
- MCQ 10문제: C\# 기초, MVVM 개념, 코드 분석, 패턴 이해
*핵심 포인트: *
1. C\#은 타입 안전성과 GC로 안정적인 개발 가능
2. MVVM 패턴은 테스트 가능성과 유지보수성을 크게 향상
3. 데이터 바인딩은 UI와 로직의 자동 동기화를 제공
4. 디자인 패턴(Observer, Command, Singleton)의 실무 적용
다음 챕터에서는 C\# 실시간 데이터 처리와 멀티스레딩을 학습한다.
#pagebreak()