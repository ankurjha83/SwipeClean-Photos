//
//  SwipeOverlays.swift
//  PhotoZ
//
//  Center-weighted swipe badges + soft tint overlay + tiny one-time hints.
//

import SwiftUI

/// A large, angled badge (DELETE/KEEP/LATER) that appears near the center.
/// Pass `progress` from 0…1 (how close the drag is to committing).
public struct SwipeBadge: View {
    public enum Kind { case delete, keep, later }

    let kind: Kind
    let progress: CGFloat   // 0…1

    public init(kind: Kind, progress: CGFloat) {
        self.kind = kind
        self.progress = max(0, min(1, progress))
    }

    public var body: some View {
        let c = constants(for: kind)

        return Text(c.text)
            .font(.system(size: 42, weight: .black, design: .rounded))
            .kerning(1.5)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(c.color.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(radius: 8, y: 4)
            .opacity(Double(progress))
            .scaleEffect(0.9 + 0.15 * progress)
            .rotationEffect(.degrees(c.rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .offset(c.offset)                 // ← positions on screen
            .allowsHitTesting(false)
    }

    // Swapped positions: KEEP on the LEFT, DELETE on the RIGHT
    private func constants(for kind: Kind) -> (text: String, color: Color, rotation: Double, offset: CGSize) {
        switch kind {
        case .keep:
            // Left of center, slight tilt left
            return ("KEEP", .green, -8, .init(width: -90, height: -12))
        case .delete:
            // Right of center, slight tilt right
            return ("DELETE", .red, 8, .init(width: 90, height: -12))
        case .later:
            // Centered but nudged upward a bit
            return ("LATER", .yellow, 0, .init(width: 0, height: -60))
        }
    }
}

/// A soft color wash that tints the image as you drag.
public struct SwipeBackdropTint: View {
    public enum Direction { case none, left, right, up }

    let direction: Direction
    let strength: CGFloat // 0…1

    public init(direction: Direction, strength: CGFloat) {
        self.direction = direction
        self.strength = max(0, min(1, strength))
    }

    public var body: some View {
        let tint: Color = {
            switch direction {
            case .left:  return .red
            case .right: return .green
            case .up:    return .yellow
            case .none:  return .clear
            }
        }()
        return tint.opacity(0.18 * strength)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

/// Small, one-time “cheat sheet” HUD shown until the first successful swipe.
public struct SwipeHintsHUD: View {
    @AppStorage("hasSeenSwipeHints") private var hasSeen = false

    public init() {}

    public var body: some View {
        if hasSeen {
            EmptyView()
        } else {
            HStack(spacing: 14) {
                label("← delete", .red)
                label("↑ later",  .yellow)
                label("→ keep",   .green)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .padding(.top, 8)
            .allowsHitTesting(false)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { hasSeen = true }
            }
        }
    }

    private func label(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.9), in: Capsule())
    }
}
