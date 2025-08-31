import SwiftUI

/// Large tap targets for VoiceOver / accessibility users.
/// Hidden for non-VO users (PhotoCard decides when to show).
struct ActionButtons: View {
    let onKeep: () -> Void
    let onDelete: () -> Void
    let onLater: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Button {
                onLater()
            } label: {
                Label("Later", systemImage: "clock.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)

            Button {
                onKeep()
            } label: {
                Label("Keep", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(.ultraThinMaterial)
    }
}
