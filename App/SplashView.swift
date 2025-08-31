//
//  SplashView.swift
//  PhotoZ
//

import SwiftUI

struct SplashView: View {
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images

    var onFinish: () -> Void

    @State private var isReady = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                // Tiny brand mark
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 40, weight: .semibold))
                Text("SwipeClean")
                    .font(.system(.largeTitle, design: .rounded)).bold()

                ProgressView("Preparing photos…")
                    .padding(.top, 12)
            }
        }
        .task { await prepare() }
        .onChange(of: isReady) { ready in
            if ready { onFinish() }
        }
    }

    private func prepare() async {
        // Ask for permissions if needed
        let status = await lib.requestAuthorization()
        guard status.isAuthorized else {
            // No access → just continue; downstream views will show a banner
            isReady = true
            return
        }

        // Fetch and prefetch the first 6
        let all = lib.fetchAllPhotos(includeFavorites: true)
        let first = Array(all.prefix(6))
        let screen = UIScreen.main.bounds.size
        let target = CGSize(width: screen.width * UIScreen.main.scale,
                            height: screen.height * UIScreen.main.scale)
        images.startPrefetch(assets: first, targetSize: target)

        // Keep splash up briefly so it doesn't flash
        try? await Task.sleep(nanoseconds: 600_000_000) // ~0.6s
        isReady = true
    }
}
