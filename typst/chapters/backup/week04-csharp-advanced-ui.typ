= Week 4: C\# WPF 고급 UI 컨트롤 및 커스텀 컨트롤

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ 고급 WPF 컨트롤 활용
+ 커스텀 컨트롤 개발
+ 스타일과 템플릿
+ 애니메이션 구현

== 고급 WPF 컨트롤

=== DataGrid

반도체 공정 데이터를 테이블 형태로 표시:

```xml
<DataGrid ItemsSource="{Binding ProcessRecords}"
          AutoGenerateColumns="False"
          IsReadOnly="True">
    \<DataGrid.Columns>
        \<DataGridTextColumn Header="Timestamp"
                            Binding="{Binding Timestamp}"/>
        \<DataGridTextColumn Header="Temperature"
                            Binding="{Binding Temperature, StringFormat=F1}"/>
        \<DataGridTextColumn Header="Pressure"
                            Binding="{Binding Pressure, StringFormat=F2}"/>
    \</DataGrid.Columns>
</DataGrid>
```

=== TreeView

장비 계층 구조 표시:

```xml
<TreeView ItemsSource="{Binding EquipmentTree}">
    \<TreeView.ItemTemplate>
        \<HierarchicalDataTemplate ItemsSource="{Binding Children}">
            \<TextBlock Text="{Binding Name}"/>
        \</HierarchicalDataTemplate>
    \</TreeView.ItemTemplate>
</TreeView>
```

=== TabControl

다중 장비 모니터링:

```xml
<TabControl ItemsSource="{Binding Equipments}">
    \<TabControl.ItemTemplate>
        \<DataTemplate>
            \<TextBlock Text="{Binding Name}"/>
        \</DataTemplate>
    \</TabControl.ItemTemplate>
    \<TabControl.ContentTemplate>
        \<DataTemplate>
            \<local:EquipmentView DataContext="{Binding}"/>
        \</DataTemplate>
    \</TabControl.ContentTemplate>
</TabControl>
```

== 커스텀 컨트롤

=== Gauge 컨트롤

반도체 파라미터를 게이지로 표시:

```csharp
public class GaugeControl : Control
{
    public static readonly DependencyProperty ValueProperty =
        DependencyProperty.Register(
            nameof(Value),
            typeof(double),
            typeof(GaugeControl),
            new PropertyMetadata(0.0, OnValueChanged));

    public double Value
    {
        get => (double)GetValue(ValueProperty);
        set => SetValue(ValueProperty, value);
    }

    public static readonly DependencyProperty MinimumProperty =
        DependencyProperty.Register(nameof(Minimum), typeof(double),
            typeof(GaugeControl), new PropertyMetadata(0.0));

    public double Minimum
    {
        get => (double)GetValue(MinimumProperty);
        set => SetValue(MinimumProperty, value);
    }

    public static readonly DependencyProperty MaximumProperty =
        DependencyProperty.Register(nameof(Maximum), typeof(double),
            typeof(GaugeControl), new PropertyMetadata(100.0));

    public double Maximum
    {
        get => (double)GetValue(MaximumProperty);
        set => SetValue(MaximumProperty, value);
    }

    private static void OnValueChanged(DependencyObject d,
        DependencyPropertyChangedEventArgs e)
    {
        var control = (GaugeControl)d;
        control.UpdateNeedle();
    }

    private void UpdateNeedle()
    {
        // 바늘 각도 계산 및 업데이트
        var angle = (Value - Minimum) / (Maximum - Minimum) * 270 - 135;
        // RotateTransform 업데이트
    }
}
```

=== LED 인디케이터

장비 상태 표시:

```csharp
public class LedIndicator : Control
{
    public static readonly DependencyProperty IsOnProperty =
        DependencyProperty.Register(
            nameof(IsOn),
            typeof(bool),
            typeof(LedIndicator),
            new PropertyMetadata(false));

    public bool IsOn
    {
        get => (bool)GetValue(IsOnProperty);
        set => SetValue(IsOnProperty, value);
    }

    public static readonly DependencyProperty ColorProperty =
        DependencyProperty.Register(
            nameof(Color),
            typeof(Brush),
            typeof(LedIndicator),
            new PropertyMetadata(Brushes.Green));

    public Brush Color
    {
        get => (Brush)GetValue(ColorProperty);
        set => SetValue(ColorProperty, value);
    }
}
```

