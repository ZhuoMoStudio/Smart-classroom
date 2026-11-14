# 参与开发

这个仓库的**全部构建与验证都在 GitHub Actions 完成**，本地不需要装 Flutter。
你只需要能改文件、发 PR。

## 一次改动的完整流程

1. 从 `main` 开分支：`fix/xxx`、`feat/xxx`、`chore/xxx`。
2. 改代码，推分支，开 PR。
3. PR 会自动跑 **Build & Release → 静态分析与测试**：
   - `flutter analyze`（编译级错误会红）
   - `flutter test`
   - 完整输出会回写到 `docs/analyzer-report.md`，在 Actions 日志里也能看到
   - PR 阶段**不编译** Android / Windows，省 runner 时间
4. 绿了之后合入 `main`，`main` 上会编译两端产物。
5. 发布：推 `v*` tag，或提交信息里带 `[release]`。

> CI 用 `GITHUB_TOKEN` 回提交诊断报告。这类提交不会再触发其他 workflow，
> 属于 GitHub 的防递归机制，不是配置错误。

## 本地环境（可选）

如果确实要在本地跑：

```bash
# Flutter 3.44.9 / Dart 3.10（CI 固定这个版本，见 build.yml 的 FLUTTER_VERSION）
flutter --version
flutter pub get
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
```

本地不要求能打包 Windows：`windows/` 工程已随仓库提供，但构建需要 MSVC。

## 动手前先读

[docs/PITFALLS.md](docs/PITFALLS.md) 记录了真实发生过的故障与对应教训
（资源占位、权限、SAF、CI 回提交、弃用 API……）。改相关代码前先扫一眼。

## 代码约定

- **注释解释「为什么」，不解释「做了什么」**。这个仓库里大量注释记录的是
  某个写法曾经造成的真实事故（丢名单、同步假成功、音效从未生效……），
  改动时请保留这类信息，不要为了整洁删掉。
- 面向用户的文案用中文；代码标识符用英文。
- 新增逻辑优先写成**可单测的纯函数**（参考 `RankSystem`、`RosterManager`），
  再在 UI 里调用。
- 涉及文件名识别（年级/班级）的改动必须补测试：判断错的后果是删错班。

## 数据兼容

老师的 xlsx、批注 JSON、云同步目录都是**长期存在的数据**，不是缓存：

- 改字段要有读取旧格式的分支，不能要求老师手动迁移；
- 改云端路径要保留旧路径的读取（至少一个版本）；
- 任何「删除/覆盖」操作前先备份到 `数据存档/`。

## 提交信息

```
fix(音效): 替换 5 字节的 wav 占位文件
feat(题库): 支持按章节筛选
chore(ci): 固定 Flutter 版本
```

类型用 `feat` / `fix` / `chore` / `docs` / `test` / `refactor`。

## 不要做的事

- 不要把 keystore、`key.properties`、token 提交进仓库（`.gitignore` 已挡住，
  但别用 `git add -f`）。
- 不要在 CI 里静默吞掉失败：`flutter analyze` / `test` 的退出码必须传递到 job 结果。
- 不要为了过 CI 把 lint 规则关掉；历史告警应当逐条修掉。
