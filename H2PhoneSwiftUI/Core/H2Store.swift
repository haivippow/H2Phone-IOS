import Combine
import Foundation

@MainActor
final class H2Store: ObservableObject {
    @Published var profiles: [DeviceProfile] = PreviewData.profiles
    @Published var activeID: UUID = PreviewData.profiles[0].id
    @Published var apps: [TargetApp] = PreviewData.apps
    @Published var operation: OperationState = .idle
    @Published var discoveryMessage = "Dữ liệu minh họa • Chưa kết nối quyền đọc ứng dụng trên thiết bị"

    private let service: DeviceService

    init(service: DeviceService) {
        self.service = service
    }

    var active: DeviceProfile? { profiles.first { $0.id == activeID } }
    var selectedApps: [TargetApp] { apps.filter(\.isSelected) }
    var nextName: String { String(format: "Profile #%02d", (profiles.map(\.number).max() ?? -1) + 1) }

    func update(_ app: TargetApp) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) { apps[index] = app }
    }

    func discover() async {
        do {
            apps = try await service.discoveredApps()
            discoveryMessage = "Ứng dụng đã phát hiện"
        } catch {
            discoveryMessage = error.localizedDescription
        }
    }

    func change(name: String) async {
        operation = .loading("Đang thực hiện Change…")
        do {
            let result = try await service.change(to: name, apps: selectedApps)
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
