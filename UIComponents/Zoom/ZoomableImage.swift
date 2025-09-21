//
//  ZoomableImage.swift
//  PhotoZ
//
//  Pinch to zoom always; pan is only active when zoomed.
//  This prevents the pan from stealing the swipe gesture of the card.
//

import SwiftUI

public struct ZoomableImage: View {
    public let image: UIImage
    public let containerSize: CGSize

    @Binding public var scale: CGFloat
    @Binding public var offset: CGSize

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    public init(image: UIImage,
                containerSize: CGSize,
                scale: Binding<CGFloat>,
                offset: Binding<CGSize>) {
        self.image = image
        self.containerSize = containerSize
        self._scale = scale
        self._offset = offset
    }

    public var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: containerSize.width, height: containerSize.height)
                .clipped()
                .scaleEffect(scale)
                .offset(offset)
                // Pinch is always active (does NOT block parent swipe)
                .gesture(magnificationGesture)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: scale)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: offset)

            // Pan is attached on a transparent overlay, ONLY when zoomed.
            // At 1x, this overlay doesn’t hit-test, so the parent card receives the drag.
            Color.clear
                .contentShape(Rectangle())
                .frame(width: containerSize.width, height: containerSize.height)
                .gesture(panGesture)
                .allowsHitTesting(scale > minScale + 0.01)
        }
        .accessibilityLabel("Zoomable photo")
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let proposed = scale * value
                scale = clamped(proposed)
                if scale <= minScale + 0.01 { offset = .zero }
            }
            .onEnded { _ in
                scale = clamped(scale)
                if scale <= minScale + 0.01 {
                    scale = minScale
                    offset = .zero
                } else {
                    offset = clampedOffset(offset, for: scale)
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { v in
                guard scale > minScale + 0.01 else { return }
                let proposed = CGSize(width: offset.width + v.translation.width,
                                      height: offset.height + v.translation.height)
                offset = clampedOffset(proposed, for: scale)
            }
            .onEnded { _ in
                guard scale > minScale + 0.01 else { return }
                offset = clampedOffset(offset, for: scale)
            }
    }

    // MARK: - Helpers

    private func clamped(_ s: CGFloat) -> CGFloat {
        min(max(s, minScale), maxScale)
    }

    private func clampedOffset(_ proposed: CGSize, for s: CGFloat) -> CGSize {
        guard s > 1 else { return .zero }
        let maxX = (containerSize.width  * (s - 1)) / 2
        let maxY = (containerSize.height * (s - 1)) / 2
        return CGSize(
            width: min(max(proposed.width,  -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }
}
