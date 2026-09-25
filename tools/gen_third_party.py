#!/usr/bin/env python3
"""从 pubspec.lock 与 pub 缓存生成第三方组件与协议清单。

为什么不用手写清单
------------------
仓库里原先有一份手写的开源项目清单（open_source_screen.dart 里 18 行），
它已经不准了：既列着一个从未被调用的 flutter_local_notifications，
也漏掉了 meta / http_parser 这类间接依赖。

手写的清单一定会腐烂。这个脚本从 pubspec.lock（唯一事实来源）生成，
每次 CI 刷新一次，不可能漏、也不可能多。

用法
----
    python3 tools/gen_third_party.py [--cache <pub缓存目录>]
"""

from __future__ import annotations

import argparse
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 协议判定：按特异性从高到低匹配关键词
LICENSE_PATTERNS = [
    ("AGPL-3.0", r"GNU AFFERO GENERAL PUBLIC LICENSE"),
    ("GPL-3.0", r"GNU GENERAL PUBLIC LICENSE\s+Version 3"),
    ("GPL-2.0", r"GNU GENERAL PUBLIC LICENSE\s+Version 2"),
    ("LGPL-3.0", r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 3"),
    ("Apache-2.0", r"Apache License\s*,?\s*Version 2\.0"),
    ("MPL-2.0", r"Mozilla Public License Version 2\.0"),
    ("BSD-3-Clause", r"Redistributions of source code must retain|3-Clause BSD"),
    ("BSD-2-Clause", r"BSD 2-Clause"),
    ("MIT", r"Permission is hereby granted, free of charge"),
    ("Unlicense", r"This is free and unencumbered software"),
    ("CC0-1.0", r"CC0 1\.0 Universal"),
    ("ISC", r"ISC License"),
]


def parse_lock(path: str) -> list[dict]:
    """极简 pubspec.lock 解析。只取我们需要的几个字段。"""
    pkgs: list[dict] = []
    cur: dict | None = None
    section = None

    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            m = re.match(r"^  (\w[\w\-]*):$", line)
            if m:
                if cur:
                    pkgs.append(cur)
                cur = {"name": m.group(1)}
                section = None
                continue
            if cur is None:
                continue
            m = re.match(r"^    (\w+):\s*(.*)$", line)
            if m:
                section = m.group(1)
                value = m.group(2).strip().strip('"')
                if section in ("dependency", "source", "version"):
                    cur[section] = value
                continue
            m = re.match(r"^      (\w+):\s*(.*)$", line)
            if m and section == "description":
                value = m.group(2).strip().strip('"')
                if m.group(1) == "name":
                    cur["pkg"] = value
                elif m.group(1) == "url":
                    cur["url"] = value

    if cur:
        pkgs.append(cur)
    return [p for p in pkgs if p.get("source") == "hosted"]


def detect_license(text: str) -> str:
    for name, pattern in LICENSE_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return name
    return "未知（请人工确认）"


def find_license(cache: str, name: str, version: str) -> tuple[str, str]:
    base = os.path.join(cache, f"{name}-{version}")
    for candidate in glob.glob(os.path.join(base, "LICENSE*")) + glob.glob(
        os.path.join(base, "license*")
    ):
        try:
            with open(candidate, encoding="utf-8", errors="replace") as f:
                return detect_license(f.read()), candidate
        except OSError:
            continue
    return "未找到 LICENSE 文件", ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=os.path.expanduser("~/.pub-cache/hosted/pub.dev"))
    ap.add_argument("--out", default=os.path.join(ROOT, "docs", "third-party.md"))
    args = ap.parse_args()

    lock = os.path.join(ROOT, "pubspec.lock")
    if not os.path.exists(lock):
        print(f"找不到 {lock}（需要先 flutter pub get）")
        return 1

    pkgs = parse_lock(lock)
    if not pkgs:
        print("pubspec.lock 里没有解析到任何 hosted 包")
        return 1

    rows = []
    unknown = []
    for p in sorted(pkgs, key=lambda x: x.get("pkg", x["name"])):
        name = p.get("pkg", p["name"])
        version = p.get("version", "?")
        kind = p.get("dependency", "?")
        lic, _ = find_license(args.cache, name, version)
        if "未知" in lic or "未找到" in lic:
            unknown.append(f"{name} {version}")
        rows.append((name, version, kind, lic))

    out_dir = os.path.dirname(args.out)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    direct = [r for r in rows if r[2] == "direct main"]
    dev = [r for r in rows if r[2] == "direct dev"]
    transitive = [r for r in rows if r[2] == "transitive"]

    lines = [
        "# 第三方组件与协议清单",
        "",
        "> 本文件由 `tools/gen_third_party.py` 从 `pubspec.lock` 与 pub 缓存自动生成，",
        "> **请勿手工编辑** —— 手写的清单一定会与依赖实际状态脱节。",
        "",
        f"- 直接依赖：{len(direct)} 个",
        f"- 开发依赖：{len(dev)} 个",
        f"- 间接依赖：{len(transitive)} 个",
        f"- 合计：{len(rows)} 个",
        "",
        "应用内的完整协议原文由 Flutter 框架在构建时收集，",
        "界面上的「开源许可」页直接调用 `showLicensePage()` 展示，",
        "因此不会与依赖的实际内容不一致。",
        "",
    ]

    def table(title: str, items: list[tuple[str, str, str, str]]) -> None:
        lines.append(f"## {title}")
        lines.append("")
        if not items:
            lines.append("（无）")
            lines.append("")
            return
        lines.append("| 组件 | 版本 | 协议 |")
        lines.append("|---|---|---|")
        for name, version, _kind, lic in items:
            lines.append(f"| `{name}` | {version} | {lic} |")
        lines.append("")

    table("直接依赖", direct)
    table("开发依赖", dev)
    table("间接依赖", transitive)

    if unknown:
        lines.append("## 需要人工确认")
        lines.append("")
        lines.append("以下组件未能自动识别协议，请人工核对：")
        lines.append("")
        for u in unknown:
            lines.append(f"- {u}")
        lines.append("")

    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"✓ 已生成 {os.path.relpath(args.out, ROOT)}（{len(rows)} 个组件）")
    if unknown:
        print(f"  ⚠ {len(unknown)} 个组件协议未能自动识别")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
