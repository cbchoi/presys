= Week 12: ImGui 스레딩, 통신 및 최적화

== 학습 목표

본 챕터에서는 다음을 학습합니다:

+ C++20 스레딩 (std::jthread, std::stop_token)
+ Asio 비동기 I/O
+ 성능 최적화
+ 메모리 관리

== C++20 스레딩

=== std::jthread

```cpp
#include \<thread>
#include \<stop_token>
#include \<chrono>

class DataCollector {
public:
    void start() {
        worker_ = std::jthread([this](std::stop_token stoken) {
            while (!stoken.stop_requested()) {
                // 데이터 수집
                collect_data();

                // 100ms 대기 (취소 가능)
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        });
    }

    void stop() {
        // jthread는 소멸자에서 자동으로 stop 요청 및 join
    }

private:
    void collect_data() {
        // 시뮬레이션
        std::lock_guard<std::mutex> lock(mutex_);
        current_data_.temperature = 450.0f + (rand() % 100 - 50) / 10.0f;
        current_data_.pressure = 2.5f + (rand() % 40 - 20) / 100.0f;
    }

    std::jthread worker_;
    std::mutex mutex_;
    ProcessData current_data_;
};
```

=== 스레드 안전 큐

```cpp
#include \<queue>
#include \<mutex>
#include \<condition_variable>
#include \<optional>

template<typename T>
class ThreadSafeQueue {
public:
    void push(T value) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(value));
        cond_.notify_one();
    }

    std::optional<T> pop() {
        std::unique_lock<std::mutex> lock(mutex_);
        if (queue_.empty()) {
            return std::nullopt;
        }
        T value = std::move(queue_.front());
        queue_.pop();
        return value;
    }

    std::optional<T> wait_and_pop(std::stop_token stoken) {
        std::unique_lock<std::mutex> lock(mutex_);
        cond_.wait(lock, stoken, [this] { return !queue_.empty(); });

        if (stoken.stop_requested()) {
            return std::nullopt;
        }

        T value = std::move(queue_.front());
        queue_.pop();
        return value;
    }

    bool empty() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.empty();
    }

private:
    mutable std::mutex mutex_;
    std::queue<T> queue_;
    std::condition_variable_any cond_;
};
```

=== 프로듀서-컨슈머 패턴

```cpp
class EquipmentMonitor {
public:
    EquipmentMonitor()
        : data_queue_(std::make_shared<ThreadSafeQueue<ProcessData>>()) {}

    void start() {
        // 프로듀서 스레드
        producer_ = std::jthread([this](std::stop_token stoken) {
            while (!stoken.stop_requested()) {
                ProcessData data = collect_data();
                data_queue_->push(data);
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        });

        // 컨슈머 스레드
        consumer_ = std::jthread([this](std::stop_token stoken) {
            while (!stoken.stop_requested()) {
                if (auto data = data_queue_->wait_and_pop(stoken)) {
                    process_data(*data);
                }
            }
        });
    }

    void render() {
        // UI 스레드에서 안전하게 렌더링
        std::lock_guard<std::mutex> lock(data_mutex_);
        ImGui::Text("Temperature: %.1f°C", latest_data_.temperature);
        ImGui::Text("Pressure: %.2f Torr", latest_data_.pressure);
    }

private:
    ProcessData collect_data() {
        // 데이터 수집 로직
        return ProcessData{};
    }

    void process_data(const ProcessData& data) {
        std::lock_guard<std::mutex> lock(data_mutex_);
        latest_data_ = data;
    }

    std::jthread producer_;
    std::jthread consumer_;
    std::shared_ptr<ThreadSafeQueue<ProcessData>> data_queue_;
    std::mutex data_mutex_;
    ProcessData latest_data_;
};
```

== Asio 비동기 I/O

=== TCP 클라이언트

