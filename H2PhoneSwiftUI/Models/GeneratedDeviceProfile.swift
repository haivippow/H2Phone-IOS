import Foundation

struct GeneratedDeviceProfile: Equatable {
    let marketingName: String
    let productType: String
    let board: String
    let modelNumber: String
    let iosVersion: String
    let build: String
    let darwin: String
    let memoryBytes: UInt64
    let coreCount: Int
    let diskTotalBytes: UInt64
    let diskFreeBytes: UInt64
    let screenWidth: Int
    let screenHeight: Int
    let nativeWidth: Int
    let nativeHeight: Int
    let screenScale: Int
    let uuid: String
    let idfa: String
    let imei: String
    let imei2: String
    let batteryLevel: Double
    let uptime: Double

    var propertyList: [String: Any] {
        [
            "name": marketingName,
            "model": productType,
            "board": board,
            "modelNumber": modelNumber,
            "ios": iosVersion,
            "build": build,
            "darwin": darwin,
            "uuid": uuid,
            "idfa": idfa,
            "imei": imei,
            "imei2": imei2,
            "memory": NSNumber(value: memoryBytes),
            "cores": coreCount,
            "diskTotal": NSNumber(value: diskTotalBytes),
            "diskFree": NSNumber(value: diskFreeBytes),
            "uptime": uptime,
            "ssid": "H2-WiFi",
            "bssid": Self.bssid(from: uuid),
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "nativeWidth": nativeWidth,
            "nativeHeight": nativeHeight,
            "screenScale": screenScale,
            "maxTouchPoints": 5,
            "carrier": "Viettel",
            "mcc": "452",
            "mnc": "04",
            "country": "vn",
            "latitude": 21.0285,
            "longitude": 105.8542,
            "battery": batteryLevel,
            "webglVendor": "Apple Inc.",
            "webglRenderer": "Apple GPU"
        ]
    }

    private static func bssid(from uuid: String) -> String {
        let hex = uuid.replacingOccurrences(of: "-", with: "")
        let pairs = stride(from: 0, to: min(hex.count, 10), by: 2).map { offset -> String in
            let start = hex.index(hex.startIndex, offsetBy: offset)
            let end = hex.index(start, offsetBy: 2)
            return String(hex[start..<end])
        }
        return (["02"] + pairs).joined(separator: ":")
    }
}
