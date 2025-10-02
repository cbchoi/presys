#!/usr/bin/env python3
"""
Bootstrap script for Presys - Universal Presentation System
Dynamically generates index.html based on available topics in slides/ directory
"""

import os
import re
import json
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime


def scan_topics_directory(slides_path: Path) -> List[Dict[str, Any]]:
    """
    Scan slides directory for topic folders and extract topic information

    Args:
        slides_path: Path to slides directory

    Returns:
        List of topic dictionaries with metadata
    """
    topics = []

    if not slides_path.exists():
        print(f"⚠️  Warning: slides directory not found at {slides_path}")
        return topics

    # Ignore special directories
    ignore_dirs = {'css', 'themes', 'assets', 'images', 'js'}

    for item in slides_path.iterdir():
        # Skip files and special directories
        if not item.is_dir() or item.name in ignore_dirs or item.name.startswith('.'):
            continue

        # Skip if only contains hidden files
        if not any(f.name != '.gitkeep' and not f.name.startswith('.') for f in item.iterdir()):
            continue

        topic_info = extract_topic_info(item)
        if topic_info:
            topics.append(topic_info)

    # Sort topics by name (natural sort for numbers)
    topics.sort(key=lambda x: natural_sort_key(x['id']))
    return topics


def natural_sort_key(text: str) -> list:
    """
    Generate a key for natural sorting (handles numbers correctly)
    e.g., ['topic1', 'topic2', 'topic10'] instead of ['topic1', 'topic10', 'topic2']
    """
    return [int(c) if c.isdigit() else c.lower() for c in re.split(r'(\d+)', text)]


def extract_topic_info(topic_path: Path) -> Dict[str, Any]:
    """
    Extract topic information from topic directory

    Args:
        topic_path: Path to topic directory

    Returns:
        Dictionary with topic metadata
    """
    topic_id = topic_path.name

    topic_info = {
        'id': topic_id,
        'path': topic_id,
        'title': format_title(topic_id),
        'description': 'No description available',
        'has_slides': False,
        'has_code': False,
        'has_images': False,
        'slide_count': 0,
        'modules': []
    }

    # Check for slides.md (single-file topic)
    slides_file = topic_path / 'slides.md'
    if slides_file.exists():
        topic_info['has_slides'] = True
        topic_info['slide_count'] = count_slides(slides_file)

        # Try to extract title from slides.md
        title = extract_title_from_markdown(slides_file)
        if title:
            topic_info['title'] = title

    # Check for summary.md
    summary_file = topic_path / 'summary.md'
    if summary_file.exists():
        summary_info = extract_summary_info(summary_file)
        topic_info.update(summary_info)

    # Check for modules (subdirectories with slides)
    modules = scan_modules(topic_path)
    if modules:
        topic_info['modules'] = modules
        topic_info['has_slides'] = True
        topic_info['slide_count'] = sum(m['slide_count'] for m in modules)

    # Check for code directory
    code_dir = topic_path / 'code'
    if code_dir.exists() and any(code_dir.iterdir()):
        topic_info['has_code'] = True

    # Check for images directory
    images_dir = topic_path / 'images'
    if images_dir.exists() and any(images_dir.iterdir()):
        topic_info['has_images'] = True

    return topic_info


def scan_modules(topic_path: Path) -> List[Dict[str, Any]]:
    """
    Scan for module subdirectories within a topic

    Args:
        topic_path: Path to topic directory

    Returns:
        List of module dictionaries
    """
    modules = []
    ignore_dirs = {'code', 'images', 'assets', 'data'}

    for item in topic_path.iterdir():
        if not item.is_dir() or item.name in ignore_dirs or item.name.startswith('.'):
            continue

        # Check if this directory contains slides
        slides_file = item / 'slides.md'
        if slides_file.exists():
            module_info = {
                'id': item.name,
                'title': format_title(item.name),
                'slide_count': count_slides(slides_file)
            }

            # Try to extract title from module's slides.md
            title = extract_title_from_markdown(slides_file)
            if title:
                module_info['title'] = title

            modules.append(module_info)

    # Sort modules naturally
    modules.sort(key=lambda x: natural_sort_key(x['id']))
    return modules


def format_title(folder_name: str) -> str:
    """
    Format folder name into a readable title

    Examples:
        'my-presentation' -> 'My Presentation'
        'week01' -> 'Week 01'
        'chapter-01-intro' -> 'Chapter 01 Intro'
    """
    # Remove leading numbers and dashes
    title = re.sub(r'^(\d+[-_])+', '', folder_name)

    # Replace dashes and underscores with spaces
    title = title.replace('-', ' ').replace('_', ' ')

    # Capitalize each word
    title = ' '.join(word.capitalize() for word in title.split())

    return title


