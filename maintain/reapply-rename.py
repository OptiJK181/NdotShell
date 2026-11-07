#!/usr/bin/env python3
"""Re-apply the SekaiPop -> NdotShell rename to everything git tracks.

Run after merging upstream SekaiPop into this fork: it moves the files and
rewrites the strings upstream still names after SekaiPop, so the codebase
stays entirely under NdotShell naming. Idempotent: running it on an
already-renamed tree changes nothing.

Usage:
    python3 maintain/reapply-rename.py            # do the rename
    python3 maintain/reapply-rename.py --check    # only report what would change

What it does:
  1. renames tracked paths whose names contain a "sekaipop" token (any case
     variant). The tracked shell folder is one of them.
  2. rewrites tokens inside text files it can decode as UTF-8, in this order:
       SEKAIPOP -> NDOTSHELL       env vars
       SekaiPop -> NdotShell       display / product name
       Sekaipop -> Ndotshell       file names (color schemes, etc.)
       sekaipop -> ndotshell       paths, ids, namespaces
     "SekaiPopup" (a widget class that happens to contain "SekaiPop") is
     protected with a placeholder and survives untouched.
  3. reports any leftover case-insensitive occurrence (expect none); exits 1
     when some remain.

Run `git status` afterwards: `git mv` stages the renames, nothing else is
committed for you.
"""

from __future__ import annotations

import subprocess
import sys

TOKENS = [  # longest/case-specific first; applied in this order
    ("SEKAIPOP", "NDOTSHELL"),
    ("SekaiPop", "NdotShell"),
    ("Sekaipop", "Ndotshell"),
    ("sekaipop", "ndotshell"),
]
PROTECTED = ("SekaiPopup",)  # widget class name, not the brand
PROTECT_MARK = "__NPOPUP__"


def repo_root() -> str:
    return subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
    ).stdout.strip()


ROOT = repo_root()


def tracked() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z"], capture_output=True, text=True, check=True
    ).stdout
    return [p for p in out.split("\0") if p]


SELF = "maintain/reapply-rename.py"  # the tool must not rename or rewrite itself


def excludes(path: str) -> bool:
    return path == SELF


def rename_part(part: str) -> str:
    for token in PROTECTED:
        part = part.replace(token, PROTECT_MARK)
    for old, new in TOKENS:
        part = part.replace(old, new)
    for token in PROTECTED:
        part = part.replace(PROTECT_MARK, token)
    return part


def read_text(path: str) -> str | None:
    try:
        with open(path, "rb") as fh:
            return fh.read().decode()
    except (UnicodeDecodeError, FileNotFoundError, IsADirectoryError, PermissionError):
        return None  # binary or unreadable: leave alone


def write_text(path: str, text: str) -> None:
    with open(path, "wb") as fh:
        fh.write(text.encode())


def apply_rename(text: str) -> str:
    for token in PROTECTED:
        text = text.replace(token, PROTECT_MARK)
    for old, new in TOKENS:
        text = text.replace(old, new)
    for token in PROTECTED:
        text = text.replace(PROTECT_MARK, token)
    return text


def rename_paths(files: list[str], apply: bool) -> list[tuple[str, str]]:
    moved: list[tuple[str, str]] = []
    planned = {p for p in files if not excludes(p)}
    for path in sorted(planned):
        new = "/".join(rename_part(p) for p in path.split("/"))
        if new == path:
            continue
        if new in planned:
            print(f"SKIP (target exists): {path}")
            continue
        if apply:
            import os
            parent = "/".join(new.split("/")[:-1])
            if parent:
                os.makedirs(f"{ROOT}/{parent}", exist_ok=True)
            subprocess.run(["git", "mv", path, new], check=True)
        planned.discard(path)
        planned.add(new)
        moved.append((path, new))
    return moved


def rewrite_contents(files: list[str], apply: bool) -> list[str]:
    edited = []
    for path in files:
        if excludes(path):
            continue
        text = read_text(f"{ROOT}/{path}")
        if text is None:
            continue
        out = apply_rename(text)
        if out != text:
            if apply:
                write_text(f"{ROOT}/{path}", out)
            edited.append(path)
    return edited


def leftovers(files: list[str]) -> list[str]:
    hits = []
    for path in files:
        if excludes(path):
            continue
        text = read_text(f"{ROOT}/{path}")
        if text is None:
            continue
        stripped = text
        for token in PROTECTED:
            stripped = stripped.replace(token, "")
        if "sekaipop" in stripped.lower():
            hits.append(path)
    return hits


def main() -> None:
    do_apply = "--check" not in sys.argv[1:]
    files = tracked()

    moved = rename_paths(files, do_apply)
    files = tracked()
    edited = rewrite_contents(files, do_apply)

    if moved:
        print(f"moved {len(moved)} path(s):")
        for old, new in moved[:30]:
            print(f"  {old} -> {new}")
        if len(moved) > 30:
            print(f"  ... and {len(moved) - 30} more")
    if edited:
        print(f"edited {len(edited)} file(s)")
    if not moved and not edited:
        print("nothing to do: the tree is already renamed")

    bad = leftovers(tracked())
    if bad:
        print(f"\nWARNING: case-insensitive 'sekaipop' remains in {len(bad)} file(s):")
        for p in bad:
            print(f"  {p}")
        sys.exit(1)
    print("leftover check: clean")


if __name__ == "__main__":
    main()
