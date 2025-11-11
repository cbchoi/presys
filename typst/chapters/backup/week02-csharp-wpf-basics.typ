= Week 2: C\# WPF 기초 및 반도체 HMI 프로젝트 구조

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ C\# 11과 .NET 8의 최신 기능 이해
+ WPF 아키텍처와 XAML 기초
+ MVVM 패턴을 활용한 HMI 설계
+ 반도체 장비 모니터링 UI 프로토타입 개발

== C\# 11 주요 기능

=== Raw String Literals

```csharp
string json = """
{
    "equipmentId": "CVD-01",
    "temperature": 450.5,
    "pressure": 2.5
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
    { Temperature: > 500 } => "Too Hot",
    { Temperature: \< 200 } => "Too Cold",
    _ => "Normal"
};
```

== WPF 아키텍처

=== WPF 구조

#figure(
  table(
    columns: (auto, 1fr),
    align: left,
    [*계층*], [*설명*],
    [Presentation Layer], [XAML UI 정의],
    [Business Logic], [ViewModel (MVVM)],
    [Data Access], [Model/Service],
    [Hardware], [장비 통신],
  ),
  caption: "WPF 아키텍처 계층"
)

=== XAML 기초

XAML(eXtensible Application Markup Language)은 WPF UI를 선언적으로 정의하는 언어입니다.

```xml
<Window x:Class="HMI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="반도체 장비 HMI" Height="800" Width="1200">
    \<Grid>
        \<TextBlock Text="{Binding Temperature}"
                   FontSize="24"/>
    \</Grid>
</Window>
```

== MVVM 패턴

=== MVVM 구조

- *Model*: 데이터 및 비즈니스 로직
- *View*: XAML UI
- *ViewModel*: View와 Model 연결, INotifyPropertyChanged

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
│   ├── Equipment.cs
│   └── ProcessData.cs
├── ViewModels/
│   ├── MainViewModel.cs
│   └── EquipmentViewModel.cs
├── Views/
│   ├── MainWindow.xaml
│   └── EquipmentView.xaml
├── Services/
│   └── DataService.cs
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
<TextBox Text="{Binding SetPoint, Mode=TwoWay,
                UpdateSourceTrigger=PropertyChanged}"/>
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
<Window x:Class="SemiconductorHMI.MainWindow"
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
                    \<TextBlock Text="{Binding Temperature,
                               StringFormat='Temperature: {0:F1}°C'}"/>
                    \<TextBlock Text="{Binding Pressure,
                               StringFormat='Pressure: {0:F2} Torr'}"/>
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

== 요약

이번 챕터에서는 C\# WPF의 기초를 학습했습니다:

- C\# 11 최신 기능
- WPF 아키텍처와 XAML
- MVVM 패턴
- 데이터 바인딩
- 커맨드 패턴
- 반도체 HMI 프로젝트 구조

다음 챕터에서는 실시간 데이터 처리를 학습합니다.

#pagebreak()