def count_slides(slides_file: Path) -> int:
    """
    Count the number of slides in a markdown file
    Slides are separated by '---'
    """
    try:
        with open(slides_file, 'r', encoding='utf-8') as f:
            content = f.read()
            # Count horizontal rules (slide separators)
            count = content.count('\n---\n') + 1  # +1 for the first slide
            return max(count, 1)
    except Exception as e:
        print(f"⚠️  Warning: Could not read {slides_file}: {e}")
        return 0


def extract_title_from_markdown(md_file: Path) -> str:
    """Extract title (first H1) from markdown file"""
    try:
        with open(md_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line.startswith('# '):
                    return line[2:].strip()
                # Stop after first non-comment content
                if line and not line.startswith('#') and not line.startswith('>'):
                    break
    except Exception as e:
        print(f"⚠️  Warning: Could not read {md_file}: {e}")
    return ""


def extract_summary_info(summary_file: Path) -> Dict[str, Any]:
    """Extract information from summary.md file"""
    info = {}

    try:
        with open(summary_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract title (first h1)
        title_match = re.search(r'^# (.+)$', content, re.MULTILINE)
        if title_match:
            info['title'] = title_match.group(1).strip()

        # Extract description from various possible sections
        # Try 학습 목표, 주요 내용, Overview, Description
        desc_patterns = [
            r'## (?:🎯 )?학습 목표\s*\n(.+?)(?=\n##|\Z)',
            r'## (?:📋 )?주요 내용\s*\n(.+?)(?=\n##|\Z)',
            r'## (?:📝 )?Description\s*\n(.+?)(?=\n##|\Z)',
            r'## (?:🔍 )?Overview\s*\n(.+?)(?=\n##|\Z)',
        ]

        for pattern in desc_patterns:
            desc_match = re.search(pattern, content, re.DOTALL)
            if desc_match:
                description = desc_match.group(1).strip()
                # Clean up markdown list markers
                description = re.sub(r'^[-*]\s+', '', description, flags=re.MULTILINE)
                # Limit to first few lines
                lines = [l.strip() for l in description.split('\n') if l.strip()][:3]
                info['description'] = '\n'.join(lines)
                break

    except Exception as e:
        print(f"⚠️  Warning: Could not read {summary_file}: {e}")

    return info


def generate_index_html(topics: List[Dict[str, Any]]) -> str:
    """
    Generate complete index.html content for the presentation system

    Args:
        topics: List of topic dictionaries

    Returns:
        Complete HTML content as string
    """

    # Generate topic cards HTML
    if not topics:
        cards_html = """
            <div class="welcome-card" style="text-align: center; padding: 60px 40px;">
                <h2 style="font-size: 2.5em; margin-bottom: 20px;">🎉 환영합니다!</h2>
                <p style="font-size: 1.2em; color: #4a5568; margin-bottom: 30px;">
                    아직 콘텐츠가 없습니다. 첫 프레젠테이션을 만들어보세요!
                </p>
                <div style="background: #f7fafc; padding: 30px; border-radius: 12px; text-align: left; max-width: 600px; margin: 0 auto;">
                    <h3 style="margin-top: 0; color: #2d3748;">🚀 빠른 시작</h3>
                    <ol style="line-height: 2; color: #4a5568;">
                        <li><code style="background: #e2e8f0; padding: 3px 8px; border-radius: 4px;">slides/my-topic/</code> 폴더 생성</li>
                        <li><code style="background: #e2e8f0; padding: 3px 8px; border-radius: 4px;">slides.md</code> 파일 작성</li>
                        <li><code style="background: #e2e8f0; padding: 3px 8px; border-radius: 4px;">npm run bootstrap</code> 실행</li>
                        <li>이 페이지를 새로고침하세요!</li>
                    </ol>
                    <p style="margin-bottom: 0; font-size: 0.95em;">
                        📚 자세한 가이드는 <a href="https://github.com/yourusername/presys#readme" style="color: #667eea;">README.md</a>를 참조하세요.
                    </p>
                </div>
            </div>
        """
    else:
        cards = []
        for topic in topics:
            status_indicators = []
            if topic['has_slides']:
                status_indicators.append('<span class="status-indicator">📄 Slides</span>')
            if topic['has_code']:
                status_indicators.append('<span class="status-indicator">💻 Code</span>')
            if topic['has_images']:
                status_indicators.append('<span class="status-indicator">🖼️ Images</span>')

            status_html = '\n                    '.join(status_indicators) if status_indicators else '<span class="status-indicator">📋 Draft</span>'

            # Generate module badges if modules exist
            modules_html = ''
            if topic['modules']:
                module_badges = [f'<span class="module-badge">{m["title"]}</span>' for m in topic['modules']]
                modules_html = f'''
                <div class="modules">
                    <strong>Modules:</strong> {' '.join(module_badges)}
                </div>'''

            card_html = f'''
            <div class="topic-card">
                <div class="topic-header">
                    <h3>{topic['title']}</h3>
                    <span class="slide-count">{topic['slide_count']} slides</span>
                </div>
                <div class="topic-description">
                    {topic['description']}
                </div>{modules_html}
                <div class="status-indicators">
                    {status_html}
                </div>
                <div class="actions">
                    <a href="?topic={topic['path']}" class="view-link">🎯 View Slides</a>
                    <button onclick="generatePDF('{topic['path']}')" class="pdf-button">📄 Export PDF</button>
                </div>
            </div>'''
            cards.append(card_html)

        cards_html = '\n            '.join(cards)

    # Generate statistics
    total_topics = len(topics)
    total_slides = sum(t['slide_count'] for t in topics)
    topics_with_code = sum(1 for t in topics if t['has_code'])

    html_content = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="Presys Bootstrap v3.0.0">
    <meta name="generated-date" content="{datetime.now().isoformat()}">
    <title>Presys - Presentation System</title>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5.2.1/dist/reveal.css">
    <link rel="stylesheet" id="theme-link" href="https://cdn.jsdelivr.net/npm/reveal.js@5.2.1/dist/theme/white.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5.2.1/plugin/highlight/monokai.css">
    <link rel="stylesheet" href="/css/main.css">

    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans KR', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}

        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}

        .header {{
            text-align: center;
            color: white;
            padding: 40px 20px;
            margin-bottom: 40px;
        }}

        .header h1 {{
            font-size: 3em;
            margin-bottom: 15px;
            font-weight: 700;
        }}

        .header p {{
            font-size: 1.2em;
            opacity: 0.9;
            margin: 10px 0;
        }}

        .stats {{
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-top: 25px;
            flex-wrap: wrap;
        }}

        .stat-item {{
            background: rgba(255, 255, 255, 0.2);
            padding: 12px 24px;
            border-radius: 25px;
            font-size: 1em;
            backdrop-filter: blur(10px);
        }}

        .topics-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
        }}

        .topic-card, .welcome-card {{
            background: white;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }}

        .topic-card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.2);
        }}

        .topic-header {{
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 15px;
            gap: 15px;
        }}

        .topic-header h3 {{
            font-size: 1.4em;
            color: #2d3748;
            margin: 0;
            flex: 1;
        }}

        .slide-count {{
            background: #667eea;
            color: white;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 0.85em;
            font-weight: 600;
            white-space: nowrap;
        }}

        .topic-description {{
            color: #4a5568;
            line-height: 1.7;
            margin-bottom: 15px;
            min-height: 60px;
            font-size: 0.95em;
        }}

        .modules {{
            margin: 15px 0;
            padding: 12px;
            background: #f7fafc;
            border-radius: 8px;
            font-size: 0.9em;
        }}

        .module-badge {{
            display: inline-block;
            background: #e2e8f0;
            color: #4a5568;
            padding: 4px 10px;
            border-radius: 12px;
            margin: 3px;
            font-size: 0.85em;
        }}

        .status-indicators {{
            display: flex;
            gap: 8px;
            margin: 15px 0;
            flex-wrap: wrap;
        }}

        .status-indicator {{
            background: #e2e8f0;
            color: #4a5568;
            padding: 6px 12px;
            border-radius: 15px;
            font-size: 0.85em;
            font-weight: 500;
        }}

        .actions {{
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }}

        .view-link, .pdf-button {{
            flex: 1;
            padding: 12px 20px;
            border-radius: 10px;
            text-decoration: none;
            text-align: center;
            font-weight: 600;
            font-size: 0.95em;
            transition: all 0.3s ease;
            cursor: pointer;
        }}

        .view-link {{
            background: #667eea;
            color: white;
        }}

        .view-link:hover {{
            background: #5568d3;
            transform: translateY(-2px);
        }}

        .pdf-button {{
            background: #f7fafc;
            color: #4a5568;
            border: 2px solid #e2e8f0;
        }}

        .pdf-button:hover {{
            background: #e2e8f0;
            border-color: #cbd5e0;
        }}

        .footer {{
            text-align: center;
            color: white;
            padding: 30px 20px;
            opacity: 0.9;
        }}

        .footer p {{
            margin: 8px 0;
        }}

        .footer a {{
            color: white;
            text-decoration: underline;
        }}

        @media (max-width: 768px) {{
            .header h1 {{
                font-size: 2em;
            }}

            .topics-grid {{
                grid-template-columns: 1fr;
            }}

            .stats {{
                flex-direction: column;
                gap: 10px;
            }}
        }}
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>📊 Presys</h1>
            <p>Reveal.js 기반 범용 프레젠테이션 시스템</p>
            <div class="stats">
                <span class="stat-item">📚 {total_topics} Topics</span>
                <span class="stat-item">📄 {total_slides} Slides</span>
                <span class="stat-item">💻 {topics_with_code} with Code</span>
            </div>
        </div>

        <div class="topics-grid">
            {cards_html}
        </div>

        <div class="footer">
            <p>© 2025 Presys | Built with Reveal.js 5.2.1 & Vite 7.1.8</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                🤖 Generated by <a href="https://github.com/yourusername/presys">bootstrap.py</a> on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            </p>
        </div>
    </div>

    <script>
        // PDF generation function
        async function generatePDF(topicId) {{
            const isWindows = navigator.platform.toLowerCase().includes('win');
            const command = isWindows
                ? `scripts\\\\export-pdf.bat ${{topicId}}`
                : `./scripts/export-pdf.sh ${{topicId}}`;
            const platform = isWindows ? 'Windows' : 'Linux/Mac';

            const message = `${{topicId}} 토픽의 PDF를 생성하려면 터미널에서 다음 명령어를 실행하세요:\\n\\n${{platform}}: ${{command}}\\n\\n생성된 PDF는 pdf-exports 폴더에 저장됩니다.\\n\\n※ 먼저 개발 서버가 실행 중인지 확인해주세요.`;

            if (confirm(message + '\\n\\n명령어를 클립보드에 복사하시겠습니까?')) {{
                try {{
                    await navigator.clipboard.writeText(command);
                    alert('명령어가 클립보드에 복사되었습니다!\\n터미널에서 붙여넣기(Ctrl+V)하여 실행하세요.');
                }} catch (err) {{
                    // Fallback for older browsers
                    const textArea = document.createElement('textarea');
                    textArea.value = command;
                    document.body.appendChild(textArea);
                    textArea.select();
                    try {{
                        document.execCommand('copy');
                        alert('명령어가 클립보드에 복사되었습니다!\\n터미널에서 붙여넣기(Ctrl+V)하여 실행하세요.');
                    }} catch (err2) {{
                        alert('클립보드 복사에 실패했습니다. 수동으로 복사해주세요:\\n' + command);
                    }}
                    document.body.removeChild(textArea);
                }}
            }}
        }}

        // Make function globally available
        window.generatePDF = generatePDF;
    </script>
