= Week 13: ImGui 통합 프로젝트

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ 종합 HMI 시스템 설계
+ 아키텍처 패턴 적용
+ 테스트 및 디버깅
+ 배포 및 문서화

== 프로젝트 개요

=== 요구사항

*기능 요구사항*:
+ 다중 장비 모니터링 (최소 3대)
+ 실시간 데이터 수집 및 차트 표시
+ 알람 시스템
+ 공정 레시피 관리
+ 데이터 로깅 (CSV/데이터베이스)
+ 네트워크 통신 (TCP/OPC UA)

*비기능 요구사항*:
+ 60 FPS 이상 렌더링
+ 100ms 이내 데이터 업데이트
+ 99.9% 가용성
+ SEMI E95 표준 준수

== 아키텍처 설계

=== 계층 구조

```
┌─────────────────────────────────┐
│     Presentation Layer          │
│     (ImGui UI)                  │
├─────────────────────────────────┤
│     Application Layer           │
│     (Business Logic)            │
├─────────────────────────────────┤
│     Domain Layer                │
│     (Equipment, Recipe, Alarm)  │
├─────────────────────────────────┤
│     Infrastructure Layer        │
│     (Network, Database, File)   │
└─────────────────────────────────┘
```

=== 클래스 다이어그램

```cpp
// Domain Layer
class Equipment {
public:
    std::string id;
    std::string name;
    EquipmentType type;
    EquipmentStatus status;

    ProcessData current_data;
    std::vector<ProcessData> history;

    void start();
    void stop();
    void update_data(const ProcessData& data);
};

class Recipe {
public:
    std::string id;
    std::string name;
    std::vector<RecipeStep> steps;

    void load_from_file(const std::string& filename);
    void save_to_file(const std::string& filename);
};

class Alarm {
public:
    AlarmSeverity severity;
    std::string message;
    std::chrono::system_clock::time_point timestamp;
    bool acknowledged;

    void acknowledge();
};

// Application Layer
class EquipmentManager {
public:
    void add_equipment(std::unique_ptr<Equipment> eq);
    Equipment* get_equipment(const std::string& id);
    std::vector<Equipment*> get_all_equipment();

    void start_all();
    void stop_all();
};

class AlarmManager {
public:
    void add_alarm(Alarm alarm);
    std::vector<Alarm> get_active_alarms();
    void acknowledge_alarm(size_t index);
    void clear_all();
};

class DataLogger {
public:
    void start_logging(const std::string& filename);
    void stop_logging();
    void log_data(const std::string& equipment_id, const ProcessData& data);
};

// Infrastructure Layer
class TcpCommunicator {
public:
    void connect(const std::string& host, uint16_t port);
    void disconnect();
    void send_command(const std::string& command);
    void set_data_callback(std::function<void(const std::string&)> callback);
};

class DatabaseManager {
public:
    void connect(const std::string& connection_string);
    void insert_data(const ProcessData& data);
    std::vector<ProcessData> query_data(
        const std::string& equipment_id,
        const std::chrono::system_clock::time_point& start,
        const std::chrono::system_clock::time_point& end
    );
};
```

== 구현

=== main.cpp

