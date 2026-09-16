import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var state: AppState
    private let accent = Color(red: 0.30, green: 0.36, blue: 0.88)

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(nsImage: DockIcon.image())
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(accent.gradient, in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 5) {
                    Text("DockKeys").font(.system(size: 27, weight: .bold, design: .rounded))
                    Text("按 Dock 顺序，快速打开或切换应用").foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    state.paused.toggle()
                } label: {
                    Label(state.paused ? "恢复快捷键" : "暂停快捷键",
                          systemImage: state.paused ? "play.fill" : "pause.fill")
                }.controlSize(.large)
            }

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("快捷键").font(.headline)
                        Picker("修饰键", selection: $state.modifier) {
                            ForEach(ModifierChoice.allCases) { choice in Text(choice.label).tag(choice) }
                        }.labelsHidden().frame(maxWidth: .infinity)
                        Text("\(state.modifier.symbol) + 1…9，0 对应第 10 个应用")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 18) {
                        Toggle("Finder 参与编号", isOn: $state.includeFinder)
                        Toggle("再次按键隐藏当前应用", isOn: $state.hideOnRepeat)
                        Toggle("登录时启动", isOn: Binding(
                            get: { state.loginEnabled }, set: { state.setLoginEnabled($0) }))
                        if state.loginNeedsApproval {
                            Button("在系统设置中允许登录启动") { SMAppService.openSystemSettingsLoginItems() }
                                .font(.callout)
                        }
                    }.toggleStyle(.checkbox)
                    Divider()
                    VStack(alignment: .leading, spacing: 9) {
                        Label("顺序自动同步", systemImage: "arrow.triangle.2.circlepath")
                            .font(.callout.weight(.medium))
                        Text("只编号固定在 Dock 的应用。拖动图标后，快捷键会跟随新顺序。")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        Text("使用 ⌘ 或 ⌃ 时，可能覆盖应用或系统已有的数字快捷键。")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(20).frame(width: 282, height: 436)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("当前映射").font(.headline)
                        Spacer()
                        HStack(spacing: 5) {
                            Circle().fill(state.paused ? Color.secondary : (state.failures.isEmpty ? Color.green : Color.orange))
                                .frame(width: 6, height: 6)
                            Text(state.paused ? "已暂停" : (state.failures.isEmpty ? "已启用" : "部分未启用"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(0..<10, id: \.self) { slot in row(slot) }
                        }
                    }
                    if !state.failures.isEmpty {
                        HStack(alignment: .top) {
                            Text("标记的快捷键注册失败，可能已被 Snap 等工具占用。退出占用工具后重试，或更换修饰键。")
                                .font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                            Button("重试") { state.retryShortcuts() }.controlSize(.small)
                        }
                    }
                }.padding(20).frame(maxWidth: .infinity).frame(height: 436)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
            }
            if let message = state.message {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                    Text(message).font(.callout).textSelection(.enabled)
                    Spacer()
                    Button { state.clearMessage() } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
                }.padding(12).background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            HStack {
                Text("在菜单栏随时调整 · 跨桌面切换跟随 macOS 设置")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "").font(.caption.monospaced()).foregroundStyle(.tertiary)
            }
        }
        .padding(26)
        .frame(minWidth: 790, idealWidth: 790, maxWidth: .infinity, minHeight: 610)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(accent)
    }

    @ViewBuilder private func row(_ slot: Int) -> some View {
        let app = DockModel.app(at: slot, in: state.apps)
        let failed = state.failures[slot] != nil
        HStack(spacing: 10) {
            Text(state.shortcut(for: slot)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(app == nil || state.paused ? Color.secondary : accent)
                .frame(width: 62, height: 28)
                .background(accent.opacity(app == nil ? 0.035 : 0.08), in: RoundedRectangle(cornerRadius: 7))
            if let app {
                Image(nsImage: state.icon(for: app)).resizable().frame(width: 27, height: 27)
                Text(app.name).font(.callout).lineLimit(1).help(app.url.path)
            } else {
                Text("未分配").font(.callout).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if failed {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                    .help("注册失败（\(state.failures[slot]!)）")
            }
        }.padding(.vertical, 3).padding(.horizontal, 2)
    }
}
