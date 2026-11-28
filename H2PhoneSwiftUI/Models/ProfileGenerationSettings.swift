import Foundation

struct DeviceCompatibility: Equatable {
    let minimumIOS: String
    let maximumIOS: String
}

enum ProfileCapabilityGroup: String, CaseIterable, Identifiable {
    case device = "Thiết bị & phần cứng"
    case operatingSystem = "iOS & kernel"
    case identifiers = "Định danh thiết bị"
    case batteryAndSystem = "Pin & trạng thái hệ thống"
    case network = "Nhà mạng & Wi‑Fi"
    case location = "Vị trí"
    case locale = "Ngôn ngữ, vùng & múi giờ"
    case sensors = "Cảm biến"
    case webFingerprint = "Web fingerprint"
    var id: String { rawValue }
}

enum ProfileRandomField: String, Codable, CaseIterable, Identifiable {
    case deviceName, deviceModel, iosVersion, idfv, idfa, imei, imei2, batteryLevel, timeZone, wifi, location, webGL
    case memory, processor, storage, screen, touchPoints, kernelBuild, userAgent
    case batteryState, uptime, thermalState, lowPowerMode, carrier, radioAccess, locationMetadata
    case locale, preferredLanguages, accelerometer, gyroscope, deviceMotion
    case browserNavigator, webScreen, canvas, audio, fonts, mediaCodecs, permissions, mediaDevices

    var id: String { rawValue }
    var group: ProfileCapabilityGroup {
        switch self {
        case .deviceName, .deviceModel, .memory, .processor, .storage, .screen, .touchPoints: return .device
        case .iosVersion, .kernelBuild, .userAgent: return .operatingSystem
        case .idfv, .idfa, .imei, .imei2: return .identifiers
        case .batteryLevel, .batteryState, .uptime, .thermalState, .lowPowerMode: return .batteryAndSystem
        case .carrier, .radioAccess, .wifi: return .network
        case .location, .locationMetadata: return .location
        case .locale, .preferredLanguages, .timeZone: return .locale
        case .accelerometer, .gyroscope, .deviceMotion: return .sensors
        case .browserNavigator, .webScreen, .canvas, .audio, .fonts, .webGL, .mediaCodecs, .permissions, .mediaDevices: return .webFingerprint
        }
    }
    var title: String {
        switch self {
        case .deviceName: return "Tên thiết bị"
        case .deviceModel: return "Model, ProductType & Board"
        case .iosVersion: return "Phiên bản iOS"
        case .idfv: return "IDFV / UUID"
        case .idfa: return "IDFA"
        case .imei: return "IMEI"
        case .imei2: return "IMEI2"
        case .batteryLevel: return "Mức pin"
        case .timeZone: return "Múi giờ"
        case .wifi: return "Wi‑Fi SSID & BSSID"
        case .location: return "Tọa độ latitude & longitude"
        case .webGL: return "WebGL vendor & renderer"
        case .memory: return "Dung lượng RAM"
        case .processor: return "Số lõi CPU"
        case .storage: return "Bộ nhớ tổng & còn trống"
        case .screen: return "Kích thước & scale màn hình"
        case .touchPoints: return "Số điểm chạm"
        case .kernelBuild: return "Build & Darwin kernel"
        case .userAgent: return "User-Agent"
        case .batteryState: return "Trạng thái pin"
        case .uptime: return "Uptime & thời điểm boot"
        case .thermalState: return "Trạng thái nhiệt"
        case .lowPowerMode: return "Low Power Mode"
        case .carrier: return "Nhà mạng, MCC, MNC & quốc gia"
        case .radioAccess: return "Công nghệ sóng di động"
        case .locationMetadata: return "Độ cao, độ chính xác, tốc độ & hướng"
        case .locale: return "Locale / vùng"
        case .preferredLanguages: return "Ngôn ngữ ưu tiên"
        case .accelerometer: return "Gia tốc kế"
        case .gyroscope: return "Con quay hồi chuyển"
        case .deviceMotion: return "Gravity & Device Motion"
        case .browserNavigator: return "Navigator platform, vendor & language"
        case .webScreen: return "Screen & devicePixelRatio trên web"
        case .canvas: return "Canvas fingerprint"
        case .audio: return "Audio fingerprint"
        case .fonts: return "Font fingerprint"
        case .mediaCodecs: return "Codec & Media Capabilities"
        case .permissions: return "Permissions fingerprint"
        case .mediaDevices: return "Danh sách media devices"
        }
    }
    var isConfigurable: Bool {
        switch self {
        case .deviceName, .deviceModel, .iosVersion, .idfv, .idfa, .imei, .imei2, .batteryLevel,
             .memory, .processor, .storage, .screen, .touchPoints, .kernelBuild, .userAgent,
             .uptime, .carrier, .wifi, .location, .webGL: return true
        default: return false
        }
    }
    static let defaultEnabled: Set<ProfileRandomField> = [.deviceModel, .iosVersion, .carrier, .location, .locale, .preferredLanguages, .timeZone]
}

