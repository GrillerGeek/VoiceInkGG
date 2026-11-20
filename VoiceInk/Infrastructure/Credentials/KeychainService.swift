import Foundation
import Security
import os

/// Stores fork credentials in an isolated, non-syncing macOS login Keychain namespace.
final class KeychainService {
    static let shared = KeychainService()

    enum ReadResult<Value> {
        case value(Value)
        case notFound
        case unavailable(OSStatus)
    }

    private let logger = Logger(subsystem: AppIdentity.logSubsystem, category: "KeychainService")
    private let service = AppIdentity.keychainServiceName

    private init() {}

    // MARK: - Public API

    /// Saves a string value to Keychain.
    @discardableResult
    func save(
        _ value: String,
        forKey key: String
    ) -> Bool {
        guard let data = value.data(using: .utf8) else {
            logger.error("Failed to convert value to data for key: \(key, privacy: .public)")
            return false
        }
        return save(data: data, forKey: key)
    }

    /// Saves data to Keychain.
    @discardableResult
    func save(
        data: Data,
        forKey key: String
    ) -> Bool {
        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            logger.info("Successfully updated keychain item for key: \(key, privacy: .public)")
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            logger.error(
                "Failed to update keychain item for key: \(key, privacy: .public), status: \(updateStatus, privacy: .public)"
            )
            return false
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

        if addStatus == errSecSuccess {
            logger.info("Successfully saved keychain item for key: \(key, privacy: .public)")
            return true
        }

        if addStatus == errSecDuplicateItem {
            let retryStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if retryStatus == errSecSuccess {
                logger.info("Successfully updated concurrently created keychain item for key: \(key, privacy: .public)")
                return true
            }

            logger.error(
                "Failed to update concurrently created keychain item for key: \(key, privacy: .public), status: \(retryStatus, privacy: .public)"
            )
            return false
        }

        logger.error(
            "Failed to save keychain item for key: \(key, privacy: .public), status: \(addStatus, privacy: .public)"
        )
        return false
    }

    /// Retrieves a string value from Keychain.
    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Retrieves a string while distinguishing missing data from unavailable storage.
    func readString(forKey key: String) -> ReadResult<String> {
        switch readData(forKey: key) {
        case .value(let data):
            guard let value = String(data: data, encoding: .utf8) else {
                logger.error("Failed to decode keychain string for key: \(key, privacy: .public)")
                return .unavailable(errSecDecode)
            }
            return .value(value)
        case .notFound:
            return .notFound
        case .unavailable(let status):
            return .unavailable(status)
        }
    }

    /// Retrieves data from Keychain.
    func getData(forKey key: String) -> Data? {
        guard case .value(let data) = readData(forKey: key) else {
            return nil
        }
        return data
    }

    /// Retrieves data while preserving the Security framework status.
    func readData(forKey key: String) -> ReadResult<Data> {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            guard let data = result as? Data else {
                logger.error("Keychain returned invalid data for key: \(key, privacy: .public)")
                return .unavailable(errSecDecode)
            }
            return .value(data)
        }

        if status == errSecItemNotFound {
            return .notFound
        }

        logger.error(
            "Failed to retrieve keychain item for key: \(key, privacy: .public), status: \(status, privacy: .public)"
        )
        return .unavailable(status)
    }

    /// Deletes an item from Keychain.
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            if status == errSecSuccess {
                logger.info("Successfully deleted keychain item for key: \(key, privacy: .public)")
            }
            return true
        } else {
            logger.error(
                "Failed to delete keychain item for key: \(key, privacy: .public), status: \(status, privacy: .public)"
            )
            return false
        }
    }

    /// Checks if a key exists in Keychain. Returns nil when the Keychain can't answer
    /// (for example while it's locked), so callers can tell that apart from a missing key.
    func exists(forKey key: String) -> Bool? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanFalse

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            logger.error(
                "Failed to check keychain item for key: \(key, privacy: .public), status: \(status, privacy: .public)"
            )
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Creates a base Keychain query.
    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        // Login Keychain items are device-local and never synchronized or shared
        // with the upstream application, regardless of signing configuration.
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse
        return query
    }
}
