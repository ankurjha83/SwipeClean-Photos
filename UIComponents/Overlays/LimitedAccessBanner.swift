//
//  LimitedAccessBanner.swift
//  PhotoZ
//
//  Created by Swati Pareek on 17/08/25.
//


import SwiftUI
import UIKit

public struct LimitedAccessBanner: View {
    public init(onManage: @escaping () -> Void) { self.onManage = onManage }
    private let onManage: () -> Void

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.slash")
            Text("Access limited. Choose more photos")
            Spacer()
            Button("Manage") { onManage() }
        }
        .font(.footnote)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Access limited. Manage photos.")
    }
}
