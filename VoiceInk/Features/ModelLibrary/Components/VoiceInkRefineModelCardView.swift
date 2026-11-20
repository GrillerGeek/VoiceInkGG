import SwiftUI

struct VoiceInkRefineModelCardView: View {
    @ObservedObject var service: VoiceInkRefineService
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("VoiceInk Refine — Unavailable", systemImage: "info.circle")
                .font(.headline)
            Text(VoiceInkRefineService.unavailableReason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppMaterialCardBackground())
    }
}
