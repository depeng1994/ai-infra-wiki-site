#!/usr/bin/env python3
"""Check that the MkDocs navigation and publishable Markdown stay in sync."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from urllib.parse import urldefrag, urlsplit

from mkdocs.config import load_config


LINK_RE = re.compile(r"!??\[[^\]]*\]\(([^)]+)\)")
EXCLUDED_PREFIXES = ("assets/", "examples/", "superpowers/")


def flatten_nav(value: object) -> list[str]:
    """Return every Markdown path referenced by a MkDocs nav object."""
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        paths: list[str] = []
        for item in value:
            paths.extend(flatten_nav(item))
        return paths
    if isinstance(value, dict):
        paths: list[str] = []
        for item in value.values():
            paths.extend(flatten_nav(item))
        return paths
    return []


def publishable_markdown(docs_root: Path) -> set[str]:
    return {
        path.relative_to(docs_root).as_posix()
        for path in docs_root.rglob("*.md")
        if not path.relative_to(docs_root).as_posix().startswith(EXCLUDED_PREFIXES)
    }


def markdown_link_targets(page: Path, docs_root: Path) -> list[tuple[str, str]]:
    targets: list[tuple[str, str]] = []
    for raw_target in LINK_RE.findall(page.read_text(encoding="utf-8")):
        target = raw_target.strip().strip("<>")
        parsed = urlsplit(urldefrag(target).url)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        if not parsed.path.endswith(".md"):
            continue
        resolved = (page.parent / parsed.path).resolve()
        try:
            relative = resolved.relative_to(docs_root.resolve()).as_posix()
        except ValueError:
            continue
        targets.append((relative, target))
    return targets


def nav_group_for_index(nav: object, index_path: str) -> list[str] | None:
    """Find the top-level nav group containing a chapter index page."""
    if not isinstance(nav, list):
        return None
    for item in nav:
        if not isinstance(item, dict):
            continue
        children = next(iter(item.values()), None)
        if not isinstance(children, list):
            continue
        paths = flatten_nav(children)
        if index_path in paths:
            return paths
    return None


def check(site_root: Path, docs_root: Path) -> list[str]:
    config = load_config(str(site_root / "mkdocs.yml"))
    nav = config.get("nav", [])
    nav_paths = set(flatten_nav(nav))
    docs_paths = publishable_markdown(docs_root)
    errors: list[str] = []

    for path in sorted(nav_paths - docs_paths):
        errors.append(f"导航目标不存在: {path}")
    for path in sorted(docs_paths - nav_paths):
        errors.append(f"文档未加入导航: {path}")

    for page in sorted(docs_root.glob("*/index.md")):
        links = markdown_link_targets(page, docs_root)
        for relative, target in links:
            if relative not in docs_paths:
                errors.append(f"章节首页链接不存在: {page.relative_to(docs_root)} -> {target}")

        index_path = page.relative_to(docs_root).as_posix()
        nav_group = nav_group_for_index(nav, index_path)
        if nav_group is None:
            errors.append(f"章节首页未找到对应导航分组: {index_path}")
            continue
        chapter_dir = page.parent.relative_to(docs_root).as_posix()
        index_links = [
            relative
            for relative, _ in links
            if Path(relative).parent.as_posix() == chapter_dir
        ]
        nav_chapter_pages = [
            relative
            for relative in nav_group
            if relative != index_path and Path(relative).parent.as_posix() == chapter_dir
        ]
        if index_links != nav_chapter_pages:
            errors.append(
                f"章节导航顺序不一致: {index_path}; "
                f"首页={index_links}; 导航={nav_chapter_pages}"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site-root", type=Path, required=True)
    parser.add_argument("--docs-root", type=Path, required=True)
    args = parser.parse_args()

    errors = check(args.site_root, args.docs_root)
    if errors:
        print("导航一致性检查失败:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("导航一致性检查通过")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
