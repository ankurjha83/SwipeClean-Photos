//
//  PhotoViewer.swift
//  PhotoZ
//
//  Full-screen zoomable viewer for a single asset.
//  - Sharp image (requests large pixel sizes, upgrades to near full-res in background)
//  - Pinch to zoom (in/out), pan when zoomed
//  - Double-tap to toggle zoom
//  - Swipe-down to dismiss when not zoomed
//

import SwiftUI

struct PhotoViewer: View {
    let asset: PhotoAsset

    @Environment(\.imageLoader) private var images
    @Environment(\.dismiss) private var dismiss

    @State private var uiImage: UIImage?

    // Zoom model (base * gesture)
    @State private var baseScale: CGFloat = 1.0
    @State private var pinchScale: CGFloat = 1.0
    private var effectiveScale: CGFloat { clamp(baseScale * pinchScale, min: 1.0, max: 5.0) }

    // Pan model
    @State private var baseOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    private var effectiveOffset: CGSize { clampedOffset(base: baseOffset, delta: dragOffset, scale: effectiveScale) }

    // Swipe-down-to-dismiss (active only when ~1x)
    @GestureState private var dismissDrag: CGSize = .zero
    private var canDragDismiss: Bool { effectiveScale <= 1.02 }
    private var dismissOffsetY: CGFloat { canDragDismiss ? dismissDrag.height : 0 }
    private var bgOpacity: Double {
        guard canDragDismiss else { return 1.0 }
        let p = min(max(abs(dismissDrag.height) / 300, 0), 1) // 0…1
        return 1.0 - (0.7 * Double(p)) // fade to 30%
    }

    // Upgrade to hi-res once (avoid needless repeats)
    @State private var didUpgradeToFull = false

    var body: some View {
        ZStack {
            Color.black
                .opacity(bgOpacity)
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let img = uiImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit() // show full photo initially
                                .frame(width: geo.size.width, height: geo.size.height)
                                .offset(x: effectiveOffset.width,
                                        y: effectiveOffset.height + dismissOffsetY) // add dismiss drag
                                .scaleEffect(effectiveScale, anchor: .center)
                                // Zoom gesture (pinch)
                                .gesture(zoomGesture.onEnded { _ in finalizeZoom() })
                                // Pan gesture only matters when zoomed in
                                .simultaneousGesture(panGesture(in: geo.size))
                                // Dismiss drag (active only near 1x)
                                .simultaneousGesture(dismissGesture)
                                .onTapGesture(count: 2, perform: toggleZoom)
                                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: effectiveScale)
                                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: effectiveOffset)
                                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: dismissOffsetY)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }

                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white.opacity(0.95))
                            .padding(12)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
            }

            // Hint
            VStack {
                Spacer()
                Text("Pinch or double-tap to zoom • Swipe down to close")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                    .opacity(0.9)
                    .padding(.bottom, 20)
            }
        }
        .task {
            await loadBestImage()            // sharp initial image (3× screen)
            await upgradeFullResInBackground() // upgrade to ~full-res quietly
        }
        .statusBar(hidden: true)
    }

    // MARK: - Gestures

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                pinchScale = value
            }
            .onEnded { _ in
                // handled in finalizeZoom()
            }
    }

    private func panGesture(in _: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard effectiveScale > 1.01 else {
                    // when not zoomed, keep centered (panning disabled)
                    baseOffset = .zero
                    dragOffset = .zero
                    return
                }
                dragOffset = v.translation
            }
            .onEnded { _ in
                baseOffset = clampedOffset(base: baseOffset, delta: dragOffset, scale: effectiveScale)
                dragOffset = .zero
            }
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dismissDrag) { value, state, _ in
                guard canDragDismiss else { state = .zero; return }
                // vertical-only feel
                state = CGSize(width: 0, height: max(0, value.translation.height))
            }
            .onEnded { v in
                guard canDragDismiss else { return }
                if v.translation.height > 140 {
                    dismiss()
                }
            }
    }

    private func finalizeZoom() {
        baseScale = clamp(baseScale * pinchScale, min: 1.0, max: 5.0)
        pinchScale = 1.0
        if baseScale <= 1.01 {
            baseScale = 1.0
            baseOffset = .zero
            dragOffset = .zero
        } else {
            baseOffset = clampedOffset(base: baseOffset, delta: dragOffset, scale: baseScale)
            dragOffset = .zero
            maybeUpgradeToFullRes()
        }
    }

    private func toggleZoom() {
        if baseScale > 1.01 || pinchScale > 1.01 {
            baseScale = 1.0
            pinchScale = 1.0
            baseOffset = .zero
            dragOffset = .zero
        } else {
            baseScale = 2.0
            maybeUpgradeToFullRes()
        }
    }

    // MARK: - Image loading (sharp)

    private func loadBestImage() async {
        // Request a large, crisp image (3× screen) for immediate sharpness
        let screen = UIScreen.main.bounds.size
        let target = CGSize(width: screen.width * UIScreen.main.scale * 3,
                            height: screen.height * UIScreen.main.scale * 3)
        if let img = await images.thumbnail(for: asset, targetSize: target) {
            uiImage = img
        }
    }

    private func upgradeFullResInBackground() async {
        guard !didUpgradeToFull else { return }
        // Fetch an even larger image (near full-res). 4096 is a good practical cap.
        let target = CGSize(width: 4096, height: 4096)
        if let hi = await images.thumbnail(for: asset, targetSize: target) {
            uiImage = hi
            didUpgradeToFull = true
        }
    }

    private func maybeUpgradeToFullRes() {
        // Fire-and-forget upgrade when the user zooms in
        Task { await upgradeFullResInBackground() }
    }

    // MARK: - Math helpers

    private func clamp<T: Comparable>(_ v: T, min lo: T, max hi: T) -> T { max(lo, min(v, hi)) }

    private func clampedOffset(base: CGSize, delta: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1 else { return .zero }
        // Bound the pan so the image doesn't drift infinitely.
        // Use generous limits that feel natural for a scaledToFit image.
        let extraX: CGFloat = 500 * (scale - 1)
        let extraY: CGFloat = 500 * (scale - 1)
        let x = clamp(base.width + delta.width, min: -extraX, max: extraX)
        let y = clamp(base.height + delta.height, min: -extraY, max: extraY)
        return CGSize(width: x, height: y)
    }
}
