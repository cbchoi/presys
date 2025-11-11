#!/usr/bin/env python3
"""Remove unnecessary whitespace from .typ files"""

import re
import sys
from pathlib import Path

def clean_whitespace(text):
    """Remove unnecessary whitespace patterns."""

    # 1. 괄호 안 불필요한 공백 제거
    # "( 중급)" → "(중급)"
    # "( 기초 )" → "(기초)"
    text = re.sub(r'\(\s+', '(', text)
    text = re.sub(r'\s+\)', ')', text)

    # 2. 쉼표 뒤 공백 정규화 (0개 또는 2개 이상 → 1개)
    text = re.sub(r',\s{0}([^\s])', r', \1', text)  # 쉼표 뒤 공백 없으면 추가
    text = re.sub(r',\s{2,}', ', ', text)  # 쉼표 뒤 공백 2개 이상이면 1개로

    # 3. 콜론 뒤 공백 정규화
    text = re.sub(r':\s{0}([^\s])', r': \1', text)  # 콜론 뒤 공백 없으면 추가
    text = re.sub(r':\s{2,}', ': ', text)  # 콜론 뒤 공백 2개 이상이면 1개로

    # 4. 연속된 공백 제거 (탭 제외, 코드 블록 내부는 제외)
    # 일반 텍스트 라인에서만 연속 공백 제거
    lines = text.split('\n')
    cleaned_lines = []
    in_code_block = False

    for line in lines:
        # 코드 블록 시작/종료 감지
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            cleaned_lines.append(line)
            continue

        # 코드 블록 내부는 건드리지 않음
        if in_code_block:
            cleaned_lines.append(line)
            continue

        # 일반 텍스트: 연속 공백을 1개로
        cleaned_line = re.sub(r'([^\t])\s{2,}([^\s])', r'\1 \2', line)
        cleaned_lines.append(cleaned_line)

    text = '\n'.join(cleaned_lines)

    # 5. 줄 끝 공백 제거
    text = re.sub(r'\s+$', '', text, flags=re.MULTILINE)

    # 6. 파일 끝 빈 줄 정리 (최대 1개의 빈 줄만)
    text = re.sub(r'\n{3,}$', '\n\n', text)

    return text

def process_file(filepath):
    """Process a single file."""
    path = Path(filepath)

    # Read original content
    try:
        with open(path, 'r', encoding='utf-8') as f:
            original = f.read()
    except Exception as e:
        print(f"Error reading {path}: {e}")
        return False

    # Clean whitespace
    cleaned = clean_whitespace(original)

    # Only write if changed
    if cleaned != original:
        try:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            print(f"✓ Cleaned: {path.name}")
            return True
        except Exception as e:
            print(f"Error writing {path}: {e}")
            return False
    else:
        print(f"  Unchanged: {path.name}")
        return False

def main():
    """Main entry point."""
    # Get all .typ files (exclude backup folder)
    chapters_dir = Path('/home/cbchoi/Projects/presys/typst/chapters')
    files = [
        f for f in chapters_dir.glob('*.typ')
        if f.is_file() and 'backup' not in str(f)
    ]

    files = sorted(files)  # Sort for consistent order

    print(f"Found {len(files)} files to process\n")

    modified_count = 0
    for filepath in files:
        if process_file(filepath):
            modified_count += 1

    print(f"\n완료: {modified_count}/{len(files)} 파일 수정됨")

if __name__ == '__main__':
    main()
