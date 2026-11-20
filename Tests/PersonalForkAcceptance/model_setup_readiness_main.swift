import Foundation

/// Probe only a unique synthetic domain; never use the application's defaults.
@main
struct ModelSetupReadinessProbe {
    static func main() throws {
        guard CommandLine.arguments.count == 5 else { exit(64) }
        let suite = CommandLine.arguments[1]
        let key = CommandLine.arguments[2]
        let operation = CommandLine.arguments[3]
        let model = CommandLine.arguments[4]
        let prefix = "com.robeyvoice.acceptance.model-setup."
        guard suite.hasPrefix(prefix),
              UUID(uuidString: String(suite.dropFirst(prefix.count))) != nil,
              let defaults = UserDefaults(suiteName: suite) else { exit(64) }

        var result: [String: Any] = [:]
        var status: Int32 = 0
        switch operation {
        case "cleanup":
            defaults.removePersistentDomain(forName: suite)
        case "seed":
            defaults.set("keep this synthetic value", forKey: "unrelated.string")
            defaults.set(true, forKey: "unrelated.bool")
            defaults.set(["first", "second"], forKey: "unrelated.array")
        case "unrelated":
            result = [
                "string": defaults.object(forKey: "unrelated.string") ?? NSNull(),
                "bool": defaults.object(forKey: "unrelated.bool") ?? NSNull(),
                "array": defaults.object(forKey: "unrelated.array") ?? NSNull(),
            ]
        default:
            let store = ModelSetupReadinessStore(defaults: defaults, key: key)
            switch operation {
            case "status":
                result["requiresRetry"] = store.requiresRetry(for: model)
            case "begin":
                store.beginSetup(for: model)
            case "begin-and-interrupt":
                store.beginSetup(for: model)
                // Deliberately stop setup without a completion call; a later process retries.
                status = 75
                result["interrupted"] = true
            case "complete":
                store.completeSetup(for: model)
            default:
                exit(64)
            }
        }
        guard defaults.synchronize() else {
            FileHandle.standardError.write(Data("Synthetic defaults synchronization failed\n".utf8))
            exit(74)
        }
        let data = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
        exit(status)
    }
}
