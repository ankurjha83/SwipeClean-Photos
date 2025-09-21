////
////  PhotoCard.swift
////  PhotoZ
////
//
//import SwiftUI
//
//struct PhotoCard: View {
//    let asset: PhotoAsset
//    let size: CGSize
//
//    let onDelete: () -> Void
//    let onLater:  () -> Void
//    let onKeep:   () -> Void
//
//    @Environment(\.imageLoader) private var images
//
//    @State private var uiImage: UIImage?
//    @GestureState private var drag: CGSize = .zero
//    @State private var showViewer = false
//
//    private let commitX: CGFloat = 100
//    private let commitY: CGFloat = -100
//
//    @AppStorage("hasSeenFullSwipeOnboarding") private var hasSeenFullOnboarding = false
//
//    var body: some View {
//        ZStack {
//            // BACKDROP (soft blur of the photo to avoid hard bars)
//            if let img = uiImage {
//                Image(uiImage: img)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: size.width, height: size.height)
//                    .blur(radius: 20)
//                    .clipped()
//                    .opacity(0.35)
//            } else {
//                Color(UIColor.secondarySystemBackground)
//            }
//
//            // MAIN IMAGE — keep aspect (no cropping)
//            Group {
//                if let img = uiImage {
//                    Image(uiImage: img)
//                        .resizable()
//                        .scaledToFit()                          // ← no crop; respects landscape
//                        .frame(width: size.width, height: size.height)
//                        .clipped()
//                } else {
//                    Rectangle().fill(Color.secondary.opacity(0.15))
//                        .overlay(ProgressView())
//                        .frame(width: size.width, height: size.height)
//                }
//            }
//            .contentShape(Rectangle())
//            .onTapGesture { showViewer = true }
//
//            // Backdrop tint + badges
//            SwipeBackdropTint(direction: directionForDrag(drag),
//                              strength: progressForDrag(drag))
//
//            if drag.width > 0 {
//                SwipeBadge(kind: .keep,   progress: min(1, abs(drag.width) / commitX))
//            } else if drag.width < 0 {
//                SwipeBadge(kind: .delete, progress: min(1, abs(drag.width) / commitX))
//            }
//            if drag.height < 0 && abs(drag.width) < commitX * 0.6 {
//                SwipeBadge(kind: .later,  progress: min(1, abs(drag.height) / abs(commitY)))
//            }
//
//            if hasSeenFullOnboarding {
//                VStack { SwipeHintsHUD(); Spacer() }
//            } else {
//                FirstRunOverlay { hasSeenFullOnboarding = true }
//                    .transition(.opacity)
//                    .zIndex(10)
//                    .allowsHitTesting(true)
//            }
//        }
//        .frame(width: size.width, height: size.height)
//        .background(
//            RoundedRectangle(cornerRadius: 18, style: .continuous)
//                .fill(Color(UIColor.secondarySystemBackground))
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
//        .shadow(color: .black.opacity(0.15), radius: 10, y: 8)
//        .rotationEffect(.degrees(Double(drag.width / 15)))
//        .offset(x: drag.width, y: drag.height * 0.6)
//        .gesture(
//            DragGesture(minimumDistance: 8, coordinateSpace: .local)
//                .updating($drag) { value, state, _ in
//                    state = value.translation
//                }
//                .onEnded(handleEnd)
//        )
//        .task(id: size) { await load() }
//        .fullScreenCover(isPresented: $showViewer) {
//            PhotoViewer(asset: asset)
//        }
//    }
//
//    private func handleEnd(_ value: DragGesture.Value) {
//        let t = value.translation
//        let h = UIImpactFeedbackGenerator(style: .medium)
//        if t.width > commitX { h.impactOccurred(); onKeep() }
//        else if t.width < -commitX { h.impactOccurred(); onDelete() }
//        else if t.height < commitY && abs(t.width) < commitX { h.impactOccurred(); onLater() }
//    }
//
//    private func directionForDrag(_ t: CGSize) -> SwipeBackdropTint.Direction {
//        if t.width > 0, abs(t.width) >= abs(t.height) { return .right }
//        if t.width < 0, abs(t.width) >= abs(t.height) { return .left  }
//        if t.height < 0 { return .up }
//        return .none
//    }
//    private func progressForDrag(_ t: CGSize) -> CGFloat {
//        switch directionForDrag(t) {
//        case .right, .left: return min(1, abs(t.width) / commitX)
//        case .up:           return min(1, abs(t.height) / abs(commitY))
//        case .none:         return 0
//        }
//    }
//
//    private func load() async {
//        // Request at pixel size for crispness
//        let s = UIScreen.main.scale
//        let target = CGSize(width: size.width * s, height: size.height * s)
//        if let img = await images.thumbnail(for: asset, targetSize: target) {
//            uiImage = img
//        }
//    }
//}