== 스타일과 템플릿

=== 스타일 정의

```xml
<Style x:Key="EquipmentButtonStyle" TargetType="Button">
    \<Setter Property="Background" value="#3498db"/>
    \<Setter Property="Foreground" Value="White"/>
    \<Setter Property="Padding" Value="15,8"/>
    \<Setter Property="FontSize" Value="14"/>
    \<Setter Property="BorderThickness" Value="0"/>
    \<Setter Property="Cursor" Value="Hand"/>
    \<Style.Triggers>
        \<Trigger Property="IsMouseOver" Value="True">
            \<Setter Property="Background" Value="#2980b9"/>
        \</Trigger>
        \<Trigger Property="IsPressed" Value="True">
            \<Setter Property="Background" Value="#21618c"/>
        \</Trigger>
    \</Style.Triggers>
</Style>
```

=== 컨트롤 템플릿

```xml
<ControlTemplate x:Key="RoundButtonTemplate" TargetType="Button">
    \<Grid>
        \<Ellipse Fill="{TemplateBinding Background}"
                 Stroke="{TemplateBinding BorderBrush}"
                 StrokeThickness="{TemplateBinding BorderThickness}"/>
        \<ContentPresenter HorizontalAlignment="Center"
                          VerticalAlignment="Center"/>
    \</Grid>
</ControlTemplate>
```

=== 데이터 템플릿

```xml
<DataTemplate x:Key="AlarmTemplate">
    \<Border Background="{Binding Severity, Converter={StaticResource SeverityToBrushConverter}}"
            Padding="10" Margin="5">
        \<StackPanel>
            \<TextBlock Text="{Binding Message}" FontWeight="Bold"/>
            \<TextBlock Text="{Binding Timestamp, StringFormat='HH:mm:ss'}"/>
        \</StackPanel>
    \</Border>
</DataTemplate>
```

== 애니메이션

=== Storyboard

```xml
<Storyboard x:Key="AlarmAnimation">
    \<ColorAnimation Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)"
                    To="Red"
                    Duration="0:0:0.5"
                    AutoReverse="True"
                    RepeatBehavior="Forever"/>
</Storyboard>
```

=== 코드 비하인드에서 애니메이션

```csharp
public void AnimateAlarm(UIElement element)
{
    var animation = new DoubleAnimation
    {
        From = 1.0,
        To = 0.0,
        Duration = TimeSpan.FromMilliseconds(500),
        AutoReverse = true,
        RepeatBehavior = RepeatBehavior.Forever
    };

    element.BeginAnimation(UIElement.OpacityProperty, animation);
}
```

=== 트리거 기반 애니메이션

```xml
<Style.Triggers>
    \<DataTrigger Binding="{Binding HasAlarm}" Value="True">
        \<DataTrigger.EnterActions>
            \<BeginStoryboard>
                \<Storyboard>
                    \<ColorAnimation Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)"
                                    To="Red"
                                    Duration="0:0:0.5"
                                    AutoReverse="True"
                                    RepeatBehavior="Forever"/>
                \</Storyboard>
            \</BeginStoryboard>
        \</DataTrigger.EnterActions>
    \</DataTrigger>
</Style.Triggers>
```

== Value Converter

=== 기본 Converter

```csharp
public class TemperatureToColorConverter : IValueConverter
{
    public object Convert(object value, Type targetType,
        object parameter, CultureInfo culture)
    {
        if (value is double temp)
        {
            return temp switch
            {
                > 480 => Brushes.Red,
                > 460 => Brushes.Yellow,
                _ => Brushes.Green
            };
        }
        return Brushes.Gray;
    }

    public object ConvertBack(object value, Type targetType,
        object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
```

=== Multi Value Converter

