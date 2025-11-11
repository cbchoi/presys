= Week 8: Python 고급 UI 및 차트
== 학습 목표
본 챕터에서는 다음을 학습한다: + 2D 그래픽 라이브러리 비교 (Matplotlib, PyQtGraph, Plotly)
+ OpenGL 기초 및 하드웨어 가속
+ 디자인 패턴 적용 (Observer, Strategy, Flyweight)
+ PyQtGraph를 사용한 고급 실시간 차트
== 사전 요구 사항
본 챕터를 학습하기 위해 다음 지식이 필요한다: - *PySide6 기초*: Week 6에서 학습한 Qt 위젯, Signal/Slot
- *NumPy 기초*: 배열 연산, 브로드캐스팅, 인덱싱
- *Python 동시성*: Week 7에서 학습한 QThread, Signal
- *선형대수 기초*: 행렬, 벡터 개념 (OpenGL 이해를 위해)
- *권장사항*: Week 7 실시간 데이터 처리 학습 완료
== 2D 그래픽 라이브러리 비교
=== Matplotlib
==== 개요
Matplotlib은 MATLAB 스타일의 플로팅 인터페이스를 제공하는 Python 표준 시각화 라이브러리이다.
*역사: *
- 2003년 John D. Hunter가 개발 시작
- 과학 출판물 품질의 정적 그래픽 생성에 초점
- NumPy, SciPy 생태계와 긴밀히 통합
*장점: *
- 고품질 출판용 그래픽
- 다양한 플롯 타입 (수백 종류)
- 광범위한 커뮤니티 및 문서
- MATLAB 사용자에게 친숙
*단점: *
- 실시간 업데이트 성능 낮음
- 인터랙티브 기능 제한적
- API가 복잡함 (pyplot vs OOP 인터페이스)
==== 사용 사례
```python
import matplotlib.pyplot as plt
import numpy as np
# 정적 플롯
x = np.linspace(0, 10, 100)
y = np.sin(x)
plt.plot(x, y)
plt.xlabel('Time (s)')
plt.ylabel('Amplitude')
plt.title('Sine Wave')
plt.grid(True)
plt.show()
```
=== PyQtGraph
==== 개요
PyQtGraph는 빠른 실시간 데이터 시각화를 위해 설계된 라이브러리이다.
*역사: *
- 2010년 Luke Campagnola 개발
- Qt 기반 (PyQt/PySide)
- 과학 계측 및 실시간 모니터링에 최적화
*장점: *
- 매우 빠른 실시간 업데이트 (1000+ Hz 가능)
- Qt와 네이티브 통합
- OpenGL 하드웨어 가속 지원
- 적은 메모리 사용
*단점: *
- Matplotlib보다 플롯 타입 적음
- 출판 품질은 Matplotlib보다 낮음
- 학습 자료가 상대적으로 적음
==== 사용 사례
```python
import pyqtgraph as pg
import numpy as np
# 실시간 플롯
plot = pg.plot()
curve = plot.plot(pen='r')
def update(): data = np.random.normal(size=100)
    curve.setData(data)
timer = pg.QtCore.QTimer()
timer.timeout.connect(update)
timer.start(50)  # 50ms = 20 FPS
```
=== Plotly
==== 개요
Plotly는 인터랙티브 웹 기반 시각화 라이브러리이다.
*역사: *
- 2012년 Plotly Technologies 설립
- D3.js 기반 (JavaScript)
- 대시보드 및 웹 애플리케이션에 최적화
*장점: *
- 아름다운 인터랙티브 그래픽
- 웹 브라우저에서 실행 (크로스 플랫폼)
- Dash 프레임워크로 대시보드 구축 용이
- 클라우드 호스팅 지원
*단점: *
- 실시간 성능이 PyQtGraph보다 낮음
- 웹 기반이라 오프라인 환경에서 제한적
- 큰 데이터셋 처리 시 느림
==== 사용 사례
```python
import plotly.graph_objects as go
fig = go.Figure(data=go.Scatter(x=[1, 2, 3], y=[4, 1, 2]))
fig.update_layout(title='Interactive Plot')
fig.show()  # 웹 브라우저에서 열림
```
=== 라이브러리 비교표
#figure(table(columns: (auto, auto, auto, auto, auto), align: left, [*라이브러리*], [*실시간 성능*], [*출판 품질*], [*인터랙티브*], [*반도체 HMI 적합도*], [Matplotlib], [낮음], [매우 높음], [낮음], [정적 보고서용], [PyQtGraph], [매우 높음], [보통], [높음], [실시간 모니터링 (권장)], [Plotly], [보통], [높음], [매우 높음], [웹 대시보드용], ), caption: "2D 그래픽 라이브러리 비교")
*반도체 HMI 권장: *
- 실시간 공정 모니터링: PyQtGraph (최우선)
- 데이터 분석 및 보고서: Matplotlib
- 원격 웹 대시보드: Plotly + Dash
== 2D 렌더링 이론적 기반
=== Vector vs Raster 그래픽
==== Vector Graphics (벡터 그래픽)
벡터 그래픽은 수학적 표현 (선, 곡선, 다각형)으로 이미지를 정의한다.
*수학적 표현 예시: *
```
선분: P₁(x₁, y₁) → P₂(x₂, y₂)
원: (x - cx)² + (y - cy)² = r²
베지어 곡선: B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
```
*장점: *
- 무손실 확대/축소 (해상도 독립적)
- 작은 파일 크기 (단순한 도형의 경우)
- 수정 용이 (개별 객체 조작)
*단점: *
- 복잡한 이미지 표현 어려움 (사진 등)
- 렌더링 시 계산 오버헤드
*반도체 HMI 응용: *
- 공정 다이어그램, 플로우차트
- 계측기 게이지, 차트 축/그리드
- UI 아이콘, 버튼
==== Raster Graphics (래스터 그래픽)
래스터 그래픽은 픽셀 배열로 이미지를 저장한다.
*데이터 구조: *
```python
# RGB 이미지 (width × height × 3)
image = np.array([
    [[255, 0, 0], [0, 255, 0], [0, 0, 255]], # 행 1
    [[255, 255, 0], [0, 255, 255], [255, 0, 255]], # 행 2
], dtype=np.uint8)
# shape: (2, 3, 3) = 2행 × 3열 × RGB
```
*장점: *
- 복잡한 이미지 표현 가능 (사진, 텍스처)
- 렌더링 빠름 (단순 픽셀 복사)
- 하드웨어 가속 용이 (GPU 텍스처)
*단점: *
- 확대 시 품질 저하 (픽셀화)
- 큰 파일 크기
- 수정 어려움 (픽셀 단위 편집)
*반도체 HMI 응용: *
- 히트맵, 온도 분포도
- 카메라 영상 (웨이퍼 검사)
- 실시간 차트 렌더링 (픽셀 버퍼)
==== 성능 비교
#figure(table(columns: (auto, auto, auto, auto), align: left, [*작업*], [*Vector*], [*Raster*], [*반도체 HMI 권장*], [차트 선 그리기], [느림 (계산)], [빠름 (픽셀 쓰기)], [Raster (실시간)], [확대/축소], [품질 유지], [품질 저하], [Vector (다이어그램)], [복잡한 텍스처], [불가능], [가능], [Raster (영상)], [메모리 사용], [적음 (단순 도형)], [많음 (해상도 비례)], [-], ), caption: "Vector vs Raster 성능 비교")
*하이브리드 접근: *
반도체 HMI는 두 방식을 혼합한다: ```
Vector: UI 레이아웃, 차트 축, 그리드
  +
Raster: 차트 데이터 포인트, 히트맵
  ↓
최종 렌더링: GPU 합성
```
=== Anti-Aliasing (안티에일리어싱)
==== Aliasing 문제
디지털 신호 처리에서 샘플링 주파수가 부족할 때 발생하는 왜곡 현상이다.
*Nyquist-Shannon Sampling Theorem (1949): *
```
신호를 완벽히 복원하려면:
샘플링 주파수 f_s ≥ 2 × f_max (최대 주파수)
```
그래픽에서는 픽셀 격자가 "샘플링"에 해당한다. 대각선이나 곡선은 계단 현상 (jaggies)이 발생한다.
*예시: *
```
Aliased (계단 현상): ████
  ████
  ████
Anti-Aliased (부드러움): ████
  ░░████
  ░░████
```
==== Anti-Aliasing 알고리즘
*1. Supersampling Anti-Aliasing (SSAA)*
고해상도 렌더링 후 다운샘플링한다.
```python
# 4× SSAA
high_res = render(width * 2, height * 2) # 4배 해상도
final = downscale(high_res, (width, height)) # 평균
```
성능: 매우 느림 (4×SSAA는 16배 픽셀)
*2. Multisample Anti-Aliasing (MSAA)*
픽셀 경계에서만 다중 샘플링한다.
```
일반 픽셀: 1 샘플
경계 픽셀: 4 샘플 (코너)
```
성능: SSAA보다 빠름, OpenGL 하드웨어 지원
*3. Fast Approximate Anti-Aliasing (FXAA)*
후처리 셰이더로 계단 감지 후 블러 적용한다.
```glsl
// FXAA pseudo-code
float edge = detect_edge(pixel);
if (edge > threshold) {
  color = blur(pixel);
}
```
성능: 매우 빠름, 품질은 MSAA보다 낮음
*4. Subpixel Rendering*
LCD 서브픽셀 (R, G, B)을 개별 제어한다.
```
픽셀: [R|G|B][R|G|B][R|G|B]
  ↑ 각각 독립적으로 제어 (해상도 3배)
```
*반도체 HMI 권장: *
```python
# PyQtGraph에서 안티에일리어싱 활성화
pg.setConfigOptions(antialias=True)
# PlotItem별 설정
curve = plot.plot(x, y, antialias=True)
```
성능 영향: 약 10-20% 감소, 하지만 시각적 품질 크게 향상
=== Compositing (합성)
==== Porter-Duff Compositing (1984)
Thomas Porter와 Tom Duff가 개발한 알파 블렌딩 모델이다.
*기본 연산: *
```
최종 색상 = Source 색상 × α_s + Destination 색상 × α_d × (1 - α_s)
α: 투명도 (0 = 완전 투명, 1 = 불투명)
```
*12가지 연산 모드: *
#figure(table(columns: (auto, auto, auto), align: left, [*모드*], [*수식*], [*용도*], [Clear], [0], [영역 지우기], [Source], [A], [덮어쓰기], [Destination], [B], [기존 유지], [Source Over], [A + B(1-αA)], [일반 그리기 (기본)], [Destination Over], [B + A(1-αB)], [배경에 그리기], [Source In], [A × αB], [마스크], [Destination In], [B × αA], [역마스크], [Source Out], [A × (1-αB)], [차집합], [Source Atop], [A×αB + B×(1-αA)], [전경 제한], [XOR], [A×(1-αB) + B×(1-αA)], [배타적 OR], ), caption: "Porter-Duff Compositing 모드")
*Python 예시: *
```python
from PIL import Image, ImageDraw
# Source Over 합성
base = Image.open('background.png').convert('RGBA')
overlay = Image.open('chart.png').convert('RGBA')
# Alpha blending
result = Image.alpha_composite(base, overlay)
```
==== Blend Modes (블렌드 모드)
Photoshop 스타일의 블렌드 모드이다.
*1. Multiply (곱하기): *
```
C_out = C_s × C_d
용도: 그림자, 어둡게 하기
예: (0.8, 0.5, 0.2) × (0.6, 0.7, 0.9) = (0.48, 0.35, 0.18)
```
*2. Screen (스크린): *
```
C_out = 1 - (1 - C_s) × (1 - C_d)
용도: 빛, 밝게 하기
```
*3. Overlay (오버레이): *
```
C_out = {
  2 × C_s × C_d, if C_d < 0.5
  1 - 2(1-C_s)(1-C_d), otherwise
}
용도: 대비 강조
```
*반도체 HMI 응용: *
```python
import pyqtgraph as pg
from PySide6.QtGui import QPainter
# QPainter 블렌드 모드
painter = QPainter()
painter.setCompositionMode(QPainter.CompositionMode_Multiply)
painter.drawImage(0, 0, overlay_image)
```
=== 좌표계 변환
==== 2D Affine Transformation (어파인 변환)
선형 변환 + 이동을 포함하는 변환이다.
*행렬 표현: *
```
┌ x' ┐ ┌ a b  tx ┐ ┌ x ┐
│ y' │ = │ c d  ty │ │ y │
└ 1 ┘  └ 0 0  1 ┘ └ 1 ┘
[x', y', 1]^T = Affine Matrix × [x, y, 1]^T
```
*기본 변환: *
*1. Translation (이동): *
```
┌ 1 0  tx ┐
│ 0 1  ty │
└ 0 0  1 ┘
예: tx=10, ty=20 → (5, 5) 이동 후 (15, 25)
```
*2. Scaling (크기 조절): *
```
┌ sx 0  0 ┐
│ 0 sy 0 │
└ 0 0  1 ┘
예: sx=2, sy=0.5 → (10, 20) 변환 후 (20, 10)
```
*3. Rotation (회전): *
```
┌ cos(θ) -sin(θ) 0 ┐
│ sin(θ) cos(θ) 0 │
└ 0 0  1 ┘
예: θ=90° → (1, 0) 회전 후 (0, 1)
```
*4. Shearing (기울이기): *
```
┌ 1 shx 0 ┐
│shy 1  0 │
└ 0 0  1 ┘
```
*변환 합성: *
```python
import numpy as np
# Translation
T = np.array([[1, 0, 100], [0, 1, 50], [0, 0, 1]])
# Rotation (45°)
θ = np.pi / 4
R = np.array([[np.cos(θ), -np.sin(θ), 0], [np.sin(θ), np.cos(θ), 0], [0, 0, 1]])
# Scaling
S = np.array([[2, 0, 0], [0, 2, 0], [0, 0, 1]])
# 합성 (순서 중요!): Scale → Rotate → Translate
M = T @ R @ S
# 점 변환
point = np.array([10, 20, 1])
transformed = M @ point
print(transformed[: 2]) # [x', y']
```
*주의사항: *
```
변환 순서가 중요하다!
회전 후 이동 ≠ 이동 후 회전
┌───┐ 회전 ┌─┐ 이동 ┌─┐
│ A │ ───────→ │A│ ─────→ │A│
└───┘ └─┘ └─┘
  ↑ 다른 위치
┌───┐ 이동 ┌───┐ 회전 ┌─┐
│ A │ ───────→ │ A │ ─────→ │A│
└───┘ └───┘ └─┘
  ↑ 다른 위치
```
*PyQtGraph 응용: *
```python
# ViewBox 변환 설정
viewbox = plot.getViewBox()
viewbox.setRange(xRange=[0, 100], yRange=[-50, 50])
viewbox.setAspectLocked(True) # 종횡비 고정
```
== Graphics Library 아키텍처 비교
=== Matplotlib 아키텍처
==== 3-Layer Architecture
```
┌─────────────────────────────────────┐
│ Scripting Layer (pyplot) │  ← 사용자 API
│ plt.plot(), plt.xlabel(), ... │
└────────────────┬────────────────────┘
  │
┌────────────────▼────────────────────┐
│ Artist Layer │  ← 객체 지향 API
│ Figure, Axes, Line2D, Text, ... │
│ (모든 그래픽 요소는 Artist) │
└────────────────┬────────────────────┘
  │
┌────────────────▼────────────────────┐
│ Backend Layer │  ← 렌더링 엔진
│ Agg (PNG), PDF, SVG, Qt, GTK, ...│
└─────────────────────────────────────┘
```
*Artist 계층 구조: *
```python
from matplotlib import pyplot as plt
import matplotlib.patches as mpatches
fig, ax = plt.subplots()
# Figure (최상위 Artist)
# └─ Axes (플롯 영역 Artist)
# ├─ Line2D (선 Artist)
# ├─ Text (텍스트 Artist)
# └─ Patch (도형 Artist)
line, = ax.plot([1, 2, 3], [4, 5, 6]) # Line2D Artist
text = ax.text(2, 5, 'Label') # Text Artist
rect = mpatches.Rectangle((1, 4), 1, 1) # Patch Artist
ax.add_patch(rect)
# 모든 Artist는 draw() 메서드 가짐
for artist in ax.get_children(): print(type(artist), artist.get_visible())
```
*렌더링 과정: *
```
1. plt.plot(x, y)
  ↓
2. Axes.plot() → Line2D 객체 생성
  ↓
3. Figure.canvas.draw()
  ↓
4. Axes.draw(renderer) → 모든 자식 Artist 순회
  ↓
5. Line2D.draw(renderer) → Backend에 렌더링 명령
  ↓
6. Backend (Agg) → 픽셀 버퍼 생성
  ↓
7. GUI Toolkit (Qt) → 화면 표시
```
*성능 병목: *
```python
import time
import numpy as np
import matplotlib.pyplot as plt
x = np.arange(10000)
y = np.sin(x / 100)
fig, ax = plt.subplots()
line, = ax.plot(x, y)
# ❌ 느림: 전체 Figure 재렌더링
for i in range(100): start = time.time()
  y = np.sin(x / 100 + i * 0.1)
  line.set_ydata(y)
  fig.canvas.draw() # 전체 재렌더링 (~50ms)
  fig.canvas.flush_events()
  print(f"Frame time: {(time.time() - start) * 1000: .2f}ms")
# ✓ 빠름: Blit (Bit Block Transfer) 사용
# (하지만 여전히 PyQtGraph보다 느림)
```
=== PyQtGraph 아키텍처
==== Qt Graphics View Framework 기반
```
┌────────────────────────────────────────┐
│ Application │
└───────────────┬────────────────────────┘
  │
┌───────────────▼────────────────────────┐
│ PlotWidget (QGraphicsView) │  ← 뷰포트
│ - 줌, 팬, 이벤트 처리 │
└───────────────┬────────────────────────┘
  │
┌───────────────▼────────────────────────┐
│ PlotItem (QGraphicsItem) │  ← 플롯 컨테이너
│ - ViewBox, AxisItem, LegendItem │
└───────────────┬────────────────────────┘
  │
┌───────────────▼────────────────────────┐
│ PlotCurveItem (QGraphicsItem) │  ← 데이터 아이템
│ - 선, 점 렌더링 │
│ - NumPy 배열 직접 사용 │
└───────────────┬────────────────────────┘
  │
┌───────────────▼────────────────────────┐
│ QPainter (렌더링) 또는 OpenGL │  ← 백엔드
└────────────────────────────────────────┘
```
*Qt Graphics Scene 모델: *
```python
# QGraphicsScene: 논리적 씬 (무한 좌표계)
# │
# ├─ QGraphicsView: 물리적 뷰 (위젯)
# │  └─ ViewBox: 좌표 변환 (데이터 → 화면)
# │
# └─ QGraphicsItems: 그래픽 객체들
# ├─ AxisItem (축)
# ├─ PlotCurveItem (선)
# └─ ScatterPlotItem (점)
```
*좌표 변환 체인: *
```
데이터 좌표 (Data Coordinates)
  ↓ ViewBox.mapToView()
씬 좌표 (Scene Coordinates)
  ↓ QGraphicsView.mapFromScene()
뷰 좌표 (View Coordinates, 픽셀)
  ↓ QWidget.mapToGlobal()
글로벌 좌표 (Screen Coordinates)
```
*최적화 전략: *
```python
# 1. NumPy 배열 직접 사용 (복사 최소화)
x = np.arange(100000)
y = np.sin(x / 1000)
curve.setData(x, y) # ✓ NumPy 배열 직접 참조
# 2. 자동 다운샘플링
curve.setDownsampling(auto=True, method='peak')
# 3. 클리핑
curve.setClipToView(True) # 뷰 밖 데이터 렌더링 안 함
# 4. OpenGL 가속
pg.setConfigOptions(useOpenGL=True)
```
*렌더링 성능 비교: *
#figure(table(columns: (auto, auto, auto, auto), align: left, [*데이터 포인트*], [*Matplotlib*], [*PyQtGraph (QPainter)*], [*PyQtGraph (OpenGL)*], [1, 000], [~5ms], [~1ms], [~0.5ms], [10, 000], [~50ms], [~5ms], [~1ms], [100, 000], [~500ms], [~50ms], [~5ms], [1, 000, 000], [~5s (불가능)], [~500ms], [~50ms], ), caption: "프레임당 렌더링 시간 비교 (Intel i7, NVIDIA GTX)")
=== Cairo vs Skia vs OpenGL 비교
==== Cairo Graphics
*역사: *
- 2003년 Keith Packard, Carl Worth 개발
- GTK+, Firefox, Inkscape에서 사용
- 2D 벡터 그래픽 라이브러리
*아키텍처: *
```
Cairo API
  │
  ├─ 백엔드 선택
  │  ├─ Image (메모리)
  │  ├─ PDF
  │  ├─ SVG
  │  ├─ PostScript
  │  └─ X11/Win32
  │
  └─ 렌더링 파이프라인
  ├─ Path (경로 구축)
  ├─ Fill/Stroke (채우기/선)
  └─ Rasterization (픽셀화)
```
*Python 예시: *
```python
import cairo
# Image surface 생성
surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 800, 600)
ctx = cairo.Context(surface)
# 베지어 곡선 그리기
ctx.move_to(50, 50)
ctx.curve_to(100, 100, 200, 100, 250, 50)
ctx.set_source_rgb(1, 0, 0)
ctx.set_line_width(5)
ctx.stroke()
surface.write_to_png('output.png')
```
*성능 특성: *
- 벡터 그래픽에 최적화
- CPU 렌더링 (소프트웨어)
- Anti-aliasing 품질 우수
- 실시간 차트에는 부적합
==== Skia Graphics
*역사: *
- 2005년 Skia Inc. 개발, 2005년 Google 인수
- Chrome, Android, Flutter에서 사용
- 하드웨어 가속 지원 (OpenGL, Vulkan, Metal)
*아키텍처: *
```
Skia API (SkCanvas, SkPaint, SkPath)
  │
  ├─ GPU Backend
  │  ├─ OpenGL
  │  ├─ Vulkan
  │  └─ Metal
  │
  └─ CPU Backend
  └─ Rasterizer
```
*특징: *
- 2D + 일부 3D 효과 (그림자, 블러)
- GPU 가속으로 매우 빠름
- Cross-platform (Windows, Linux, macOS, Android, iOS)
- Python 바인딩: `skia-python`
*성능: *
```
벤치마크 (1000×1000 캔버스, 1000개 원 그리기):
- Cairo (CPU): ~80ms
- Skia (CPU): ~50ms
- Skia (GPU): ~5ms
```
==== OpenGL
*역사: *
- 1992년 Silicon Graphics 개발
- 3D 그래픽 표준 API
- 거의 모든 플랫폼 지원
*렌더링 파이프라인 (상세): *
```
┌──────────────────────────────────────────┐
│ 1. Vertex Specification │
│ - 정점 데이터 (위치, 색상, 텍스처 좌표) │
└─────────────┬────────────────────────────┘
  │
┌─────────────▼────────────────────────────┐
│ 2. Vertex Shader (GPU 프로그램) │
│ - 정점 변환 (Model → World → View → │
│ Clip → NDC) │
│ - gl_Position = MVP × vertex │
└─────────────┬────────────────────────────┘
  │
┌─────────────▼────────────────────────────┐
│ 3. Primitive Assembly │
│ - 정점을 삼각형/선으로 조립 │
└─────────────┬────────────────────────────┘
  │
┌─────────────▼────────────────────────────┐
│ 4. Rasterization │
│ - 삼각형을 픽셀(프래그먼트)로 변환 │
│ - 보간 (색상, 텍스처 좌표) │
└─────────────┬────────────────────────────┘
  │
┌─────────────▼────────────────────────────┐
│ 5. Fragment Shader (GPU 프로그램) │
│ - 픽셀 색상 계산 │
│ - gl_FragColor = texture(sampler, uv) │
└─────────────┬────────────────────────────┘
  │
┌─────────────▼────────────────────────────┐
│ 6. Per-Fragment Operations │
│ - Depth Test (깊이 테스트) │
│ - Stencil Test (스텐실 테스트) │
│ - Blending (알파 블렌딩) │
└─────────────┬────────────────────────────┘
  │
┌─────────────▼────────────────────────────┐
│ 7. Framebuffer │
│ - 최종 이미지 (Color + Depth + Stencil)│
└──────────────────────────────────────────┘
```
*좌표계 변환 상세: *
```
Model Space (물체 좌표계)
  │ Model Matrix (M)
  ↓
World Space (세계 좌표계)
  │ View Matrix (V)
  ↓
View Space (카메라 좌표계)
  │ Projection Matrix (P)
  ↓
Clip Space (클립 좌표계, -w ≤ x, y, z ≤ w)
  │ Perspective Division (÷ w)
  ↓
Normalized Device Coordinates (NDC, -1 ≤ x, y, z ≤ 1)
  │ Viewport Transform
  ↓
Screen Space (화면 픽셀 좌표)
```
*셰이더 예시: *
```glsl
// Vertex Shader
#version 330 core
layout (location = 0) in vec3 aPos; // 정점 위치
layout (location = 1) in vec3 aColor; // 정점 색상
uniform mat4 MVP; // Model-View-Projection Matrix
out vec3 vertexColor; // Fragment Shader로 전달
void main()
{
  gl_Position = MVP * vec4(aPos, 1.0);
  vertexColor = aColor;
}
// Fragment Shader
#version 330 core
in vec3 vertexColor; // Vertex Shader로부터 받음
out vec4 FragColor; // 최종 색상
void main()
{
  FragColor = vec4(vertexColor, 1.0);
}
```
==== 성능 및 용도 비교
#figure(table(columns: (auto, auto, auto, auto, auto), align: left, [*라이브러리*], [*렌더링*], [*성능*], [*복잡도*], [*반도체 HMI 용도*], [Cairo], [CPU (소프트웨어)], [느림], [낮음], [정적 보고서, PDF 생성], [Skia], [GPU/CPU], [빠름], [중간], [고품질 UI, 애니메이션], [OpenGL], [GPU (하드웨어)], [매우 빠름], [높음], [실시간 3D, 대량 데이터], [PyQtGraph], [Qt (QPainter/OpenGL)], [빠름], [낮음], [실시간 2D 차트 (권장)], ), caption: "Graphics Library 비교")
*PyQtGraph의 선택: *
PyQtGraph는 기본적으로 Qt의 QPainter (CPU)를 사용하지만, `useOpenGL=True`로 OpenGL 백엔드를 활성화할 수 있다.
```python
# CPU 렌더링 (기본)
pg.setConfigOptions(useOpenGL=False)
# 장점: 안정적, 드라이버 의존성 없음
# 단점: 대량 데이터 느림
# GPU 렌더링 (고성능)
pg.setConfigOptions(useOpenGL=True, enableExperimental=True)
# 장점: 대량 데이터 빠름 (10-100배)
# 단점: 드라이버 버그 가능, 가상 머신 제한
```
*벤치마크 (100만 포인트 선 그리기): *
```
Cairo: ~5000ms (불가능)
Skia (CPU): ~800ms
Skia (GPU): ~50ms
OpenGL: ~10ms
PyQtGraph (QPainter): ~500ms
PyQtGraph (OpenGL): ~15ms ← 반도체 HMI 권장
```
== Custom Widget 아키텍처 이론
=== Qt Paint System
==== Paint Event 메커니즘
Qt의 모든 위젯 렌더링은 `paintEvent()`를 통해 이루어진다.
*이벤트 흐름: *
```
1. 위젯 상태 변경 (데이터 업데이트, 크기 변경 등)
  ↓
2. QWidget.update() 호출
  ↓
3. Qt Event Loop: Paint 이벤트 큐에 추가
  ↓
4. 이벤트 루프에서 Paint 이벤트 처리
  ↓
5. QWidget.paintEvent(QPaintEvent) 호출
  ↓
6. QPainter로 렌더링
  ↓
7. 화면 업데이트 (Swap Buffers)
```
*주의사항: *
```python
# ❌ 잘못된 사용
def on_data_update(self): self.data = new_data
  self.paintEvent(None) # 직접 호출 ❌
# ✓ 올바른 사용
def on_data_update(self): self.data = new_data
  self.update() # Qt에게 다시 그려달라고 요청 ✓
```
*이유: *
- `paintEvent()`는 Qt 내부에서만 호출되어야 한다
- 직접 호출 시 QPainter 상태가 올바르지 않을 수 있다
- `update()`는 여러 번 호출해도 하나의 Paint 이벤트로 합쳐진다 (Coalescing)
==== QPainter 렌더링 파이프라인
```python
from PySide6.QtWidgets import QWidget
from PySide6.QtGui import QPainter, QPen, QBrush, QColor
from PySide6.QtCore import Qt, QRect, QPoint
class CustomGauge(QWidget): """커스텀 게이지 위젯"""
  def __init__(self): super().__init__()
  self._value = 0.0 # 0.0 ~ 1.0
  def paintEvent(self, event): """Paint 이벤트 핸들러"""
  painter = QPainter(self)
  # 1. 렌더링 힌트 설정
  painter.setRenderHint(QPainter.Antialiasing)
  painter.setRenderHint(QPainter.TextAntialiasing)
  # 2. 배경 그리기
  painter.setBrush(QBrush(QColor(240, 240, 240)))
  painter.setPen(Qt.NoPen)
  painter.drawRect(self.rect())
  # 3. 게이지 바 그리기
  bar_width = int(self.width() * self._value)
  bar_rect = QRect(0, 0, bar_width, self.height())
  # 그라디언트 색상
  if self._value < 0.5: color = QColor(46, 204, 113) # 녹색
  elif self._value < 0.8: color = QColor(241, 196, 15) # 노란색
  else: color = QColor(231, 76, 60) # 빨간색
  painter.setBrush(QBrush(color))
  painter.drawRect(bar_rect)
  # 4. 텍스트 그리기
  painter.setPen(QPen(QColor(0, 0, 0)))
  text = f"{self._value * 100: .1f}%"
  painter.drawText(self.rect(), Qt.AlignCenter, text)
  def setValue(self, value): """값 설정 (0.0 ~ 1.0)"""
  self._value = max(0.0, min(1.0, value))
  self.update() # 다시 그리기 요청
```
*QPainter 상태 관리: *
```python
def paintEvent(self, event): painter = QPainter(self)
  # 상태 저장
  painter.save()
  # 변환 적용
  painter.translate(100, 100)
  painter.rotate(45)
  painter.scale(2.0, 2.0)
  # 그리기
  painter.drawRect(0, 0, 50, 50)
  # 상태 복원 (변환 초기화)
  painter.restore()
  # 원래 좌표계로 그리기
  painter.drawLine(0, 0, 200, 200)
```
==== Coordinate System (좌표계)
*Qt 좌표계: *
```
┌──────────────────────────→ x (오른쪽)
│ (0, 0)
│ ┌──────────┐
│ │ Widget │
│ │  │
│ └──────────┘
↓
y (아래)
```
*변환 함수: *
```python
# 이동
painter.translate(dx, dy)
# 회전 (도 단위, 시계 방향)
painter.rotate(angle)
# 크기 조절
painter.scale(sx, sy)
# 기울이기
painter.shear(sh, sv)
# 직접 행렬 설정
from PySide6.QtGui import QTransform
transform = QTransform()
transform.rotate(45)
transform.translate(100, 100)
painter.setTransform(transform)
```
*좌표 매핑: *
```python
# 위젯 좌표 → 글로벌 좌표
global_pos = widget.mapToGlobal(QPoint(10, 10))
# 글로벌 좌표 → 위젯 좌표
widget_pos = widget.mapFromGlobal(global_pos)
# 부모 좌표 → 자식 좌표
child_pos = child.mapFromParent(QPoint(50, 50))
```
=== Double Buffering (이중 버퍼링)
==== Flicker 문제
단일 버퍼에서 직접 렌더링하면 깜빡임 (flicker)이 발생한다.
*원인: *
```
Time 0: 화면에 이전 프레임 표시 중
  ↓
Time 1: 새 프레임 렌더링 시작 (화면에 부분적으로 그려짐)
  ↓ ← 사용자가 부분 렌더링을 봄 (깜빡임!)
Time 2: 새 프레임 렌더링 완료
  ↓
Time 3: 화면 표시
```
==== Double Buffering 해결책
백 버퍼(off-screen)에 렌더링 후 완성된 이미지를 프론트 버퍼로 교체한다.
*구조: *
```
┌─────────────────┐ 렌더링 ┌─────────────────┐
│ Front Buffer │ ←──────────── │ Back Buffer │
│ (화면 표시 중) │ │  (렌더링 중) │
└─────────────────┘ └─────────────────┘
  ↑  │
  └───── Swap Buffers ───────────────┘
  (포인터 교환, 매우 빠름)
```
*Qt에서 자동 지원: *
Qt는 기본적으로 Double Buffering을 사용한다.
```python
class MyWidget(QWidget): def __init__(self): super().__init__()
  # Qt는 자동으로 백 버퍼 생성
  # paintEvent()는 백 버퍼에 렌더링됨
  def paintEvent(self, event): painter = QPainter(self) # 백 버퍼에 렌더링
  painter.drawLine(0, 0, 100, 100)
  # paintEvent() 종료 후 자동으로 Swap
```
*수동 Double Buffering (필요 시): *
```python
from PySide6.QtGui import QPixmap
class ManualDoubleBuffer(QWidget): def __init__(self): super().__init__()
  self.buffer = None
  def resizeEvent(self, event): # 버퍼 크기 조정
  self.buffer = QPixmap(self.size())
  self.buffer.fill(Qt.white)
  def paintEvent(self, event): if self.buffer is None: return
  # 백 버퍼에 렌더링
  buffer_painter = QPainter(self.buffer)
  buffer_painter.setRenderHint(QPainter.Antialiasing)
  buffer_painter.drawLine(0, 0, 100, 100)
  buffer_painter.end()
  # 백 버퍼를 화면에 복사
  screen_painter = QPainter(self)
  screen_painter.drawPixmap(0, 0, self.buffer)
```
==== Triple Buffering
고성능 애니메이션에서 사용된다.
*구조: *
```
┌─────────────┐ Swap ┌─────────────┐
│ Display │ ←────── │  Front Buf │
│ Buffer │  └─────────────┘
└─────────────┘ ↑
  Swap │
  ┌─────────────┐
  │  Back Buf 1 │
  └─────────────┘
  ↑
  렌더링 │
  ┌─────────────┐
  │  Back Buf 2 │ ← 다음 프레임 렌더링 시작
  └─────────────┘
```
*장점: *
- GPU가 Swap을 기다리지 않고 다음 프레임 렌더링 시작
- 프레임 드롭 방지
*단점: *
- 메모리 사용량 50% 증가
- 1 프레임 입력 지연 (Input Lag)
*OpenGL 설정: *
```python
import pyqtgraph as pg
from PySide6.QtWidgets import QApplication
app = QApplication([])
# OpenGL Surface Format 설정
from PySide6.QtGui import QSurfaceFormat
fmt = QSurfaceFormat()
fmt.setSwapInterval(1) # VSync 활성화
fmt.setSwapBehavior(QSurfaceFormat.TripleBuffer) # Triple Buffering
QSurfaceFormat.setDefaultFormat(fmt)
# PyQtGraph OpenGL 활성화
pg.setConfigOptions(useOpenGL=True)
```
=== Dirty Region Tracking (변경 영역 추적)
==== 개념
전체 위젯을 다시 그리는 대신, 변경된 영역만 업데이트한다.
*비교: *
```
전체 렌더링:
┌────────────────────┐
│ █████████████████ │  ← 전체 다시 그림 (느림)
│ █████████████████ │
│ █████████████████ │
└────────────────────┘
렌더링 시간: 16ms
Dirty Region:
┌────────────────────┐
│ │
│ ┌───┐ │  ← 작은 영역만 그림 (빠름)
│ │ █ │ │
└────────└───┘───────┘
렌더링 시간: 1ms
```
==== Qt에서 구현
```python
class OptimizedWidget(QWidget): def __init__(self): super().__init__()
  self._dirty_rects = []
  def update_region(self, x, y, width, height): """특정 영역만 업데이트 요청"""
  rect = QRect(x, y, width, height)
  self._dirty_rects.append(rect)
  self.update(rect) # ✓ 영역 지정
  def paintEvent(self, event): painter = QPainter(self)
  # 변경된 영역만 렌더링
  dirty_region = event.region()
  for rect in dirty_region.rects(): # rect 영역만 다시 그림
  painter.setClipRect(rect)
  self.render_region(painter, rect)
```
==== PyQtGraph 최적화
PyQtGraph는 자동으로 Dirty Region을 추적한다.
```python
# PlotCurveItem.setData() 호출 시:
curve.setData(x, y)
  ↓
# 내부적으로:
1. 이전 데이터 범위 계산 (old_bounds)
2. 새 데이터 범위 계산 (new_bounds)
3. 변경 영역 = union(old_bounds, new_bounds)
4. update(변경_영역) # 해당 영역만 다시 그림
```
*성능 비교: *
```
1920×1080 플롯에서 작은 업데이트 (100×100 픽셀): 전체 렌더링: ~16ms (1920×1080 전체)
Dirty Region: ~0.5ms (100×100만)
성능 향상: 32배
```
== OpenGL 기초
=== OpenGL이란?
OpenGL(Open Graphics Library)는 2D/3D 그래픽을 렌더링하기 위한 크로스 플랫폼 API이다.
*역사: *
- 1992년 Silicon Graphics가 개발
- 현재 Khronos Group이 관리
- 거의 모든 플랫폼에서 지원 (Windows, Linux, macOS, Android, iOS)
*버전: *
- OpenGL 1.x-2.x: 고정 파이프라인 (Fixed Pipeline)
- OpenGL 3.x+: 셰이더 프로그래밍 (Programmable Pipeline)
- OpenGL 4.x: 계산 셰이더, 테셀레이션
- OpenGL ES: 모바일/임베디드용
- Vulkan: OpenGL의 후속 (2016년)
=== OpenGL 렌더링 파이프라인
```
정점 데이터 (Vertex Data)
  │
  ↓
  버텍스 셰이더 (Vertex Shader)
  - 정점 위치 변환
  - 좌표계 변환 (Model → View → Projection)
  │
  ↓
  래스터화 (Rasterization)
  - 정점을 픽셀로 변환
  │
  ↓
  프래그먼트 셰이더 (Fragment Shader)
  - 픽셀 색상 계산
  - 텍스처 적용
  │
  ↓
  프레임 버퍼 (Frame Buffer)
  - 최종 이미지
```
=== PyQtGraph에서 OpenGL 사용
```python
import pyqtgraph as pg
import numpy as np
# OpenGL 활성화
pg.setConfigOptions(useOpenGL=True, enableExperimental=True)
# 3D 플롯
view = pg.opengl.GLViewWidget()
view.show()
# 3D 표면
x = np.linspace(-10, 10, 50)
y = np.linspace(-10, 10, 50)
X, Y = np.meshgrid(x, y)
Z = np.sin(np.sqrt(X**2 + Y**2))
surface = pg.opengl.GLSurfacePlotItem(x=X, y=Y, z=Z, shader='shaded', smooth=True)
view.addItem(surface)
```
=== 하드웨어 가속의 이점
#figure(table(columns: (auto, auto, auto), align: left, [*작업*], [*CPU 렌더링*], [*GPU (OpenGL) 렌더링*], [1M 점 그리기], [~500ms], [~10ms], [실시간 업데이트], [10-20 FPS], [60+ FPS], [메모리 사용], [높음], [낮음 (GPU 메모리)], ), caption: "CPU vs GPU 렌더링 성능 비교")
*주의사항: *
- OpenGL은 드라이버 의존성이 높음 (버그 가능)
- 가상 머신에서 제한적 지원
- 일부 오래된 하드웨어는 미지원
== 디자인 패턴 적용
=== Observer Pattern (이벤트 기반 차트 업데이트)
Week 6-7에서 학습한 Signal/Slot이 Observer 패턴의 구현이다. 차트 위젯은 데이터 모델을 관찰하여 자동 업데이트된다.
```python
from PySide6.QtCore import QObject, Signal
class ChartDataModel(QObject): """차트 데이터 모델 (Subject)"""
  data_updated = Signal(object)
  def __init__(self): super().__init__()
  self._data = []
  def add_data(self, value): self._data.append(value)
  self.data_updated.emit(self._data) # Observer들에게 통지
class ChartWidget(QWidget): """차트 위젯 (Observer)"""
  def __init__(self, model: ChartDataModel): super().__init__()
  self.model = model
  self.model.data_updated.connect(self.on_data_updated)
  @Slot(object)
  def on_data_updated(self, data): self.update_chart(data)
```
=== Strategy Pattern (차트 렌더링 전략)
Strategy 패턴은 알고리즘을 교체 가능하게 만든다. 차트 렌더링 방식을 동적으로 변경할 수 있다.
```python
from abc import ABC, abstractmethod
class PlotStrategy(ABC): """차트 렌더링 전략 인터페이스"""
  @abstractmethod
  def render(self, plot_widget, data): pass
class LinePlotStrategy(PlotStrategy): """선 그래프 전략"""
  def render(self, plot_widget, data): plot_widget.plot(data, pen='r')
class ScatterPlotStrategy(PlotStrategy): """산점도 전략"""
  def render(self, plot_widget, data): plot_widget.plot(data, pen=None, symbol='o')
class BarPlotStrategy(PlotStrategy): """막대 그래프 전략"""
  def render(self, plot_widget, data): bg = pg.BarGraphItem(x=range(len(data)), height=data, width=0.6)
  plot_widget.addItem(bg)
class ChartRenderer: """차트 렌더러 (Context)"""
  def __init__(self, strategy: PlotStrategy): self._strategy = strategy
  def set_strategy(self, strategy: PlotStrategy): """전략 교체"""
  self._strategy = strategy
  def render(self, plot_widget, data): """현재 전략으로 렌더링"""
  self._strategy.render(plot_widget, data)
# 사용
renderer = ChartRenderer(LinePlotStrategy())
renderer.render(plot_widget, data)
# 전략 변경
renderer.set_strategy(ScatterPlotStrategy())
renderer.render(plot_widget, data)
```
=== Flyweight Pattern (메모리 최적화)
Flyweight 패턴은 대량의 유사한 객체를 효율적으로 관리한다. 차트에서 동일한 스타일의 펜/브러시를 재사용한다.
```python
import pyqtgraph as pg
class PenFactory: """Pen Flyweight 팩토리"""
  _pens = {}
  @classmethod
  def get_pen(cls, color, width=2): """펜 재사용 (Flyweight)"""
  key = (color, width)
  if key not in cls._pens: cls._pens[key] = pg.mkPen(color=color, width=width)
  return cls._pens[key]
# 사용
pen1 = PenFactory.get_pen('#e74c3c', 2)
pen2 = PenFactory.get_pen('#e74c3c', 2)
assert pen1 is pen2 # True (같은 객체)
# 메모리 절약
for i in range(1000): curve = plot.plot(pen=PenFactory.get_pen('#3498db', 2))
  # 1000개 곡선이 하나의 Pen 객체를 공유
```
== PyQtGraph 고급 기능
=== ViewBox와 다중 축
```python
import pyqtgraph as pg
# 메인 PlotWidget
plot = pg.PlotWidget()
plot.setLabel('left', 'Temperature', units='°C', color='red')
plot.setLabel('bottom', 'Time', units='s')
# 두 번째 Y축 생성
viewbox2 = pg.ViewBox()
plot.scene().addItem(viewbox2)
plot.getAxis('right').linkToView(viewbox2)
viewbox2.setXLink(plot)
# 왼쪽 축: 온도
temp_curve = plot.plot(pen=pg.mkPen('r', width=2), name='Temperature')
# 오른쪽 축: 압력
pressure_curve = pg.PlotCurveItem(pen=pg.mkPen('b', width=2), name='Pressure')
viewbox2.addItem(pressure_curve)
# 축 범위 업데이트 함수
def update_views(): viewbox2.setGeometry(plot.plotItem.vb.sceneBoundingRect())
  viewbox2.linkedViewChanged(plot.plotItem.vb, viewbox2.XAxis)
update_views()
plot.plotItem.vb.sigResized.connect(update_views)
```
=== 다운샘플링
```python
# 자동 다운샘플링
curve.setDownsampling(auto=True, method='peak')
# 수동 다운샘플링
def downsample(data, factor): """Peak-hold 다운샘플링"""
  n = len(data) // factor
  result = np.zeros(n * 2)
  for i in range(n): chunk = data[i*factor: (i+1)*factor]
  result[i*2] = chunk.max()
  result[i*2+1] = chunk.min()
  return result
# 사용
if len(data) > 10000: data = downsample(data, 10) # 1/10로 축소
```
=== 이미지 아이템 (히트맵)
```python
import pyqtgraph as pg
import numpy as np
# 히트맵 생성
img_widget = pg.ImageView()
img_widget.show()
# 데이터 (2D 배열)
data = np.random.normal(size=(100, 100))
# 히트맵 표시
img_widget.setImage(data)
# 컬러맵 설정
img_widget.setColorMap(pg.colormap.get('CET-L9'))
```
=== ROI (Region of Interest)
```python
# ROI 추가
roi = pg.ROI([10, 10], [20, 20])
plot.addItem(roi)
# ROI 변경 이벤트
def on_roi_changed(): data = roi.getArrayRegion(img_data, img_item)
  print(f"ROI Mean: {data.mean()}")
roi.sigRegionChanged.connect(on_roi_changed)
```
== 완전한 예제: 고급 실시간 차트 시스템
다음은 Observer, Strategy, Flyweight 패턴을 모두 적용한 완전한 실행 가능 예제이다.
=== advanced_chart_system.py
```python
#!/usr/bin/env python3
"""
고급 실시간 차트 시스템
Observer + Strategy + Flyweight 패턴
"""
import sys
import random
from datetime import datetime
from dataclasses import dataclass
from collections import deque
from abc import ABC, abstractmethod
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QComboBox, QLabel, QGroupBox)
from PySide6.QtCore import QThread, Signal, Slot, Qt
import pyqtgraph as pg
import numpy as np
# ============== Data Model ==============
@dataclass
class ProcessData: """공정 데이터 모델"""
  timestamp: datetime
  temperature: float
  pressure: float
  flow_rate: float
# ============== Flyweight Pattern: Pen Factory ==============
class PenFactory: """Pen Flyweight 패턴"""
  _pens = {}
  @classmethod
  def get_pen(cls, color, width=2, style='solid'): key = (color, width, style)
  if key not in cls._pens: cls._pens[key] = pg.mkPen(color=color, width=width)
  return cls._pens[key]
  @classmethod
  def get_stats(cls): return f"Cached pens: {len(cls._pens)}"
# ============== Strategy Pattern: Plot Strategies ==============
class PlotStrategy(ABC): """차트 렌더링 전략 인터페이스"""
  @abstractmethod
  def setup_plot(self, plot_widget): pass
  @abstractmethod
  def update_data(self, curve, time_data, value_data): pass
class LinePlotStrategy(PlotStrategy): """선 그래프 전략"""
  def setup_plot(self, plot_widget): return plot_widget.plot(pen=PenFactory.get_pen('#e74c3c', 2))
  def update_data(self, curve, time_data, value_data): curve.setData(time_data, value_data)
class ScatterPlotStrategy(PlotStrategy): """산점도 전략"""
  def setup_plot(self, plot_widget): return plot_widget.plot(pen=None, symbol='o', symbolSize=5, symbolBrush=PenFactory.get_pen('#e74c3c').color())
  def update_data(self, curve, time_data, value_data): curve.setData(time_data, value_data)
class StepPlotStrategy(PlotStrategy): """계단 그래프 전략"""
  def setup_plot(self, plot_widget): return plot_widget.plot(pen=PenFactory.get_pen('#e74c3c', 2), stepMode='right')
  def update_data(self, curve, time_data, value_data): curve.setData(time_data, value_data)
# ============== Worker Thread ==============
class DataWorker(QThread): """백그라운드 데이터 수집"""
  data_ready = Signal(object)
  def __init__(self): super().__init__()
  self._running = False
  def run(self): self._running = True
  current_temp = 450.0
  current_pressure = 2.5
  current_flow = 100.0
  while self._running: try: # 시뮬레이션
  current_temp += random.uniform(-3, 3)
  current_pressure += random.uniform(-0.1, 0.1)
  current_flow += random.uniform(-5, 5)
  current_temp = max(100, min(550, current_temp))
  current_pressure = max(0.5, min(5.5, current_pressure))
  current_flow = max(50, min(150, current_flow))
  data = ProcessData(timestamp=datetime.now(), temperature=current_temp, pressure=current_pressure, flow_rate=current_flow)
  self.data_ready.emit(data)
  self.msleep(100)
  except Exception as e: print(f"Error: {e}")
  self._running = False
  def stop(self): self._running = False
  self.wait()
# ============== Chart Widget with Strategy ==============
class AdvancedChartWidget(QWidget): """고급 차트 위젯"""
  def __init__(self, max_points=100): super().__init__()
  self.max_points = max_points
  self.start_time = None
  self.strategy = LinePlotStrategy() # 기본 전략
  self.init_buffers()
  self.setup_ui()
  def init_buffers(self): self.time_buffer = deque(maxlen=self.max_points)
  self.temp_buffer = deque(maxlen=self.max_points)
  self.pressure_buffer = deque(maxlen=self.max_points)
  self.flow_buffer = deque(maxlen=self.max_points)
  def setup_ui(self): layout = QVBoxLayout()
  # Temperature plot
  self.temp_plot = pg.PlotWidget(title="Temperature")
  self.temp_plot.setLabel('left', 'Temperature', units='°C')
  self.temp_plot.setLabel('bottom', 'Time', units='s')
  self.temp_plot.showGrid(x=True, y=True, alpha=0.3)
  self.temp_plot.addLegend()
  # Strategy 적용
  self.temp_curve = self.strategy.setup_plot(self.temp_plot)
  layout.addWidget(self.temp_plot)
  # Multi-axis plot
  self.multi_plot = pg.PlotWidget(title="Pressure & Flow Rate")
  self.multi_plot.setLabel('left', 'Pressure', units='Torr', color='blue')
  self.multi_plot.setLabel('bottom', 'Time', units='s')
  self.multi_plot.setLabel('right', 'Flow Rate', units='sccm', color='green')
  self.multi_plot.showGrid(x=True, y=True, alpha=0.3)
  self.multi_plot.addLegend()
  # 왼쪽 축: Pressure
  self.pressure_curve = self.multi_plot.plot(pen=PenFactory.get_pen('#3498db', 2), name='Pressure')
  # 오른쪽 축: Flow Rate
  self.viewbox2 = pg.ViewBox()
  self.multi_plot.scene().addItem(self.viewbox2)
  self.multi_plot.getAxis('right').linkToView(self.viewbox2)
  self.viewbox2.setXLink(self.multi_plot)
  self.flow_curve = pg.PlotCurveItem(pen=PenFactory.get_pen('#2ecc71', 2), name='Flow Rate')
  self.viewbox2.addItem(self.flow_curve)
  # ViewBox 동기화
  def update_views(): self.viewbox2.setGeometry(self.multi_plot.plotItem.vb.sceneBoundingRect())
  self.viewbox2.linkedViewChanged(self.multi_plot.plotItem.vb, self.viewbox2.XAxis)
  update_views()
  self.multi_plot.plotItem.vb.sigResized.connect(update_views)
  layout.addWidget(self.multi_plot)
  self.setLayout(layout)
  def set_strategy(self, strategy: PlotStrategy): """렌더링 전략 변경 (Strategy Pattern)"""
  self.strategy = strategy
  self.temp_plot.clear()
  self.temp_curve = self.strategy.setup_plot(self.temp_plot)
  def update_data(self, data: ProcessData): """데이터 업데이트 (Observer Pattern)"""
  if self.start_time is None: self.start_time = data.timestamp
  elapsed = (data.timestamp - self.start_time).total_seconds()
  self.time_buffer.append(elapsed)
  self.temp_buffer.append(data.temperature)
  self.pressure_buffer.append(data.pressure)
  self.flow_buffer.append(data.flow_rate)
  time_list = list(self.time_buffer)
  # Temperature (Strategy 적용)
  self.strategy.update_data(self.temp_curve, time_list, list(self.temp_buffer))
  # Pressure & Flow
  self.pressure_curve.setData(time_list, list(self.pressure_buffer))
  self.flow_curve.setData(time_list, list(self.flow_buffer))
# ============== Main Window ==============
class MainWindow(QMainWindow): """메인 윈도우"""
  def __init__(self): super().__init__()
  self.setWindowTitle("Advanced Chart System")
  self.setGeometry(100, 100, 1400, 900)
  self.worker = DataWorker()
  self.worker.data_ready.connect(self.on_data_ready)
  self.data_count = 0
  self.setup_ui()
  def setup_ui(self): central_widget = QWidget()
  self.setCentralWidget(central_widget)
  layout = QVBoxLayout()
  # Header with controls
  header_layout = QHBoxLayout()
  title = QLabel("Advanced Chart System")
  title.setStyleSheet("font-size: 24px; font-weight: bold;")
  header_layout.addWidget(title)
  header_layout.addStretch()
  # Strategy selector
  strategy_label = QLabel("Plot Style: ")
  header_layout.addWidget(strategy_label)
  self.strategy_combo = QComboBox()
  self.strategy_combo.addItems(["Line", "Scatter", "Step"])
  self.strategy_combo.currentTextChanged.connect(self.on_strategy_changed)
  header_layout.addWidget(self.strategy_combo)
  layout.addLayout(header_layout)
  # Chart widget
  self.chart_widget = AdvancedChartWidget(max_points=100)
  layout.addWidget(self.chart_widget)
  # Control panel
  control_layout = QHBoxLayout()
  self.start_button = QPushButton("Start")
  self.start_button.setMinimumHeight(40)
  self.start_button.clicked.connect(self.on_start)
  control_layout.addWidget(self.start_button)
  self.stop_button = QPushButton("Stop")
  self.stop_button.setMinimumHeight(40)
  self.stop_button.setEnabled(False)
  self.stop_button.clicked.connect(self.on_stop)
  control_layout.addWidget(self.stop_button)
  self.count_label = QLabel("Samples: 0")
  self.count_label.setStyleSheet("font-size: 14px;")
  control_layout.addWidget(self.count_label)
  self.pen_stats_label = QLabel(PenFactory.get_stats())
  self.pen_stats_label.setStyleSheet("font-size: 12px; color: gray;")
  control_layout.addWidget(self.pen_stats_label)
  control_layout.addStretch()
  layout.addLayout(control_layout)
  central_widget.setLayout(layout)
  self.apply_stylesheet()
  def apply_stylesheet(self): stylesheet = """
  QMainWindow {
  background-color: #ecf0f1;
  }
  QPushButton {
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 5px;
  font-size: 14px;
  padding: 10px;
  }
  QPushButton: hover {
  background-color: #2980b9;
  }
  QPushButton: disabled {
  background-color: #95a5a6;
  }
  QComboBox {
  padding: 5px;
  font-size: 14px;
  }
  """
  self.setStyleSheet(stylesheet)
  @Slot(str)
  def on_strategy_changed(self, strategy_name): """전략 변경 (Strategy Pattern)"""
  strategies = {
  "Line": LinePlotStrategy(), "Scatter": ScatterPlotStrategy(), "Step": StepPlotStrategy()
  }
  self.chart_widget.set_strategy(strategies[strategy_name])
  print(f"Strategy changed to: {strategy_name}")
  @Slot()
  def on_start(self): self.worker.start()
  self.start_button.setEnabled(False)
  self.stop_button.setEnabled(True)
  self.data_count = 0
  @Slot()
  def on_stop(self): self.worker.stop()
  self.start_button.setEnabled(True)
  self.stop_button.setEnabled(False)
  print(f"Total samples: {self.data_count}")
  @Slot(object)
  def on_data_ready(self, data: ProcessData): """데이터 수신 (Observer Pattern)"""
  self.data_count += 1
  self.chart_widget.update_data(data)
  self.count_label.setText(f"Samples: {self.data_count}")
  self.pen_stats_label.setText(PenFactory.get_stats())
  def closeEvent(self, event): if self.worker.isRunning(): self.worker.stop()
  event.accept()
# ============== Main ==============
def main(): app = QApplication(sys.argv)
  window = MainWindow()
  window.show()
  sys.exit(app.exec())
if __name__ == "__main__": main()
```
*실행 방법: *
1. 위 코드를 `advanced_chart_system.py`로 저장
2. `pip install PySide6 pyqtgraph numpy` 실행
3. `python advanced_chart_system.py` 실행
*기능: *
- Plot Style 선택: Line, Scatter, Step (Strategy Pattern)
- 실시간 차트: 온도, 압력 (왼쪽 축), 유량 (오른쪽 축)
- Pen 재사용: Flyweight Pattern으로 메모리 최적화
- Observer Pattern: 데이터 변경 시 자동 차트 업데이트
== MCQ (Multiple Choice Questions)
=== 문제 1: 라이브러리 선택 (기초)
반도체 HMI에서 1000Hz 실시간 차트가 필요할 때 가장 적합한 라이브러리는?
A. Matplotlib \
B. PyQtGraph \
C. Plotly \
D. Seaborn
*정답: B*
*해설*: PyQtGraph는 빠른 실시간 업데이트에 최적화되어 있으며 1000+ Hz 업데이트도 가능하다. Matplotlib은 정적 플롯에, Plotly는 웹 기반 인터랙티브 플롯에 적합하다.
---
=== 문제 2: OpenGL 이점 (기초)
OpenGL을 사용하는 주된 이유는?
A. 더 나은 색상 표현 \
B. GPU 하드웨어 가속 \
C. 크로스 브라우저 호환성 \
D. 간단한 API
*정답: B*
*해설*: OpenGL은 GPU를 활용한 하드웨어 가속을 제공하여, CPU 렌더링보다 수십 배 빠른 성능을 낸다.
---
=== 문제 3: Strategy Pattern (중급)
Strategy Pattern의 주된 목적은?
A. 메모리 절약 \
B. 알고리즘을 런타임에 교체 가능하게 만듦 \
C. 싱글톤 인스턴스 보장 \
D. 데이터 캡슐화
*정답: B*
*해설*: Strategy Pattern은 알고리즘군을 정의하고, 각각 캡슐화하여 런타임에 교체 가능하게 만든다. 예제에서는 Line/Scatter/Step 플롯 전략을 동적으로 변경한다.
---
=== 문제 4: Flyweight Pattern (중급)
다음 코드에서 Flyweight Pattern의 효과는?
```python
for i in range(1000): curve = plot.plot(pen=PenFactory.get_pen('#3498db', 2))
```
A. 1000개의 Pen 객체 생성 \
B. 1개의 Pen 객체를 1000번 재사용 \
C. 메모리 누수 발생 \
D. 성능 저하
*정답: B*
*해설*: PenFactory는 동일한 색상/두께의 Pen을 캐시하여 재사용한다 (Flyweight Pattern). 1000개 곡선이 1개 Pen 객체를 공유하여 메모리를 절약한다.
---
=== 문제 5: 다운샘플링 (중급)
PyQtGraph에서 다운샘플링을 사용하는 이유는?
A. 데이터 압축 \
B. 대량 데이터 포인트의 렌더링 성능 향상 \
C. 색상 품질 개선 \
D. 파일 크기 줄이기
*정답: B*
*해설*: 다운샘플링은 화면에 표시되지 않는 데이터 포인트를 제거하여 렌더링 성능을 향상시킨다. 1M 포인트 → 1K 포인트로 축소 가능.
---
=== 문제 6: ViewBox 다중 축 (고급)
다음 코드의 목적은?
```python
viewbox2 = pg.ViewBox()
plot.scene().addItem(viewbox2)
plot.getAxis('right').linkToView(viewbox2)
```
A. 플롯 복제 \
B. 오른쪽 Y축 추가 \
C. 줌 기능 추가 \
D. 그리드 추가
*정답: B*
*해설*: 두 번째 ViewBox를 생성하여 오른쪽 Y축을 추가한다. 서로 다른 스케일의 데이터를 하나의 플롯에 표시할 수 있다.
---
=== 문제 7: OpenGL 파이프라인 (고급)
OpenGL 렌더링 파이프라인의 올바른 순서는?
A. Vertex Shader → Rasterization → Fragment Shader \
B. Fragment Shader → Vertex Shader → Rasterization \
C. Rasterization → Vertex Shader → Fragment Shader \
D. Vertex Shader → Fragment Shader → Rasterization
*정답: A*
*해설*: 1) Vertex Shader (정점 변환) → 2) Rasterization (픽셀 생성) → 3) Fragment Shader (픽셀 색상 계산)
---
=== 문제 8: 코드 분석 - Strategy (고급)
다음 코드의 출력은?
```python
class DoubleStrategy: def calc(self, x): return x * 2
class SquareStrategy: def calc(self, x): return x * x
strategy = DoubleStrategy()
print(strategy.calc(5))
strategy = SquareStrategy()
print(strategy.calc(5))
```
A. 10, 10 \
B. 5, 5 \
C. 10, 25 \
D. 오류 발생
*정답: C*
*해설*: 첫 번째는 DoubleStrategy (`5*2=10`), 두 번째는 SquareStrategy (`5*5=25`). Strategy Pattern으로 알고리즘을 동적으로 교체한다.
---
=== 문제 9: PyQtGraph vs Matplotlib (고급)
다음 중 PyQtGraph가 Matplotlib보다 우수한 점은?
A. 더 많은 플롯 타입 \
B. 출판 품질 그래픽 \
C. 실시간 업데이트 성능 \
D. MATLAB 호환성
*정답: C*
*해설*: PyQtGraph는 실시간 업데이트 성능에 최적화되어 있다 (1000+ Hz). Matplotlib은 출판 품질과 다양한 플롯 타입에서 우수하다.
---
=== 문제 10: 패턴 종합 (도전)
다음 시스템에서 사용된 디자인 패턴의 조합은?
- 데이터 모델 변경 시 차트 자동 업데이트
- 플롯 스타일 (Line/Scatter/Bar) 런타임 변경
- Pen 객체 재사용으로 메모리 절약
A. Singleton, Factory, Adapter \
B. Observer, Strategy, Flyweight \
C. Builder, Prototype, Facade \
D. Proxy, Decorator, Command
*정답: B*
*해설*: Observer (자동 업데이트), Strategy (플롯 스타일 변경), Flyweight (Pen 재사용)
== 추가 학습 자료
=== 공식 문서
- *PyQtGraph Documentation*: https: //pyqtgraph.readthedocs.io/
- *OpenGL Tutorial*: https: //learnopengl.com/
- *Matplotlib Documentation*: https: //matplotlib.org/stable/contents.html
- *Plotly Documentation*: https: //plotly.com/python/
=== 참고 서적
- "OpenGL Programming Guide" (Red Book)
- "Python Data Science Handbook" by Jake VanderPlas (Matplotlib)
- "Design Patterns: Elements of Reusable Object-Oriented Software" (GoF)
=== 온라인 자료
- PyQtGraph Examples: https: //pyqtgraph.readthedocs.io/en/latest/getting_started/examples.html
- OpenGL Tutorial (Korean): https: //heinleinsgame.tistory.com/
- Real Python Graphics: https: //realpython.com/python-data-visualization/
== 요약
이번 챕터에서는 Python 고급 UI 및 차트를 학습했다: *이론 (Theory): *
- 2D 그래픽 라이브러리 비교: Matplotlib, PyQtGraph, Plotly
  - PyQtGraph: 실시간 모니터링 최적 (1000+ Hz)
  - Matplotlib: 출판 품질 정적 그래픽
  - Plotly: 웹 기반 인터랙티브 대시보드
