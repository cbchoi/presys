// 새로운 절(==)이 시작할 때마다 새 페이지에서 시작
#show heading.where(level: 2): it => {
  pagebreak(weak: true)
  it
}

= Week 1: HCI/HMI 이론 및 반도체 장비 적용
== 학습 목표
본 챕터에서는 다음을 학습한다: + *인간-컴퓨터 상호작용 기초*: HCI 핵심 법칙(Miller's Law, Fitts' Law)을 이해하고 반도체 HMI 설계에 적용하는 방법을 학습한다.
+ *정보처리 모델*: 인간의 감각-인지-운동 시스템을 이해하고 실시간 공정 모니터링 UI 설계 원칙을 습득한다.
+ *동시성 프로그래밍 기초*: 멀티스레딩/멀티프로세싱 개념, 운영체제별 차이점, Locking Mechanism, 실시간 시스템 고려사항을 이해한다.
+ *반도체 HMI 특수성*: 클린룸 환경, 고신뢰성 요구사항, SEMI 표준을 기반으로 한 HMI 설계 방법론을 학습한다.
== 배경
반도체 제조 장비(CVD, PVD, ETCH, CMP)는 24/7 연속 운전되며, 운영자의 실수는 수백억원의 손실로 이어질 수 있다. HCI 이론을 적용한 과학적 HMI 설계가 필수적이다.
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *기초 통계학*: 평균, 표준편차, 정규분포의 개념
- *기초 수학*: 로그 함수(log₂)의 의미와 계산 방법
- *프로그래밍 기초*: Python 기본 문법 (변수, 함수, 조건문)
- *운영체제 기초*: 프로세스와 스레드의 개념, 메모리 구조 (선택사항)
- *권장사항*: 반도체 제조 공정 개요 (선택사항)
== HCI 이론의 역사와 발전
=== HCI 학문의 탄생
Human-Computer Interaction (HCI)은 1980년대 초반 독립적인 학문 분야로 자리잡았다. 그 이전에는 인간공학(Ergonomics), 인지심리학(Cognitive Psychology), 컴퓨터 과학(Computer Science)이 각각 분리되어 연구되었다.
*주요 이정표: *
- *1954년*: Paul Fitts가 Fitts' Law 발표 (미 공군 연구소)
- *1956년*: George Miller가 "The Magical Number Seven" 논문 발표
- *1966년*: Green과 Swets가 Signal Detection Theory 정립
- *1983년*: ACM CHI (Computer-Human Interaction) 학회 설립
- *1984년*: Apple Macintosh 출시 - GUI의 대중화
- *2007년*: iPhone 출시 - 터치 인터페이스의 혁명
=== Fitts' Law의 탄생 배경
Paul Fitts는 제2차 세계대전 중 전투기 조종사들의 실수를 연구하던 미 공군 연구원이었다. 그는 조종사들이 계기판의 버튼을 잘못 누르는 빈도가 버튼의 크기와 거리에 따라 달라진다는 점을 발견했다. 1954년 발표한 "The information capacity of the human motor system"에서 이를 수학적 모델로 정립했다.
*실제 적용 사례: *
- 전투기 조종석 설계
- 원자력 발전소 제어실
- 의료 장비 인터페이스
- 반도체 제조 장비 HMI
=== Miller's Law의 발견 과정
George A. Miller는 1956년 심리학 역사상 가장 유명한 논문 중 하나인 "The Magical Number Seven, Plus or Minus Two: Some Limits on Our Capacity for Processing Information"을 발표했다. 그는 다양한 실험을 통해 인간의 단기 기억이 약 7±2개의 정보 단위(chunk)로 제한된다는 것을 증명했다.
*실험 방법: *
- 숫자 기억 실험: 일련의 숫자를 보여주고 몇 개까지 기억하는지 측정
- 단어 기억 실험: 무작위 단어 목록 제시
- 음색 구별 실험: 서로 다른 음높이를 몇 개까지 구별하는지 측정
*결과*: 대부분의 사람들이 7±2개 범위 내에서 정보를 처리한다.
=== Signal Detection Theory의 기원
신호탐지이론은 제2차 세계대전 중 레이더 운영자의 의사결정 과정을 연구하면서 시작되었다. 레이더 화면의 점(blip)이 적기인지 아니면 노이즈인지 판단하는 과정에서, 운영자의 심리 상태(보수적/공격적)가 의사결정에 영향을 미친다는 것을 발견했다.
Green과 Swets(1966)는 이를 정교한 수학적 모델로 발전시켜 "Signal Detection Theory and Psychophysics"를 출간했다. 이 이론은 현재 의료 진단, 품질 관리, 보안 검색 등 다양한 분야에 적용된다.
== 반도체 HMI 산업 동향
=== 표준화 움직임
*SEMI 표준*:
- *SEMI E95*: Operator Interface for Equipment (2004년 제정)
- *SEMI E125*: Alarm Management (2006년 제정)
- *SEMI E148*: Interface for Remote Service (2013년 제정)
*국제 표준*:
- *IEC 62682*: Management of Alarms for Process Industries
- *ISO 9241-9*: Ergonomics of Human-System Interaction (터치스크린 요구사항)
=== 주요 장비사 HMI 전략 비교
#figure(table(columns: (auto, auto, auto, auto), align: left, [*회사*], [*플랫폼*], [*특징*], [*기술 스택*], [Applied Materials], [Centura], [통합 멀티챔버 제어], [C++ / Qt], [ASML], [TWINSCAN], [초정밀 리소그래피], [C\# / WPF], [Tokyo Electron], [Vesta], [AI 기반 최적화], [Python / Web], [Lam Research], [Flex], [모듈러 아키텍처], [C\# / WPF], ), caption: "주요 반도체 장비사 HMI 플랫폼 비교")
=== 기술 트렌드
*1. 클라우드 연결*:
- 원격 모니터링 및 진단
- 빅데이터 분석을 통한 예지 보전
- 보안 문제로 제한적 적용
*2. AI/ML 통합*:
- 이상 패턴 자동 감지
- 최적 공정 파라미터 추천
- Predictive Maintenance
*3. AR/VR 활용*:
- 원격 교육 및 훈련
- 3D 시각화를 통한 장비 상태 확인
- 가상 유지보수 시뮬레이션
*4. 웹 기반 HMI*:
- HTML5, WebGL 기반 클라이언트
- 크로스 플랫폼 호환성
- 보안 및 실시간 성능 이슈
== 인지심리학 이론적 기반
HCI는 인지심리학의 여러 이론적 토대 위에 구축되었다. 반도체 HMI 설계를 이해하기 위해서는 인간의 정보처리 메커니즘에 대한 이론적 배경을 먼저 이해해야 한다.
=== 정보처리이론 (Information Processing Theory)
Broadbent(1958)와 Atkinson & Shiffrin(1968)이 제안한 정보처리이론은 인간의 인지를 컴퓨터의 정보처리 과정에 비유한다.
*모델 구성요소: *
1. **감각 기억 (Sensory Memory)**
  - 용량: 매우 큼 (거의 무제한)
  - 지속 시간: 시각 250ms, 청각 4초
  - 기능: 환경 자극의 일시적 저장
2. **단기 기억 / 작업 기억 (Working Memory)**
  - 용량: 7±2 청크 (Miller, 1956)
  - 지속 시간: 약 18-30초
  - 기능: 의식적 정보 처리 및 조작
3. **장기 기억 (Long-term Memory)**
  - 용량: 사실상 무제한
  - 지속 시간: 영구적
  - 기능: 지식과 경험의 영구 저장
*반도체 HMI 적용: *
- 알람 발생 시 250ms 이내 시각적 피드백 제공 (감각 기억)
- 작업 기억 부하 최소화를 위한 정보 청킹 (7±2 법칙)
- 숙련 운영자의 장기 기억 활용 (일관된 UI 패턴)
=== 인지 부하 이론 (Cognitive Load Theory)
Sweller(1988)의 인지 부하 이론은 작업 기억의 제한된 용량과 학습 효율성의 관계를 설명한다.
*3가지 인지 부하 유형: *
1. **내재적 부하 (Intrinsic Load)**
  - 정의: 과제 자체의 복잡도
  - 예: CVD 공정의 고유한 복잡성
  - 감소 방법: 과제 자체는 변경 불가, 점진적 학습 설계
2. **외재적 부하 (Extraneous Load)**
  - 정의: 불필요한 정보로 인한 부하
  - 예: 복잡한 UI, 불필요한 애니메이션
  - 감소 방법: UI 단순화, 정보 계층화
3. **생성적 부하 (Germane Load)**
  - 정의: 학습과 이해를 위한 유익한 부하
  - 예: 스키마 형성, 패턴 인식
  - 증가 방법: 적절한 연습, 피드백 제공
*반도체 HMI 설계 원칙: *
- 외재적 부하 최소화: SEMI E95 표준 준수, 일관된 색상 코드
- 생성적 부하 최적화: 시뮬레이터를 통한 훈련, 상황별 도움말
#figure(table(columns: (auto, auto, auto), align: left, [*부하 유형*], [*HMI 사례*], [*설계 전략*], [내재적], [공정 복잡도], [단계적 학습], [외재적], [복잡한 UI], [단순화 / 표준화], [생성적], [스키마 형성], [시뮬레이터 훈련], ), caption: "인지 부하 유형과 HMI 설계 전략")
=== 작업 기억 모델 (Working Memory Model)
Baddeley & Hitch(1974)의 다중 구성요소 모델은 작업 기억이 단일 저장소가 아니라 여러 하위 시스템으로 구성된다고 주장한다.
*구성요소: *
1. **중앙 실행기 (Central Executive)**
  - 기능: 주의 통제, 정보 조정
  - 용량: 매우 제한적
  - HMI 적용: 중요 정보에 주의 집중 유도 (색상, 크기)
2. **음운 루프 (Phonological Loop)**
  - 기능: 언어 정보 일시 저장
  - 용량: 약 2초 분량 발화
  - HMI 적용: 알람 메시지는 간결하게 (10단어 이내)
3. **시공간 스케치패드 (Visuospatial Sketchpad)**
  - 기능: 시각/공간 정보 저장
  - 용량: 3-4개 객체
  - HMI 적용: 동시 표시 차트 개수 제한 (최대 4개)
4. **일화적 버퍼 (Episodic Buffer)**
  - 기능: 다중 감각 정보 통합
  - HMI 적용: 시각+청각 멀티모달 알람
*듀얼 코딩 이론 (Dual Coding Theory, Paivio, 1986): *
- 시각 정보와 언어 정보를 함께 제공하면 작업 기억 효율 증가
- 예: 압력 수치(텍스트) + 게이지(시각)
=== 주의 자원 이론 (Attention Resource Theory)
Kahneman(1973)의 주의 자원 이론은 인간의 주의가 제한된 자원이며, 여러 과제에 분산될 수 있다고 설명한다.
*주의의 특성: *
1. **제한된 용량 (Limited Capacity)**
  - 동시에 처리 가능한 정보량 제한
  - 과부하 시 성능 저하
