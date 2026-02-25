#!/usr/bin/env python3
"""
WCAG Accessibility Checker for HTML/CSS and React/TypeScript files.

This script performs static analysis to detect common WCAG 2.1 AA violations.
"""

import re
import sys
import json
from pathlib import Path
from typing import List, Dict, Tuple
from dataclasses import dataclass, asdict


@dataclass
class Issue:
    """Represents an accessibility issue found in code."""
    file: str
    line: int
    column: int
    severity: str  # 'error', 'warning'
    rule: str
    message: str
    code_snippet: str


class WCAGChecker:
    """Checks code for WCAG 2.1 AA compliance issues."""
    
    def __init__(self):
        self.issues: List[Issue] = []
    
    def check_file(self, filepath: str) -> List[Issue]:
        """Check a single file for accessibility issues."""
        self.issues = []
        path = Path(filepath)
        
        if not path.exists():
            print(f"Error: File not found: {filepath}", file=sys.stderr)
            return []
        
        content = path.read_text(encoding='utf-8')
        lines = content.split('\n')
        
        # Determine file type
        if path.suffix in ['.html', '.htm']:
            self._check_html(lines, filepath)
        elif path.suffix in ['.tsx', '.jsx', '.ts', '.js']:
            self._check_react(lines, filepath)
        elif path.suffix == '.css':
            self._check_css(lines, filepath)
        
        return self.issues
    
    def _add_issue(self, file: str, line_num: int, severity: str, rule: str, message: str, snippet: str):
        """Add an issue to the list."""
        self.issues.append(Issue(
            file=file,
            line=line_num,
            column=0,
            severity=severity,
            rule=rule,
            message=message,
            code_snippet=snippet.strip()
        ))
    
    def _check_html(self, lines: List[str], filepath: str):
        """Check HTML files for accessibility issues."""
        for i, line in enumerate(lines, 1):
            line_lower = line.lower()
            
            # Check for images without alt text
            if '<img' in line_lower and 'alt=' not in line_lower:
                self._add_issue(
                    filepath, i, 'error', 'img-alt',
                    'Image missing alt attribute (WCAG 1.1.1)',
                    line
                )
            
            # Check for input without label
            if '<input' in line_lower and 'type=' in line_lower:
                if 'aria-label=' not in line_lower and 'id=' in line_lower:
                    # This is a simplified check - would need context to verify label exists
                    pass
            
            # Check for buttons without accessible name
            if '<button' in line_lower and '>' in line:
                # Extract content between tags
                content = re.search(r'<button[^>]*>(.*?)</button>', line, re.IGNORECASE)
                if content and not content.group(1).strip():
                    if 'aria-label=' not in line_lower:
                        self._add_issue(
                            filepath, i, 'error', 'button-name',
                            'Button has no accessible name (WCAG 4.1.2)',
                            line
                        )
            
            # Check for lang attribute on html tag
            if i == 1 or '<html' in line_lower:
                if '<html' in line_lower and 'lang=' not in line_lower:
                    self._add_issue(
                        filepath, i, 'error', 'html-lang',
                        'HTML element missing lang attribute (WCAG 3.1.1)',
                        line
                    )
            
            # Check for click handlers on non-interactive elements
            if 'onclick=' in line_lower:
                if '<div' in line_lower or '<span' in line_lower:
                    if 'role=' not in line_lower and 'tabindex=' not in line_lower:
                        self._add_issue(
                            filepath, i, 'error', 'click-events-have-key-events',
                            'Click handler on non-interactive element without role/tabindex (WCAG 2.1.1)',
                            line
                        )
            
            # Check for tabindex > 0
            tabindex_match = re.search(r'tabindex=["\']?(\d+)', line_lower)
            if tabindex_match and int(tabindex_match.group(1)) > 0:
                self._add_issue(
                    filepath, i, 'warning', 'no-positive-tabindex',
                    'Positive tabindex values can cause focus order issues',
                    line
                )
    
    def _check_react(self, lines: List[str], filepath: str):
        """Check React/TypeScript files for accessibility issues."""
        for i, line in enumerate(lines, 1):
            line_lower = line.lower()
            
            # Check for img without alt
            if '<img' in line and 'alt=' not in line and 'alt={' not in line:
                self._add_issue(
                    filepath, i, 'error', 'img-alt',
                    'Image missing alt attribute (WCAG 1.1.1)',
                    line
                )
            
            # Check for onClick on div/span without role
            if 'onClick=' in line or 'onclick=' in line_lower:
                if ('<div' in line or '<span' in line) and 'role=' not in line:
                    if 'tabIndex=' not in line and 'tabindex=' not in line_lower:
                        self._add_issue(
                            filepath, i, 'error', 'click-events-have-key-events',
                            'onClick on non-interactive element needs role="button" and onKeyDown (WCAG 2.1.1)',
                            line
                        )
            
            # Check for role="button" without onKeyDown
            if 'role="button"' in line or "role='button'" in line:
                # Look for onKeyDown in same line or nearby
                if 'onKeyDown=' not in line and 'onkeydown=' not in line_lower:
                    self._add_issue(
                        filepath, i, 'warning', 'interactive-supports-focus',
                        'Element with role="button" should have onKeyDown handler',
                        line
                    )
            
            # Check for aria-expanded not being boolean
            aria_expanded = re.search(r'aria-expanded=["\']?(true|false|{)', line)
            if 'aria-expanded=' in line and not aria_expanded:
                self._add_issue(
                    filepath, i, 'error', 'aria-expanded-invalid',
                    'aria-expanded must be "true" or "false" or boolean expression',
                    line
                )
            
            # Check for missing htmlFor on label
            if '<label' in line and 'htmlFor=' not in line and '>' in line:
                # Check if it's not wrapping an input
                if '<input' not in line:
                    self._add_issue(
                        filepath, i, 'warning', 'label-has-associated-control',
                        'Label should have htmlFor attribute or wrap an input',
                        line
                    )
            
            # Check for autoFocus
            if 'autoFocus' in line or 'autofocus' in line_lower:
                self._add_issue(
                    filepath, i, 'warning', 'no-autofocus',
                    'autoFocus can be disruptive for keyboard and screen reader users',
                    line
                )
            
            # Check for tabIndex > 0
            tabindex_match = re.search(r'tabIndex={?(\d+)}?', line)
            if tabindex_match and int(tabindex_match.group(1)) > 0:
                self._add_issue(
                    filepath, i, 'warning', 'no-positive-tabindex',
                    'Positive tabIndex values can cause focus order issues',
                    line
                )
    
    def _check_css(self, lines: List[str], filepath: str):
        """Check CSS files for accessibility issues."""
        for i, line in enumerate(lines, 1):
            line_lower = line.strip().lower()
            
            # Check for outline: none without alternative focus indicator
            if 'outline:' in line_lower and 'none' in line_lower:
                # Check if it's on :focus
                if ':focus' in line_lower or i > 1 and ':focus' in lines[i-2].lower():
                    self._add_issue(
                        filepath, i, 'warning', 'focus-visible',
                        'Removing outline on :focus requires alternative visible focus indicator (WCAG 2.4.7)',
                        line
                    )
            
            # Check for potential color contrast issues (basic heuristic)
            # This is a simplified check - full contrast checking requires color analysis
            color_match = re.search(r'color:\s*#([0-9a-f]{3,6})', line_lower)
            bg_match = re.search(r'background(?:-color)?:\s*#([0-9a-f]{3,6})', line_lower)
            
            if color_match and bg_match:
                # Light colors on light backgrounds or dark on dark might be issues
                color = color_match.group(1)
                bg = bg_match.group(1)
                if self._similar_lightness(color, bg):
                    self._add_issue(
                        filepath, i, 'warning', 'color-contrast',
                        'Potential color contrast issue - verify 4.5:1 ratio for text (WCAG 1.4.3)',
                        line
                    )
    
    def _similar_lightness(self, color1: str, color2: str) -> bool:
        """Simple heuristic to check if two colors might have similar lightness."""
        def hex_to_lightness(hex_color: str) -> int:
            # Expand 3-digit hex to 6-digit
            if len(hex_color) == 3:
                hex_color = ''.join([c*2 for c in hex_color])
            # Simple average of RGB values
            r = int(hex_color[0:2], 16)
            g = int(hex_color[2:4], 16)
            b = int(hex_color[4:6], 16)
            return (r + g + b) // 3
        
        l1 = hex_to_lightness(color1)
        l2 = hex_to_lightness(color2)
        
        # If both are light (>180) or both are dark (<75)
        return (l1 > 180 and l2 > 180) or (l1 < 75 and l2 < 75)


