= Week 13: ImGui 통합 프로젝트
== 학습 목표
본 챕터에서는 다음을 학습한다: + 소프트웨어 아키텍처 원칙(SOLID, DRY) 이해
+ 시스템 통합 전략 수립
+ 아키텍처 패턴 적용
+ 완전한 반도체 HMI 시스템 구축
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *모든 이전 주차 완료*: Week 1-12의 모든 개념과 기술
- *C++ 고급*: RAII, 스마트 포인터, 템플릿, STL 컨테이너
- *멀티스레딩*: std: :thread, std: :mutex, std: :condition_variable
- *네트워킹 기초*: TCP/IP, 소켓 프로그래밍
- *디자인 패턴*: Strategy, Factory, Observer, Singleton
- *권장사항*: CMake, Git 사용 경험
== 소프트웨어 아키텍처 원칙
=== SOLID 원칙의 역사
SOLID 원칙은 Robert C. Martin(Uncle Bob)이 2000년대 초반 정립한 객체지향 설계 원칙이다. Michael Feathers가 "SOLID"라는 약어를 만들었다.
==== 1. Single Responsibility Principle (SRP)
*원칙*: 클래스는 하나의 책임만 가져야 한다. 변경의 이유가 오직 하나여야 한다.
*나쁜 예: *
```cpp
class EquipmentController {
public: void ReadSensor() { /* 센서 읽기 */ }
    void SaveToDatabase() { /* DB 저장 */ }
    void RenderUI() { /* UI 렌더링 */ }
    void SendEmail() { /* 이메일 전송 */ }
};
// 문제: 4가지 책임 → 4가지 변경 이유
```
*좋은 예: *
```cpp
class SensorReader {
public: ProcessData ReadSensor();
};
class DataRepository {
public: void Save(const ProcessData& data);
};
class EquipmentView {
public: void Render(const ProcessData& data);
};
class NotificationService {
public: void SendAlert(const std: :string& message);
};
// 각 클래스는 하나의 책임만 가짐
```
==== 2. Open/Closed Principle (OCP)
*원칙*: 확장에는 열려있고, 수정에는 닫혀있어야 한다.
*나쁜 예: *
```cpp
class ChartRenderer {
public: void Render(ChartType type, const Data& data) {
        if (type == ChartType: :Line) {
            // 라인 차트 그리기
        } else if (type == ChartType: :Bar) {
            // 바 차트 그리기
        } else if (type == ChartType: :Pie) {
            // 파이 차트 그리기 (새로 추가 시 이 함수 수정!)
        }
    }
};
```
*좋은 예 (Strategy Pattern): *
```cpp
class IChartStrategy {
public: virtual ~IChartStrategy() = default;
    virtual void Render(const Data& data) = 0;
};
class LineChartStrategy : public IChartStrategy {
    void Render(const Data& data) override { /* 라인 차트 */ }
};
class BarChartStrategy : public IChartStrategy {
    void Render(const Data& data) override { /* 바 차트 */ }
};
// 새 차트 추가 시 기존 코드 수정 불필요
class PieChartStrategy : public IChartStrategy {
    void Render(const Data& data) override { /* 파이 차트 */ }
};
```
==== 3. Liskov Substitution Principle (LSP)
*원칙*: 서브타입은 기반 타입으로 대체 가능해야 한다.
*나쁜 예: *
```cpp
class Rectangle {
public: void SetWidth(int w) { width_ = w; }
    void SetHeight(int h) { height_ = h; }
    int GetArea() const { return width_ * height_; }
private: int width_, height_;
};
class Square : public Rectangle {
public: void SetWidth(int w) override {
        width_ = w;
        height_ = w;  // 정사각형이므로 같이 설정
    }
    void SetHeight(int h) override {
        width_ = h;
        height_ = h;
    }
};
// 문제 발생:
void Test(Rectangle& rect) {
    rect.SetWidth(5);
    rect.SetHeight(4);
    assert(rect.GetArea() == 20);  // Square일 경우 16! (실패)
}
```
*좋은 예: *
```cpp
class Shape {
public: virtual ~Shape() = default;
    virtual int GetArea() const = 0;
};
class Rectangle : public Shape {
public: Rectangle(int w, int h) : width_(w), height_(h) {}
    int GetArea() const override { return width_ * height_; }
private: int width_, height_;
};
class Square : public Shape {
public: Square(int side) : side_(side) {}
    int GetArea() const override { return side_ * side_; }
private: int side_;
};
// 이제 LSP 위반 없음
```
==== 4. Interface Segregation Principle (ISP)
*원칙*: 클라이언트는 사용하지 않는 인터페이스에 의존하면 안 된다.
*나쁜 예: *
```cpp
class IEquipment {
public: virtual void Start() = 0;
    virtual void Stop() = 0;
    virtual void LoadRecipe() = 0;
    virtual void CleanChamber() = 0;
    virtual void CalibrateRobot() = 0;  // 로봇 없는 장비에는 불필요
};
class SimpleHeater : public IEquipment {
    void Start() override { /* 구현 */ }
    void Stop() override { /* 구현 */ }
    void LoadRecipe() override { /* 구현 */ }
    void CleanChamber() override { /* 구현 */ }
    void CalibrateRobot() override { /* 로봇 없는데?? */ }
};
```
*좋은 예: *
```cpp
class IControllable {
public: virtual void Start() = 0;
    virtual void Stop() = 0;
};
class IRecipeLoader {
public: virtual void LoadRecipe() = 0;
};
class ICleaner {
public: virtual void CleanChamber() = 0;
};
class IRobotEquipment {
public: virtual void CalibrateRobot() = 0;
};
// 필요한 인터페이스만 구현
class SimpleHeater : public IControllable, public IRecipeLoader, public ICleaner {
    void Start() override { /* 구현 */ }
    void Stop() override { /* 구현 */ }
    void LoadRecipe() override { /* 구현 */ }
    void CleanChamber() override { /* 구현 */ }
};
class RobotEquipment : public IControllable, public IRobotEquipment {
    void Start() override { /* 구현 */ }
    void Stop() override { /* 구현 */ }
    void CalibrateRobot() override { /* 구현 */ }
};
```
==== 5. Dependency Inversion Principle (DIP)
*원칙*: 고수준 모듈은 저수준 모듈에 의존하면 안 된다. 둘 다 추상화에 의존해야 한다.
*나쁜 예: *
```cpp
class MySQLDatabase {
public: void Save(const Data& data) { /* MySQL 저장 */ }
};
class DataLogger {
public: DataLogger() : db_(new MySQLDatabase()) {}
    void Log(const Data& data) {
        db_->Save(data);  // MySQL에 직접 의존!
    }
private: MySQLDatabase* db_;
};
// 나중에 PostgreSQL로 바꾸려면? DataLogger 수정 필요!
```
*좋은 예: *
```cpp
class IDatabase {
public: virtual ~IDatabase() = default;
    virtual void Save(const Data& data) = 0;
};
class MySQLDatabase : public IDatabase {
    void Save(const Data& data) override { /* MySQL 저장 */ }
};
class PostgreSQLDatabase : public IDatabase {
    void Save(const Data& data) override { /* PostgreSQL 저장 */ }
};
class DataLogger {
public: DataLogger(std: :shared_ptr<IDatabase> db) : db_(db) {}
    void Log(const Data& data) {
        db_->Save(data);  // 추상화에 의존
    }
private: std: :shared_ptr<IDatabase> db_;
};
// 사용:
auto db = std: :make_shared<PostgreSQLDatabase>();  // 쉽게 교체 가능
DataLogger logger(db);
```
=== DRY (Don't Repeat Yourself) 원칙
DRY 원칙은 Andy Hunt와 Dave Thomas가 "The Pragmatic Programmer"(1999)에서 제안했다.
*원칙*: 모든 지식은 시스템 내에서 단 하나의 명확한 표현을 가져야 한다.
*나쁜 예: *
```cpp
void RenderTemperature(float temp) {
    ImGui: :Text("Temperature: %.1f °C", temp);
    if (temp > 500) {
        ImGui: :TextColored(ImVec4(1, 0, 0, 1), "HIGH");
    } else if (temp < 100) {
        ImGui: :TextColored(ImVec4(0, 0, 1, 1), "LOW");
    }
}
void RenderPressure(float pressure) {
    ImGui: :Text("Pressure: %.2f Torr", pressure);
    if (pressure > 5) {
        ImGui: :TextColored(ImVec4(1, 0, 0, 1), "HIGH");
    } else if (pressure < 1) {
        ImGui: :TextColored(ImVec4(0, 0, 1, 1), "LOW");
    }
}
// 중복: 상태 표시 로직
```
*좋은 예: *
```cpp
void RenderStatusBadge(float value, float min, float max) {
    if (value > max) {
        ImGui: :TextColored(ImVec4(1, 0, 0, 1), "HIGH");
    } else if (value < min) {
        ImGui: :TextColored(ImVec4(0, 0, 1, 1), "LOW");
    } else {
        ImGui: :TextColored(ImVec4(0, 1, 0, 1), "NORMAL");
    }
}
void RenderTemperature(float temp) {
    ImGui: :Text("Temperature: %.1f °C", temp);
    RenderStatusBadge(temp, 100, 500);
}
void RenderPressure(float pressure) {
    ImGui: :Text("Pressure: %.2f Torr", pressure);
    RenderStatusBadge(pressure, 1, 5);
}
```
== 시스템 통합 전략
=== 계층형 아키텍처 (Layered Architecture)
```
┌─────────────────────────────────────┐
│   Presentation Layer (View)         │  ← ImGui UI
│   - 사용자 입력 수신                   │
│   - 데이터 시각화                      │
└──────────────┬──────────────────────┘
               │ Command/Query
               ↓
┌──────────────────────────────────────┐
│   Application Layer (Controller)     │  ← Business Logic
│   - Use Cases 구현                    │
│   - 트랜잭션 관리                      │
└──────────────┬──────────────────────┘
               │ Domain Operations
               ↓
┌──────────────────────────────────────┐
│   Domain Layer (Model)               │  ← Core Domain
│   - Equipment, Sensor, Alarm         │
│   - 비즈니스 규칙                      │
└──────────────┬──────────────────────┘
               │ Data Access
               ↓
┌──────────────────────────────────────┐
│   Infrastructure Layer               │  ← External Systems
│   - Database, Network, File I/O      │
│   - 외부 장비 통신                     │
└──────────────────────────────────────┘
```
*의존성 규칙*: 상위 계층은 하위 계층에 의존 가능, 하위는 상위에 의존 불가.
=== 산업 동향
==== 1. 마이크로서비스 아키텍처
*전통적 Monolithic: *
```
┌────────────────────────────┐
│     HMI Application        │
│  - UI                      │
│  - Business Logic          │
│  - Data Access             │
│  - Equipment Control       │
└────────────────────────────┘
    단일 프로세스, 배포 단위
```
*마이크로서비스: *
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ UI       │  │ Equipment│  │ Data     │
│ Service  │◄─┤ Control  │◄─┤ Service  │
│ (Web)    │  │ Service  │  │ (DB)     │
└──────────┘  └──────────┘  └──────────┘
      ▲             ▲             ▲
      └─────────────┴─────────────┘
           API Gateway / Message Bus
```
*장점: *
- 독립 배포 (UI만 업데이트 가능)
- 기술 스택 자유 (UI는 Web, 제어는 C++)
- 확장성 (트래픽 많은 서비스만 스케일)
*단점: *
- 복잡도 증가
- 네트워크 지연
- 디버깅 어려움
==== 2. Event-Driven Architecture
이벤트 기반 아키텍처는 시스템 간 느슨한 결합을 제공한다.
```
┌───────────┐   Event: ┌────────────┐
│  Sensor   │ TempChanged │  Alarm     │
│  Monitor  ├────────────►│  Service   │
└───────────┘             └────────────┘
                             │
                             │ Event: │ AlarmTriggered
                             ↓
                          ┌────────────┐
                          │  UI        │
                          │  Update    │
                          └────────────┘
```
*예제: *
```cpp
#include <functional>
#include <vector>
#include <string>
// Event Bus (Publish-Subscribe 패턴)
class EventBus {
public: using EventHandler = std: :function<void(const std: :string&)>;
    void Subscribe(const std: :string& eventType, EventHandler handler) {
        handlers_[eventType].push_back(handler);
    }
    void Publish(const std: :string& eventType, const std: :string& data) {
        auto it = handlers_.find(eventType);
        if (it != handlers_.end()) {
            for (auto& handler : it->second) {
                handler(data);
            }
        }
    }
private: std: :unordered_map<std: :string, std: :vector<EventHandler>> handlers_;
};
// 사용:
EventBus bus;
bus.Subscribe("TempChanged", [](const std: :string& data) {
    std: :cout << "Alarm Service: " << data << "\n";
});
bus.Subscribe("TempChanged", [](const std: :string& data) {
    std: :cout << "Logger: " << data << "\n";
});
bus.Publish("TempChanged", "Temperature: 550°C");
// 출력:
// Alarm Service: Temperature: 550°C
// Logger: Temperature: 550°C
```
==== 3. Cloud-Native HMI
*Edge Computing + Cloud: *
```
┌──────────────────┐
│  Factory Floor   │
│  ┌────────────┐  │
│  │   Edge     │  │  ← Local HMI (낮은 지연)
│  │   HMI      │  │
│  └─────┬──────┘  │
│        │         │
│        │ MQTT/   │
│        │ gRPC    │
│        ↓         │
│  ┌────────────┐  │
│  │  Edge      │  │  ← Data Aggregation
│  │  Gateway   │  │
│  └─────┬──────┘  │
└────────┼─────────┘
         │ HTTPS
         ↓
┌────────────────────┐
│   Cloud            │
│  ┌──────────────┐  │
│  │  Analytics   │  │  ← Big Data / ML
│  │  Dashboard   │  │
│  └──────────────┘  │
└────────────────────┘
```
*장점: *
- Edge: 실시간 제어 (< 10ms 지연)
- Cloud: 대규모 데이터 분석, 예지 보전
- Remote Monitoring: 전 세계 어디서나 접근
== 응용: 아키텍처 패턴
=== Layered Architecture (계층형 아키텍처)
완전한 구현 예제: ==== Domain Layer
```cpp
// Domain/ProcessData.h
#pragma once
#include <chrono>
#include <string>
namespace Domain {
struct ProcessData {
    std: :string equipmentId;
    double temperature;
    double pressure;
    double flowRate;
    std: :chrono: :system_clock: :time_point timestamp;
    bool IsNormal() const {
        return temperature >= 100 && temperature <= 500 &&
               pressure >= 1.0 && pressure <= 5.0 &&
               flowRate >= 50 && flowRate <= 200;
    }
};
enum class EquipmentStatus {
    Idle, Running, Error, Maintenance
};
class Equipment {
public: Equipment(std: :string id, std: :string name)
        : id_(std: :move(id)), name_(std: :move(name)), status_(EquipmentStatus: :Idle) {}
    const std: :string& GetId() const { return id_; }
    const std: :string& GetName() const { return name_; }
    EquipmentStatus GetStatus() const { return status_; }
    void Start() { status_ = EquipmentStatus: :Running; }
    void Stop() { status_ = EquipmentStatus: :Idle; }
    void SetError() { status_ = EquipmentStatus: :Error; }
    void UpdateData(const ProcessData& data) {
        currentData_ = data;
        history_.push_back(data);
        if (history_.size() > 1000) {
            history_.erase(history_.begin());
        }
    }
    const ProcessData& GetCurrentData() const { return currentData_; }
    const std: :vector<ProcessData>& GetHistory() const { return history_; }
private: std: :string id_;
    std: :string name_;
    EquipmentStatus status_;
    ProcessData currentData_;
    std: :vector<ProcessData> history_;
};
} // namespace Domain
```
==== Infrastructure Layer
```cpp
// Infrastructure/IDataRepository.h
#pragma once
#include "../Domain/ProcessData.h"
#include <vector>
#include <memory>
namespace Infrastructure {
class IDataRepository {
public: virtual ~IDataRepository() = default;
    virtual void Save(const Domain: :ProcessData& data) = 0;
    virtual std: :vector<Domain: :ProcessData> LoadHistory(const std: :string& equipmentId, std: :chrono: :system_clock: :time_point from, std: :chrono: :system_clock: :time_point to) = 0;
};
// Infrastructure/FileDataRepository.cpp
class FileDataRepository : public IDataRepository {
public: explicit FileDataRepository(const std: :string& filepath) : filepath_(filepath) {}
    void Save(const Domain: :ProcessData& data) override {
        std: :ofstream file(filepath_, std: :ios: :app);
        if (!file) return;
        auto time = std: :chrono: :system_clock: :to_time_t(data.timestamp);
        file << data.equipmentId << ", "
             << data.temperature << ", "
             << data.pressure << ", "
             << data.flowRate << ", "
             << time << "\n";
    }
    std: :vector<Domain: :ProcessData> LoadHistory(const std: :string& equipmentId, std: :chrono: :system_clock: :time_point from, std: :chrono: :system_clock: :time_point to) override {
        // CSV 파싱 로직...
        return {};
    }
private: std: :string filepath_;
};
} // namespace Infrastructure
```
==== Application Layer
```cpp
// Application/EquipmentService.h
#pragma once
#include "../Domain/ProcessData.h"
#include "../Infrastructure/IDataRepository.h"
#include <memory>
#include <vector>
#include <mutex>
namespace Application {
class EquipmentService {
public: explicit EquipmentService(std: :shared_ptr<Infrastructure: :IDataRepository> repository)
        : repository_(repository) {}
    void RegisterEquipment(std: :shared_ptr<Domain: :Equipment> equipment) {
        std: :lock_guard<std: :mutex> lock(mutex_);
        equipments_.push_back(equipment);
    }
    std: :vector<std: :shared_ptr<Domain: :Equipment>> GetAllEquipments() {
        std: :lock_guard<std: :mutex> lock(mutex_);
        return equipments_;
    }
    void UpdateEquipmentData(const std: :string& equipmentId, const Domain: :ProcessData& data) {
        std: :lock_guard<std: :mutex> lock(mutex_);
        for (auto& eq : equipments_) {
            if (eq->GetId() == equipmentId) {
                eq->UpdateData(data);
                repository_->Save(data);  // 영속성
                break;
            }
        }
    }
private: std: :shared_ptr<Infrastructure: :IDataRepository> repository_;
    std: :vector<std: :shared_ptr<Domain: :Equipment>> equipments_;
    std: :mutex mutex_;
};
} // namespace Application
```
==== Presentation Layer
```cpp
// Presentation/EquipmentView.h
#pragma once
#include "../Application/EquipmentService.h"
#include <imgui.h>
namespace Presentation {
class EquipmentView {
public: explicit EquipmentView(std: :shared_ptr<Application: :EquipmentService> service)
        : service_(service) {}
    void Render() {
        ImGui: :Begin("Equipment Monitor");
        auto equipments = service_->GetAllEquipments();
        for (auto& eq : equipments) {
            ImGui: :PushID(eq->GetId().c_str());
            if (ImGui: :CollapsingHeader(eq->GetName().c_str())) {
                const auto& data = eq->GetCurrentData();
                ImGui: :Text("Temperature: %.1f °C", data.temperature);
                ImGui: :Text("Pressure: %.2f Torr", data.pressure);
                ImGui: :Text("Flow Rate: %.1f sccm", data.flowRate);
                ImGui: :Spacing();
                if (ImGui: :Button("Start") && eq->GetStatus() == Domain: :EquipmentStatus: :Idle) {
                    eq->Start();
                }
                ImGui: :SameLine();
                if (ImGui: :Button("Stop") && eq->GetStatus() == Domain: :EquipmentStatus: :Running) {
                    eq->Stop();
                }
            }
            ImGui: :PopID();
        }
        ImGui: :End();
    }
private: std: :shared_ptr<Application: :EquipmentService> service_;
};
} // namespace Presentation
```
=== Repository Pattern (저장소 패턴)
Repository Pattern은 Martin Fowler가 정립한 패턴으로, 데이터 접근 로직을 캡슐화한다.
```cpp
// IEquipmentRepository.h
class IEquipmentRepository {
public: virtual ~IEquipmentRepository() = default;
    virtual void Add(const Equipment& equipment) = 0;
    virtual Equipment* GetById(const std: :string& id) = 0;
    virtual std: :vector<Equipment*> GetAll() = 0;
    virtual void Update(const Equipment& equipment) = 0;
    virtual void Delete(const std: :string& id) = 0;
};
// MemoryRepository.cpp (In-Memory 구현)
class MemoryRepository : public IEquipmentRepository {
public: void Add(const Equipment& equipment) override {
        equipments_[equipment.GetId()] = equipment;
    }
    Equipment* GetById(const std: :string& id) override {
        auto it = equipments_.find(id);
        return (it != equipments_.end()) ? &it->second : nullptr;
    }
    std: :vector<Equipment*> GetAll() override {
        std: :vector<Equipment*> result;
        for (auto& [id, eq] : equipments_) {
            result.push_back(&eq);
        }
        return result;
    }
    void Update(const Equipment& equipment) override {
        equipments_[equipment.GetId()] = equipment;
    }
    void Delete(const std: :string& id) override {
        equipments_.erase(id);
    }
private: std: :unordered_map<std: :string, Equipment> equipments_;
};
// 사용:
auto repository = std: :make_shared<MemoryRepository>();
Equipment cvd("CVD-01", "Chemical Vapor Deposition");
repository->Add(cvd);
auto* eq = repository->GetById("CVD-01");
if (eq) {
    eq->Start();
    repository->Update(*eq);
}
```
=== Facade Pattern (퍼사드 패턴)
복잡한 서브시스템을 간단한 인터페이스로 감싼다.
```cpp
// Subsystems
class SensorReader {
public: ProcessData Read() { /* 센서 읽기 */ return {}; }
};
class AlarmChecker {
public: bool CheckAlarms(const ProcessData& data) {
        return !data.IsNormal();
    }
};
class DataLogger {
public: void Log(const ProcessData& data) { /* 로그 저장 */ }
};
class NotificationService {
public: void SendNotification(const std: :string& message) { /* 알림 전송 */ }
};
// Facade: 복잡한 시스템을 단순화
class EquipmentFacade {
public: EquipmentFacade()
        : sensor_(std: :make_unique<SensorReader>())
        , alarmChecker_(std: :make_unique<AlarmChecker>())
        , logger_(std: :make_unique<DataLogger>())
        , notifier_(std: :make_unique<NotificationService>()) {}
    void MonitorEquipment() {
        // 1. 센서 읽기
        auto data = sensor_->Read();
        // 2. 알람 체크
        if (alarmChecker_->CheckAlarms(data)) {
            notifier_->SendNotification("Equipment alarm triggered!");
        }
        // 3. 로그 저장
        logger_->Log(data);
    }
private: std: :unique_ptr<SensorReader> sensor_;
    std: :unique_ptr<AlarmChecker> alarmChecker_;
    std: :unique_ptr<DataLogger> logger_;
    std: :unique_ptr<NotificationService> notifier_;
};
// 사용: 복잡한 시스템을 한 줄로!
EquipmentFacade facade;
facade.MonitorEquipment();
```
=== Observer Pattern (관찰자 패턴)
이벤트 기반 시스템의 핵심 패턴.
```cpp
#include <vector>
#include <algorithm>
// Observer 인터페이스
class IDataObserver {
public: virtual ~IDataObserver() = default;
    virtual void OnDataChanged(const ProcessData& data) = 0;
};
// Subject (관찰 대상)
class EquipmentSubject {
public: void Attach(IDataObserver* observer) {
        observers_.push_back(observer);
    }
    void Detach(IDataObserver* observer) {
        observers_.erase(std: :remove(observers_.begin(), observers_.end(), observer), observers_.end());
    }
    void Notify(const ProcessData& data) {
        for (auto* observer : observers_) {
            observer->OnDataChanged(data);
        }
    }
private: std: :vector<IDataObserver*> observers_;
};
// Concrete Observers
class ChartObserver : public IDataObserver {
public: void OnDataChanged(const ProcessData& data) override {
        std: :cout << "Chart updated with temp: " << data.temperature << "\n";
        // 차트 갱신 로직...
    }
};
class AlarmObserver : public IDataObserver {
public: void OnDataChanged(const ProcessData& data) override {
        if (!data.IsNormal()) {
            std: :cout << "ALARM: Abnormal data detected!\n";
        }
    }
};
class LoggerObserver : public IDataObserver {
public: void OnDataChanged(const ProcessData& data) override {
        std: :cout << "Logged data at " << /* timestamp */ "\n";
    }
};
// 사용:
EquipmentSubject subject;
ChartObserver chart;
AlarmObserver alarm;
LoggerObserver logger;
subject.Attach(&chart);
subject.Attach(&alarm);
subject.Attach(&logger);
ProcessData data{"CVD-01", 550, 3.0, 120, std: :chrono: :system_clock: :now()};
subject.Notify(data);
// 출력:
// Chart updated with temp: 550
// ALARM: Abnormal data detected!
// Logged data at ...
```
== 완전한 실행 가능 예제: 통합 HMI 시스템
다음은 모든 아키텍처 패턴을 통합한 완전한 HMI 시스템이다.
=== 프로젝트 구조
```
IntegratedHMI/
├── Domain/
│   ├── Equipment.h
│   └── ProcessData.h
├── Infrastructure/
│   ├── IDataRepository.h
│   └── FileDataRepository.h
├── Application/
│   ├── EquipmentService.h
│   └── AlarmService.h
├── Presentation/
│   ├── EquipmentView.h
│   └── AlarmView.h
└── main.cpp
```
=== main.cpp (통합 예제)
```cpp
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <memory>
#include <thread>
#include <atomic>
#include <random>
// ==================== Domain Layer ====================
namespace Domain {
struct ProcessData {
    std: :string equipmentId;
    double temperature;
    double pressure;
    double flowRate;
    bool IsNormal() const {
        return temperature >= 100 && temperature <= 500 &&
               pressure >= 1.0 && pressure <= 5.0 &&
               flowRate >= 50 && flowRate <= 200;
    }
};
enum class EquipmentStatus { Idle, Running, Error };
class Equipment {
public: Equipment(std: :string id, std: :string name)
        : id_(std: :move(id)), name_(std: :move(name)), status_(EquipmentStatus: :Idle) {}
    const std: :string& GetId() const { return id_; }
    const std: :string& GetName() const { return name_; }
    EquipmentStatus GetStatus() const { return status_; }
    const ProcessData& GetCurrentData() const { return currentData_; }
    void Start() { status_ = EquipmentStatus: :Running; }
    void Stop() { status_ = EquipmentStatus: :Idle; }
    void SetError() { status_ = EquipmentStatus: :Error; }
    void UpdateData(const ProcessData& data) {
        currentData_ = data;
        if (!data.IsNormal()) {
            SetError();
        }
    }
private: std: :string id_;
    std: :string name_;
    EquipmentStatus status_;
    ProcessData currentData_;
};
} // namespace Domain
// ==================== Infrastructure Layer ====================
namespace Infrastructure {
class IDataRepository {
public: virtual ~IDataRepository() = default;
    virtual void Save(const Domain: :ProcessData& data) = 0;
};
class ConsoleRepository : public IDataRepository {
public: void Save(const Domain: :ProcessData& data) override {
        std: :cout << "[LOG] " << data.equipmentId
                  << " | Temp: " << data.temperature
                  << " | Press: " << data.pressure << "\n";
    }
};
} // namespace Infrastructure
// ==================== Application Layer ====================
namespace Application {
// Observer Pattern
class IDataObserver {
public: virtual ~IDataObserver() = default;
    virtual void OnDataChanged(const Domain: :ProcessData& data) = 0;
};
class EquipmentService {
public: EquipmentService(std: :shared_ptr<Infrastructure: :IDataRepository> repository)
        : repository_(repository) {}
    void RegisterEquipment(std: :shared_ptr<Domain: :Equipment> equipment) {
        equipments_.push_back(equipment);
    }
    std: :vector<std: :shared_ptr<Domain: :Equipment>> GetAllEquipments() {
        return equipments_;
    }
    void UpdateEquipmentData(const std: :string& equipmentId, const Domain: :ProcessData& data) {
        for (auto& eq : equipments_) {
            if (eq->GetId() == equipmentId) {
                eq->UpdateData(data);
                repository_->Save(data);
                NotifyObservers(data);
                break;
            }
        }
    }
    void Attach(IDataObserver* observer) {
        observers_.push_back(observer);
    }
private: void NotifyObservers(const Domain: :ProcessData& data) {
        for (auto* observer : observers_) {
            observer->OnDataChanged(data);
        }
    }
    std: :shared_ptr<Infrastructure: :IDataRepository> repository_;
    std: :vector<std: :shared_ptr<Domain: :Equipment>> equipments_;
    std: :vector<IDataObserver*> observers_;
};
class AlarmService : public IDataObserver {
public: void OnDataChanged(const Domain: :ProcessData& data) override {
        if (!data.IsNormal()) {
            alarms_.push_back("ALARM: " + data.equipmentId + " abnormal!");
            if (alarms_.size() > 10) {
                alarms_.erase(alarms_.begin());
            }
        }
    }
    const std: :vector<std: :string>& GetAlarms() const {
        return alarms_;
    }
    void ClearAll() {
        alarms_.clear();
    }
private: std: :vector<std: :string> alarms_;
};
} // namespace Application
// ==================== Presentation Layer ====================
namespace Presentation {
class EquipmentView {
public: EquipmentView(std: :shared_ptr<Application: :EquipmentService> service)
        : service_(service) {}
    void Render() {
        ImGui: :Begin("Equipment Control");
        auto equipments = service_->GetAllEquipments();
        for (auto& eq : equipments) {
            ImGui: :PushID(eq->GetId().c_str());
            ImGui: :Text("%s", eq->GetName().c_str());
            ImGui: :Separator();
            const auto& data = eq->GetCurrentData();
            ImGui: :Text("Temperature: %.1f °C", data.temperature);
            ImGui: :Text("Pressure: %.2f Torr", data.pressure);
            ImGui: :Text("Flow Rate: %.1f sccm", data.flowRate);
            // 상태 표시
            const char* statusText = "Unknown";
            ImVec4 statusColor = ImVec4(1, 1, 1, 1);
            switch (eq->GetStatus()) {
                case Domain: :EquipmentStatus: :Idle: statusText = "Idle";
                    statusColor = ImVec4(0.5f, 0.5f, 0.5f, 1.0f);
                    break;
                case Domain: :EquipmentStatus: :Running: statusText = "Running";
                    statusColor = ImVec4(0.0f, 1.0f, 0.0f, 1.0f);
                    break;
                case Domain: :EquipmentStatus: :Error: statusText = "Error";
                    statusColor = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);
                    break;
            }
            ImGui: :TextColored(statusColor, "Status: %s", statusText);
            ImGui: :Spacing();
            if (ImGui: :Button("Start")) {
                eq->Start();
            }
            ImGui: :SameLine();
            if (ImGui: :Button("Stop")) {
                eq->Stop();
            }
            ImGui: :Spacing();
            ImGui: :PopID();
        }
        ImGui: :End();
    }
private: std: :shared_ptr<Application: :EquipmentService> service_;
};
class AlarmView {
public: AlarmView(std: :shared_ptr<Application: :AlarmService> service)
        : service_(service) {}
    void Render() {
        ImGui: :Begin("Alarms");
        const auto& alarms = service_->GetAlarms();
        if (alarms.empty()) {
            ImGui: :TextColored(ImVec4(0, 1, 0, 1), "No active alarms");
        } else {
            if (ImGui: :Button("Clear All")) {
                service_->ClearAll();
            }
            ImGui: :Separator();
            for (const auto& alarm : alarms) {
                ImGui: :TextColored(ImVec4(1, 0, 0, 1), "%s", alarm.c_str());
            }
        }
        ImGui: :End();
    }
private: std: :shared_ptr<Application: :AlarmService> service_;
};
} // namespace Presentation
// ==================== Main ====================
int main() {
    // GLFW 초기화
    if (!glfwInit()) {
        return -1;
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    GLFWwindow* window = glfwCreateWindow(1280, 720, "Integrated HMI System", NULL, NULL);
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
    // ==================== 의존성 주입 (DI) ====================
    auto repository = std: :make_shared<Infrastructure: :ConsoleRepository>();
    auto equipmentService = std: :make_shared<Application: :EquipmentService>(repository);
    auto alarmService = std: :make_shared<Application: :AlarmService>();
    // Observer 등록
    equipmentService->Attach(alarmService.get());
    // Equipment 등록
    auto cvd = std: :make_shared<Domain: :Equipment>("CVD-01", "Chemical Vapor Deposition");
    auto pvd = std: :make_shared<Domain: :Equipment>("PVD-01", "Physical Vapor Deposition");
    equipmentService->RegisterEquipment(cvd);
    equipmentService->RegisterEquipment(pvd);
    // Views 생성
    Presentation: :EquipmentView equipmentView(equipmentService);
    Presentation: :AlarmView alarmView(alarmService);
    // ==================== 데이터 시뮬레이션 스레드 ====================
    std: :atomic<bool> running{true};
    std: :thread simulationThread([&]() {
        std: :random_device rd;
        std: :mt19937 gen(rd());
        std: :uniform_real_distribution<> tempDist(200, 600);
        std: :uniform_real_distribution<> pressDist(0.5, 6.0);
        std: :uniform_real_distribution<> flowDist(40, 210);
        while (running) {
            // CVD 데이터 업데이트
            Domain: :ProcessData cvdData{
                "CVD-01", tempDist(gen), pressDist(gen), flowDist(gen)
            };
            equipmentService->UpdateEquipmentData("CVD-01", cvdData);
            // PVD 데이터 업데이트
            Domain: :ProcessData pvdData{
                "PVD-01", tempDist(gen), pressDist(gen), flowDist(gen)
            };
            equipmentService->UpdateEquipmentData("PVD-01", pvdData);
            std: :this_thread: :sleep_for(std: :chrono: :seconds(2));
        }
    });
    // ==================== 메인 루프 ====================
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui: :NewFrame();
        // Views 렌더링
        equipmentView.Render();
        alarmView.Render();
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
    running = false;
    simulationThread.join();
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
project(IntegratedHMI)
set(CMAKE_CXX_STANDARD 17)
find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)
find_package(Threads REQUIRED)
set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/imgui")
add_executable(integrated_hmi
    main.cpp
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
    ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp)
target_include_directories(integrated_hmi PRIVATE
    ${IMGUI_DIR}
    ${IMGUI_DIR}/backends)
target_link_libraries(integrated_hmi
    OpenGL: :GL
    glfw
    Threads: :Threads)
```
*빌드 및 실행: *
```bash
mkdir build && cd build
cmake ..
make
./integrated_hmi
```
*기능: *
1. Layered Architecture: Domain → Application → Presentation 분리
2. Repository Pattern: 데이터 접근 추상화 (ConsoleRepository)
3. Observer Pattern: AlarmService가 데이터 변경 감지
4. Dependency Injection: 생성자를 통한 의존성 주입
5. 멀티스레딩: 데이터 시뮬레이션 백그라운드 실행
6. SOLID 원칙 준수: SRP, OCP, DIP 적용
== MCQ (Multiple Choice Questions)
=== 문제 1: Single Responsibility Principle (기초)
SRP를 위반하는 클래스는?
A. SensorReader (센서 읽기만 담당) \
B. DataLogger (로그 저장만 담당) \
C. EquipmentManager (센서 읽기 + DB 저장 + UI 렌더링 + 이메일 전송) \
D. AlarmChecker (알람 체크만 담당)
*정답: C*
*해설*: EquipmentManager가 4가지 책임을 가지므로 SRP 위반. 변경 이유가 4가지나 되어 유지보수가 어렵다.
---
=== 문제 2: Open/Closed Principle (기초)
OCP를 준수하는 방법은?
A. 새 기능 추가 시 기존 코드 수정 \
B. 상속과 다형성을 활용한 확장 \
C. if-else 체인으로 모든 경우 처리 \
D. 전역 변수 사용
*정답: B*
*해설*: OCP는 "확장에 열림, 수정에 닫힘"을 의미한다. 상속과 다형성(Strategy Pattern 등)을 통해 기존 코드를 수정하지 않고 확장 가능하다.
---
=== 문제 3: Dependency Inversion Principle (중급)
DIP를 적용한 올바른 코드는?
A. `DataLogger(MySQLDatabase* db)` \
B. `DataLogger(IDatabase* db)` \
C. `DataLogger() { db = new MySQLDatabase(); }` \
D. `DataLogger(std: :string dbType)`
*정답: B*
*해설*: DIP는 고수준 모듈(DataLogger)이 저수준 모듈(MySQLDatabase)이 아닌 추상화(IDatabase)에 의존해야 한다는 원칙이다.
---
=== 문제 4: DRY 원칙 (중급)
DRY 원칙의 핵심은?
A. 코드를 짧게 작성 \
B. 동일한 지식을 여러 곳에 중복하지 않음 \
C. 주석을 많이 작성 \
D. 함수를 많이 만듦
*정답: B*
*해설*: DRY(Don't Repeat Yourself)는 동일한 로직/지식을 시스템 내 한 곳에만 표현해야 한다는 원칙이다.
---
=== 문제 5: Layered Architecture (중급)
Layered Architecture에서 의존성 규칙은?
A. 상위 계층 → 하위 계층 의존 가능 \
B. 하위 계층 → 상위 계층 의존 가능 \
C. 양방향 의존 가능 \
D. 의존 금지
*정답: A*
*해설*: Layered Architecture는 상위 계층(Presentation)이 하위 계층(Application, Domain)에 의존할 수 있지만, 반대는 불가능하다.
---
=== 문제 6: Repository Pattern (고급)
Repository Pattern의 주요 목적은?
A. UI 렌더링 최적화 \
B. 데이터 접근 로직 캡슐화 \
C. 네트워크 통신 \
D. 메모리 관리
*정답: B*
*해설*: Repository Pattern은 데이터 접근 로직을 캡슐화하여 비즈니스 로직과 분리한다. DB 변경 시 Repository만 수정하면 된다.
---
=== 문제 7: Observer Pattern (고급)
Observer Pattern의 핵심 장점은?
A. 코드 라인 수 감소 \
B. Subject와 Observer 간 느슨한 결합 \
C. 실행 속도 향상 \
D. 메모리 사용량 감소
*정답: B*
*해설*: Observer Pattern은 Subject(관찰 대상)와 Observer(관찰자)를 분리하여 느슨한 결합을 제공한다. Subject는 Observer의 구체 타입을 알 필요가 없다.
---
=== 문제 8: 코드 분석 - LSP (고급)
다음 중 LSP 위반 사례는?
```cpp
class Bird {
    virtual void Fly() = 0;
};
class Sparrow : public Bird {
    void Fly() override { /* 날다 */ }
};
class Penguin : public Bird {
    void Fly() override { /* 펭귄은 못 날아! */ }
};
```
A. Sparrow \
B. Penguin \
C. Bird \
D. 위반 없음
*정답: B*
*해설*: Penguin은 날 수 없으므로 Bird의 Fly() 계약을 위반한다. LSP는 서브타입이 기반 타입으로 대체 가능해야 한다는 원칙이다.
---
=== 문제 9: Microservices vs Monolithic (고급)
마이크로서비스 아키텍처의 단점은?
A. 독립 배포 가능 \
B. 기술 스택 자유 \
C. 디버깅 및 복잡도 증가 \
D. 확장성 향상
*정답: C*
*해설*: 마이크로서비스는 많은 장점이 있지만, 여러 서비스로 분리되어 디버깅이 어렵고 시스템 복잡도가 증가한다.
---
=== 문제 10: 종합 응용 (도전)
다음 시나리오에 가장 적합한 패턴은?
"센서 데이터가 변경될 때마다 차트, 알람, 로거 3개 컴포넌트가 자동으로 업데이트되어야 한다."
A. Factory Pattern \
B. Observer Pattern \
C. Singleton Pattern \
D. Strategy Pattern
*정답: B*
*해설*: Observer Pattern은 하나의 Subject(센서) 변경 시 여러 Observer(차트, 알람, 로거)에 자동 통지하는 패턴이다. 이벤트 기반 시스템에 이상적이다.
== 실습 과제
=== 최종 프로젝트
다음 요구사항을 만족하는 통합 HMI 시스템 개발: *기능 요구사항: *
+ 3대 이상 장비 동시 모니터링
+ 실시간 데이터 차트 (온도, 압력, 유량)
+ 3단계 알람 시스템 (Info, Warning, Critical)
+ 데이터 로깅 (CSV 또는 SQLite)
+ 레시피 관리 (로드/저장)
*아키텍처 요구사항: *
+ Layered Architecture 적용
+ 최소 3개 디자인 패턴 사용 (Repository, Observer, Strategy 등)
+ SOLID 원칙 준수
+ DRY 원칙 준수
*품질 요구사항: *
+ 60 FPS 이상 유지
+ 100ms 이내 데이터 업데이트
+ 메모리 누수 없음
+ 코드 주석 및 문서화
*제출물: *
+ 소스 코드 (GitHub 링크)
+ CMakeLists.txt
+ README.md (빌드 방법, 실행 방법)
+ 아키텍처 다이어그램 (ASCII 또는 이미지)
+ 실행 영상 또는 스크린샷
== 추가 학습 자료
=== 공식 문서 및 표준
- *C++ Core Guidelines*: https: //isocpp.github.io/CppCoreGuidelines/
- *SOLID Principles*: Robert C. Martin's Blog
- *ImGui Documentation*: https: //github.com/ocornut/imgui/wiki
=== 참고 서적
- "Clean Architecture" by Robert C. Martin (SOLID, 아키텍처 원칙)
- "Design Patterns: Elements of Reusable Object-Oriented Software" by Gang of Four
- "The Pragmatic Programmer" by Andy Hunt & Dave Thomas (DRY 원칙)
- "Domain-Driven Design" by Eric Evans (Layered Architecture)
=== 온라인 강의
- Udemy: "Design Patterns in C++"
- Coursera: "Software Architecture"
- YouTube: "ArjanCodes" (Python이지만 원칙은 동일)
== 요약
이번 챕터에서는 통합 HMI 시스템을 학습했다: *이론 (Theory): *
- SOLID 원칙: SRP, OCP, LSP, ISP, DIP (Robert C. Martin)
- DRY 원칙: 중복 제거 (Andy Hunt & Dave Thomas)
- 시스템 통합 전략: Layered Architecture, 의존성 규칙
- 산업 동향: 마이크로서비스, Event-Driven Architecture, Cloud-Native HMI
*응용 (Application): *
- Layered Architecture: Domain, Infrastructure, Application, Presentation 분리
- Repository Pattern: 데이터 접근 로직 캡슐화
- Facade Pattern: 복잡한 서브시스템 단순화
- Observer Pattern: 이벤트 기반 통신
- 완전한 실행 가능 예제: 멀티스레드 통합 HMI 시스템
*성찰 (Reflections): *
- MCQ 10문제: SOLID 원칙, 아키텍처 패턴, 코드 분석, 종합 응용
*핵심 포인트: *
1. SOLID 원칙은 유지보수 가능한 소프트웨어의 기초다
2. Layered Architecture는 관심사 분리(Separation of Concerns)를 강제한다
3. 디자인 패턴은 검증된 해결책으로 코드 품질을 향상시킨다
4. 의존성 주입(DI)과 추상화는 테스트 가능성과 유연성을 제공한다

#pagebreak()