```cpp
#include \<GLFW/glfw3.h>
#include \<imgui.h>
#include \<imgui_impl_glfw.h>
#include \<imgui_impl_opengl3.h>
#include \<implot.h>

#include "application.h"
#include "config.h"
#include "logging.h"

int main(int argc, char** argv) {
    // 로깅 설정
    setup_logging();
    spdlog::info("Application starting...");

    // 설정 로드
    AppConfig config;
    try {
        config = AppConfig::from_file("config.json");
    } catch (const std::exception& e) {
        spdlog::error("Failed to load config: {}", e.what());
        config = AppConfig::default_config();
    }

    // GLFW 초기화
    if (!glfwInit()) {
        spdlog::error("Failed to initialize GLFW");
        return -1;
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // 윈도우 생성
    GLFWwindow* window = glfwCreateWindow(
        1920, 1080, "Semiconductor HMI System", nullptr, nullptr
    );
    if (!window) {
        spdlog::error("Failed to create window");
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // ImGui 초기화
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImPlot::CreateContext();

    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
    io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;

    // 스타일
    setup_imgui_style();

    // 백엔드 초기화
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    // 애플리케이션 생성
    Application app(config);
    app.initialize();

    spdlog::info("Entering main loop");

    // 메인 루프
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        // ImGui 프레임 시작
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // 애플리케이션 렌더링
        app.render();

        // ImGui 렌더링
        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        // Multi-viewport
        if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
            GLFWwindow* backup_current_context = glfwGetCurrentContext();
            ImGui::UpdatePlatformWindows();
            ImGui::RenderPlatformWindowsDefault();
            glfwMakeContextCurrent(backup_current_context);
        }

        glfwSwapBuffers(window);
    }

    // 정리
    app.shutdown();

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImPlot::DestroyContext();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    spdlog::info("Application shutdown complete");
    return 0;
}
```

=== Application 클래스

