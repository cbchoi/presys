= Week 10: ImGui C++ 기초 및 OpenGL 통합

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ ImGui 아키�ecture 이해
+ OpenGL/GLFW 통합
+ 기본 위젯 사용
+ Immediate Mode GUI 개념

== Immediate Mode GUI

=== Retained Mode vs Immediate Mode

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: left,
    [*특성*], [*Retained Mode*], [*Immediate Mode*],
    [상태 관리], [프레임워크가 관리], [애플리케이션이 관리],
    [렌더링], [변경 시만], [매 프레임],
    [메모리], [많음], [적음],
    [복잡도], [높음], [낮음],
    [예시], [WPF, Qt], [ImGui],
  ),
  caption: "GUI 모드 비교"
)

=== ImGui 장점

- 빠른 개발 속도
- 낮은 메모리 사용
- 실시간 시스템에 적합
- 디버깅 도구로 활용

== 환경 설정

=== CMake 설정

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(SemiconductorHMI)

set(CMAKE_CXX_STANDARD 20)

# GLFW
find_package(glfw3 3.3 REQUIRED)

# OpenGL
find_package(OpenGL REQUIRED)

# ImGui
add_library(imgui
    imgui/imgui.cpp
    imgui/imgui_demo.cpp
    imgui/imgui_draw.cpp
    imgui/imgui_tables.cpp
    imgui/imgui_widgets.cpp
    imgui/backends/imgui_impl_glfw.cpp
    imgui/backends/imgui_impl_opengl3.cpp
)

target_include_directories(imgui PUBLIC
    imgui
    imgui/backends
)

# 메인 실행 파일
add_executable(hmi main.cpp)
target_link_libraries(hmi
    imgui
    glfw
    OpenGL::GL
)
```

=== 기본 애플리케이션

```cpp
// main.cpp
#include \<GLFW/glfw3.h>
#include \<imgui.h>
#include \<imgui_impl_glfw.h>
#include \<imgui_impl_opengl3.h>
#include \<iostream>

int main() {
    // GLFW 초기화
    if (!glfwInit()) {
        std::cerr \<< "Failed to initialize GLFW\n";
        return -1;
    }

    // OpenGL 버전 설정
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // 윈도우 생성
    GLFWwindow* window = glfwCreateWindow(
        1280, 720, "Semiconductor HMI", nullptr, nullptr
    );
    if (!window) {
        std::cerr \<< "Failed to create window\n";
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1); // V-Sync

    // ImGui 초기화
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    // 스타일
    ImGui::StyleColorsDark();

    // 백엔드 설정
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    // 메인 루프
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        // ImGui 프레임 시작
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // UI 렌더링
        ImGui::Begin("Semiconductor Equipment");
        ImGui::Text("Temperature: 450.0°C");
        if (ImGui::Button("Start")) {
            std::cout \<< "Start clicked\n";
        }
        ImGui::End();

        // 렌더링
        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    // 정리
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
```

== 기본 위젯

=== Text

```cpp
ImGui::Text("Simple text");
ImGui::TextColored(ImVec4(1.0f, 0.0f, 0.0f, 1.0f), "Red text");
ImGui::TextWrapped("Very long text that will wrap...");

// 포맷팅
float temp = 450.0f;
ImGui::Text("Temperature: %.1f°C", temp);
```

=== Button

```cpp
if (ImGui::Button("Start")) {
    // 클릭 시 실행
    start_equipment();
}

// 크기 지정
if (ImGui::Button("Large Button", ImVec2(200, 50))) {
    // ...
}

// 비활성화
ImGui::BeginDisabled(is_running);
if (ImGui::Button("Start")) {
    // ...
}
ImGui::EndDisabled();
```

=== Input

```cpp
// Text input
static char buffer[256] = "";
ImGui::InputText("Equipment ID", buffer, sizeof(buffer));

// Numeric input
static float temperature = 450.0f;
ImGui::InputFloat("Temperature", &temperature);

// Slider
ImGui::SliderFloat("Setpoint", &temperature, 0.0f, 600.0f);

// Drag
ImGui::DragFloat("Pressure", &pressure, 0.1f, 0.0f, 5.0f);
```

=== Checkbox & Radio

```cpp
// Checkbox
static bool enable_alarm = true;
ImGui::Checkbox("Enable Alarm", &enable_alarm);

// Radio buttons
static int equipment_type = 0;
ImGui::RadioButton("CVD", &equipment_type, 0);
ImGui::SameLine();
ImGui::RadioButton("PVD", &equipment_type, 1);
ImGui::SameLine();
ImGui::RadioButton("ETCH", &equipment_type, 2);
```

=== Combo

```cpp
static int current_item = 0;
const char* items[] = {"CVD-01", "PVD-02", "ETCH-03", "CMP-04"};
ImGui::Combo("Equipment", &current_item, items, IM_ARRAYSIZE(items));
```

== 레이아웃

=== 윈도우

```cpp
// 기본 윈도우
ImGui::Begin("Main Window");
// ... 내용
ImGui::End();

// 플래그
ImGui::Begin("Fixed Window",
    nullptr,
    ImGuiWindowFlags_NoResize |
    ImGuiWindowFlags_NoMove |
    ImGuiWindowFlags_NoCollapse
);
ImGui::End();

// 크기 설정
ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);
ImGui::Begin("Sized Window");
ImGui::End();
```

=== 수평/수직 레이아웃

```cpp
// 수평
ImGui::Text("Label");
ImGui::SameLine();
ImGui::Button("Button");

