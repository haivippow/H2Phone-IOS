import Foundation

enum PreviewData {
    static let profiles: [DeviceProfile] = [
        .init(id: UUID(), number: 2, createdAt: Date(timeIntervalSince1970: 1795746000), model: "iPhone 15 Pro", ios: "17.5.1", carrier: "Viettel", region: "Hồ Chí Minh", uptime: "2 giờ 14 phút", backedUpApps: [.init(bundleID: "com.zhiliaoapp.musically", name: "TikTok", dataBytes: 62_000_000), .init(bundleID: "com.twitter.twitter", name: "X", dataBytes: 54_000_000)], isOriginal: false),
        .init(id: UUID(), number: 1, createdAt: Date(timeIntervalSince1970: 1795658400), model: "iPhone 14 Pro", ios: "17.4", carrier: "VinaPhone", region: "Hà Nội", uptime: nil, backedUpApps: [.init(bundleID: "com.zhiliaoapp.musically", name: "TikTok", dataBytes: 70_000_000), .init(bundleID: "com.twitter.twitter", name: "X", dataBytes: 58_000_000)], isOriginal: false),
        .init(id: UUID(), number: 0, createdAt: Date(timeIntervalSince1970: 1795576200), model: "iPhone XS", ios: "16.1", carrier: "Viettel", region: "Hồ Chí Minh", uptime: nil, backedUpApps: [.init(bundleID: "com.h2phone.dev", name: "H2DEV", dataBytes: 40_000_000), .init(bundleID: "com.apple.mobilesafari", name: "Safari", dataBytes: 58_000_000)], isOriginal: true)
    ]

    static let apps: [TargetApp] = [
        .init(id: "com.zhiliaoapp.musically", name: "TikTok", symbol: "music.note", iconPNGData: nil, dataBytes: 350_000_000, fakeInfo: true, backupData: true),
        .init(id: "com.twitter.twitter", name: "X", symbol: "xmark", iconPNGData: nil, dataBytes: 280_000_000, fakeInfo: true, backupData: true),
        .init(id: "com.facebook.Facebook", name: "Facebook", symbol: "f", iconPNGData: nil, dataBytes: 420_000_000, fakeInfo: false, backupData: false),
        .init(id: "com.burbn.instagram", name: "Instagram", symbol: "camera", iconPNGData: nil, dataBytes: 310_000_000, fakeInfo: false, backupData: false),
        .init(id: "com.finalwire.aida64", name: "AIDA64", symbol: "cpu", iconPNGData: nil, dataBytes: 12_000_000, fakeInfo: false, backupData: false)
    ]
}