```cpp
// application.h
#pragma once
#include "equipment_manager.h"
#include "alarm_manager.h"
#include "data_logger.h"
#include "tcp_communicator.h"
#include "config.h"

class Application {
public:
    explicit Application(const AppConfig& config);
    ~Application();

    void initialize();
    void shutdown();
    void render();

private:
    void render_menu_bar();
    void render_equipment_panel();
    void render_chart_panel();
    void render_alarm_panel();
    void render_recipe_panel();
    void render_settings_panel();

    void update();
    void handle_alarms();

    AppConfig config_;
    std::unique_ptr<EquipmentManager> equipment_manager_;
    std::unique_ptr<AlarmManager> alarm_manager_;
    std::unique_ptr<DataLogger> data_logger_;
    std::unique_ptr<TcpCommunicator> communicator_;

    asio::io_context io_context_;
    std::jthread io_thread_;
    std::jthread update_thread_;

    bool show_settings_ = false;
    bool show_recipe_editor_ = false;
};

// application.cpp
Application::Application(const AppConfig& config)
    : config_(config)
    , equipment_manager_(std::make_unique<EquipmentManager>())
    , alarm_manager_(std::make_unique<AlarmManager>())
    , data_logger_(std::make_unique<DataLogger>())
    , communicator_(std::make_unique<TcpCommunicator>(io_context_)) {
}

void Application::initialize() {
    spdlog::info("Initializing application");

    // 장비 초기화
    for (const auto& eq_config : config_.equipment) {
        auto equipment = std::make_unique<Equipment>(
            eq_config.id, eq_config.name, eq_config.type
        );
        equipment_manager_->add_equipment(std::move(equipment));
    }

    // 통신 초기화
    communicator_->connect(config_.connection.host, config_.connection.port);
    communicator_->set_data_callback([this](const std::string& data) {
        // 데이터 파싱 및 처리
        process_received_data(data);
    });

    // I/O 컨텍스트 스레드
    io_thread_ = std::jthread([this](std::stop_token stoken) {
        while (!stoken.stop_requested()) {
            io_context_.run_for(std::chrono::milliseconds(10));
        }
    });

    // 업데이트 스레드
    update_thread_ = std::jthread([this](std::stop_token stoken) {
        while (!stoken.stop_requested()) {
            update();
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    });

    // 데이터 로깅 시작
    data_logger_->start_logging("process_data.csv");

    spdlog::info("Application initialized");
}

void Application::render() {
    // Docking 설정
    ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->Pos);
    ImGui::SetNextWindowSize(viewport->Size);
    ImGui::SetNextWindowViewport(viewport->ID);

    ImGuiWindowFlags window_flags =
        ImGuiWindowFlags_NoDocking |
        ImGuiWindowFlags_NoTitleBar |
        ImGuiWindowFlags_NoCollapse |
        ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoBringToFrontOnFocus |
        ImGuiWindowFlags_NoNavFocus |
        ImGuiWindowFlags_MenuBar;

    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
    ImGui::Begin("DockSpace", nullptr, window_flags);
    ImGui::PopStyleVar();

    // Dockspace
    ImGuiID dockspace_id = ImGui::GetID("MainDockspace");
    ImGui::DockSpace(dockspace_id, ImVec2(0, 0), ImGuiDockNodeFlags_None);

    render_menu_bar();

    ImGui::End();

    // 패널 렌더링
    render_equipment_panel();
    render_chart_panel();
    render_alarm_panel();

    if (show_recipe_editor_) {
        render_recipe_panel();
    }

    if (show_settings_) {
        render_settings_panel();
    }
}

void Application::render_equipment_panel() {
    ImGui::Begin("Equipment Control");

    auto equipments = equipment_manager_->get_all_equipment();

    for (auto* eq : equipments) {
        ImGui::PushID(eq->id.c_str());

        if (ImGui::CollapsingHeader(eq->name.c_str(),
            ImGuiTreeNodeFlags_DefaultOpen)) {

            ImGui::Text("Status: %s", get_status_text(eq->status).c_str());

            ImGui::Spacing();

            // 게이지
            render_gauge("Temperature", eq->current_data.temperature, 0, 600);
            ImGui::SameLine();
            render_gauge("Pressure", eq->current_data.pressure, 0, 5);
            ImGui::SameLine();
            render_gauge("Flow Rate", eq->current_data.flow_rate, 0, 200);

            ImGui::Spacing();

            // 제어 버튼
            if (eq->status == EquipmentStatus::Idle) {
                if (ImGui::Button("Start", ImVec2(100, 40))) {
                    eq->start();
                    spdlog::info("Equipment {} started", eq->id);
                }
            } else if (eq->status == EquipmentStatus::Running) {
                if (ImGui::Button("Stop", ImVec2(100, 40))) {
                    eq->stop();
                    spdlog::info("Equipment {} stopped", eq->id);
                }
            }
        }

        ImGui::PopID();
        ImGui::Separator();
    }

    ImGui::End();
}

void Application::render_chart_panel() {
    ImGui::Begin("Real-time Charts");

    auto equipments = equipment_manager_->get_all_equipment();

    if (ImGui::BeginTabBar("EquipmentTabs")) {
        for (auto* eq : equipments) {
            if (ImGui::BeginTabItem(eq->name.c_str())) {
                render_equipment_charts(eq);
                ImGui::EndTabItem();
            }
        }
        ImGui::EndTabBar();
    }

    ImGui::End();
}

void Application::render_alarm_panel() {
    ImGui::Begin("Alarms");

    auto alarms = alarm_manager_->get_active_alarms();

    if (alarms.empty()) {
        ImGui::TextColored(ImVec4(0, 1, 0, 1), "No active alarms");
    } else {
        if (ImGui::Button("Clear All")) {
            alarm_manager_->clear_all();
        }

        ImGui::Separator();

        for (size_t i = 0; i \< alarms.size(); ++i) {
            const auto& alarm = alarms[i];

            ImGui::PushID(static_cast<int>(i));

            // 색상
            ImVec4 color = get_alarm_color(alarm.severity);
            ImGui::PushStyleColor(ImGuiCol_ChildBg, color);

            ImGui::BeginChild("Alarm", ImVec2(0, 80), true);

            ImGui::TextWrapped("%s", alarm.message.c_str());
            ImGui::Text("Time: %s", format_time(alarm.timestamp).c_str());

            if (!alarm.acknowledged) {
                if (ImGui::Button("Acknowledge")) {
                    alarm_manager_->acknowledge_alarm(i);
                }
            } else {
                ImGui::TextColored(ImVec4(0, 1, 0, 1), "Acknowledged");
            }

            ImGui::EndChild();
            ImGui::PopStyleColor();

            ImGui::PopID();
        }
    }

    ImGui::End();
}
```

== 테스트

=== 단위 테스트 (Catch2)

