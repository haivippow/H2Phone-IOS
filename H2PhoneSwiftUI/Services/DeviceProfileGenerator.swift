import Foundation

enum DeviceProfileGeneratorError: LocalizedError {
    case catalogUnavailable
    case noCompatibleProfile

    var errorDescription: String? {
        switch self {
        case .catalogUnavailable: return "Catalog thiết bị không khả dụng."
        case .noCompatibleProfile: return "Không có tổ hợp thiết bị và iOS tương thích trong khoảng đã chọn."
        }
    }
}

private struct DeviceHardwareSpec {
    let memoryGB: UInt64
    let cores: Int
    let storageGB: UInt64
    let width: Int
    let height: Int
    let nativeWidth: Int
    let nativeHeight: Int
    let scale: Int

    static func forMarketingName(_ name: String) -> DeviceHardwareSpec? {
        let memory: UInt64
        switch name {
        case "iPhone 7", "iPhone 8": memory = 2
        case "iPhone 7 Plus", "iPhone 8 Plus", "iPhone X", "iPhone XS", "iPhone XS Max", "iPhone XR", "iPhone SE (2nd generation)": memory = 3
        case "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone 12 mini", "iPhone 12", "iPhone 13 mini", "iPhone 13", "iPhone SE (3rd generation)": memory = 4
        case "iPhone 12 Pro", "iPhone 12 Pro Max", "iPhone 13 Pro", "iPhone 13 Pro Max", "iPhone 14", "iPhone 14 Plus", "iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone 15", "iPhone 15 Plus": memory = 6
        case "iPhone 15 Pro", "iPhone 15 Pro Max", "iPhone 16e", "iPhone 16", "iPhone 16 Plus", "iPhone 16 Pro", "iPhone 16 Pro Max": memory = 8
        default: return nil
        }

        let screen: (Int, Int, Int, Int, Int)
        switch name {
        case "iPhone 7", "iPhone 8", "iPhone SE (2nd generation)", "iPhone SE (3rd generation)": screen = (375, 667, 750, 1334, 2)
        case "iPhone 7 Plus", "iPhone 8 Plus": screen = (414, 736, 1242, 2208, 3)
        case "iPhone X", "iPhone XS", "iPhone 11 Pro": screen = (375, 812, 1125, 2436, 3)
        case "iPhone XS Max", "iPhone 11 Pro Max": screen = (414, 896, 1242, 2688, 3)
        case "iPhone XR", "iPhone 11": screen = (414, 896, 828, 1792, 2)
        case "iPhone 12 mini", "iPhone 13 mini": screen = (375, 812, 1080, 2340, 3)
        case "iPhone 12", "iPhone 12 Pro", "iPhone 13", "iPhone 13 Pro", "iPhone 14", "iPhone 16e": screen = (390, 844, 1170, 2532, 3)
        case "iPhone 12 Pro Max", "iPhone 13 Pro Max", "iPhone 14 Plus": screen = (428, 926, 1284, 2778, 3)
        case "iPhone 14 Pro", "iPhone 15", "iPhone 15 Pro", "iPhone 16": screen = (393, 852, 1179, 2556, 3)
        case "iPhone 14 Pro Max", "iPhone 15 Plus", "iPhone 15 Pro Max", "iPhone 16 Plus": screen = (430, 932, 1290, 2796, 3)
        case "iPhone 16 Pro": screen = (402, 874, 1206, 2622, 3)
        case "iPhone 16 Pro Max": screen = (440, 956, 1320, 2868, 3)
        default: return nil
        }

        let cores = ["iPhone 7", "iPhone 7 Plus"].contains(name) ? 4 : 6
        let storageGB: UInt64
        if name.contains("iPhone 7") {
            storageGB = 32
        } else if name.hasPrefix("iPhone 12 Pro") || name.hasPrefix("iPhone 13") || name.hasPrefix("iPhone 14") || name.hasPrefix("iPhone 15") || name.hasPrefix("iPhone 16") {
            storageGB = 128
        } else {
            storageGB = 64
        }
        return .init(memoryGB: memory, cores: cores, storageGB: storageGB, width: screen.0, height: screen.1, nativeWidth: screen.2, nativeHeight: screen.3, scale: screen.4)
    }
}

struct DeviceProfileGenerator {
    private let catalog: DeviceCatalogDocument

