#!/usr/bin/env python3
import re
import sys

# Define the patterns to fix in descriptive text (Korean paragraphs)
# These should only be fixed in regular text, not in code blocks

fixes = [
    # Color codes pattern: "#XXXXXX" -> "\"\#XXXXXX\""
    (r'"(#[0-9A-Fa-f]{6})"(?!>)', r'"\\\"\#\1\\\""'),  # Make sure not to break XAML attributes
    
    # Special strings patterns - only in Korean text
    (r'Width를 "(\*)"로', r'Width를 "\"*\""로'),
    (r'Width를 "(Auto)"로', r'Width를 "\"Auto\""로'),
    (r'Height를 "(Auto)"로', r'Height를 "\"Auto\""로'),
    (r'Orientation을 "(Vertical)"로', r'Orientation을 "\"Vertical\""로'),
    (r'Orientation을 "(Horizontal)"로', r'Orientation을 "\"Horizontal\""로'),
    (r'FontWeight를 "(Bold)"로', r'FontWeight를 "\"Bold\""로'),
    (r'FontWeight는 "(Medium)"로', r'FontWeight는 "\"Medium\""로'),
    (r'Foreground를 "(White)"로', r'Foreground를 "\"White\""로'),
    (r'Background를 "(White)"로', r'Background를 "\"White\""로'),
]

def fix_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Process fixes, but be careful about code blocks
        lines = content.split('\n')
        in_code_block = False
        
        for i, line in enumerate(lines):
            # Track if we're in a code block (starts with ```)
            if line.strip().startswith('```'):
                in_code_block = not in_code_block
            
            # Only apply fixes to non-code lines
            if not in_code_block and not line.strip().startswith('```'):
                # Skip lines that are actual XAML code (start with whitespace and <)
                if not re.match(r'^\s+<', line):
                    # Apply fixes
                    for pattern, replacement in fixes:
                        line = re.sub(pattern, replacement, line)
            
            lines[i] = line
        
        content = '\n'.join(lines)
        
        if content != original:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {filename}: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        if fix_file(filename):
            print(f"Fixed: {filename}")
        else:
            print(f"No changes: {filename}")
    else:
        print("Usage: fix_typst.py <filename>")
