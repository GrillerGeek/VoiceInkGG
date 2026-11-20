import Foundation

/// Stable fork identity. Debug installations have independent data and credentials.
enum AppIdentity {
    static let displayName = "Robey Voice"
    static let productionBundleIdentifier = "com.jasonrobey.RobeyVoice"
    static let developmentBundleIdentifier = "com.jasonrobey.RobeyVoice.dev"
    #if DEBUG
    static let bundleIdentifier = developmentBundleIdentifier
    #else
    static let bundleIdentifier = productionBundleIdentifier
    #endif
    static let applicationSupportDirectoryName = bundleIdentifier
    static let keychainServiceName = bundleIdentifier
    static let logSubsystem = bundleIdentifier.lowercased()
    static let refineXPCServiceName = "com.jasonrobey.RobeyVoice.RefineXPC"
}
