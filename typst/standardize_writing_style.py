#!/usr/bin/env python3
"""Standardize writing style in Typst files - convert polite form to declarative form."""

import re
import glob

# 문체 변환 규칙
STYLE_REPLACEMENTS = [
    # ~입니다 → ~이다
    (r'([가-힣]+)입니다\.', r'\1이다.'),
    (r'([가-힣]+)입니다:', r'\1이다:'),
    (r'([가-힣]+)입니다,', r'\1이다,'),

    # ~합니다 → ~한다
    (r'([가-힣]+)합니다\.', r'\1한다.'),
    (r'([가-힣]+)합니다:', r'\1한다:'),
    (r'([가-힣]+)합니다,', r'\1한다,'),

    # ~됩니다 → ~된다
    (r'([가-힣]+)됩니다\.', r'\1된다.'),
    (r'([가-힣]+)됩니다:', r'\1된다:'),
    (r'([가-힣]+)됩니다,', r'\1된다,'),

    # ~습니다 → ~다
    (r'([가-힣]+)습니다\.', r'\1다.'),
    (r'([가-힣]+)습니다:', r'\1다:'),
    (r'([가-힣]+)습니다,', r'\1다,'),

    # ~해보세요 → ~수행한다
    (r'해보세요\.', r'수행한다.'),
    (r'해보세요:', r'수행한다:'),

    # ~하세요 → ~한다
    (r'([가-힣]+)하세요\.', r'\1한다.'),
    (r'([가-힣]+)하세요:', r'\1한다:'),

    # 명령형: ~하라 유지 (변경 안함)
    # ~합니까 → ~하는가
    (r'([가-힣]+)합니까\?', r'\1하는가?'),
    (r'([가-힣]+)습니까\?', r'\1는가?'),

    # ~있습니다 → ~있다
    (r'있습니다\.', r'있다.'),
    (r'있습니다:', r'있다:'),
    (r'있습니다,', r'있다,'),

    # ~없습니다 → ~없다
    (r'없습니다\.', r'없다.'),
    (r'없습니다:', r'없다:'),
    (r'없습니다,', r'없다,'),

    # ~받습니다 → ~받는다
    (r'([가-힣]+)받습니다\.', r'\1받는다.'),

    # ~갑니다 → ~간다
    (r'([가-힣]+)갑니다\.', r'\1간다.'),

    # ~옵니다 → ~온다
    (r'([가-힣]+)옵니다\.', r'\1온다.'),

    # 추가 패턴
    # ~됐다 → ~되었다 (구어체 제거)
    (r'([가-힣]+)됐다', r'\1되었다'),

    # ~했다 유지 (과거형은 그대로)
]

def clean_text(text):
    """Apply all style replacement rules to text."""
    for pattern, replacement in STYLE_REPLACEMENTS:
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
