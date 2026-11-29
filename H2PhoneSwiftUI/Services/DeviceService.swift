import Foundation

protocol DeviceService {
    func discoveredApps() async throws -> [TargetApp]
    func change(to name: String, apps: [TargetApp], settings: ProfileGenerationSettings) async throws -> DeviceProfile
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
    func change(to name: String, apps: [TargetApp], settings: ProfileGenerationSettings) async throws -> DeviceProfile { throw DeviceServiceError.unavailable }
    func restore(_ profile: DeviceProfile, backupCurrent: Bool) async throws { throw DeviceServiceError.unavailable }
}

struct InstalledAppDeviceService: DeviceService {
    private let generator: DeviceProfileGenerator

    init(generator: DeviceProfileGenerator = DeviceProfileGenerator()) {
        self.generator = generator
    }

    func discoveredApps() async throws -> [TargetApp] {
#if THEOS
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let apps = H2InstalledAppService.installedApplications().compactMap { record -> TargetApp? in
                    guard let bundleID = record["id"] as? String,
                          let name = record["name"] as? String else { return nil }
                    return TargetApp(
                        id: bundleID,
                        name: name,
                        symbol: "app.fill",
                        iconPNGData: record["iconPNGData"] as? Data,
                        dataBytes: nil,
                        fakeInfo: (record["fakeInfo"] as? NSNumber)?.boolValue ?? false,
                        backupData: false
                    )
                }
                continuation.resume(returning: apps)
            }
        }
#else
        throw DeviceServiceError.unavailable
#endif
    }

    func change(to name: String, apps: [TargetApp], settings: ProfileGenerationSettings) async throws -> DeviceProfile {
#if THEOS
        let generated = try generator.generate(settings: settings)
        let enabledApps = apps.filter(\.fakeInfo).map(\.id)
        try H2ProfileActivationService.activateProfile(generated.propertyList, enabledApps: enabledApps)
        let digits = name.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return DeviceProfile(
            id: UUID(),
            number: Int(digits) ?? 0,
            createdAt: Date(),
            model: generated.marketingName,
            ios: generated.iosVersion,
            carrier: generated.propertyList["carrier"] as? String ?? "",
            region: generated.propertyList["country"] as? String ?? "",
            uptime: nil,
            backedUpApps: apps.filter(\.backupData).map {
                ProfileAppBackup(bundleID: $0.id, name: $0.name, dataBytes: $0.dataBytes)
            },
            isOriginal: false
        )
#else
        throw DeviceServiceError.unavailable
#endif
    }

    func restore(_ profile: DeviceProfile, backupCurrent: Bool) async throws {
        throw DeviceServiceError.unavailable
    }
}
