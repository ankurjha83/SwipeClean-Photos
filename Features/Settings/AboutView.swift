import SwiftUI
import SafariServices

private let donateURL = URL(string: "https://www.paypal.com/donate/?hosted_button_id=REPLACE_ME")!

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SwipeClean")
                            .font(.headline)
                        Text("Review, stage, and clean your photo library with fast swipe gestures.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Support development") {
                    Button {
                        showSafari = true
                    } label: {
                        Label("Donate via PayPal", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                    }
                    .accessibilityHint("Opens PayPal in a browser")
                }

                Section("Version") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersionString).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSafari) {
                SafariView(url: donateURL)
                    .ignoresSafeArea()
            }
        }
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}

/// Simple SFSafariViewController wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
