#!/usr/bin/env python3
"""Print real xcodebuild errors, not later CodeSign copy noise."""
from __future__ import annotations

import sys
from pathlib import Path

MARKERS = (
    ": error:",
    "fatal error:",
    "isn't code signed",
    "is not code signed",
    "requires a provisioning profile",
    "requires entitlements",
    "no signing certificate",
    "command codesign failed",
    "does not include the aps-environment",
    "doesn't include the aps-environment",
    "provisioning profile",
    "archive failed",
)


def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/xcarchive.log")
    if not path.exists():
        print(f"missing {path}")
        return
    lines = path.read_text(errors="replace").splitlines()
    hits = []
    for line in lines:
        low = line.lower()
        if any(m in low for m in MARKERS):
            if line.strip().startswith("Copy "):
                continue
            hits.append(line)
    print("================ REAL ERRORS ================")
    if hits:
        for line in hits[-80:]:
            print(line)
    else:
        print("NO MATCHES — last 40 lines:")
        for line in lines[-40:]:
            print(line)
    print("============================================")


if __name__ == "__main__":
    main()
