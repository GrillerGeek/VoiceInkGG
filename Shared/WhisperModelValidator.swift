import Foundation
import whisper

/// Checks the complete GGML Whisper container before a file is advertised as usable.
/// This follows the pinned whisper.cpp loader's metadata and tensor layout, but never
/// allocates model weights or initializes a backend. Tensor payloads are skipped.
enum WhisperModelValidator {
    struct InvalidModel: LocalizedError {
        let reason: String

        var errorDescription: String? {
            String(localized: "Invalid or incomplete Whisper model. Download it again or import a complete compatible .bin file.")
        }
    }

    static func validate(at url: URL) throws {
        let reader = try Reader(url: url)
        guard reader.size > 48, reader.size <= 32 * 1_024 * 1_024 * 1_024 else {
            throw InvalidModel(reason: "Invalid file length")
        }
        guard try reader.uint32() == 0x67676d6c else {
            throw InvalidModel(reason: "Unsupported container")
        }

        let header = try Header(reader: reader)
        let expected = header.tensors()

        let melCount = try reader.uint32()
        let fftCount = try reader.uint32()
        guard melCount == header.mels, fftCount == 201 else {
            throw InvalidModel(reason: "Invalid mel filter dimensions")
        }
        try reader.skip(UInt64(melCount) * UInt64(fftCount) * 4)

        let vocabularyCount = try reader.uint32()
        guard vocabularyCount > 0, vocabularyCount <= header.vocabulary else {
            throw InvalidModel(reason: "Invalid vocabulary count")
        }
        let vocabularyByteLimit: UInt64 = 8 * 1_024 * 1_024
        var vocabularyBytes: UInt64 = 0
        for _ in 0..<vocabularyCount {
            try Task<Never, Never>.checkCancellation()
            let length = try reader.uint32()
            let entryBytes = UInt64(length) + 4
            guard length <= 65_536, entryBytes <= vocabularyByteLimit - vocabularyBytes else {
                throw InvalidModel(reason: "Invalid or excessive vocabulary metadata")
            }
            vocabularyBytes += entryBytes
            try reader.skip(UInt64(length))
        }
        reader.stopReadAhead()

        var seen = Set<String>()
        while reader.remaining > 0 {
            try Task<Never, Never>.checkCancellation()
            let dimensionCount = try reader.uint32()
            let nameLength = try reader.uint32()
            let rawType = try reader.uint32()
            guard (1...3).contains(dimensionCount), (1...256).contains(nameLength),
                  rawType < GGML_TYPE_COUNT.rawValue else {
                throw InvalidModel(reason: "Invalid tensor metadata")
            }
            var dimensions = [UInt64](repeating: 1, count: 3)
            for index in 0..<Int(dimensionCount) {
                dimensions[index] = UInt64(try reader.uint32())
            }
            guard let name = String(data: try reader.bytes(Int(nameLength)), encoding: .utf8),
                  let tensor = expected[name], seen.insert(name).inserted,
                  dimensions == tensor.dimensions, rawType == tensor.type.rawValue else {
                throw InvalidModel(reason: "Unexpected, duplicate or incompatible tensor")
            }

            // The native functions assert on out-of-range types. Only the validated,
            // expected type reaches them; removed GGML types are never constructed.
            let block = ggml_blck_size(tensor.type)
            let typeSize = ggml_type_size(tensor.type)
            guard block > 0, typeSize > 0, dimensions[0] % UInt64(block) == 0 else {
                throw InvalidModel(reason: "Invalid tensor block size")
            }
            var elements: UInt64 = 1
            for dimension in dimensions {
                let product = elements.multipliedReportingOverflow(by: dimension)
                guard !product.overflow, dimension > 0 else {
                    throw InvalidModel(reason: "Invalid tensor dimensions")
                }
                elements = product.partialValue
            }
            let payload = (elements / UInt64(block)).multipliedReportingOverflow(by: UInt64(typeSize))
            guard !payload.overflow else { throw InvalidModel(reason: "Invalid tensor length") }
            try reader.skip(payload.partialValue)
        }
        guard seen.count == expected.count else {
            // whisper.cpp deliberately accepts zero tensors for its own test models;
            // a user-installed transcription model must contain every weight tensor.
            throw InvalidModel(reason: "Missing model tensors")
        }
    }

    private struct Tensor {
        let dimensions: [UInt64]
        let type: ggml_type

        init(_ dimensions: [UInt64], _ type: ggml_type) {
            self.dimensions = dimensions + Array(repeating: 1, count: 3 - dimensions.count)
            self.type = type
        }
    }

    private struct Header {
        let vocabulary: UInt32
        let audioContext: UInt32
        let audioState: UInt32
        let audioLayers: UInt32
        let textContext: UInt32
        let textState: UInt32
        let textLayers: UInt32
        let mels: UInt32
        let weightType: ggml_type

        init(reader: Reader) throws {
            vocabulary = try reader.uint32()
            audioContext = try reader.uint32()
            audioState = try reader.uint32()
            let audioHeads = try reader.uint32()
            audioLayers = try reader.uint32()
            textContext = try reader.uint32()
            textState = try reader.uint32()
            let textHeads = try reader.uint32()
            textLayers = try reader.uint32()
            mels = try reader.uint32()
            let encodedType = try reader.uint32()

            // The pinned runtime derives language IDs from this count. Other
            // counts can reach an absent language and abort during native loading.
            guard [51_864, 51_865, 51_866].contains(vocabulary),
                  (1...16_384).contains(audioContext), (1...16_384).contains(textContext),
                  (1...8_192).contains(audioState), textState == audioState,
                  (1...128).contains(audioHeads), (1...128).contains(textHeads),
                  audioState % audioHeads == 0, textState % textHeads == 0,
                  [4, 6, 12, 24, 32].contains(audioLayers), (1...64).contains(textLayers),
                  (1...1_024).contains(mels), encodedType < 10_000 else {
                throw InvalidModel(reason: "Invalid Whisper dimensions")
            }
            let format = encodedType % 1_000
            // Matches ggml_ftype_to_ggml_type in the pinned native dependency. Its
            // unsupported values assert, so reject them before calling into C.
            guard [0, 1, 2, 3, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
                   19, 20, 21, 22, 23, 24, 25].contains(format) else {
                throw InvalidModel(reason: "Unsupported weight format")
            }
            weightType = ggml_ftype_to_ggml_type(ggml_ftype(rawValue: Int32(format)))
        }

