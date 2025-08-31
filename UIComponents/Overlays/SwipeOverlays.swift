//
//  SwipeHint.swift
//  PhotoZ
//
//  Created by Swati Pareek on 17/08/25.
//


import SwiftUI

/// Semantic hint for swipe direction.
enum SwipeHint: Equatable {
    case keep, delete, later
}

/// Corner badge used while dragging to indicate the intended action.
/// `strength` should be 0...1 and controls opacity/scale.
struct SwipeBadge: View {
    let hint: SwipeHint
    let strength: CGFloat

    private var title: String {
        switch hint {
        case .keep:   return "KEEP"
        case .delete: return "DELETE"
        case .later:  return "LATER"
        }
    }

    private var color: Color {
        switch hint {
        case .keep:   return .green
        case .delete: return .red
        case .later:  return .yellow
        }
    }

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .kerning(1.2)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15 + 0.65 * strength))
                    .overlay(Capsule().stroke(color, lineWidth: 2 * strength))
            )
            .foregroundStyle(color)
            .scaleEffect(0.85 + 0.25 * strength)
            .accessibilityHidden(true)
    }
}
