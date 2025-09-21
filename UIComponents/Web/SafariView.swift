import SwiftUI
import SafariServices

public struct SafariView: UIViewControllerRepresentable {
    public init(url: URL) { self.url = url }
    private let url: URL

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.preferredBarTintColor = nil
        vc.preferredControlTintColor = nil
        return vc
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
