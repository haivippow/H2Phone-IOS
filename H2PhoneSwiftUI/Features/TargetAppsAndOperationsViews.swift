import SwiftUI

enum AppFilter: String, CaseIterable { case all = "Tất cả", selected = "Đã chọn", fake = "Fake Info", backup = "Backup Data" }

struct AppsView: View {
    @EnvironmentObject private var store: H2Store
    @State private var query = ""
    @State private var filter: AppFilter = .all
    @State private var detail: TargetApp?
    private var filtered: [TargetApp] {
        store.apps.filter { app in
            let matches = query.isEmpty || app.name.localizedCaseInsensitiveContains(query) || app.id.localizedCaseInsensitiveContains(query)
            let matchesFilter: Bool
            switch filter { case .all: matchesFilter = true; case .selected: matchesFilter = app.isSelected; case .fake: matchesFilter = app.fakeInfo; case .backup: matchesFilter = app.backupData }
            return matches && matchesFilter
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Label(store.discoveryMessage, systemImage: "info.circle").font(.caption).foregroundStyle(Palette.blue).frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Palette.pale, in: RoundedRectangle(cornerRadius: 14))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) { ForEach(AppFilter.allCases, id: \.self) { item in Button { filter = item } label: { Text("\(item.rawValue) (\(count(item)))").font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 9).foregroundStyle(filter == item ? .white : Palette.ink).background(filter == item ? Palette.blue : .white, in: Capsule()) }.buttonStyle(.plain) } }
                    }
                    if filtered.isEmpty { EmptyState(title: "Không có ứng dụng phù hợp", symbol: "square.grid.2x2") }
                    ForEach(filtered) { app in AppRow(app: app, detail: $detail) }
                }.padding(16)
            }.background(Palette.background).navigationTitle("App mục tiêu").searchable(text: $query, prompt: "Tìm ứng dụng đã cài")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await store.discover() } } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Quét ứng dụng") } }
                .sheet(item: $detail) { AppDetailView(bundleID: $0.id).environmentObject(store).presentationDetents([.medium]) }
        }
    }
    private func count(_ item: AppFilter) -> Int { switch item { case .all: return store.apps.count; case .selected: return store.apps.filter(\.isSelected).count; case .fake: return store.apps.filter(\.fakeInfo).count; case .backup: return store.apps.filter(\.backupData).count } }
}

struct AppRow: View {
    @EnvironmentObject private var store: H2Store
    let app: TargetApp
    @Binding var detail: TargetApp?
    var body: some View {
        H2Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: app.symbol).font(.title2.bold()).foregroundStyle(.white).frame(width: 48, height: 48).background(Palette.blue, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Button { detail = app } label: { HStack { Text(app.name).font(.headline); Image(systemName: "chevron.right").font(.caption) } }.buttonStyle(.plain)
                    Text(app.id).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
                    Text("Dữ liệu: \(app.dataBytes?.h2Size ?? "Chưa xác định")").font(.caption)
                    if app.resetOnChange && !app.backupData { Text("Reset không backup: có thể mất dữ liệu").font(.caption2).foregroundStyle(.red) }
                }
                Spacer(minLength: 0)
            }
            Divider().padding(.vertical, 4)
            HStack(spacing: 14) {
                Toggle("Fake Info", isOn: binding(\.fakeInfo)).font(.caption)
                Toggle("Backup Data", isOn: binding(\.backupData)).font(.caption)
            }.tint(Palette.blue)
        }
    }
    private func binding(_ keyPath: WritableKeyPath<TargetApp, Bool>) -> Binding<Bool> { Binding(get: { store.apps.first(where: { $0.id == app.id })?[keyPath: keyPath] ?? false }, set: { value in var copy = app; copy[keyPath: keyPath] = value; store.update(copy) }) }
}

struct AppDetailView: View {
    @EnvironmentObject private var store: H2Store
    @Environment(\.dismiss) private var dismiss
    let bundleID: String
    private var app: TargetApp? { store.apps.first { $0.id == bundleID } }
    var body: some View {
        NavigationStack {
            Form {
                if let app {
                    Section { Text(app.id).font(.caption); Text("Dữ liệu cục bộ: \(app.dataBytes?.h2Size ?? "Chưa xác định")") }
                    Section("Cấu hình") {
                        Toggle("Fake Info", isOn: binding(\.fakeInfo))
                        Toggle("Backup Data", isOn: binding(\.backupData))
                        Toggle("Reset Data on Change", isOn: binding(\.resetOnChange))
                    }
                    if app.resetOnChange && !app.backupData { Section { Label("Dữ liệu sẽ bị xóa nếu Change thực sự chạy. Hãy bật Backup Data nếu cần giữ lại.", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) } }
                }
            }.navigationTitle(app?.name ?? "Ứng dụng").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { dismiss() } } }
        }
    }
    private func binding(_ keyPath: WritableKeyPath<TargetApp, Bool>) -> Binding<Bool> { Binding(get: { app?[keyPath: keyPath] ?? false }, set: { value in guard var copy = app else { return }; copy[keyPath: keyPath] = value; store.update(copy) }) }
}

