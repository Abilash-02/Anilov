#!/usr/bin/env python3
"""
tools/patch_android.py
Idempotent Android project patcher for Anilov:
1. Sets app label to 'Anilov' in AndroidManifest.xml
2. Ensures INTERNET permission is declared
3. Ensures POST_NOTIFICATIONS permission is declared
4. Ensures cleartext traffic is disabled (android:usesCleartextTraffic="false")
"""

import os
import re
import sys
from pathlib import Path

MANIFEST_PATH = Path("android/app/src/main/AndroidManifest.xml")

def patch_manifest():
    if not MANIFEST_PATH.exists():
        print(f"Manifest not found at {MANIFEST_PATH}; skipping patch (will be applied in CI when android/ is created).")
        return False

    content = MANIFEST_PATH.read_text(encoding="utf-8")
    original = content

    # 1. Ensure permissions exist
    permissions = [
        '<uses-permission android:name="android.permission.INTERNET" />',
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
    ]

    for perm in permissions:
        # Match by permission name
        name_match = re.search(r'android:name="([^"]+)"', perm)
        if not name_match:
            continue
        perm_name = name_match.group(1)
        if f'android:name="{perm_name}"' not in content:
            # Insert right after <manifest ...>
            manifest_tag = re.search(r'(<manifest[^>]*>)', content)
            if manifest_tag:
                idx = manifest_tag.end()
                content = content[:idx] + f"\n    {perm}" + content[idx:]
                print(f"Added permission: {perm_name}")

    # 2. Ensure queries block exists for url_launcher (Android 11+)
    if '<queries>' not in content:
        queries_block = """
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
    </queries>"""
        manifest_tag = re.search(r'(<manifest[^>]*>)', content)
        if manifest_tag:
            idx = manifest_tag.end()
            content = content[:idx] + queries_block + content[idx:]
            print("Added <queries> block for url_launcher")

    # 3. Set application label to 'Anilov'
    # Match android:label="..." inside <application ...>
    app_tag_match = re.search(r'<application\b([^>]*)>', content, re.DOTALL)
    if app_tag_match:
        app_tag_full = app_tag_match.group(0)
        app_attrs = app_tag_match.group(1)

        new_attrs = app_attrs
        # Replace or add android:label="Anilov"
        if 'android:label=' in new_attrs:
            new_attrs = re.sub(r'android:label="[^"]*"', 'android:label="Anilov"', new_attrs)
        else:
            new_attrs = ' android:label="Anilov"' + new_attrs

        # Ensure android:usesCleartextTraffic="false"
        if 'android:usesCleartextTraffic=' in new_attrs:
            new_attrs = re.sub(r'android:usesCleartextTraffic="[^"]*"', 'android:usesCleartextTraffic="false"', new_attrs)
        else:
            new_attrs = ' android:usesCleartextTraffic="false"' + new_attrs

        new_app_tag = f"<application{new_attrs}>"
        content = content.replace(app_tag_full, new_app_tag, 1)

    if content != original:
        MANIFEST_PATH.write_text(content, encoding="utf-8")
        print(f"Successfully patched {MANIFEST_PATH}")
        return True
    else:
        print(f"{MANIFEST_PATH} is already up to date (idempotent check passed).")
        return False

def main():
    print("Running patch_android.py...")
    patch_manifest()
    print("Done.")

if __name__ == "__main__":
    main()
