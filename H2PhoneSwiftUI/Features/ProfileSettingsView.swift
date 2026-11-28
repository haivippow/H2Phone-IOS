import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var store: H2Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                H2Card {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thông tin sẽ random").font(.headline).padding(.bottom, 6)
                        settingToggle("iphone", "Model iPhone", binding: valueBinding(\.randomizeModel))
                        Divider()
                        settingToggle("square.stack.3d.up", "Phiên bản iOS", binding: valueBinding(\.randomizeIOS))
                        Divider()
                        settingToggle("antenna.radiowaves.left.and.right", "Nhà mạng", binding: valueBinding(\.randomizeCarrier))
                        Divider()
                        settingToggle("globe.asia.australia", "Vùng", binding: valueBinding(\.randomizeRegion))
                        Divider()
                        settingToggle("character.bubble", "Ngôn ngữ & múi giờ", binding: valueBinding(\.randomizeLocaleAndTimeZone))
                    }
                }
                H2Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Khoảng thiết bị").font(.headline)
                        Picker("Từ iPhone", selection: modelMinimumBinding) { modelOptions }
                        Divider()
                        Picker("Đến iPhone", selection: modelMaximumBinding) { modelOptions }
                    }
                }
                .opacity(store.generationSettings.randomizeModel ? 1 : 0.45)
                .disabled(!store.generationSettings.randomizeModel)
                H2Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Khoảng iOS").font(.headline)
                        Picker("Từ iOS", selection: iosMinimumBinding) { iosOptions }
                        Divider()
                        Picker("Đến iOS", selection: iosMaximumBinding) { iosOptions }
                    }
                }
                .opacity(store.generationSettings.randomizeIOS ? 1 : 0.45)
                .disabled(!store.generationSettings.randomizeIOS)
                Label("Chỉ random trong phạm vi tương thích với model đã chọn.", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(Palette.blue).padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.pale, in: RoundedRectangle(cornerRadius: 14))
                Text("Tự động lưu thay đổi").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }.padding(16)
        }
        .background(Palette.background)
        .navigationTitle("Cài đặt tạo Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var modelOptions: some View { ForEach(Array(ProfileGenerationSettings.modelOptions.enumerated()), id: \.offset) { Text($0.element).tag($0.offset) } }
    private var iosOptions: some View { ForEach(Array(ProfileGenerationSettings.iosOptions.enumerated()), id: \.offset) { Text($0.element).tag($0.offset) } }
    private func settingToggle(_ symbol: String, _ title: String, binding: Binding<Bool>) -> some View { Toggle(isOn: binding) { Label(title, systemImage: symbol).font(.subheadline) }.tint(Palette.blue).padding(.vertical, 7) }
    private func valueBinding(_ keyPath: WritableKeyPath<ProfileGenerationSettings, Bool>) -> Binding<Bool> { Binding(get: { store.generationSettings[keyPath: keyPath] }, set: { value in var copy = store.generationSettings; copy[keyPath: keyPath] = value; store.updateGenerationSettings(copy) }) }
    private var modelMinimumBinding: Binding<Int> { Binding(get: { store.generationSettings.modelMinimumIndex }, set: { var copy = store.generationSettings; copy.setModelMinimum($0); store.updateGenerationSettings(copy) }) }
    private var modelMaximumBinding: Binding<Int> { Binding(get: { store.generationSettings.modelMaximumIndex }, set: { var copy = store.generationSettings; copy.setModelMaximum($0); store.updateGenerationSettings(copy) }) }
    private var iosMinimumBinding: Binding<Int> { Binding(get: { store.generationSettings.iosMinimumIndex }, set: { var copy = store.generationSettings; copy.setIOSMinimum($0); store.updateGenerationSettings(copy) }) }
    private var iosMaximumBinding: Binding<Int> { Binding(get: { store.generationSettings.iosMaximumIndex }, set: { var copy = store.generationSettings; copy.setIOSMaximum($0); store.updateGenerationSettings(copy) }) }
}

