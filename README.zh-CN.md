**[English](README.md) | 简体中文**

<p align="center">
  <img src="./assets/readme/hero-zh-v2.svg" width="100%" alt="FinderWrap：让方向键跨越行末。">
</p>

Finder 图标视图里，左右键走到行末就停住了。FinderWrap 是常驻菜单栏的小工具，把这两步合并成一步：**行末按右键直接落到下一行行首，行首按左键回到上一行行末。** 整个图标区首尾也会循环。

## 功能

- **跨行移动**：越过行边界继续移动，并在整个图标区首尾循环，不再卡在边缘。
- **扩展选择**：按住 Shift 再按左右键，把多选范围带到相邻行。
- **覆盖常见视图**：普通、搜索、智能和 iCloud 文件夹，分组行、被裁切的行以及桌面图标。
- **配合快速查看**：预览窗口打开时，继续操作底下的图标网格。
- **画廊缩略图循环**：缩略图条到两端后循环，可单独关闭。
- **列表视图导航（可选）**：让左右键切换到上一项或下一项，端点不会误触文件夹展开。
- **只驻留菜单栏**：无 Dock 图标和主窗口；隐藏菜单栏图标后应用仍在运行。
- **不改动 Finder 布局**：网格只读，每次写选择都先回读确认，再继续处理。

## 覆盖范围

| 场景 | 行为 |
|---|---|
| 普通、搜索、智能和 iCloud 文件夹的图标视图 | 跨行移动并在文档首尾循环；支持单选和多选；Shift 可跨行扩选 |
| 按种类分组的图标视图 | 行按 Y 坐标聚类，跨组继续换行 |
| 被窗口边缘裁切的行 | 只要边缘行能读出几何信息就参与换行 |
| 桌面图标 | 支持；桌面表面通过焦点 AXGroup 识别，逐项写入选择 |
| 快速查看 | 支持；继续操作底下的图标布局，不抢焦点 |
| 画廊视图 | 缩略图条两端循环，可关闭 |
| 列表视图 | 左右键切换上一项或下一项（独立开关）；**首尾不循环** |
| 分栏视图、重命名、搜索框等编辑状态 | 保持 Finder 原生行为 |

## 工作原理

<p align="center">
  <img src="./assets/readme/flow.svg" width="100%" alt="按键处理流程：捕获按键、读取选区、网格快照、计算目标、写回并回读校验">
</p>

- **布局只读**：网格在后台采集，从不改变 Finder 显示的内容。
- **每次写入都回读**：写选择后立即读回确认；只能逐项读取时，用 `AXSelected` 兜底。无法确认时保持原生状态，绝不重放按键。
- **只需要两项权限**：辅助功能和输入监控。自 1.0.7 起不再需要「自动化 Finder」（Apple Events）。

## 安装

推荐使用 Homebrew：

```sh
brew tap yangn-st/ygn
brew install --cask yangn-st/ygn/finderwrap
brew upgrade --cask yangn-st/ygn/finderwrap
brew uninstall --cask yangn-st/ygn/finderwrap
```

也可以从 [Releases](https://github.com/YanGN-ST/FinderWrap/releases/latest) 下载 DMG 或 ZIP，并用同名 `.sha256` 文件校验：

```sh
shasum -a 256 -c FinderWrap-1.0.14-b17-fixed-arm64.sha256
```

- 当前版本：**1.0.14（build 17）**，仅 Apple Silicon，最低 macOS 13。Intel 用户请继续使用 1.0.3。
- 应用使用固定自签证书，未经过 Apple 公证。若 macOS 阻止首次打开，请核对来源，再到「系统设置 → 隐私与安全性」中允许打开。Homebrew 仍保留自己的安全检查。
- 首次启动时授予辅助功能和输入监控，然后开启左右键跨行。应用只驻留菜单栏，无 Dock 图标和主窗口。
- 面板的「界面」区域可以隐藏菜单栏图标。隐藏后应用继续在后台运行；再次打开 FinderWrap 时，面板会以小窗口出现。

## 开始使用

1. 从菜单栏打开 FinderWrap。
2. 按提示授予辅助功能和输入监控。
3. 在面板中开启左右键跨行。

面板控制图标、画廊和列表视图行为。画廊循环和列表导航各有独立开关。隐藏菜单栏图标后，应用仍会继续运行。

## 兼容性与限制

| macOS | 状态 |
|---|---|
| 26.x | 本机实测通过（26.6.2 / Finder 26.4） |
| 15.x | 旧版本曾出现「无反应」。1.0.10 移除了窗口和 section 的硬校验，增加结构与逐项兜底，但 15.x **尚未实机复验** |
| 27.x | 未实机测试；使用 SDK 27 构建，适用相同的兜底与诊断逻辑 |

- 列表视图首尾不循环：向不可见行写入选择会清空选择，所以端点按键会被吞掉，而不是交给 Finder。
- Shift 扩选只覆盖 Finder 已加载的行。到未加载的滚动边界时，保留当前选区并停止移动。
- 分栏视图、重命名、搜索框等编辑状态保持 Finder 原生行为；快速查看需要从图标视图打开。
- 辅助功能与 Apple Events 没有跨进程原子事务。不要同时用其他自动化工具更改 Finder 的选择。
- 屏外目标和无法确认的折叠组保持原生行为。应用不承诺支持所有可能的布局。

如果 FinderWrap 看起来没有反应，请从菜单栏面板选择「复制诊断信息」并回传。报告包含 macOS 和 Finder 版本、权限、焦点与窗口角色、网格标识、行数和列数以及最近的决策，**不包含文件名、路径或按键内容**。详见[兼容性文档](docs/compatibility.md)。

## 开发与签名

<details>
<summary>构建、测试与仓库结构</summary>

需要 Xcode 命令行工具，不引入第三方运行时依赖。

```sh
bash scripts/test.sh
bash scripts/build.sh Release
bash scripts/package.sh --fixed
```

- Swift 测试覆盖纯逻辑：行聚类、跨行换行、不齐末行、单行循环、文档首尾循环、多选锚点、重复 URL 和非法几何。测试不访问 Finder、不发送真实按键、不修改权限。
- Python 测试覆盖签名策略、最低系统版本和固定证书规则；CI 还会检查 shell 语法并构建未签名归档。
- 构建与发布约束见[验收文档](docs/testing.md)和[签名文档](docs/signing.md)。

| 路径 | 内容 |
|---|---|
| `Rebuild/Sources/FinderBridge/` | 辅助功能读写、网格模型、后台读取、监控与矢量标记 |
| `Rebuild/Host/` | AppKit 菜单栏宿主与 SwiftUI 面板 |
| `Rebuild/Tests/` | 纯换行逻辑的 XCTest 目标 |
| `scripts/` | 构建、测试、打包、签名与诊断脚本 |
| `Tests/` | Python 签名与系统测试 |
| `docs/` | 架构、兼容性、验收与签名说明 |
| `config/signing.json` | 固定证书指纹与 designated requirement |

</details>

## 许可与签名

本项目使用 MIT 许可。应用使用固定自签证书，未公证，无遥测，不发起网络请求；权限由用户自行授予。签名身份来自仓库固定的证书（`config/signing.json`），升级后保持不变，已有权限可以继续使用。macOS 升级或系统重置后仍可能需要重新授权。详见[签名文档](docs/signing.md)。

[MIT](LICENSE) · [关注 YanGN 的小红书](https://www.xiaohongshu.com/user/profile/66a7e7ae000000001d023641)
