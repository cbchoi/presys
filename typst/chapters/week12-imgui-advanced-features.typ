= Week 12: ImGui 고급 기능
== 학습 목표
본 챕터에서는 다음을 학습한다: + ImGui의 2D 렌더링 파이프라인 이해
+ ImDrawList를 활용한 커스텀 위젯 개발
+ 렌더링 최적화 기법
+ 고급 디자인 패턴 적용
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *ImGui 중급*: Week 10-11에서 학습한 기본 위젯, 레이아웃, 이벤트 처리
- *렌더링 기초*: Vertex, Index Buffer 개념, 래스터화 과정
- *C++ 중급*: 클래스 상속, 가상 함수, 템플릿
- *선형대수 기초*: 2D 좌표계, 벡터 연산
- *권장사항*: OpenGL 또는 DirectX 기본 개념
== ImGui 렌더링의 역사와 특징
=== Immediate Mode GUI의 탄생
IMGUI(Immediate Mode GUI) 패러다임은 2005년 Casey Muratori가 Molly Rocket 프로젝트에서 처음 제안했다. 전통적인 Retained Mode GUI(MFC, Qt, WPF)와 달리, 매 프레임마다 UI를 재생성하는 방식이다.
*전통적 GUI (Retained Mode): *
```
초기화 → 위젯 생성 → 이벤트 대기 → 콜백 처리
          (메모리에 상태 유지)
```
*IMGUI (Immediate Mode): *
```
매 프레임: UI 코드 실행 → 렌더링 → 다음 프레임
           (상태는 애플리케이션이 관리)
```
=== ImGui(Dear ImGui)의 발전
- *2014년*: Omar Cornut(ocornut)이 Dear ImGui 첫 릴리스
- *2016년*: Docking Branch 추가 (멀티 윈도우 지원)
- *2020년*: Tables API 도입 (고급 테이블 위젯)
- *2023년*: v1.90 - Multi-viewport 안정화
=== 산업 적용 사례
*게임 개발 도구: *
- Unreal Engine: 에디터 디버깅 도구
- Unity: 프로파일러 UI
- CryEngine: 레벨 에디터
*반도체/산업: *
- 실시간 장비 모니터링 (낮은 오버헤드)
- 임베디드 시스템 UI (작은 메모리 풋프린트)
- 테스트 장비 인터페이스
== 이론: 2D 렌더링 기초
=== Vertex Buffer와 Index Buffer
2D 그래픽의 기본은 삼각형(Triangle)이다. 모든 도형은 삼각형의 조합으로 표현된다.
==== Vertex Buffer 구조
```cpp
// ImGui의 Vertex 구조
struct ImDrawVert
{
    ImVec2 pos;   // 위치 (x, y)
    ImVec2 uv;    // 텍스처 좌표 (u, v)
    ImU32 col;    // 색상 (RGBA, 32bit)
};
```
사각형 그리기 예제:
```
정점 0: (0, 0)     정점 1: (100, 0)
   +------------------+
   |                  |
   |                  |
   +------------------+
정점 2: (0, 100)   정점 3: (100, 100)
Vertex Buffer: [V0, V1, V2, V3]
Index Buffer: [0, 1, 2, 1, 3, 2]  // 2개 삼각형
                 -----    -----
                 삼각형1  삼각형2
```
==== Index Buffer의 장점
*메모리 절약: *
```
사각형 100개 그리기:
- Index Buffer 미사용: 600개 정점 (100×6)
- Index Buffer 사용: 400개 정점 + 600개 인덱스 (100×4 + 100×6)
  → 정점 데이터 33% 절약 (정점이 무거울수록 효과 큼)
```
=== Batching과 Draw Call 최적화
==== Draw Call이란?
Draw Call은 GPU에게 "이 데이터를 화면에 그려라"라고 명령하는 CPU-GPU 통신이다. 각 Draw Call은 오버헤드를 발생시킨다.
```
나쁜 예 (1000개 Draw Call):
for (int i = 0; i < 1000; i++) {
    DrawRectangle(i * 10, 0, 10, 10);  // 각각 Draw Call
}
→ CPU-GPU 통신 1000번
좋은 예 (1개 Draw Call):
BeginBatch();
for (int i = 0; i < 1000; i++) {
    AddRectangleToBatch(i * 10, 0, 10, 10);
}
EndBatch();  // 한 번에 Draw Call
→ CPU-GPU 통신 1번
```
==== ImGui의 Automatic Batching
ImGui는 자동으로 Draw Call을 최소화한다: 1. *Command Buffer 누적*: 한 프레임 동안 모든 그리기 명령을 버퍼에 저장
2. *State Grouping*: 같은 텍스처, 같은 클립 영역을 그룹화
3. *Single Pass Rendering*: 프레임 끝에 한 번에 렌더링
```
ImGui 내부 동작:
Frame Start
  → ImGui: :Begin("Window1")
  → ImGui: :Text("Hello")        // Command 1
  → ImGui: :Button("OK")          // Command 2
  → ImGui: :End()
  → ImGui: :Begin("Window2")
  → ImGui: :Text("World")         // Command 3
Frame End
  → Render()
     → Batch Commands 1, 2, 3 by texture/clip
     → Submit to GPU (최소 Draw Call)
```
=== 렌더링 최적화 전략
==== 1. Clipping (보이는 영역만 렌더링)
```cpp
// ImGui는 자동으로 클리핑
ImGuiListClipper clipper;
clipper.Begin(10000);  // 10000개 항목
while (clipper.Step()) {
    for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
        ImGui: :Text("Item %d", i);  // 보이는 것만 렌더링
    }
}
// 화면에 보이는 ~20개만 실제로 처리
```
*효과: *
- 10000개 → 20개 렌더링 (500배 감소)
- 스크롤 성능 대폭 향상
==== 2. Texture Atlas (텍스처 병합)
여러 작은 텍스처를 하나의 큰 텍스처로 결합: ```
개별 텍스처 (5개 Draw Call):
[Icon1.png] [Icon2.png] [Icon3.png] [Icon4.png] [Icon5.png]
Texture Atlas (1개 Draw Call):
+---+---+---+---+---+
| 1 | 2 | 3 | 4 | 5 |
+---+---+---+---+---+
```
ImGui는 폰트 텍스처를 Atlas로 관리한다.
==== 3. Vertex Cache 최적화
GPU는 최근 처리한 정점을 캐시에 보관한다. Index 순서를 최적화하면 캐시 히트율이 올라간다.
```
나쁜 순서 (캐시 미스):
Indices: [0, 100, 1, 101, 2, 102, ...]
좋은 순서 (캐시 히트):
Indices: [0, 1, 2, 3, 4, 5, ...]
```
== 응용: 디자인 패턴
=== Strategy Pattern (전략 패턴)
서로 다른 렌더링 전략을 런타임에 교체한다.
==== 완전한 구현
```cpp
#include <memory>
#include <imgui.h>
// 전략 인터페이스
class IRenderStrategy {
public: virtual ~IRenderStrategy() = default;
  virtual void Render(ImDrawList* drawList, float value) = 0;
};
// 구체적 전략 1: 바 차트
class BarChartStrategy : public IRenderStrategy {
public: void Render(ImDrawList* drawList, float value) override {
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  float width = 200.0f;
  float height = 100.0f;
  // 배경
  drawList->AddRectFilled(pos, ImVec2(pos.x + width, pos.y + height), IM_COL32(50, 50, 50, 255));
  // 바 (value: 0.0~1.0)
  float barWidth = width * value;
  drawList->AddRectFilled(pos, ImVec2(pos.x + barWidth, pos.y + height), IM_COL32(100, 200, 100, 255));
  // 텍스트
  char buf[32];
  snprintf(buf, sizeof(buf), "%.1f%%", value * 100);
  drawList->AddText(ImVec2(pos.x + 5, pos.y + 5), IM_COL32(255, 255, 255, 255), buf);
  }
};
// 구체적 전략 2: 원형 게이지
class CircularGaugeStrategy : public IRenderStrategy {
public: void Render(ImDrawList* drawList, float value) override {
  ImVec2 center = ImGui: :GetCursorScreenPos();
  center.x += 100;
  center.y += 100;
  float radius = 80.0f;
  // 배경 원
  drawList->AddCircleFilled(center, radius, IM_COL32(50, 50, 50, 255));
  // 진행 호 (0도부터 value*360도까지)
  float angle = value * 3.14159f * 2.0f;
  int segments = 50;
  for (int i = 0; i < segments * value; i++) {
  float a1 = (float)i / segments * 3.14159f * 2.0f;
  float a2 = (float)(i+1) / segments * 3.14159f * 2.0f;
  ImVec2 p1(center.x + cosf(a1) * radius, center.y + sinf(a1) * radius);
  ImVec2 p2(center.x + cosf(a2) * radius, center.y + sinf(a2) * radius);
  drawList->AddLine(p1, p2, IM_COL32(100, 200, 100, 255), 8.0f);
  }
  // 중앙 텍스트
  char buf[32];
  snprintf(buf, sizeof(buf), "%.0f%%", value * 100);
  ImVec2 textSize = ImGui: :CalcTextSize(buf);
  drawList->AddText(ImVec2(center.x - textSize.x/2, center.y - textSize.y/2), IM_COL32(255, 255, 255, 255), buf);
  }
};
// Context (사용자 코드)
class ValueVisualizer {
public: void SetStrategy(std: :unique_ptr<IRenderStrategy> strategy) {
  strategy_ = std: :move(strategy);
  }
  void Render(float value) {
  if (strategy_) {
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  strategy_->Render(drawList, value);
  }
  }
private: std: :unique_ptr<IRenderStrategy> strategy_;
};
// 사용 예제
void DemoStrategyPattern() {
  static ValueVisualizer visualizer;
  static float value = 0.75f;
  static int strategyType = 0;
  ImGui: :Begin("Strategy Pattern Demo");
  // 전략 선택
  if (ImGui: :RadioButton("Bar Chart", &strategyType, 0)) {
  visualizer.SetStrategy(std: :make_unique<BarChartStrategy>());
  }
  if (ImGui: :RadioButton("Circular Gauge", &strategyType, 1)) {
  visualizer.SetStrategy(std: :make_unique<CircularGaugeStrategy>());
  }
  ImGui: :SliderFloat("Value", &value, 0.0f, 1.0f);
  // 렌더링
  visualizer.Render(value);
  ImGui: :End();
}
```
*장점: *
- 런타임에 알고리즘 교체 가능
- Open/Closed Principle 준수 (확장에 열림, 수정에 닫힘)
- 코드 재사용성 향상
=== Factory Pattern (팩토리 패턴)
위젯 생성 로직을 캡슐화한다.
==== 완전한 구현
```cpp
#include <memory>
#include <string>
#include <unordered_map>
// 위젯 베이스
class Widget {
public: virtual ~Widget() = default;
  virtual void Render() = 0;
  virtual const char* GetType() const = 0;
};
// 구체적 위젯 1: 온도 표시
class TemperatureWidget : public Widget {
public: TemperatureWidget(const std: :string& label, float initialValue)
  : label_(label), value_(initialValue) {}
  void Render() override {
  ImGui: :PushID(this);
  ImGui: :Text("%s: %.1f °C", label_.c_str(), value_);
  ImGui: :SameLine();
  if (ImGui: :SmallButton("+")) value_ += 1.0f;
  ImGui: :SameLine();
  if (ImGui: :SmallButton("-")) value_ -= 1.0f;
  ImGui: :PopID();
  }
  const char* GetType() const override { return "Temperature"; }
  void SetValue(float val) { value_ = val; }
private: std: :string label_;
  float value_;
};
// 구체적 위젯 2: 압력 게이지
class PressureGaugeWidget : public Widget {
public: PressureGaugeWidget(const std: :string& label, float initialValue)
  : label_(label), value_(initialValue) {}
  void Render() override {
  ImGui: :PushID(this);
  // 바 형태로 표시
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  float width = 150.0f;
  float height = 20.0f;
  float normalized = value_ / 10.0f; // 0~10 Torr 가정
  // 배경
  drawList->AddRectFilled(pos, ImVec2(pos.x + width, pos.y + height), IM_COL32(40, 40, 40, 255));
  // 게이지
  ImU32 color = (normalized > 0.8f) ? IM_COL32(255, 0, 0, 255) : IM_COL32(0, 255, 0, 255);
  drawList->AddRectFilled(pos, ImVec2(pos.x + width * normalized, pos.y + height), color);
  // 텍스트
  char buf[64];
  snprintf(buf, sizeof(buf), "%s: %.2f Torr", label_.c_str(), value_);
  drawList->AddText(ImVec2(pos.x + 5, pos.y + 2), IM_COL32(255, 255, 255, 255), buf);
  ImGui: :Dummy(ImVec2(width, height));
  ImGui: :PopID();
  }
  const char* GetType() const override { return "Pressure"; }
  void SetValue(float val) { value_ = val; }
private: std: :string label_;
  float value_;
};
// Factory
class WidgetFactory {
public: static std: :unique_ptr<Widget> CreateWidget(const std: :string& type, const std: :string& label, float initialValue) {
  if (type == "Temperature") {
  return std: :make_unique<TemperatureWidget>(label, initialValue);
  } else if (type == "Pressure") {
  return std: :make_unique<PressureGaugeWidget>(label, initialValue);
  }
  return nullptr;
  }
  // 등록 기반 팩토리 (확장성 높음)
  using CreatorFunc = std: :unique_ptr<Widget>(*)(const std: :string&, float);
  static void RegisterWidget(const std: :string& type, CreatorFunc creator) {
  GetRegistry()[type] = creator;
  }
  static std: :unique_ptr<Widget> CreateRegistered(const std: :string& type, const std: :string& label, float initialValue) {
  auto& registry = GetRegistry();
  auto it = registry.find(type);
  if (it != registry.end()) {
  return it->second(label, initialValue);
  }
  return nullptr;
  }
private: static std: :unordered_map<std: :string, CreatorFunc>& GetRegistry() {
  static std: :unordered_map<std: :string, CreatorFunc> registry;
  return registry;
  }
};
// 사용 예제
void DemoFactoryPattern() {
  static std: :vector<std: :unique_ptr<Widget>> widgets;
  static char labelBuf[64] = "Sensor";
  static int widgetType = 0;
  ImGui: :Begin("Factory Pattern Demo");
  // 위젯 생성 UI
  ImGui: :InputText("Label", labelBuf, sizeof(labelBuf));
  ImGui: :RadioButton("Temperature", &widgetType, 0); ImGui: :SameLine();
  ImGui: :RadioButton("Pressure", &widgetType, 1);
  if (ImGui: :Button("Create Widget")) {
  const char* type = (widgetType == 0) ? "Temperature" : "Pressure";
  auto widget = WidgetFactory: :CreateWidget(type, labelBuf, 0.0f);
  if (widget) {
  widgets.push_back(std: :move(widget));
  }
  }
  ImGui: :Separator();
  // 위젯 렌더링
  for (auto& widget : widgets) {
  widget->Render();
  }
  ImGui: :End();
}
```
*장점: *
- 객체 생성 로직 중앙화
- 클라이언트 코드와 구체 클래스 분리
- 새로운 위젯 추가 시 Factory만 수정
=== Template Method Pattern (템플릿 메서드 패턴)
알고리즘의 골격을 정의하고, 세부 단계를 서브클래스에서 구현한다.
==== 완전한 구현
```cpp
#include <imgui.h>
#include <vector>
#include <algorithm>
// 추상 베이스: 차트 렌더링 템플릿
class ChartRenderer {
public: virtual ~ChartRenderer() = default;
  // 템플릿 메서드 (알고리즘 골격)
  void Render(const std: :vector<float>& data, const char* title) {
  if (data.empty()) return;
  ImGui: :BeginChild(title, ImVec2(0, 200), true);
  // 1. 타이틀 렌더링 (공통)
  RenderTitle(title);
  // 2. 데이터 정규화 (공통)
  auto [minVal, maxVal] = GetDataRange(data);
  // 3. 축 렌더링 (서브클래스마다 다름)
  RenderAxes(minVal, maxVal);
  // 4. 데이터 렌더링 (서브클래스마다 다름)
  RenderData(data, minVal, maxVal);
  // 5. 범례 렌더링 (공통)
  RenderLegend(data);
  ImGui: :EndChild();
  }
protected: // Hook methods (서브클래스에서 구현)
  virtual void RenderAxes(float minVal, float maxVal) = 0;
  virtual void RenderData(const std: :vector<float>& data, float minVal, float maxVal) = 0;
  // 공통 메서드
  void RenderTitle(const char* title) {
  ImGui: :Text("%s", title);
  ImGui: :Separator();
  }
  void RenderLegend(const std: :vector<float>& data) {
  ImGui: :Text("Samples: %zu", data.size());
  }
  std: :pair<float, float> GetDataRange(const std: :vector<float>& data) {
  auto [minIt, maxIt] = std: :minmax_element(data.begin(), data.end());
  return {*minIt, *maxIt};
  }
  ImVec2 GetChartArea() {
  return ImVec2(ImGui: :GetContentRegionAvail().x, 150);
  }
};
// 구체적 구현 1: 라인 차트
class LineChartRenderer : public ChartRenderer {
protected: void RenderAxes(float minVal, float maxVal) override {
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  ImVec2 size = GetChartArea();
  // Y축
  drawList->AddLine(pos, ImVec2(pos.x, pos.y + size.y), IM_COL32(200, 200, 200, 255));
  // X축
  drawList->AddLine(ImVec2(pos.x, pos.y + size.y), ImVec2(pos.x + size.x, pos.y + size.y), IM_COL32(200, 200, 200, 255));
  }
  void RenderData(const std: :vector<float>& data, float minVal, float maxVal) override {
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  ImVec2 size = GetChartArea();
  float range = maxVal - minVal;
  if (range == 0) range = 1.0f;
  for (size_t i = 1; i < data.size(); i++) {
  float x1 = pos.x + (float)(i-1) / data.size() * size.x;
  float y1 = pos.y + size.y - (data[i-1] - minVal) / range * size.y;
  float x2 = pos.x + (float)i / data.size() * size.x;
  float y2 = pos.y + size.y - (data[i] - minVal) / range * size.y;
  drawList->AddLine(ImVec2(x1, y1), ImVec2(x2, y2), IM_COL32(100, 200, 255, 255), 2.0f);
  }
  ImGui: :Dummy(size);
  }
};
// 구체적 구현 2: 바 차트
class BarChartRenderer : public ChartRenderer {
protected: void RenderAxes(float minVal, float maxVal) override {
  // 라인 차트와 동일
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  ImVec2 size = GetChartArea();
  drawList->AddLine(pos, ImVec2(pos.x, pos.y + size.y), IM_COL32(200, 200, 200, 255));
  drawList->AddLine(ImVec2(pos.x, pos.y + size.y), ImVec2(pos.x + size.x, pos.y + size.y), IM_COL32(200, 200, 200, 255));
  }
  void RenderData(const std: :vector<float>& data, float minVal, float maxVal) override {
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  ImVec2 size = GetChartArea();
  float range = maxVal - minVal;
  if (range == 0) range = 1.0f;
  float barWidth = size.x / data.size() * 0.8f;
  for (size_t i = 0; i < data.size(); i++) {
  float x = pos.x + (float)i / data.size() * size.x;
  float barHeight = (data[i] - minVal) / range * size.y;
  float y = pos.y + size.y - barHeight;
  drawList->AddRectFilled(ImVec2(x, y), ImVec2(x + barWidth, pos.y + size.y), IM_COL32(100, 200, 100, 255));
  }
  ImGui: :Dummy(size);
  }
};
// 사용 예제
void DemoTemplateMethodPattern() {
  static std: :vector<float> data = {10, 25, 18, 42, 35, 28, 50, 45};
  static int chartType = 0;
  ImGui: :Begin("Template Method Pattern Demo");
  ImGui: :RadioButton("Line Chart", &chartType, 0); ImGui: :SameLine();
  ImGui: :RadioButton("Bar Chart", &chartType, 1);
  if (ImGui: :Button("Add Random Data")) {
  data.push_back(rand() % 50 + 10);
  if (data.size() > 20) data.erase(data.begin());
  }
  // 차트 렌더링
  std: :unique_ptr<ChartRenderer> renderer;
  if (chartType == 0) {
  renderer = std: :make_unique<LineChartRenderer>();
  } else {
  renderer = std: :make_unique<BarChartRenderer>();
  }
  renderer->Render(data, "Temperature Trend");
  ImGui: :End();
}
```
*장점: *
- 알고리즘 구조 재사용
- 코드 중복 최소화
- 서브클래스가 특정 단계만 재정의 가능
== 완전한 실행 가능 예제: 커스텀 위젯 시스템
다음은 ImDrawList를 활용한 완전한 커스텀 위젯 시스템이다.
=== CustomGauge.h
```cpp
#ifndef CUSTOM_GAUGE_H
#define CUSTOM_GAUGE_H
#include <imgui.h>
#include <cmath>
#include <string>
class CustomGauge {
public: CustomGauge(const char* label, float minVal, float maxVal)
  : label_(label), minValue_(minVal), maxValue_(maxVal), currentValue_(minVal) {}
  void SetValue(float val) {
  currentValue_ = std: :clamp(val, minValue_, maxValue_);
  }
  float GetValue() const { return currentValue_; }
  void Render() {
  ImGui: :PushID(this);
  ImVec2 pos = ImGui: :GetCursorScreenPos();
  ImDrawList* drawList = ImGui: :GetWindowDrawList();
  // 게이지 크기
  float radius = 80.0f;
  ImVec2 center(pos.x + radius + 10, pos.y + radius + 10);
  // 배경 원
  drawList->AddCircleFilled(center, radius, IM_COL32(30, 30, 30, 255), 64);
  drawList->AddCircle(center, radius, IM_COL32(100, 100, 100, 255), 64, 2.0f);
  // 눈금 그리기
  RenderTicks(drawList, center, radius);
  // 값 호 그리기
  RenderValueArc(drawList, center, radius);
  // 바늘 그리기
  RenderNeedle(drawList, center, radius);
  // 중앙 텍스트
  RenderCenterText(drawList, center);
  // 레이블
  ImVec2 labelSize = ImGui: :CalcTextSize(label_);
  drawList->AddText(ImVec2(center.x - labelSize.x/2, center.y + radius + 15), IM_COL32(255, 255, 255, 255), label_);
  ImGui: :Dummy(ImVec2(radius * 2 + 20, radius * 2 + 40));
  ImGui: :PopID();
  }
private: void RenderTicks(ImDrawList* drawList, ImVec2 center, float radius) {
  int numTicks = 10;
  for (int i = 0; i <= numTicks; i++) {
  float angle = -3.14159f * 0.75f + (3.14159f * 1.5f) * i / numTicks;
  float tickRadius = (i % 2 == 0) ? radius - 10 : radius - 5;
  ImVec2 p1(center.x + cosf(angle) * tickRadius, center.y + sinf(angle) * tickRadius);
  ImVec2 p2(center.x + cosf(angle) * radius, center.y + sinf(angle) * radius);
  drawList->AddLine(p1, p2, IM_COL32(150, 150, 150, 255), (i % 2 == 0) ? 2.0f : 1.0f);
  }
  }
  void RenderValueArc(ImDrawList* drawList, ImVec2 center, float radius) {
  float normalized = (currentValue_ - minValue_) / (maxValue_ - minValue_);
  float startAngle = -3.14159f * 0.75f;
  float sweepAngle = 3.14159f * 1.5f * normalized;
  int segments = 50;
  for (int i = 0; i < segments * normalized; i++) {
  float a1 = startAngle + (sweepAngle * i / (segments * normalized));
  float a2 = startAngle + (sweepAngle * (i+1) / (segments * normalized));
  ImVec2 p1(center.x + cosf(a1) * (radius - 15), center.y + sinf(a1) * (radius - 15));
  ImVec2 p2(center.x + cosf(a2) * (radius - 15), center.y + sinf(a2) * (radius - 15));
  // 색상: 초록 → 노랑 → 빨강
  ImU32 color;
  if (normalized < 0.5f) {
  color = IM_COL32(100, 200, 100, 255); // 초록
  } else if (normalized < 0.8f) {
  color = IM_COL32(200, 200, 100, 255); // 노랑
  } else {
  color = IM_COL32(200, 100, 100, 255); // 빨강
  }
  drawList->AddLine(p1, p2, color, 8.0f);
  }
  }
  void RenderNeedle(ImDrawList* drawList, ImVec2 center, float radius) {
  float normalized = (currentValue_ - minValue_) / (maxValue_ - minValue_);
  float angle = -3.14159f * 0.75f + 3.14159f * 1.5f * normalized;
  ImVec2 needleEnd(center.x + cosf(angle) * (radius - 20), center.y + sinf(angle) * (radius - 20));
  drawList->AddLine(center, needleEnd, IM_COL32(255, 255, 255, 255), 3.0f);
  drawList->AddCircleFilled(center, 5.0f, IM_COL32(255, 255, 255, 255));
  }
  void RenderCenterText(ImDrawList* drawList, ImVec2 center) {
  char buf[64];
  snprintf(buf, sizeof(buf), "%.1f", currentValue_);
  ImVec2 textSize = ImGui: :CalcTextSize(buf);
  drawList->AddText(ImVec2(center.x - textSize.x/2, center.y + 20), IM_COL32(255, 255, 255, 255), buf);
  }
  const char* label_;
  float minValue_;
  float maxValue_;
  float currentValue_;
};
#endif // CUSTOM_GAUGE_H
```
=== main.cpp (완전한 실행 가능 예제)
```cpp
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <GLFW/glfw3.h>
#include "CustomGauge.h"
#include <vector>
#include <memory>
#include <cstdlib>
#include <ctime>
int main() {
  // GLFW 초기화
  if (!glfwInit()) {
  return -1;
  }
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  GLFWwindow* window = glfwCreateWindow(1280, 720, "ImGui Advanced Features Demo", NULL, NULL);
  if (!window) {
  glfwTerminate();
  return -1;
  }
  glfwMakeContextCurrent(window);
  glfwSwapInterval(1);
  // ImGui 초기화
  IMGUI_CHECKVERSION();
  ImGui: :CreateContext();
  ImGuiIO& io = ImGui: :GetIO();
  ImGui_ImplGlfw_InitForOpenGL(window, true);
  ImGui_ImplOpenGL3_Init("#version 330");
  // 커스텀 게이지 생성
  CustomGauge tempGauge("Temperature", 0, 600);
  CustomGauge pressureGauge("Pressure", 0, 10);
  CustomGauge flowGauge("Flow Rate", 0, 200);
  tempGauge.SetValue(450);
  pressureGauge.SetValue(5.5);
  flowGauge.SetValue(120);
  srand(static_cast<unsigned>(time(nullptr)));
  // 메인 루프
  while (!glfwWindowShouldClose(window)) {
  glfwPollEvents();
  ImGui_ImplOpenGL3_NewFrame();
  ImGui_ImplGlfw_NewFrame();
  ImGui: :NewFrame();
  // 메인 윈도우
  ImGui: :Begin("Semiconductor Equipment Monitor", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
  ImGui: :Text("Custom Gauge Widgets with ImDrawList");
  ImGui: :Separator();
  // 3개 게이지 가로 배치
  tempGauge.Render();
  ImGui: :SameLine();
  pressureGauge.Render();
  ImGui: :SameLine();
  flowGauge.Render();
  ImGui: :Separator();
  // 제어 버튼
  if (ImGui: :Button("Simulate Data Update")) {
  tempGauge.SetValue(tempGauge.GetValue() + (rand() % 20 - 10));
  pressureGauge.SetValue(pressureGauge.GetValue() + (rand() % 100 - 50) / 100.0f);
  flowGauge.SetValue(flowGauge.GetValue() + (rand() % 20 - 10));
  }
  ImGui: :End();
  // 렌더링
  ImGui: :Render();
  int display_w, display_h;
  glfwGetFramebufferSize(window, &display_w, &display_h);
  glViewport(0, 0, display_w, display_h);
  glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  ImGui_ImplOpenGL3_RenderDrawData(ImGui: :GetDrawData());
  glfwSwapBuffers(window);
  }
  // 정리
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplGlfw_Shutdown();
  ImGui: :DestroyContext();
  glfwDestroyWindow(window);
  glfwTerminate();
  return 0;
}
```
=== CMakeLists.txt
```cmake
cmake_minimum_required(VERSION 3.10)
project(ImGuiAdvancedFeatures)
set(CMAKE_CXX_STANDARD 17)
find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)
# ImGui 소스 (프로젝트에 복사 필요)
set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/imgui")
add_executable(demo
  main.cpp
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp)
target_include_directories(demo PRIVATE
  ${IMGUI_DIR}
  ${IMGUI_DIR}/backends)
target_link_libraries(demo
  OpenGL: :GL
  glfw)
```
*빌드 및 실행: *
```bash
mkdir build && cd build
cmake ..
make
./demo
```
== MCQ (Multiple Choice Questions)
=== 문제 1: Vertex Buffer 개념 (기초)
ImDrawVert 구조체에 포함되지 않는 것은?
A. 위치 (pos) \
B. 텍스처 좌표 (uv) \
C. 색상 (col) \
D. 법선 벡터 (normal)
*정답: D*
*해설*: ImGui는 2D 렌더링이므로 법선 벡터가 필요 없다. ImDrawVert는 pos(위치), uv(텍스처 좌표), col(색상) 3가지만 포함한다.
---
=== 문제 2: Batching 효과 (기초)
Draw Call Batching의 주요 목적은?
A. 메모리 사용량 감소 \
B. CPU-GPU 통신 횟수 감소 \
C. 텍스처 품질 향상 \
D. 코드 가독성 향상
*정답: B*
*해설*: Batching은 여러 그리기 명령을 하나로 묶어 CPU-GPU 통신(Draw Call) 횟수를 줄인다. 이는 렌더링 성능 향상의 핵심이다.
---
=== 문제 3: Index Buffer 장점 (중급)
사각형 100개를 그릴 때, Index Buffer 사용 시 정점 개수는?
A. 200개 \
B. 400개 \
C. 600개 \
D. 800개
*정답: B*
*해설*: 사각형 1개 = 4개 정점. Index Buffer를 사용하면 정점을 재사용하므로 100개 사각형 = 400개 정점 + 600개 인덱스. Index Buffer 미사용 시 600개 정점이 필요하다.
---
=== 문제 4: Strategy Pattern (중급)
Strategy Pattern의 핵심 장점은?
A. 메모리 절약 \
B. 실행 속도 향상 \
C. 런타임에 알고리즘 교체 가능 \
D. 코드 라인 수 감소
*정답: C*
*해설*: Strategy Pattern은 알고리즘을 캡슐화하여 런타임에 교체할 수 있게 한다. 예: 바 차트 ↔ 원형 게이지 전환.
---
=== 문제 5: Factory Pattern (중급)
Factory Pattern에서 객체 생성 결정은 누가 하는가?
A. 클라이언트 코드 \
B. Factory 클래스 \
C. 생성될 객체 자신 \
D. 컴파일러
*정답: B*
*해설*: Factory 클래스가 입력(타입 문자열 등)에 따라 어떤 구체적 객체를 생성할지 결정한다. 클라이언트는 구체 클래스를 알 필요가 없다.
---
=== 문제 6: ImDrawList 코드 분석 (고급)
다음 코드의 출력은?
```cpp
ImDrawList* drawList = ImGui: :GetWindowDrawList();
ImVec2 pos = ImGui: :GetCursorScreenPos();
drawList->AddRectFilled(pos, ImVec2(pos.x + 100, pos.y + 50), IM_COL32(255, 0, 0, 255));
```
A. 빨간색 테두리 사각형 \
B. 빨간색 채운 사각형 (100×50) \
C. 초록색 채운 사각형 \
D. 컴파일 오류
*정답: B*
*해설*: AddRectFilled는 채운 사각형을 그린다. `IM_COL32(255, 0, 0, 255)`는 빨간색(`R=255, G=0, B=0, A=255`). 크기는 100×50 픽셀.
---
=== 문제 7: Template Method Pattern (고급)
Template Method Pattern에서 "template method"가 하는 역할은?
A. 모든 단계를 구현 \
B. 알고리즘 골격만 정의, 세부는 서브클래스에 위임 \
C. 객체 생성 \
D. 메모리 관리
*정답: B*
*해설*: Template Method는 알고리즘의 골격(순서)을 정의하고, 각 단계의 구현은 서브클래스가 hook method로 제공한다.
---
=== 문제 8: Clipping 최적화 (고급)
ImGuiListClipper로 10000개 항목을 표시할 때, 실제 렌더링되는 항목 수는?
A. 10000개 전부 \
B. 화면에 보이는 ~20개만 \
C. 1000개 \
D. 100개
*정답: B*
*해설*: ImGuiListClipper는 화면에 보이는 영역의 항목만 렌더링한다. 스크롤 가능한 리스트에서 성능을 극적으로 향상시킨다.
---
=== 문제 9: Texture Atlas (고급)
Texture Atlas의 장점은?
A. 이미지 해상도 향상 \
B. 메모리 사용량 증가 \
C. Draw Call 감소 \
D. 코딩 편의성
*정답: C*
*해설*: 여러 작은 텍스처를 하나의 큰 텍스처로 결합하면, 텍스처 전환 없이 여러 이미지를 그릴 수 있어 Draw Call이 줄어든다.
---
=== 문제 10: 종합 응용 (도전)
다음 중 렌더링 성능을 가장 크게 향상시키는 방법은?
A. 폰트 크기를 작게 \
B. ImGuiListClipper로 대량 데이터 클리핑 \
C. 색상을 흑백으로 \
D. 윈도우 크기 축소
*정답: B*
*해설*: ImGuiListClipper는 수천~수만 개 항목을 수십 개로 줄여 CPU/GPU 부하를 극적으로 감소시킨다. 폰트 크기, 색상, 윈도우 크기는 성능에 미미한 영향만 준다.
== 실습 과제
=== 과제 1: 커스텀 위젯 개발
+ ImDrawList로 LED 인디케이터 위젯 구현
+ 3가지 상태: OFF(회색), ON(초록), ERROR(빨강)
+ 깜빡임 효과 추가
=== 과제 2: 디자인 패턴 적용
+ Strategy Pattern으로 3가지 차트 타입 구현 (라인, 바, 파이)
+ Factory Pattern으로 센서 위젯 생성 시스템
+ Template Method로 알람 렌더링 골격 정의
=== 과제 3: 성능 최적화
+ 1000개 항목 리스트에 ImGuiListClipper 적용
+ Texture Atlas 생성 (5개 아이콘 결합)
+ 프로파일링으로 성능 개선 측정
== 추가 학습 자료
=== 공식 문서
- *Dear ImGui GitHub*: https: //github.com/ocornut/imgui
- *ImGui Wiki*: https: //github.com/ocornut/imgui/wiki
- *ImDrawList API*: imgui.h 파일의 ImDrawList 섹션 참고
=== 참고 서적
- "Game Engine Architecture" by Jason Gregory (GUI 시스템 챕터)
- "Real-Time Rendering" by Tomas Akenine-Möller (2D 렌더링 기초)
=== 샘플 프로젝트
- ImGui Demo (imgui_demo.cpp): 모든 기능 예제
- ImPlot: 고급 차트 라이브러리 (https: //github.com/epezent/implot)
== 요약
이번 챕터에서는 ImGui 고급 기능을 학습했다: *이론 (Theory): *
- IMGUI 패러다임의 역사: Retained Mode vs Immediate Mode
- 2D 렌더링 기초: Vertex Buffer, Index Buffer, 삼각형 기반 렌더링
- Batching: Draw Call 최소화로 성능 향상
- 최적화 전략: Clipping, Texture Atlas, Vertex Cache
*응용 (Application): *
- Strategy Pattern: 런타임 알고리즘 교체 (차트 타입 전환)
- Factory Pattern: 위젯 생성 로직 캡슐화
- Template Method Pattern: 알고리즘 골격 재사용 (차트 렌더링)
- 완전한 실행 가능 예제: CustomGauge 위젯 시스템
*성찰 (Reflections): *
- MCQ 10문제: 렌더링 기초, 디자인 패턴, 코드 분석, 최적화
*핵심 포인트: *
1. ImGui는 자동 Batching으로 Draw Call을 최소화한다
2. ImDrawList는 저수준 2D 그리기 API로 커스텀 위젯 개발 가능
3. 디자인 패턴(Strategy, Factory, Template Method)은 코드 재사용성과 확장성을 높인다
4. Clipping과 Texture Atlas는 대규모 UI에서 필수 최적화 기법이다
다음 챕터에서는 통합 프로젝트로 전체 HMI 시스템을 설계하고 구현한다.
#pagebreak()