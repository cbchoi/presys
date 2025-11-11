= Week 3: C\# WPF 실시간 데이터 처리 및 차트

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ Reactive Extensions (Rx)를 활용한 실시간 데이터 스트림 처리
+ LiveCharts2를 사용한 실시간 차트 구현
+ 비동기 프로그래밍 (async/await)
+ 스레드 안전성과 Dispatcher

== Reactive Extensions (Rx)

=== Rx 소개

Reactive Extensions는 비동기 데이터 스트림을 처리하는 라이브러리입니다.

*주요 개념*:
- Observable: 데이터 스트림
- Observer: 데이터 구독자
- Operators: 데이터 변환/필터링

=== Observable 생성

```csharp
// 주기적 데이터 생성
var observable = Observable
    .Interval(TimeSpan.FromMilliseconds(100))
    .Select(_ => GetTemperature());

// 구독
observable.Subscribe(temp => Temperature = temp);
```

=== Rx Operators

```csharp
// 필터링
observable.Where(temp => temp > 400);

// 변환
observable.Select(temp => temp * 1.8 + 32); // C to F

// 버퍼링
observable.Buffer(TimeSpan.FromSeconds(1));

// 샘플링
observable.Sample(TimeSpan.FromMilliseconds(100));
```

== 실시간 데이터 시뮬레이션

=== 장비 데이터 시뮬레이터

```csharp
public class EquipmentSimulator
{
    private readonly Random _random = new();

    public IObservable<ProcessData> CreateDataStream()
    {
        return Observable
            .Interval(TimeSpan.FromMilliseconds(100))
            .Select(_ => new ProcessData
            {
                Timestamp = DateTime.Now,
                Temperature = 450 + _random.NextDouble() * 10,
                Pressure = 2.5 + _random.NextDouble() * 0.5,
                FlowRate = 100 + _random.NextDouble() * 20
            });
    }
}
```

=== 알람 감지

```csharp
var alarmStream = dataStream
    .Where(data => data.Temperature > 480 || data.Pressure > 3.0)
    .Select(data => new Alarm
    {
        Severity = AlarmSeverity.Warning,
        Message = $"Parameter out of range: {data}",
        Timestamp = DateTime.Now
    });

alarmStream.Subscribe(alarm => AddAlarm(alarm));
```

== LiveCharts2

=== LiveCharts2 설치

```bash
dotnet add package LiveChartsCore.SkiaSharpView.WPF
```

=== 실시간 차트 구성

```csharp
public class ChartViewModel
{
    public ObservableCollection<double> TemperatureData { get; } = new();
    public ISeries[] Series { get; set; }

    public ChartViewModel()
    {
        Series = new ISeries[]
        {
            new LineSeries<double>
            {
                Values = TemperatureData,
                Fill = null,
                GeometrySize = 0
            }
        };

        // 데이터 스트림 구독
        dataStream.Subscribe(data =>
        {
            TemperatureData.Add(data.Temperature);
            if (TemperatureData.Count > 100)
                TemperatureData.RemoveAt(0);
        });
    }
}
```

=== XAML 차트

```xml
<lvc:CartesianChart Series="{Binding Series}"
                    XAxes="{Binding XAxes}"
                    YAxes="{Binding YAxes}"/>
```

== 비동기 프로그래밍

=== async/await 패턴

```csharp
public async Task<ProcessData> GetProcessDataAsync()
{
    await Task.Delay(100); // 장비 통신 시뮬레이션
    return new ProcessData
    {
        Temperature = await ReadTemperatureAsync(),
        Pressure = await ReadPressureAsync()
    };
}
```

=== Task.WhenAll

```csharp
public async Task<EquipmentStatus> GetFullStatusAsync()
{
    var tasks = new[]
    {
        ReadTemperatureAsync(),
        ReadPressureAsync(),
        ReadFlowRateAsync()
    };

    var results = await Task.WhenAll(tasks);
    return new EquipmentStatus(results);
}
```

== 스레드 안전성

=== Dispatcher 사용

```csharp
// 백그라운드 스레드에서 UI 업데이트
Application.Current.Dispatcher.Invoke(() =>
{
    Temperature = newValue;
});

// 또는
await Application.Current.Dispatcher.InvokeAsync(() =>
{
    Temperature = newValue;
});
```

=== ObserveOn 활용

