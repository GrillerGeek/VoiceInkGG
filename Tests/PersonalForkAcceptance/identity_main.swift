import Foundation

let snapshot: [String: String] = [
    "displayName": AppIdentity.displayName,
    "productionBundleIdentifier": AppIdentity.productionBundleIdentifier,
    "developmentBundleIdentifier": AppIdentity.developmentBundleIdentifier,
    "bundleIdentifier": AppIdentity.bundleIdentifier,
    "applicationSupportDirectoryName": AppIdentity.applicationSupportDirectoryName,
    "keychainServiceName": AppIdentity.keychainServiceName,
    "logSubsystem": AppIdentity.logSubsystem,
    "refineXPCServiceName": AppIdentity.refineXPCServiceName
]
let data = try JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys])
print(String(decoding: data, as: UTF8.self))
