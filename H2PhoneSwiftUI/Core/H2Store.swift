import Combine
import Foundation

@MainActor
final class H2Store: ObservableObject {
    @Published var profiles: [DeviceProfile]
    @Published var activeID: UUID
    @Published var apps: [TargetApp]
    @Published var generationSettings: ProfileGenerationSettings
    @Published var operation: OperationState = .idle
    @Published var discoveryMessage = "Dữ liệu minh họa • Chưa kết nối quyền đọc ứng dụng trên thiết bị"

    private let service: DeviceService
    private let settingsService: ProfileSettingsService
    private var hasDiscoveredApps = false

    init(
        service: DeviceService,
        settingsService: ProfileSettingsService = UserDefaultsProfileSettingsService(),
        profiles: [DeviceProfile] = PreviewData.profiles,
        apps: [TargetApp] = PreviewData.apps
    ) {
        self.service = service
        self.settingsService = settingsService
        self.generationSettings = settingsService.load()
        self.profiles = profiles
        self.activeID = profiles.first?.id ?? UUID()
        self.apps = apps
    }

    var active: DeviceProfile? { profiles.first { $0.id == activeID } }
    var selectedApps: [TargetApp] { apps.filter(\.isSelected) }
    var nextName: String { String(format: "Profile #%02d", (profiles.map(\.number).max() ?? -1) + 1) }

    func update(_ app: TargetApp) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) { apps[index] = app }
    }

    func updateGenerationSettings(_ settings: ProfileGenerationSettings) {
        var normalized = settings
        normalized.normalizeRanges()
        generationSettings = normalized
        settingsService.save(normalized)
    }

    func discover() async {
        discoveryMessage = "Đang quét ứng dụng trên thiết bị…"
        do {
            apps = try await service.discoveredApps()
            hasDiscoveredApps = true
            discoveryMessage = apps.isEmpty
                ? "Không tìm thấy ứng dụng có thể truy cập"
                : "Đã phát hiện \(apps.count) ứng dụng trên thiết bị"
        } catch {
            discoveryMessage = error.localizedDescription
        }
    }

    func discoverIfNeeded() async {
        guard !hasDiscoveredApps else { return }
        await discover()
    }

    func deleteProfile(_ profile: DeviceProfile) {
        guard profile.id != activeID, !profile.isOriginal else { return }
        profiles.removeAll { $0.id == profile.id }
    }

    func change(name: String) async {
        operation = .loading("Đang thực hiện Change…")
        do {
            let result = try await service.change(to: name, apps: selectedApps, settings: generationSettings)
            profiles.insert(result, at: 0)
            activeID = result.id
            operation = .success("Đã áp dụng \(result.name)")
        } catch {
            operation = .unavailable(error.localizedDescription)
        }
    }

    func restore(_ profile: DeviceProfile, backupCurrent: Bool) async {
        operation = .loading("Đang khôi phục…")
        do {
            try await service.restore(profile, backupCurrent: backupCurrent)
            activeID = profile.id
            operation = .success("Đã khôi phục \(profile.name)")
        } catch {
            operation = .unavailable(error.localizedDescription)
        }
    }
}
