import SwiftUI

import UIKit

enum AppFilter: String, CaseIterable { case all = "Tất cả", selected = "Đã chọn", fake = "Fake Info", backup = "Backup & Làm sạch" }

struct AppsView: View {
    @EnvironmentObject private var store: H2Store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var filter: AppFilter = .all
    @State private var detail: TargetApp?
    private let filterColumns = [GridItem(.flexible()), GridItem(.flexible())]
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
                LazyVStack(alignment: .leading, spacing: 14) {
                    Label(store.discoveryMessage, systemImage: "info.circle").font(.caption).foregroundStyle(Palette.blue).frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Palette.pale, in: RoundedRectangle(cornerRadius: 14))
                    LazyVGrid(columns: filterColumns, spacing: 8) {
                        ForEach(AppFilter.allCases, id: \.self) { item in
                            Button { filter = item } label: {
                                Text("\(item.rawValue) (\(count(item)))")
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(filter == item ? .white : Palette.ink)
                                    .background(filter == item ? Palette.blue : .white, in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain)
                        }
                    }
                    if filtered.isEmpty { EmptyState(title: "Không có ứng dụng phù hợp", symbol: "square.grid.2x2") }
                    ForEach(filtered) { app in AppRow(app: app, detail: $detail) }
                }.padding(16)
            }.background(Palette.background).navigationTitle("Ứng dụng áp dụng").navigationBarTitleDisplayMode(.inline).searchable(text: $query, prompt: "Tìm ứng dụng đã cài")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { Button("Đóng") { dismiss() } }
                    ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await store.discover() } } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Quét ứng dụng") }
                }
                .sheet(item: $detail) { AppDetailView(bundleID: $0.id).environmentObject(store).presentationDetents([.medium]) }
                .task { await store.discoverIfNeeded() }
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
            VStack(alignment: .leading, spacing: 0) {
                Button { detail = app } label: {
                HStack(spacing: 12) {
                    AppIconView(app: app)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name).font(.headline).foregroundStyle(Palette.ink)
                        Text(app.id).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.75)
                        Label("Dữ liệu: \(app.dataBytes?.h2Size ?? "Chưa xác định")", systemImage: "internaldrive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                }.buttonStyle(.plain)
                Divider().padding(.vertical, 12)
                VStack(spacing: 12) {
                    AppSettingToggle(symbol: "iphone.gen3.radiowaves.left.and.right", title: "Fake Info", subtitle: "Áp dụng thông tin Profile cho app", isOn: binding(\.fakeInfo))
                    Divider()
                    AppSettingToggle(symbol: "externaldrive", title: "Backup & Làm sạch", subtitle: "Chỉ làm sạch sau khi backup được xác minh thành công", isOn: binding(\.backupData))
                }
            }
        }
    }
    private func binding(_ keyPath: WritableKeyPath<TargetApp, Bool>) -> Binding<Bool> { Binding(get: { store.apps.first(where: { $0.id == app.id })?[keyPath: keyPath] ?? false }, set: { value in guard var copy = store.apps.first(where: { $0.id == app.id }) else { return }; copy[keyPath: keyPath] = value; store.update(copy) }) }
}

struct AppIconView: View {
    private static let iconCache = NSCache<NSString, UIImage>()
    let app: TargetApp
    @State private var decodedIcon: UIImage?

    var body: some View {
        Group {
            if let decodedIcon {
                Image(uiImage: decodedIcon).resizable().scaledToFill()
            } else {
                Image(systemName: app.symbol)
                    .resizable()
                    .scaledToFit()
                    .padding(13)
                    .foregroundStyle(.white)
                    .background(Palette.blue)
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Color.black.opacity(0.06)) }
        .task(id: app.id) {
            let cacheKey = app.id as NSString
            if let cached = Self.iconCache.object(forKey: cacheKey) {
                decodedIcon = cached
                return
            }
            guard let data = app.iconPNGData else { return }
            let image = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value
            guard let image else { return }
            Self.iconCache.setObject(image, forKey: cacheKey)
            decodedIcon = image
        }
    }
}