struct ProfileGenerationSettings: Codable, Equatable {
    static let legacyModelOptions = [
        "iPhone XS", "iPhone XS Max", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max",
        "iPhone 12", "iPhone 12 Pro", "iPhone 12 Pro Max", "iPhone 13", "iPhone 13 Pro",
        "iPhone 13 Pro Max", "iPhone 14", "iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone 15",
        "iPhone 15 Pro", "iPhone 15 Pro Max", "iPhone 16", "iPhone 16 Pro", "iPhone 16 Pro Max"
    ]
    static let legacyIOSOptions = ["16.0", "16.1", "16.2", "16.3", "16.4", "16.5", "16.6", "17.0", "17.1", "17.2", "17.3", "17.4", "17.5", "17.6", "18.0", "18.1"]
    static let modelOptions = [
        "iPhone 7", "iPhone 7 Plus", "iPhone 8", "iPhone 8 Plus", "iPhone X",
        "iPhone XS", "iPhone XS Max", "iPhone XR", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max",
        "iPhone SE (2nd generation)", "iPhone 12 mini", "iPhone 12", "iPhone 12 Pro", "iPhone 12 Pro Max",
        "iPhone 13 mini", "iPhone 13", "iPhone 13 Pro", "iPhone 13 Pro Max", "iPhone SE (3rd generation)",
        "iPhone 14", "iPhone 14 Plus", "iPhone 14 Pro", "iPhone 14 Pro Max",
        "iPhone 15", "iPhone 15 Plus", "iPhone 15 Pro", "iPhone 15 Pro Max",
        "iPhone 16e", "iPhone 16", "iPhone 16 Plus", "iPhone 16 Pro", "iPhone 16 Pro Max",
        "iPhone 17e", "iPhone 17", "iPhone Air", "iPhone 17 Pro", "iPhone 17 Pro Max",
        "iPhone 18 Pro", "iPhone 18 Pro Max"
    ]
    static let iosOptions = [
        "10.0", "10.1", "10.2", "10.3", "11.0", "11.1", "11.2", "11.3", "11.4",
        "12.0", "12.1", "12.2", "12.3", "12.4", "12.5", "13.0", "13.1", "13.2", "13.3", "13.4", "13.5", "13.6", "13.7",
        "14.0", "14.1", "14.2", "14.3", "14.4", "14.5", "14.6", "14.7", "14.8",
        "15.0", "15.1", "15.2", "15.3", "15.4", "15.5", "15.6", "15.7", "15.8",
        "16.0", "16.1", "16.2", "16.3", "16.4", "16.5", "16.6", "16.7",
        "17.0", "17.1", "17.2", "17.3", "17.4", "17.5", "17.6", "17.7",
        "18.0", "18.1", "18.2", "18.3", "18.4", "18.5", "18.6", "18.7",
        "26.0", "26.1", "26.2", "26.3", "26.4", "26.5"
    ]

    var randomizeModel = true
    var randomizeIOS = true
    var randomizeCarrier = false
    var randomizeRegion = false
    var randomizeLocaleAndTimeZone = true
    var modelMinimumIndex = 0
    var modelMaximumIndex = ProfileGenerationSettings.modelOptions.count - 1
    var iosMinimumIndex = 0
    var iosMaximumIndex = ProfileGenerationSettings.iosOptions.count - 1
    var catalogVersion: Int? = 2
    var enabledFields: Set<ProfileRandomField>? = ProfileRandomField.defaultEnabled

    mutating func migrateCatalogIfNeeded() {
        if enabledFields == nil {
            var migrated = ProfileRandomField.defaultEnabled
            if randomizeModel { migrated.insert(.deviceModel) } else { migrated.remove(.deviceModel) }
            if randomizeIOS { migrated.insert(.iosVersion) } else { migrated.remove(.iosVersion) }
            if randomizeCarrier { migrated.insert(.carrier) } else { migrated.remove(.carrier) }
            if randomizeRegion { migrated.insert(.location) } else { migrated.remove(.location) }
            enabledFields = migrated
        }
        guard catalogVersion != 2 else { return }
        let oldMinimumModel = Self.legacyModelOptions.indices.contains(modelMinimumIndex) ? Self.legacyModelOptions[modelMinimumIndex] : Self.legacyModelOptions.first!
        let oldMaximumModel = Self.legacyModelOptions.indices.contains(modelMaximumIndex) ? Self.legacyModelOptions[modelMaximumIndex] : Self.legacyModelOptions.last!
        let oldMinimumIOS = Self.legacyIOSOptions.indices.contains(iosMinimumIndex) ? Self.legacyIOSOptions[iosMinimumIndex] : Self.legacyIOSOptions.first!
        let oldMaximumIOS = Self.legacyIOSOptions.indices.contains(iosMaximumIndex) ? Self.legacyIOSOptions[iosMaximumIndex] : Self.legacyIOSOptions.last!
        modelMinimumIndex = Self.modelOptions.firstIndex(of: oldMinimumModel) ?? 0
        modelMaximumIndex = Self.modelOptions.firstIndex(of: oldMaximumModel) ?? Self.modelOptions.count - 1
        iosMinimumIndex = Self.iosOptions.firstIndex(of: oldMinimumIOS) ?? 0
        iosMaximumIndex = Self.iosOptions.firstIndex(of: oldMaximumIOS) ?? Self.iosOptions.count - 1
        catalogVersion = 2
        normalizeRanges()
    }

