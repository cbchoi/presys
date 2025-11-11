= Week 5: C\# WPF 테스트 및 배포

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ 단위 테스트 (xUnit)
+ UI 자동화 테스트
+ 로깅 및 에러 처리
+ 애플리케이션 배포

== 단위 테스트

=== xUnit 설치

```bash
dotnet add package xUnit
dotnet add package xunit.runner.visualstudio
dotnet add package Moq
```

=== ViewModel 테스트

```csharp
public class EquipmentViewModelTests
{
    [Fact]
    public void Temperature_WhenSet_ShouldRaisePropertyChanged()
    {
        // Arrange
        var vm = new EquipmentViewModel();
        var raised = false;
        vm.PropertyChanged += (s, e) =>
        {
            if (e.PropertyName == nameof(vm.Temperature))
                raised = true;
        };

        // Act
        vm.Temperature = 450.0;

        // Assert
        Assert.True(raised);
        Assert.Equal(450.0, vm.Temperature);
    }

    [Theory]
    [InlineData(400, true)]
    [InlineData(500, false)]
    public void CanStart_ShouldReturnCorrectValue(double temp, bool expected)
    {
        // Arrange
        var vm = new EquipmentViewModel { Temperature = temp };

        // Act
        var result = vm.CanStart();

        // Assert
        Assert.Equal(expected, result);
    }
}
```

=== Mock 사용

```csharp
public class DataServiceTests
{
    [Fact]
    public async Task GetDataAsync_ShouldReturnData()
    {
        // Arrange
        var mockRepository = new Mock<IDataRepository>();
        mockRepository
            .Setup(r => r.GetTemperatureAsync())
            .ReturnsAsync(450.0);

        var service = new DataService(mockRepository.Object);

        // Act
        var data = await service.GetDataAsync();

        // Assert
        Assert.Equal(450.0, data.Temperature);
        mockRepository.Verify(r => r.GetTemperatureAsync(), Times.Once);
    }
}
```

== UI 자동화 테스트

=== FlaUI

```csharp
using FlaUI.Core;
using FlaUI.UIA3;

public class MainWindowTests : IDisposable
{
    private Application _app;
    private AutomationBase _automation;

    public MainWindowTests()
    {
        _app = Application.Launch("SemiconductorHMI.exe");
        _automation = new UIA3Automation();
    }

    [Fact]
    public void StartButton_WhenClicked_ShouldStartMonitoring()
    {
        // Arrange
        var window = _app.GetMainWindow(_automation);
        var startButton = window.FindFirstDescendant(cf =>
            cf.ByAutomationId("StartButton"));

        // Act
        startButton.Click();

        // Assert
        var statusText = window.FindFirstDescendant(cf =>
            cf.ByAutomationId("StatusText"));
        Assert.Equal("Running", statusText.Name);
    }

    public void Dispose()
    {
        _app?.Close();
        _automation?.Dispose();
    }
}
```

== 로깅

=== Serilog 설정

```csharp
using Serilog;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Debug()
            .WriteTo.Console()
            .WriteTo.File("logs/hmi-.txt",
                rollingInterval: RollingInterval.Day)
            .CreateLogger();

        Log.Information("Application starting");

        base.OnStartup(e);
    }

    protected override void OnExit(ExitEventArgs e)
    {
        Log.Information("Application shutting down");
        Log.CloseAndFlush();
        base.OnExit(e);
    }
}
```

=== 로그 사용

```csharp
public class EquipmentService
{
    private readonly ILogger _logger;

    public EquipmentService()
    {
        _logger = Log.ForContext<EquipmentService>();
    }

    public async Task StartAsync()
    {
        _logger.Information("Starting equipment monitoring");

        try
        {
            await ConnectToEquipmentAsync();
            _logger.Information("Successfully connected to equipment");
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Failed to connect to equipment");
            throw;
        }
    }
}
```

== 에러 처리

=== 전역 예외 처리

```csharp
public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        DispatcherUnhandledException += OnDispatcherUnhandledException;
        AppDomain.CurrentDomain.UnhandledException +=
            OnUnhandledException;
        TaskScheduler.UnobservedTaskException +=
            OnUnobservedTaskException;
    }

    private void OnDispatcherUnhandledException(object sender,
        DispatcherUnhandledExceptionEventArgs e)
    {
        Log.Error(e.Exception, "Unhandled dispatcher exception");
        MessageBox.Show($"An error occurred: {e.Exception.Message}",
            "Error", MessageBoxButton.OK, MessageBoxImage.Error);
        e.Handled = true;
    }

    private void OnUnhandledException(object sender,
        UnhandledExceptionEventArgs e)
    {
        Log.Fatal((Exception)e.ExceptionObject,
            "Unhandled domain exception");
    }

    private void OnUnobservedTaskException(object? sender,
        UnobservedTaskExceptionEventArgs e)
    {
        Log.Error(e.Exception, "Unobserved task exception");
        e.SetObserved();
    }
}
```