        func tensors() -> [String: Tensor] {
            let a = UInt64(audioState)
            let t = UInt64(textState)
            let convolutionType = weightType == GGML_TYPE_F32 ? GGML_TYPE_F32 : GGML_TYPE_F16
            var result: [String: Tensor] = [
                "encoder.positional_embedding": Tensor([a, UInt64(audioContext)], GGML_TYPE_F32),
                "encoder.conv1.weight": Tensor([3, UInt64(mels), a], convolutionType),
                "encoder.conv1.bias": Tensor([1, a], GGML_TYPE_F32),
                "encoder.conv2.weight": Tensor([3, a, a], convolutionType),
                "encoder.conv2.bias": Tensor([1, a], GGML_TYPE_F32),
                "encoder.ln_post.weight": Tensor([a], GGML_TYPE_F32),
                "encoder.ln_post.bias": Tensor([a], GGML_TYPE_F32),
                "decoder.positional_embedding": Tensor([t, UInt64(textContext)], GGML_TYPE_F32),
                "decoder.token_embedding.weight": Tensor([t, UInt64(vocabulary)], weightType),
                "decoder.ln.weight": Tensor([t], GGML_TYPE_F32),
                "decoder.ln.bias": Tensor([t], GGML_TYPE_F32),
            ]

            func attention(_ prefix: String, state: UInt64) {
                for suffix in ["query.weight", "key.weight", "value.weight", "out.weight"] {
                    result[prefix + suffix] = Tensor([state, state], weightType)
                }
                for suffix in ["query.bias", "value.bias", "out.bias"] {
                    result[prefix + suffix] = Tensor([state], GGML_TYPE_F32)
                }
            }

            for (system, layers, state) in [("encoder", audioLayers, a), ("decoder", textLayers, t)] {
                for index in 0..<layers {
                    let prefix = "\(system).blocks.\(index)."
                    for norm in ["mlp_ln", "attn_ln"] {
                        result[prefix + norm + ".weight"] = Tensor([state], GGML_TYPE_F32)
                        result[prefix + norm + ".bias"] = Tensor([state], GGML_TYPE_F32)
                    }
                    result[prefix + "mlp.0.weight"] = Tensor([state, 4 * state], weightType)
                    result[prefix + "mlp.0.bias"] = Tensor([4 * state], GGML_TYPE_F32)
                    result[prefix + "mlp.2.weight"] = Tensor([4 * state, state], weightType)
                    result[prefix + "mlp.2.bias"] = Tensor([state], GGML_TYPE_F32)
                    attention(prefix + "attn.", state: state)
                    if system == "decoder" {
                        result[prefix + "cross_attn_ln.weight"] = Tensor([state], GGML_TYPE_F32)
                        result[prefix + "cross_attn_ln.bias"] = Tensor([state], GGML_TYPE_F32)
                        attention(prefix + "cross_attn.", state: state)
                    }
                }
            }
            return result
        }
    }

    /// A bounded metadata buffer; skips use file offsets rather than allocating payloads.
    private final class Reader {
        let size: UInt64
        private let handle: FileHandle
        private var position: UInt64 = 0
        private var bufferStart: UInt64 = 0
        private var buffer = Data()
        private var readsAhead = true

        var remaining: UInt64 { size - position }

        init(url: URL) throws {
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
                throw InvalidModel(reason: "Not a regular model file")
            }
            handle = try FileHandle(forReadingFrom: url)
            size = try handle.seekToEnd()
        }

        deinit { try? handle.close() }

        func stopReadAhead() {
            // Dense token metadata benefits from buffering. Once weight records
            // begin, read only requested header bytes instead of each weight prefix.
            buffer = Data()
            readsAhead = false
        }

        func uint32() throws -> UInt32 {
            let bytes = try self.bytes(4)
            return UInt32(bytes[0]) | UInt32(bytes[1]) << 8
                | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
        }

        func bytes(_ count: Int) throws -> Data {
            guard count >= 0, UInt64(count) <= remaining else {
                throw InvalidModel(reason: "Truncated model metadata")
            }
            var result = Data()
            result.reserveCapacity(count)
            while result.count < count {
                if position < bufferStart || position >= bufferStart + UInt64(buffer.count) {
                    try handle.seek(toOffset: position)
                    let limit = readsAhead ? 65_536 : count - result.count
                    buffer = try handle.read(upToCount: Int(min(UInt64(limit), remaining))) ?? Data()
                    bufferStart = position
                    guard !buffer.isEmpty else { throw InvalidModel(reason: "Truncated model file") }
                }
                let index = Int(position - bufferStart)
                let amount = min(count - result.count, buffer.count - index)
                result.append(buffer[index..<(index + amount)])
                position += UInt64(amount)
            }
            return result
        }

        func skip(_ count: UInt64) throws {
            guard count <= remaining else { throw InvalidModel(reason: "Truncated model payload") }
            position += count
        }
    }
}
