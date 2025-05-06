import SwiftUI

@main
struct PortStatusApp: App {
    var body: some Scene {
        MenuBarExtra() {
            PortListView()
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        } label: {
            HStack {
                Text("Ports")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
