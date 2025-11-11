= Week 4: C\# 고급 UI 컨트롤 및 커스텀 컨트롤
== 학습 목표
본 챕터에서는 다음을 학습한다: + WPF Control 아키텍처 이해 (Visual Tree, Logical Tree)
+ 고급 WPF 컨트롤 활용 (DataGrid, TreeView, TabControl)
+ 커스텀 컨트롤 개발 (Gauge, LED Indicator)
+ 스타일과 템플릿을 활용한 UI 디자인
+ 디자인 패턴을 적용한 UI 개발
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *WPF 기초*: XAML 문법, 레이아웃 컨트롤 (Grid, StackPanel)
- *XAML 문법*: Property Element 문법, Attached Property
- *C\# 중급*: 상속, 가상 메서드, DependencyProperty
- *Week 2 MVVM*: 데이터 바인딩, INotifyPropertyChanged
- *권장사항*: 그래픽스 기초 (2D 좌표계, 회전 변환)
== WPF Control 아키텍처의 역사와 발전
=== Windows Forms vs WPF Control
Windows Forms (2002)와 WPF (2006)의 근본적 차이: *Windows Forms 한계*:
- GDI/GDI+ 기반 (래스터 그래픽)
- 컨트롤 상속 기반 (복잡도 증가)
- 디자이너-개발자 협업 어려움
- 하드웨어 가속 미지원
*WPF 혁신*:
- DirectX 기반 (벡터 그래픽)
- Template 기반 (재사용성 향상)
- XAML로 UI/로직 분리
- 하드웨어 가속 지원
=== Visual Tree vs Logical Tree
WPF는 두 가지 트리 구조로 UI를 관리한다: ==== Logical Tree
```
Window
└── Grid
    ├── Button ("Start")
    └── TextBlock ("Status")
```
*특징*:
- XAML에서 정의한 요소
- 데이터 바인딩, 이벤트 라우팅
- 리소스 상속
==== Visual Tree
```
Window
└── Border (Window Chrome)
    └── Grid
        ├── Button
        │   └── ButtonChrome
        │       └── ContentPresenter
        │           └── TextBlock ("Start")
        └── TextBlock ("Status")
```
*특징*:
- 실제 렌더링되는 모든 요소
- Template에서 정의한 내부 요소 포함
- Hit Testing, 렌더링
*Visual Tree 탐색 코드*:
```csharp
public static void PrintVisualTree(DependencyObject element, int depth = 0)
{
    if (element == null) return;
    Console.WriteLine(new string(' ', depth * 2) + element.GetType().Name);
    int childCount = VisualTreeHelper.GetChildrenCount(element);
    for (int i = 0; i < childCount; i++)
    {
        var child = VisualTreeHelper.GetChild(element, i);
        PrintVisualTree(child, depth + 1);
    }
}
// 사용
PrintVisualTree(this);  // MainWindow
```
=== Dependency Property 시스템
WPF의 핵심 메커니즘인 Dependency Property: *일반 Property vs Dependency Property*:
```csharp
// 일반 Property
public class NormalClass
{
    private int _value;
    public int Value
    {
        get => _value;
        set => _value = value;
    }
}
// Dependency Property
public class DependencyClass : DependencyObject
{
    public static readonly DependencyProperty ValueProperty =
        DependencyProperty.Register(nameof(Value), typeof(int), typeof(DependencyClass), new PropertyMetadata(0));  // 기본값
    public int Value
    {
        get => (int)GetValue(ValueProperty);
        set => SetValue(ValueProperty, value);
    }
}
```
*Dependency Property 장점*:
- 값 상속 (Visual Tree를 통해)
- 데이터 바인딩 지원
- 스타일 및 애니메이션 지원
- 메모리 효율적 (기본값은 공유)
- Change Notification 자동
== 반도체 산업 UI 트렌드
=== SCADA 시스템 진화
*1세대 (1990s)*: 단순 표시
- 텍스트 기반 모니터링
- 알람 리스트
- 정적 화면
*2세대 (2000s)*: 2D 그래픽
- Mimic 다이어그램
- 실시간 트렌드 차트
- 애니메이션 효과
*3세대 (2010s)*: 3D 시각화
- 3D 장비 모델
- VR/AR 통합
- 터치 인터페이스
*4세대 (2020s)*: AI 기반
- 예측 알람
- 자동 최적화
- 디지털 트윈
=== 주요 장비사 UI 특징
*Applied Materials*:
- 멀티 챔버 3D 뷰
- 실시간 파라미터 오버레이
- 터치 최적화
*ASML*:
- 초고해상도 웨이퍼 맵
- 오버레이 히트맵
- 실시간 스루풋 차트
*KLA*:
- 검사 결과 시각화
- Defect Classification
- 통계 차트
== WPF 렌더링 파이프라인 이론
=== WPF 아키텍처 계층
WPF는 3계층 아키텍처로 구성된다: ```
┌────────────────────────────────────────────┐
│ Presentation Layer (XAML + C#) │
│ - Window, Button, TextBox, etc. │
│ - Application Logic │
└─────────────────┬──────────────────────────┘
  │
┌─────────────────┴──────────────────────────┐
│ PresentationCore (Managed) │
│ - Visual Tree 관리 │
│ - Layout, Input, Animation │
│ - Media Integration │
└─────────────────┬──────────────────────────┘
  │
┌─────────────────┴──────────────────────────┐
│ PresentationFramework (Managed) │
│ - Dependency Property System │
│ - Data Binding Engine │
│ - Styling and Templating │
└─────────────────┬──────────────────────────┘
  │
┌─────────────────┴──────────────────────────┐
│ milcore.dll (Unmanaged C++) │
│ - Composition Engine │
│ - Rendering Thread │
└─────────────────┬──────────────────────────┘
  │
┌─────────────────┴──────────────────────────┐
│ DirectX (Hardware Acceleration) │
│ - GPU Rendering │
│ - Shader Pipeline │
└────────────────────────────────────────────┘
```
*핵심 포인트*:
- **UI Thread (Managed)**: 사용자 코드, 이벤트 처리, 데이터 바인딩
- **Render Thread (Unmanaged)**: 실제 렌더링, GPU 명령 생성
- **분리의 이점**: UI 스레드 블로킹 없이 부드러운 렌더링
=== 렌더링 파이프라인 단계
WPF 렌더링은 다음 단계를 거친다: ```
1. Measure Pass
   └─> 각 요소가 필요한 크기 계산
       |
2. Arrange Pass
   └─> 각 요소의 최종 위치와 크기 결정
       |
3. Render Pass
   └─> Visual Tree를 Composition Tree로 변환
       |
4. Composition
   └─> milcore에서 렌더링 명령 생성
       |
5. GPU Rendering
   └─> DirectX를 통해 화면에 출력
```
*단계별 상세 설명*: **1단계: Measure Pass**
각 요소가 `MeasureCore()`를 호출하여 필요한 크기를 계산한다.
```csharp
// 간략화된 의사코드
protected override Size MeasureCore(Size availableSize)
{
    // 자식 요소들의 크기 측정
    foreach (var child in Children)
    {
        child.Measure(availableSize);
    }
    // 자신이 필요한 크기 반환
    return new Size(desiredWidth, desiredHeight);
}
```
**2단계: Arrange Pass**
각 요소가 `ArrangeCore()`를 호출하여 최종 위치와 크기를 결정한다.
```csharp
// 간략화된 의사코드
protected override void ArrangeCore(Rect finalRect)
{
    // 자식 요소들 배치
    foreach (var child in Children)
    {
        Rect childRect = CalculateChildRect(finalRect, child);
        child.Arrange(childRect);
    }
}
```
**3단계: Render Pass**
Visual Tree를 순회하며 렌더링 명령을 생성한다.
```csharp
// OnRender() 호출 - 개발자가 오버라이드 가능
protected override void OnRender(DrawingContext dc)
{
    // DrawingContext에 그리기 명령 추가
    dc.DrawRectangle(Brushes.Blue, null, new Rect(0, 0, 100, 100));
    dc.DrawEllipse(Brushes.Red, null, new Point(50, 50), 20, 20);
}
```
**4단계: Composition**
UI 스레드의 Visual Tree를 Render 스레드의 Composition Tree로 변환한다.
```
UI Thread (60 FPS): Render Thread (독립적):
┌────────────┐              ┌────────────────┐
│ Visual Tree│ ─────────>  │ Composition    │
│            │ (비동기 전송) │ Tree           │
│ - Button   │              │ - RenderData   │
│ - TextBox  │              │ - Transforms   │
│ - Canvas   │              │ - Brushes      │
└────────────┘              └────────┬───────┘
                                     │
                                     ↓
                            ┌────────────────┐
                            │ DirectX        │
                            │ Draw Calls     │
                            └────────────────┘
```
**5단계: GPU Rendering**
DirectX를 통해 GPU에서 최종 렌더링을 수행한다.
=== Dirty Region Tracking
WPF는 변경된 영역만 다시 그리는 최적화를 사용한다.
```
Frame N: Frame N+1:
┌────────────────────┐       ┌────────────────────┐
│ ░░░░░░░░░░░░░░░░░  │       │ ░░░░░░░░░░░░░░░░░  │
│ ░░ Button 1 ░░░░░  │       │ ░░ Button 1 ░░░░░  │
│ ░░░░░░░░░░░░░░░░░  │       │ ░░░░░░░░░░░░░░░░░  │
│                    │       │  ┌──────────┐      │ ← Dirty Region
│ ┌──────────┐       │       │  │ Button 2 │      │   (변경된 부분만)
│ │ Button 2 │       │  -->  │  │ (Moved)  │      │
│ └──────────┘       │       │  └──────────┘      │
│                    │       │                    │
│ ░░ Button 3 ░░░░░  │       │ ░░ Button 3 ░░░░░  │
└────────────────────┘       └────────────────────┘
      (불변 영역은 캐시 사용)      (변경 영역만 재렌더링)
```
*최적화 포인트*:
```csharp
// ❌ 나쁜 예: 매 프레임 전체 다시 그리기
protected override void OnRender(DrawingContext dc)
{
    dc.DrawRectangle(Brushes.Blue, null, new Rect(0, 0, ActualWidth, ActualHeight));
    // 전체 영역이 Dirty Region이 됨
}
// ✓ 좋은 예: 캐싱 활용
protected override void OnRender(DrawingContext dc)
{
    // CacheMode 설정으로 정적 콘텐츠 캐싱
    // 변경된 부분만 InvalidateVisual() 호출
}
```
=== Visual vs DrawingVisual
WPF는 두 가지 렌더링 방식을 제공한다: **Visual (일반 컨트롤)**:
- Control 클래스 상속
- Layout, Input, Data Binding 지원
- 높은 수준 API
- 상대적으로 무거움
**DrawingVisual (고성능 렌더링)**:
- Visual 클래스 직접 상속
- Layout, Input 없음 (수동 처리 필요)
- 저수준 API
- 매우 가벼움
*성능 비교*: ```csharp
// 10, 000개 도형 렌더링 성능 비교
// ❌ 느림: Button 10, 000개 (각각 Control)
for (int i = 0; i < 10000; i++)
{
  var button = new Button { Width = 10, Height = 10 };
  canvas.Children.Add(button);
}
// 결과: 렌더링 시간 ~500ms, 메모리 ~200MB
// ✓ 빠름: DrawingVisual 10, 000개
var visuals = new DrawingVisual[10000];
for (int i = 0; i < 10000; i++)
{
  visuals[i] = new DrawingVisual();
  using (var dc = visuals[i].RenderOpen())
  {
  dc.DrawRectangle(Brushes.Blue, null, new Rect(0, 0, 10, 10));
  }
}
// 결과: 렌더링 시간 ~50ms, 메모리 ~20MB (10배 빠름)
```
*반도체 HMI 적용*: ```csharp
// 웨이퍼 맵 (10, 000개 다이 표시)에는 DrawingVisual 사용
public class WaferMapControl : FrameworkElement
{
    private readonly VisualCollection _visuals;
    public WaferMapControl()
    {
        _visuals = new VisualCollection(this);
    }
    public void RenderWaferMap(WaferData waferData)
    {
        _visuals.Clear();
        foreach (var die in waferData.Dies)  // 10, 000+ dies
        {
            var visual = new DrawingVisual();
            using (var dc = visual.RenderOpen())
            {
                var brush = GetDieBrush(die.Status);  // Good/Fail/Unknown
                dc.DrawRectangle(brush, null, new Rect(die.X, die.Y, 2, 2));
            }
            _visuals.Add(visual);
        }
    }
    protected override int VisualChildrenCount => _visuals.Count;
    protected override Visual GetVisualChild(int index) => _visuals[index];
}
```
== Dependency Property 이론 심화
=== Dependency Property 값 결정 우선순위
Dependency Property의 값은 다음 우선순위로 결정된다 (낮은 번호가 높은 우선순위): ```
1. Animation (활성화 중인 애니메이션)
  ↓
2. Local Value (SetValue로 직접 설정한 값)
  ↓
3. Trigger (ControlTemplate, Style의 Trigger)
  ↓
4. TemplatedParent (Template에서 설정한 값)
  ↓
5. Style Setter (Style에서 설정한 값)
  ↓
6. Inherited Value (부모로부터 상속된 값)
  ↓
7. Default Value (PropertyMetadata의 기본값)
```
*예제로 이해하기*: ```csharp
// Dependency Property 정의
public static readonly DependencyProperty ValueProperty =
    DependencyProperty.Register(nameof(Value), typeof(double), typeof(MyControl), new PropertyMetadata(0.0));  // 7. 기본값
// XAML 사용:
<Style TargetType="local: MyControl">
    <Setter Property="Value" Value="50"/>  <!-- 5. Style Setter -->
    <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
            <Setter Property="Value" Value="75"/>  <!-- 3. Trigger -->
        </Trigger>
    </Style.Triggers>
</Style>
<local: MyControl Value="100">  <!-- 2. Local Value -->
    <local: MyControl.Triggers>
        <EventTrigger RoutedEvent="Loaded">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Value"
                                   To="150" Duration="0: 0: 2"/>  <!-- 1. Animation -->
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </local: MyControl.Triggers>
</local: MyControl>
```
*값 결정 과정*:
1. 로드 시: Local Value = 100 (우선순위 2)
2. 애니메이션 시작: Animation = 100→150 (우선순위 1, Local Value 무시)
3. 애니메이션 종료: Local Value = 100 (다시 우선순위 2)
4. Local Value 제거 시: Style Setter = 50 (우선순위 5)
=== Attached Property
Attached Property는 부모 요소에 자식 요소의 정보를 저장하는 특수한 Dependency Property다.
*대표적 예: Grid.Row, Grid.Column*
```csharp
// Grid.RowProperty 정의 (간략화)
public class Grid : Panel
{
    public static readonly DependencyProperty RowProperty =
        DependencyProperty.RegisterAttached("Row", typeof(int), typeof(Grid), new PropertyMetadata(0));
    public static void SetRow(UIElement element, int value)
    {
        element.SetValue(RowProperty, value);
    }
    public static int GetRow(UIElement element)
    {
        return (int)element.GetValue(RowProperty);
    }
}
// 사용:
<Grid>
    <Button Grid.Row="0"/>  <!-- Grid가 아닌 Button에 속성 설정 -->
    <Button Grid.Row="1"/>
</Grid>
```
*Attached Property의 동작 원리*: ```
┌─────────────────────────────┐
│ Grid (Panel) │
│ │
│ ┌─────────────────────┐ │
│ │ Button │  │
│ │ Properties: │ │
│ │ - Content = "OK" │  │
│ │ - Grid.Row = 0 ←───┼───┼── Attached Property
│ └─────────────────────┘ │  (Grid의 속성이지만 Button에 저장)
│ │
│ ┌─────────────────────┐ │
│ │ Button │  │
│ │ Properties: │ │
│ │ - Content = "Cancel"│ │
│ │ - Grid.Row = 1 ←───┼───┼── Grid가 ArrangeOverride에서
│ └─────────────────────┘ │  이 값을 읽어 배치
└─────────────────────────────┘
```
*커스텀 Attached Property 예제*: ```csharp
// 반도체 HMI: 알람 레벨을 Border에 설정
public static class AlarmProperties
{
    public static readonly DependencyProperty LevelProperty =
        DependencyProperty.RegisterAttached("Level", typeof(AlarmLevel), typeof(AlarmProperties), new PropertyMetadata(AlarmLevel.Normal, OnLevelChanged));
    public static void SetLevel(DependencyObject obj, AlarmLevel value)
    {
        obj.SetValue(LevelProperty, value);
    }
    public static AlarmLevel GetLevel(DependencyObject obj)
    {
        return (AlarmLevel)obj.GetValue(LevelProperty);
    }
    private static void OnLevelChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is Border border)
        {
            var level = (AlarmLevel)e.NewValue;
            border.BorderBrush = level switch
            {
                AlarmLevel.Critical => Brushes.Red, AlarmLevel.Warning => Brushes.Yellow, AlarmLevel.Normal => Brushes.Green, _ => Brushes.Gray
            };
            border.BorderThickness = level == AlarmLevel.Critical ? new Thickness(3) : new Thickness(1);
        }
    }
}
public enum AlarmLevel { Normal, Warning, Critical }
// XAML 사용:
<Border local: AlarmProperties.Level="Critical">
    <TextBlock Text="High Temperature"/>
</Border>
```
=== Dependency Property 메모리 최적화
Dependency Property는 기본값을 공유하여 메모리를 절약한다.
*일반 Property (메모리 비효율)*: ```csharp
// ❌ 10, 000개 Button → 10, 000개 _background 필드 (각 8 bytes)
public class NormalButton
{
  private Brush _background = Brushes.LightGray; // 모든 인스턴스가 메모리 사용
  public Brush Background
  {
  get => _background;
  set => _background = value;
  }
}
// 10, 000개 버튼 = 10, 000 × 8 bytes = 80 KB (배경색만)
```
*Dependency Property (메모리 효율)*: ```csharp
// ✓ 10, 000개 Button → 1개 공유 기본값
public class DependencyButton : DependencyObject
{
    public static readonly DependencyProperty BackgroundProperty =
        DependencyProperty.Register(nameof(Background), typeof(Brush), typeof(DependencyButton), new PropertyMetadata(Brushes.LightGray));  // 공유 기본값
    public Brush Background
    {
        get => (Brush)GetValue(BackgroundProperty);
        set => SetValue(BackgroundProperty, value);
    }
}
// 10, 000개 버튼이 모두 기본값 사용 시 = 8 bytes (공유)
// 일부만 값 변경 시 = 8 bytes (공유) + n × 8 bytes (변경된 버튼만)
```
*내부 구조*: ```
DependencyObject 인스턴스:
┌────────────────────────┐
│ _effectiveValues │ ← null (기본값만 사용 시)
│ │  또는
│ │  Dictionary (값 변경 시만 생성)
└────────────────────────┘
공유 기본값:
┌────────────────────────────────────┐
│ BackgroundProperty.DefaultMetadata │
│ - DefaultValue = Brushes.LightGray │ ← 모든 인스턴스가 공유
└────────────────────────────────────┘
```
=== Property Changed Callback vs CoerceValue
Dependency Property는 값 변경 시 두 가지 콜백을 제공한다: **1. PropertyChangedCallback**: 값이 변경된 **후** 호출
```csharp
new PropertyMetadata(0.0, OnValueChanged)
private static void OnValueChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
{
  if (d is GaugeControl gauge)
  {
  double oldValue = (double)e.OldValue;
  double newValue = (double)e.NewValue;
  // UI 업데이트, 로깅, 이벤트 발생 등
  gauge.InvalidateVisual();
  gauge.ValueChangedEvent?.Invoke(gauge, newValue);
  }
}
```
**2. CoerceValueCallback**: 값 설정 **전** 강제 조정
```csharp
new PropertyMetadata(0.0, OnValueChanged, CoerceValue)
private static object CoerceValue(DependencyObject d, object baseValue)
{
  if (d is GaugeControl gauge)
  {
  double value = (double)baseValue;
  // Minimum과 Maximum 범위로 제한
  value = Math.Max(gauge.Minimum, value);
  value = Math.Min(gauge.Maximum, value);
  return value;
  }
  return baseValue;
}
// 사용:
gauge.Value = 999; // Maximum이 100이면
  // CoerceValue가 100으로 조정
  // OnValueChanged에는 100이 전달됨
```
*실행 순서*: ```
SetValue(ValueProperty, 999)
    ↓
1. CoerceValue(d, 999) → 100 반환 (범위 제한)
    ↓
2. 기존 값과 비교 (50 vs 100)
    ↓
3. OnValueChanged(d, new: 100, old: 50) 호출
    ↓
4. InvalidateVisual() → 화면 갱신
```
*반도체 HMI 예제*: ```csharp
// 센서 값이 항상 유효 범위 내에 있도록 보장
public static readonly DependencyProperty SensorValueProperty =
  DependencyProperty.Register(nameof(SensorValue), typeof(double), typeof(SensorDisplay), new PropertyMetadata(0.0, OnSensorValueChanged, CoerceSensorValue), ValidateSensorValue); // 추가 검증 (선택)
private static object CoerceSensorValue(DependencyObject d, object baseValue)
{
  var display = (SensorDisplay)d;
  double value = (double)baseValue;
  // 1. 범위 제한
  value = Math.Clamp(value, display.MinValue, display.MaxValue);
  // 2. 정밀도 제한 (소수점 2자리)
  value = Math.Round(value, 2);
  return value;
}
private static bool ValidateSensorValue(object value)
{
  // NaN, Infinity 거부
  double d = (double)value;
  return !double.IsNaN(d) && !double.IsInfinity(d);
}
```
== 이론: WPF Control 아키텍처
=== Control 클래스 계층
```
DependencyObject
└── Visual
  └── UIElement (입력 처리)
  └── FrameworkElement (레이아웃)
  └── Control (템플릿 지원)
  ├── ContentControl (단일 콘텐츠)
  │  ├── Button
  │  ├── Label
  │  └── Window
  ├── ItemsControl (컬렉션)
  │  ├── ListBox
  │  ├── ComboBox
  │  └── TabControl
  └── UserControl (사용자 정의)
```
=== Template 시스템
*ControlTemplate*: 컨트롤의 시각적 구조
```xml
<ControlTemplate TargetType="Button">
  <Border Background="{TemplateBinding Background}"
  BorderBrush="{TemplateBinding BorderBrush}">
  <ContentPresenter HorizontalAlignment="Center"
  VerticalAlignment="Center"/>
  </Border>
</ControlTemplate>
```
*DataTemplate*: 데이터의 시각적 표현
```xml
<DataTemplate DataType="{x: Type local: SensorData}">
  <StackPanel>
  <TextBlock Text="{Binding Temperature}"/>
  <TextBlock Text="{Binding Pressure}"/>
  </StackPanel>
</DataTemplate>
```
=== Visual State Manager
컨트롤의 상태 관리:
```xml
<VisualStateManager.VisualStateGroups>
  <VisualStateGroup Name="CommonStates">
  <VisualState Name="Normal"/>
  <VisualState Name="MouseOver">
  <Storyboard>
  <ColorAnimation Storyboard.TargetName="border"
  Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)"
  To="LightBlue" Duration="0: 0: 0.2"/>
  </Storyboard>
  </VisualState>
  <VisualState Name="Pressed">
  <Storyboard>
  <ColorAnimation To="DarkBlue" Duration="0: 0: 0.1"/>
  </Storyboard>
  </VisualState>
  </VisualStateGroup>
</VisualStateManager.VisualStateGroups>
```
== 응용: 디자인 패턴
=== Template Method Pattern
Control의 OnRender를 오버라이드하여 커스텀 그리기: ```csharp
public class CustomGauge : Control
{
    protected override void OnRender(DrawingContext drawingContext)
    {
        base.OnRender(drawingContext);
        // 1. 배경 그리기
        DrawBackground(drawingContext);
        // 2. 눈금 그리기
        DrawScale(drawingContext);
        // 3. 바늘 그리기
        DrawNeedle(drawingContext);
        // 4. 중심점 그리기
        DrawCenter(drawingContext);
    }
    protected virtual void DrawBackground(DrawingContext dc)
    {
        dc.DrawEllipse(Brushes.LightGray, null, new Point(ActualWidth / 2, ActualHeight / 2), ActualWidth / 2 - 10, ActualHeight / 2 - 10);
    }
    protected virtual void DrawScale(DrawingContext dc)
    {
        // 눈금 구현
    }
    protected virtual void DrawNeedle(DrawingContext dc)
    {
        // 바늘 구현
    }
    protected virtual void DrawCenter(DrawingContext dc)
    {
        // 중심점 구현
    }
}
```
*장점*:
- 알고리즘 골격 정의
- 하위 클래스에서 단계별 커스터마이징
- 코드 재사용성
=== Composite Pattern
TreeView는 Composite 패턴의 전형적 예: ```csharp
// Component
public abstract class EquipmentNode
{
  public string Name { get; set; } = string.Empty;
  public abstract void Accept(IEquipmentVisitor visitor);
}
// Composite
public class EquipmentGroup : EquipmentNode
{
  public List<EquipmentNode> Children { get; } = new();
  public override void Accept(IEquipmentVisitor visitor)
  {
  visitor.VisitGroup(this);
  foreach (var child in Children)
  {
  child.Accept(visitor);
  }
  }
}
// Leaf
public class Equipment : EquipmentNode
{
  public EquipmentType Type { get; set; }
  public EquipmentStatus Status { get; set; }
  public override void Accept(IEquipmentVisitor visitor)
  {
  visitor.VisitEquipment(this);
  }
}
// Visitor
public interface IEquipmentVisitor
{
  void VisitGroup(EquipmentGroup group);
  void VisitEquipment(Equipment equipment);
}
// Concrete Visitor
public class AlarmCountVisitor : IEquipmentVisitor
{
  public int AlarmCount { get; private set; }
  public void VisitGroup(EquipmentGroup group)
  {
  // 그룹은 스킵
  }
  public void VisitEquipment(Equipment equipment)
  {
  if (equipment.Status == EquipmentStatus.Alarm)
  AlarmCount++;
  }
}
```
*사용*:
```csharp
var root = new EquipmentGroup { Name = "FAB1" };
root.Children.Add(new EquipmentGroup
{
  Name = "CVD", Children =
  {
  new Equipment { Name = "CVD-01", Status = EquipmentStatus.Running }, new Equipment { Name = "CVD-02", Status = EquipmentStatus.Alarm }
  }
});
var visitor = new AlarmCountVisitor();
root.Accept(visitor);
Console.WriteLine($"Total Alarms: {visitor.AlarmCount}");
```
=== Strategy Pattern
Value Converter는 Strategy 패턴: ```csharp
// Strategy Interface
public interface IValueConversionStrategy
{
    object Convert(object value);
}
// Concrete Strategies
public class TemperatureToColorStrategy : IValueConversionStrategy
{
    public object Convert(object value)
    {
        if (value is double temp)
        {
            return temp switch
            {
                > 500 => Brushes.Red, > 450 => Brushes.Orange, > 400 => Brushes.Yellow, _ => Brushes.Green
            };
        }
        return Brushes.Gray;
    }
}
public class PressureToColorStrategy : IValueConversionStrategy
{
    public object Convert(object value)
    {
        if (value is double pressure)
        {
            return pressure switch
            {
                > 3.0 => Brushes.Red, > 2.5 => Brushes.Yellow, _ => Brushes.Green
            };
        }
        return Brushes.Gray;
    }
}
// Context
public class ConfigurableConverter : IValueConverter
{
    public IValueConversionStrategy? Strategy { get; set; }
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return Strategy?.Convert(value) ?? Brushes.Gray;
    }
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
```
*XAML 사용*:
```xml
<Window.Resources>
    <local: ConfigurableConverter x: Key="TempConverter">
        <local: ConfigurableConverter.Strategy>
            <local: TemperatureToColorStrategy/>
        </local: ConfigurableConverter.Strategy>
    </local: ConfigurableConverter>
</Window.Resources>
<Border Background="{Binding Temperature, Converter={StaticResource TempConverter}}"/>
```
== 완전한 실행 가능한 예제: 커스텀 Gauge 컨트롤
=== 요구사항
+ 반도체 장비 파라미터를 게이지로 표시
+ 최소/최대값 설정
+ 경고/위험 범위 시각화
+ 값 변경 시 애니메이션
+ 완전히 실행 가능한 WPF 프로젝트
=== CustomGauge.cs
```csharp
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
namespace AdvancedHMI.Controls
{
    public class GaugeControl : Control
    {
        static GaugeControl()
        {
            DefaultStyleKeyProperty.OverrideMetadata(typeof(GaugeControl), new FrameworkPropertyMetadata(typeof(GaugeControl)));
        }
        #region Dependency Properties
        public static readonly DependencyProperty ValueProperty =
            DependencyProperty.Register(nameof(Value), typeof(double), typeof(GaugeControl), new PropertyMetadata(0.0, OnValueChanged));
        public double Value
        {
            get => (double)GetValue(ValueProperty);
            set => SetValue(ValueProperty, value);
        }
        public static readonly DependencyProperty MinimumProperty =
            DependencyProperty.Register(nameof(Minimum), typeof(double), typeof(GaugeControl), new PropertyMetadata(0.0, OnRangeChanged));
        public double Minimum
        {
            get => (double)GetValue(MinimumProperty);
            set => SetValue(MinimumProperty, value);
        }
        public static readonly DependencyProperty MaximumProperty =
            DependencyProperty.Register(nameof(Maximum), typeof(double), typeof(GaugeControl), new PropertyMetadata(100.0, OnRangeChanged));
        public double Maximum
        {
            get => (double)GetValue(MaximumProperty);
            set => SetValue(MaximumProperty, value);
        }
        public static readonly DependencyProperty WarningThresholdProperty =
            DependencyProperty.Register(nameof(WarningThreshold), typeof(double), typeof(GaugeControl), new PropertyMetadata(75.0));
        public double WarningThreshold
        {
            get => (double)GetValue(WarningThresholdProperty);
            set => SetValue(WarningThresholdProperty, value);
        }
        public static readonly DependencyProperty CriticalThresholdProperty =
            DependencyProperty.Register(nameof(CriticalThreshold), typeof(double), typeof(GaugeControl), new PropertyMetadata(90.0));
        public double CriticalThreshold
        {
            get => (double)GetValue(CriticalThresholdProperty);
            set => SetValue(CriticalThresholdProperty, value);
        }
        public static readonly DependencyProperty TitleProperty =
            DependencyProperty.Register(nameof(Title), typeof(string), typeof(GaugeControl), new PropertyMetadata("Value"));
        public string Title
        {
            get => (string)GetValue(TitleProperty);
            set => SetValue(TitleProperty, value);
        }
        public static readonly DependencyProperty UnitProperty =
            DependencyProperty.Register(nameof(Unit), typeof(string), typeof(GaugeControl), new PropertyMetadata(""));
        public string Unit
        {
            get => (string)GetValue(UnitProperty);
            set => SetValue(UnitProperty, value);
        }
        #endregion
        private static void OnValueChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is GaugeControl gauge)
            {
                gauge.InvalidateVisual();
            }
        }
        private static void OnRangeChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is GaugeControl gauge)
            {
                gauge.InvalidateVisual();
            }
        }
        protected override void OnRender(DrawingContext drawingContext)
        {
            base.OnRender(drawingContext);
            double centerX = ActualWidth / 2;
            double centerY = ActualHeight * 0.75;
            double radius = Math.Min(ActualWidth, ActualHeight) * 0.35;
            // 배경 호
            DrawArc(drawingContext, centerX, centerY, radius, -225, -45, Brushes.LightGray, 15);
            // 정상 범위 (초록)
            double normalEnd = Math.Min(WarningThreshold, Maximum);
            double normalAngle = ValueToAngle(normalEnd);
            DrawArc(drawingContext, centerX, centerY, radius, -225, normalAngle, Brushes.LightGreen, 12);
            // 경고 범위 (노랑)
            if (WarningThreshold < Maximum)
            {
                double warningEnd = Math.Min(CriticalThreshold, Maximum);
                double warningAngle = ValueToAngle(warningEnd);
                DrawArc(drawingContext, centerX, centerY, radius, normalAngle, warningAngle, Brushes.Yellow, 12);
            }
            // 위험 범위 (빨강)
            if (CriticalThreshold < Maximum)
            {
                double criticalAngle = ValueToAngle(Maximum);
                DrawArc(drawingContext, centerX, centerY, radius, ValueToAngle(CriticalThreshold), criticalAngle, Brushes.Red, 12);
            }
            // 눈금
            DrawScale(drawingContext, centerX, centerY, radius);
            // 바늘
            DrawNeedle(drawingContext, centerX, centerY, radius);
            // 중심점
            drawingContext.DrawEllipse(Brushes.DarkGray, null, new Point(centerX, centerY), 8, 8);
            // 값 텍스트
            var formattedText = new FormattedText($"{Value: F1} {Unit}", System.Globalization.CultureInfo.CurrentCulture, FlowDirection.LeftToRight, new Typeface("Arial"), 20, Brushes.Black, VisualTreeHelper.GetDpi(this).PixelsPerDip);
            drawingContext.DrawText(formattedText, new Point(centerX - formattedText.Width / 2, centerY + radius * 0.5));
            // 제목
            var titleText = new FormattedText(Title, System.Globalization.CultureInfo.CurrentCulture, FlowDirection.LeftToRight, new Typeface("Arial"), 14, Brushes.DarkGray, VisualTreeHelper.GetDpi(this).PixelsPerDip);
            drawingContext.DrawText(titleText, new Point(centerX - titleText.Width / 2, 10));
        }
        private void DrawArc(DrawingContext dc, double centerX, double centerY, double radius, double startAngle, double endAngle, Brush brush, double thickness)
        {
            if (endAngle <= startAngle) return;
            var startRad = startAngle * Math.PI / 180;
            var endRad = endAngle * Math.PI / 180;
            var startPoint = new Point(centerX + radius * Math.Cos(startRad), centerY + radius * Math.Sin(startRad));
            var endPoint = new Point(centerX + radius * Math.Cos(endRad), centerY + radius * Math.Sin(endRad));
            bool isLargeArc = (endAngle - startAngle) > 180;
            var figure = new PathFigure { StartPoint = startPoint };
            figure.Segments.Add(new ArcSegment(endPoint, new Size(radius, radius), 0, isLargeArc, SweepDirection.Clockwise, true));
            var geometry = new PathGeometry();
            geometry.Figures.Add(figure);
            dc.DrawGeometry(null, new Pen(brush, thickness), geometry);
        }
        private void DrawScale(DrawingContext dc, double centerX, double centerY, double radius)
        {
            int tickCount = 11;
            for (int i = 0; i < tickCount; i++)
            {
                double value = Minimum + (Maximum - Minimum) * i / (tickCount - 1);
                double angle = ValueToAngle(value);
                double angleRad = angle * Math.PI / 180;
                double x1 = centerX + (radius - 20) * Math.Cos(angleRad);
                double y1 = centerY + (radius - 20) * Math.Sin(angleRad);
                double x2 = centerX + (radius - 10) * Math.Cos(angleRad);
                double y2 = centerY + (radius - 10) * Math.Sin(angleRad);
                dc.DrawLine(new Pen(Brushes.Black, 2), new Point(x1, y1), new Point(x2, y2));
                // 숫자 레이블
                var text = new FormattedText($"{value: F0}", System.Globalization.CultureInfo.CurrentCulture, FlowDirection.LeftToRight, new Typeface("Arial"), 10, Brushes.Black, VisualTreeHelper.GetDpi(this).PixelsPerDip);
                double textX = centerX + (radius - 35) * Math.Cos(angleRad) - text.Width / 2;
                double textY = centerY + (radius - 35) * Math.Sin(angleRad) - text.Height / 2;
                dc.DrawText(text, new Point(textX, textY));
            }
        }
        private void DrawNeedle(DrawingContext dc, double centerX, double centerY, double radius)
        {
            double angle = ValueToAngle(Value);
            double angleRad = angle * Math.PI / 180;
            double tipX = centerX + (radius - 15) * Math.Cos(angleRad);
            double tipY = centerY + (radius - 15) * Math.Sin(angleRad);
            var needleColor = Value switch
            {
                var v when v >= CriticalThreshold => Brushes.Red, var v when v >= WarningThreshold => Brushes.Orange, _ => Brushes.Green
            };
            dc.DrawLine(new Pen(needleColor, 3), new Point(centerX, centerY), new Point(tipX, tipY));
        }
        private double ValueToAngle(double value)
        {
            double normalized = (value - Minimum) / (Maximum - Minimum);
            normalized = Math.Clamp(normalized, 0, 1);
            return -225 + normalized * 180;  // -225도 ~ -45도 (180도 범위)
        }
    }
}
```
=== MainWindow.xaml
```xml
<Window x: Class="AdvancedHMI.MainWindow"
        xmlns="http: //schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns: x="http: //schemas.microsoft.com/winfx/2006/xaml"
        xmlns: local="clr-namespace: AdvancedHMI.Controls"
        xmlns: vm="clr-namespace: AdvancedHMI.ViewModels"
        Title="Advanced HMI - Custom Gauge" Height="600" Width="900">
    \<Window.DataContext>
        \<vm: MainViewModel/>
    \</Window.DataContext>
    \<Grid Margin="20">
        \<Grid.RowDefinitions>
            \<RowDefinition Height="Auto"/>
            \<RowDefinition Height="*"/>
            \<RowDefinition Height="Auto"/>
        \</Grid.RowDefinitions>
        \<!-- Header -->
        \<TextBlock Grid.Row="0" Text="Semiconductor Equipment Monitoring"
                   FontSize="24" FontWeight="Bold" Margin="0, 0, 0, 20"/>
        \<!-- Gauges -->
        \<UniformGrid Grid.Row="1" Columns="3" Rows="1">
            \<!-- Temperature Gauge -->
            \<local: GaugeControl Value="{Binding Temperature}"
                               Minimum="0" Maximum="600"
                               WarningThreshold="480"
                               CriticalThreshold="520"
                               Title="Temperature"
                               Unit="°C"
                               Margin="10"/>
            \<!-- Pressure Gauge -->
            \<local: GaugeControl Value="{Binding Pressure}"
                               Minimum="0" Maximum="5"
                               WarningThreshold="3.0"
                               CriticalThreshold="3.5"
                               Title="Pressure"
                               Unit="Torr"
                               Margin="10"/>
            \<!-- Flow Rate Gauge -->
            \<local: GaugeControl Value="{Binding FlowRate}"
                               Minimum="0" Maximum="200"
                               WarningThreshold="150"
                               CriticalThreshold="180"
                               Title="Flow Rate"
                               Unit="sccm"
                               Margin="10"/>
        \</UniformGrid>
        \<!-- Controls -->
        \<StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center">
            \<Button Content="Start Monitoring" Command="{Binding StartCommand}"
                   Width="150" Height="40" Margin="5"/>
            \<Button Content="Stop Monitoring" Command="{Binding StopCommand}"
                   Width="150" Height="40" Margin="5"/>
            \<Button Content="Reset" Command="{Binding ResetCommand}"
                   Width="100" Height="40" Margin="5"/>
        \</StackPanel>
    \</Grid>
</Window>
```
=== MainViewModel.cs
```csharp
using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using System.Windows.Threading;
namespace AdvancedHMI.ViewModels
{
    public class MainViewModel : INotifyPropertyChanged
    {
        private readonly DispatcherTimer _timer;
        private readonly Random _random = new();
        private double _temperature = 300;
        private double _pressure = 2.0;
        private double _flowRate = 100;
        private bool _isMonitoring;
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
        public ICommand ResetCommand { get; }
        public MainViewModel()
        {
            _timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
            _timer.Tick += OnTimerTick;
            StartCommand = new RelayCommand(_ => Start(), _ => !IsMonitoring);
            StopCommand = new RelayCommand(_ => Stop(), _ => IsMonitoring);
            ResetCommand = new RelayCommand(_ => Reset(), _ => !IsMonitoring);
        }
        private void Start()
        {
            IsMonitoring = true;
            _timer.Start();
        }
        private void Stop()
        {
            IsMonitoring = false;
            _timer.Stop();
        }
        private void Reset()
        {
            Temperature = 300;
            Pressure = 2.0;
            FlowRate = 100;
        }
        private void OnTimerTick(object? sender, EventArgs e)
        {
            // 랜덤 워크 시뮬레이션
            Temperature += _random.NextDouble() * 10 - 5;
            Pressure += _random.NextDouble() * 0.2 - 0.1;
            FlowRate += _random.NextDouble() * 10 - 5;
            // 범위 제한
            Temperature = Math.Clamp(Temperature, 0, 600);
            Pressure = Math.Clamp(Pressure, 0, 5);
            FlowRate = Math.Clamp(FlowRate, 0, 200);
        }
        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
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
*실행 방법*:
1. Visual Studio 2022에서 새 WPF App (.NET 8.0) 프로젝트 생성
2. Controls/, ViewModels/ 폴더 생성
3. GaugeControl.cs, MainViewModel.cs, MainWindow.xaml 파일 생성
4. F5로 실행
5. "Start Monitoring" 버튼 클릭
*기능*:
- 3개 게이지 동시 모니터링 (온도, 압력, 유량)
- 경고/위험 범위 색상 구분
- 바늘 색상 자동 변경
- 실시간 값 업데이트 (500ms 주기)
- 완전히 커스터마이징 가능한 게이지
== MCQ (Multiple Choice Questions)
=== 문제 1: Visual Tree vs Logical Tree (기초)
Logical Tree에 포함되지만 Visual Tree에는 포함되지 않는 것은?
A. Button의 ContentPresenter \
B. XAML에서 정의한 Grid \
C. 없음 (Logical Tree는 Visual Tree의 부분집합) \
D. Window의 Border Chrome
*정답: C*
*해설*: Logical Tree는 XAML에서 정의한 요소만 포함하고, Visual Tree는 Template에서 정의한 내부 요소까지 포함한다. 따라서 Logical Tree는 Visual Tree의 부분집합이다.
---
=== 문제 2: Dependency Property (기초)
Dependency Property의 장점이 아닌 것은?
A. 데이터 바인딩 지원 \
B. 메모리 효율적 \
C. 코드 작성이 간단함 \
D. 애니메이션 지원
*정답: C*
*해설*: Dependency Property는 많은 기능을 제공하지만, 일반 Property보다 코드가 복잡하다 (DependencyProperty.Register 등).
---
=== 문제 3: ControlTemplate (중급)
ControlTemplate에서 원본 컨트롤의 속성을 참조하려면?
A. `{Binding Property}` \
B. `{TemplateBinding Property}` \
C. `{StaticResource Property}` \
D. `{DynamicResource Property}`
*정답: B*
*해설*: TemplateBinding은 Template 내에서 원본 컨트롤의 속성에 접근하는 특수 바인딩이다.
---
=== 문제 4: Template Method Pattern (중급)
다음 중 Template Method Pattern의 핵심 개념은?
A. 데이터 템플릿 정의 \
B. 알고리즘 골격은 상위 클래스, 세부 구현은 하위 클래스 \
C. UI 템플릿 재사용 \
D. 싱글톤 보장
*정답: B*
*해설*: Template Method Pattern은 알고리즘의 골격을 정의하고, 세부 단계는 하위 클래스에서 구현하도록 하는 패턴이다.
---
=== 문제 5: Composite Pattern (중급)
TreeView가 Composite Pattern을 사용하는 이유는?
A. 메모리 절약 \
B. 트리 구조의 재귀적 특성 표현 \
C. 빠른 검색 \
D. UI 테마 변경
*정답: B*
*해설*: Composite Pattern은 부분-전체 계층을 표현하며, TreeView는 노드와 리프를 동일하게 처리할 수 있다.
---
=== 문제 6: 코드 분석 - OnRender (고급)
다음 코드에서 InvalidateVisual()의 역할은?
```csharp
private static void OnValueChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
{
    if (d is GaugeControl gauge)
    {
        gauge.InvalidateVisual();
    }
}
```
A. Visual Tree 재구성 \
B. OnRender() 재호출 요청 \
C. 데이터 바인딩 갱신 \
D. 메모리 해제
*정답: B*
*해설*: InvalidateVisual()은 컨트롤이 다시 그려져야 함을 WPF에 알리고, 다음 렌더링 사이클에 OnRender()가 호출된다.
---
=== 문제 7: Strategy Pattern (고급)
Value Converter에서 Strategy Pattern을 사용하는 장점은?
A. 빠른 실행 속도 \
B. 변환 로직을 런타임에 교체 가능 \
C. 메모리 절약 \
D. UI 스레드 분리
*정답: B*
*해설*: Strategy Pattern은 알고리즘 군을 정의하고 런타임에 교체할 수 있게 한다. Value Converter의 Strategy를 바꾸면 변환 로직이 바뀐다.
---
=== 문제 8: DependencyProperty.Register (고급)
다음 코드의 PropertyMetadata(0.0)의 의미는?
```csharp
DependencyProperty.Register(nameof(Value), typeof(double), typeof(GaugeControl), new PropertyMetadata(0.0));
```
A. 최소값 \
B. 최대값 \
C. 기본값 \
D. 변경 콜백
*정답: C*
*해설*: PropertyMetadata의 첫 번째 인자는 기본값(default value)이다. 속성이 명시적으로 설정되지 않으면 이 값이 사용된다.
---
=== 문제 9: Visual Tree 탐색 (고급)
VisualTreeHelper.GetChildrenCount()가 0을 반환하는 경우는?
A. Template이 적용되지 않음 \
B. 자식 요소가 없음 \
C. A 또는 B \
D. 절대 0을 반환하지 않음
*정답: C*
*해설*: Template이 아직 적용되지 않았거나 (OnApplyTemplate 이전), 실제로 자식 요소가 없는 경우 0을 반환한다.
---
=== 문제 10: 커스텀 컨트롤 설계 (도전)
반도체 HMI에서 커스텀 게이지 컨트롤을 만들 때 가장 중요한 원칙은?
A. 화려한 애니메이션 \
B. 데이터 범위를 시각적으로 명확히 구분 (정상/경고/위험) \
C. 3D 효과 \
D. 많은 기능
*정답: B*
*해설*: 반도체 HMI에서는 안전이 최우선이다. 운영자가 정상/경고/위험 상태를 즉시 파악할 수 있도록 색상과 범위를 명확히 구분해야 한다.
== 추가 학습 자료
=== 공식 문서
- *WPF Graphics and Multimedia*: https: //learn.microsoft.com/en-us/dotnet/desktop/wpf/graphics-multimedia/
- *Custom Controls*: https: //learn.microsoft.com/en-us/dotnet/desktop/wpf/controls/control-authoring-overview
- *Dependency Properties*: https: //learn.microsoft.com/en-us/dotnet/desktop/wpf/advanced/dependency-properties-overview
=== 참고 서적
- "Pro WPF 4.5 in C#" by Matthew MacDonald (Chapter 15: Custom Controls)
- "WPF Control Development Unleashed" by Pavan Podila
- "Design Patterns" by Gang of Four (Template Method, Composite, Strategy)
== 요약
이번 챕터에서는 C\# 고급 UI 컨트롤을 학습했다: *이론 (Theory): *
- WPF Control 아키텍처: Visual Tree vs Logical Tree
- Dependency Property 시스템
- Control 클래스 계층
- Template 시스템 (ControlTemplate, DataTemplate)
- Visual State Manager
*응용 (Application): *
- Template Method Pattern (OnRender 오버라이드)
- Composite Pattern (TreeView, 장비 계층 구조)
- Strategy Pattern (Value Converter)
- 완전한 실행 가능한 커스텀 Gauge 컨트롤
*성찰 (Reflections): *
- MCQ 10문제: Visual Tree, Dependency Property, 디자인 패턴
*핵심 포인트: *
1. Visual Tree는 실제 렌더링되는 모든 요소를 포함
2. Dependency Property는 데이터 바인딩, 애니메이션 등을 지원
3. 디자인 패턴을 적용하여 유지보수 가능한 UI 개발
4. 커스텀 컨트롤은 OnRender를 오버라이드하여 완전히 커스터마이징
다음 챕터에서는 C\# 테스트 및 배포를 학습한다.
#pagebreak()