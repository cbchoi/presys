#!/usr/bin/env python3
"""Remove emotional and philosophical expressions from Typst files."""

import re
import glob

def clean_line(line):
    """Apply replacement rules to a single line."""
    # 감성적 형용사
    line = re.sub(r'혁신적인 기능', '기능', line)
    line = re.sub(r'혁신적인', '', line)
    line = re.sub(r'획기적으로 개선', '개선', line)
    line = re.sub(r'획기적으로 단축', '단축', line)
    line = re.sub(r'획기적으로', '크게', line)
    line = re.sub(r'가장 강력한 기능 중 하나', '주요 기능', line)
    line = re.sub(r'가장 강력한', '주요', line)
    line = re.sub(r'훨씬 강력한', '다양한', line)
    line = re.sub(r'매우 강력한', '중요한', line)
    line = re.sub(r'강력한 기능', '기능', line)

    # 철학적 표현
    line = re.sub(r'본질적으로 다른 철학', '다른 방식', line)
    line = re.sub(r'본질적으로 다른', '다른', line)
    line = re.sub(r'본질적인 가치', '가치', line)
    line = re.sub(r'본질적인', '', line)
    line = re.sub(r'진정한 긴급', '긴급', line)
    line = re.sub(r'진정한', '', line)
    line = re.sub(r'의 철학', '의 원리', line)
    line = re.sub(r'철학을 따른다', '원리를 따른다', line)

    # 연봉/경력 관련
    line = re.sub(r'월급 1\.5배.*프리미엄을 받는.*도약할 수 있다\.?', '', line)
    line = re.sub(r'신입 대비 \d+\.\d+배의 연봉 프리미엄을 받는다\.?', '', line)

    # 수백억원 등
    line = re.sub(r'수백억원의 손실을 막을 수 있는', '', line)

    # 핵심은 패턴
    line = re.sub(r'의 핵심은 ([^이다]+)이다', r'는 \1', line)
    line = re.sub(r'이 구현의 핵심은', '이 구현은', line)
    line = re.sub(r'이 코드의 핵심은', '이 코드는', line)

    # 공백 정리
    line = re.sub(r'\s+\.', '.', line)
    line = re.sub(r'\s+,', ',', line)
    line = re.sub(r'\s{2,}', ' ', line)

    return line

def process_file(filepath):
    """Process a single file line by line."""
    print(f"Processing: {filepath}")

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    modified = False
    new_lines = []

    for line in lines:
        original = line
        cleaned = clean_line(line)
        new_lines.append(cleaned)
        if cleaned != original:
            modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
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