// 간격
ImGui::Text("Text 1");
ImGui::SameLine(0, 20); // 20px 간격
ImGui::Text("Text 2");

// 수직 간격
ImGui::Spacing();
ImGui::Separator();
```

=== Child Window

```cpp
ImGui::BeginChild("Left Pane", ImVec2(200, 0), true);
ImGui::Text("Equipment List");
// ...
ImGui::EndChild();

ImGui::SameLine();

ImGui::BeginChild("Right Pane", ImVec2(0, 0), true);
ImGui::Text("Details");
// ...
ImGui::EndChild();
```

=== Columns

```cpp
ImGui::Columns(3, "equipment_columns");
ImGui::Separator();

// Header
ImGui::Text("ID"); ImGui::NextColumn();
ImGui::Text("Type"); ImGui::NextColumn();
ImGui::Text("Status"); ImGui::NextColumn();
ImGui::Separator();

// Rows
ImGui::Text("CVD-01"); ImGui::NextColumn();
ImGui::Text("CVD"); ImGui::NextColumn();
ImGui::Text("Running"); ImGui::NextColumn();

ImGui::Columns(1);
```

== 스타일

=== 색상

```cpp
ImGuiStyle& style = ImGui::GetStyle();

// 배경색
style.Colors[ImGuiCol_WindowBg] = ImVec4(0.1f, 0.1f, 0.1f, 1.0f);

// 버튼
style.Colors[ImGuiCol_Button] = ImVec4(0.2f, 0.4f, 0.8f, 1.0f);
style.Colors[ImGuiCol_ButtonHovered] = ImVec4(0.3f, 0.5f, 0.9f, 1.0f);
style.Colors[ImGuiCol_ButtonActive] = ImVec4(0.15f, 0.35f, 0.7f, 1.0f);

// 임시 색상 변경
ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(1.0f, 0.0f, 0.0f, 1.0f));
ImGui::Button("Red Button");
ImGui::PopStyleColor();
```

=== 크기 및 간격

```cpp
style.WindowPadding = ImVec2(15, 15);
style.FramePadding = ImVec2(8, 4);
style.ItemSpacing = ImVec2(10, 5);
style.WindowRounding = 5.0f;
style.FrameRounding = 3.0f;
```

== 데이터 모델

=== Equipment 클래스

```cpp
// equipment.h
#pragma once
#include \<string>
#include \<chrono>

enum class EquipmentStatus {
    Idle,
    Running,
    Paused,
    Error
};

struct ProcessData {
    std::chrono::system_clock::time_point timestamp;
    float temperature;
    float pressure;
    float flow_rate;

