#!/usr/bin/env python3
"""
tools/patch_android.py
Idempotent Android project patcher for Anilov:
1. Sets app label to 'Anilov' in AndroidManifest.xml
2. Ensures INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, and media permissions are declared
3. Ensures cleartext traffic is disabled (android:usesCleartextTraffic="false")
4. Configures core library desugaring in android/app/build.gradle[.kts] for notifications/workmanager
"""

import os
import re
import sys
from pathlib import Path

MANIFEST_PATH = Path("android/app/src/main/AndroidManifest.xml")
GRADLE_GROOVY_PATH = Path("android/app/build.gradle")
GRADLE_KTS_PATH = Path("android/app/build.gradle.kts")

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
        '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />',
        '<uses-permission android:name="android.permission.VIBRATE" />',
        '<uses-permission android:name="android.permission.WAKE_LOCK" />',
        '<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />',
        '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />',
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

def patch_gradle():
    # Check for Groovy build.gradle or Kotlin build.gradle.kts
    target_path = None
    is_kts = False
    if GRADLE_GROOVY_PATH.exists():
        target_path = GRADLE_GROOVY_PATH
    elif GRADLE_KTS_PATH.exists():
        target_path = GRADLE_KTS_PATH
        is_kts = True
    else:
        print("Neither android/app/build.gradle nor build.gradle.kts found; skipping Gradle patch.")
        return False

    content = target_path.read_text(encoding="utf-8")
    original = content

    # 1. Ensure coreLibraryDesugaringEnabled is true in compileOptions
    if is_kts:
        if "isCoreLibraryDesugaringEnabled" not in content:
            compile_match = re.search(r'(compileOptions\s*\{)', content)
            if compile_match:
                idx = compile_match.end()
                content = content[:idx] + "\n        isCoreLibraryDesugaringEnabled = true" + content[idx:]
                print("Added isCoreLibraryDesugaringEnabled to compileOptions (kts)")
    else:
        if "coreLibraryDesugaringEnabled" not in content:
            compile_match = re.search(r'(compileOptions\s*\{)', content)
            if compile_match:
                idx = compile_match.end()
                content = content[:idx] + "\n        coreLibraryDesugaringEnabled true" + content[idx:]
                print("Added coreLibraryDesugaringEnabled to compileOptions (groovy)")

    # 2. Ensure desugar_jdk_libs dependency is present
    desugar_lib = "com.android.tools:desugar_jdk_libs:2.1.4"
    if desugar_lib not in content and "desugar_jdk_libs" not in content:
        dep_statement = (
            f'    coreLibraryDesugaring("{desugar_lib}")'
            if is_kts
            else f"    coreLibraryDesugaring '{desugar_lib}'"
        )
        if "dependencies {" in content:
            content = re.sub(
                r'(dependencies\s*\{)',
                r'\1\n' + dep_statement,
                content,
                count=1
            )
            print("Added desugar_jdk_libs to existing dependencies block")
        else:
            content += f"\n\ndependencies {{\n{dep_statement}\n}}\n"
            print("Appended dependencies block with desugar_jdk_libs")

    if content != original:
        target_path.write_text(content, encoding="utf-8")
        print(f"Successfully patched {target_path}")
        return True
    else:
        print(f"{target_path} is already up to date (idempotent check passed).")
        return False

def main():
    print("Running patch_android.py...")
    patch_manifest()
    patch_gradle()
    print("Done.")

if __name__ == "__main__":
    main()
