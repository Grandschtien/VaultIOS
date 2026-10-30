#!/usr/bin/env python3
"""Checks that every element id in Maestro flows exists in AccessibilityIdentifier.swift.

Usage: check-ids.py <flow.yaml> [...]
Exit code 1 if an unknown id is found.
"""
import re
import sys
from pathlib import Path

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "Vault/Common").is_dir())
SWIFT = ROOT / "Vault/Common/Accessibility/AccessibilityIdentifier.swift"
# Suffixes added by shared components (TextFieldParts, MultilineInputParts, PeriodPicker, CategoryEditor).
SUFFIXES = r"(\.(input|additionalLabel|rightAccessory|helpText|title|value|counter|option\.[0-9]+))?"
# Ids of system UI the app does not own (iOS sheets and alerts).
SYSTEM_IDS = {"xmark"}


def known_patterns():
    patterns = []
    for literal in re.findall(r'"([^"]+)"', SWIFT.read_text()):
        if literal.startswith("\\("):
            continue  # parts like "\(identifier).input" are covered by SUFFIXES
        parts = re.split(r"\\\([^)]*\)", literal)
        body = "[A-Za-z0-9_.-]+".join(re.escape(p) for p in parts)
        patterns.append(re.compile(f"^{body}{SUFFIXES}$"))
    return patterns


def flow_ids(text):
    # Ids are `id:` values; a regex id like `a\\.b|c\\.d` is split into its alternatives.
    for value in re.findall(r"^\s*-?\s*id:\s*[\"']?([^\"'\n#]+?)[\"']?\s*$", text, re.MULTILINE):
        for token in value.replace("\\\\.", ".").replace("\\.", ".").split("|"):
            if "*" in token or "${" in token:
                continue  # wildcard or variable: cannot be checked statically
            yield token.strip()


def main(paths):
    patterns = known_patterns()
    unknown = 0
    for path in paths:
        for token in sorted(set(flow_ids(Path(path).read_text()))):
            if token not in SYSTEM_IDS and not any(p.match(token) for p in patterns):
                print(f"{path}: unknown id `{token}`")
                unknown += 1
    print("OK" if unknown == 0 else f"{unknown} unknown id(s)")
    return 1 if unknown else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
