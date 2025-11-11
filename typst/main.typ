// HCI/HMI 강의 교재
// 반도체 장비를 위한 Human-Computer Interaction과 Human-Machine Interface

// 다이어그램 패키지
#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge
#import "@preview/cetz:0.2.2": canvas, draw, tree

// 한글 폰트 설정
#let nanum-gothic = ("fonts/NanumGothic.ttf",)

#set document(
  title: "HCI/HMI 강의 교재",
  author: "cbchoi",
  date: datetime.today(),
)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 3cm),
  numbering: "1",
  header: align(right)[
    _HCI/HMI 강의 교재_
  ],
)

#set text(
  font: "NanumGothic",
  size: 11pt,
  lang: "ko",
  fallback: true,
)

#set par(
  justify: true,
  leading: 0.65em,
)

#set heading(
  numbering: "1.1",
)

// 제목 페이지
#align(center)[
  #v(3cm)

  #text(size: 28pt, weight: "bold")[
    HCI/HMI 강의 교재
  ]

  #v(1cm)

  #text(size: 18pt)[
    반도체 장비를 위한 \
    Human-Computer Interaction과 \
    Human-Machine Interface
  ]

  #v(2cm)

  #text(size: 14pt)[
    *주요 내용*
  ]

  #v(0.5cm)

  #text(size: 12pt)[
    - C\# WPF: Windows 기반 HMI 개발 \
    - Python PySide6: 크로스 플랫폼 HMI 개발 \
    - ImGui C++: 실시간 반도체 HMI 개발
  ]

  #v(3cm)

  #text(size: 11pt)[
    #datetime.today().display()
  ]
]

#pagebreak()

// 목차
#outline(
  title: "목차",
  depth: 3,
)

#pagebreak()

// 강의 개요
#align(center)[
  #text(size: 20pt, weight: "bold")[
    강의 개요
  ]
]

#v(1cm)

= 과목 소개

반도체 장비를 위한 Human-Computer Interaction(HCI)과 Human-Machine Interface(HMI) 설계 및 구현 능력을 습득하는 강의입니다.

== 학습 목표

본 강의를 통해 다음을 습득할 수 있습니다:

- HCI 이론을 반도체 장비 HMI 설계에 적용하는 능력
- C\# WPF를 활용한 Windows 기반 HMI 개발
- Python PySide6를 활용한 크로스 플랫폼 HMI 개발
- ImGui C++를 활용한 실시간 반도체 HMI 개발
- SEMI 표준을 준수하는 산업용 HMI 설계

== 기술 스택

본 강의에서 다루는 주요 기술:

- *언어*: C\#, Python, C++
- *프레임워크*: WPF, PySide6, Qt, ImGui
- *디자인 패턴*: MVVM
- *그래픽스*: OpenGL

== 대상 수강생

- 반도체 장비 소프트웨어 개발자
- HMI 설계자
- 산업용 UI/UX 엔지니어
- 실시간 시스템 개발자

#pagebreak()

// 챕터 포함
#include "chapters/week01-hci-hmi-theory.typ"
#include "chapters/week02-csharp-wpf-basics.typ"
#include "chapters/week03-csharp-realtime-data.typ"
#include "chapters/week04-csharp-advanced-ui.typ"
#include "chapters/week05-csharp-test-deploy.typ"
#include "chapters/week06-python-pyside6-basics.typ"
#include "chapters/week07-python-realtime-data.typ"
#include "chapters/week08-python-advanced-features.typ"
#include "chapters/week09-python-deployment.typ"
#include "chapters/week10-imgui-basics.typ"
#include "chapters/week11-imgui-advanced.typ"
#include "chapters/week12-imgui-advanced-features.typ"
#include "chapters/week13-imgui-integrated-project.typ"