struct ChangeSheet: View {
    @EnvironmentObject private var store: H2Store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    private var backupApps: [TargetApp] { store.apps.filter { $0.backupData } }
    private var resetApps: [TargetApp] { store.apps.filter { $0.resetOnChange } }
    private var unknownSize: Bool { backupApps.contains { $0.dataBytes == nil } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Tên Profile mới", text: $name).textFieldStyle(.roundedBorder)
                    Label("Profile hiện tại sẽ được lưu snapshot trước khi tạo profile mới.", systemImage: "square.stack.3d.up").font(.subheadline)
                    H2Card { VStack(alignment: .leading, spacing: 8) {
                        Text("Ứng dụng bị ảnh hưởng").font(.headline)
                        Text("Backup: \(backupApps.count) • Reset: \(resetApps.count)")
                        Text(store.selectedApps.map(\.name).joined(separator: ", ").isEmpty ? "Chưa chọn ứng dụng" : store.selectedApps.map(\.name).joined(separator: ", "))
                        Text("Dung lượng cần backup: \(unknownSize ? "Chưa xác định" : backupApps.compactMap(\.dataBytes).reduce(0, +).h2Size)").font(.caption).foregroundStyle(.secondary)
                    } }
                    if resetApps.contains(where: { !$0.backupData }) { Label("Có ứng dụng được reset mà không backup. Dữ liệu có thể mất vĩnh viễn.", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.subheadline) }
                    Label("Chưa khả dụng trên bản UI: cần service đóng app, backup, xác minh, reset và áp dụng profile.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    HStack { Button("Hủy") { dismiss() }.frame(maxWidth: .infinity); Button("Thực hiện") { let value = name.trimmingCharacters(in: .whitespacesAndNewlines); dismiss(); Task { await store.change(name: value.isEmpty ? store.nextName : value) } }.buttonStyle(.borderedProminent).tint(Palette.blue).frame(maxWidth: .infinity) }
                }.padding(20)
            }.background(Palette.background).navigationTitle("Xác nhận Change").navigationBarTitleDisplayMode(.inline)
                .onAppear { name = store.nextName }
        }
    }
}

struct RollbackSheet: View {
    @EnvironmentObject private var store: H2Store
    @Environment(\.dismiss) private var dismiss
    let profile: DeviceProfile
    @State private var backupCurrent = true
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Khôi phục \(profile.name)").font(.title3.bold())
                    Text("\(profile.model) • iOS \(profile.ios) • \(profile.createdAt.h2Text)")
                    H2Card { VStack(alignment: .leading, spacing: 8) { Text("Dữ liệu sẽ khôi phục").font(.headline); Text("\(profile.backupCount) ứng dụng • \(profile.backupBytes?.h2Size ?? "Chưa xác định")"); Text("Danh sách app trong snapshot chưa khả dụng; cần đọc manifest backup thực tế.").font(.caption).foregroundStyle(.secondary) } }
                    Toggle("Backup trạng thái hiện tại trước khi quay lại", isOn: $backupCurrent).tint(Palette.blue)
                    Label("Dữ liệu chưa có bản backup có thể bị mất khi khôi phục.", systemImage: "exclamationmark.triangle.fill").font(.subheadline).foregroundStyle(.orange)
                    Label("Chưa khả dụng trên bản UI: chỉ báo hoàn tất khi service khôi phục trả về thành công.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    HStack { Button("Hủy") { dismiss() }.frame(maxWidth: .infinity); Button("Quay lại bản này") { dismiss(); Task { await store.restore(profile, backupCurrent: backupCurrent) } }.buttonStyle(.borderedProminent).tint(Palette.blue).frame(maxWidth: .infinity) }
                }.padding(20)
            }.background(Palette.background).navigationTitle("Xác nhận quay lại").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EmptyState: View {
    let title: String
    let symbol: String
    var body: some View { VStack(spacing: 10) { Image(systemName: symbol).font(.largeTitle).foregroundStyle(Palette.blue); Text(title).font(.headline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(36) }
}
