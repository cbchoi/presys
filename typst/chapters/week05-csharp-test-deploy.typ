= Week 5: C\# 테스트 및 배포
== 학습 목표
본 챕터에서는 다음을 학습한다: + TDD vs BDD 방법론 이해
+ xUnit을 활용한 단위 테스트 작성
+ Moq를 사용한 Mock 객체 생성
+ CI/CD 파이프라인 구축
+ WPF 애플리케이션 배포 전략
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *C\# 중급 수준*: LINQ, 람다 표현식, 제네릭
- *Unit Test 개념*: 테스트의 목적, Arrange-Act-Assert 패턴
- *Week 2 MVVM*: ViewModel, INotifyPropertyChanged 구현 경험
- *Git 기초*: add, commit, push 명령어
- *권장사항*: CI/CD 개념, Docker 기초
== 테스트 방법론의 역사와 발전
=== Test-Driven Development (TDD)의 탄생
TDD는 Kent Beck이 2003년 "Test-Driven Development: By Example"에서 체계화한 방법론이다.
*TDD 사이클 (Red-Green-Refactor)*:
```
1. Red    : 실패하는 테스트 작성
2. Green  : 테스트를 통과하는 최소한의 코드 작성
3. Refactor : 코드 개선 (리팩토링)
```
*장점*:
- 요구사항 명확화
- 회귀 버그 방지
- 리팩토링 안전성
- 문서화 효과
*단점*:
- 초기 학습 곡선
- 개발 시간 증가 (단기)
- UI 테스트 어려움
=== Behavior-Driven Development (BDD)의 등장
Dan North가 2006년 제안한 BDD는 TDD를 비즈니스 언어로 확장한 것이다.
*Given-When-Then 패턴*:
```gherkin
Feature: 반도체 장비 알람
  Scenario: 온도가 500도 초과 시 알람 발생
    Given 장비가 정상 운전 중이고
    When 온도가 500도를 초과하면
    Then Critical 알람이 발생한다
```
*TDD vs BDD 비교*:
- TDD: 개발자 중심, 코드 수준
- BDD: 비즈니스 중심, 시나리오 수준
=== 반도체 산업의 테스트 표준
*SEMI E30 (GEM)*:
- Generic Equipment Model
- 장비 통신 프로토콜 테스트
- Host-Equipment 인터페이스 검증
*SEMI E10 (Equipment Maintenance)*:
- MTBF (Mean Time Between Failures) 측정
- MTTR (Mean Time To Repair) 추적
- 예방 정비 검증
== CI/CD의 역사와 DevOps
=== Continuous Integration의 발전
*2000년대 초반*: CruiseControl
- XML 기반 설정
- CVS/SVN 연동
- 제한적 기능
*2010년대*: Jenkins (Hudson에서 분기)
- 플러그인 생태계
- 파이프라인 as Code
- 클라우드 통합
*2020년대*: GitHub Actions, GitLab CI
- YAML 기반 설정
- 컨테이너 네이티브
- 서버리스 실행
=== DevOps 문화의 확산
*DevOps 핵심 원칙*:
- Culture: 협업 문화
- Automation: 자동화
- Measurement: 측정
- Sharing: 지식 공유
*반도체 산업 적용*:
- Fab 자동화와 유사
- Zero Defect 목표
- 빠른 피드백 루프
== 테스트 이론적 기반
=== Test Pyramid (테스트 피라미드)
Mike Cohn이 2009년 "Succeeding with Agile"에서 제안한 Test Pyramid는 효율적인 테스트 전략을 시각화한 모델이다.
```
            ┌─────────────┐
           ╱  E2E Tests   ╲      ← 느림, 비쌈 (5%)
          ╱   (UI Tests)   ╲
         ╱─────────────────╲
        ╱ Integration Tests ╲    ← 중간 속도 (15%)
       ╱   (API Tests)       ╲
      ╱───────────────────────╲
     ╱     Unit Tests          ╲  ← 빠름, 저렴 (80%)
    ╱  (Method-level Tests)     ╲
   ╱─────────────────────────────╲
```
*각 계층의 특성: *
**1. Unit Tests (단위 테스트)**
- 비율: 전체의 70-80%
- 범위: 단일 메서드/클래스
- 속도: 밀리초 단위 (< 10ms)
- 격리: Mock/Stub으로 의존성 제거
- 예시: `CalculateAverage()` 메서드 테스트
```csharp
[Fact]
public void CalculateAverage_EmptyArray_ThrowsException()
{
    var calc = new StatisticsCalculator();
    var emptyData = new double[] { };
    Assert.Throws<ArgumentException>(() => calc.CalculateAverage(emptyData));
}
// 실행 시간: 2ms
```
**2. Integration Tests (통합 테스트)**
- 비율: 전체의 15-20%
- 범위: 여러 컴포넌트 간 상호작용
- 속도: 초 단위 (1-10s)
- 격리: 실제 데이터베이스/파일 시스템 사용
- 예시: ViewModel + Service + Database 통합
```csharp
[Fact]
public async Task SaveSensorData_WithValidData_SavesToDatabase()
{
    // Arrange: 실제 DB 연결
    var dbContext = new TestDbContext();
    var service = new SensorService(dbContext);
    // Act
    await service.SaveAsync(new SensorData { Temperature = 450 });
    // Assert
    var saved = await dbContext.SensorData.FirstAsync();
    Assert.Equal(450, saved.Temperature);
}
// 실행 시간: 3초
```
**3. E2E Tests (End-to-End 테스트)**
- 비율: 전체의 5-10%
- 범위: 전체 애플리케이션 워크플로우
- 속도: 분 단위 (1-5min)
- 격리: 실제 환경과 유사한 통합 환경
- 예시: UI 자동화 테스트 (Selenium, Appium)
```csharp
[Fact]
public void FullWorkflow_StartMonitoring_DisplaysData()
{
    // Arrange: WPF 애플리케이션 시작
    var app = new Application();
    app.Run(new MainWindow());
    // Act: UI 조작
    ClickButton("StartMonitoring");
    WaitFor(TimeSpan.FromSeconds(5));
    // Assert: 화면에 데이터 표시됨
    AssertElementExists("SensorValue");
}
// 실행 시간: 2분
```
*Test Pyramid의 원칙: *
- 하위로 갈수록 많은 테스트, 빠른 실행
- 상위로 갈수록 적은 테스트, 느린 실행
- 80%의 버그를 Unit Test에서 잡아야 함
*안티패턴: Ice Cream Cone (거꾸로 된 피라미드)*
```
     ╱─────────────╲
    ╱  E2E Tests    ╲    ← 80% (잘못됨!)
   ╱   (너무 많음)   ╲
  ╱─────────────────╲
 ╱ Integration Tests ╲  ← 15%
╱───────────────────╲
╱   Unit Tests       ╱  ← 5% (너무 적음!)
```
- 느린 빌드 (1시간 이상)
- 불안정한 테스트 (Flaky Tests)
- 높은 유지보수 비용
*반도체 HMI 적용: *
```csharp
// Unit Tests (80%): 비즈니스 로직
- SensorDataValidator.Validate()
- AlarmThresholdCalculator.Calculate()
- StatisticsCalculator.CalculateAverage()
// Integration Tests (15%): 컴포넌트 통합
- SensorService + Database
- AlarmSystem + NotificationService
- DataLogger + FileSystem
// E2E Tests (5%): Critical 시나리오만
- 장비 시작 → 모니터링 → 알람 → 정지
- 데이터 수집 → 저장 → 조회 → 내보내기
```
=== Code Coverage (코드 커버리지)
코드 커버리지는 테스트가 실행한 코드의 비율을 측정하는 지표다.
*커버리지 유형: *
**1. Line Coverage (라인 커버리지)**
- 정의: 실행된 코드 라인의 비율
- 측정: (실행된 라인 수) / (전체 라인 수) × 100%
```csharp
public double Divide(double a, double b)
{
    if (b == 0)          // Line 1 (조건)
        throw new DivideByZeroException();  // Line 2
    return a / b;        // Line 3
}
// Test 1: Divide(10, 2) → Line 1, 3 실행 (Line 2 미실행)
// Line Coverage: 66.7% (2/3)
// Test 2: Divide(10, 0) → Line 1, 2 실행
// 추가 후 Line Coverage: 100% (3/3)
```
**2. Branch Coverage (분기 커버리지)**
- 정의: 모든 조건의 true/false 경로를 실행했는지
- 측정: (실행된 분기 수) / (전체 분기 수) × 100%
```csharp
public string GetStatus(double temp, double pressure)
{
    if (temp > 500 && pressure > 3.0)  // 4가지 조합
        return "Critical";
    return "Normal";
}
// Test 1: GetStatus(600, 4.0) → true && true (1/4)
// Test 2: GetStatus(400, 4.0) → false && true (2/4)
// Test 3: GetStatus(600, 2.0) → true && false (3/4)
// Test 4: GetStatus(400, 2.0) → false && false (4/4)
// Branch Coverage: 100% (4/4)
```
**3. Path Coverage (경로 커버리지)**
- 정의: 모든 실행 가능한 경로를 테스트했는지
- 측정: 가장 엄격하지만 현실적으로 100% 달성 어려움
```csharp
public int Classify(int a, int b, int c)
{
    if (a > 0) {           // Branch 1
        if (b > 0) {       // Branch 2
            if (c > 0)     // Branch 3
                return 1;
            return 2;
        }
        return 3;
    }
    return 4;
}
// 가능한 경로: 2³ = 8가지
// Path Coverage 100% = 8개 테스트 필요
```
*커버리지 목표 설정: *
#figure(table(columns: (auto, auto, auto), align: left, [*프로젝트 유형*], [*목표 커버리지*], [*설명*], [Critical 시스템], [90-100%], [반도체 장비, 의료기기, 항공], [엔터프라이즈], [70-80%], [금융, ERP 시스템], [일반 애플리케이션], [60-70%], [웹/모바일 앱], [프로토타입], [30-50%], [PoC, MVP], ), caption: "프로젝트 유형별 코드 커버리지 목표")
*커버리지의 함정: *
```csharp
// ❌ 나쁜 예: 100% 커버리지지만 의미 없는 테스트
[Fact]
public void Add_CalledOnce_DoesNotThrow()
{
    var calc = new Calculator();
    calc.Add(1, 2);  // 결과 검증 없음!
    // Coverage: 100%, 실제 테스트 가치: 0%
}
// ✓ 좋은 예: 의미 있는 테스트
[Fact]
public void Add_TwoPositiveNumbers_ReturnsSum()
{
    var calc = new Calculator();
    var result = calc.Add(1, 2);
    Assert.Equal(3, result);  // 결과 검증
}
```
*Martin Fowler의 조언: *
> "코드 커버리지는 테스트가 충분한지 알려주지 않는다. 단지 테스트가 부족한 곳을 찾아줄 뿐이다."
*Visual Studio Code Coverage 사용: *
```bash
# .NET CLI로 커버리지 측정
dotnet test --collect: "XPlat Code Coverage"
# Coverlet으로 리포트 생성
dotnet test /p: CollectCoverage=true /p: CoverletOutputFormat=opencover
# ReportGenerator로 HTML 리포트
reportgenerator -reports: coverage.opencover.xml -targetdir: coveragereport
```
=== Test Double (테스트 더블)
Gerard Meszaros의 "xUnit Test Patterns"(2007)에서 정의한 테스트 더블은 테스트 대상의 의존성을 대체하는 객체들이다.
*5가지 Test Double 유형: *
**1. Dummy**
- 정의: 전달되지만 실제로 사용되지 않는 객체
- 용도: 파라미터 채우기
```csharp
// Dummy 예제
public interface ILogger { void Log(string message); }
public class DummyLogger : ILogger
{
    public void Log(string message) { }  // 아무것도 안함
}
[Fact]
public void ProcessData_ValidInput_Succeeds()
{
    var processor = new DataProcessor(new DummyLogger());  // Logger는 사용 안됨
    processor.Process(new SensorData { Temperature = 450 });
}
```
**2. Stub**
- 정의: 미리 준비된 응답을 반환하는 객체
- 용도: 테스트에 필요한 값 제공
```csharp
// Stub 예제
public class StubSensorReader : ISensorReader
{
    public double ReadTemperature() => 450.0;  // 항상 고정값 반환
    public double ReadPressure() => 2.5;
}
[Fact]
public void Monitor_Temperature450_NoAlarm()
{
    var stubReader = new StubSensorReader();  // 항상 450 반환
    var monitor = new TemperatureMonitor(stubReader);
    var alarm = monitor.Check();
    Assert.Null(alarm);  // 450은 정상 범위
}
```
**3. Spy**
- 정의: 호출 정보를 기록하는 객체
- 용도: 메서드가 호출되었는지 확인
```csharp
// Spy 예제
public class SpyNotificationService : INotificationService
{
    public int CallCount { get; private set; }
    public List<string> Messages { get; } = new();
    public void Notify(string message)
    {
        CallCount++;
        Messages.Add(message);
    }
}
[Fact]
public void RaiseAlarm_CriticalLevel_NotifiesTwice()
{
    var spy = new SpyNotificationService();
    var alarmSystem = new AlarmSystem(spy);
    alarmSystem.RaiseCritical("High Temperature");
    Assert.Equal(2, spy.CallCount);  // Email + SMS
    Assert.Contains("High Temperature", spy.Messages[0]);
}
```
**4. Mock**
- 정의: 기대값(Expectation)을 설정하고 검증하는 객체
- 용도: 상호작용 검증
```csharp
// Mock 예제 (Moq 라이브러리 사용)
[Fact]
public void SaveData_ValidData_CallsRepositorySave()
{
    // Arrange
    var mockRepo = new Mock<ISensorRepository>();
    var service = new SensorService(mockRepo.Object);
    var data = new SensorData { Temperature = 450 };
    // Act
    service.Save(data);
    // Assert: Save()가 정확히 1번 호출되었는지 검증
    mockRepo.Verify(r => r.Save(It.Is<SensorData>(d => d.Temperature == 450)), Times.Once());
}
```
**5. Fake**
- 정의: 실제 구현의 단순화된 버전 (동작하는 구현)
- 용도: 통합 테스트에서 외부 의존성 대체
```csharp
// Fake 예제: 메모리 내 데이터베이스
public class FakeSensorRepository : ISensorRepository
{
    private readonly List<SensorData> _data = new();
    public void Save(SensorData data) => _data.Add(data);
    public SensorData? GetById(int id) => _data.FirstOrDefault(d => d.Id == id);
    public IEnumerable<SensorData> GetAll() => _data;
}
[Fact]
public async Task SaveAndRetrieve_ValidData_ReturnsCorrectData()
{
    var fakeRepo = new FakeSensorRepository();  // 실제 동작하는 가짜 DB
    var service = new SensorService(fakeRepo);
    await service.SaveAsync(new SensorData { Id = 1, Temperature = 450 });
    var retrieved = await service.GetByIdAsync(1);
    Assert.Equal(450, retrieved.Temperature);
}
```
*Test Double 선택 가이드: *
```
질문: 테스트에서 무엇을 검증하는가?
┌─> 반환값만 중요? → Stub 사용
│
├─> 호출 여부/횟수? → Spy 또는 Mock 사용
│
├─> 복잡한 상호작용? → Mock 사용 (Moq, NSubstitute)
│
└─> 실제 동작 필요? → Fake 사용 (In-memory DB)
```
== Dependency Injection 이론
=== IoC (Inversion of Control) 원리
제어의 역전(IoC)은 Martin Fowler가 2004년 "Inversion of Control Containers and the Dependency Injection pattern"에서 체계화한 개념이다.
*전통적 제어 흐름 (직접 제어): *
```csharp
// ❌ 나쁜 예: SensorService가 직접 의존성 생성
public class SensorService
{
    private readonly DatabaseContext _db;
    private readonly Logger _logger;
    public SensorService()
    {
        _db = new DatabaseContext();  // 직접 생성
        _logger = new Logger();       // 직접 생성
    }
}
// 문제점:
// 1. 테스트 불가능 (DB 연결 필수)
// 2. 변경 어려움 (Logger 교체 시 코드 수정)
// 3. 강한 결합 (Tight Coupling)
```
*IoC 적용 (제어 역전): *
```csharp
// ✓ 좋은 예: 외부에서 의존성 주입
public class SensorService
{
    private readonly IDatabaseContext _db;
    private readonly ILogger _logger;
    // 생성자 주입 (Constructor Injection)
    public SensorService(IDatabaseContext db, ILogger logger)
    {
        _db = db;      // 외부에서 주입받음
        _logger = logger;  // 외부에서 주입받음
    }
}
// 사용:
var db = new DatabaseContext();
var logger = new ConsoleLogger();
var service = new SensorService(db, logger);  // 제어가 역전됨
```
*제어가 역전된 이유: *
- **Before**: SensorService가 의존성을 제어함 (생성, 관리)
- **After**: 외부(Container)가 의존성을 제어함
=== Dependency Injection Container (DI Container)
DI Container는 객체의 생명주기와 의존성을 자동으로 관리하는 프레임워크다.
*.NET의 내장 DI Container: *
```csharp
// Program.cs 또는 App.xaml.cs에서 설정
var services = new ServiceCollection();
// 1. Transient: 매번 새 인스턴스 생성
services.AddTransient<ISensorReader, SensorReader>();
// 2. Scoped: 요청당 1개 인스턴스 (WPF에서는 Window당)
services.AddScoped<ISensorService, SensorService>();
// 3. Singleton: 앱 전체에 1개 인스턴스
services.AddSingleton<IConfiguration, Configuration>();
var serviceProvider = services.BuildServiceProvider();
// 사용: Container가 자동으로 의존성 해결
var service = serviceProvider.GetService<ISensorService>();
// → Container가 ISensorReader를 자동으로 주입한 SensorService 반환
```
*Lifetime 비교: *
```
┌─────────────────────────────────────────┐
│ Application Lifetime                     │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Singleton (1 instance)              │ │
│  │  - Configuration                    │ │
│  │  - Logger                           │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌─────────────┐  ┌─────────────┐      │
│  │ Window 1    │  │ Window 2    │      │
│  │             │  │             │      │
│  │ ┌─────────┐ │  │ ┌─────────┐ │      │
│  │ │ Scoped  │ │  │ │ Scoped  │ │      │
│  │ │ Service │ │  │ │ Service │ │      │
│  │ └─────────┘ │  │ └─────────┘ │      │
│  │             │  │             │      │
│  │ ┌──┐ ┌──┐  │  │ ┌──┐ ┌──┐   │      │
│  │ │T1│ │T2│  │  │ │T1│ │T2│   │      │
│  │ └──┘ └──┘  │  │ └──┘ └──┘   │      │
│  │ Transient   │  │ Transient   │      │
│  └─────────────┘  └─────────────┘      │
└─────────────────────────────────────────┘
```
*실무 예제: WPF 애플리케이션*: ```csharp
// App.xaml.cs
public partial class App : Application
{
  private ServiceProvider _serviceProvider;
  public App()
  {
  // DI Container 설정
  var services = new ServiceCollection();
  // Services
  services.AddSingleton<IDatabaseContext, DatabaseContext>();
  services.AddSingleton<ILogger, FileLogger>();
  services.AddTransient<ISensorReader, SensorReader>();
  services.AddTransient<ISensorService, SensorService>();
  // ViewModels
  services.AddTransient<MainViewModel>();
  services.AddTransient<SettingsViewModel>();
  // Views
  services.AddTransient<MainWindow>();
  services.AddTransient<SettingsWindow>();
  _serviceProvider = services.BuildServiceProvider();
  }
  protected override void OnStartup(StartupEventArgs e)
  {
  // MainWindow를 Container에서 가져옴 (모든 의존성 자동 주입)
  var mainWindow = _serviceProvider.GetService<MainWindow>();
  mainWindow.Show();
  }
}
// MainWindow.xaml.cs
public partial class MainWindow : Window
{
  // ViewModel을 생성자 주입으로 받음
  public MainWindow(MainViewModel viewModel)
  {
  InitializeComponent();
  DataContext = viewModel; // Container가 자동으로 주입
  }
}
// MainViewModel.cs
public class MainViewModel : INotifyPropertyChanged
{
  private readonly ISensorService _sensorService;
  private readonly ILogger _logger;
  // 의존성을 생성자로 받음
  public MainViewModel(ISensorService sensorService, ILogger logger)
  {
  _sensorService = sensorService; // Container가 자동 주입
  _logger = logger; // Container가 자동 주입
  }
}
```
*DI의 장점: *
1. **테스트 용이성**: Mock 객체 주입 가능
2. **느슨한 결합**: 인터페이스 기반 의존성
3. **유지보수성**: 의존성 변경이 쉬움
4. **확장성**: 새로운 구현 추가가 쉬움
*테스트 예제: *
```csharp
// 테스트에서 Mock 주입
[Fact]
public void SaveData_DatabaseError_LogsError()
{
  // Arrange: Mock 생성
  var mockDb = new Mock<IDatabaseContext>();
  mockDb.Setup(db => db.Save(It.IsAny<SensorData>()))
  .Throws(new DbException("Connection failed"));
  var mockLogger = new Mock<ILogger>();
  // Act: Mock을 주입한 Service 생성
  var service = new SensorService(mockDb.Object, mockLogger.Object);
  service.SaveData(new SensorData { Temperature = 450 });
  // Assert: Logger가 에러를 기록했는지 확인
  mockLogger.Verify(l => l.LogError(It.IsAny<string>()), Times.Once());
}
```
== 이론: 테스트 방법론
=== TDD (Test-Driven Development)
==== Red-Green-Refactor 사이클
```
┌──────────────────┐
│ Red: 실패 테스트 │  ← 요구사항 명세
└────────┬─────────┘
  │
  ↓
┌──────────────────┐
│ Green: 최소 구현 │  ← 테스트 통과
└────────┬─────────┘
  │
  ↓
┌──────────────────┐
│ Refactor: 개선 │  ← 코드 품질 향상
└────────┬─────────┘
  │
  ↓ (반복)
```
==== TDD 실습 예제
*1단계 (Red)*: 실패하는 테스트 작성
```csharp
[Fact]
public void CalculateAverage_WithValidData_ReturnsCorrectAverage()
{
  // Arrange
  var calculator = new StatisticsCalculator();
  var data = new double[] { 100, 200, 300 };
  // Act
  var result = calculator.CalculateAverage(data);
  // Assert
  Assert.Equal(200, result);
}
```
*2단계 (Green)*: 최소한의 코드로 통과
```csharp
public class StatisticsCalculator
{
  public double CalculateAverage(double[] data)
  {
  return data.Sum() / data.Length; // 최소 구현
  }
}
```
*3단계 (Refactor)*: 개선
```csharp
public double CalculateAverage(double[] data)
{
  if (data == null || data.Length == 0)
  throw new ArgumentException("Data cannot be null or empty");
  return data.Average(); // LINQ 사용으로 개선
}
```
=== BDD (Behavior-Driven Development)
==== Given-When-Then 패턴
```
Given (전제 조건)
  → 시스템의 초기 상태 설정
When (행동)
  → 테스트할 액션 실행
Then (결과 검증)
  → 기대 결과 확인
```
==== BDD 실습 예제
```csharp
public class TemperatureAlarmTests
{
  [Fact]
  public void Temperature_WhenExceeds500_RaiseCriticalAlarm()
  {
  // Given: 장비가 정상 운전 중
  var equipment = new Equipment { Status = EquipmentStatus.Running };
  var alarmSystem = new AlarmSystem(equipment);
  var alarmsRaised = new List<Alarm>();
  alarmSystem.AlarmRaised += (s, alarm) => alarmsRaised.Add(alarm);
  // When: 온도가 500도 초과
  equipment.Temperature = 510;
  // Then: Critical 알람 발생
  Assert.Single(alarmsRaised);
  Assert.Equal(AlarmLevel.Critical, alarmsRaised[0].Level);
  Assert.Contains("temperature", alarmsRaised[0].Message.ToLower());
  }
}
```
=== CI/CD 개념
==== Continuous Integration (CI)
```
개발자 A, B, C
  │  │ │
  │  │ │  git push
  ↓  ↓ ↓
┌────────────────┐
│ Git Repository │
└────────┬───────┘
  │ webhook
  ↓
┌────────────────┐
│ CI Server │  ← 자동 빌드/테스트
│ (GitHub Actions)│
└────────┬───────┘
  │
  ↓
  Build Success?
  Yes → Deploy
  No → Notify
```
==== Continuous Deployment (CD)
*배포 단계*:
1. Build: 컴파일, 패키징
2. Test: 자동화 테스트 실행
3. Stage: Staging 환경 배포
4. Production: 운영 환경 배포
*Blue-Green Deployment*:
```
┌──────────────┐
│ Blue (현재) │ ← 사용자 트래픽
└──────────────┘
  ↓ 배포 준비
┌──────────────┐
│ Green (신규) │ ← 테스트 완료
└──────────────┘
  ↓ 트래픽 전환
┌──────────────┐
│ Blue │
└──────────────┘
┌──────────────┐
│ Green (현재) │ ← 사용자 트래픽
└──────────────┘
```
== 응용: 디자인 패턴
=== AAA Pattern (Arrange-Act-Assert)
모든 단위 테스트는 3단계로 구성: ```csharp
[Fact]
public void AddEquipment_WithValidEquipment_AddsToCollection()
{
    // Arrange (준비): 테스트 대상과 데이터 준비
    var manager = new EquipmentManager();
    var equipment = new Equipment
    {
        Id = "CVD-01", Name = "CVD Equipment 01", Type = EquipmentType.CVD
    };
    // Act (실행): 테스트할 메서드 호출
    manager.AddEquipment(equipment);
    // Assert (검증): 결과 확인
    Assert.Contains(equipment, manager.Equipments);
    Assert.Equal(1, manager.Equipments.Count);
}
```
*명확한 구분의 장점*:
- 가독성 향상
- 테스트 의도 명확화
- 유지보수 용이
=== Mock Object Pattern
의존성을 가짜 객체로 대체하여 격리된 테스트: ```csharp
// 인터페이스 정의
public interface IDataRepository
{
  Task<double> GetTemperatureAsync(string equipmentId);
  Task SaveDataAsync(SensorData data);
}
// Production 구현
public class SqlDataRepository : IDataRepository
{
  public async Task<double> GetTemperatureAsync(string equipmentId)
  {
  // 실제 DB 접근
  using var connection = new SqlConnection(_connectionString);
  // ... SQL 쿼리 실행
  return 450.0;
  }
  public async Task SaveDataAsync(SensorData data)
  {
  // 실제 DB 저장
  }
}
// Mock 사용 테스트
public class DataServiceTests
{
  [Fact]
  public async Task GetEquipmentData_WithValidId_ReturnsData()
  {
  // Arrange: Mock 객체 생성
  var mockRepo = new Mock<IDataRepository>();
  mockRepo
  .Setup(r => r.GetTemperatureAsync("CVD-01"))
  .ReturnsAsync(450.0);
  var service = new DataService(mockRepo.Object);
  // Act
  var temperature = await service.GetEquipmentDataAsync("CVD-01");
  // Assert
  Assert.Equal(450.0, temperature);
  mockRepo.Verify(r => r.GetTemperatureAsync("CVD-01"), Times.Once);
  }
}
```
*Mock의 장점*:
- DB, 네트워크 없이 테스트
- 빠른 실행 속도
- 예측 가능한 결과
- 에러 상황 시뮬레이션
=== Dependency Injection Pattern
의존성을 외부에서 주입하여 테스트 가능성 향상: ```csharp
// 나쁜 예: 의존성 하드코딩
public class EquipmentService
{
    private readonly SqlDataRepository _repository;
    public EquipmentService()
    {
        _repository = new SqlDataRepository();  // ❌ 테스트 불가능
    }
}
// 좋은 예: 의존성 주입
public class EquipmentService
{
    private readonly IDataRepository _repository;
    public EquipmentService(IDataRepository repository)  // ✓ 주입
    {
        _repository = repository;
    }
    public async Task<EquipmentStatus> GetStatusAsync(string id)
    {
        var temp = await _repository.GetTemperatureAsync(id);
        return temp > 500 ? EquipmentStatus.Alarm : EquipmentStatus.Normal;
    }
}
// 테스트
[Fact]
public async Task GetStatus_WhenHighTemp_ReturnsAlarm()
{
    // Mock 주입
    var mockRepo = new Mock<IDataRepository>();
    mockRepo.Setup(r => r.GetTemperatureAsync(It.IsAny<string>()))
            .ReturnsAsync(510);
    var service = new EquipmentService(mockRepo.Object);
    // 테스트
    var status = await service.GetStatusAsync("CVD-01");
    Assert.Equal(EquipmentStatus.Alarm, status);
}
```
== 완전한 실행 가능한 예제: ViewModel 단위 테스트
=== 요구사항
+ xUnit + Moq를 사용한 ViewModel 테스트
+ INotifyPropertyChanged 검증
+ Command CanExecute 테스트
+ Mock을 사용한 의존성 격리
+ 완전히 실행 가능한 테스트 프로젝트
=== EquipmentViewModel.cs (프로덕션 코드)
```csharp
using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
namespace HMI.ViewModels
{
    public class EquipmentViewModel : INotifyPropertyChanged
    {
        private readonly IEquipmentService _equipmentService;
        private string _equipmentId;
        private double _temperature;
        private EquipmentStatus _status;
        private bool _isLoading;
        public string EquipmentId
        {
            get => _equipmentId;
            set
            {
                if (_equipmentId != value)
                {
                    _equipmentId = value;
                    OnPropertyChanged();
                }
            }
        }
        public double Temperature
        {
            get => _temperature;
            set
            {
                if (_temperature != value)
                {
                    _temperature = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(StatusText));
                }
            }
        }
        public EquipmentStatus Status
        {
            get => _status;
            private set
            {
                if (_status != value)
                {
                    _status = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(StatusText));
                }
            }
        }
        public string StatusText => Status switch
        {
            EquipmentStatus.Running => "Running", EquipmentStatus.Idle => "Idle", EquipmentStatus.Alarm => "Alarm", _ => "Unknown"
        };
        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
                CommandManager.InvalidateRequerySuggested();
            }
        }
        public ICommand LoadDataCommand { get; }
        public ICommand StartCommand { get; }
        public ICommand StopCommand { get; }
        public EquipmentViewModel(IEquipmentService equipmentService)
        {
            _equipmentService = equipmentService ?? throw new ArgumentNullException(nameof(equipmentService));
            LoadDataCommand = new RelayCommand(async _ => await LoadDataAsync(), _ => !IsLoading);
            StartCommand = new RelayCommand(async _ => await StartAsync(), _ => CanStart());
            StopCommand = new RelayCommand(async _ => await StopAsync(), _ => CanStop());
        }
        private async Task LoadDataAsync()
        {
            IsLoading = true;
            try
            {
                var data = await _equipmentService.GetDataAsync(EquipmentId);
                Temperature = data.Temperature;
                Status = data.Status;
            }
            finally
            {
                IsLoading = false;
            }
        }
        private async Task StartAsync()
        {
            await _equipmentService.StartEquipmentAsync(EquipmentId);
            Status = EquipmentStatus.Running;
        }
        private async Task StopAsync()
        {
            await _equipmentService.StopEquipmentAsync(EquipmentId);
            Status = EquipmentStatus.Idle;
        }
        private bool CanStart() => !IsLoading && Status != EquipmentStatus.Running;
        private bool CanStop() => !IsLoading && Status == EquipmentStatus.Running;
        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
    public interface IEquipmentService
    {
        Task<EquipmentData> GetDataAsync(string equipmentId);
        Task StartEquipmentAsync(string equipmentId);
        Task StopEquipmentAsync(string equipmentId);
    }
    public class EquipmentData
    {
        public double Temperature { get; set; }
        public EquipmentStatus Status { get; set; }
    }
    public enum EquipmentStatus
    {
        Idle, Running, Alarm
    }
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
=== EquipmentViewModelTests.cs (테스트 코드)
```csharp
using System;
using System.ComponentModel;
using System.Threading.Tasks;
using HMI.ViewModels;
using Moq;
using Xunit;
namespace HMI.Tests.ViewModels
{
    public class EquipmentViewModelTests
    {
        private readonly Mock<IEquipmentService> _mockService;
        private readonly EquipmentViewModel _viewModel;
        public EquipmentViewModelTests()
        {
            _mockService = new Mock<IEquipmentService>();
            _viewModel = new EquipmentViewModel(_mockService.Object);
        }
        [Fact]
        public void Constructor_WithNullService_ThrowsArgumentNullException()
        {
            // Act & Assert
            Assert.Throws<ArgumentNullException>(() => new EquipmentViewModel(null!));
        }
        [Fact]
        public void EquipmentId_WhenSet_RaisesPropertyChanged()
        {
            // Arrange
            var propertyChangedRaised = false;
            _viewModel.PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(EquipmentViewModel.EquipmentId))
                    propertyChangedRaised = true;
            };
            // Act
            _viewModel.EquipmentId = "CVD-01";
            // Assert
            Assert.True(propertyChangedRaised);
            Assert.Equal("CVD-01", _viewModel.EquipmentId);
        }
        [Fact]
        public void EquipmentId_WhenSetToSameValue_DoesNotRaisePropertyChanged()
        {
            // Arrange
            _viewModel.EquipmentId = "CVD-01";
            var propertyChangedCount = 0;
            _viewModel.PropertyChanged += (s, e) => propertyChangedCount++;
            // Act
            _viewModel.EquipmentId = "CVD-01";
            // Assert
            Assert.Equal(0, propertyChangedCount);
        }
        [Fact]
        public void Temperature_WhenChanged_UpdatesStatusText()
        {
            // Arrange
            var statusTextChangedCount = 0;
            _viewModel.PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(EquipmentViewModel.StatusText))
                    statusTextChangedCount++;
            };
            // Act
            _viewModel.Temperature = 450;
            // Assert
            Assert.True(statusTextChangedCount > 0, "StatusText PropertyChanged should be raised");
        }
        [Theory]
        [InlineData(EquipmentStatus.Running, "Running")]
        [InlineData(EquipmentStatus.Idle, "Idle")]
        [InlineData(EquipmentStatus.Alarm, "Alarm")]
        public void StatusText_ReturnsCorrectText(EquipmentStatus status, string expectedText)
        {
            // Arrange & Act
            // Status setter는 private이므로 LoadDataAsync를 통해 설정
            _mockService
                .Setup(s => s.GetDataAsync(It.IsAny<string>()))
                .ReturnsAsync(new EquipmentData { Temperature = 450, Status = status });
            _viewModel.EquipmentId = "CVD-01";
            _viewModel.LoadDataCommand.Execute(null);
            // Wait for async completion (simplified for example)
            Task.Delay(100).Wait();
            // Assert
            Assert.Equal(expectedText, _viewModel.StatusText);
        }
        [Fact]
        public async Task LoadDataAsync_CallsServiceAndUpdatesProperties()
        {
            // Arrange
            var expectedData = new EquipmentData
            {
                Temperature = 450.5, Status = EquipmentStatus.Running
            };
            _mockService
                .Setup(s => s.GetDataAsync("CVD-01"))
                .ReturnsAsync(expectedData);
            _viewModel.EquipmentId = "CVD-01";
            // Act
            _viewModel.LoadDataCommand.Execute(null);
            await Task.Delay(100);  // Wait for async completion
            // Assert
            Assert.Equal(450.5, _viewModel.Temperature);
            Assert.Equal(EquipmentStatus.Running, _viewModel.Status);
            _mockService.Verify(s => s.GetDataAsync("CVD-01"), Times.Once);
        }
        [Fact]
        public void LoadDataCommand_WhenLoading_CannotExecute()
        {
            // Arrange
            _mockService
                .Setup(s => s.GetDataAsync(It.IsAny<string>()))
                .Returns(Task.Delay(1000).ContinueWith(_ => new EquipmentData()));
            _viewModel.EquipmentId = "CVD-01";
            // Act
            _viewModel.LoadDataCommand.Execute(null);
            // Assert (during loading)
            Assert.False(_viewModel.LoadDataCommand.CanExecute(null));
        }
        [Fact]
        public void StartCommand_WhenIdle_CanExecute()
        {
            // Arrange
            _mockService
                .Setup(s => s.GetDataAsync(It.IsAny<string>()))
                .ReturnsAsync(new EquipmentData { Status = EquipmentStatus.Idle });
            _viewModel.EquipmentId = "CVD-01";
            _viewModel.LoadDataCommand.Execute(null);
            Task.Delay(100).Wait();
            // Act & Assert
            Assert.True(_viewModel.StartCommand.CanExecute(null));
        }
        [Fact]
        public void StartCommand_WhenRunning_CannotExecute()
        {
            // Arrange
            _mockService
                .Setup(s => s.GetDataAsync(It.IsAny<string>()))
                .ReturnsAsync(new EquipmentData { Status = EquipmentStatus.Running });
            _viewModel.EquipmentId = "CVD-01";
            _viewModel.LoadDataCommand.Execute(null);
            Task.Delay(100).Wait();
            // Act & Assert
            Assert.False(_viewModel.StartCommand.CanExecute(null));
        }
        [Fact]
        public async Task StartAsync_CallsServiceAndUpdatesStatus()
        {
            // Arrange
            _mockService
                .Setup(s => s.StartEquipmentAsync("CVD-01"))
                .Returns(Task.CompletedTask);
            _viewModel.EquipmentId = "CVD-01";
            // Act
            _viewModel.StartCommand.Execute(null);
            await Task.Delay(100);
            // Assert
            Assert.Equal(EquipmentStatus.Running, _viewModel.Status);
            _mockService.Verify(s => s.StartEquipmentAsync("CVD-01"), Times.Once);
        }
        [Fact]
        public void StopCommand_WhenRunning_CanExecute()
        {
            // Arrange
            _mockService
                .Setup(s => s.GetDataAsync(It.IsAny<string>()))
                .ReturnsAsync(new EquipmentData { Status = EquipmentStatus.Running });
            _viewModel.EquipmentId = "CVD-01";
            _viewModel.LoadDataCommand.Execute(null);
            Task.Delay(100).Wait();
            // Act & Assert
            Assert.True(_viewModel.StopCommand.CanExecute(null));
        }
    }
}
```
=== 테스트 실행
```bash
# 테스트 프로젝트 생성
dotnet new xunit -n HMI.Tests
# 패키지 설치
cd HMI.Tests
dotnet add package Moq
dotnet add reference ../HMI/HMI.csproj
# 테스트 실행
dotnet test
# 결과
# Test run summary:
#   Total: 10
#   Passed: 10
#   Failed: 0
#   Skipped: 0
```
== MCQ (Multiple Choice Questions)
=== 문제 1: TDD 사이클 (기초)
TDD의 Red-Green-Refactor 사이클에서 "Red"의 의미는?
A. 에러 메시지 \
B. 실패하는 테스트 작성 \
C. 코드 리뷰 \
D. 배포 실패
*정답: B*
*해설*: Red 단계는 아직 구현되지 않은 기능에 대한 실패하는 테스트를 먼저 작성하는 단계이다.
---
=== 문제 2: AAA Pattern (기초)
AAA 패턴의 3단계는?
A. Add-Apply-Assert \
B. Arrange-Act-Assert \
C. Allocate-Action-Analyze \
D. Assign-Activate-Approve
*정답: B*
*해설*: Arrange (준비), Act (실행), Assert (검증)의 3단계로 테스트를 구조화한다.
---
=== 문제 3: Mock 객체 (중급)
Mock 객체의 주요 목적은?
A. 성능 향상 \
B. 의존성 격리 및 예측 가능한 테스트 \
C. 메모리 절약 \
D. UI 렌더링
*정답: B*
*해설*: Mock은 실제 의존성(DB, 네트워크)을 가짜 객체로 대체하여 격리된 테스트를 가능하게 한다.
---
=== 문제 4: Dependency Injection (중급)
의존성 주입의 장점이 아닌 것은?
A. 테스트 가능성 향상 \
B. 느슨한 결합 \
C. 코드 작성량 감소 \
D. 유연성 증가
*정답: C*
*해설*: DI는 인터페이스와 생성자 주입으로 인해 오히려 초기 코드량이 증가할 수 있다. 하지만 장기적으로 유지보수성이 향상된다.
---
=== 문제 5: CI/CD (중급)
Continuous Integration의 핵심 원칙은?
A. 매일 배포 \
B. 자주 통합하고 자동으로 빌드/테스트 \
C. 주 1회 통합 \
D. 수동 테스트
*정답: B*
*해설*: CI는 개발자들이 자주 (하루 여러 번) 코드를 통합하고, 자동으로 빌드와 테스트를 실행하여 조기에 문제를 발견한다.
---
=== 문제 6: 코드 분석 - Mock Setup (고급)
다음 코드의 문제점은?
```csharp
var mock = new Mock<IDataRepository>();
mock.Setup(r => r.GetDataAsync("CVD-01")).ReturnsAsync(new SensorData());
var service = new DataService(mock.Object);
var result = await service.GetDataAsync("CVD-02");  // 다른 ID!
```
A. 문법 오류 \
B. Setup과 호출 ID가 불일치하여 null 반환 \
C. Mock 생성 오류 \
D. 문제 없음
*정답: B*
*해설*: Mock은 "CVD-01"에 대해서만 Setup되었는데, "CVD-02"로 호출하면 설정되지 않은 동작이므로 기본값(null 또는 default)을 반환한다.
---
=== 문제 7: PropertyChanged 테스트 (고급)
INotifyPropertyChanged 테스트에서 확인해야 할 사항은?
A. 속성이 변경될 때 이벤트 발생 \
B. 같은 값으로 설정 시 이벤트 미발생 \
C. 올바른 PropertyName 전달 \
D. 모두 확인
*정답: D*
*해설*: 완전한 테스트를 위해 (1) 변경 시 이벤트 발생, (2) 동일 값 설정 시 미발생 (성능 최적화), (3) PropertyName 정확성을 모두 검증해야 한다.
---
=== 문제 8: TDD vs BDD (고급)
다음 중 BDD의 특징은?
A. 코드 중심 \
B. 비즈니스 언어(Given-When-Then) 사용 \
C. 단위 테스트만 작성 \
D. 개발자 전용
*정답: B*
*해설*: BDD는 비즈니스 이해관계자와 개발자가 공통으로 이해할 수 있는 Given-When-Then 형식의 시나리오를 사용한다.
---
=== 문제 9: Code Coverage (고급)
Code Coverage 80%의 의미는?
A. 80%의 코드 줄이 테스트로 실행됨 \
B. 80%의 버그가 발견됨 \
C. 80%의 기능이 구현됨 \
D. 80%의 속도 향상
*정답: A*
*해설*: Code Coverage는 테스트가 실행한 코드의 비율을 나타낸다. 80%는 전체 코드 중 80%가 최소 한 번 이상 테스트로 실행되었음을 의미한다.
---
=== 문제 10: 통합 테스트 vs 단위 테스트 (도전)
반도체 HMI에서 ViewModel 테스트 시 Mock을 사용하는 이유는?
A. 빠른 테스트 실행 (DB/네트워크 제거) \
B. 예측 가능한 결과 \
C. 의존성 격리 (ViewModel만 테스트) \
D. 모두 해당
*정답: D*
*해설*: Mock을 사용하면 (1) 실제 DB/네트워크 없이 빠르게 실행, (2) 항상 동일한 결과로 안정적, (3) ViewModel 로직만 격리하여 테스트할 수 있다.
== 추가 학습 자료
=== 공식 문서
- *xUnit Documentation*: https: //xunit.net/
- *Moq Documentation*: https: //github.com/moq/moq4
- *GitHub Actions*: https: //docs.github.com/en/actions
- *.NET Testing*: https: //learn.microsoft.com/en-us/dotnet/core/testing/
=== 참고 서적
- "Test-Driven Development: By Example" by Kent Beck
- "The Art of Unit Testing" by Roy Osherove
- "Continuous Delivery" by Jez Humble and David Farley
== 요약
이번 챕터에서는 C\# 테스트 및 배포를 학습했다: *이론 (Theory): *
- TDD vs BDD: Red-Green-Refactor vs Given-When-Then
- CI/CD 개념: 지속적 통합과 배포
- DevOps 문화: 자동화, 측정, 공유
- 반도체 산업 테스트 표준 (SEMI E30, E10)
*응용 (Application): *
- AAA Pattern (Arrange-Act-Assert)
- Mock Object Pattern (Moq 라이브러리)
- Dependency Injection Pattern
- 완전한 실행 가능한 ViewModel 단위 테스트
*성찰 (Reflections): *
- MCQ 10문제: TDD, Mock, CI/CD, 코드 분석
*핵심 포인트: *
1. TDD는 Red-Green-Refactor 사이클로 품질 보장
2. Mock은 의존성을 격리하여 빠르고 안정적인 테스트
3. AAA 패턴으로 명확한 테스트 구조 유지
4. CI/CD로 자동화된 빌드/테스트/배포 파이프라인 구축
이로써 C\# WPF 반도체 HMI 개발의 기초 과정을 완료했다. 다음 챕터에서는 Python PySide6를 학습한다.
#pagebreak()