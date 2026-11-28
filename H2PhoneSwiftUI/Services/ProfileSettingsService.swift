import Foundation

protocol ProfileSettingsService {
    func load() -> ProfileGenerationSettings
    func save(_ settings: ProfileGenerationSettings)
}

struct UserDefaultsProfileSettingsService: ProfileSettingsService {
    private let defaults: UserDefaults
    private let key = "com.h2phone.profile-generation-settings"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load() -> ProfileGenerationSettings {
        guard let data = defaults.data(forKey: key),
              var settings = try? JSONDecoder().decode(ProfileGenerationSettings.self, from: data) else {
            return ProfileGenerationSettings()
        }
        settings.migrateCatalogIfNeeded()
        settings.normalizeRanges()
        return settings
    }

    func save(_ settings: ProfileGenerationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}

