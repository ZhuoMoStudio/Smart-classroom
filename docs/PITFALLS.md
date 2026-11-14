# 踩坑记录（Pitfalls）

> 这份文档只记**真实发生过**的错误：每一条都对应一次线上/构建/真机故障。
> 改代码前扫一眼，别在同一个地方摔第二次。

## 1. 构建通过 ≠ 功能可用

| 事故 | 教训 |
|---|---|
| 11 个 `assets/sounds/*.wav` 都是 5 字节的 `RIFF\n` 残片。`flutter build` 照过，运行时 `audioplayers` 抛异常又被 `catch (_) {}` 吞掉，音效从来没响过 | 资源文件要有**内容测试**（文件头、采样率、时长、峰值），不能只测「文件存在」 |
| `assets/textbook_index.json` 里混进一段四层数据，应用按三层强转，`(files as List)` 直接抛类型错误，整份教材索引加载失败 | 外部/生成的数据在**读入时做形状校验**，并且**单个坏节点不能拖垮整体** |
| 5 个 Android 启动图标是同一张 2047×2047 大图（19.6 MB 打进 APK） | 大资源要派生，不要原图塞进各个 density；CI 里加体积检查 |

## 2. 「写了」不等于「接上了」

真实出现过、而且从代码里看不出来的：

- 「使用指南」页面写好了，**没有任何入口**（死代码）。
- `AppLog.exportTo()` 写好了，没有任何按钮调用它。
- 同步成功/失败音效方法写好了，`_doSync` 里从没调用。
- 「布局方向」「24 小时制」「保存间隔」三个设置项，**没有任何代码读取**。
- 「关于」写死 v1.31 / Apache 2.0，实际版本与协议都不对。

**判定完成的标准**：UI 上有入口 + 真机点得到 + 有日志或测试能证明它执行了。
只写 service 不算完成。

## 3. Android 存储（最容易反复踩）

1. **不要用 `dart:io` 直接写 `/storage/emulated/0/Download/...`**。
   Android 11+ 分区存储会直接 `EACCES (errno 13)`，读也一样。
2. 公共目录要么拿 `MANAGE_EXTERNAL_STORAGE`（「所有文件访问」），
   要么走 SAF。权限 API 说 granted 也可能写不进去 —— **以「写探测文件」实测为准**。
3. **`FilePicker.saveFile` 必须传 `bytes`**。
   `saveFile` 拿到路径再 `File.copy` 在 Android 11+ 必然失败（SAF 位置没有 dart:io 权限）。
   旧实现把异常吞掉又去写 Download，最后返回一个私有临时路径，界面还显示「已导出」。
4. 权限被拒时要有**可用兜底**：本项目提供「改用应用目录」（应用私有目录，免权限）。
5. 下载文件要做**内容校验**（如 PDF 的 `%PDF-` 头）：代理/网关返回 200 + HTML 错误页时，
   不能把它当成功缓存，否则阅读器永远打开空白。

## 4. 网络与 URI

- **中文/全角字符不能直接拼进 URL**：`Uri.parse`/`Uri.decodeFull` 会抛
  `Illegal percent encoding`。按路径段 `Uri.encodeComponent`。
- **所有网络请求都要有超时**：检查更新曾经没有超时，弱网时启动页一直挂着。
- **镜像列表必须实测**：仓库里两个 GitHub 加速域名早已失效，`resolveRawUrl` 里的 for 循环
  还会在第一次迭代就 return，等于没有回退。
- **缓存键用原始 URL**，不要用镜像 URL，否则换镜像/关镜像后缓存全部命中不了。
- 外部 API 不可达时要有降级：更新检查即使拿不到版本号，也要能跳转 `releases/latest`。

## 5. CI / 发布

- **`GITHUB_TOKEN` 回提交时，checkout 是 detached HEAD**：
  `git pull --rebase origin main` 一定报 “not currently on a branch”。
  要用 `git fetch origin main && git rebase FETCH_HEAD`。
- **并发构建会互相把 main 往前推**：回提交必须 rebase + 重试；
  而且**报告提交失败不能把整次构建判红**（曾经连续 5 次 push 被拒 → verify 失败 →
  Android/Windows 全部 skipped）。
