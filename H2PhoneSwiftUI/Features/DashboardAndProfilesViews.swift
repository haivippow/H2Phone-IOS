import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: H2Store
    @State private var tab = 0
    @State private var showChange = false
    @State private var showTargetApps = false
    @State private var rollbackTarget: DeviceProfile?
    var body: some View {
        TabView(selection: $tab) {
            DashboardView(tab: $tab, showChange: $showChange, showTargetApps: $showTargetApps, rollbackTarget: $rollbackTarget)
                .tabItem { Label("Điều khiển", systemImage: "house.fill") }.tag(0)
            ProfilesView(rollbackTarget: $rollbackTarget)
                .tabItem { Label("Profile", systemImage: "square.stack.fill") }.tag(1)
        }
        .tint(Palette.blue)
        .sheet(isPresented: $showChange) { ChangeSheet().environmentObject(store).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showTargetApps) { AppsView().environmentObject(store).presentationDetents([.large]) }
        .sheet(item: $rollbackTarget) { RollbackSheet(profile: $0).environmentObject(store).presentationDetents([.large]) }
        .alert("Trạng thái", isPresented: Binding(get: { if case .unavailable = store.operation { return true }; if case .error = store.operation { return true }; if case .success = store.operation { return true }; return false }, set: { if !$0 { store.operation = .idle } })) {
            Button("Đóng", role: .cancel) { store.operation = .idle }
        } message: {
            switch store.operation { case .unavailable(let value), .error(let value), .success(let value): Text(value); default: Text("") }
        }
        .overlay { if case .loading(let message) = store.operation { ZStack { Color.black.opacity(0.2).ignoresSafeArea(); ProgressView(message).padding(28).background(.white, in: RoundedRectangle(cornerRadius: 18)) } } }
    }
}

struct H2Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.white, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.blue.opacity(0.12))).shadow(color: Palette.blue.opacity(0.05), radius: 10, y: 4) }
}

struct Badge: View {
    let text: String
    var body: some View { Text(text).font(.caption.bold()).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 5).background(Color.green, in: Capsule()) }
}

struct PhoneGlyph: View {
    var body: some View { ZStack { RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(red: 0.16, green: 0.42, blue: 0.86), Color(red: 0.72, green: 0.83, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing)); RoundedRectangle(cornerRadius: 10).stroke(Palette.ink, lineWidth: 2); Image(systemName: "apple.logo").foregroundStyle(.white) }.frame(width: 42, height: 76) }
}

struct DashboardView: View {
    @EnvironmentObject private var store: H2Store
    @Binding var tab: Int
    @Binding var showChange: Bool
    @Binding var showTargetApps: Bool
    @Binding var rollbackTarget: DeviceProfile?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Image("Icon-1024")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Palette.blue.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: Palette.blue.opacity(0.14), radius: 10, y: 4)
                    Text("H2PHONE").font(.title.bold())
                    Text("Quản lý cấu hình thiết bị & dữ liệu ứng dụng")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                if let profile = store.active {
                    H2Card {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 14) {
                                PhoneGlyph()
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack { Text(profile.name).font(.title2.bold()); Badge(text: "Đang dùng") }
                                    Text("Tạo: \(profile.createdAt.h2Text)").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                metric("iphone", profile.model, "Model")
                                metric("info.circle", "iOS \(profile.ios)", "iOS")
                                metric("antenna.radiowaves.left.and.right", profile.carrier, "Nhà mạng")
                                metric("location", profile.region, "Vùng / IP")
                            }
                            if let uptime = profile.uptime { Label("Uptime: \(uptime)", systemImage: "clock").font(.caption).foregroundStyle(.secondary) }
                        }
                    }.background(Palette.pale, in: RoundedRectangle(cornerRadius: 18))
                } else { EmptyState(title: "Chưa có Profile", symbol: "iphone") }
                Button { showTargetApps = true } label: {
                    H2Card { HStack(spacing: 12) { Image(systemName: "square.stack.3d.up.fill").foregroundStyle(Palette.blue); VStack(alignment: .leading, spacing: 3) { Text("Đang áp dụng cho \(store.selectedApps.count) ứng dụng").font(.subheadline.bold()); Text(store.selectedApps.map(\.name).joined(separator: ", ")).font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Spacer(); Image(systemName: "chevron.right") } }
                }.buttonStyle(.plain)
                Button { showChange = true } label: { Label("Change", systemImage: "arrow.triangle.2.circlepath").font(.title3.bold()).frame(maxWidth: .infinity).padding(17).foregroundStyle(.white).background(Palette.blue, in: RoundedRectangle(cornerRadius: 16)) }
                VStack(alignment: .leading, spacing: 12) {
                    HStack { Text("Profile gần đây").font(.title3.bold()); Spacer(); Button("Xem tất cả") { tab = 1 }.font(.subheadline) }
                    let recent = store.profiles.filter { $0.id != store.activeID }.sorted { $0.createdAt > $1.createdAt }.prefix(3)
                    if recent.isEmpty { Text("Chưa có profile gần đây").foregroundStyle(.secondary).padding() }
                    ForEach(Array(recent)) { profile in
                        H2Card { HStack(spacing: 12) { PhoneGlyph(); VStack(alignment: .leading, spacing: 4) { Text(profile.name).font(.headline); Text(profile.createdAt.h2Text).font(.caption).foregroundStyle(.secondary); Text("\(profile.model) • iOS \(profile.ios)").font(.caption) }; Spacer(minLength: 4); Button { rollbackTarget = profile } label: { Image(systemName: "arrow.uturn.backward.circle.fill").font(.title2) }.accessibilityLabel("Quay lại \(profile.name)") } }
                    }
                }
            }.padding(20)
        }.background(Palette.background).foregroundStyle(Palette.ink)
    }
    private func metric(_ symbol: String, _ value: String, _ caption: String) -> some View { HStack(spacing: 8) { Image(systemName: symbol).foregroundStyle(Palette.blue); VStack(alignment: .leading) { Text(value).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.75); Text(caption).font(.caption2).foregroundStyle(.secondary) }; Spacer(minLength: 0) }.padding(9).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 11)) }
}