2. **선택적 주의 (Selective Attention)**
  - 중요 정보에 선택적 집중
  - 칵테일 파티 효과 (Cherry, 1953)
3. **분산 주의 (Divided Attention)**
  - 여러 과제 동시 수행
  - 자동화된 과제일수록 용이
*반도체 HMI 설계 원칙: *
- 알람 시 Pre-attentive Processing 활용 (빨간색, 깜박임)
- 주의 분산 최소화: 한 번에 하나의 Critical 알람만 표시
- Change Blindness 방지: 변경사항 명확히 표시
*Endsley의 상황 인식 모델 (Situation Awareness, 1995): *
```
Level 1: Perception of Elements
   ↓
Level 2: Comprehension of Current Situation
   ↓
Level 3: Projection of Future Status
```
- Level 1: 센서 값 인지 (온도 450°C)
- Level 2: 상황 이해 (정상 범위 초과)
- Level 3: 미래 예측 (5분 후 알람 발생 예상)
== HCI 이론 핵심 개념
=== Miller's Law (7±2)
Miller's Law는 인간의 단기 기억 용량이 약 7±2개의 정보 항목으로 제한된다는 원리이다.
*반도체 HMI 적용*:
- 한 화면에 7±2개 이하의 핵심 파라미터만 표시
- 주요 파라미터: 온도, 압력, 가스유량 등
- 정보 청킹을 통한 계층화 전략
#figure(table(columns: (auto, auto, auto), align: left, [*분류*], [*파라미터*], [*표시 개수*], [공정 파라미터], [온도, 압력, 유량], [5-7개], [상태 정보], [진공도, RF 파워], [2-3개], [알람/경고], [Critical 알람만], [최대 3개], ), caption: "Miller's Law 기반 정보 표시 원칙")
=== Fitts' Law
Fitts' Law는 Paul Fitts(1954)가 제안한 인간의 운동 제어 모델로, 목표물까지의 이동 시간이 거리와 크기에 의해 결정된다는 원리이다.
==== 수학적 모델
$ "MT" = a + b log_2(D/W + 1) = a + b "ID" $
여기서:
- MT (Movement Time): 목표물 획득 시간
- D (Distance): 시작점에서 목표물까지의 거리
- W (Width): 목표물의 크기 (운동 방향)
- ID (Index of Difficulty): 과제의 난이도
- a, b: 경험적 상수 (a ≈ 50-100ms, b ≈ 100-150ms/bit)
Index of Difficulty(ID)는 정보 이론의 비트(bit) 단위로 측정되며, 이는 운동 제어 과제의 정보량을 나타낸다. ID가 1bit 증가할 때마다 약 100-150ms의 추가 시간이 필요하다.
==== Shannon Formulation
MacKenzie와 Buxton(1992)은 원래 공식을 개선한 Shannon formulation을 제안했다: $ "MT" = a + b log_2(D/W + 1) $
이 공식은 W=D인 극한 상황에서도 음수가 나오지 않는 장점이 있다.
==== 반도체 HMI 적용 사례
긴급 정지 버튼 설계:
- 거리 D = 300mm (중앙에서)
- 크기 W = 50mm
- ID = log₂(300/50 + 1) = log₂(7) ≈ 2.81 bits
- 예상 MT = 100 + 120×2.81 ≈ 437ms
일반 조작 버튼:
- 거리 D = 150mm
- 크기 W = 30mm
- ID = log₂(150/30 + 1) = log₂(6) ≈ 2.58 bits
- 예상 MT = 100 + 120×2.58 ≈ 410ms
*설계 원칙*:
- 긴급 정지 버튼: W ≥ 50mm, D ≤ 300mm (MT < 500ms 목표)
- 자주 사용하는 버튼: W ≥ 30mm, D ≤ 200mm
- 위험한 조작: 작은 크기 + 확인 절차 (의도하지 않은 클릭 방지)
- 터치스크린의 경우: 최소 타겟 크기 44×44 pixels (ISO 9241-9)
=== 정보처리 모델
인간의 정보처리는 감각 → 인지 → 운동의 세 단계를 거칩니다.
==== 정보처리 흐름도
```
환경 자극
   │
   │ (빛/소리/촉각)
   ↓
감각 기관
   │
   │ (250ms)
   ↓
지각/인지
   │
   │ (100ms-2s)
   ↓
의사결정
   │
   │ (70-100ms)
   ↓
운동 반응
   │
   ↓
행동 실행
```
_그림: 인간 정보처리 프로세스 흐름도 (화살표는 처리 시간을 나타냄)_
#figure(table(columns: (auto, auto, auto), align: left, [*단계*], [*처리 시간*], [*HMI 최적화*], [감각], [250ms], [명확한 시각적 피드백], [인지], [100ms-2s], [직관적인 정보 구조], [운동], [70-100ms], [적절한 버튼 크기/위치], ), caption: "정보처리 단계별 시간과 최적화 전략")
*반도체 HMI 응답 시간 목표*:
- 알람 발생 → 인지(250ms)
- 판단(500ms)
- 조치(100ms)
- *총 850ms 이내 처리*
=== 신호탐지이론 (Signal Detection Theory)
신호탐지이론(SDT)은 Green과 Swets(1966)가 정립한 이론으로, 신호(Signal)와 노이즈(Noise)를 구별하는 인간의 의사결정 과정을 수학적으로 모델링한다.
==== 수학적 모델
SDT는 신호와 노이즈가 각각 정규분포를 따른다고 가정한다: - 노이즈 분포: N ~ N(0, σ²)
- 신호+노이즈 분포: S+N ~ N(μ, σ²)
두 분포의 분리도를 나타내는 민감도 d'는 다음과 같이 정의된다: $ d' = (mu_("signal") - mu_("noise"))/sigma $
여기서:
- d' = 0: 신호와 노이즈를 전혀 구별 못함
- d' = 1: 신호와 노이즈가 1 표준편차만큼 분리됨
- d' ≥ 2: 우수한 구별 능력
==== 의사결정 행렬
#figure(table(columns: (auto, auto, auto), align: center, [], [실제: 신호], [실제: 노이즈], [응답: Yes], [Hit (정탐)], [False Alarm (오경보)], [응답: No], [Miss (미탐)], [Correct Rejection (정기각)], ), caption: "SDT 의사결정 행렬")
반응 편향(β)은 의사결정 기준의 위치를 나타낸다: $ beta = ("likelihood ratio at criterion") = (P("SN"|x_c))/(P("N"|x_c)) $
- β < 1: 자유로운 기준 (Hit 증가, False Alarm도 증가)
- β = 1: 중립적 기준
- β > 1: 보수적 기준 (False Alarm 감소, Miss 증가)
==== 반도체 HMI 적용
알람 시스템 설계 목표:
- d' ≥ 2.0 (Critical 알람과 Normal 상태 구별)
- False Alarm Rate < 5% (시간당 0.3회 이하)
- Miss Rate < 1% (Critical 상황 미탐 최소화)
실제 사례 - CVD 장비 압력 알람:
- 정상 운전: 5.0 ± 0.1 Torr
- Critical 알람 기준: 5.5 Torr 이상
- d' = (5.5 - 5.0) / 0.1 = 5.0 (매우 우수한 구별 능력)
알람 우선순위 계층:
1. Critical (빨간색, 음향): d' ≥ 3.0, β = 1.5 (보수적)
2. Warning (노란색): d' ≥ 2.0, β = 1.0 (중립)
3. Info (파란색): d' ≥ 1.0, β = 0.8 (자유로운)
== 반도체 HMI를 위한 동시성 프로그래밍 기초
반도체 제조 장비 HMI는 본질적으로 동시성(Concurrency)을 요구한다. 센서 데이터를 실시간으로 수집하면서 동시에 UI를 업데이트하고, 사용자 입력에 즉각 반응해야 한다. 이 섹션에서는 Week 3(C\#), Week 7(Python), Week 10(C++)에서 다룰 실제 구현 전에 반드시 이해해야 할 동시성 프로그래밍의 이론적 기반을 다룬다.
=== 동시성의 필요성
==== 반도체 HMI의 동시 작업 요구사항
반도체 제조 장비 HMI에서 동시에 처리해야 하는 작업들:
1. **센서 데이터 수집** (10-100Hz)
   - 온도, 압력, 가스 유량 센서 폴링
   - PLC/SECS-GEM 통신
   - 로그 데이터 버퍼링
2. **UI 렌더링** (30-60Hz)
   - 차트 업데이트 (실시간 트렌딩)
   - 알람 표시
   - 애니메이션 처리
3. **사용자 입력 처리** (즉시 응답)
   - 버튼 클릭 (Fitts' Law: < 500ms)
   - 레시피 편집
   - 긴급 정지 명령
4. **백그라운드 작업**
   - 데이터베이스 저장
   - 네트워크 통신 (MES/ERP)
   - 파일 I/O (로그 기록)

만약 단일 스레드로 이 모든 작업을 순차 처리하면: - 센서 데이터 수집 (100ms) + UI 렌더링 (16ms) + 파일 I/O (200ms) = 316ms/cycle
- 실제 응답 속도: 3.16Hz (목표: 10-100Hz) ❌
- UI 프리징 발생 → 사용자 경험 저하

*동시성 적용 후*:
- 센서 수집 Thread: 100Hz 달성
- UI Thread: 60Hz 달성
- I/O Thread: 백그라운드 처리
- 사용자 입력: 즉시 응답
=== 동시성과 병렬성의 개념
==== Concurrency vs Parallelism
Rob Pike(Go 언어 개발자)의 명언: "Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once."
*동시성 (Concurrency)*:
- 정의: 여러 작업을 다루는(dealing) 구조적 설계
- 구현: 단일 CPU 코어에서도 가능 (Time-slicing)
- 예: 단일 코어에서 센서 수집 + UI 업데이트를 번갈아 실행
- 목표: 응답성(Responsiveness) 향상

*병렬성 (Parallelism)*:
- 정의: 여러 작업을 실제로 동시 실행(doing)
- 구현: 멀티코어/멀티프로세서 필요
- 예: 4개 코어에서 4개 챔버 데이터를 동시 처리
- 목표: 처리량(Throughput) 향상

==== 시각화
```
# 동시성 (Concurrency) - 단일 코어
시간 →
Core 1: [Task A][Task B][Task A][Task B][Task A]
       (빠른 전환으로 동시 실행처럼 보임)

# 병렬성 (Parallelism) - 멀티코어
시간 →
Core 1: [Task A][Task A][Task A][Task A]
Core 2: [Task B][Task B][Task B][Task B]
       (실제로 동시 실행)

# 반도체 HMI: 동시성 + 병렬성
Core 1: [UI Render][UI Render][UI Render]  (60Hz)
Core 2: [Sensor 1][Sensor 1][Sensor 1]     (100Hz)
Core 3: [Sensor 2][Sensor 2][Sensor 2]     (100Hz)
Core 4: [File I/O][DB Save][Network]       (Background)
```

==== 반도체 HMI 적용 전략
#figure(table(columns: (auto, auto, auto), align: left, [*작업 유형*], [*동시성 전략*], [*병렬성 활용*], [UI 렌더링], [별도 Thread (Main)], [GPU 가속], [센서 수집], [Worker Thread], [멀티코어 분산], [데이터 처리], [Thread Pool], [병렬 처리], [파일 I/O], [비동기 I/O], [불필요], ), caption: "반도체 HMI 동시성 전략")
=== 멀티스레딩 vs 멀티프로세싱
==== 프로세스(Process)와 스레드(Thread)의 차이
*프로세스*:
- 정의: 실행 중인 프로그램의 인스턴스
- 메모리: 독립적 주소 공간 (4GB~ in 64-bit)
- 구성: Code, Data, Heap, Stack
- 생성 비용: 높음 (Windows: ~10ms, Linux: ~5ms)
- 통신: IPC (Inter-Process Communication)
  - Pipe, Socket, Shared Memory, Message Queue

*스레드*:
- 정의: 프로세스 내 실행 단위
- 메모리: 프로세스 메모리 공유 (Stack만 독립)
- 구성: Stack, Registers, Program Counter
- 생성 비용: 낮음 (~1ms)
- 통신: 공유 메모리 (직접 접근)

==== 상세 비교표
#figure(table(columns: (auto, auto, auto, auto), align: left, [*특성*], [*프로세스*], [*스레드*], [*반도체 HMI 영향*], [메모리], [독립 (4GB~)], [공유 (1MB stack)], [Thread 선호], [생성 비용], [10ms], [1ms], [Thread Pool 사용], [컨텍스트 스위칭], [느림 (TLB flush)], [빠름], [실시간성 유리], [통신 오버헤드], [높음 (IPC)], [낮음 (메모리)], [Thread 선호], [안정성], [높음 (격리)], [낮음 (크래시 전파)], [Critical 작업 분리], [디버깅], [쉬움 (격리)], [어려움 (Race)], [철저한 테스트 필요], ), caption: "프로세스 vs 스레드 상세 비교")
==== I/O-bound vs CPU-bound 작업
*I/O-bound 작업*:
- 특징: 입출력 대기 시간이 대부분
- CPU 사용률: 낮음 (< 30%)
- 예: 파일 읽기, 네트워크 통신, 센서 폴링
- 최적 전략: 멀티스레딩 + 비동기 I/O
- 스레드 개수: CPU 코어 수보다 많아도 됨 (10-100개)

*CPU-bound 작업*:
- 특징: 계산이 대부분
- CPU 사용률: 높음 (> 80%)
- 예: 이미지 처리, FFT 계산, 데이터 압축
- 최적 전략: 멀티프로세싱 (GIL 회피)
- 스레드 개수: CPU 코어 수와 동일 (4-8개)

*반도체 HMI 사례*:
```python
# I/O-bound: 센서 데이터 수집 (Threading 적합)
def collect_sensor_data():
    while True:
        data = sensor.read()  # I/O 대기 (GIL 해제)
        queue.put(data)
        time.sleep(0.01)  # 100Hz

# CPU-bound: 웨이퍼 이미지 분석 (Multiprocessing 적합)
def analyze_wafer_image(image):
    fft_result = np.fft.fft2(image)  # CPU 집약적
    defects = detect_defects(fft_result)
    return defects
```
=== 운영체제별 스레딩 모델
==== Windows 스레딩
*Thread API*:
- Win32: `CreateThread`, `WaitForSingleObject`
- .NET: `System.Threading.Thread`, `Task`
- 커널 객체: HANDLE 기반

*스케줄링*:
- 알고리즘: Priority-based Preemptive
- 우선순위: 0-31 levels (0=가장 낮음, 31=실시간)
- 시간 할당: 기본 20ms quantum (Server: 120ms)
- 우선순위 부스팅: I/O 완료 시 일시적 상승

*MMCSS (Multimedia Class Scheduler Service)*:
```csharp
// 실시간 우선순위 설정 (반도체 HMI Critical Thread)
[DllImport("avrt.dll")]
static extern IntPtr AvSetMmThreadCharacteristics(string taskName, out uint taskIndex);

uint taskIndex;
IntPtr handle = AvSetMmThreadCharacteristics("Pro Audio", out taskIndex);
// 이제 이 스레드는 높은 우선순위로 스케줄링됨
```

*고성능 I/O: IOCP (I/O Completion Port)*:
- 비동기 I/O 완료 알림
- Thread Pool 자동 관리
- 수만 개 동시 연결 처리 가능
- 반도체 MES 통신에 활용

==== Linux 스레딩
*Thread API*:
- POSIX: `pthread_create`, `pthread_join`
- 커널 객체: NPTL (Native POSIX Thread Library)

*스케줄링*:
- 기본: CFS (Completely Fair Scheduler)
- 실시간: SCHED_FIFO, SCHED_RR
- 우선순위: 1-99 (1=가장 낮음, 99=최고)
- 시간 할당: 동적 (CFS는 vruntime 기반)

*Real-time 설정*:
```c
// SCHED_FIFO: 선점형 실시간 스케줄링
#include <pthread.h>
#include <sched.h>

struct sched_param param;
param.sched_priority = 80;  // 높은 우선순위
pthread_setschedparam(pthread_self(), SCHED_FIFO, &param);
```

*PREEMPT_RT 패치*:
- 표준 Linux: Soft Real-time (밀리초 단위)
- PREEMPT_RT: Hard Real-time (마이크로초 단위)
- 반도체 장비 제어용 Linux에서 필수

*고성능 I/O: epoll*:
```c
// epoll: 대량 소켓 연결 모니터링
int epfd = epoll_create1(0);
struct epoll_event ev;
ev.events = EPOLLIN;
ev.data.fd = sockfd;
epoll_ctl(epfd, EPOLL_CTL_ADD, sockfd, &ev);
```

==== Windows vs Linux 비교
#figure(table(columns: (auto, auto, auto), align: left, [*항목*], [*Windows*], [*Linux*], [스레드 구현], [1:1 (kernel thread)], [1:1 (NPTL)], [기본 스케줄링], [Priority-based], [CFS (fair)], [실시간 지원], [MMCSS (soft)], [SCHED_FIFO (hard)], [타이머 정밀도], [1-15ms (개선 가능)], [< 1ms (PREEMPT_RT)], [I/O 모델], [IOCP (Proactor)], [epoll (Reactor)], [HMI 프레임워크], [WPF, WinForms], [Qt, GTK], ), caption: "Windows vs Linux 스레딩 비교")
*크로스 플랫폼 개발 시 고려사항*:
- Qt Framework: 플랫폼 독립적 QThread 제공
- .NET Core: Windows/Linux 모두 지원 (Task, async/await)
- 실시간성: Linux가 유리 (PREEMPT_RT)
- 개발 생태계: Windows가 풍부 (Visual Studio)
- 반도체 장비: 역사적으로 Windows 선호, 최근 Linux 증가
=== 동기화와 Locking Mechanism
==== Race Condition (경쟁 조건)
*정의*: 여러 스레드가 공유 데이터에 동시 접근하여 실행 순서에 따라 결과가 달라지는 상황
*반도체 HMI 사례*:
```python
# 잘못된 코드: Race Condition 발생
class SensorData:
    def __init__(self):
        self.temperature = 0.0
        self.count = 0

    def update(self, temp):
        # 문제: 두 스레드가 동시 실행 시
        self.count += 1  # READ-MODIFY-WRITE (비원자적!)
        self.temperature = temp

# Thread 1과 Thread 2가 동시에 update() 호출
# 예상: count = 2
# 실제: count = 1 (하나의 증가가 손실됨) ❌
```

*메모리 레벨 분석*:
```
Thread 1:           Memory:         Thread 2:
                    count = 0
READ count (0)                      READ count (0)
ADD 1 → temp1=1                     ADD 1 → temp2=1
WRITE temp1 (1)     count = 1
                                    WRITE temp2 (1)  count = 1 ❌
```

==== 동기화 메커니즘
===== 1. Mutex (Mutual Exclusion)
*특징*:
- 상호 배제 보장 (한 번에 한 스레드만 진입)
- 소유권(Ownership) 있음: 잠근 스레드만 해제 가능
- 재진입(Reentrant) 가능 (Recursive Mutex)

*사용 사례*: 공유 데이터 보호
```python
import threading

class SensorData:
    def __init__(self):
        self.temperature = 0.0
        self.count = 0
        self.mutex = threading.Lock()  # Mutex

    def update(self, temp):
        with self.mutex:  # 자동 획득/해제
            self.count += 1  # 이제 안전함 ✓
            self.temperature = temp
```

*C\# 예제*:
```csharp
private readonly object lockObj = new object();
private int count = 0;

public void Update()
{
    lock (lockObj)  // Monitor.Enter/Exit
    {
        count++;  // Thread-safe
    }
}
```

===== 2. Semaphore (세마포어)
*특징*:
- 카운터 기반 (N개 리소스 관리)
- 소유권 없음 (누구나 signal 가능)
- Binary Semaphore (N=1) = Mutex와 유사

*사용 사례*: 제한된 리소스 풀 관리
```python
import threading

# 최대 3개 챔버만 동시 공정 실행
chamber_semaphore = threading.Semaphore(3)

def process_wafer(chamber_id):
    with chamber_semaphore:  # 최대 3개까지 진입
        print(f"Chamber {chamber_id} processing...")
        time.sleep(10)  # 공정 수행
        print(f"Chamber {chamber_id} done")
```

===== 3. Monitor (모니터)
*특징*:
- Mutex + Condition Variable
- Wait/Notify(Pulse) 메커니즘
- 조건 대기 및 신호

*사용 사례*: Producer-Consumer 패턴
```csharp
class DataQueue
{
    private Queue<double> queue = new Queue<double>();
    private readonly object lockObj = new object();

    // Producer
    public void Enqueue(double data)
    {
        lock (lockObj)
        {
            queue.Enqueue(data);
            Monitor.Pulse(lockObj);  // Consumer 깨우기
        }
    }

    // Consumer
    public double Dequeue()
    {
        lock (lockObj)
        {
            while (queue.Count == 0)
                Monitor.Wait(lockObj);  // 데이터 올 때까지 대기
            return queue.Dequeue();
        }
    }
}
```

===== 4. Read-Write Lock (읽기-쓰기 잠금)
*특징*:
- 다중 읽기(Multiple Readers) 허용
- 단일 쓰기(Single Writer) 보장
- 읽기 우선 vs 쓰기 우선 정책

*사용 사례*: 센서 데이터 공유 (읽기 빈도 >> 쓰기 빈도)
```python
import threading

class SensorCache:
    def __init__(self):
        self.data = {}
        self.lock = threading.RLock()  # 재진입 가능

    def read_sensor(self, sensor_id):
        with self.lock:  # 다중 읽기 가능 (RLock)
            return self.data.get(sensor_id, 0.0)

    def write_sensor(self, sensor_id, value):
        with self.lock:  # 쓰기 시 배타적
            self.data[sensor_id] = value
```

*C\# ReaderWriterLockSlim*:
```csharp
class SensorCache
{
    private Dictionary<int, double> data = new Dictionary<int, double>();
    private ReaderWriterLockSlim rwLock = new ReaderWriterLockSlim();

    public double Read(int sensorId)
    {
        rwLock.EnterReadLock();
        try { return data[sensorId]; }
        finally { rwLock.ExitReadLock(); }
    }

    public void Write(int sensorId, double value)
    {
        rwLock.EnterWriteLock();
        try { data[sensorId] = value; }
        finally { rwLock.ExitWriteLock(); }
    }
}
```
==== Deadlock (교착 상태)
*정의*: 두 개 이상의 스레드가 서로가 점유한 리소스를 기다리며 무한 대기하는 상황
*반도체 HMI 사례*:
```python
# Deadlock 발생 코드
mutex_A = threading.Lock()
mutex_B = threading.Lock()

# Thread 1
def thread1():
    with mutex_A:
        time.sleep(0.1)  # Thread 2가 mutex_B 획득할 시간
        with mutex_B:  # 데드락! Thread 2가 mutex_B 소유 중
            print("Thread 1")

# Thread 2
def thread2():
    with mutex_B:
        time.sleep(0.1)
        with mutex_A:  # 데드락! Thread 1이 mutex_A 소유 중
            print("Thread 2")
```

===== Coffman의 4대 조건
Deadlock이 발생하려면 다음 4가지 조건이 *모두* 만족해야 한다:

1. **Mutual Exclusion (상호 배제)**
   - 리소스를 한 번에 한 스레드만 사용
   - 예: Mutex 잠금

2. **Hold and Wait (보유 및 대기)**
   - 리소스를 보유한 채로 다른 리소스 대기
   - 예: mutex_A 잠근 상태에서 mutex_B 대기

3. **No Preemption (비선점)**
   - 리소스를 강제로 빼앗을 수 없음
   - 예: 다른 스레드가 mutex를 강제 해제 불가

4. **Circular Wait (순환 대기)**
   - 스레드들이 원형으로 대기
   - 예: T1 → A → T2 → B → T1

*Deadlock 방지 전략*: 4가지 조건 중 *하나라도* 깨면 됨!
===== 해결 방법 1: Lock Ordering (순환 대기 제거)
```python
# 올바른 코드: 항상 같은 순서로 잠금
def thread1():
    with mutex_A:  # 항상 A 먼저
        with mutex_B:
            print("Thread 1")

def thread2():
    with mutex_A:  # 항상 A 먼저 (순서 동일)
        with mutex_B:
            print("Thread 2")
```

===== 해결 방법 2: Timeout (비선점 제거)
```python
# Timeout으로 포기 가능
def thread1():
    if mutex_A.acquire(timeout=1.0):
        try:
            if mutex_B.acquire(timeout=1.0):
                try:
                    print("Thread 1")
                finally:
                    mutex_B.release()
        finally:
            mutex_A.release()
```

===== 해결 방법 3: 한 번에 모두 획득 (보유 및 대기 제거)
```python
# 모든 리소스를 원자적으로 획득
global_lock = threading.Lock()

def thread1():
    with global_lock:  # 모든 리소스 획득 보장
        with mutex_A:
            with mutex_B:
                print("Thread 1")
```
==== Priority Inversion (우선순위 역전)
*정의*: 높은 우선순위 스레드가 낮은 우선순위 스레드를 기다리는 현상

*반도체 HMI 심각 사례*:
```
시나리오:
- High Priority (P=90): 긴급 정지 스레드
- Medium Priority (P=50): 로깅 스레드
- Low Priority (P=10): 센서 수집 스레드 (Mutex 소유)

시간 순서:
t=0:  Low가 Mutex 획득
t=1:  High가 Mutex 요청 → Low가 끝날 때까지 대기 (정상)
t=2:  Medium이 실행 가능 → Low를 선점 (우선순위 높음)
t=3:  High는 Medium이 끝날 때까지 무한정 대기! ❌
      → 긴급 정지 버튼이 작동 안 함! (위험!)
```

*실제 사건: Mars Pathfinder (1997)*:
- NASA의 화성 탐사선에서 Priority Inversion 발생
- 시스템이 반복적으로 재부팅됨
- 해결: Priority Inheritance 적용

===== 해결책 1: Priority Inheritance (우선순위 상속)
```
Low가 Mutex 소유 중 High가 대기하면:
→ Low를 일시적으로 High 우선순위로 승격
→ Low가 빠르게 완료
→ High가 Mutex 획득
```

*C\# 예제*:
```csharp
// .NET에서는 Monitor.Enter가 자동으로 Priority Inheritance 적용
lock (mutex)
{
    // 이 블록 실행 중 높은 우선순위 스레드 대기 시
    // 현재 스레드의 우선순위가 일시적으로 상승
}
```

===== 해결책 2: Priority Ceiling (우선순위 천장)
```
Mutex 획득 시 무조건 최고 우선순위로 상승:
→ 어떤 스레드도 선점 불가
→ Priority Inversion 원천 차단
```

*실시간 운영체제(RTOS)에서 필수 구현*
=== 실시간 시스템 고려사항
==== Hard Real-time vs Soft Real-time
#figure(table(columns: (auto, auto, auto), align: left, [*항목*], [*Hard Real-time*], [*Soft Real-time*], [데드라인], [절대적 (필수)], [통계적 (평균)], [위반 결과], [시스템 실패], [성능 저하], [예: 반도체], [진공 밸브 제어], [UI 렌더링], [OS], [RTOS (VxWorks)], [GPOS (Windows/Linux)], [Latency], [\< 1ms], [\< 100ms], ), caption: "Real-time 시스템 분류")
*반도체 장비의 실시간 요구사항*:
- **Hard Real-time**:
  - 긴급 정지 (\< 100μs)
  - RF 파워 제어 (\< 1ms)
  - 가스 밸브 제어 (\< 10ms)

- **Soft Real-time**:
  - 센서 데이터 수집 (\< 100ms)
  - UI 업데이트 (\< 16ms, 60Hz)
  - 알람 표시 (\< 500ms)

==== Latency, Jitter, Throughput
*Latency (지연)*:
- 정의: 요청부터 응답까지 시간
- 측정: 평균, 최대, 99 percentile
- 목표: 반도체 HMI \< 100ms

*Jitter (변동)*:
- 정의: Latency의 변동 폭
- 측정: 표준편차
- 목표: \< 10ms (일관성 중요)

*Throughput (처리량)*:
- 정의: 단위 시간당 처리 작업 수
- 측정: ops/sec, requests/sec
- 목표: 센서 수집 100Hz = 100 samples/sec

*예제: 센서 데이터 수집 성능 측정*:
```python
import time
import statistics

latencies = []
for i in range(1000):
    start = time.perf_counter()
    data = sensor.read()  # 센서 읽기
    end = time.perf_counter()
    latencies.append((end - start) * 1000)  # ms

print(f"평균 Latency: {statistics.mean(latencies):.2f} ms")
print(f"최대 Latency: {max(latencies):.2f} ms")
print(f"Jitter (std): {statistics.stdev(latencies):.2f} ms")
print(f"99 percentile: {sorted(latencies)[990]:.2f} ms")
```

==== RTOS vs GPOS
#figure(table(columns: (auto, auto, auto), align: left, [*항목*], [*RTOS*], [*GPOS*], [스케줄링], [Priority-based], [Fair (CFS)], [선점성], [높음 (즉시)], [낮음 (quantum)], [Latency], [\< 100μs], [\< 10ms], [Jitter], [매우 낮음], [높음], [예시], [VxWorks, QNX], [Windows, Linux], [사용 사례], [장비 제어], [HMI, 데이터 처리], ), caption: "RTOS vs GPOS 비교")
*반도체 장비 아키텍처*:
```
┌─────────────────────────────────────┐
│  HMI PC (Windows/Linux GPOS)        │
│  - UI (WPF/Qt)                      │
│  - 데이터 수집 (Soft Real-time)      │
│  - MES 통신                          │
└─────────┬───────────────────────────┘
          │ EtherCAT / Ethernet
          ↓
┌─────────────────────────────────────┐
│  제어기 (VxWorks/QNX RTOS)           │
│  - RF 파워 제어 (Hard Real-time)     │
│  - 밸브 제어                         │
│  - Safety Interlock                 │
└─────────────────────────────────────┘
```
=== 동시성 디자인 패턴
==== Producer-Consumer 패턴
*목적*: 데이터 생성과 소비를 분리하여 버퍼로 연결

*반도체 HMI 적용*: 센서 수집(Producer) → 큐 → UI 업데이트(Consumer)
```python
import threading
import queue
import time

# Thread-safe 큐
data_queue = queue.Queue(maxsize=100)

# Producer: 센서 데이터 수집
def producer():
    sensor_id = 0
    while True:
        data = f"Sensor_{sensor_id}: {random.uniform(20, 30):.2f}°C"
        data_queue.put(data)  # 큐에 삽입 (자동 블로킹)
        sensor_id += 1
        time.sleep(0.01)  # 100Hz

# Consumer: UI 업데이트
def consumer():
    while True:
        data = data_queue.get()  # 큐에서 꺼냄 (데이터 올 때까지 대기)
        print(f"UI Update: {data}")
        data_queue.task_done()  # 처리 완료 표시

# 스레드 시작
threading.Thread(target=producer, daemon=True).start()
threading.Thread(target=consumer, daemon=True).start()
```

*장점*:
- Producer/Consumer 속도 차이 흡수
- 버퍼링으로 burst 처리
- 독립적 개발 및 테스트

==== Reader-Writer 패턴
*목적*: 읽기는 동시 허용, 쓰기는 배타적 보장

*반도체 HMI 적용*: 여러 UI 컴포넌트가 센서 데이터 읽기
```python
import threading

class SensorDataStore:
    def __init__(self):
        self.data = {}
        self.lock = threading.RLock()
        self.readers = 0
        self.writer = False

    def read(self, sensor_id):
        with self.lock:
            self.readers += 1
        try:
            return self.data.get(sensor_id, 0.0)
        finally:
            with self.lock:
                self.readers -= 1

    def write(self, sensor_id, value):
        with self.lock:
            while self.readers > 0 or self.writer:
                time.sleep(0.001)  # 읽기/쓰기 완료 대기
            self.writer = True
        try:
            self.data[sensor_id] = value
        finally:
            with self.lock:
                self.writer = False
```

==== Thread Pool 패턴
*목적*: 스레드 생성 비용 절감 및 재사용

*반도체 HMI 적용*: 여러 챔버 데이터 병렬 처리
```python
from concurrent.futures import ThreadPoolExecutor

# 4개 워커 스레드 풀 생성
with ThreadPoolExecutor(max_workers=4) as executor:
    chambers = [1, 2, 3, 4, 5, 6, 7, 8]

    # 8개 챔버 데이터를 4개 스레드로 병렬 처리
    results = executor.map(process_chamber_data, chambers)

    for chamber_id, result in enumerate(results, 1):
        print(f"Chamber {chamber_id}: {result}")
```

*장점*:
- 스레드 생성/삭제 오버헤드 제거
- 동시 실행 스레드 수 제한 (리소스 관리)
- 작업 큐 자동 관리

==== Active Object 패턴
*목적*: 메서드 호출을 별도 스레드에서 비동기 실행

*반도체 HMI 적용*: 장비 명령 큐잉
```python
import threading
import queue

class EquipmentController:
    def __init__(self):
        self.command_queue = queue.Queue()
        self.worker_thread = threading.Thread(target=self._process_commands, daemon=True)
        self.worker_thread.start()

    def _process_commands(self):
        while True:
            command, args = self.command_queue.get()
            try:
                command(*args)  # 명령 실행
            finally:
                self.command_queue.task_done()

    def start_process(self, recipe_id):
        self.command_queue.put((self._do_start, (recipe_id,)))

    def stop_process(self):
        self.command_queue.put((self._do_stop, ()))

    def _do_start(self, recipe_id):
        print(f"Starting process with recipe {recipe_id}")
        time.sleep(2)  # 실제 시작 시간

    def _do_stop(self):
        print("Stopping process")
        time.sleep(1)
```
=== 실습: Race Condition 시뮬레이션
다음 Python 코드는 Race Condition을 시연하고 해결 방법을 보여준다.
==== 실습 1: Race Condition 재현
```python
#!/usr/bin/env python3
"""Race Condition 시뮬레이션"""
import threading
import time

# 공유 변수 (문제 발생)
counter = 0

def increment_unsafe():
    """Thread-unsafe 증가 함수"""
    global counter
    for _ in range(100000):
        counter += 1  # Race Condition 발생!

# 10개 스레드로 동시 실행
threads = []
start = time.time()
for _ in range(10):
    t = threading.Thread(target=increment_unsafe)
    threads.append(t)
    t.start()

for t in threads:
    t.join()

elapsed = time.time() - start

print(f"예상 결과: {10 * 100000}")
print(f"실제 결과: {counter}")
print(f"손실: {10 * 100000 - counter}")
print(f"소요 시간: {elapsed:.2f}s")
```

*예상 출력*:
```
예상 결과: 1000000
실제 결과: 873421  # 매번 다름!
손실: 126579       # Race Condition으로 손실
소요 시간: 0.15s
```

==== 실습 2: Mutex로 해결
```python
#!/usr/bin/env python3
"""Mutex로 Race Condition 해결"""
import threading
import time

counter = 0
counter_lock = threading.Lock()  # Mutex

def increment_safe():
    """Thread-safe 증가 함수"""
    global counter
    for _ in range(100000):
        with counter_lock:  # 임계 영역 보호
            counter += 1  # 이제 안전함 ✓

# 10개 스레드로 동시 실행
threads = []
start = time.time()
for _ in range(10):
    t = threading.Thread(target=increment_safe)
    threads.append(t)
    t.start()

for t in threads:
    t.join()

elapsed = time.time() - start

print(f"예상 결과: {10 * 100000}")
print(f"실제 결과: {counter}")
print(f"손실: {10 * 100000 - counter}")
print(f"소요 시간: {elapsed:.2f}s")
```

*예상 출력*:
```
예상 결과: 1000000
실제 결과: 1000000  # 정확함 ✓
손실: 0
소요 시간: 1.23s    # 느려짐 (Lock 오버헤드)
```

==== 실습 3: Atomic Operation으로 최적화
```python
#!/usr/bin/env python3
"""Atomic Operation으로 성능 개선"""
import threading
import time
from multiprocessing import Value
import ctypes

# Atomic counter (C 레벨에서 원자성 보장)
counter = Value(ctypes.c_int64, 0)

def increment_atomic():
    """Atomic 증가 함수"""
    for _ in range(100000):
        with counter.get_lock():  # 내부적으로 원자적
            counter.value += 1

# 10개 스레드로 동시 실행
threads = []
start = time.time()
for _ in range(10):
    t = threading.Thread(target=increment_atomic)
    threads.append(t)
    t.start()

for t in threads:
    t.join()

elapsed = time.time() - start

print(f"예상 결과: {10 * 100000}")
print(f"실제 결과: {counter.value}")
print(f"손실: {10 * 100000 - counter.value}")
print(f"소요 시간: {elapsed:.2f}s")
```
=== MCQ: 동시성 프로그래밍 (Multiple Choice Questions)
==== 문제 1: 동시성 vs 병렬성 (기초)
단일 CPU 코어 시스템에서 가능한 것은?

A. 동시성만 가능 \
B. 병렬성만 가능 \
C. 둘 다 가능 \
D. 둘 다 불가능

#pagebreak(weak: true)

*정답: A*

*해설*: 단일 코어에서는 Time-slicing(시간 분할)으로 동시성을 구현할 수 있지만, 실제 동시 실행(병렬성)은 멀티코어가 필요하다.

---

==== 문제 2: 프로세스 vs 스레드 (기초)
다음 중 스레드의 장점이 아닌 것은?

A. 생성 비용이 낮다 \
B. 컨텍스트 스위칭이 빠르다 \
C. 메모리 격리로 안정성이 높다 \
D. 공유 메모리로 통신 오버헤드가 낮다

#pagebreak(weak: true)

*정답: C*

*해설*: 메모리 격리는 프로세스의 장점이다. 스레드는 메모리를 공유하므로 한 스레드의 크래시가 전체 프로세스에 영향을 줄 수 있다.

---

==== 문제 3: I/O-bound vs CPU-bound (중급)
센서 데이터 수집 작업(I/O-bound)에 가장 적합한 전략은?

A. 단일 스레드 \
B. 멀티스레딩 \
C. 멀티프로세싱 \
D. GPU 가속

#pagebreak(weak: true)

*정답: B*

*해설*: I/O-bound 작업은 대기 시간이 많아 멀티스레딩이 효율적이다. 멀티프로세싱은 CPU-bound 작업에 적합하다.

---

==== 문제 4: Deadlock 조건 (중급)
다음 중 Deadlock 방지를 위해 깨야 할 조건이 아닌 것은?

A. Mutual Exclusion \
B. Hold and Wait \
C. Preemption \
D. Thread Priority

#pagebreak(weak: true)

*정답: D*

*해설*: Coffman의 4대 조건은 Mutual Exclusion, Hold and Wait, No Preemption, Circular Wait이다. Thread Priority는 Deadlock 조건이 아니다.

---

==== 문제 5: Priority Inversion (고급)
Priority Inversion을 해결하는 방법은?

A. Priority Inheritance \
B. Deadlock Detection \
C. Lock Ordering \
D. Timeout

#pagebreak(weak: true)

*정답: A*

*해설*: Priority Inheritance는 낮은 우선순위 스레드가 Mutex를 소유할 때, 높은 우선순위 스레드가 대기 중이면 일시적으로 우선순위를 상승시켜 Priority Inversion을 방지한다.

---

==== 문제 6: 코드 분석 - Race Condition (고급)
다음 코드에서 Race Condition이 발생하는 이유는?

```python
counter = 0
def increment():
    counter += 1
```

A. counter가 전역 변수라서 \
B. +=이 원자적(atomic) 연산이 아니라서 \
C. 함수가 반환값이 없어서 \
D. 스레드가 너무 많아서

#pagebreak(weak: true)

*정답: B*

*해설*: `counter += 1`은 READ-MODIFY-WRITE 3단계로 이루어진 비원자적 연산이다. 두 스레드가 동시에 실행하면 증가가 손실될 수 있다.

---

==== 문제 7: Windows vs Linux 스레딩 (중급)
Linux PREEMPT_RT 패치의 주요 목적은?

A. 성능 향상 \
B. Hard Real-time 지원 \
C. 전력 절약 \
D. 보안 강화

#pagebreak(weak: true)

*정답: B*

*해설*: PREEMPT_RT 패치는 Linux를 Hard Real-time 시스템으로 만들어 마이크로초 단위의 정밀한 제어를 가능하게 한다.

---

==== 문제 8: 동시성 패턴 (고급)
Producer-Consumer 패턴의 핵심 구성 요소는?

A. Mutex \
B. Semaphore \
C. Queue (Buffer) \
D. Thread Pool

#pagebreak(weak: true)

*정답: C*

*해설*: Producer-Consumer 패턴의 핵심은 생산자와 소비자를 분리하는 큐(버퍼)이다. Mutex/Semaphore는 큐의 Thread-safety를 보장하는 도구일 뿐이다.

---

==== 문제 9: Latency vs Throughput (중급)
반도체 HMI에서 더 중요한 것은?

A. Latency (지연) \
B. Throughput (처리량) \
C. 둘 다 중요 \
D. 상황에 따라 다름

#pagebreak(weak: true)

*정답: A*

*해설*: 반도체 HMI는 실시간 응답이 중요하므로 Latency가 더 우선이다. Throughput은 데이터 처리 시스템에서 중요하다.

---

==== 문제 10: 종합 응용 (도전)
4개 코어 CPU에서 8개 센서 데이터를 수집한다. 각 센서 읽기는 I/O-bound이고 50ms 걸린다. 단일 스레드 vs 8개 스레드의 총 소요 시간은?

A. 400ms vs 400ms \
B. 400ms vs 200ms \
C. 400ms vs 100ms \
D. 400ms vs 50ms

#pagebreak(weak: true)

*정답: D*

*해설*:
- 단일 스레드: 8 × 50ms = 400ms
- 8개 스레드 (I/O-bound): I/O 대기 중 다른 스레드 실행 → 병렬 처리 → 약 50ms
  (실제로는 약간의 오버헤드가 있지만 거의 50ms에 근접)
== 반도체 HMI 특수 요구사항
=== 클린룸 환경 (ISO 14644-1)
#figure(table(columns: (auto, auto, auto), align: left, [*항목*], [*기준값*], [*비고*], [Class 1 입자 농도], [\< 10개/m³ (0.1μm)], [최첨단 리소그래피], [온도 제어 정밀도], [±0.1°C], [일부 공정 ±0.05°C], [습도 제어 정밀도], [±1% RH], [포토 공정 45±1% 유지], ), caption: "클린룸 환경 요구사항")
=== 고신뢰성
#figure(table(columns: (auto, auto, auto), align: left, [*항목*], [*기준값*], [*비고*], [MTBF], [>8760시간], [1년 이상], [MTTR], [\< 30분], [신속 복구], [가용성], [99.94%], [MTBF/(MTBF+MTTR)], ), caption: "고신뢰성 요구사항")
=== 실시간 응답
#figure(table(columns: (auto, auto), align: left, [*시스템*], [*응답 시간*], [일반 HCI], [100ms-2s], [반도체 HMI], [10ms-100ms], [알람 응답], [\< 50ms], ), caption: "실시간 응답 요구사항")
반도체 HMI는 일반 시스템보다 *10배 빠른 응답*이 요구된다.
== SEMI 표준
=== SEMI E95: 반도체 제조 장비 운영자 인터페이스
SEMI E95는 반도체 장비 HMI 설계의 국제 표준이다.
*주요 내용*:
- 화면 레이아웃 가이드라인
- 색상 사용 원칙
- 알람 표시 방법
- 에르고노믹 요구사항
*색상 코드*:
- 🔴 빨강: 긴급/위험
- 🟡 노랑: 경고
- 🟢 초록: 정상
- 🔵 파랑: 정보
=== 에르고노믹 가이드라인
- 화면 높이: 눈높이 ±15°
- 조작 패널 높이: 바닥에서 75-120cm
- 버튼 크기: 최소 15mm
- 긴급 정지: 50mm 이상
== 실제 HMI 사례 분석
=== ASML (리소그래피 장비)
*특징*:
- 초정밀 웨이퍼 얼라인먼트
- 실시간 오버레이 모니터링
- 3D 시각화
=== Applied Materials (CVD/PVD/Etch)
*특징*:
- 멀티 챔버 통합 제어
- 공정 레시피 관리
- 실시간 데이터 트렌딩
=== Tokyo Electron (코팅/현상)
*특징*:
- 포토레지스트 코팅 균일도 모니터링
- 자동화된 레시피 최적화
- 예지 보전 (Predictive Maintenance)
== 사용성 테스트 방법론
=== System Usability Scale (SUS)
10개 질문으로 구성된 사용성 평가 척도:
- 점수 범위: 0-100
- 70점 이상: 우수
- 50점 이하: 개선 필요
=== NASA Task Load Index (NASA-TLX)
작업 부하를 6가지 차원으로 평가:
- 정신적 요구
- 신체적 요구
- 시간적 요구
- 성과
- 노력
- 좌절
=== Situation Awareness Global Assessment Technique (SAGAT)
상황 인식 평가 기법:
- Level 1: 요소 인지
- Level 2: 이해
- Level 3: 예측
== 실습: Python 기반 HCI 계산 도구
=== 실습 1: Fitts' Law 계산기
다음 Python 코드는 Fitts' Law를 계산하는 도구이다. 이 코드를 실행하여 다양한 버튼 설계를 평가수행한다.
```python
#!/usr/bin/env python3
"""Fitts' Law 계산기"""
import math
def calculate_fitts_law(distance, width, a=100, b=120): """
    Fitts' Law에 따른 Movement Time 계산
    Args: distance (float): 시작점에서 목표까지의 거리 (mm)
        width (float): 목표의 크기 (mm)
        a (float): 경험적 상수 a (기본값: 100ms)
        b (float): 경험적 상수 b (기본값: 120ms/bit)
    Returns: tuple: (ID, MT) - Index of Difficulty (bits), Movement Time (ms)
    """
    # Index of Difficulty 계산
    ID = math.log2(distance / width + 1)
    # Movement Time 계산
    MT = a + b * ID
    return ID, MT
def compare_buttons(buttons, a=100, b=120): """
    여러 버튼 후보를 비교
    Args: buttons (list): [(이름, x, y, width), ...] 형식의 버튼 리스트
        a, b (float): Fitts' Law 상수
    Returns: None (결과를 출력)
    """
    print("=" * 60)
    print("Fitts' Law 기반 버튼 비교")
    print("=" * 60)
    results = []
    for name, x, y, width in buttons: # 거리 계산 (원점 0, 0 기준)
        distance = math.sqrt(x**2 + y**2)
        # Fitts' Law 계산
        ID, MT = calculate_fitts_law(distance, width, a, b)
        results.append((name, distance, width, ID, MT))
        print(f"\n{name}: ")
        print(f"  위치: ({x}, {y}) mm")
        print(f"  거리 D: {distance: .1f} mm")
        print(f"  크기 W: {width} mm")
        print(f"  난이도 ID: {ID: .2f} bits")
        print(f"  예상 시간 MT: {MT: .1f} ms")
    # 최적 버튼 찾기
    best = min(results, key=lambda x: x[4])  # MT 기준 최소
    print("\n" + "=" * 60)
    print(f"권장: {best[0]} (MT={best[4]: .1f}ms)")
    print("=" * 60)
# 예제 실행
if __name__ == "__main__": # 긴급 정지 버튼 후보 비교
    emergency_buttons = [
        ("후보 A", 200, 100, 60), # 가까운 거리, 큰 크기
        ("후보 B", 400, 50, 40), # 먼 거리, 작은 크기
        ("후보 C", 150, 150, 80), # 중간 거리, 매우 큰 크기
    ]
    compare_buttons(emergency_buttons)
    print("\n\n")
    # 일반 버튼 후보 비교
    normal_buttons = [
        ("Start", 100, 50, 40), ("Stop", 100, 100, 40), ("Reset", 100, 150, 40), ]
    compare_buttons(normal_buttons)
```
*실행 방법: *
1. 위 코드를 `fitts_law.py`로 저장
2. 터미널에서 `python fitts_law.py` 실행
3. 다양한 버튼 위치와 크기를 입력하여 실험
=== 실습 2: Signal Detection Theory 시뮬레이션
다음 Python 코드는 신호탐지이론을 시뮬레이션한다. 이 코드를 통해 d'와 β의 의미를 체험할 수 있다.
```python
#!/usr/bin/env python3
"""Signal Detection Theory 시뮬레이션"""
import numpy as np
import statistics
def sdt_simulation(mu_signal, sigma, criterion, n_trials=10000): """
    SDT 시뮬레이션
    Args: mu_signal (float): 신호 분포의 평균
        sigma (float): 표준편차
        criterion (float): 의사결정 기준
        n_trials (int): 시행 횟수
    Returns: dict: Hit Rate, False Alarm Rate, d', β
    """
    # 노이즈 분포: N(0, σ²)
    noise_samples = np.random.normal(0, sigma, n_trials)
    # 신호+노이즈 분포: N(μ, σ²)
    signal_samples = np.random.normal(mu_signal, sigma, n_trials)
    # Hit: 신호 있을 때 "Yes" 응답
    hits = np.sum(signal_samples > criterion)
    hit_rate = hits / n_trials
    # False Alarm: 신호 없을 때 "Yes" 응답
    false_alarms = np.sum(noise_samples > criterion)
    fa_rate = false_alarms / n_trials
    # Miss: 신호 있을 때 "No" 응답
    miss_rate = 1 - hit_rate
    # Correct Rejection: 신호 없을 때 "No" 응답
    cr_rate = 1 - fa_rate
    # d' 계산
    d_prime = mu_signal / sigma
    # β 계산 (근사)
    # β = (신호 분포 at criterion) / (노이즈 분포 at criterion)
    signal_pdf = np.exp(-0.5 * ((criterion - mu_signal) / sigma)**2)
    noise_pdf = np.exp(-0.5 * (criterion / sigma)**2)
    beta = signal_pdf / noise_pdf if noise_pdf > 0 else float('inf')
    return {
        'hit_rate': hit_rate, 'fa_rate': fa_rate, 'miss_rate': miss_rate, 'cr_rate': cr_rate, 'd_prime': d_prime, 'beta': beta, 'n_hits': hits, 'n_fa': false_alarms
    }
def print_sdt_results(results, scenario_name): """SDT 결과를 보기 좋게 출력"""
    print("=" * 60)
    print(f"시나리오: {scenario_name}")
    print("=" * 60)
    print(f"Hit Rate: {results['hit_rate']: .1%} ({results['n_hits']}회)")
    print(f"False Alarm Rate: {results['fa_rate']: .1%} ({results['n_fa']}회)")
    print(f"Miss Rate: {results['miss_rate']: .1%}")
    print(f"Correct Reject Rate: {results['cr_rate']: .1%}")
    print(f"\nd' (민감도): {results['d_prime']: .2f}")
    print(f"β (반응 편향): {results['beta']: .2f}")
    # 평가
    if results['d_prime'] >= 2.0: print("  → 우수한 구별 능력 ✓")
    elif results['d_prime'] >= 1.0: print("  → 보통 구별 능력")
    else: print("  → 구별 능력 부족 ✗")
    if results['beta'] > 1.0: print("  → 보수적 기준 (Miss 위험)")
    elif results['beta'] < 1.0: print("  → 자유로운 기준 (False Alarm 위험)")
    else: print("  → 중립적 기준")
    print("=" * 60)
# 예제 실행
if __name__ == "__main__": # 시나리오 1: CVD 장비 압력 알람 (Critical)
    print("\n시나리오 1: CVD Critical 알람")
    print("정상 압력: 5.0 Torr")
    print("알람 기준: 5.5 Torr")
    print("표준편차: 0.1 Torr\n")
    results1 = sdt_simulation(mu_signal=0.5, # 5.5 - 5.0 = 0.5 (정규화)
        sigma=0.1, criterion=0.3     # 5.3 Torr에서 알람 발동)
    print_sdt_results(results1, "CVD Critical Alarm (d'=5.0)")
    # 시나리오 2: PVD 장비 압력 알람 (Warning)
    print("\n\n시나리오 2: PVD Warning 알람")
    print("정상 압력: 3.0 Torr")
    print("알람 기준: 3.3 Torr")
    print("표준편차: 0.2 Torr\n")
    results2 = sdt_simulation(mu_signal=0.3, # 3.3 - 3.0 = 0.3
        sigma=0.2, criterion=0.2     # 3.2 Torr에서 알람 발동)
    print_sdt_results(results2, "PVD Warning Alarm (d'=1.5)")
    # 시나리오 3: 개선된 PVD 알람
    print("\n\n시나리오 3: 개선된 PVD Warning 알람")
    print("정상 압력: 3.0 Torr")
    print("알람 기준: 3.4 Torr (d'=2.0 달성)")
    print("표준편차: 0.2 Torr\n")
    results3 = sdt_simulation(mu_signal=0.4, # 3.4 - 3.0 = 0.4
        sigma=0.2, criterion=0.2)
    print_sdt_results(results3, "Improved PVD Warning (d'=2.0)")
```
*실행 방법: *
1. 위 코드를 `sdt_simulation.py`로 저장
2. NumPy 설치: `pip install numpy`
3. 터미널에서 `python sdt_simulation.py` 실행
4. 다양한 μ, σ, criterion 값을 변경하여 실험
== MCQ (Multiple Choice Questions)
다음 문제를 풀고 이해도를 점검한다.
=== 문제 1: Miller's Law 개념 (기초)
Miller's Law에서 인간의 단기 기억 용량은 몇 개의 정보 항목으로 제한되는가?

A. 5±2개 \
B. 7±2개 \
C. 9±2개 \
D. 10±2개

#pagebreak(weak: true)

*정답: B*

*해설*: George Miller(1956)는 인간의 단기 기억 용량이 약 7±2개, 즉 5~9개의 정보 항목(chunk)으로 제한된다는 것을 실험적으로 증명했다. 이는 반도체 HMI 설계에서 한 화면에 표시할 핵심 파라미터 개수를 결정하는 중요한 원칙이다.

---

=== 문제 2: Fitts' Law 계산 (기초)
버튼까지의 거리 D=200mm, 버튼 크기 W=50mm일 때, Index of Difficulty (ID)는? (log₂(5) ≈ 2.32)

A. 1.32 bits \
B. 2.32 bits \
C. 3.32 bits \
D. 4.32 bits

#pagebreak(weak: true)

*정답: B*

*해설*: ID = log₂(D/W + 1) = log₂(200/50 + 1) = log₂(5) ≈ 2.32 bits. ID는 과제의 난이도를 나타내며, 값이 클수록 목표물 획득이 어렵다.

---

=== 문제 3: Signal Detection Theory (중급)
신호와 노이즈의 분리도를 나타내는 민감도 d'가 2.0일 때, 이는 무엇을 의미하는가?

A. 신호와 노이즈가 2배 차이 \
B. Hit Rate가 20% \
C. 신호와 노이즈가 2 표준편차만큼 분리됨 \
D. False Alarm Rate가 2%

#pagebreak(weak: true)

*정답: C*

*해설*: d' = (μ_signal - μ_noise) / σ 공식에서 d'=2.0은 신호와 노이즈의 평균이 2 표준편차만큼 떨어져 있음을 의미한다. d' ≥ 2.0이면 우수한 구별 능력으로 간주된다.

---

=== 문제 4: 반도체 HMI 응답 시간 (중급)
반도체 HMI에서 알람 발생부터 운영자 조치까지 목표 응답 시간은?

A. 100ms \
B. 500ms \
C. 850ms \
D. 2000ms

#pagebreak(weak: true)

*정답: C*

*해설*: 반도체 HMI는 알람 인지(250ms) + 판단(500ms) + 조치(100ms) = 총 850ms 이내 응답을 목표로 한다. 이는 일반 HCI보다 훨씬 엄격한 기준이다.

---

=== 문제 5: SEMI E95 색상 코드 (기초)
SEMI E95 표준에서 빨간색이 나타내는 의미는?

A. 정상 \
B. 정보 \
C. 경고 \
D. 긴급/위험

#pagebreak(weak: true)

*정답: D*

*해설*: SEMI E95 색상 코드: 🔴 빨강=긴급/위험, 🟡 노랑=경고, 🟢 초록=정상, 🔵 파랑=정보. 이는 국제 표준으로 전 세계 반도체 장비에서 일관되게 적용된다.

---

=== 문제 6: Fitts' Law 응용 (중급)
긴급 정지 버튼의 Movement Time을 줄이는 가장 효과적인 방법은?

A. 버튼 색상을 밝게 변경 \
B. 버튼 크기를 크게 하고 가까운 위치에 배치 \
C. 버튼에 텍스트 추가 \
D. 버튼 클릭 시 소리 추가

#pagebreak(weak: true)

*정답: B*

*해설*: Fitts' Law MT = a + b·log₂(D/W + 1)에서 W(크기)를 크게 하고 D(거리)를 작게 하면 ID가 감소하여 MT가 줄어든다. 긴급 정지 버튼은 W≥50mm, D≤300mm를 권장한다.
---

=== 문제 7: 코드 분석 - Fitts' Law (고급)
다음 Python 코드의 출력 결과는?

```python
import math
ID = math.log2(300/60 + 1)
MT = 100 + 120 * ID
print(f"{MT: .0f}ms")
```

A. 368ms \
B. 400ms \
C. 437ms \
D. 500ms

#pagebreak(weak: true)

*정답: A*

*해설*:
- ID = log₂(300/60 + 1) = log₂(6) ≈ 2.58 bits
- MT = 100 + 120 × 2.58 ≈ 410ms
(계산기로 정확히 하면 약 368ms가 나옴 - log₂(6)=2.585)

---

=== 문제 8: SDT 코드 분석 (고급)
다음 SDT 시뮬레이션 코드에서 d'를 개선하려면 어떤 값을 변경해야 하는가?

```python
results = sdt_simulation(mu_signal=0.3, sigma=0.2, criterion=0.2)
```

A. criterion을 증가 \
B. sigma를 증가 \
C. mu_signal을 증가 \
D. mu_signal을 감소

#pagebreak(weak: true)

*정답: C*

*해설*: d' = mu_signal / sigma 공식에서 d'를 증가시키려면 mu_signal을 크게 하거나 sigma를 작게 해야 한다. 실무에서는 알람 기준(mu_signal)을 상향 조정하는 것이 일반적이다.

---

=== 문제 9: 정보처리 모델 응용 (고급)
다음 중 인지 처리 시간을 가장 효과적으로 단축할 수 있는 방법은?

A. 화면 밝기를 높인다 \
B. 알람 메시지를 더 명확하고 간결하게 작성한다 \
C. 버튼 크기를 크게 한다 \
D. 경고음 볼륨을 높인다

#pagebreak(weak: true)

*정답: B*

*해설*: 인지 처리 시간(100ms-2s)은 정보의 복잡도와 명확성에 영향을 받는다. 명확하고 간결한 메시지는 인지 부하를 줄여 판단 시간을 단축한다. 화면 밝기와 경고음은 감각 처리에, 버튼 크기는 운동 반응에 영향을 준다.

---

=== 문제 10: 종합 응용 (도전)
CVD 장비 HMI에 12개의 파라미터를 표시해야 한다. Miller's Law와 정보 청킹을 적용하여 화면을 설계할 때, 가장 적절한 구성은?

A. 12개 모두 메인 화면에 균등하게 배치 \
B. 3개 그룹으로 묶고 각 그룹을 대표값으로 요약하여 메인에 3개만 표시 \
C. 4개 그룹으로 묶고 각 그룹의 요약값을 메인에 표시 (총 4개 + 알람 상태) \
D. 가장 중요한 1개만 표시하고 나머지는 숨김

#pagebreak(weak: true)

*정답: C*

*해설*: Miller's Law(7±2개)를 준수하려면 12개를 그룹화해야 한다. 4개 그룹으로 묶고 각 그룹의 요약값 + 알람 상태를 표시하면 총 5개 항목으로 메인 화면을 구성할 수 있다. B는 너무 적은 정보만 제공하고, A는 Miller's Law 위반, D는 정보 손실이 너무 크다.
== 실습 과제
=== 과제 1: HMI 사례 분석
실제 반도체 장비 HMI를 선택하여 다음을 분석한다:
+ Miller's Law 적용 여부
+ Fitts' Law 준수 여부
+ SEMI E95 표준 충족도
=== 과제 2: HMI 설계 개선안
기존 HMI의 문제점을 찾고 개선안을 제시한다:
+ 정보 과부하 개선
+ 버튼 배치 최적화
+ 알람 시스템 개선
=== 과제 3: 사용성 테스트 실시
SUS 또는 NASA-TLX를 사용하여 HMI 사용성을 평가한다:
+ 테스트 계획 수립
+ 5명 이상 테스트
+ 결과 분석 및 개선안 도출
== 연습 문제
=== 문제 1: Fitts' Law 계산 (🌟 기초)
ETCH 장비의 긴급 정지 버튼을 설계한다. 운영자의 기본 위치는 화면 중앙 하단 (0, 0)이다.
*버튼 후보: *
- 후보 A: 위치 (200mm, 100mm), 크기 60mm
- 후보 B: 위치 (400mm, 50mm), 크기 40mm
- 경험적 상수: a = 100ms, b = 120ms/bit
*질문: *
1. 각 버튼까지의 거리 D 계산
2. 각 버튼의 Index of Difficulty (ID) 계산
3. 각 버튼의 예상 Movement Time (MT) 계산
4. 어느 버튼이 더 적합한가? 그 이유는?
*해답: *
#text(size: 9pt)[
```
후보 A:
- D = √(200² + 100²) = √50000 = 223.6mm
- ID = log₂(D/W + 1) = log₂(223.6/60 + 1) = log₂(4.73) = 2.24 bits
- MT = a + b×ID = 100 + 120×2.24 = 368.8ms
후보 B:
- D = √(400² + 50²) = √162500 = 403.1mm
- ID = log₂(403.1/40 + 1) = log₂(11.08) = 3.47 bits
- MT = a + b×ID = 100 + 120×3.47 = 516.4ms
결론: 후보 A가 147.6ms 더 빠르므로 긴급 상황에 적합하다.
```
]
=== 문제 2: Miller's Law 적용 (🌟🌟 중급)
CVD 장비의 메인 모니터링 화면을 설계한다. 다음 파라미터를 표시해야 한다: *필수 파라미터 (12개): *
- 챔버 온도 (상/중/하 3개 센서)
- 챔버 압력
- RF 파워 (Forward/Reflected)
- 가스 유량 (4개 채널)
- 공정 시간
- 웨이퍼 개수
*질문: *
1. Miller's Law (7±2)를 고려하여 정보를 그룹화하라
2. 각 그룹의 이름을 정하고 정당화하라
3. 어떤 정보를 메인 화면에, 어떤 정보를 서브 화면에 배치할지 결정하라
*해답 예시: *
#text(size: 9pt)[
```
그룹 1: 온도 시스템 (3개)
- 챔버 온도 상단, 중단, 하단
- 평균값으로 요약 표시 가능
그룹 2: 압력 및 파워 (3개)
- 챔버 압력
- RF Forward Power
- RF Reflected Power
그룹 3: 가스 시스템 (4개)
- 가스 유량 A, B, C, D
- 총 유량으로 요약 표시 가능
그룹 4: 공정 정보 (2개)
- 공정 시간
- 웨이퍼 개수
메인 화면 (7개):
- 평균 온도 (3개 센서의 평균)
- 압력
- 총 RF 파워
- 총 가스 유량
- 공정 시간
- 웨이퍼 개수
- 알람 상태
서브 화면:
- 온도 상세 (3개 센서 개별값 + 트렌드)
- RF 상세 (Forward/Reflected + 임피던스)
- 가스 상세 (4개 채널 개별값)
```
]
=== 문제 3: 신호탐지이론 (🌟🌟 중급)
PVD 장비의 압력 알람 시스템을 설계한다.
*조건: *
- 정상 압력: 3.0 ± 0.2 Torr (표준편차 σ = 0.2)
- Critical 알람: 3.5 Torr 이상
- Warning 알람: 3.3 Torr 이상
*질문: *
1. Critical 알람의 민감도 d' 계산
2. Warning 알람의 민감도 d' 계산
3. 각 알람의 d'가 충분한가? (d' ≥ 2.0 권장)
4. Warning 기준을 어떻게 조정하면 d' = 2.0을 달성할 수 있는가?
*해답: *
#text(size: 9pt)[
```
1. Critical 알람 d': d' = (μ_signal - μ_noise) / σ
   d' = (3.5 - 3.0) / 0.2 = 2.5
   → 우수한 구별 능력 (✓)
2. Warning 알람 d': d' = (3.3 - 3.0) / 0.2 = 1.5
   → 구별 능력이 다소 부족 (✗)
3. Warning 기준 조정: d' = 2.0을 달성하려면
   2.0 = (μ_warning - 3.0) / 0.2
   μ_warning = 3.0 + 2.0×0.2 = 3.4 Torr
   권장: Warning을 3.4 Torr로 상향 조정
```
]
=== 문제 4: 정보처리 모델 (🌟🌟🌟 고급)
반도체 HMI에서 알람 발생부터 운영자 조치까지의 프로세스를 분석한다.
*시나리오: *
1. 압력 센서가 이상값 감지 (t=0ms)
2. 화면에 빨간색 알람 표시 + 경고음 (t=?)
3. 운영자가 알람을 인지 (t=?)
4. 운영자가 상황을 판단 (t=?)
5. 운영자가 긴급 정지 버튼 클릭 (t=?)
6. 장비 정지 명령 전송 (t=?)
*질문: *
1. 각 단계의 예상 소요 시간을 정보처리 모델에 기반하여 추정하라
2. 전체 프로세스의 총 소요 시간을 계산하라
3. 850ms 목표를 달성하기 위해 어느 단계를 최적화해야 하는가?
*해답 예시: *
#text(size: 9pt)[
```
1. 센서 감지 → 알람 표시: 50ms (시스템 처리)
2. 알람 표시 → 운영자 인지: 250ms (감각 처리)
3. 인지 → 판단: 500ms (인지 처리)
4. 판단 → 버튼 클릭: 370ms (운동 반응, Fitts' Law)
5. 버튼 클릭 → 명령 전송: 50ms (시스템 처리)
총 소요 시간: 1220ms (목표 초과!)
최적화 방안:
- 판단 시간 단축 (500ms → 300ms): * 알람 메시지를 더 명확하게
  * 권장 조치 자동 제안
  * 컨텍스트 정보 즉시 표시
- 운동 반응 단축 (370ms → 250ms): * 긴급 정지 버튼을 더 크게 (60mm → 80mm)
  * 버튼을 더 가까이 (D=220mm → 150mm)
최적화 후: 50 + 250 + 300 + 250 + 50 = 900ms (여전히 약간 초과)
추가 최적화: 자동 긴급 정지 기능 (사용자 확인 필요 시)
```
]
=== 문제 5: SEMI E95 적용 (🌟🌟🌟🌟 도전)
새로운 반도체 장비의 HMI를 SEMI E95 표준에 맞게 설계하라.
*요구사항: *
- 3개의 공정 모드 (Idle, Running, Alarm)
- 5개의 주요 파라미터 모니터링
- 알람 시스템 (Critical/Warning/Info)
- 레시피 관리 기능
*질문: *
1. SEMI E95의 4가지 주요 원칙을 적용하여 화면 레이아웃을 설계하라
2. 색상 사용 가이드라인을 적용하라
3. 알람 우선순위 설정 (IEC 62682 고려)
4. 화면 설계를 간단한 스케치로 표현하라
*평가 기준: *
- SEMI E95 원칙 준수도
- 사용자 중심 설계
- 일관성 및 직관성
- 접근성 고려
== 추가 학습 자료

