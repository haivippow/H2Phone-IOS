import Foundation

protocol DeviceService {
    func discoveredApps() async throws -> [TargetApp]
    func change(to name: String, apps: [TargetApp]) async throws -> DeviceProfile
    func restore(_ profile: DeviceProfile, backupCurrent: Bool) async throws
}

enum DeviceServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Chưa khả dụng: chưa kết nối dịch vụ backup, reset và khôi phục trên thiết bị."
    }
}

struct UnavailableDeviceService: DeviceService {
    func discoveredApps() async throws -> [TargetApp] { throw DeviceServiceError.unavailable }
    func change(to name: String, apps: [TargetApp]) async throws -> DeviceProfile { throw DeviceServiceError.unavailable }
    func restore(_ profile: DeviceProfile, backupCurrent: Bool) async throws { throw DeviceServiceError.unavailable }
}
