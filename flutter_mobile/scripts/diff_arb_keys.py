"""Print ARB keys present in EN but missing from TE/HI."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "l10n"


def keys(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    found = set(re.findall(r'^\s*"([^"]+)":', text, re.M))
    return {k for k in found if not k.startswith("@")}


def main() -> None:
    en = keys(ROOT / "app_en.arb")
    te = keys(ROOT / "app_te.arb")
    hi = keys(ROOT / "app_hi.arb")
    miss_te = sorted(en - te)
    miss_hi = sorted(en - hi)
    print(f"en={len(en)} te={len(te)} hi={len(hi)}")
    print(f"missing_te={len(miss_te)} missing_hi={len(miss_hi)}")
    print("TE_MISSING")
    for k in miss_te:
        print(k)
    print("HI_MISSING")
    for k in miss_hi:
        print(k)


if __name__ == "__main__":
    main()
