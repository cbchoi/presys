= Week 11: ImGui 고급 위젯 및 ImPlot
== 학습 목표
본 챕터에서는 다음을 학습한다: + Table API 활용
+ ImPlot 라이브러리로 실시간 차트
+ 커스텀 렌더링
+ 이미지 및 텍스처
== Table API
=== 기본 테이블
```cpp
if (ImGui: :BeginTable("process_data", 4, ImGuiTableFlags_Borders |
 ImGuiTableFlags_RowBg |
 ImGuiTableFlags_Resizable)) {
 // Header
 ImGui: :TableSetupColumn("Timestamp");
 ImGui: :TableSetupColumn("Temperature");
 ImGui: :TableSetupColumn("Pressure");
 ImGui: :TableSetupColumn("Flow Rate");
 ImGui: :TableHeadersRow();
 // Rows
 for (const auto& data : process_history) {
 ImGui: :TableNextRow();
 ImGui: :TableNextColumn();
 ImGui: :Text("%s", format_time(data.timestamp).c_str());
 ImGui: :TableNextColumn();
 ImGui: :Text("%.1f°C", data.temperature);
 ImGui: :TableNextColumn();
 ImGui: :Text("%.2f Torr", data.pressure);
 ImGui: :TableNextColumn();
 ImGui: :Text("%.1f sccm", data.flow_rate);
 }
 ImGui: :EndTable();
}
```
=== 고급 기능
```cpp
if (ImGui: :BeginTable("advanced", 3, ImGuiTableFlags_Sortable |
 ImGuiTableFlags_ScrollY |
 ImGuiTableFlags_RowBg |
 ImGuiTableFlags_Borders)) {
 // Setup
 ImGui: :TableSetupScrollFreeze(0, 1); // 헤더 고정
 ImGui: :TableSetupColumn("ID", ImGuiTableColumnFlags_DefaultSort);
 ImGui: :TableSetupColumn("Name");
 ImGui: :TableSetupColumn("Status");
 ImGui: :TableHeadersRow();
 // 정렬
 if (ImGuiTableSortSpecs* sorts = ImGui: :TableGetSortSpecs()) {
 if (sorts->SpecsDirty) {
 sort_equipment_list(sorts);
 sorts->SpecsDirty = false;
 }
 }
 // Data
 for (const auto& eq : equipment_list) {
 ImGui: :TableNextRow();
 ImGui: :TableNextColumn();
 ImGui: :Text("%s", eq.id.c_str());
 ImGui: :TableNextColumn();
 ImGui: :Text("%s", eq.name.c_str());
 ImGui: :TableNextColumn();
 ImGui: :Text("%s", get_status_text(eq.status).c_str());
 }
 ImGui: :EndTable();
}
```
== ImPlot
=== 설치
```cmake
# CMakeLists.txt
add_library(implot
 implot/implot.cpp
 implot/implot_items.cpp
 implot/implot_demo.cpp)
target_include_directories(implot PUBLIC implot)
target_link_libraries(hmi implot)
```
=== 기본 라인 차트
```cpp
#include \<implot.h>
// 초기화 (한 번만)
ImPlot: :CreateContext();
// 렌더링
if (ImPlot: :BeginPlot("Temperature")) {
 ImPlot: :SetupAxes("Time (s)", "Temperature (°C)");
 ImPlot: :SetupAxisLimits(ImAxis_Y1, 0, 600);
 ImPlot: :PlotLine("Temperature", time_data.data(), temp_data.data(), time_data.size());
 ImPlot: :EndPlot();
}
// 정리 (종료 시)
ImPlot: :DestroyContext();
```
=== 실시간 스크롤링 차트
```cpp
class ScrollingBuffer {
public: ScrollingBuffer(int max_size = 1000)
 : max_size_(max_size)
, offset_(0) {
 data_.reserve(max_size);
 }
 void add_point(float x, float y) {
 if (data_.size() \< max_size_) {
 data_.push_back({x, y});
 } else {
 data_[offset_] = {x, y};
 offset_ = (offset_ + 1) % max_size_;
 }
 }
 void erase() {
 if (!data_.empty()) {
 data_.clear();
 offset_ = 0;
 }
 }
 const ImVec2* data() const {
 return data_.data();
 }
 int size() const {
 return static_cast<int>(data_.size());
 }
 int offset() const {
 return offset_;
 }
private: int max_size_;
 int offset_;
 std: :vector<ImVec2> data_;
};
// 사용
static ScrollingBuffer temp_buffer(1000);
static float time_counter = 0.0f;
// 데이터 추가
temp_buffer.add_point(time_counter, current_temperature);
time_counter += ImGui: :GetIO().DeltaTime;
// 렌더링
if (ImPlot: :BeginPlot("Real-time Temperature", ImVec2(-1, 300))) {
 ImPlot: :SetupAxes("Time", "Temperature (°C)");
 ImPlot: :SetupAxisLimits(ImAxis_X1, time_counter - 10, time_counter, ImGuiCond_Always);
 ImPlot: :SetupAxisLimits(ImAxis_Y1, 400, 500);
 ImPlot: :PlotLine("Temperature", &temp_buffer.data()[0].x, &temp_buffer.data()[0].y, temp_buffer.size(), 0, temp_buffer.offset(), 2 * sizeof(float));
 ImPlot: :EndPlot();
}
```
=== 다중 Y축
```cpp
if (ImPlot: :BeginPlot("Multi-axis", ImVec2(-1, 400))) {
 ImPlot: :SetupAxes("Time", "Temperature (°C)");
 ImPlot: :SetupAxis(ImAxis_Y2, "Pressure (Torr)", ImPlotAxisFlags_AuxDefault);
 ImPlot: :SetAxes(ImAxis_X1, ImAxis_Y1);
 ImPlot: :PlotLine("Temperature", time_data, temp_data, data_size);
 ImPlot: :SetAxes(ImAxis_X1, ImAxis_Y2);
 ImPlot: :PlotLine("Pressure", time_data, pressure_data, data_size);
 ImPlot: :EndPlot();
}
```
=== 차트 스타일
```cpp
ImPlotStyle& style = ImPlot: :GetStyle();
style.LineWeight = 2.0f;
style.MarkerSize = 4.0f;
style.Colors[ImPlotCol_Line] = ImVec4(0.2f, 0.6f, 1.0f, 1.0f);
style.Colors[ImPlotCol_Fill] = ImVec4(0.2f, 0.6f, 1.0f, 0.3f);
// 임시 스타일
ImPlot: :PushStyleColor(ImPlotCol_Line, ImVec4(1.0f, 0.0f, 0.0f, 1.0f));
ImPlot: :PlotLine("Red Line", x_data, y_data, size);
ImPlot: :PopStyleColor();
```
== 커스텀 렌더링
=== DrawList API
```cpp
ImDrawList* draw_list = ImGui: :GetWindowDrawList();
// 현재 위치
ImVec2 pos = ImGui: :GetCursorScreenPos();
// 사각형
draw_list->AddRect(ImVec2(pos.x, pos.y), ImVec2(pos.x + 100, pos.y + 50), IM_COL32(255, 0, 0, 255), 0.0f, // rounding
 0, // flags
 2.0f // thickness);
// 채워진 사각형
draw_list->AddRectFilled(ImVec2(pos.x, pos.y), ImVec2(pos.x + 100, pos.y + 50), IM_COL32(0, 255, 0, 128));
// 원
draw_list->AddCircle(ImVec2(pos.x + 50, pos.y + 25), 20.0f, IM_COL32(0, 0, 255, 255), 32, // segments
 2.0f // thickness);
// 선
draw_list->AddLine(ImVec2(pos.x, pos.y), ImVec2(pos.x + 100, pos.y + 50), IM_COL32(255, 255, 0, 255), 2.0f);
// 텍스트
draw_list->AddText(ImVec2(pos.x + 10, pos.y + 10), IM_COL32(255, 255, 255, 255), "Custom Text");
// 커서 이동 (공간 확보)
ImGui: :Dummy(ImVec2(100, 50));
```
=== 게이지 커스텀 위젯
```cpp
void render_gauge(const char* label, float value, float min_val, float max_val) {
 ImDrawList* draw_list = ImGui: :GetWindowDrawList();
 ImVec2 pos = ImGui: :GetCursorScreenPos();
 const float radius = 80.0f;
 const ImVec2 center(pos.x + radius, pos.y + radius);
 // 배경 원
 draw_list->AddCircle(center, radius, IM_COL32(100, 100, 100, 255), 64, 2.0f);
 // 눈금
 for (int i = 0; i \<= 10; i++) {
 float angle = -135.0f + (270.0f * i / 10.0f);
 float rad = angle * 3.14159f / 180.0f;
 float x1 = center.x + (radius - 10) * std: :cos(rad);
 float y1 = center.y + (radius - 10) * std: :sin(rad);
 float x2 = center.x + radius * std: :cos(rad);
 float y2 = center.y + radius * std: :sin(rad);
 draw_list->AddLine(ImVec2(x1, y1), ImVec2(x2, y2), IM_COL32(200, 200, 200, 255), 1.0f);
 }
 // 바늘
 float normalized = (value - min_val) / (max_val - min_val);
 float needle_angle = -135.0f + (270.0f * normalized);
 float needle_rad = needle_angle * 3.14159f / 180.0f;
 float needle_x = center.x + (radius - 20) * std: :cos(needle_rad);
 float needle_y = center.y + (radius - 20) * std: :sin(needle_rad);
 draw_list->AddLine(center, ImVec2(needle_x, needle_y), IM_COL32(255, 0, 0, 255), 3.0f);
 // 중심점
 draw_list->AddCircleFilled(center, 5.0f, IM_COL32(255, 0, 0, 255));
 // 텍스트
 char value_text[32];
 snprintf(value_text, sizeof(value_text), "%.1f", value);
 ImVec2 text_size = ImGui: :CalcTextSize(value_text);
 draw_list->AddText(ImVec2(center.x - text_size.x / 2, center.y + radius - 30), IM_COL32(255, 255, 255, 255), value_text);
 ImGui: :Dummy(ImVec2(radius * 2, radius * 2));
 ImGui: :Text("%s", label);
}
// 사용
render_gauge("Temperature", current_temp, 0.0f, 600.0f);
```
== 이미지 및 텍스처
=== 텍스처 로딩
```cpp
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
struct Texture {
 GLuint id;
 int width;
 int height;
};
Texture load_texture(const char* filename) {
 Texture texture{};
 int channels;
 unsigned char* data = stbi_load(filename, &texture.width, &texture.height, &channels, 4);
 if (!data) {
 std: :cerr \<< "Failed to load texture: " \<< filename \<< "\n";
 return texture;
 }
 glGenTextures(1, &texture.id);
 glBindTexture(GL_TEXTURE_2D, texture.id);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture.width, texture.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
 stbi_image_free(data);
 return texture;
}
```
=== 이미지 표시
```cpp
// 텍스처 로딩 (초기화 시)
static Texture equipment_image = load_texture("equipment.png");
// 렌더링
ImGui: :Image((void*)(intptr_t)equipment_image.id, ImVec2(equipment_image.width, equipment_image.height));
// 크기 조정
ImGui: :Image((void*)(intptr_t)equipment_image.id, ImVec2(200, 150));
// 버튼으로 사용
if (ImGui: :ImageButton((void*)(intptr_t)equipment_image.id, ImVec2(64, 64))) {
 // 클릭 시 실행
}
```
== Tree & Collapsing Header
=== Tree
```cpp
if (ImGui: :TreeNode("Equipment List")) {
 for (const auto& equipment : equipment_list) {
 if (ImGui: :TreeNode(equipment.name.c_str())) {
 ImGui: :Text("ID: %s", equipment.id.c_str());
 ImGui: :Text("Status: %s", get_status_text(equipment.status).c_str());
 ImGui: :TreePop();
 }
 }
 ImGui: :TreePop();
}
```
=== Collapsing Header
```cpp
if (ImGui: :CollapsingHeader("Process Parameters")) {
 ImGui: :Text("Temperature: %.1f°C", current_temp);
 ImGui: :Text("Pressure: %.2f Torr", current_pressure);
 ImGui: :Text("Flow Rate: %.1f sccm", current_flow);
}
// 기본 열림
if (ImGui: :CollapsingHeader("Alarms", ImGuiTreeNodeFlags_DefaultOpen)) {
 // 알람 리스트
}
```
== 통합 예제: 고급 대시보드
```cpp
class AdvancedDashboard {
public: AdvancedDashboard() {
 temp_buffer_ = std: :make_unique<ScrollingBuffer>(1000);
 pressure_buffer_ = std: :make_unique<ScrollingBuffer>(1000);
 }
 void render() {
 render_control_panel();
 render_chart_panel();
 render_data_table();
 }
private: void render_control_panel() {
 ImGui: :Begin("Control Panel");
 // Equipment selector
 static int current_eq = 0;
 const char* equipment[] = {"CVD-01", "PVD-02", "ETCH-03"};
 ImGui: :Combo("Equipment", &current_eq, equipment, 3);
 // Gauges
 ImGui: :Columns(3);
 render_gauge("Temperature", current_temp_, 0.0f, 600.0f);
 ImGui: :NextColumn();
 render_gauge("Pressure", current_pressure_, 0.0f, 5.0f);
 ImGui: :NextColumn();
 render_gauge("Flow Rate", current_flow_, 0.0f, 200.0f);
 ImGui: :Columns(1);
 // Controls
 if (ImGui: :Button("Start", ImVec2(100, 40))) {
 start_equipment();
 }
 ImGui: :SameLine();
 if (ImGui: :Button("Stop", ImVec2(100, 40))) {
 stop_equipment();
 }
 ImGui: :End();
 }
 void render_chart_panel() {
 ImGui: :Begin("Real-time Charts");
 // Update data
 update_buffers();
 // Temperature chart
 if (ImPlot: :BeginPlot("Temperature", ImVec2(-1, 200))) {
 ImPlot: :SetupAxes("Time (s)", "Temperature (°C)");
 ImPlot: :SetupAxisLimits(ImAxis_X1, time_ - 10, time_, ImGuiCond_Always);
 ImPlot: :SetupAxisLimits(ImAxis_Y1, 400, 500);
 ImPlot: :PlotLine("Temperature", &temp_buffer_->data()[0].x, &temp_buffer_->data()[0].y, temp_buffer_->size(), 0, temp_buffer_->offset(), 2 * sizeof(float));
 ImPlot: :EndPlot();
 }
 // Pressure chart
 if (ImPlot: :BeginPlot("Pressure", ImVec2(-1, 200))) {
 ImPlot: :SetupAxes("Time (s)", "Pressure (Torr)");
 ImPlot: :SetupAxisLimits(ImAxis_X1, time_ - 10, time_, ImGuiCond_Always);
 ImPlot: :SetupAxisLimits(ImAxis_Y1, 2.0, 3.0);
 ImPlot: :PlotLine("Pressure", &pressure_buffer_->data()[0].x, &pressure_buffer_->data()[0].y, pressure_buffer_->size(), 0, pressure_buffer_->offset(), 2 * sizeof(float));
 ImPlot: :EndPlot();
 }
 ImGui: :End();
 }
 void render_data_table() {
 ImGui: :Begin("Process History");
 if (ImGui: :BeginTable("history", 4, ImGuiTableFlags_ScrollY |
 ImGuiTableFlags_RowBg |
 ImGuiTableFlags_Borders)) {
 ImGui: :TableSetupScrollFreeze(0, 1);
 ImGui: :TableSetupColumn("Time");
 ImGui: :TableSetupColumn("Temperature");
 ImGui: :TableSetupColumn("Pressure");
 ImGui: :TableSetupColumn("Flow Rate");
 ImGui: :TableHeadersRow();
 for (const auto& data : history_) {
 ImGui: :TableNextRow();
 ImGui: :TableNextColumn();
 ImGui: :Text("%.2f", data.time);
 ImGui: :TableNextColumn();
 ImGui: :Text("%.1f", data.temperature);
 ImGui: :TableNextColumn();
 ImGui: :Text("%.2f", data.pressure);
 ImGui: :TableNextColumn();
 ImGui: :Text("%.1f", data.flow_rate);
 }
 ImGui: :EndTable();
 }
 ImGui: :End();
 }
 void update_buffers() {
 time_ += ImGui: :GetIO().DeltaTime;
 temp_buffer_->add_point(time_, current_temp_);
 pressure_buffer_->add_point(time_, current_pressure_);
 }
 std: :unique_ptr<ScrollingBuffer> temp_buffer_;
 std: :unique_ptr<ScrollingBuffer> pressure_buffer_;
 float time_ = 0.0f;
 float current_temp_ = 450.0f;
 float current_pressure_ = 2.5f;
 float current_flow_ = 100.0f;
 std: :vector<ProcessData> history_;
};
```
== 실습 과제
=== 과제 1: 실시간 차트
+ ImPlot으로 3개 파라미터 차트
+ 자동 스크롤링
+ 축 범위 자동 조정
=== 과제 2: 커스텀 게이지
+ 원형 게이지 위젯 구현
+ 색상 변화 (범위 초과 시 빨강)
+ 애니메이션 효과
=== 과제 3: 데이터 테이블
+ Table API로 공정 이력 표시
+ 정렬 기능
+ 필터링
== 요약
이번 챕터에서는 고급 위젯을 학습했다: - Table API
- ImPlot 실시간 차트
- 커스텀 렌더링 (DrawList)
- 게이지 위젯
- 이미지 및 텍스처
- Tree & Collapsing Header
다음 챕터에서는 더 고급 기능을 학습한다.
#pagebreak()