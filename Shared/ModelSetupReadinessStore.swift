import Foundation

/// Remembers setup attempts that have not yet passed every native readiness check.
/// Callers must only complete an attempt after all required setup has succeeded.
final class ModelSetupReadinessStore {
    private static let lock = NSLock()
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
    }

    func requiresRetry(for modelName: String) -> Bool {
        Self.lock.withLock { pendingModels().contains(modelName) }
    }

    func beginSetup(for modelName: String) {
        Self.lock.withLock {
            var models = pendingModels()
            models.insert(modelName)
            defaults.set(models.sorted(), forKey: key)
            // Persist the latch before the caller starts network/native work rather
            // than depending on the app reaching a normal termination afterward.
            _ = defaults.synchronize()
        }
    }

    func completeSetup(for modelName: String) {
        Self.lock.withLock {
            var models = pendingModels()
            guard models.remove(modelName) != nil else { return }
            if models.isEmpty {
                defaults.removeObject(forKey: key)
            } else {
                defaults.set(models.sorted(), forKey: key)
            }
            _ = defaults.synchronize()
        }
    }

    private func pendingModels() -> Set<String> {
        Set((defaults.array(forKey: key) ?? []).compactMap { $0 as? String })
    }
}
