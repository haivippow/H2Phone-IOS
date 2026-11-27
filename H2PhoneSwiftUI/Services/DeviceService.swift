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

struct InstalledAppDeviceService: DeviceService {
    func discoveredApps() async throws -> [TargetApp] {
#if THEOS
        return H2InstalledAppService.installedApplications().compactMap { record in
            guard let bundleID = record["id"] as? String,
                  let name = record["name"] as? String else { return nil }
            return TargetApp(
                id: bundleID,
                name: name,
                symbol: "app.fill",
                iconPNGData: record["iconPNGData"] as? Data,
                dataBytes: nil,
                fakeInfo: (record["fakeInfo"] as? NSNumber)?.boolValue ?? false,
                backupData: false,
                resetOnChange: false
            )
        }
#else
        throw DeviceServiceError.unavailable
#endif
    }

    func change(to name: String, apps: [TargetApp]) async throws -> DeviceProfile {
        throw DeviceServiceError.unavailable
    }

    func restore(_ profile: DeviceProfile, backupCurrent: Bool) async throws {
        throw DeviceServiceError.unavailable
    }
}