def format_output(issues: List[Issue], format: str = 'text') -> str:
    """Format issues for output."""
    if format == 'json':
        return json.dumps([asdict(issue) for issue in issues], indent=2)
    
    # Text format
    output = []
    if not issues:
        return "✅ No accessibility issues found!"
    
    output.append(f"\n🔍 Found {len(issues)} accessibility issue(s):\n")
    
    # Group by file
    issues_by_file: Dict[str, List[Issue]] = {}
    for issue in issues:
        if issue.file not in issues_by_file:
            issues_by_file[issue.file] = []
        issues_by_file[issue.file].append(issue)
    
    for file, file_issues in issues_by_file.items():
        output.append(f"\n📄 {file}")
        output.append("─" * 80)
        
        for issue in file_issues:
            severity_icon = "❌" if issue.severity == "error" else "⚠️"
            output.append(f"{severity_icon} Line {issue.line}: {issue.message}")
            output.append(f"   Rule: {issue.rule}")
            output.append(f"   Code: {issue.code_snippet}")
            output.append("")
    
    # Summary
    errors = sum(1 for i in issues if i.severity == 'error')
    warnings = sum(1 for i in issues if i.severity == 'warning')
    output.append("─" * 80)
    output.append(f"📊 Summary: {errors} error(s), {warnings} warning(s)\n")
    
    return "\n".join(output)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python check_wcag.py <file1> [file2] ... [--json]")
        print("\nExample:")
        print("  python check_wcag.py src/components/Button.tsx")
        print("  python check_wcag.py src/**/*.tsx --json")
        sys.exit(1)
    
    files = [arg for arg in sys.argv[1:] if not arg.startswith('--')]
    format_json = '--json' in sys.argv
    
    checker = WCAGChecker()
    all_issues = []
    
    for filepath in files:
        issues = checker.check_file(filepath)
        all_issues.extend(issues)
    
    output_format = 'json' if format_json else 'text'
    print(format_output(all_issues, output_format))
    
    # Exit with error code if errors found
    errors = sum(1 for i in all_issues if i.severity == 'error')
    sys.exit(1 if errors > 0 else 0)


if __name__ == '__main__':
    main()
