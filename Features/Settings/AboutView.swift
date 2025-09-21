import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("HOW IT WORKS") {
                    Label("Swipe right / down: Keep", systemImage: "checkmark.circle")
                    Label("Swipe left: Delete (staged)", systemImage: "trash")
                    Label("Swipe up: Decide later", systemImage: "clock")
                }
                Section("PRIVACY") {
                    Text("Photos never leave your device. Deletions are staged until you confirm.")
                }
                Section {
                    Link("Donate with PayPal",
                         destination: URL(string: "https://www.paypal.com/donate/?hosted_button_id=YourButtonID")!)
                } footer: {
                    Text("Thank you for supporting the app ❤️")
                }
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