=== 공식 문서 및 표준

*HCI/HMI 표준*:
- *SEMI E95*: Specification for Operator Interface \
  https://www.semi.org/
- *ISO 9241-9*: Ergonomics of Human-System Interaction - Requirements for Non-keyboard Input Devices \
  https://www.iso.org/standard/30030.html
- *IEC 62682*: Management of Alarm Systems for the Process Industries \
  https://webstore.iec.ch/publication/7330

*동시성 프로그래밍 표준*:
- *POSIX Threads (pthread)* Programming Guide \
  https://pubs.opengroup.org/onlinepubs/9699919799/
- *C++ Concurrency* in Action (Anthony Williams) \
  https://www.manning.com/books/c-plus-plus-concurrency-in-action-second-edition

=== 참고 논문

*HCI 이론*:
- Fitts, P. M. (1954). "The information capacity of the human motor system in controlling the amplitude of movement". _Journal of Experimental Psychology_, 47(6), 381-391. \
  https://doi.org/10.1037/h0055392
- Miller, G. A. (1956). "The magical number seven, plus or minus two: Some limits on our capacity for processing information". _Psychological Review_, 63(2), 81-97. \
  https://doi.org/10.1037/h0043158
- Green, D. M., & Swets, J. A. (1966). _Signal Detection Theory and Psychophysics_. New York: Wiley. \
  https://psycnet.apa.org/record/1966-35014-000

