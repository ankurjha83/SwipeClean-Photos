//
//  SplashView.swift
//  PhotoZ
//

import SwiftUI

struct SplashView: View {
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 40, weight: .semibold))
                Text("SwipeClean")
                    .font(.system(.largeTitle, design: .rounded)).bold()
                ProgressView("Preparing photos…")
                    .padding(.top, 12)
            }
        }
        .task { await prepare() }
    }

    private func prepare() async {
        // Ask for permission first
        let status = await lib.requestAuthorization()

        let granted: Bool
        switch status {
        case .authorized, .limited:
            granted = true
        default:
            granted = false
        }

        if granted {
            // Fetch and prefetch first 6
            let all = lib.fetchAllPhotos(includeFavorites: true)
            let first = Array(all.prefix(6))
            let screen = UIScreen.main.bounds.size
            let target = CGSize(width: screen.width * UIScreen.main.scale,
                                height: screen.height * UIScreen.main.scale)
            images.startPrefetch(assets: first, targetSize: target)
        }

        // Keep splash briefly to avoid a flash
        try? await Task.sleep(nanoseconds: 600_000_000) // ~0.6s

        await MainActor.run { onFinish() }
    }
}
