import AppKit
import SwiftUI

/// Compile the theme as an opaque subject; do not duplicate its implementation.
@main
struct ContrastProbe {
    static func channels(_ color: NSColor) throws -> [String: Double] {
        guard let rgb = color.usingColorSpace(.sRGB) else {
            throw NSError(domain: "ContrastProbe", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot resolve color to sRGB"])
        }
        return ["red": Double(rgb.redComponent), "green": Double(rgb.greenComponent),
                "blue": Double(rgb.blueComponent), "alpha": Double(rgb.alphaComponent)]
    }

    static func main() throws {
        var output: [String: [String: [String: Double]]] = [:]
        let dynamic = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .white : .black
        }
        for (label, name) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            guard let appearance = NSAppearance(named: name) else {
                throw NSError(domain: "ContrastProbe", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Missing appearance: \(label)"])
            }
            var result: Result<[String: [String: Double]], Error>!
            appearance.performAsCurrentDrawingAppearance {
                result = Result {
                    ["foreground": try channels(NSColor(AppTheme.Text.onAccent)),
                     "dynamicBridge": try channels(NSColor(Color(nsColor: dynamic))),
                     "blackBridge": try channels(NSColor(Color.black)),
                     "whiteBridge": try channels(NSColor(Color.white))]
                }
            }
            output[label] = try result.get()
        }
        let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
