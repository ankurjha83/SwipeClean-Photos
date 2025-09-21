import SwiftUI

struct FirstRunOverlay: View {
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("How SwipeClean works")
                    .font(.largeTitle).bold()

                VStack(spacing: 14) {
                    row(icon: "trash.fill",
                        iconColor: .red,
                        title: "Swipe Left",
                        subtitle: "Mark for delete")

                    row(icon: "clock.fill",
                        iconColor: .yellow,
                        title: "Swipe Up",
                        subtitle: "Decide later")

                    row(icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "Swipe Right / Down",
                        subtitle: "Keep photo")
                }

                Text("Tip: drag a little to preview the action badge. Release past the threshold to commit.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onClose) {
                    Text("Got it, let me try!")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(24)
        }
    }

    private func row(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: One-time flag
    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: "FirstRunOverlayShown")
    }

    static func markShown() {
        UserDefaults.standard.set(true, forKey: "FirstRunOverlayShown")
    }
}
