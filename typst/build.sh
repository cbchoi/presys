#!/bin/bash

# HCI/HMI 강의 교재 빌드 스크립트

set -e

echo "======================================"
echo "HCI/HMI 강의 교재 빌드"
echo "======================================"

# Typst 설치 확인
if ! command -v typst &> /dev/null; then
    echo "Error: Typst가 설치되어 있지 않습니다."
    echo "설치 방법:"
    echo "  - Linux/Mac: brew install typst"
    echo "  - Linux: cargo install --git https://github.com/typst/typst"
    echo "  - Windows: scoop install typst"
    exit 1
fi

echo "Typst 버전: $(typst --version)"
echo ""

# 출력 디렉토리 생성
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

# 전체 교재 빌드
echo "전체 교재 빌드 중..."
typst compile --font-path fonts main.typ "$OUTPUT_DIR/HCI-HMI-Complete.pdf"
echo "✓ 전체 교재: $OUTPUT_DIR/HCI-HMI-Complete.pdf"

# 개별 챕터 빌드 (선택사항)
if [ "$1" == "--chapters" ]; then
    echo ""
    echo "개별 챕터 빌드 중..."

    CHAPTERS=(
        "week01-hci-hmi-theory:Week01-HCI-HMI-Theory"
        "week02-csharp-wpf-basics:Week02-CSharp-WPF-Basics"
        "week03-csharp-realtime-data:Week03-CSharp-Realtime-Data"
        "week04-csharp-advanced-ui:Week04-CSharp-Advanced-UI"
        "week05-csharp-test-deploy:Week05-CSharp-Test-Deploy"
        "week06-python-pyside6-basics:Week06-Python-PySide6-Basics"
        "week07-python-realtime-data:Week07-Python-Realtime-Data"
        "week08-python-advanced-features:Week08-Python-Advanced-Features"
        "week09-python-deployment:Week09-Python-Deployment"
        "week10-imgui-basics:Week10-ImGui-Basics"
        "week11-imgui-advanced:Week11-ImGui-Advanced"
        "week12-imgui-advanced-features:Week12-ImGui-Advanced-Features"
        "week13-imgui-integrated-project:Week13-ImGui-Integrated-Project"
    )

    for chapter in "${CHAPTERS[@]}"; do
        IFS=':' read -r filename output_name <<< "$chapter"
        echo "#set text(font: \"NanumGothic\", lang: \"ko\", fallback: true)" > temp_chapter.typ
        echo "#include \"chapters/${filename}.typ\"" >> temp_chapter.typ
        typst compile --font-path fonts temp_chapter.typ "$OUTPUT_DIR/${output_name}.pdf"
        echo "✓ $output_name.pdf"
        rm temp_chapter.typ
    done
fi

echo ""
echo "======================================"
echo "빌드 완료!"
echo "======================================"
echo "출력 위치: $OUTPUT_DIR/"
echo ""

# 파일 크기 표시
du -h "$OUTPUT_DIR"/*.pdf

exit 0
