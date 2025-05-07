import SwiftUI

@main
struct PortStatusApp: App {
    var body: some Scene {
        MenuBarExtra() {
            VStack(spacing: 0) {
                PortListView()
                Divider()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)//, alignment: .leading)
                        .padding(5)
                }
                .buttonStyle(.accessoryBar)
                .padding(5)
            }
        } label: {
            //TODO: add some general status indicator to menu bar label
            Text("Ports")
        }
        .menuBarExtraStyle(.window)
    }
}
