import Foundation

struct ProfileGenerationSettings: Codable, Equatable {
    static let modelOptions = [
        "iPhone XS", "iPhone XS Max", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max",
        "iPhone 12", "iPhone 12 Pro", "iPhone 12 Pro Max", "iPhone 13", "iPhone 13 Pro",
        "iPhone 13 Pro Max", "iPhone 14", "iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone 15",
        "iPhone 15 Pro", "iPhone 15 Pro Max", "iPhone 16", "iPhone 16 Pro", "iPhone 16 Pro Max"
    ]
    static let iosOptions = ["16.0", "16.1", "16.2", "16.3", "16.4", "16.5", "16.6", "17.0", "17.1", "17.2", "17.3", "17.4", "17.5", "17.6", "18.0", "18.1"]

    var randomizeModel = true
    var randomizeIOS = true
    var randomizeCarrier = false
    var randomizeRegion = false
    var randomizeLocaleAndTimeZone = true
    var modelMinimumIndex = 0
    var modelMaximumIndex = ProfileGenerationSettings.modelOptions.count - 1
    var iosMinimumIndex = 0
    var iosMaximumIndex = ProfileGenerationSettings.iosOptions.count - 1

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
        [(randomizeModel, "Model iPhone"), (randomizeIOS, "Phiên bản iOS"), (randomizeCarrier, "Nhà mạng"), (randomizeRegion, "Vùng"), (randomizeLocaleAndTimeZone, "Ngôn ngữ & múi giờ")]
            .compactMap { $0.0 ? $0.1 : nil }
    }
    var modelRangeText: String { "\(Self.modelOptions[modelMinimumIndex]) → \(Self.modelOptions[modelMaximumIndex])" }
    var iosRangeText: String { "iOS \(Self.iosOptions[iosMinimumIndex]) → iOS \(Self.iosOptions[iosMaximumIndex])" }
}