*동시성 프로그래밍*:
- Coffman, E. G., Elphick, M., & Shoshani, A. (1971). "System deadlocks". _ACM Computing Surveys_, 3(2), 67-78. \
  https://doi.org/10.1145/356586.356588
- Sha, L., Rajkumar, R., & Lehoczky, J. P. (1990). "Priority inheritance protocols: An approach to real-time synchronization". _IEEE Transactions on Computers_, 39(9), 1175-1185. \
  https://doi.org/10.1109/12.57058

=== 온라인 자료

*HCI 커뮤니티*:
- ACM CHI Conference (Human-Computer Interaction) \
  https://chi.acm.org/
- Nielsen Norman Group (UX Research & Usability) \
  https://www.nngroup.com/
- Human Factors and Ergonomics Society \
  https://www.hfes.org/

*동시성 프로그래밍*:
- The Little Book of Semaphores (Allen B. Downey) \
  https://greenteapress.com/wp/semaphores/
- Concurrent Programming in Java (Doug Lea) \
  https://gee.cs.oswego.edu/dl/cpj/
- Linux Kernel Documentation - Real-Time \
  https://www.kernel.org/doc/html/latest/scheduler/sched-rt-group.html
- Microsoft Docs - Threading for C\# \
  https://learn.microsoft.com/en-us/dotnet/standard/threading/
