# 安全策略

## 报告方式

请**不要**开公开 issue。使用 GitHub 的
[私密安全公告](https://github.com/ZhuoMoStudio/Smart-classroom/security/advisories/new)
提交，或在 issue 里只写「有安全问题，请给一个私下联系方式」。

## 这个项目会接触到的敏感数据

| 数据 | 存放位置 | 说明 |
|---|---|---|
| 学生姓名、班级、积分 | 老师自选的工作目录 `学生信息/*.xlsx` | 明文，随老师的网盘/文件夹走 |
| WebDAV 账号与密码 | 账号在 `shared_preferences`；密码在 `flutter_secure_storage`（Android Keystore / Windows DPAPI） | 密码从不写进工作目录 |
| 教材 PDF 与批注 | 工作目录 `课本/`、`数据存档/批注/` | 批注是独立 JSON，不改 PDF 原件 |
| 运行日志 | 工作目录 `数据存档/运行日志.log` | 可能含文件路径，不含密码 |

应用不收集遥测，不上传任何数据；唯一的对外请求是
GitHub Releases 版本检查、教材 PDF 下载与老师自己配置的 WebDAV。

## 已知的边界

- **发布包签名**：仓库 CI 默认使用 debug 签名（没有把密钥放进仓库）。
  如果你要正式分发，请按
  [README 的签名说明](README.md#android-签名) 配置自己的 keystore；
  debug 签名的 APK 不适合分发给其他人。
- **明文 HTTP**：应用只允许 HTTPS；`network_security_config.xml`
  没有开放任意明文流量。