    init(catalog: DeviceCatalogDocument = DeviceCatalog.bundled) {
        self.catalog = catalog
    }

    func generate(
        settings input: ProfileGenerationSettings,
        randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) throws -> GeneratedDeviceProfile {
        guard !catalog.devices.isEmpty else { throw DeviceProfileGeneratorError.catalogUnavailable }
        var settings = input
        settings.normalizeRanges()
        let allowedNames = Set(ProfileGenerationSettings.modelOptions[settings.modelMinimumIndex...settings.modelMaximumIndex])
        let minimumIOS = versionPair(ProfileGenerationSettings.iosOptions[settings.iosMinimumIndex])
        let maximumIOS = versionPair(ProfileGenerationSettings.iosOptions[settings.iosMaximumIndex])

        let candidates = catalog.devices.compactMap { device -> (DeviceCatalogEntry, DeviceHardwareSpec, [DeviceFirmware])? in
            guard allowedNames.contains(device.name),
                  let spec = DeviceHardwareSpec.forMarketingName(device.name),
                  !device.boards.isEmpty else { return nil }
            let firmwares = device.firmwares.filter {
                let pair = versionPair($0.version)
                return compare(pair, minimumIOS) >= 0 && compare(pair, maximumIOS) <= 0
            }
            return firmwares.isEmpty ? nil : (device, spec, firmwares)
        }
        guard !candidates.isEmpty else { throw DeviceProfileGeneratorError.noCompatibleProfile }

        let selected = candidates[safeIndex(randomIndex(candidates.count), upperBound: candidates.count)]
        let device = selected.0
        let spec = selected.1
        let firmware = selected.2[safeIndex(randomIndex(selected.2.count), upperBound: selected.2.count)]
        let board = device.boards[safeIndex(randomIndex(device.boards.count), upperBound: device.boards.count)]
        let modelNumber = device.models.isEmpty ? "" : device.models[safeIndex(randomIndex(device.models.count), upperBound: device.models.count)]
        let total = spec.storageGB * 1_073_741_824
        let freePercent = UInt64(45 + safeIndex(randomIndex(41), upperBound: 41))

        return GeneratedDeviceProfile(
            marketingName: device.name,
            productType: device.identifier,
            board: board,
            modelNumber: modelNumber,
            iosVersion: firmware.version,
            build: firmware.build,
            darwin: firmware.darwin,
            memoryBytes: spec.memoryGB * 1_073_741_824,
            coreCount: spec.cores,
            diskTotalBytes: total,
            diskFreeBytes: total * freePercent / 100,
            screenWidth: spec.width,
            screenHeight: spec.height,
            nativeWidth: spec.nativeWidth,
            nativeHeight: spec.nativeHeight,
            screenScale: spec.scale,
            uuid: UUID().uuidString,
            idfa: UUID().uuidString,
            imei: makeIMEI(randomIndex: randomIndex),
            imei2: makeIMEI(randomIndex: randomIndex),
            batteryLevel: Double(20 + safeIndex(randomIndex(80), upperBound: 80)) / 100,
            uptime: Double(3_600 + safeIndex(randomIndex(601_200), upperBound: 601_200))
        )
    }

    private func safeIndex(_ value: Int, upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return ((value % upperBound) + upperBound) % upperBound
    }

    private func versionPair(_ value: String) -> (Int, Int) {
        let parts = value.split(separator: ".").compactMap { Int($0) }
        return (parts.first ?? 0, parts.count > 1 ? parts[1] : 0)
    }

    private func compare(_ left: (Int, Int), _ right: (Int, Int)) -> Int {
        if left.0 != right.0 { return left.0 < right.0 ? -1 : 1 }
        if left.1 != right.1 { return left.1 < right.1 ? -1 : 1 }
        return 0
    }

    private func makeIMEI(randomIndex: (Int) -> Int) -> String {
        var digits = [3, 5]
        while digits.count < 14 { digits.append(safeIndex(randomIndex(10), upperBound: 10)) }
        let sum = digits.enumerated().reduce(0) { result, item in
            let doubled = item.offset.isMultiple(of: 2) ? item.element : item.element * 2
            return result + (doubled > 9 ? doubled - 9 : doubled)
        }
        digits.append((10 - sum % 10) % 10)
        return digits.map(String.init).joined()
    }
}
