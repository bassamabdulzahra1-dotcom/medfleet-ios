#!/usr/bin/env python3
"""Patch only the MedFleet app target signing settings in project.pbxproj."""
from __future__ import annotations

import argparse
from pathlib import Path


BUNDLE_ID = "net.medfleet.rep"
TEAM_ID = "DZW782KNRM"


def patch_settings(inner: str, profile_name: str) -> str:
    assignments = {
        "CODE_SIGN_STYLE": "Manual",
        "CODE_SIGN_IDENTITY": '"Apple Distribution"',
        '"CODE_SIGN_IDENTITY[sdk=iphoneos*]"': '"Apple Distribution"',
        "DEVELOPMENT_TEAM": TEAM_ID,
        "PROVISIONING_PROFILE_SPECIFIER": f'"{profile_name}"',
        "CODE_SIGNING_ALLOWED": "YES",
        "CODE_SIGNING_REQUIRED": "YES",
    }
    lines = inner.splitlines()
    kept: list[str] = []
    skip_keys = {
        "CODE_SIGN_STYLE",
        "CODE_SIGN_IDENTITY",
        '"CODE_SIGN_IDENTITY[sdk=iphoneos*]"',
        "DEVELOPMENT_TEAM",
        "PROVISIONING_PROFILE_SPECIFIER",
        "CODE_SIGNING_ALLOWED",
        "CODE_SIGNING_REQUIRED",
        "PROVISIONING_PROFILE",
    }
    for line in lines:
        stripped = line.strip()
        key = stripped.split(" = ", 1)[0] if " = " in stripped else ""
        if key in skip_keys or "PROVISIONING_PROFILE" in key:
            continue
        kept.append(line)
    indent = "				"
    extra = [f"{indent}{key} = {value};" for key, value in assignments.items()]
    body = "\n".join([ln for ln in kept if ln.strip()] + extra)
    return "\n" + body + "\n			"


def strip_shared_profile(inner: str) -> str:
    """SPM/Firebase cannot use the app's provisioning profile."""
    kept: list[str] = []
    for line in inner.splitlines():
        key = line.strip().split(" = ", 1)[0] if " = " in line.strip() else ""
        if "PROVISIONING_PROFILE" in key:
            continue
        kept.append(line)
    return "\n".join(kept) + ("\n" if kept else "")


def patch_pbxproj(text: str, profile_name: str) -> str:
    token = "buildSettings = {"
    out: list[str] = []
    idx = 0
    patched = 0
    stripped = 0
    while True:
        start = text.find(token, idx)
        if start < 0:
            out.append(text[idx:])
            break
        out.append(text[idx:start])
        i = start + len(token)
        depth = 1
        while i < len(text) and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        block = text[start:i]
        inner = block[len(token) : -1]
        if f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}" in inner:
            block = token + patch_settings(inner, profile_name) + "}"
            patched += 1
        else:
            cleaned = strip_shared_profile(inner)
            if cleaned != inner:
                stripped += 1
            block = token + cleaned + "}"
        out.append(block)
        idx = i
    if patched == 0:
        raise SystemExit("no MedFleet buildSettings block found in pbxproj")
    print(f"patched {patched} MedFleet buildSettings blocks, stripped profile from {stripped} other blocks")
    return "".join(out)


def write_export_options(path: Path, profile_name: str) -> None:
    path.write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
	<key>teamID</key>
	<string>{TEAM_ID}</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>{BUNDLE_ID}</key>
		<string>{profile_name}</string>
	</dict>
	<key>compileBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
"""
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--profile-name", required=True)
    parser.add_argument("--export-options", required=True)
    args = parser.parse_args()
    pbx = Path(args.project) / "project.pbxproj"
    text = pbx.read_text(encoding="utf-8")
    pbx.write_text(patch_pbxproj(text, args.profile_name), encoding="utf-8")
    write_export_options(Path(args.export_options), args.profile_name)
    print(f"wrote {args.export_options}")


if __name__ == "__main__":
    main()