```cpp
#define CATCH_CONFIG_MAIN
#include \<catch2/catch.hpp>

#include "equipment.h"
#include "alarm_manager.h"

TEST_CASE("Equipment status transitions", "[equipment]") {
    Equipment eq("CVD-01", "Chemical Vapor Deposition", EquipmentType::CVD);

    SECTION("Initial status is Idle") {
        REQUIRE(eq.status == EquipmentStatus::Idle);
    }

    SECTION("Start changes status to Running") {
        eq.start();
        REQUIRE(eq.status == EquipmentStatus::Running);
    }

    SECTION("Stop changes status to Idle") {
        eq.start();
        eq.stop();
        REQUIRE(eq.status == EquipmentStatus::Idle);
    }
}

TEST_CASE("Alarm management", "[alarm]") {
    AlarmManager manager;

    SECTION("New alarm is added") {
        Alarm alarm{AlarmSeverity::Warning, "Test alarm",
                    std::chrono::system_clock::now(), false};
        manager.add_alarm(alarm);

        auto alarms = manager.get_active_alarms();
        REQUIRE(alarms.size() == 1);
        REQUIRE(alarms[0].message == "Test alarm");
    }

    SECTION("Alarm can be acknowledged") {
        Alarm alarm{AlarmSeverity::Warning, "Test alarm",
                    std::chrono::system_clock::now(), false};
        manager.add_alarm(alarm);
        manager.acknowledge_alarm(0);

        auto alarms = manager.get_active_alarms();
        REQUIRE(alarms[0].acknowledged == true);
    }
}
```

== 배포

=== CMake 릴리스 빌드

```cmake
# Release 빌드 옵션
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# 의존성 정적 링크
if(WIN32)
    set(CMAKE_EXE_LINKER_FLAGS "-static")
endif()

# 리소스 파일 복사
add_custom_command(TARGET hmi POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/resources
    $\<TARGET_FILE_DIR:hmi>/resources
)

add_custom_command(TARGET hmi POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_SOURCE_DIR}/config.json
    $\<TARGET_FILE_DIR:hmi>/config.json
)
```

=== 빌드 및 패키징

```bash
# 빌드
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# 패키징 (CPack)
cpack -G ZIP
```

== 문서화

=== README.md

```markdown
# Semiconductor HMI System

## 기능
- 다중 장비 실시간 모니터링
- 알람 시스템
- 데이터 로깅
- 공정 레시피 관리

## 요구사항
- C++20 컴파일러
- OpenGL 3.3+
- CMake 3.20+

## 빌드
```bash
mkdir build && cd build
cmake ..
cmake --build .
```

## 실행
```bash
./hmi
```

## 설정
`config.json` 파일을 수정하여 설정 변경
```

== 실습 과제

=== 최종 프로젝트

다음 요구사항을 만족하는 통합 HMI 시스템 개발:

+ *기능*
  - 3대 이상 장비 모니터링
  - 실시간 차트 (최소 3개 파라미터)
  - 알람 시스템 (3단계 이상)
  - 데이터 로깅
  - 네트워크 통신 또는 시뮬레이션

+ *품질*
  - 단위 테스트 (커버리지 70% 이상)
  - 문서화 (README, 사용자 가이드)
  - SEMI E95 표준 준수

+ *성능*
  - 60 FPS 이상
  - 100ms 이내 데이터 업데이트
  - 메모리 누수 없음

+ *제출물*
  - 소스 코드
  - 빌드 스크립트
  - 테스트 결과
  - 문서
  - 실행 영상 (선택)

== 요약

13주 동안 HCI/HMI 이론부터 실제 구현까지 학습했습니다:

*Week 1-5: C\# WPF*
- HCI 이론 및 SEMI 표준
- MVVM 패턴
- 실시간 데이터 및 차트
- 고급 UI 컨트롤
- 테스트 및 배포

*Week 6-9: Python PySide6*
- Signal/Slot 메커니즘
- PyQtGraph 차트
- 고급 통신 (TCP, OPC UA, Modbus)
- PyInstaller 배포

*Week 10-13: ImGui C++*
- Immediate Mode GUI
- ImPlot 실시간 차트
- 멀티스레딩 및 Asio
- 통합 프로젝트

이제 실무에서 반도체 장비 HMI를 개발할 수 있습니다!

#pagebreak()
