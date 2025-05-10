import SwiftUI
import os

@Observable class PortsModel {
    private let service: PortServiceProtocol
    private let api: PortApiProtocol
    private let logger: Logger
    var ports: [Port]
    var loading: Bool
    var lastChecked: String?

    init(ports: [Port]) {
        self.service = ShellPortService()
        self.api = PortHttpApi()
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "")
        self.ports = ports
        self.loading = false
    }

    private func updateLastChecked() {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd HH:mm"
        lastChecked = formatter.string(from: Date())
    }

    func load(partial: Bool = false) async {
        do {
            loading = true
            logger.debug("loading...")

            let localPorts = try service.loadLocalPorts()
            if(partial) {
                ports = localPorts
            }
            let remoteVersions: [String: String] = try await api.fetchPortVersions(names: localPorts.map { $0.name })

            updateLastChecked()
            ports = localPorts.map {
                if let latestVersion = remoteVersions[$0.name] {
                    Port(name: $0.name, version: $0.version, latestVersion: latestVersion)
                }
                else {
                    $0
                }
            }
            loading = false
        } catch {
            loading = false
            logger.error("\(error)")
        }
    }
}

struct PortListView: View {
    @State var model = PortsModel(ports: [])

    var body: some View {
        // TODO: handla case when zero ports installed
        VStack {
            HStack {
                Text("Last check: \(model.loading ? "loading..." : model.lastChecked ?? "")")
                    .padding([.top, .leading, .trailing,], 5)
                Spacer()
                Button {
                    Task {
                        await model.load()
                    }
                } label: {
                    Text("reload")
                }
                .disabled(model.loading)
                .padding([.top, .leading, .trailing,], 5)
            }
            Divider()
            ScrollView {
                Grid(horizontalSpacing: 5, verticalSpacing: 10) {
                    ForEach(model.ports) { port in
                        GridRow {
                            image(port.status)
                                .gridColumnAlignment(.trailing)
                                .foregroundColor(color(port.status))
                                .padding(.leading, 15)
                            Text("\(port.name)")
                                .gridColumnAlignment(.leading)
                                .foregroundColor(color(port.status))
                            Spacer()
                            Text("\(port.version)")
                                .gridColumnAlignment(.trailing)
                                .foregroundColor(color(port.status))
                        }
                    }
                }
            }
            .task { await model.load(partial: true) }
        }
    }

    func image(_ status: PortStatus) -> Image {
        switch status {
        case .latest:
            return Image(systemName: "checkmark.circle")
        case .outdated:
            return Image(systemName: "xmark.circle")
        case .unknown:
            return Image(systemName: "questionmark.circle")
        }
    }

    func color(_ status: PortStatus) -> Color {
        switch status {
        case .latest:
            return Color.green
        case .outdated:
            return Color.red
        case .unknown:
            return Color.gray
        }
    }
}

#Preview {
    let model = PortsModel(ports: [
        Port(name: "openjdk21", version: "21.0.1", latestVersion: "21.0.2"),
        Port(name: "openjdk24", version: "24.0.1"),
        Port(name: "python312", version: "3.12.10"),
        Port(name: "python313", version: "3.13.3", latestVersion: "3.13.3")
    ])
    PortListView(model: model)
}