```cpp
#include \<asio.hpp>

class TcpClient {
public:
    TcpClient(asio::io_context& io_context)
        : socket_(io_context) {}

    void connect(const std::string& host, uint16_t port) {
        asio::ip::tcp::resolver resolver(socket_.get_executor());
        auto endpoints = resolver.resolve(host, std::to_string(port));

        asio::async_connect(socket_, endpoints,
            [this](const std::error_code& ec,
                   const asio::ip::tcp::endpoint&) {
                if (!ec) {
                    std::cout \<< "Connected\n";
                    start_read();
                } else {
                    std::cerr \<< "Connect error: " \<< ec.message() \<< "\n";
                }
            });
    }

    void send(const std::string& message) {
        asio::async_write(socket_,
            asio::buffer(message),
            [](const std::error_code& ec, std::size_t) {
                if (ec) {
                    std::cerr \<< "Write error: " \<< ec.message() \<< "\n";
                }
            });
    }

    void set_data_callback(std::function<void(const std::string&)> callback) {
        data_callback_ = std::move(callback);
    }

private:
    void start_read() {
        asio::async_read_until(socket_, buffer_, '\n',
            [this](const std::error_code& ec, std::size_t bytes) {
                if (!ec) {
                    std::istream is(&buffer_);
                    std::string line;
                    std::getline(is, line);

                    if (data_callback_) {
                        data_callback_(line);
                    }

                    start_read(); // 계속 읽기
                } else {
                    std::cerr \<< "Read error: " \<< ec.message() \<< "\n";
                }
            });
    }

    asio::ip::tcp::socket socket_;
    asio::streambuf buffer_;
    std::function<void(const std::string&)> data_callback_;
};

// 사용
asio::io_context io_context;
TcpClient client(io_context);

client.set_data_callback([](const std::string& data) {
    std::cout \<< "Received: " \<< data \<< "\n";
});

client.connect("localhost", 5000);

// I/O 컨텍스트를 별도 스레드에서 실행
std::jthread io_thread([&io_context] {
    io_context.run();
});
```

=== 타이머

```cpp
class PeriodicTask {
public:
    PeriodicTask(asio::io_context& io_context,
                 std::chrono::milliseconds interval)
        : timer_(io_context)
        , interval_(interval) {}

    void start(std::function<void()> callback) {
        callback_ = std::move(callback);
        schedule_next();
    }

    void stop() {
        timer_.cancel();
    }

private:
    void schedule_next() {
        timer_.expires_after(interval_);
        timer_.async_wait([this](const std::error_code& ec) {
            if (!ec) {
                if (callback_) {
                    callback_();
                }
                schedule_next();
            }
        });
    }

    asio::steady_timer timer_;
    std::chrono::milliseconds interval_;
    std::function<void()> callback_;
};

// 사용
PeriodicTask task(io_context, std::chrono::milliseconds(100));
task.start([] {
    std::cout \<< "Periodic task executed\n";
});
```

== 성능 최적화

=== 프로파일링

```cpp
#include \<chrono>

class Profiler {
public:
    Profiler(const char* name)
        : name_(name)
        , start_(std::chrono::high_resolution_clock::now()) {}

    ~Profiler() {
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
            end - start_).count();
        std::cout \<< name_ \<< ": " \<< duration \<< " µs\n";
    }

private:
    const char* name_;
    std::chrono::time_point<std::chrono::high_resolution_clock> start_;
};

// 사용
void expensive_function() {
    Profiler profiler("expensive_function");
    // ... 작업
}

// 또는 매크로
#define PROFILE_SCOPE(name) Profiler _profiler##__LINE__(name)

void another_function() {
    PROFILE_SCOPE("another_function");
    // ... 작업
}
```

=== 렌더링 최적화

```cpp
// 1. 불필요한 렌더링 방지
static bool window_visible = true;
if (window_visible) {
    ImGui::Begin("Equipment", &window_visible);
    // ... 내용
    ImGui::End();
}

// 2. 대량 데이터 처리 시 클리핑
ImGuiListClipper clipper;
clipper.Begin(data_list.size());
while (clipper.Step()) {
    for (int i = clipper.DisplayStart; i \< clipper.DisplayEnd; i++) {
        ImGui::Text("%s", data_list[i].c_str());
    }
}

// 3. 텍스처 아틀라스 사용
// 여러 작은 이미지를 하나의 큰 텍스처로 결합
```