    ProcessData()
        : timestamp(std::chrono::system_clock::now())
        , temperature(0.0f)
        , pressure(0.0f)
        , flow_rate(0.0f) {}
};

class Equipment {
public:
    Equipment(std::string id, std::string name)
        : id_(std::move(id))
        , name_(std::move(name))
        , status_(EquipmentStatus::Idle) {}

    const std::string& id() const { return id_; }
    const std::string& name() const { return name_; }
    EquipmentStatus status() const { return status_; }
    const ProcessData& current_data() const { return current_data_; }

    void start() {
        status_ = EquipmentStatus::Running;
    }

    void stop() {
        status_ = EquipmentStatus::Idle;
    }

    void update_data(const ProcessData& data) {
        current_data_ = data;
    }

private:
    std::string id_;
    std::string name_;
    EquipmentStatus status_;
    ProcessData current_data_;
};
```

== 실습: 기본 HMI

```cpp
class HMIApplication {
public:
    HMIApplication() {
        equipment_ = std::make_unique<Equipment>("CVD-01", "Chemical Vapor Deposition");
    }

    void render() {
        render_main_window();
        render_equipment_panel();
        render_data_panel();
    }

private:
    void render_main_window() {
        ImGui::SetNextWindowPos(ImVec2(0, 0));
        ImGui::SetNextWindowSize(ImGui::GetIO().DisplaySize);
        ImGui::Begin("Main", nullptr,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoCollapse |
            ImGuiWindowFlags_NoBringToFrontOnFocus |
            ImGuiWindowFlags_MenuBar
        );

        if (ImGui::BeginMenuBar()) {
            if (ImGui::BeginMenu("File")) {
                if (ImGui::MenuItem("Exit")) {
                    // 종료
                }
                ImGui::EndMenu();
            }
            ImGui::EndMenuBar();
        }

        ImGui::End();
    }

    void render_equipment_panel() {
        ImGui::Begin("Equipment Control");

        ImGui::Text("Equipment: %s", equipment_->name().c_str());
        ImGui::Text("ID: %s", equipment_->id().c_str());

        // Status
        const char* status_text = get_status_text(equipment_->status());
        ImGui::Text("Status: %s", status_text);

        // Controls
        if (equipment_->status() == EquipmentStatus::Idle) {
            if (ImGui::Button("Start", ImVec2(100, 40))) {
                equipment_->start();
            }
        } else {
            if (ImGui::Button("Stop", ImVec2(100, 40))) {
                equipment_->stop();
            }
        }

        ImGui::End();
    }

    void render_data_panel() {
        ImGui::Begin("Process Data");

        const auto& data = equipment_->current_data();

        ImGui::Text("Temperature: %.1f°C", data.temperature);
        ImGui::Text("Pressure: %.2f Torr", data.pressure);
        ImGui::Text("Flow Rate: %.1f sccm", data.flow_rate);

        ImGui::End();
    }

    const char* get_status_text(EquipmentStatus status) {
        switch (status) {
            case EquipmentStatus::Idle: return "Idle";
            case EquipmentStatus::Running: return "Running";
            case EquipmentStatus::Paused: return "Paused";
            case EquipmentStatus::Error: return "Error";
            default: return "Unknown";
        }
    }

    std::unique_ptr<Equipment> equipment_;
};
```

== 실습 과제

=== 과제 1: 기본 HMI 구현

+ 메인 윈도우 with 메뉴바
+ 장비 선택 콤보박스
+ 시작/정지 버튼
+ 파라미터 표시

=== 과제 2: 레이아웃 구성

+ 3-column 레이아웃
+ Child windows
+ 스타일 커스터마이징

=== 과제 3: 데이터 모델

+ Equipment 클래스 확장
+ ProcessData 관리
+ 상태 머신 구현

== 요약

이번 챕터에서는 ImGui 기초를 학습했습니다:

- Immediate Mode GUI 개념
- OpenGL/GLFW 통합
- 기본 위젯 (Text, Button, Input 등)
- 레이아웃 (Window, Columns 등)
- 스타일링
- 데이터 모델 설계

다음 챕터에서는 고급 위젯을 학습합니다.

#pagebreak()
