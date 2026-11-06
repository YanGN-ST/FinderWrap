**[English](README.md) | 简体中文**

<p align="center">
  <img src="./assets/readme/hero-zh-v2.svg" width="100%" alt="FinderWrap: 让方向键跨越行末。">
</p>

FinderWrap 让 Finder 图标视图中的左右方向键跨行移动。它支持跨行扩选、桌面图标、快速查看、画廊视图和可选的列表视图导航。

## 功能

- 在相邻图标行之间移动，并在整个图标区域的首尾循环。
- 按住 Shift 和方向键，跨行扩展选择范围。
- 支持普通、搜索、智能和 iCloud 文件夹的图标视图，以及分组和部分裁切的行。
- 支持画廊缩略图首尾循环，可选择启用列表视图左右切项。

## 安装

需要 macOS 13 或更高版本及 Apple Silicon。使用 [Homebrew](https://github.com/YanGN-ST/homebrew-ygn) 安装：

```sh
brew tap yangn-st/ygn
brew install --cask yangn-st/ygn/finderwrap
```

也可以从 [Releases](https://github.com/YanGN-ST/FinderWrap/releases/latest) 下载 DMG 或 ZIP。应用使用固定自签证书，未经过 Apple 公证。若 macOS 阻止打开，请核对来源后在「系统设置 → 隐私与安全性」中允许打开。

## 开始使用

1. 从菜单栏打开 FinderWrap。
2. 授予辅助功能和输入监控权限。
3. 在设置中启用左右方向键跨行。

菜单栏面板提供图标、画廊和列表视图设置。隐藏菜单栏图标后，应用仍会在后台运行。

## 兼容性与限制

列表视图首尾不循环。Shift 扩选覆盖 Finder 已加载的行。分栏视图和文字编辑区域保持系统原有行为。快速查看需从图标视图打开。屏外目标及无法确认选区的布局保持原有行为。

已在 macOS 26.6.2 和 Finder 26.4 上测试，macOS 15 和 27 仍需实机验证。遇到问题时可在菜单栏面板选择「复制诊断信息」，报告不含文件名、路径或按键内容。详见[兼容性文档](docs/compatibility.md)。

<details>
<summary>开发与签名</summary>

需要 Xcode 命令行工具。

```sh
bash scripts/test.sh
bash scripts/build.sh Release
bash scripts/package.sh --fixed
```

构建和签名要求见[测试文档](docs/testing.md)和[签名文档](docs/signing.md)。

</details>

## 许可

[MIT](LICENSE) · [YanGN 的小红书主页](https://www.xiaohongshu.com/user/profile/66a7e7ae000000001d023641)
