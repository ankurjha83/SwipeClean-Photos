//import SwiftUI
//import UIKit
//import Combine   // <- add this
//
///// Wrap your app content with this gate. It requests Photos permission once,
///// and shows polished states for .authorized / .limited / .denied.
//struct PermissionGate<Content: View>: View {
//    @Environment(\.photoLibrary) private var lib
//    @State private var status: PhotoAuthStatus = .notDetermined
//
//    let content: () -> Content
//
//    init(@ViewBuilder content: @escaping () -> Content) {
//        self.content = content
//    }
//
//    var body: some View {
//        Group {
//            switch status {
//            case .authorized:
//                content()
//
//            case .limited:
//                VStack(spacing: 16) {
//                    Image(systemName: "lock.slash")
//                        .font(.system(size: 44))
//                    Text("Limited Photos Access")
//                        .font(.headline)
//                    Text("You allowed access to a subset of photos. You can continue, or manage which photos are available.")
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.secondary)
//                        .padding(.horizontal)
//
//                    HStack(spacing: 12) {
//                        Button("Manage Selection") { lib.presentLimitedLibraryPicker() }
//                            .buttonStyle(.bordered)
//
//                        Button("Open Settings") { openSettings() }
//                            .buttonStyle(.bordered)
//
//                        Button("Continue") { }
//                            .buttonStyle(.borderedProminent)
//                    }
//                }
//                .padding()
//
//            case .denied:
//                VStack(spacing: 16) {
//                    Image(systemName: "hand.raised.fill")
//                        .font(.system(size: 44))
//                    Text("Photos Access Denied")
//                        .font(.headline)
//                    Text("Please allow Photos access in Settings to review and clean your library.")
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.secondary)
//                        .padding(.horizontal)
//                    Button("Open Settings") { openSettings() }
//                        .buttonStyle(.borderedProminent)
//                }
//                .padding()
//
//            case .notDetermined:
//                VStack(spacing: 12) {
//                    ProgressView()
//                    Text("Requesting Photos permission…")
//                        .foregroundStyle(.secondary)
//                }
//                .padding()
//            }
//        }
//        .task {
//            let current = lib.authorizationStatus
//            if current == .notDetermined {
//                let granted = await lib.requestAuthorization()
//                status = granted
//            } else {
//                status = current
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//            status = lib.authorizationStatus
//        }
//    }
//
//    private func openSettings() {
//        if let url = URL(string: UIApplication.openSettingsURLString) {
//            UIApplication.shared.open(url)
//        }
//    }
//}

//
//  PermissionGate.swift
//  PhotoZ
//
import SwiftUI
import Photos
import UIKit

@MainActor
struct PermissionGate<Content: View>: View {
    @Environment(\.photoLibrary) private var lib
    @State private var status: PhotoAuthStatus = .notDetermined

    private let contentBuilder: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.contentBuilder = content }

    var body: some View {
        content
            .task { status = lib.authorizationStatus }
            .onChange(of: lib.authorizationStatus) { _, new in status = new }
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .authorized, .limited:
            contentBuilder()

        case .notDetermined:
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Allow Photo Access").font(.title3).bold()
                Text("SwipeClean needs access to your photo library to show images.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Button { Task { await requestAuthorization() } } label: {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .denied:
            VStack(spacing: 16) {
                Image(systemName: "lock.slash")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Photos Access Disabled").font(.title3).bold()
                Text("Enable access in Settings to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func requestAuthorization() async {
        let new = await lib.requestAuthorization()
        status = new
    }
}