struct AppSettingToggle: View {
    let symbol: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundStyle(Palette.blue).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn).labelsHidden().tint(Palette.blue)
        }
    }
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
                        Toggle("Backup & Làm sạch", isOn: binding(\.backupData))
                    }
                    if app.backupData { Section { Label("H2PHONE sẽ backup, xác minh rồi mới làm sạch dữ liệu khi Change.", systemImage: "checkmark.shield.fill").foregroundStyle(Palette.blue) } }
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
    private var unknownSize: Bool { backupApps.contains { $0.dataBytes == nil } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Tên Profile mới", text: $name).textFieldStyle(.roundedBorder)
                    Label("Profile hiện tại sẽ được lưu snapshot trước khi tạo profile mới.", systemImage: "square.stack.3d.up").font(.subheadline)
                    H2Card { VStack(alignment: .leading, spacing: 8) {
                        Text("Ứng dụng bị ảnh hưởng").font(.headline)
                        Text("Backup & làm sạch: \(backupApps.count) ứng dụng")
                        Text(store.selectedApps.map(\.name).joined(separator: ", ").isEmpty ? "Chưa chọn ứng dụng" : store.selectedApps.map(\.name).joined(separator: ", "))
                        Text("Dung lượng cần backup: \(unknownSize ? "Chưa xác định" : backupApps.compactMap(\.dataBytes).reduce(0, +).h2Size)").font(.caption).foregroundStyle(.secondary)
                    } }
                    H2Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Thông tin sẽ random").font(.headline)
                            Text(store.generationSettings.enabledFieldNames.isEmpty ? "Không random trường nào" : store.generationSettings.enabledFieldNames.joined(separator: ", "))
                                .font(.subheadline)
                            if store.generationSettings.randomizeModel { Label(store.generationSettings.modelRangeText, systemImage: "iphone").font(.caption).foregroundStyle(.secondary) }
                            if store.generationSettings.randomizeIOS { Label(store.generationSettings.iosRangeText, systemImage: "square.stack.3d.up").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    Label("Dữ liệu chỉ được làm sạch sau khi backup được xác minh thành công. Nếu backup lỗi, Change sẽ dừng lại.", systemImage: "checkmark.shield.fill").font(.caption).foregroundStyle(Palette.blue)
                    Label("Chưa khả dụng trên bản UI: cần service đóng app, backup, xác minh, làm sạch và áp dụng profile.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
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
                    H2Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dữ liệu sẽ khôi phục").font(.headline)
                            Text("\(profile.backupCount) ứng dụng • \(profile.backupBytes?.h2Size ?? "Chưa xác định")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Divider()
                            if profile.backedUpApps.isEmpty {
                                Label("Không có danh sách ứng dụng trong bản backup", systemImage: "tray")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(profile.backedUpApps) { app in
                                    BackupAppRow(app: app)
                                    if app.id != profile.backedUpApps.last?.id { Divider() }
                                }
                            }
                        }
                    }
                    Toggle("Backup trạng thái hiện tại trước khi quay lại", isOn: $backupCurrent).tint(Palette.blue)
                    Label("Dữ liệu chưa có bản backup có thể bị mất khi khôi phục.", systemImage: "exclamationmark.triangle.fill").font(.subheadline).foregroundStyle(.orange)
                    Label("Chưa khả dụng trên bản UI: chỉ báo hoàn tất khi service khôi phục trả về thành công.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                }.padding(20)
            }.background(Palette.background).navigationTitle("Xác nhận quay lại").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) {
                    HStack(spacing: 12) {
                        Button("Hủy") { dismiss() }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        Button("Quay lại bản này") {
                            dismiss()
                            Task { await store.restore(profile, backupCurrent: backupCurrent) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.blue)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
        }
    }
}

struct BackupAppRow: View {
    let app: ProfileAppBackup

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(Palette.blue)
                .frame(width: 38, height: 38)
                .background(Palette.pale, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name).font(.subheadline.bold())
                Text(app.bundleID).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(app.dataBytes?.h2Size ?? "Không rõ")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct EmptyState: View {
    let title: String
    let symbol: String
    var body: some View { VStack(spacing: 10) { Image(systemName: symbol).font(.largeTitle).foregroundStyle(Palette.blue); Text(title).font(.headline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(36) }
}
