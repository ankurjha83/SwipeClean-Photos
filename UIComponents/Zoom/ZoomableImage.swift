//
//  ZoomableImage.swift
//  PhotoZ
//
//  Pinch to zoom, double-tap to zoom, and pan within bounds.
//

import SwiftUI

public struct ZoomableImage: View {
    public let image: UIImage
    public let containerSize: CGSize             // the card size

    @Binding public var scale: CGFloat           // external bindings so parent can gate swipes
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
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: containerSize.width, height: containerSize.height)
            .clipped()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(zoomAndPanGesture)
            .onTapGesture(count: 2, perform: toggleZoom)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: scale)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: offset)
            .accessibilityLabel("Zoomable photo")
    }

    // MARK: - Gestures

    private var zoomAndPanGesture: some Gesture {
        let mag = MagnificationGesture()
            .onChanged { value in
                let proposed = scale * value
                scale = clamped(proposed)
                // when zooming out close to 1, recenter
                if scale <= minScale + 0.01 { offset = .zero }
            }
            .onEnded { value in
                scale = clamped(scale)
                if scale <= minScale + 0.01 {
                    scale = minScale
                    offset = .zero
                } else {
                    offset = clampedOffset(offset, for: scale)
                }
            }

        let pan = DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard scale > minScale + 0.01 else { offset = .zero; return }
                let proposed = CGSize(width: offset.width + v.translation.width,
                                      height: offset.height + v.translation.height)
                offset = clampedOffset(proposed, for: scale)
            }
            .onEnded { _ in
                offset = clampedOffset(offset, for: scale)
            }

        return mag.simultaneously(with: pan)
    }

    // MARK: - Helpers

    private func toggleZoom() {
        if scale > minScale + 0.01 {
            scale = minScale
            offset = .zero
        } else {
            scale = 2.0
            offset = .zero
        }
    }

    private func clamped(_ s: CGFloat) -> CGFloat {
        min(max(s, minScale), maxScale)
    }

    private func clampedOffset(_ proposed: CGSize, for s: CGFloat) -> CGSize {
        guard s > 1 else { return .zero }
        // Content grows by factor s; extra size is (s - 1) * size
        let maxX = (containerSize.width  * (s - 1)) / 2
        let maxY = (containerSize.height * (s - 1)) / 2
        return CGSize(
            width: min(max(proposed.width,  -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }
}