=== 메모리 풀

```cpp
template<typename T, size_t BlockSize = 4096>
class MemoryPool {
public:
    T* allocate() {
        if (free_list_.empty()) {
            allocate_block();
        }

        T* ptr = free_list_.back();
        free_list_.pop_back();
        return ptr;
    }

    void deallocate(T* ptr) {
        free_list_.push_back(ptr);
    }

private:
    void allocate_block() {
        T* block = static_cast<T*>(::operator new(BlockSize * sizeof(T)));
        blocks_.push_back(block);

        for (size_t i = 0; i \< BlockSize; ++i) {
            free_list_.push_back(&block[i]);
        }
    }

    std::vector<T*> blocks_;
    std::vector<T*> free_list_;
};

// 사용
MemoryPool<ProcessData> data_pool;
ProcessData* data = data_pool.allocate();
// ... 사용
data_pool.deallocate(data);
```

== 통합 예제: 비동기 HMI

```cpp
class AsynchronousHMI {
public:
    AsynchronousHMI()
        : io_context_()
        , tcp_client_(io_context_)
        , periodic_task_(io_context_, std::chrono::milliseconds(100))
        , data_queue_(std::make_shared<ThreadSafeQueue<ProcessData>>()) {

        // TCP 콜백 설정
        tcp_client_.set_data_callback([this](const std::string& data) {
            parse_and_queue_data(data);
        });

        // 주기적 데이터 수집
        periodic_task_.start([this] {
            collect_local_data();
        });

        // I/O 컨텍스트 스레드
        io_thread_ = std::jthread([this](std::stop_token stoken) {
            while (!stoken.stop_requested()) {
                io_context_.run_for(std::chrono::milliseconds(10));
            }
        });

        // UI 업데이트 스레드
        update_thread_ = std::jthread([this](std::stop_token stoken) {
            while (!stoken.stop_requested()) {
                if (auto data = data_queue_->wait_and_pop(stoken)) {
                    update_display_data(*data);
                }
            }
        });
    }

    void render() {
        PROFILE_SCOPE("AsynchronousHMI::render");

        render_connection_panel();
        render_monitoring_panel();
        render_chart_panel();
    }

private:
    void render_connection_panel() {
        ImGui::Begin("Connection");

        static char host[128] = "localhost";
        static int port = 5000;

        ImGui::InputText("Host", host, sizeof(host));
        ImGui::InputInt("Port", &port);

        if (ImGui::Button("Connect")) {
            tcp_client_.connect(host, static_cast<uint16_t>(port));
        }

        ImGui::End();
    }

    void render_monitoring_panel() {
        ImGui::Begin("Monitoring");

        std::lock_guard<std::mutex> lock(display_mutex_);

        ImGui::Text("Temperature: %.1f°C", display_data_.temperature);
        ImGui::Text("Pressure: %.2f Torr", display_data_.pressure);
        ImGui::Text("Flow Rate: %.1f sccm", display_data_.flow_rate);

        ImGui::End();
    }

    void render_chart_panel() {
        ImGui::Begin("Charts");

        std::lock_guard<std::mutex> lock(history_mutex_);

        if (ImPlot::BeginPlot("Temperature", ImVec2(-1, 300))) {
            if (!history_.empty()) {
                std::vector<float> times, temps;
                for (const auto& data : history_) {
                    times.push_back(data.time);
                    temps.push_back(data.temperature);
                }

                ImPlot::PlotLine("Temperature",
                    times.data(), temps.data(), times.size());
            }
            ImPlot::EndPlot();
        }

        ImGui::End();
    }

    void parse_and_queue_data(const std::string& data) {
        // 파싱 및 큐에 추가
        ProcessData pd = parse_data(data);
        data_queue_->push(pd);
    }

    void collect_local_data() {
        // 로컬 센서 데이터 수집
        ProcessData data{};
        data.temperature = 450.0f + (rand() % 100 - 50) / 10.0f;
        data.pressure = 2.5f + (rand() % 40 - 20) / 100.0f;
        data_queue_->push(data);
    }

    void update_display_data(const ProcessData& data) {
        {
            std::lock_guard<std::mutex> lock(display_mutex_);
            display_data_ = data;
        }

        {
            std::lock_guard<std::mutex> lock(history_mutex_);
            history_.push_back(data);
            if (history_.size() > 1000) {
                history_.erase(history_.begin());
            }
        }
    }

    ProcessData parse_data(const std::string& str) {
        // 실제 파싱 로직
        return ProcessData{};
    }

    asio::io_context io_context_;
    TcpClient tcp_client_;
    PeriodicTask periodic_task_;

    std::jthread io_thread_;
    std::jthread update_thread_;

    std::shared_ptr<ThreadSafeQueue<ProcessData>> data_queue_;

    std::mutex display_mutex_;
    ProcessData display_data_;

    std::mutex history_mutex_;
    std::vector<ProcessData> history_;
};
```