    mutating func normalizeRanges() {
        modelMinimumIndex = min(max(modelMinimumIndex, 0), Self.modelOptions.count - 1)
        modelMaximumIndex = min(max(modelMaximumIndex, modelMinimumIndex), Self.modelOptions.count - 1)
        iosMinimumIndex = min(max(iosMinimumIndex, 0), Self.iosOptions.count - 1)
        iosMaximumIndex = min(max(iosMaximumIndex, iosMinimumIndex), Self.iosOptions.count - 1)
    }

    mutating func setModelMinimum(_ value: Int) { modelMinimumIndex = value; modelMaximumIndex = max(modelMaximumIndex, value); normalizeRanges() }
    mutating func setModelMaximum(_ value: Int) { modelMaximumIndex = value; modelMinimumIndex = min(modelMinimumIndex, value); normalizeRanges() }
    mutating func setIOSMinimum(_ value: Int) { iosMinimumIndex = value; iosMaximumIndex = max(iosMaximumIndex, value); normalizeRanges() }
    mutating func setIOSMaximum(_ value: Int) { iosMaximumIndex = value; iosMinimumIndex = min(iosMinimumIndex, value); normalizeRanges() }

    var enabledFieldNames: [String] {
        ProfileRandomField.allCases.filter(isEnabled).map(\.title)
    }
    func isEnabled(_ field: ProfileRandomField) -> Bool { (enabledFields ?? ProfileRandomField.defaultEnabled).contains(field) }
    mutating func setEnabled(_ enabled: Bool, for field: ProfileRandomField) {
        var values = enabledFields ?? ProfileRandomField.defaultEnabled
        if enabled { values.insert(field) } else { values.remove(field) }
        enabledFields = values
        if field == .deviceModel { randomizeModel = enabled }
        if field == .iosVersion { randomizeIOS = enabled }
        if field == .carrier { randomizeCarrier = enabled }
        if field == .location { randomizeRegion = enabled }
        if [.locale, .preferredLanguages, .timeZone].contains(field) { randomizeLocaleAndTimeZone = enabled }
    }
    var modelRangeText: String { "\(Self.modelOptions[modelMinimumIndex]) → \(Self.modelOptions[modelMaximumIndex])" }
    var iosRangeText: String { "iOS \(Self.iosOptions[iosMinimumIndex]) → iOS \(Self.iosOptions[iosMaximumIndex])" }

    static func compatibility(for model: String) -> DeviceCompatibility {
        if ["iPhone 7", "iPhone 7 Plus"].contains(model) { return .init(minimumIOS: "10.0", maximumIOS: "15.8") }
        if ["iPhone 8", "iPhone 8 Plus", "iPhone X"].contains(model) { return .init(minimumIOS: "11.0", maximumIOS: "16.7") }
        if ["iPhone XS", "iPhone XS Max", "iPhone XR"].contains(model) { return .init(minimumIOS: "12.0", maximumIOS: "18.7") }
        if model.contains("iPhone 11") { return .init(minimumIOS: "13.0", maximumIOS: "26.5") }
        if model == "iPhone SE (2nd generation)" { return .init(minimumIOS: "13.4", maximumIOS: "26.5") }
        if model.contains("iPhone 12") { return .init(minimumIOS: "14.1", maximumIOS: "26.5") }
        if model.contains("iPhone 13") { return .init(minimumIOS: "15.0", maximumIOS: "26.5") }
        if model == "iPhone SE (3rd generation)" { return .init(minimumIOS: "15.4", maximumIOS: "26.5") }
        if model.contains("iPhone 14") { return .init(minimumIOS: "16.0", maximumIOS: "26.5") }
        if model.contains("iPhone 15") { return .init(minimumIOS: "17.0", maximumIOS: "26.5") }
        if model.contains("iPhone 16") { return .init(minimumIOS: "18.0", maximumIOS: "26.5") }
        return .init(minimumIOS: "26.0", maximumIOS: "26.5")
    }

    static func compatibleIOSOptions(for model: String) -> [String] {
        let bounds = compatibility(for: model)
        guard let minimum = iosOptions.firstIndex(of: bounds.minimumIOS), let maximum = iosOptions.firstIndex(of: bounds.maximumIOS) else { return [] }
        return Array(iosOptions[minimum...maximum])
    }
}

