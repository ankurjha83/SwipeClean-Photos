//
//  UndoButton.swift
//  PhotoZ
//
//  Created by Swati Pareek on 15/08/25.
//


import SwiftUI

struct UndoButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("Undo", systemImage: "arrow.uturn.backward.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.trailing, 18)
        .padding(.bottom, 86)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}
