//
//  FirstRunOverlay.swift
//  PhotoZ
//
//  A one-time, full-screen tutorial explaining swipe actions.
//

import SwiftUI

public struct FirstRunOverlay: View {
    /// Call to dismiss the overlay (and persist that it was seen).
    let dismiss: () -> Void

    @State private var show = false

    public init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    public var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .transition(.opacity)

            // Card-style tutorial content
            VStack(spacing: 20) {
                Text("How swiping works")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                VStack(spacing: 14) {
                    row(icon: "trash.fill",
                        title: "Swipe Left",
                        subtitle: "Mark for delete",
                        tint: .red)

                    row(icon: "clock.fill",
                        title: "Swipe Up",
                        subtitle: "Decide later",
                        tint: .yellow)

                    row(icon: "checkmark.circle.fill",
                        title: "Swipe Right",
                        subtitle: "Keep photo",
                        tint: .green)
                }
                .padding(.vertical, 6)

                Text("Tip: drag a little to preview the action badge.\nRelease past the threshold to commit.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button(action: dismiss) {
                    Text("Got it, let me try")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: 520)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .padding(.horizontal, 24)
            .shadow(radius: 20)
            .scaleEffect(show ? 1 : 0.96)
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: show)
        }
        .onAppear { show = true }
        .accessibilityAddTraits(.isModal)
    }

    private func row(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}