- OpenGL 기초: 렌더링 파이프라인, GPU 가속, 성능 비교
- 반도체 HMI 권장: PyQtGraph + OpenGL
*응용 (Application): *
- Observer Pattern: Signal/Slot 기반 차트 자동 업데이트
- Strategy Pattern: 런타임 플롯 스타일 변경 (Line/Scatter/Step)
- Flyweight Pattern: Pen 재사용으로 메모리 최적화
- 완전한 실행 가능 예제: 고급 차트 시스템 (400+ 줄)
  - 다중 축 (Pressure + Flow Rate)
  - 동적 전략 변경
  - Flyweight 캐싱 통계
*성찰 (Reflections): *
- MCQ 10문제: 라이브러리 선택, OpenGL, 디자인 패턴, 코드 분석
*핵심 포인트: *
1. PyQtGraph는 반도체 HMI 실시간 차트에 최적의 선택
2. OpenGL 하드웨어 가속으로 CPU 대비 수십 배 성능 향상
3. 디자인 패턴 적용으로 유지보수성과 확장성 향상
4. Strategy Pattern으로 플롯 스타일을 런타임에 교체 가능
5. Flyweight Pattern으로 대량 객체의 메모리 효율화
다음 챕터에서는 Python 배포 및 테스트를 학습한다.
#pagebreak()