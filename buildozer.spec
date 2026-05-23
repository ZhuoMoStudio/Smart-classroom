name: Build All Platforms

on:
  push:
    branches: [main]
    tags:
      - 'v*'
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  # ==================== Windows 打包 ====================
  build-windows:
    name: Build Windows (PyInstaller)
    runs-on: windows-2025-vs2026
    permissions:
      contents: write

    steps:
      - name: 检出代码
        uses: actions/checkout@v6

      - name: 设置 Python 3.12
        uses: actions/setup-python@v6
        with:
          python-version: '3.12'

      - name: 安装依赖
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: 使用 PyInstaller 打包
        env:
          KIVY_GL_BACKEND: angle_sdl2
        run: |
          pyinstaller --onefile --name "SmartClassroom" --icon="icon.ico" --hidden-import kivy.graphics --hidden-import kivy.core.window --hidden-import kivy.uix.widget --hidden-import kivy.uix.boxlayout --hidden-import kivy.uix.gridlayout --hidden-import kivy.uix.floatlayout --hidden-import kivy.uix.scrollview --hidden-import kivy.uix.label --hidden-import kivy.uix.button --hidden-import kivy.uix.textinput --hidden-import kivy.uix.popup --hidden-import kivy.uix.filechooser --hidden-import kivy.uix.behaviors main.py

      - name: 上传 Windows 产物
        uses: actions/upload-artifact@v6
        with:
          name: SmartClassroom-Windows
          path: dist/SmartClassroom.exe

  # ==================== Android 打包 ====================
  build-android:
    name: Build Android (Buildozer)
    runs-on: ubuntu-latest
    timeout-minutes: 120   # 增加超时时间，编译 Python 可能较慢

    steps:
      - name: 检出代码
        uses: actions/checkout@v6

      # 清除旧缓存（避免污染）
      - name: 清除旧的 Buildozer 缓存
        run: rm -rf .buildozer

      - name: 缓存 Buildozer 依赖（加速后续构建）
        uses: actions/cache@v5
        with:
          path: .buildozer
          key: ${{ runner.os }}-buildozer-${{ hashFiles('buildozer.spec') }}

      - name: 设置 Python 3.12
        uses: actions/setup-python@v6
        with:
          python-version: '3.12'

      - name: 安装系统依赖
        run: |
          sudo apt update
          sudo apt install -y \
            git zip unzip openjdk-17-jdk \
            python3-pip autoconf libtool pkg-config \
            zlib1g-dev libncurses-dev \
            cmake libffi-dev libssl-dev \
            libltdl-dev libusb-1.0-0-dev libcairo2 \
            lld

      # 增加交换空间，防止内存不足导致编译失败
      - name: 增加 Swap 空间
        run: |
          sudo fallocate -l 4G /swapfile
          sudo chmod 600 /swapfile
          sudo mkswap /swapfile
          sudo swapon /swapfile
          free -h

      - name: 安装 Buildozer 和 Cython
        run: |
          pip install --upgrade pip
          pip install cython
          pip install buildozer

      - name: 使用 Buildozer 构建 APK
        env:
          MAKEFLAGS: -j1      # 限制并行编译，降低内存峰值
        run: buildozer -v android debug

      - name: 上传 Android 产物
        uses: actions/upload-artifact@v6
        with:
          name: SmartClassroom-Android
          path: bin/*.apk

  # ==================== 自动创建发行版 ====================
  create-release:
    name: Create GitHub Release
    needs: [build-windows, build-android]
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: 下载 Windows 产物
        uses: actions/download-artifact@v6
        with:
          name: SmartClassroom-Windows
          path: release-assets/windows

      - name: 下载 Android 产物
        uses: actions/download-artifact@v6
        with:
          name: SmartClassroom-Android
          path: release-assets/android

      - name: 创建 Release 并上传文件
        uses: softprops/action-gh-release@v2
        with:
          files: |
            release-assets/windows/*.exe
            release-assets/android/*.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}