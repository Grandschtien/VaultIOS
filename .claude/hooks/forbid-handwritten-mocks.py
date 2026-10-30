#!/usr/bin/env python3
"""PreToolUse hook: rejects hand-written test doubles and edits of Sourcery output in VaultTests."""

import json
import re
import sys

DOUBLE_NAME = re.compile(
    r"\b(?:class|struct|actor|enum)\s+\w*(?:Mock|Spy|Stub|Fake|Dummy)\b"
)
APP_CONFORMANCE = re.compile(
    r"\b(?:class|struct|actor)\s+\w+\s*:\s*[^{]*?\b\w*"
    r"(?:Protocol|Logic|Handler|Servicing|Providing|Tracking|Resolving|Output|Storage|Controlling|Converting|Logging|Reloading)\b"
)
# The only hand-written doubles allowed: shared mocks every test must reuse.
SHARED_MOCKS = (
    "/VaultTests/Support/Mocks/AsyncNetworkClientMock.swift",
    "/VaultTests/Support/Mocks/NotificationCenterMock.swift",
)


def reject(message):
    print(message, file=sys.stderr)
    sys.exit(2)


payload = json.load(sys.stdin)
tool_input = payload.get("tool_input", {})
path = tool_input.get("file_path", "")

if "/VaultTests/" not in path or not path.endswith(".swift"):
    sys.exit(0)

if "/VaultTests/Generated/" in path:
    reject(
        "VaultTests/Generated is produced by Sourcery. Do not edit it: mark the protocol with "
        "`// sourcery: AutoMockable` and run `/opt/homebrew/bin/sourcery --config .sourcery.yml --disableCache`."
    )

if path.endswith(SHARED_MOCKS):
    sys.exit(0)

if payload.get("tool_name") == "Write":
    texts = [tool_input.get("content", "")]
elif payload.get("tool_name") == "MultiEdit":
    texts = [edit.get("new_string", "") for edit in tool_input.get("edits", [])]
else:
    texts = [tool_input.get("new_string", "")]

for text in texts:
    match = DOUBLE_NAME.search(text) or APP_CONFORMANCE.search(text)
    if match:
        reject(
            f"Hand-written test double is not allowed in VaultTests: `{match.group(0).strip()}`. "
            "Use the Sourcery mock `<ProtocolName>Mock` from VaultTests/Generated/AutoMockable.generated.swift "
            "(see .claude/skills/unit-tests/SKILL.md). Complex test data goes into "
            "VaultTests/Support/Fixtures as an enum with static make functions."
        )

sys.exit(0)
