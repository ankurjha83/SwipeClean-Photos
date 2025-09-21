import SwiftUI

struct ActionButtons: View {
    let onDelete: () -> Void
    let onLater:  () -> Void
    let onKeep:   () -> Void

    var body: some View {
        HStack(spacing: 32) {
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Circle().fill(Color.red))
            }
            .accessibilityLabel("Delete")

            Button(action: onLater) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Circle().fill(Color.yellow))
            }
            .accessibilityLabel("Decide later")

            Button(action: onKeep) {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Circle().fill(Color.green))
            }
            .accessibilityLabel("Keep")
        }
        .padding(.vertical, 8)
    }
}
