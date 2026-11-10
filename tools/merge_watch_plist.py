#!/usr/bin/env python3
"""Merge actool's partial Info.plist (icon entries) into the static Watch
Info.plist and write the result to the .app bundle.

Usage: merge_watch_plist.py <base-plist> <partial-plist> <output-plist>
"""
import plistlib
import sys

base_path, partial_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]

with open(base_path, "rb") as f:
    merged = plistlib.load(f)
with open(partial_path, "rb") as f:
    partial = plistlib.load(f)

merged.update(partial)

with open(out_path, "wb") as f:
    plistlib.dump(merged, f)

print("merged Info.plist keys:", sorted(merged.keys()))