struct ProfilesView: View {
    @EnvironmentObject private var store: H2Store
    @Binding var rollbackTarget: DeviceProfile?
    @State private var query = ""
    @State private var profilePendingDeletion: DeviceProfile?
    private var filtered: [DeviceProfile] { store.profiles.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.model.localizedCaseInsensitiveContains(query) }.sorted { $0.createdAt > $1.createdAt } }
    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    EmptyState(title: "Không tìm thấy Profile", symbol: "magnifyingglass")
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                ForEach(filtered) { profile in
                    H2Card {
                        HStack(alignment: .top, spacing: 13) {
                            PhoneGlyph()
                            VStack(alignment: .leading, spacing: 7) {
                                HStack { Text(profile.name).font(.headline); if profile.id == store.activeID { Badge(text: "Đang dùng") }; if profile.isOriginal { Text("Máy gốc").font(.caption.bold()).foregroundStyle(Palette.blue) } }
                                Text(profile.createdAt.h2Text).font(.caption).foregroundStyle(.secondary)
                                Text("\(profile.model) • iOS \(profile.ios) • \(profile.carrier)").font(.caption)
                                Label("Backup: \(profile.backupCount) app • \(profile.backupBytes?.h2Size ?? "Chưa xác định")", systemImage: "externaldrive.fill").font(.caption).foregroundStyle(Palette.blue)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(profile.id == store.activeID ? Palette.blue : .clear, lineWidth: 1.5))
                    .contentShape(RoundedRectangle(cornerRadius: 18))
                    .onTapGesture {
                        if profile.id != store.activeID {
                            rollbackTarget = profile
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if profile.id != store.activeID && !profile.isOriginal {
                            Button(role: .destructive) {
                                profilePendingDeletion = profile
                            } label: {
                                Label("Xóa", systemImage: "trash")
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("Lịch sử Profile")
            .searchable(text: $query, prompt: "Tên profile hoặc dòng máy")
            .alert(
                "Xóa Profile?",
                isPresented: Binding(
                    get: { profilePendingDeletion != nil },
                    set: { if !$0 { profilePendingDeletion = nil } }
                ),
                presenting: profilePendingDeletion
            ) { profile in
                Button("Hủy", role: .cancel) { profilePendingDeletion = nil }
                Button("Xóa", role: .destructive) {
                    store.deleteProfile(profile)
                    profilePendingDeletion = nil
                }
            } message: { profile in
                Text("Profile \(profile.name) sẽ bị xóa khỏi lịch sử.")
            }
        }
    }
}



#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView().environmentObject(H2Store(service: UnavailableDeviceService()))
    }
}
#endif