- **PR 不需要打包**：PR 只跑 analyze + test，`main`/tag 才出产物。
- **`flutter analyze --fatal-infos` 才是真门禁**：`--no-fatal-infos` 下 130 条历史问题
  永远不会被处理。
- **action 版本会过期**：Node 20 弃用、`setup-java@v4` 弃用；升级要先看 release notes
  （`download-artifact` 大版本会改解压行为）。
- **Android 依赖的 compileSdk 会顶到天花板**：`permission_handler 13` 要求 compileSdk 37，
  而 AGP 9.0.1 推荐上限是 36 → 固定 `permission_handler: 11.4.0`（compileSdk 34）。
  遇到 AAR metadata 报错，先查依赖的 `android/build.gradle` 里的 compileSdk。
- **Windows 工程必须入库**：以前 CI 每次 `flutter create` 重建，窗口标题、图标全被覆盖；
  安装包版本还写死在 `setup.iss` 里（1.25.0）。
- **签名**：仓库不存 keystore，CI 产出的是 debug 签名。自用可以，对外分发必须配 Secret。

## 6. Flutter 细节

| 写法 | 问题 |
|---|---|
| `Color.withOpacity(x)` | 已弃用 → `withValues(alpha: x)` |
| `DropdownButtonFormField(value:)` | 已弃用 → `initialValue:`；外部值变化要换 `key`，否则显示不刷新 |
| `RadioListTile(groupValue:/onChanged:)` | 已弃用 → 外层 `RadioGroup` |
| `showDialog` 返回后立刻 `controller.dispose()` | 退出动画还在用 controller → `used after being disposed`；让 StatefulWidget 持有 |
| 在 `build()` 里弹窗/发请求 | 主题、字体、窗口变化都会重新触发；放到首帧后执行一次 |
| `'$name名称'` | 中文紧跟变量要写 `${name}名称` |
| `int.tryParse('1.5')` | 返回 null（被 `?? 0` 吃掉）→「1.5 分钟」变成 0；小数用 `double.tryParse` |
| 背景/文字写死 `AppColors.xxx` | 深色模式下变成「深色面板 + 浅灰底」「黑字黑底」；用 `colorScheme` / `scaffoldBackgroundColor` |
| 4 个面板同时塞一屏 | 手机竖屏每块只剩 1/4 高；改成一个功能占满 + 切换 |

## 7. 数据安全（后果最重）

- **覆盖前必须备份**：同步上传/下载、名单淘汰，都要先落到 `数据存档/`。
- **保存失败绝不能显示成功**：`syncComplete()` 只能在文件真的传上去之后调用。
- **撤销要先定位再移除记录**：先 `removeAt(0)` 再找人，会「撤销失败且历史消失」。
- **名单识别错会删错班**：「高一年级3班」≠「一年级3班」；这类纯函数必须有测试。
- **设置要持久化**：WebDAV 账号/地址曾经只存在内存，重启就丢，而密码还在 Keystore。
- **日志不能静默丢**：工作区不可写时，导出要退回内存缓冲，至少能说明问题。

## 8. 本项目的工作方式

- 本地没有可用的 Flutter 工具链（ARM 机器跑不了 x64 SDK），**一切验证靠 GitHub Actions**。
- 分析结果会写进 `docs/analyzer-report.md`，并以注解形式贴在运行页面；
  日志下载需要额外权限，注解是公开可读的反馈通道。
- 改动顺序：先 `analyze + test` 绿，再出包；发版打 `v*` tag。
- 每次修完一个「以前修过但没生效」的问题，**补一条测试或一次真机验证**，
  否则它大概率会以另一种形式回来。

## 9. 上线前检查清单

- [ ] `flutter analyze --fatal-infos` 0 条
- [ ] `flutter test` 全绿，新增逻辑有测试
- [ ] 新增设置项：有 UI、有读取方、能持久化
- [ ] 新增资源：有内容校验，不是占位文件
- [ ] 新增网络请求：有超时、有失败提示、有降级
- [ ] 新增文件写入：考虑 Android 分区存储，失败可见
- [ ] 新增界面：深色模式、窄屏、大字体下不溢出
- [ ] 改过 `windows/`：CI 打包仍是仓库内工程，不是临时 `flutter create`
- [ ] 发版：版本号、CHANGELOG、tag、Release 产物齐全
