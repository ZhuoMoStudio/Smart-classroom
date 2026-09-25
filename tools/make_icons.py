#!/usr/bin/env python3
"""从单一主图生成各平台所需尺寸的图标。

为什么需要这个脚本
------------------
仓库里 5 个 Android 启动图标曾经是同一张 2047x2047 的图（每个 3.93 MB），
打包进 APK 后合计 18.4 MB；Windows 的图标源是 2388x1668 的 5.8 MB PNG，
而 Inno Setup 真正需要的 app_icon.ico 根本不在仓库里。
正确尺寸的图标应当由一张主图派生，而不是把大图直接塞进各 density 目录。

幂等性
------
- 优先读 branding/app_icon.png（1024 方形主图）；
- 若不存在，则回退到 android/app/src/main/res/mipmap-mdpi/ic_launcher.png，
  并把它固化为 branding/app_icon.png。
派生一律以磁盘上的主图为准，因此首次运行与后续运行结果完全一致。

用法
----
    pip install Pillow
    python3 tools/make_icons.py

退出码 0 表示成功；若无任何变化，会额外打印 "unchanged"。
"""

from __future__ import annotations

import os
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit("需要 Pillow：pip install Pillow")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MASTER = os.path.join(ROOT, "branding", "app_icon.png")
LEGACY_SOURCE = os.path.join(
    ROOT, "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
)

# Android density -> 边长（px）。这些是各 density 的规范尺寸。
ANDROID_DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

ICO_SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

MASTER_PX = 1024
WINDOWS_PNG_PX = 256


def _p(*parts: str) -> str:
    return os.path.join(ROOT, *parts)


def load_master() -> tuple[Image.Image, str]:
    """返回 (主图, 来源说明)。"""
    if os.path.exists(MASTER):
        img = Image.open(MASTER).convert("RGBA")
        if img.width >= 512 and img.width == img.height:
            return img, "branding/app_icon.png"
        print(f"警告: {MASTER} 不是 >=512 的方图，回退到遗留源")

    if not os.path.exists(LEGACY_SOURCE):
        sys.exit(f"找不到图标源: {MASTER} 或 {LEGACY_SOURCE}")

    img = Image.open(LEGACY_SOURCE).convert("RGBA")
    if img.width != img.height:
        side = min(img.width, img.height)
        left = (img.width - side) // 2
        top = (img.height - side) // 2
        img = img.crop((left, top, left + side, top + side))
    return img, "android/.../mipmap-mdpi/ic_launcher.png (遗留源，将固化为主图)"


def write_if_changed(path: str, save) -> bool:
    """只在内容变化时写盘，避免无意义的 git diff。"""
    os.makedirs(os.path.dirname(path), exist_ok=True)

    tmp = path + ".tmp"
    save(tmp)

    old = None
    if os.path.exists(path):
        with open(path, "rb") as f:
            old = f.read()
    with open(tmp, "rb") as f:
        new = f.read()

    if old == new:
        os.remove(tmp)
        return False

    os.replace(tmp, path)
    return True


def main() -> int:
    master, origin = load_master()
    print(f"主图来源: {origin}  ({master.width}x{master.height})")

    results: list[tuple[str, bool]] = []  # (相对路径, 是否有变化)

    def emit(path: str, save) -> None:
        results.append((os.path.relpath(path, ROOT), write_if_changed(path, save)))

    # 1) 固化主图，作为后续所有派生的唯一来源
    emit(
        MASTER,
        lambda p: master.resize((MASTER_PX, MASTER_PX), Image.LANCZOS).save(
            p, "PNG", optimize=True
        ),
    )

    # 关键：重新从磁盘读回主图再派生。
    # 否则首次运行走的是 源图->48px，第二次走的是 源图->1024->48px，
    # 两次的重采样链路不同、字节不同，会凭空产生一次 diff。
    master = Image.open(MASTER).convert("RGBA")

    # 2) Android 各 density
    icons_before = icons_after = 0
    for density, px in ANDROID_DENSITIES.items():
        path = _p("android/app/src/main/res", f"mipmap-{density}", "ic_launcher.png")
        if os.path.exists(path):
            icons_before += os.path.getsize(path)

        def _save(p: str, px: int = px) -> None:
            master.resize((px, px), Image.LANCZOS).save(p, "PNG", optimize=True)

        emit(path, _save)
        icons_after += os.path.getsize(path)

    # 3) Windows:Inno Setup 的 SetupIconFile 与 Flutter runner 都需要 .ico
    emit(
        _p("windows/runner/resources/app_icon.ico"),
        lambda p: master.resize((256, 256), Image.LANCZOS).save(
            p, format="ICO", sizes=ICO_SIZES
        ),
    )

    # 4) Windows runner 的方形 PNG
    emit(
        _p("windows/runner/resources/app_icon.png"),
        lambda p: master.resize((WINDOWS_PNG_PX, WINDOWS_PNG_PX), Image.LANCZOS).save(
            p, "PNG", optimize=True
        ),
    )

    if icons_before:
        saved = 1 - icons_after / icons_before
        print(
            f"Android 启动图标: {icons_before/1e6:.2f} MB -> "
            f"{icons_after/1024:.1f} KB  (省 {saved:.1%})"
        )

    print("产物:")
    for path, is_changed in results:
        mark = "已更新" if is_changed else "无变化"
        print(f"  {os.path.getsize(_p(*path.split('/')))/1024:9.1f} KB  [{mark}]  {path}")

    if not any(c for _, c in results):
        print("unchanged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