```csharp
public class RangeToColorConverter : IMultiValueConverter
{
    public object Convert(object[] values, Type targetType,
        object parameter, CultureInfo culture)
    {
        if (values.Length == 3 &&
            values[0] is double current &&
            values[1] is double min &&
            values[2] is double max)
        {
            if (current \< min || current > max)
                return Brushes.Red;
            return Brushes.Green;
        }
        return Brushes.Gray;
    }

    public object[] ConvertBack(object value, Type[] targetTypes,
        object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
```

== 실습: 고급 HMI 대시보드

=== 요구사항

+ 3개 장비를 탭으로 구분
+ 각 장비별 게이지 표시
+ 알람 리스트와 애니메이션
+ 데이터 그리드로 이력 표시

=== MainWindow.xaml

```xml
<Window x:Class="AdvancedHMI.MainWindow"
        Title="Advanced Semiconductor HMI"
        Height="900" Width="1400">
    \<Window.Resources>
        \<local:TemperatureToColorConverter x:Key="TempToColor"/>
        \<Style x:Key="AlarmStyle" TargetType="Border">
            \<!-- 스타일 정의 -->
        \</Style>
    \</Window.Resources>

    \<Grid>
        \<Grid.RowDefinitions>
            \<RowDefinition Height="Auto"/>
            \<RowDefinition Height="*"/>
            \<RowDefinition Height="200"/>
        \</Grid.RowDefinitions>

        \<!-- Header -->
        \<Border Grid.Row="0" Background="#2C3E50" Padding="15">
            \<StackPanel Orientation="Horizontal">
                \<TextBlock Text="Advanced Semiconductor HMI"
                           FontSize="24" Foreground="White"/>
                \<TextBlock Text="{Binding CurrentTime}"
                           FontSize="16" Foreground="White"
                           Margin="20,0" VerticalAlignment="Center"/>
            \</StackPanel>
        \</Border>

        \<!-- Equipment Tabs -->
        \<TabControl Grid.Row="1" ItemsSource="{Binding Equipments}">
            \<TabControl.ItemTemplate>
                \<DataTemplate>
                    \<TextBlock Text="{Binding Name}"/>
                \</DataTemplate>
            \</TabControl.ItemTemplate>
            \<TabControl.ContentTemplate>
                \<DataTemplate>
                    \<Grid>
                        \<!-- Gauges -->
                        \<UniformGrid Columns="3" Margin="10">
                            \<local:GaugeControl Value="{Binding Temperature}"
                                                Minimum="0" Maximum="600"
                                                Title="Temperature (°C)"/>
                            \<local:GaugeControl Value="{Binding Pressure}"
                                                Minimum="0" Maximum="5"
                                                Title="Pressure (Torr)"/>
                            \<local:GaugeControl Value="{Binding FlowRate}"
                                                Minimum="0" Maximum="200"
                                                Title="Flow Rate (sccm)"/>
                        \</UniformGrid>
                    \</Grid>
                \</DataTemplate>
            \</TabControl.ContentTemplate>
        \</TabControl>

        \<!-- Data Grid -->
        \<DataGrid Grid.Row="2" ItemsSource="{Binding RecentData}"
                  AutoGenerateColumns="False">
            \<!-- Columns -->
        \</DataGrid>
    \</Grid>
</Window>
```

== 실습 과제

=== 과제 1: 커스텀 Gauge 컨트롤

+ 원형 게이지 컨트롤 개발
+ 최소/최대/경고 범위 표시
+ 색상 자동 변경

=== 과제 2: 알람 애니메이션

+ 알람 발생 시 깜박임 효과
+ 우선순위별 색상 구분
+ 사운드 알림 추가

=== 과제 3: 고급 대시보드

+ 3개 장비 탭 구성
+ 각 장비별 실시간 모니터링
+ 통합 알람 뷰

== 요약

이번 챕터에서는 고급 UI를 학습했습니다:

- DataGrid, TreeView, TabControl
- 커스텀 컨트롤 개발
- 스타일과 템플릿
- 애니메이션
- Value Converter
- 고급 HMI 대시보드

다음 챕터에서는 테스트와 배포를 학습합니다.

#pagebreak()
