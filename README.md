**English | [简体中文](README.zh-CN.md)**

<p align="center">
  <img src="./assets/readme/hero-en-v2.svg" width="100%" alt="FinderWrap: Move beyond the row.">
</p>

FinderWrap makes Finder's arrow keys wrap across rows in icon view. It also supports selection across rows, desktop icons, Quick Look, gallery view and optional list-view navigation.

## Features

- Navigate between adjacent icon rows and cycle across the ends of the grid.
- Extend a selection across rows with Shift and the arrow keys.
- Use icon views in ordinary, search, smart and iCloud folders, including grouped and partially visible rows.
- Cycle through gallery thumbnails and optionally move between items in list view.

## Install

Requires macOS 13 or later and Apple Silicon. Install using [Homebrew](https://github.com/YanGN-ST/homebrew-ygn):

```sh
brew tap yangn-st/ygn
brew install --cask yangn-st/ygn/finderwrap
```

You can also download a DMG or ZIP from [Releases](https://github.com/YanGN-ST/FinderWrap/releases/latest). The app uses a fixed self-signed certificate and is not notarized. If macOS blocks it, verify the source and allow it in **System Settings → Privacy & Security**.

## Get started

1. Open FinderWrap from the menu bar.
2. Grant Accessibility and Input Monitoring permissions.
3. Enable left/right arrow wrapping in the app's settings.

The menu-bar panel controls icon, gallery and list-view behavior. The menu-bar icon can be hidden while the app continues running.

## Compatibility and limits

List-view endpoints do not cycle. Shift selection covers rows currently loaded by Finder. Column view and text-editing fields retain their native behavior. Quick Look works when opened from icon view. Off-screen targets and layouts whose selection cannot be verified retain their native behavior.

macOS 26.6.2 with Finder 26.4 has been tested. macOS 15 and 27 require hardware verification. For troubleshooting, choose **Copy diagnostics** in the menu-bar panel. The report excludes file names, paths and typed keys. See [compatibility](docs/compatibility.md).

<details>
<summary>Development and signing</summary>

Requires Xcode command-line tools.

```sh
bash scripts/test.sh
bash scripts/build.sh Release
bash scripts/package.sh --fixed
```

See [testing](docs/testing.md) and [signing](docs/signing.md) for build requirements and signing identity.

</details>

## License

[MIT](LICENSE) · [YanGN on Xiaohongshu](https://www.xiaohongshu.com/user/profile/66a7e7ae000000001d023641)
