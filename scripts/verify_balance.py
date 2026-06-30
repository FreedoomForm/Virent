#!/usr/bin/env python3
"""
Verify brace/paren/bracket balance in Dart files.
Uses a Dart-aware tokenizer that handles:
  - Line comments (//)
  - Block comments (/* */)
  - String interpolation ${...} with balanced counting
  - Single-quoted strings ('...') with escape sequences
  - Double-quoted strings ("...")
  - Triple-quoted strings (''' ''' and """ """)
  - Raw strings (r'...')
"""

import os
import sys


class Tokenizer:
    """Tokenizes Dart source, tracking string/comment state."""
    
    def __init__(self, content):
        self.s = content
        self.i = 0
        self.n = len(content)
        self.counts = {'(': 0, ')': 0, '[': 0, ']': 0, '{': 0, '}': 0}
    
    def peek(self, offset=0):
        idx = self.i + offset
        return self.s[idx] if idx < self.n else ''
    
    def advance(self, n=1):
        self.i += n
    
    def at_end(self):
        return self.i >= self.n
    
    def parse(self):
        """Parse the entire content, counting braces/parens/brackets in code."""
        while not self.at_end():
            c = self.peek()
            nxt = self.peek(1)
            
            if c == '/' and nxt == '/':
                self._skip_line_comment()
            elif c == '/' and nxt == '*':
                self._skip_block_comment()
            elif c == 'r' and (nxt == "'" or nxt == '"'):
                # Raw string
                self.advance()  # skip r
                self._skip_raw_string()
            elif c == "'":
                if nxt == "'" and self.peek(2) == "'":
                    self._skip_triple_sq_string()
                else:
                    self._skip_sq_string()
            elif c == '"':
                if nxt == '"' and self.peek(2) == '"':
                    self._skip_triple_dq_string()
                else:
                    self._skip_dq_string()
            elif c in self.counts:
                self.counts[c] += 1
                self.advance()
            else:
                self.advance()
    
    def _skip_line_comment(self):
        while not self.at_end() and self.peek() != '\n':
            self.advance()
    
    def _skip_block_comment(self):
        self.advance(2)  # skip /*
        while not self.at_end():
            if self.peek() == '*' and self.peek(1) == '/':
                self.advance(2)
                return
            self.advance()
    
    def _skip_raw_string(self):
        # Raw string: r'...' or r"..." (no escapes)
        quote = self.peek()
        if self.peek(1) == quote and self.peek(2) == quote:
            # Triple-quoted raw string
            self.advance(3)
            while not self.at_end():
                if self.peek() == quote and self.peek(1) == quote and self.peek(2) == quote:
                    self.advance(3)
                    return
                self.advance()
        else:
            self.advance()  # skip opening quote
            while not self.at_end():
                if self.peek() == quote:
                    self.advance()
                    return
                self.advance()
    
    def _skip_sq_string(self):
        # Single-quoted string with escapes and ${...} interpolation
        self.advance()  # skip opening '
        while not self.at_end():
            c = self.peek()
            if c == '\\':
                self.advance(2)
                continue
            elif c == '$' and self.peek(1) == '{':
                self.counts['{'] += 1  # count the { from ${
                self.advance(2)
                self._parse_interpolation()
                continue
            elif c == "'":
                self.advance()
                return
            else:
                self.advance()
    
    def _skip_dq_string(self):
        # Double-quoted string with escapes and ${...} interpolation
        self.advance()  # skip opening "
        while not self.at_end():
            c = self.peek()
            if c == '\\':
                self.advance(2)
                continue
            elif c == '$' and self.peek(1) == '{':
                self.counts['{'] += 1
                self.advance(2)
                self._parse_interpolation()
                continue
            elif c == '"':
                self.advance()
                return
            else:
                self.advance()
    
    def _skip_triple_sq_string(self):
        self.advance(3)  # skip '''
        while not self.at_end():
            if self.peek() == "'" and self.peek(1) == "'" and self.peek(2) == "'":
                self.advance(3)
                return
            c = self.peek()
            if c == '\\':
                self.advance(2)
                continue
            elif c == '$' and self.peek(1) == '{':
                self.counts['{'] += 1
                self.advance(2)
                self._parse_interpolation()
                continue
            else:
                self.advance()
    
    def _skip_triple_dq_string(self):
        self.advance(3)  # skip """
        while not self.at_end():
            if self.peek() == '"' and self.peek(1) == '"' and self.peek(2) == '"':
                self.advance(3)
                return
            c = self.peek()
            if c == '\\':
                self.advance(2)
                continue
            elif c == '$' and self.peek(1) == '{':
                self.counts['{'] += 1
                self.advance(2)
                self._parse_interpolation()
                continue
            else:
                self.advance()
    
    def _parse_interpolation(self):
        """Parse ${...} interpolation as code, with balanced braces.
        
        Dart's lexer treats the contents of ${...} as Dart code, but for
        compatibility with code generators that escape inner quotes within
        interpolation, we also accept `\\` as an escape sequence here.
        """
        # We've already consumed ${ — now parse code until matching }
        depth = 1  # we're inside one ${...}
        while not self.at_end() and depth > 0:
            c = self.peek()
            nxt = self.peek(1)
            
            if c == '\\':
                # Escape sequence — skip the next char
                self.advance(2)
                continue
            elif c == '/' and nxt == '/':
                self._skip_line_comment()
            elif c == '/' and nxt == '*':
                self._skip_block_comment()
            elif c == 'r' and (nxt == "'" or nxt == '"'):
                self.advance()
                self._skip_raw_string()
            elif c == "'":
                if nxt == "'" and self.peek(2) == "'":
                    self._skip_triple_sq_string()
                else:
                    self._skip_sq_string()
            elif c == '"':
                if nxt == '"' and self.peek(2) == '"':
                    self._skip_triple_dq_string()
                else:
                    self._skip_dq_string()
            elif c == '{':
                self.counts['{'] += 1
                depth += 1
                self.advance()
            elif c == '}':
                self.counts['}'] += 1
                depth -= 1
                self.advance()
                if depth == 0:
                    return
            elif c in self.counts:
                self.counts[c] += 1
                self.advance()
            else:
                self.advance()


def main():
    files = sys.argv[1:]
    if not files:
        pages_dir = '/home/z/my-project/virent-dart/mobile/lib/features/admin_web/pages'
        files = [
            'iot_page.dart', 'sms_logs_page.dart', 'tariffs_page.dart',
            'tariffs_subscriptions_page.dart', 'tariff_subtariffs_page.dart',
            'settings_drivers_page.dart', 'settings_scooter_groups_page.dart',
            'task_technicians_page.dart',
        ]
        files = [os.path.join(pages_dir, f) for f in files]
    
    all_balanced = True
    for path in files:
        if not os.path.exists(path):
            print(f"MISS: {path}")
            continue
        with open(path) as f:
            content = f.read()
        tk = Tokenizer(content)
        tk.parse()
        c = tk.counts
        diffs = {
            '()': c['('] - c[')'],
            '[]': c['['] - c[']'],
            '{}': c['{'] - c['}'],
        }
        status = "OK" if all(v == 0 for v in diffs.values()) else "UNBALANCED"
        if status != "OK":
            all_balanced = False
        print(f"{os.path.basename(path)}: {status}  ()={diffs['()']} []={diffs['[]']} {{}}={diffs['{}']}")
    
    print()
    print("All balanced" if all_balanced else "ISSUES FOUND")


if __name__ == "__main__":
    main()
