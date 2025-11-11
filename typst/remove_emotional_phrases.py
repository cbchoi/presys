#!/usr/bin/env python3
"""Remove emotional and philosophical expressions from Typst files."""

import re
import glob

# 패턴 매칭 및 교체 규칙
REPLACEMENTS = [
    # 감성적 형용사
    (r'혁신적인 기능', '기능'),
    (r'혁신적인', ''),
    (r'획기적으로 개선', '개선'),
    (r'획기적으로 단축', '단축'),
    (r'획기적으로', '크게'),
    (r'가장 강력한 기능 중 하나', '주요 기능'),
    (r'가장 강력한', '주요'),
    (r'훨씬 강력한', '다양한'),
    (r'매우 강력한', '중요한'),
    (r'강력한 기능', '기능'),
    (r'탁월한', '우수한'),
    (r'놀라운', ''),
    (r'엄청난', '상당한'),

    # 철학적 표현
    (r'본질적으로 다른 철학', '다른 방식'),
    (r'본질적으로 다른', '다른'),
    (r'본질적인 가치', '가치'),
    (r'본질적인', ''),
    (r'진정한 긴급', '긴급'),
    (r'진정한', ''),
    (r'궁극적', ''),
    (r'의 철학', '의 원리'),
    (r'철학을 따른다', '원리를 따른다'),
    (r'철학을 탐구', '원리를 이해'),

    # "단순한...아니라" 패턴
    (r'단순한 학문적 개념이 아니라,?\s*', ''),
    (r'단순한 기술적 선택이 아니라,?\s*', ''),
    (r'단순한 문법이 아니라,?\s*', ''),
    (r'단순한 속성이 아니라,?\s*', ''),
    (r'단순한.*아니라,?\s*', ''),

    # 연봉/경력 관련 과장
    (r'월급 1\.5배.*프리미엄을 받는.*도약할 수 있다\.?', ''),
    (r'월급.*배.*프리미엄', ''),
    (r'연봉.*프리미엄', ''),
    (r'신입 대비 \d+\.\d+배의 연봉 프리미엄을 받는다\.?', ''),
    (r'도약할 수 있다', ''),

    # 수백억원 등 과장된 금액 표현
    (r'수백억원의 손실을 막을 수 있는', ''),
    (r'수백억.*교훈', 'HMI 설계 오류의 영향'),

    # 과장된 평가 표현
    (r'매우 높은 평가를 받는다', ''),
    (r'가장 높은 평가를 받는다', ''),

    # 핵심은 패턴
    (r'의 핵심은 ([^이다]+)이다', r'는 \1'),
    (r'핵심은 ([^이다]+)이다', r'\1'),
    (r'이 구현의 핵심은', '이 구현은'),
    (r'이 코드의 핵심은', '이 코드는'),

    # 공백 정리
    (r'\s+\.', '.'),
    (r'\s+,', ','),
    (r'\s{2,}', ' '),
]

def clean_text(text):
    """Apply all replacement rules to text."""
    for pattern, replacement in REPLACEMENTS:
        text = re.sub(pattern, replacement, text)
    return text

def process_file(filepath):
    """Process a single file."""
    print(f"Processing: {filepath}")

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    content = clean_text(content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✓ Modified")
        return True
    else:
        print(f"  - No changes")
        return False

def main():
    """Process all week chapter files."""
    pattern = '/home/cbchoi/Projects/presys/typst/chapters/week*.typ'
    files = sorted(glob.glob(pattern))

    # Exclude backup files
    files = [f for f in files if '/backup/' not in f]

    modified_count = 0
    for filepath in files:
        if process_file(filepath):
            modified_count += 1

    print(f"\n완료: {modified_count}/{len(files)} 파일 수정됨")

if __name__ == '__main__':
    main()