- Python Threading Documentation \
  https://docs.python.org/3/library/threading.html

*실시간 시스템*:
- PREEMPT_RT Linux Kernel Patch \
  https://wiki.linuxfoundation.org/realtime/start
- VxWorks Real-Time Operating System \
  https://www.windriver.com/products/vxworks
- QNX Neutrino RTOS \
  https://www.qnx.com/

*반도체 HMI*:
- SEMI Standards Store \
  https://store.semi.org/
- SEMATECH (Semiconductor Manufacturing Technology) \
  https://www.sematech.org/
== 요약
이번 챕터에서는 HCI 이론의 기초, 동시성 프로그래밍, 반도체 HMI에의 적용을 학습했다:
*이론 (Theory): *
- HCI 학문의 역사: 1954년 Fitts' Law부터 현대 터치 인터페이스까지
- Miller's Law: 정보 표시 개수 제한 (7±2개)
- Fitts' Law: 버튼 크기와 위치 최적화 (ID 최소화)
- 정보처리 모델: 850ms 이내 응답 (감각-인지-운동)
- 신호탐지이론: False Alarm 최소화 (d' ≥ 2.0)
- 반도체 HMI 산업 동향: SEMI 표준, 주요 장비사 전략, AI/ML 통합

*동시성 프로그래밍 (Concurrency): *
- 동시성 vs 병렬성: Time-slicing vs 실제 동시 실행
- 멀티스레딩 vs 멀티프로세싱: 공유 메모리 vs 독립 메모리
- 운영체제별 차이: Windows (MMCSS) vs Linux (PREEMPT_RT)
- Locking Mechanism: Mutex, Semaphore, Monitor, Read-Write Lock
- Deadlock 방지: Coffman의 4대 조건, Lock Ordering
- Priority Inversion 해결: Priority Inheritance/Ceiling
- 실시간 시스템: Hard Real-time (< 1ms) vs Soft Real-time (< 100ms)
- 동시성 패턴: Producer-Consumer, Reader-Writer, Thread Pool, Active Object

*응용 (Application): *
- Python 기반 Fitts' Law 계산기 (실행 가능한 코드)
- SDT 시뮬레이션 도구 (NumPy 기반)
- Race Condition 재현 및 해결 실습 (Mutex, Atomic Operation)
- 실제 반도체 장비 HMI 사례 분석

*성찰 (Reflections): *
- HCI MCQ 10문제: 개념, 코드 분석, 응용 문제
- 동시성 MCQ 10문제: 동시성/병렬성, Deadlock, Priority Inversion
- 5개 난이도별 연습 문제 (🌟 ~ 🌟🌟🌟🌟)

*핵심 포인트: *
1. 모든 HCI 법칙은 수학적으로 검증 가능하고 실험적으로 증명되었다
2. 반도체 HMI는 일반 UI보다 10배 엄격한 기준을 요구한다 (10ms-100ms 응답)
3. 동시성은 반도체 HMI의 필수 요구사항이다 (센서 수집 + UI 렌더링 동시 처리)
4. Race Condition, Deadlock, Priority Inversion은 실제 위험 요소이다
5. 운영체제별 실시간 특성 이해가 중요하다 (Windows vs Linux)
6. 표준 준수는 필수이며 사용자 안전과 직결된다 (SEMI E95, IEC 62682)
7. Python 코드를 통해 이론을 실습하고 검증할 수 있다

다음 챕터에서는 C\# WPF를 사용한 실제 HMI 개발을 시작하며, MVVM 패턴과 멀티스레딩(Task, async/await)을 적용하여 반도체 장비 모니터링 시스템을 구축한다.
#pagebreak()