=== 재시도 패턴

```csharp
public class RetryHelper
{
    public static async Task<T> RetryAsync<T>(
        Func<Task<T>> action,
        int maxRetries = 3,
        TimeSpan? delay = null)
    {
        delay ??= TimeSpan.FromSeconds(1);

        for (int i = 0; i \< maxRetries; i++)
        {
            try
            {
                return await action();
            }
            catch (Exception ex) when (i \< maxRetries - 1)
            {
                Log.Warning(ex, "Retry {Attempt}/{MaxRetries}",
                    i + 1, maxRetries);
                await Task.Delay(delay.Value);
            }
        }

        throw new InvalidOperationException(
            $"Failed after {maxRetries} retries");
    }
}

// 사용 예
var data = await RetryHelper.RetryAsync(
    () => _service.GetDataAsync(),
    maxRetries: 3,
    delay: TimeSpan.FromSeconds(2));
```

== 배포

=== ClickOnce 배포

```xml
<Project Sdk="Microsoft.NET.Sdk">
  \<PropertyGroup>
    \<PublishUrl>< server\deployments\\</PublishUrl>
    \<InstallUrl>< server\deployments\\</InstallUrl>
    \<UpdateEnabled>true</UpdateEnabled>
    \<UpdateMode>Foreground</UpdateMode>
    \<UpdateInterval>7</UpdateInterval>
    \<UpdateIntervalUnits>Days</UpdateIntervalUnits>
  \</PropertyGroup>
</Project>
```

```bash
dotnet publish -c Release -r win-x64 --self-contained true
```

=== 자체 포함 배포

```bash
# 단일 파일 배포
dotnet publish -c Release -r win-x64 \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true
```

=== Windows Installer (WiX)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  \<Product Id="*" Name="Semiconductor HMI"
           Version="1.0.0.0" Manufacturer="Company">
    \<Package InstallerVersion="200" Compressed="yes"/>

    \<Directory Id="TARGETDIR" Name="SourceDir">
      \<Directory Id="ProgramFilesFolder">
        \<Directory Id="INSTALLFOLDER" Name="SemiconductorHMI"/>
      \</Directory>
    \</Directory>

    \<ComponentGroup Id="ProductComponents">
      \<Component Directory="INSTALLFOLDER">
        \<File Source="bin\Release\SemiconductorHMI.exe"/>
      \</Component>
    \</ComponentGroup>

    \<Feature Id="ProductFeature" Level="1">
      \<ComponentGroupRef Id="ProductComponents"/>
    \</Feature>
  \</Product>
</Wix>
```

== 구성 관리

=== appsettings.json

```json
{
  "Equipment": {
    "ConnectionString": "localhost:5000",
    "Timeout": 30,
    "RetryCount": 3
  },
  "Logging": {
    "MinimumLevel": "Information",
    "FilePath": "logs/hmi-.txt"
  },
  "Alarms": {
    "TemperatureMax": 480.0,
    "PressureMax": 3.0
  }
}
```

=== 구성 읽기

```csharp
using Microsoft.Extensions.Configuration;

public class ConfigurationService
{
    private readonly IConfiguration _configuration;

    public ConfigurationService()
    {
        _configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false)
            .AddJsonFile($"appsettings.{Environment}.json", optional: true)
            .Build();
    }

    public string GetConnectionString()
        => _configuration["Equipment:ConnectionString"];

    public double GetTemperatureMax()
        => _configuration.GetValue<double>("Alarms:TemperatureMax");
}
```

== 성능 모니터링

=== Performance Counter

```csharp
public class PerformanceMonitor
{
    private readonly PerformanceCounter _cpuCounter;
    private readonly PerformanceCounter _memoryCounter;

    public PerformanceMonitor()
    {
        _cpuCounter = new PerformanceCounter(
            "Processor", "% Processor Time", "_Total");
        _memoryCounter = new PerformanceCounter(
            "Memory", "Available MBytes");
    }

    public double GetCpuUsage() => _cpuCounter.NextValue();
    public double GetAvailableMemory() => _memoryCounter.NextValue();
}
```

== 실습 과제

=== 과제 1: 단위 테스트 작성

+ ViewModel 테스트 10개 이상
+ Service 테스트 5개 이상
+ Code Coverage 80% 이상

=== 과제 2: 로깅 시스템

+ Serilog 설정
+ 전역 예외 처리
+ 로그 레벨별 분류

=== 과제 3: 배포 패키지

+ ClickOnce 또는 자체 포함 배포
+ 설치 가이드 작성
+ 버전 관리

== 요약

이번 챕터에서는 테스트와 배포를 학습했습니다:

- xUnit 단위 테스트
- FlaUI UI 자동화
- Serilog 로깅
- 전역 예외 처리
- ClickOnce 배포
- 구성 관리
- 성능 모니터링

다음 챕터에서는 Python PySide6를 학습합니다.

#pagebreak()
