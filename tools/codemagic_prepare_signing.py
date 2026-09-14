#!/usr/bin/env python3
"""Pick the App Store profile for net.medfleet.rep and lock Manual signing."""
from __future__ import annotations

import glob
import os
import plistlib
import subprocess
import sys
from pathlib import Path

from patch_ios_signing import BUNDLE_ID, patch_pbxproj, write_export_options


def load_provision(path: str) -> dict:
    xml = subprocess.check_output(["security", "cms", "-D", "-i", path])
    return plistlib.loads(xml)


def find_profile() -> tuple[str, str | None]:
    paths = glob.glob(os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles/*.mobileprovision"))
    paths += glob.glob("/Users/builder/Library/MobileDevice/Provisioning Profiles/*.mobileprovision")
    candidates: list[tuple[int, str, str | None]] = []
    seen: set[str] = set()
    for path in sorted(set(paths)):
        if path in seen:
            continue
        seen.add(path)
        try:
            payload = load_provision(path)
        except Exception as exc:
            print(f"skip {path}: {exc}")
            continue
        entitlements = payload.get("Entitlements") or {}
        app_id = str(entitlements.get("application-identifier") or "")
        get_task = bool(entitlements.get("get-task-allow"))
        aps = entitlements.get("aps-environment")
        name = str(payload.get("Name") or "")
        print(f"profile name={name!r} app={app_id} get-task-allow={get_task} aps={aps}")
        if not (app_id.endswith("." + BUNDLE_ID) or app_id.endswith(BUNDLE_ID)):
            continue
        if get_task:
            continue
        score = 2 if aps == "production" else (1 if aps else 0)
        candidates.append((score, name, aps if isinstance(aps, str) else None))
    if not candidates:
        raise SystemExit("No App Store provisioning profile found for net.medfleet.rep")
    candidates.sort(reverse=True)
    score, name, aps = candidates[0]
    if score < 2:
        print("WARNING: selected profile is missing aps-environment=production (Push). Fetch profiles in Codemagic after enabling Push on the App ID.")
    return name, aps


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: codemagic_prepare_signing.py <MedFleet.xcodeproj> <export_options.plist>")
    project = Path(sys.argv[1])
    export_path = Path(sys.argv[2])
    name, aps = find_profile()
    print(f"USING PROFILE {name!r} aps={aps}")
    pbx = project / "project.pbxproj"
    pbx.write_text(patch_pbxproj(pbx.read_text(encoding="utf-8"), name), encoding="utf-8")
    write_export_options(export_path, name)
    Path("/tmp/cm_profile_name.txt").write_text(name, encoding="utf-8")


if __name__ == "__main__":
    main()
