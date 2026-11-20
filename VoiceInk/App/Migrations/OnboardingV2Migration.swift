import Foundation

enum OnboardingV2Migration {
    static let completedKey = OnboardingSettings.completedV2Key

    static func prepareIfNeeded(defaults: UserDefaults = .standard) {
        // The fork starts in its own defaults domain. Never erase saved or explicitly
        // imported modes and shortcuts while preparing or resuming onboarding.
        defaults.set(true, forKey: OnboardingSettings.preparedV2Key)
    }
}