```csharp
dataStream
    .ObserveOn(SynchronizationContext.Current)
    .Subscribe(data => Temperature = data.Temperature);
```

== 성능 최적화

=== 데이터 샘플링

```csharp
// 100ms마다 데이터를 받지만 1초마다 UI 업데이트
dataStream
    .Sample(TimeSpan.FromSeconds(1))
    .Subscribe(data => UpdateUI(data));
```

=== 버퍼링

```csharp
// 100개씩 모아서 처리
dataStream
    .Buffer(100)
    .Subscribe(batch => ProcessBatch(batch));
```

=== UI 가상화

```xml
<ListBox VirtualizingPanel.IsVirtualizing="True"
         VirtualizingPanel.VirtualizationMode="Recycling">
```

== 실습: 실시간 모니터링 시스템

=== 요구사항

+ 3개 파라미터 실시간 모니터링 (온도, 압력, 유량)
+ 각 파라미터별 실시간 차트
+ 알람 자동 감지 및 표시
+ 데이터 로깅

=== ViewModel 구현

```csharp
public class MonitoringViewModel : INotifyPropertyChanged
{
    private readonly EquipmentSimulator _simulator;
    private IDisposable? _subscription;

    public ObservableCollection<ProcessData> DataLog { get; } = new();
    public ObservableCollection<Alarm> Alarms { get; } = new();

    public ISeries[] TemperatureSeries { get; set; }
    public ISeries[] PressureSeries { get; set; }

    public ICommand StartCommand { get; }
    public ICommand StopCommand { get; }

    public MonitoringViewModel()
    {
        _simulator = new EquipmentSimulator();
        StartCommand = new RelayCommand(_ => Start());
        StopCommand = new RelayCommand(_ => Stop());

        InitializeCharts();
    }

    private void Start()
    {
        var dataStream = _simulator.CreateDataStream();

        _subscription = dataStream.Subscribe(
            data => ProcessData(data),
            error => HandleError(error)
        );
    }

    private void Stop()
    {
        _subscription?.Dispose();
    }

    private void ProcessData(ProcessData data)
    {
        // 차트 업데이트
        TemperatureData.Add(data.Temperature);
        PressureData.Add(data.Pressure);

        // 알람 체크
        CheckAlarms(data);

        // 로깅
        DataLog.Add(data);
        if (DataLog.Count > 1000)
            DataLog.RemoveAt(0);
    }
}
```

== 데이터 저장

=== CSV 저장

```csharp
public async Task SaveToCsvAsync(string filename)
{
    var lines = DataLog.Select(d =>
        $"{d.Timestamp:O},{d.Temperature},{d.Pressure},{d.FlowRate}");

    await File.WriteAllLinesAsync(filename, lines);
}
```

=== SQLite 저장

```csharp
public async Task SaveToDbAsync(ProcessData data)
{
    using var connection = new SqliteConnection(_connectionString);
    await connection.OpenAsync();

    var command = connection.CreateCommand();
    command.CommandText = """
        INSERT INTO ProcessData (Timestamp, Temperature, Pressure, FlowRate)
        VALUES ($timestamp, $temp, $pressure, $flow)
        """;

    command.Parameters.AddWithValue("$timestamp", data.Timestamp);
    command.Parameters.AddWithValue("$temp", data.Temperature);
    command.Parameters.AddWithValue("$pressure", data.Pressure);
    command.Parameters.AddWithValue("$flow", data.FlowRate);

    await command.ExecuteNonQueryAsync();
}
```

== 실습 과제

=== 과제 1: 실시간 차트 구현

+ LiveCharts2를 사용한 3개 파라미터 차트
+ 자동 스크롤링
+ 축 범위 자동 조정

=== 과제 2: 알람 시스템

+ 상한/하한 알람 구현
+ 알람 우선순위 (Critical, Warning, Info)
+ 알람 로그 저장

=== 과제 3: 데이터 로깅

+ 실시간 데이터 CSV 저장
+ 데이터 재생 기능
+ 통계 계산 (평균, 최대, 최소)

== 요약

이번 챕터에서는 실시간 데이터 처리를 학습했습니다:

- Reactive Extensions (Rx)
- Observable 패턴
- LiveCharts2 실시간 차트
- async/await 비동기 프로그래밍
- Dispatcher와 스레드 안전성
- 성능 최적화
- 데이터 저장

다음 챕터에서는 고급 UI 컨트롤을 학습합니다.

#pagebreak()
