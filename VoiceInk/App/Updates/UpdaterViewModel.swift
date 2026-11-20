import AppKit
import Combine
import Foundation
import SwiftUI

/// This private build uses manual installation. No update client or feed is initialized.
@MainActor
final class UpdaterViewModel: ObservableObject {
    let canCheckForUpdates = true

    func checkForUpdates() {
        let alert = NSAlert()
        alert.messageText = "Manual Updates for Robey Voice"
        alert.informativeText = "Quit Robey Voice, build or obtain a newer Robey Voice application from your trusted source, and replace the installed app in Applications. Reopen the replacement. Production builds keep the same data location; development builds use separate data. Automatic update checks are unavailable in this build."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel

    var body: some View {
        Button("Manual Update Instructions…", action: updaterViewModel.checkForUpdates)
    }
}
