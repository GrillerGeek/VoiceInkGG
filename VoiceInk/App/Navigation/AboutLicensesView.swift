import AppKit
import SwiftUI

struct AboutLicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .accessibilityLabel("Robey Voice app icon")
                Text(AppIdentity.displayName)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Private dictation, on your Mac.")
                    .foregroundStyle(.secondary)
                Text("Robey Voice is a personal fork of VoiceInk by Prakash Joshi (Beingpax) and its contributors. Original copyright and GPLv3 rights are preserved. Robey Voice modifications: Jason Robey, November 16, 2026.")
                Text("Local dictation is unlimited. Cloud transcription, enhancement providers, and custom commands are optional and require your deliberate configuration. External providers may charge for their services.")
                Text("Manual installation")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("Quit Robey Voice and replace the app in Applications with your newer trusted build, then reopen it. Production replacements retain their stable data identity. Development builds keep separate settings, models, and credentials.")
                Text("Source and licenses")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Button("GNU GPLv3") { openLegalResource("GPL-3.0", extension: "txt") }
                    Button("Third-Party & Model Notices") { openLegalResource("THIRD_PARTY_NOTICES", extension: "md") }
                    Link("Upstream VoiceInk Source", destination: URL(string: "https://github.com/Beingpax/VoiceInk")!)
                }
                Text("Downloaded speech models retain their original provider names, licenses, and provenance. VoiceInk Refine is unavailable because its pinned model license permits use with VoiceInk only; choose plain local dictation or configure Ollama instead. See the bundled notices and the matching source archive supplied with this build.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .textSelection(.enabled)
            .frame(maxWidth: 680, alignment: .leading)
            .padding(32)
        }
    }

    private func openLegalResource(_ name: String, extension fileExtension: String) {
        let url = Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Legal")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
        if let url {
            NSWorkspace.shared.open(url)
        } else {
            let alert = NSAlert()
            alert.messageText = "License resource unavailable"
            alert.informativeText = "This application bundle is incomplete. Refer to the LICENSE and notices in the matching source package."
            alert.runModal()
        }
    }
}
