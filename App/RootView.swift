//
//import SwiftUI
//
//private enum ActiveSheet: Identifiable {
//    case albums
//    case deleteReview
//    case laterReview
//    case donate(URL)
//
//    var id: String {
//        switch self {
//        case .albums: return "albums"
//        case .deleteReview: return "deleteReview"
//        case .laterReview: return "laterReview"
//        case .donate(let u): return "donate:\(u.absoluteString)"
//        }
//    }
//}
//
//struct RootView: View {
//    @Environment(\.photoLibrary) private var lib
//    @Environment(\.imageLoader)  private var images
//    @EnvironmentObject private var store: DecisionStore
//    @EnvironmentObject private var albumSel: AlbumSelection
//
//    @AppStorage("SwipeClean.HasShownHowTo.v1") private var hasShownHowTo = false
//
//    @State private var sheet: ActiveSheet?
//    @State private var showHowTo = false
//    @State private var didScheduleHowTo = false
//
//    private let donateURL = URL(string: "https://www.paypal.com/donate/?hosted_button_id=YourButtonID")!
//
//    var body: some View {
//        NavigationStack {
//            ZStack(alignment: .top) {
//
//                // CONTENT
//                VStack(spacing: 0) {
//                    header
//                        .zIndex(10)
//                        .background(.ultraThinMaterial)      // <- creates a solid, hit-testable slab
//                        .contentShape(Rectangle())            // <- ensures taps are captured by header
//                    Divider().opacity(0.15)
//
//                    CardStackView()
//                        .environment(\.photoLibrary, lib)
//                        .environment(\.imageLoader, images)
//                        .environmentObject(store)
//                        .environmentObject(albumSel)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .clipped()                            // <- make sure deck doesn’t spill over header
//                        .zIndex(0)
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        // Unified sheets
//        .sheet(item: $sheet) { item in
//            switch item {
//            case .albums:
//                AlbumPickerView()
//                    .environmentObject(albumSel)
//
//            case .deleteReview:
//                DeleteReviewView()
//                    .environmentObject(store)
//                    .environment(\.imageLoader, images)
//
//            case .laterReview:
//                LaterReviewView()
//                    .environmentObject(store)
//                    .environment(\.imageLoader, images)
//
//            case .donate(let url):
//                SafariView(url: url).ignoresSafeArea()
//            }
//        }
//        // Tutorial (the only presenter)
//        .fullScreenCover(isPresented: $showHowTo) {
//            FirstRunOverlay {
//                hasShownHowTo = true
//                showHowTo = false
//            }
//            .ignoresSafeArea()
//        }
//        .task {
//            guard !didScheduleHowTo else { return }
//            didScheduleHowTo = true
//            if !hasShownHowTo {
//                // small delay avoids presenting while view hierarchy is still mounting
//                try? await Task.sleep(nanoseconds: 150_000_000)
//                showHowTo = true
//            }
//        }
//    }
//
//    // MARK: Header
//
//    private var header: some View {
//        HStack(spacing: 14) {
//            Text("SwipeClean")
//                .font(.system(size: 28, weight: .bold, design: .rounded))
//                .lineLimit(1)
//                .minimumScaleFactor(0.75)
//
//            Spacer(minLength: 12)
//
//            Button { sheet = .albums }        label: { Image(systemName: "folder") }
//            Button { sheet = .deleteReview }  label: { Image(systemName: "trash") }
//            Button { sheet = .laterReview }   label: { Image(systemName: "clock") }
//            Button { showHowTo = true }       label: { Image(systemName: "info.circle") }
//            Button { sheet = .donate(donateURL) } label: { Image(systemName: "heart") }
//        }
//        .font(.title3.weight(.semibold))
//        .padding(.horizontal, 16)
//        .padding(.top, 6)
//        .padding(.bottom, 6)
//    }
//}

//
//  RootView.swift
//  PhotoZ
//

import SwiftUI

private enum ActiveSheet: Identifiable {
    case albums
    case deleteReview
    case laterReview

    var id: String {
        switch self {
        case .albums:        return "albums"
        case .deleteReview:  return "deleteReview"
        case .laterReview:   return "laterReview"
        }
    }
}

struct RootView: View {
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images
    @EnvironmentObject private var store: DecisionStore
    @EnvironmentObject private var albumSel: AlbumSelection

    @AppStorage("SwipeClean.HasShownHowTo.v1") private var hasShownHowTo = false

    @State private var sheet: ActiveSheet?
    @State private var showHowTo = false
    @State private var didScheduleHowTo = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {

                VStack(spacing: 0) {
                    header
                        .zIndex(10)
                        .background(.ultraThinMaterial)  // hit-testable slab so taps always work
                        .contentShape(Rectangle())
                    Divider().opacity(0.15)

                    CardStackView()
                        .environment(\.photoLibrary, lib)
                        .environment(\.imageLoader, images)
                        .environmentObject(store)
                        .environmentObject(albumSel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .zIndex(0)
                }
            }
            .navigationBarHidden(true)
        }
        // Unified sheets
        .sheet(item: $sheet) { item in
            switch item {
            case .albums:
                AlbumPickerView()
                    .environmentObject(albumSel)

            case .deleteReview:
                DeleteReviewView()
                    .environmentObject(store)
                    .environment(\.imageLoader, images)

            case .laterReview:
                LaterReviewView()
                    .environmentObject(store)
                    .environment(\.imageLoader, images)
            }
        }
        // First-run tutorial (single presenter)
        .fullScreenCover(isPresented: $showHowTo) {
            FirstRunOverlay {
                hasShownHowTo = true
                showHowTo = false
            }
            .ignoresSafeArea()
        }
        .task {
            guard !didScheduleHowTo else { return }
            didScheduleHowTo = true
            if !hasShownHowTo {
                // small delay avoids racing with view mounting
                try? await Task.sleep(nanoseconds: 150_000_000)
                showHowTo = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Text("SwipeClean")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 12)

            Button { sheet = .albums }        label: { Image(systemName: "folder") }
            Button { sheet = .deleteReview }  label: { Image(systemName: "trash") }
            Button { sheet = .laterReview }   label: { Image(systemName: "clock") }
            Button { showHowTo = true }       label: { Image(systemName: "info.circle") }
        }
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}
