#!/usr/bin/env python3
"""Checks that every element id in QA scenarios exists in AccessibilityIdentifier.swift.

Usage: check-ids.py <scenario.md> [...]
Exit code 1 if an unknown id is found.
"""
import re
import sys
from pathlib import Path

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "Vault/Common").is_dir())
SWIFT = ROOT / "Vault/Common/Accessibility/AccessibilityIdentifier.swift"
# Suffixes added by shared components (TextFieldParts, MultilineInputParts, PeriodPicker, CategoryEditor).
SUFFIXES = r"(\.(input|additionalLabel|rightAccessory|helpText|title|value|counter|option\.[0-9]+))?"


def known_patterns():
    patterns = []
    for literal in re.findall(r'"([^"]+)"', SWIFT.read_text()):
        if literal.startswith("\\("):
            continue  # parts like "\(identifier).input" are covered by SUFFIXES
        parts = re.split(r"\\\([^)]*\)", literal)
        body = "[A-Za-z0-9_.-]+".join(re.escape(p) for p in parts)
        patterns.append(re.compile(f"^{body}{SUFFIXES}$"))
    return patterns


def scenario_ids(text):
    # Ids are backticked tokens like `login.emailField` or `main.expenses.cell.0.0`.
    for token in re.findall(r"`([^`\s]+)`", text):
        if token.startswith(("$", "text:")) or "/" in token or token.endswith((".md", ".sh", ".py", ".swift", ".json")):
            continue
        if re.fullmatch(r"[a-z][A-Za-z]*(\.[A-Za-z0-9_-]+)+", token):
            yield token


def main(paths):
    patterns = known_patterns()
    unknown = 0
    for path in paths:
        for token in sorted(set(scenario_ids(Path(path).read_text()))):
            if not any(p.match(token) for p in patterns):
                print(f"{path}: unknown id `{token}`")
                unknown += 1
    print("OK" if unknown == 0 else f"{unknown} unknown id(s)")
    return 1 if unknown else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
