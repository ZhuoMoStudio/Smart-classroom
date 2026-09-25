#!/usr/bin/env python3
"""清理教材索引里的非学段顶层键。

背景
----
assets/textbook_index.json 的顶层键应当是「学段」：
    小学 / 小学（五•四学制） / 初中 / 初中（五•四学制） / 高中 / 大学
但实际数据里混进了一个明显是笔记的键：

    "学数学最重要的刷习题在这里": { ... 19 本 ... }

它不是学段，会作为一个假学段出现在「学段选择」界面上。

处理方式：搬移，不删除
--------------------
把非学段的顶层键整体搬到保留键 `_未分类` 下面。
之所以不直接删：这些条目是真实的教材数据，只是被放错了层级；
删掉就再也找不回来，而搬移是可逆的。应用侧会跳过以 `_` 开头的顶层键。

用法
----
    python3 tools/fix_textbook_index.py [--check]

--check 只报告不写入，退出码 1 表示存在需要清理的键。
"""

from __future__ import annotations

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDEX = os.path.join(ROOT, "assets", "textbook_index.json")

# 允许的学段写法。小学（五•四学制）这类带括号与间隔号的变体也要放行，
# 因此用「标准化后比对」而不是精确字符串匹配。
KNOWN_STAGES = {"小学", "初中", "高中", "大学"}

STAGE_CLEAN = re.compile(r"[（()）\s·•・]")
QUARANTINE = "_未分类"


def is_stage_key(key: str) -> bool:
    if key.startswith("_"):
        return True  # 保留键
    cleaned = STAGE_CLEAN.sub("", key)
    if cleaned in KNOWN_STAGES:
        return True
    for stage in KNOWN_STAGES:
        if cleaned.startswith(stage):
            return True
    return False


def count_leaves(node) -> int:
    if isinstance(node, list):
        return len(node)
    if isinstance(node, dict):
        return sum(count_leaves(v) for v in node.values())
    return 0


def main() -> int:
    check_only = "--check" in sys.argv

    if not os.path.exists(INDEX):
        print(f"找不到 {INDEX}")
        return 1

    with open(INDEX, encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, dict):
        print("索引顶层不是对象，放弃处理")
        return 1

    bad = [k for k in data if not is_stage_key(k)]

    if not bad:
        print("✓ 顶层键全部是合法学段，无需清理")
        return 0

    print(f"发现 {len(bad)} 个非学段顶层键：")
    for k in bad:
        print(f"  - {k!r}  （{count_leaves(data[k])} 本）")

    if check_only:
        print("\n(--check 模式，未写入)")
        return 1

    quarantine = data.get(QUARANTINE, {})
    for k in bad:
        quarantine[k] = data.pop(k)
    data[QUARANTINE] = quarantine

    with open(INDEX, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))

    total = sum(count_leaves(v) for k, v in data.items() if not k.startswith("_"))
    print(f"\n✓ 已搬移到 {QUARANTINE} 下；当前有效学段共 {total} 本")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
