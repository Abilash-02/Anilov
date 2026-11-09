#!/usr/bin/env python3
"""
tools/patch_android.py
Idempotent Android project patcher for ANIZEN:
1. Sets app label to 'ANIZEN' in AndroidManifest.xml
2. Ensures INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, and media permissions are declared
3. Ensures cleartext traffic is disabled (android:usesCleartextTraffic="false")
4. Configures core library desugaring in android/app/build.gradle[.kts] for notifications/workmanager
5. Ensures compileSdk is set to 37 and suppresses unsupported compile SDK warnings
"""

import os
import re
import sys
from pathlib import Path

MANIFEST_PATH = Path("android/app/src/main/AndroidManifest.xml")
GRADLE_GROOVY_PATH = Path("android/app/build.gradle")
GRADLE_KTS_PATH = Path("android/app/build.gradle.kts")
GRADLE_PROPERTIES_PATH = Path("android/gradle.properties")

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
        name_match = re.search(r'android:name="([^"]+)"', perm)
        if not name_match:
            continue
        perm_name = name_match.group(1)
        if f'android:name="{perm_name}"' not in content:
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

    # 3. Set application label to 'ANIZEN'
    app_tag_match = re.search(r'<application\b([^>]*)>', content, re.DOTALL)
    if app_tag_match:
        app_tag_full = app_tag_match.group(0)
        app_attrs = app_tag_match.group(1)

        new_attrs = app_attrs
        if 'android:label=' in new_attrs:
            new_attrs = re.sub(r'android:label="[^"]*"', 'android:label="ANIZEN"', new_attrs)
        else:
            new_attrs = ' android:label="ANIZEN"' + new_attrs

        if 'android:usesCleartextTraffic=' in new_attrs:
            new_attrs = re.sub(r'android:usesCleartextTraffic="[^"]*"', 'android:usesCleartextTraffic="false"', new_attrs)
        else:
            new_attrs = ' android:usesCleartextTraffic="false"' + new_attrs

        new_app_tag = f"<application{new_attrs}>"
        content = content.replace(app_tag_full, new_app_tag, 1)

    # Also ensure any activity-level label does not override application label
    activity_matches = list(re.finditer(r'<activity\b([^>]*)>', content, re.DOTALL))
    for act in activity_matches:
        act_full = act.group(0)
        act_attrs = act.group(1)
        if 'android:label=' in act_attrs:
            new_act_attrs = re.sub(r'android:label="[^"]*"', 'android:label="ANIZEN"', act_attrs)
            content = content.replace(act_full, f"<activity{new_act_attrs}>", 1)

    # 4. Ensure OAuth deep link intent-filter exists in MainActivity
    if 'android:scheme="anilov"' not in content:
        activity_match = re.search(r'(<activity\b[^>]*>)', content)
        if activity_match:
            oauth_intent_filter = """
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="anilov" android:host="auth" />
            </intent-filter>"""
            idx = activity_match.end()
            content = content[:idx] + oauth_intent_filter + content[idx:]
            print("Added OAuth intent-filter (anilov://auth) to MainActivity")

    if content != original:
        MANIFEST_PATH.write_text(content, encoding="utf-8")
        print(f"Successfully patched {MANIFEST_PATH}")
        return True
    else:
        print(f"{MANIFEST_PATH} is already up to date (idempotent check passed).")
        return False

def patch_gradle_properties():
    if not GRADLE_PROPERTIES_PATH.exists():
        print("android/gradle.properties not found; skipping properties patch.")
        return False

    content = GRADLE_PROPERTIES_PATH.read_text(encoding="utf-8")
    original = content

    if "android.suppressUnsupportedCompileSdk" not in content:
        content += "\nandroid.suppressUnsupportedCompileSdk=37\n"
        print("Added android.suppressUnsupportedCompileSdk=37 to gradle.properties")

    if content != original:
        GRADLE_PROPERTIES_PATH.write_text(content, encoding="utf-8")
        print(f"Successfully patched {GRADLE_PROPERTIES_PATH}")
        return True
    return False

def patch_gradle():
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

    # 1. Ensure compileSdk is 37 for modern notification dependencies
    if is_kts:
        content = re.sub(
            r'compileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)',
            'compileSdk = 37',
            content
        )
    else:
        content = re.sub(
            r'compileSdk(?:Version)?\s*(?:=\s*)?(?:flutter\.compileSdkVersion|\d+)',
            'compileSdkVersion = 37',
            content
        )

    # 2. Ensure coreLibraryDesugaringEnabled is true in compileOptions
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

    # 3. Ensure desugar_jdk_libs dependency is present
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

def patch_gradle_wrapper():
    wrapper_props = Path("android/gradle/wrapper/gradle-wrapper.properties")
    if not wrapper_props.exists():
        print("android/gradle/wrapper/gradle-wrapper.properties not found; skipping wrapper patch.")
        return False

    content = wrapper_props.read_text(encoding="utf-8")
    original = content

    # Replace GitHub releases mirror with official services.gradle.org to avoid GitHub 504 Gateway Timeouts
    if "github.com/gradle/gradle-distributions" in content:
        content = content.replace("https\\://github.com/gradle/gradle-distributions/releases/download/v", "https\\://services.gradle.org/distributions/gradle-")
        content = content.replace("https://github.com/gradle/gradle-distributions/releases/download/v", "https://services.gradle.org/distributions/gradle-")
        content = content.replace("https\\://github.com/gradle/gradle-distributions/releases/download/", "https\\://services.gradle.org/distributions/")
        content = content.replace("https://github.com/gradle/gradle-distributions/releases/download/", "https://services.gradle.org/distributions/")
        print("Replaced GitHub Gradle mirror with official services.gradle.org")

    if "retries=" not in content:
        content += "\nretries=5\nnetworkTimeout=60000\n"
        print("Added retries=5 and networkTimeout=60000 to gradle-wrapper.properties")

    if content != original:
        wrapper_props.write_text(content, encoding="utf-8")
        print(f"Successfully patched {wrapper_props}")
        return True
    return False

def patch_plugin_proguards():
    """
    Patches deprecated `proguard-android.txt` to `proguard-android-optimize.txt`
    in hosted pub cache plugins (e.g., flutter_inappwebview_android) to support modern AGP 8+/9+.
    """
    pub_cache = os.environ.get("PUB_CACHE")
    paths_to_check = []
    if pub_cache:
        paths_to_check.append(Path(pub_cache))
    paths_to_check.append(Path.home() / ".pub-cache")

    patched_count = 0
    for base in paths_to_check:
        hosted = base / "hosted" / "pub.dev"
        if not hosted.exists():
            continue
        for gradle_file in hosted.glob("*/android/build.gradle"):
            try:
                content = gradle_file.read_text(encoding="utf-8")
                if "getDefaultProguardFile('proguard-android.txt')" in content:
                    content = content.replace(
                        "getDefaultProguardFile('proguard-android.txt')",
                        "getDefaultProguardFile('proguard-android-optimize.txt')"
                    )
                    gradle_file.write_text(content, encoding="utf-8")
                    print(f"Patched proguard rule in {gradle_file.parent.parent.name}")
                    patched_count += 1
            except Exception as e:
                print(f"Warning: could not patch {gradle_file}: {e}")

    print(f"Patched {patched_count} plugin build.gradle file(s) for modern AGP proguard compatibility.")

def main():
    print("Running patch_android.py...")
    patch_manifest()
    patch_gradle_properties()
    patch_gradle()
    patch_gradle_wrapper()
    patch_plugin_proguards()
    print("Done.")

if __name__ == "__main__":
    main()
