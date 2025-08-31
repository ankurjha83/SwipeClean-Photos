import SwiftUI
import UIKit

/// Wrap your app content with this gate. It requests Photos permission once,
/// and shows simple placeholders for other states. Step 6 will flesh out UI.
struct PermissionGate<Content: View>: View {
    @Environment(\.photoLibrary) private var lib
    @State private var status: PhotoAuthStatus = .notDetermined

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            switch status {
            case .authorized:
                content()

            case .limited:
                VStack(spacing: 16) {
                    Image(systemName: "lock.slash")
                        .font(.system(size: 40))
                    Text("Photos access is limited.")
                        .font(.headline)
                    Text("You can continue with limited photos or extend access in Settings.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Open Settings") { openSettings() }
                            .buttonStyle(.borderedProminent)
                        Button("Continue") {
                            // proceed with limited set
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()

            case .denied:
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 40))
                    Text("Photos access denied")
                        .font(.headline)
                    Text("Please allow Photos access in Settings to use SwipeClean.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Open Settings") { openSettings() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()

            case .notDetermined:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Requesting Photos permission…")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .task {
            // Initialize from current status, then request if needed.
            let current = lib.authorizationStatus
            if current == .notDetermined {
                let granted = await lib.requestAuthorization()
                status = granted
            } else {
                status = current
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
