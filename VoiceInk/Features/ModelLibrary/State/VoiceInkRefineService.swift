import Combine
import Foundation

enum VoiceInkRefineAvailability: Equatable {
    case restrictedModelLicense
}

enum VoiceInkRefineError: LocalizedError {
    case unavailable
    case modelNotDownloaded

    var errorDescription: String? { VoiceInkRefineService.unavailableReason }
}

/// Preserves serialized provider compatibility without downloading or running weights
/// whose pinned license does not permit use in this fork. See bundled model notices.
final class VoiceInkRefineService: ObservableObject {
    static let shared = VoiceInkRefineService()
    static let providerName = "VoiceInk Refine"
    static let modelName = "VoiceInk Refine V1"
    static let repositoryID = "beingpax/VoiceInk-Refine-V1"
    static let pinnedRevision = "ad665418d3850e379e29236e66be3ddc0ac0bf04"
    static let unavailableReason = "VoiceInk Refine is unavailable in Robey Voice: its pinned model license permits use with VoiceInk only. Keep AI enhancement off for plain local dictation, or configure Ollama or another permitted provider in AI Models."
    static let downloadSizeDescription = "Not offered in this fork"

    let availability: VoiceInkRefineAvailability = .restrictedModelLicense
    @Published private(set) var isDownloaded = false
    @Published private(set) var isDownloading = false
    @Published private(set) var downloadProgress = 0.0
    @Published private(set) var downloadError: String?
    let downloadedBytes: Int64 = 0
    let totalDownloadBytes: Int64 = 0
    let isFinalizingDownload = false
    var isAvailableInModes: Bool { false }
    var downloadedModelURL: URL? { nil }
    var unavailableDescription: String? { Self.unavailableReason }

    private init() {}

    @MainActor
    func startDownload() { downloadError = Self.unavailableReason }
    @MainActor
    func cancelDownload() {}
    @MainActor
    func deleteModel() async {}
    func enhance(transcript: String, vocabulary: RecordingVocabulary) async throws -> String {
        throw VoiceInkRefineError.unavailable
    }
    func unloadPreparedModelIfNeeded() async {}
    func keepPreparedModelWarmForRecording() async {}
    func prepareForRecording() async {}
}