</body>
</html>'''

    return html_content


def main():
    """Main function to generate index.html"""

    print("=" * 60)
    print("🚀 Presys Bootstrap v3.0.0")
    print("=" * 60)

    # Get script directory and project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    slides_dir = project_root / "slides"

    print(f"\n🔍 Scanning topics in: {slides_dir}")

    # Scan for topics
    topics = scan_topics_directory(slides_dir)

    if not topics:
        print("⚠️  No topics found in slides directory!")
        print("💡 Create a topic folder in slides/ directory to get started.")
    else:
        print(f"\n✅ Found {len(topics)} topic(s):")
        for topic in topics:
            status = []
            if topic['has_slides']:
                status.append(f"📄 {topic['slide_count']} slides")
            if topic['modules']:
                status.append(f"📦 {len(topic['modules'])} modules")
            if topic['has_code']:
                status.append("💻 code")
            if topic['has_images']:
                status.append("🖼️ images")
            status_str = " | ".join(status) if status else "📋 draft"
            print(f"   • {topic['title']}")
            print(f"     {status_str}")

    # Generate index.html
    print(f"\n🏗️  Generating index.html...")
    html_content = generate_index_html(topics)

    # Write index.html
    index_path = slides_dir / "index.html"
    try:
        with open(index_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"✅ Successfully generated: {index_path}")
        print(f"📊 Generated {len(topics)} topic card(s)")
    except Exception as e:
        print(f"❌ Failed to write index.html: {e}")
        return

    # Generate summary report
    if topics:
        print(f"\n📋 Summary:")
        print(f"   • Total topics: {len(topics)}")
        print(f"   • Total slides: {sum(t['slide_count'] for t in topics)}")
        print(f"   • Topics with slides: {sum(1 for t in topics if t['has_slides'])}")
        print(f"   • Topics with modules: {sum(1 for t in topics if t['modules'])}")
        print(f"   • Topics with code: {sum(1 for t in topics if t['has_code'])}")
        print(f"   • Topics with images: {sum(1 for t in topics if t['has_images'])}")

    print(f"\n🚀 Ready to serve!")
    print(f"   Run: npm run dev")
    print(f"   Open: http://localhost:5173")
    print("=" * 60)


if __name__ == "__main__":
    main()
