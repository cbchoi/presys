// Week 1 단독 문서
#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge
#import "@preview/cetz:0.2.2": canvas, draw, tree

#set document(
  title: "Week 1: HCI/HMI 이론 및 반도체 장비 적용",
  author: "cbchoi",
  date: datetime.today(),
)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 3cm),
  numbering: "1",
  header: align(right)[
    _Week 1: HCI/HMI 이론 및 동시성 프로그래밍_
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

#include "chapters/week01-hci-hmi-theory.typ"
