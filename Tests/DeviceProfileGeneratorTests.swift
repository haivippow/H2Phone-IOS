import Foundation

@main
enum DeviceProfileGeneratorTests {
    static func main() throws {
        let firmware = DeviceFirmware(version: "15.8", build: "19H370", darwin: "21.6.0")
        let catalog = DeviceCatalogDocument(schemaVersion: 1, source: "fixture", devices: [
            DeviceCatalogEntry(identifier: "iPhone9,1", name: "iPhone 7", boards: ["D10AP"], models: ["A1660"], released: "2016-09-16", firmwares: [firmware]),
            DeviceCatalogEntry(identifier: "iPhone15,3", name: "iPhone 14 Pro Max", boards: ["D74AP"], models: ["A2894"], released: "2022-09-16", firmwares: [DeviceFirmware(version: "16.0", build: "20A362", darwin: "22.0.0")])
        ])
        var settings = ProfileGenerationSettings()
        settings.modelMinimumIndex = ProfileGenerationSettings.modelOptions.firstIndex(of: "iPhone 7")!
        settings.modelMaximumIndex = ProfileGenerationSettings.modelOptions.firstIndex(of: "iPhone 14 Pro Max")!
        settings.iosMinimumIndex = ProfileGenerationSettings.iosOptions.firstIndex(of: "15.8")!
        settings.iosMaximumIndex = ProfileGenerationSettings.iosOptions.firstIndex(of: "15.8")!

        let generated = try DeviceProfileGenerator(catalog: catalog).generate(settings: settings, randomIndex: { _ in 0 })
        precondition(generated.productType == "iPhone9,1")
        precondition(generated.board == "D10AP")
        precondition(generated.iosVersion == "15.8" && generated.build == "19H370" && generated.darwin == "21.6.0")
        precondition(generated.memoryBytes == 2 * 1_073_741_824)
        precondition(generated.diskTotalBytes == 32 * 1_073_741_824)
        precondition(generated.propertyList["model"] as? String == "iPhone9,1")

        settings.iosMinimumIndex = ProfileGenerationSettings.iosOptions.firstIndex(of: "18.0")!
        settings.iosMaximumIndex = settings.iosMinimumIndex
        do {
            _ = try DeviceProfileGenerator(catalog: catalog).generate(settings: settings, randomIndex: { _ in 0 })
            fatalError("Expected noCompatibleProfile")
        } catch DeviceProfileGeneratorError.noCompatibleProfile {
            // Expected: no config should be produced for an impossible range.
        }

        print("Device profile generator tests passed: 7 assertions.")
    }
}
