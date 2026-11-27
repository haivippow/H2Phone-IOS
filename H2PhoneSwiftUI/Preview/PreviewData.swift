import Foundation

enum PreviewData {
    static let profiles: [DeviceProfile] = [
        .init(id: UUID(), number: 2, createdAt: Date(timeIntervalSince1970: 1795746000), model: "iPhone 15 Pro", ios: "17.5.1", carrier: "Viettel", region: "Hồ Chí Minh", uptime: "2 giờ 14 phút", backupCount: 2, backupBytes: 116_000_000, isOriginal: false),
        .init(id: UUID(), number: 1, createdAt: Date(timeIntervalSince1970: 1795658400), model: "iPhone 14 Pro", ios: "17.4", carrier: "VinaPhone", region: "Hà Nội", uptime: nil, backupCount: 2, backupBytes: 128_000_000, isOriginal: false),
        .init(id: UUID(), number: 0, createdAt: Date(timeIntervalSince1970: 1795576200), model: "iPhone XS", ios: "16.1", carrier: "Viettel", region: "Hồ Chí Minh", uptime: nil, backupCount: 2, backupBytes: 98_000_000, isOriginal: true)
    ]

    static let apps: [TargetApp] = [
        .init(id: "com.zhiliaoapp.musically", name: "TikTok", symbol: "music.note", dataBytes: 350_000_000, fakeInfo: true, backupData: true, resetOnChange: true),
        .init(id: "com.twitter.twitter", name: "X", symbol: "xmark", dataBytes: 280_000_000, fakeInfo: true, backupData: true, resetOnChange: true),
        .init(id: "com.facebook.Facebook", name: "Facebook", symbol: "f", dataBytes: 420_000_000, fakeInfo: false, backupData: false, resetOnChange: false),
        .init(id: "com.burbn.instagram", name: "Instagram", symbol: "camera", dataBytes: 310_000_000, fakeInfo: false, backupData: false, resetOnChange: false),
        .init(id: "com.finalwire.aida64", name: "AIDA64", symbol: "cpu", dataBytes: 12_000_000, fakeInfo: false, backupData: false, resetOnChange: false)
    ]
}
