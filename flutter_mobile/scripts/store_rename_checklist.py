"""Print the store-rename checklist against the current tree (read-only)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CHECKS = [
    ("Android applicationId", ROOT / "android/app/build.gradle.kts", "com.medichain.medichain_mobile"),
    ("Android namespace", ROOT / "android/app/build.gradle.kts", 'namespace = "com.medichain.medichain_mobile"'),
    ("Firebase package", ROOT / "android/app/google-services.json", '"package_name": "com.medichain.medichain_mobile"'),
    ("iOS bundle", ROOT / "ios/Runner.xcodeproj/project.pbxproj", "com.medichain.medichainMobile"),
]


def main() -> None:
    print("Store rename checklist (read-only)")
    print("Target when approved: com.medclues.app")
    print("-" * 60)
    for label, path, needle in CHECKS:
        text = path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""
        still_old = needle in text
        status = "STILL_OLD" if still_old else "CHANGED_OR_MISSING"
        print(f"{status:18} {label}: {path.relative_to(ROOT)}")
    print("-" * 60)
    print("Do not change IDs until Firebase + store approval is recorded.")
    print("See docs/enterprise/STORE_PACKAGE_RENAME_STATUS.md")


if __name__ == "__main__":
    main()