== 설정 파일

=== JSON 파싱 (nlohmann/json)

```cpp
#include \<nlohmann/json.hpp>
#include \<fstream>

using json = nlohmann::json;

struct AppConfig {
    std::string host;
    uint16_t port;
    int poll_interval_ms;
    float alarm_temp_max;

    static AppConfig from_file(const std::string& filename) {
        std::ifstream file(filename);
        json j;
        file >> j;

        AppConfig config;
        config.host = j["connection"]["host"];
        config.port = j["connection"]["port"];
        config.poll_interval_ms = j["monitoring"]["poll_interval_ms"];
        config.alarm_temp_max = j["alarms"]["temperature_max"];

        return config;
    }

    void to_file(const std::string& filename) const {
        json j = {
            {"connection", {
                {"host", host},
                {"port", port}
            }},
            {"monitoring", {
                {"poll_interval_ms", poll_interval_ms}
            }},
            {"alarms", {
                {"temperature_max", alarm_temp_max}
            }}
        };

        std::ofstream file(filename);
        file \<< j.dump(4); // 들여쓰기 4
    }
};
```

== 로깅

=== spdlog

```cpp
#include \<spdlog/spdlog.h>
#include \<spdlog/sinks/basic_file_sink.h>
#include \<spdlog/sinks/stdout_color_sinks.h>

void setup_logging() {
    auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
    auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(
        "hmi.log", true
    );

    std::vector<spdlog::sink_ptr> sinks{console_sink, file_sink};
    auto logger = std::make_shared<spdlog::logger>(
        "hmi", sinks.begin(), sinks.end()
    );

    logger->set_level(spdlog::level::debug);
    spdlog::set_default_logger(logger);
}

// 사용
spdlog::info("Application started");
spdlog::debug("Temperature: {:.1f}", temp);
spdlog::error("Connection failed: {}", error_msg);
```

== 실습 과제

=== 과제 1: 멀티스레드 데이터 수집

+ std::jthread로 백그라운드 수집
+ ThreadSafeQueue 구현
+ UI 스레드 안전성

=== 과제 2: Asio 네트워크 통신

+ TCP 클라이언트 구현
+ 비동기 읽기/쓰기
+ 재연결 로직

=== 과제 3: 성능 최적화

+ 프로파일링
+ 렌더링 최적화
+ 메모리 관리

== 요약

이번 챕터에서는 고급 기능을 학습했습니다:

- C++20 스레딩 (jthread, stop_token)
- ThreadSafeQueue
- Asio 비동기 I/O
- 성능 최적화
- 메모리 풀
- 설정 파일
- 로깅

다음 챕터에서는 통합 프로젝트를 진행합니다.

#pagebreak()
