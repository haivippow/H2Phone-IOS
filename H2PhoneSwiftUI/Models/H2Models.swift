import Foundation

struct ProfileAppBackup: Identifiable, Hashable {
    let bundleID: String
    let name: String
    let dataBytes: Int64?

    var id: String { bundleID }
}

struct DeviceProfile: Identifiable, Hashable {
    let id: UUID
    let number: Int
    let createdAt: Date
    let model: String
    let ios: String
    let carrier: String
    let region: String
    let uptime: String?
    let backedUpApps: [ProfileAppBackup]
    let isOriginal: Bool

    var name: String { String(format: "Profile #%02d", number) }
    var backupCount: Int { backedUpApps.count }
    var backupBytes: Int64? {
        guard backedUpApps.allSatisfy({ $0.dataBytes != nil }) else { return nil }
        return backedUpApps.compactMap(\.dataBytes).reduce(0, +)
    }
}

struct TargetApp: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let iconPNGData: Data?
    let dataBytes: Int64?
    var fakeInfo: Bool
    var backupData: Bool
    var resetOnChange: Bool

    var isSelected: Bool { fakeInfo || backupData || resetOnChange }
}

enum OperationState: Equatable {
    case idle
    case loading(String)
    case success(String)
    case error(String)
    case unavailable(String)
}

extension Date {
    var h2Text: String {
        formatted(.dateTime.day().month().year().hour().minute().locale(Locale(identifier: "vi_VN")))
    }
}

extension Int64 {
    var h2Size: String { ByteCountFormatter.string(fromByteCount: self, countStyle: .file) }
}
