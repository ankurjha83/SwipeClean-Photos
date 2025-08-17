import SwiftUI

enum TriageToast { case keep, favorite, later, delete }

struct ActionToastIcon: View {
    let type: TriageToast
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(color)
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(radius: 6)
    }
    private var symbol: String {
        switch type {
        case .keep:     return "checkmark.circle.fill"
        case .favorite: return "heart.circle.fill"
        case .later:    return "timer.circle.fill"
        case .delete:   return "xmark.circle.fill"
        }
    }
    private var color: Color {
        switch type {
        case .keep:     return .green
        case .favorite: return .purple
        case .later:    return .yellow
        case .delete:   return .red
        }
    }
}
