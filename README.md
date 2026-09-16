<p align="center"><img src="docs/assets/dockkeys.svg" width="88" height="88" alt="DockKeys" /></p>

# DockKeys

**用数字快捷键，直达 Dock 中的应用。**

DockKeys 是一个轻量的 macOS 菜单栏工具。按下 `⌥ + 1` 打开或切换到 Dock 中的第一个固定应用，`⌥ + 2` 对应第二个，以此类推。移动 Dock 图标后，快捷键会自动跟随新顺序。

Swift / AppKit / SwiftUI · Apple Silicon 原生 · macOS 13+ · 无第三方依赖 · [MIT 许可](LICENSE)

## 开发背景

Windows 的 `Win + 数字` 可以直接启动或切换任务栏中对应位置的应用。这种操作适合已经形成肌肉记忆的常用应用：不用搜索名称，也不用在应用切换列表里逐个寻找。

macOS 上的 [Snap](https://apps.apple.com/us/app/snap/id418073146?mt=12) 提供了类似体验，但它的 App Store 版本停留在 2012 年发布的 1.5，程序仍是 Intel 架构。在 Apple Silicon Mac 上，希望保留这种简单的使用方式，同时拥有可以自行构建、检查和维护的原生实现。

DockKeys 因此围绕三个目标设计：**按 Dock 顺序直达应用、配置足够简单、代码规模容易维护**。菜单栏图标使用应用方块和 Dock 底座，打开后即可查看当前每个数字对应的应用。

## 功能说明

| 功能 | 行为 |
|---|---|
| 按位置启动与切换 | `⌥ + 1…9` 对应前九个固定应用，`⌥ + 0` 对应第十个 |
| Dock 顺序同步 | 自动更新映射，每次触发快捷键时也会重新读取顺序 |
| 修饰键选择 | 支持 Option、Control、Command 及预设组合 |
| Finder 编号 | 可选择让 Finder 占据第一个位置，默认关闭 |
| 再按隐藏 | 目标应用已在前台时，再次按键可隐藏它，默认开启 |
| 实时映射 | 设置窗口和菜单栏列出当前应用及对应快捷键 |
| 冲突提示 | 注册失败的快捷键会被标记，可更换组合或释放占用后重试 |
| 空编号处理 | 没有对应应用的位置不注册快捷键，不会因越界而崩溃 |
| 暂停与恢复 | 临时释放全部快捷键，按需恢复 |
| 登录启动 | 使用 macOS 登录项服务，可在设置中开启，默认关闭 |

## 快速开始

已构建的应用位于 `dist/DockKeys.app`。如果从源码开始，请先阅读下面的构建说明。

1. 将 `DockKeys.app` 放到“应用程序”文件夹后打开。
2. 首次启动会显示设置窗口，确认右侧应用顺序。
3. 按 `Option + 数字` 启动或切换应用。
4. 关闭设置窗口后，程序继续在菜单栏运行。点击“三个应用方块＋底座”图标可返回设置、暂停快捷键或退出。

例如，Dock 中固定的是 `浏览器 → 终端 → 编辑器`，默认就对应 `⌥1 → ⌥2 → ⌥3`。开启“Finder 参与编号”后，Finder 使用 `⌥1`，其余应用顺延。

如果 Snap 或其他热键工具使用相同组合，请先释放该组合，或在 DockKeys 中选择其他修饰键。退出 DockKeys 会释放它注册的全部快捷键。

## 系统要求与权限

- 最低 macOS 13。默认构建目标是 Apple Silicon / ARM64。
- 核心功能使用系统热键注册和应用打开接口，不需要辅助功能或屏幕录制权限。
- 登录启动使用系统登录项服务；macOS 要求确认时，设置页会提供入口。
- 应用运行不需要联网，没有账号、遥测或自动更新服务。
- 默认构建采用本地临时签名，尚未经过 Apple 公证。用于本地构建试用；正式分发可以指定 Developer ID 签名身份并另行公证。

## 构建与测试

需要安装 Xcode Command Line Tools 或完整 Xcode。

```sh
git clone https://github.com/clxsh/DockKeys.git
cd DockKeys
./scripts/test.sh
./scripts/build.sh
open dist/DockKeys.app
```

构建产物：

```text
dist/
├── DockKeys.app
└── DockKeys-arm64.zip
```

构建脚本优先使用独立 Command Line Tools，也支持已有的 `DEVELOPER_DIR`。通过 `CODE_SIGN_IDENTITY` 可指定签名身份；`ARCH=x86_64 ./scripts/build.sh` 可生成 Intel 版本，但该平台需要独立验证。

自动测试覆盖 Dock 顺序、Finder 编号、空编号、无效条目、路径编码、十项上限、隐藏开关，以及真实系统热键的占用和释放。热键集成测试需要在已登录的 macOS 图形会话中执行；受限执行沙箱或无图形会话的环境可能无法完成注册。

查看当前 Dock 映射而不启动界面：

```sh
dist/DockKeys.app/Contents/MacOS/DockKeys --diagnose
```

## 功能边界

- 只编号固定在 Dock 应用区域的应用，最多十个位置。临时运行、最近使用的应用，以及文件夹、文档和分隔符不参与编号。
- 数字键使用主键盘的物理位置，不绑定小键盘。非美式键盘布局需要按实际键位验证。
- 快捷键绑定到应用；同一应用的多个窗口由应用自身处理，目前没有窗口轮换和窗口排列功能。
- 最小化窗口恢复、全屏和跨桌面切换由目标应用及 macOS 设置决定，不强行移动窗口。
- 全局热键注册能检测其他全局热键的占用，无法预知每个应用自己的菜单快捷键。`Command + 数字` 等组合可能覆盖浏览器切换标签等操作。
- Dock 固定应用列表读取自系统偏好设置，未来 macOS 调整存储格式时可能需要适配。
- 设置界面目前为简体中文。自动更新、按应用单独录制快捷键不在当前版本范围内。

## 代码结构

| 文件 | 职责 |
|---|---|
| `Sources/DockModel.swift` | 解析、过滤、编号与行为判定 |
| `Sources/DockReader.swift` | 刷新并读取 Dock 偏好设置 |
| `Sources/HotKeyManager.swift` | 注册、释放全局热键和报告冲突 |
| `Sources/AppState.swift` | 设置、顺序同步、启动／隐藏、登录启动 |
| `Sources/DockIcon.swift` | 菜单栏与设置窗口共享的 Dock 图标 |
| `Sources/SettingsView.swift` | 设置及实时映射界面 |
| `Sources/Main.swift` | 应用生命周期和菜单栏 |
| `Tests/` | 核心逻辑与系统热键集成测试 |
| `scripts/` | 本地构建、测试和应用图标生成 |

## 反馈与贡献

欢迎通过 [Issues](https://github.com/clxsh/DockKeys/issues) 反馈问题。请尽量提供 macOS 版本、处理器架构、快捷键组合、Finder 编号设置，以及复现步骤。涉及应用切换时，请说明目标应用是否处于最小化、全屏或其他桌面。

提交代码前运行 `./scripts/test.sh` 和 `./scripts/build.sh`，并验证受影响的界面或系统行为。

## 许可证

[MIT](LICENSE)。
