import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var store: H2Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Thông tin sẽ random").font(.title3.bold())
                ForEach(ProfileCapabilityGroup.allCases) { group in
                    H2Card {
                        DisclosureGroup {
                            VStack(spacing: 0) {
                                ForEach(ProfileRandomField.allCases.filter { $0.group == group }) { field in
                                    capabilityRow(field)
                                    if field.id != ProfileRandomField.allCases.filter({ $0.group == group }).last?.id { Divider() }
                                }
                            }.padding(.top, 8)
                        } label: {
                            Text(group.rawValue).font(.headline)
                        }
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
    @ViewBuilder private func capabilityRow(_ field: ProfileRandomField) -> some View {
        if field.isConfigurable {
            Toggle(field.title, isOn: fieldBinding(field)).font(.subheadline).tint(Palette.blue).padding(.vertical, 9)
        } else {
            HStack(spacing: 8) {
                Text(field.title).font(.subheadline)
                Spacer(minLength: 8)
                Text("Cố định hiện tại").font(.caption2.bold()).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.secondary.opacity(0.1), in: Capsule())
            }.padding(.vertical, 9)
        }
    }
    private func fieldBinding(_ field: ProfileRandomField) -> Binding<Bool> { Binding(get: { store.generationSettings.isEnabled(field) }, set: { value in var copy = store.generationSettings; copy.setEnabled(value, for: field); store.updateGenerationSettings(copy) }) }
    private var modelMinimumBinding: Binding<Int> { Binding(get: { store.generationSettings.modelMinimumIndex }, set: { var copy = store.generationSettings; copy.setModelMinimum($0); store.updateGenerationSettings(copy) }) }
    private var modelMaximumBinding: Binding<Int> { Binding(get: { store.generationSettings.modelMaximumIndex }, set: { var copy = store.generationSettings; copy.setModelMaximum($0); store.updateGenerationSettings(copy) }) }
    private var iosMinimumBinding: Binding<Int> { Binding(get: { store.generationSettings.iosMinimumIndex }, set: { var copy = store.generationSettings; copy.setIOSMinimum($0); store.updateGenerationSettings(copy) }) }
    private var iosMaximumBinding: Binding<Int> { Binding(get: { store.generationSettings.iosMaximumIndex }, set: { var copy = store.generationSettings; copy.setIOSMaximum($0); store.updateGenerationSettings(copy) }) }
}

