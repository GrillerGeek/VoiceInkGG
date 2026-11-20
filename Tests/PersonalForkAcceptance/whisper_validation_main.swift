import Foundation
import whisper

/// One candidate per process: 0 means valid, 1 means rejected, 64 means harness misuse.
/// REFERENCE_ONLY calibrates the frozen native framework using CPU and no inference state.
@main
struct WhisperValidationProbe {
    static func main() {
        guard CommandLine.arguments.count == 2 else {
            FileHandle.standardError.write(Data("usage: whisper-validation MODEL.bin\n".utf8))
            exit(64)
        }
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        #if REFERENCE_ONLY
        var parameters = whisper_context_default_params()
        parameters.use_gpu = false
        parameters.flash_attn = false
        guard let context = url.path.withCString({
            whisper_init_from_file_with_params_no_state($0, parameters)
        }) else {
            print("INVALID")
            exit(1)
        }
        whisper_free(context)
        #else
        do {
            try WhisperModelValidator.validate(at: url)
        } catch {
            print("INVALID")
            exit(1)
        }
        #endif
        print("VALID")
        exit(0)
    }
}
