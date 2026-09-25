#!/usr/bin/env python3
"""校验 .github/workflows/*.yml 是否是合法且结构合理的 Actions 工作流。

为什么需要这个
--------------
GitHub 对语法无效的 workflow 文件**不会让 push 报错**：
它只是安静地把那个文件标为失效、永不出现在 Actions 列表里。
本仓库就踩过这个坑 —— 一个 `run: |` 块里藏了顶格的 `- xxx` 续行，
YAML 于是在顶层看到 `-`、整个文件解析失败，
而当时的情况极容易让人误判为「workflow 跑了，只是没做事」。

因此这里做两层检查：
  1. 纯 YAML 能否解析（能抓住上面那类问题）；
  2. 是否具备 Actions 必需的结构（name / on / jobs / runs-on / steps）。

用法
----
    pip install pyyaml
    python3 tools/check_workflows.py

退出码非 0 表示有问题。
"""

from __future__ import annotations

import glob
import os
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("需要 PyYAML：pip install pyyaml")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> int:
    patterns = [
        os.path.join(ROOT, ".github/workflows/*.yml"),
        os.path.join(ROOT, ".github/workflows/*.yaml"),
    ]
    paths = sorted({p for pat in patterns for p in glob.glob(pat)})
    if not paths:
        print("没有找到任何 workflow 文件，视为通过。")
        return 0

    failures = 0

    for path in paths:
        rel = os.path.relpath(path, ROOT)
        raw = open(path, encoding="utf-8").read()

        try:
            doc = yaml.safe_load(raw)
        except Exception as exc:  # noqa: BLE001
            print(f"✗ {rel}")
            print(f"    YAML 解析失败: {exc}")
            failures += 1
            continue

        problems: list[str] = []

        if not isinstance(doc, dict):
            problems.append("顶层不是映射（mapping）")
        else:
            if not doc.get("name"):
                problems.append("缺少 name")
            # PyYAML 会把裸 `on:` 解析成布尔 True
            if True not in doc and "on" not in doc:
                problems.append("缺少 on:")
            jobs = doc.get("jobs")
            if not isinstance(jobs, dict) or not jobs:
                problems.append("缺少 jobs，或 jobs 为空")
            else:
                for job_id, job in jobs.items():
                    if not isinstance(job, dict):
                        problems.append(f"job {job_id} 不是映射")
                        continue
                    # 可复用的 workflow 用 uses 代替 runs-on/steps
                    if "uses" in job:
                        continue
                    if "runs-on" not in job:
                        problems.append(f"job {job_id} 缺少 runs-on")
                    steps = job.get("steps")
                    if not isinstance(steps, list) or not steps:
                        problems.append(f"job {job_id} 缺少 steps，或 steps 为空")

        if "\t" in raw:
            problems.append("含 Tab 字符（YAML 禁止用 Tab 缩进）")

        if problems:
            print(f"✗ {rel}")
            for p in problems:
                print(f"    - {p}")
            failures += 1
        else:
            jobs = doc["jobs"]
            steps = sum(
                len(j.get("steps", [])) for j in jobs.values() if isinstance(j, dict)
            )
            print(f"✓ {rel}  jobs={list(jobs)} steps={steps}")

    print()
    if failures:
        print(f"FAIL: {failures} 个 workflow 文件有问题")
        return 1
    print("ALL OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