//
//  PhotoCard.swift
//  PhotoZ
//

import SwiftUI

struct PhotoCard: View {
    let asset: PhotoAsset
    let size: CGSize

    let onDelete: () -> Void
    let onLater:  () -> Void
    let onKeep:   () -> Void

    @Environment(\.imageLoader) private var images

    @State private var uiImage: UIImage?
    @GestureState private var drag: CGSize = .zero
    @State private var showViewer = false

    private let commitX: CGFloat = 100
    private let commitY: CGFloat = -100

    var body: some View {
        ZStack {
            // BACKDROP (soft blur of the photo to avoid hard bars)
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .blur(radius: 20)
                    .clipped()
                    .opacity(0.35)
            } else {
                Color(UIColor.secondarySystemBackground)
            }

            // MAIN IMAGE — keep aspect (no cropping)
            Group {
                if let img = uiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()                          // respects landscape
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    Rectangle().fill(Color.secondary.opacity(0.15))
                        .overlay(ProgressView())
                        .frame(width: size.width, height: size.height)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { showViewer = true }

            // Backdrop tint + badges
            SwipeBackdropTint(direction: directionForDrag(drag),
                              strength: progressForDrag(drag))

            if drag.width > 0 {
                SwipeBadge(kind: .keep,   progress: min(1, abs(drag.width) / commitX))
            } else if drag.width < 0 {
                SwipeBadge(kind: .delete, progress: min(1, abs(drag.width) / commitX))
            }
            if drag.height < 0 && abs(drag.width) < commitX * 0.6 {
                SwipeBadge(kind: .later,  progress: min(1, abs(drag.height) / abs(commitY)))
            }

            // (Optional) small HUD, not a full-screen overlay
            VStack { SwipeHintsHUD(); Spacer() }
        }
        .frame(width: size.width, height: size.height)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 8)
        .rotationEffect(.degrees(Double(drag.width / 15)))
        .offset(x: drag.width, y: drag.height * 0.6)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .updating($drag) { value, state, _ in
                    state = value.translation
                }
                .onEnded(handleEnd)
        )
        .task(id: size) { await load() }
        .fullScreenCover(isPresented: $showViewer) {
            PhotoViewer(asset: asset)
        }
    }

    private func handleEnd(_ value: DragGesture.Value) {
        let t = value.translation
        let h = UIImpactFeedbackGenerator(style: .medium)
        if t.width > commitX { h.impactOccurred(); onKeep() }
        else if t.width < -commitX { h.impactOccurred(); onDelete() }
        else if t.height < commitY && abs(t.width) < commitX { h.impactOccurred(); onLater() }
    }

    private func directionForDrag(_ t: CGSize) -> SwipeBackdropTint.Direction {
        if t.width > 0, abs(t.width) >= abs(t.height) { return .right }
        if t.width < 0, abs(t.width) >= abs(t.height) { return .left  }
        if t.height < 0 { return .up }
        return .none
    }

    private func progressForDrag(_ t: CGSize) -> CGFloat {
        switch directionForDrag(t) {
        case .right, .left: return min(1, abs(t.width) / commitX)
        case .up:           return min(1, abs(t.height) / abs(commitY))
        case .none:         return 0
        }
    }

    private func load() async {
        // Request at pixel size for crispness
        let s = UIScreen.main.scale
        let target = CGSize(width: size.width * s, height: size.height * s)
        if let img = await images.thumbnail(for: asset, targetSize: target) {
            uiImage = img
        }
    }
}
