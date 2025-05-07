import SwiftUI

@Observable class PortsModel {
    private let service: PortServiceProtocol
    private let api: PortApiProtocol
    var ports: [Port]
    var loading: Bool
    var lastCheck: String?

    init(ports: [Port]) {
        self.ports = ports
        self.service = ShellPortService()
        self.api = PortHttpApi()
        self.loading = false
    }

    func load() async {
        do {
            ports = try service.loadLocalPorts()
            loading = true
            let versions: [String: String] = try await api.fetchPortVersions(names: ports.map { $0.name })
            loading = false

            var updated: [Port] = []
            for port in ports {
                if let version = versions[port.name] {
                    let new = Port(name: port.name, version: port.version, latestVersion: version)
                    updated.append(new)
                }
                else {
                    updated.append(port)
                }
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "y-MM-dd HH:mm"
            lastCheck = formatter.string(from: Date())

            ports = updated
        } catch {
            loading = false
            //TODO: handle errors
        }
    }
}

struct PortListView: View {
    @State var model = PortsModel(ports: [])

    var body: some View {
        //TODO: handla case when zero ports installed
        ScrollView {
            Grid(horizontalSpacing: 5, verticalSpacing: 10) {
                GridRow {
                    Text("Last checked: \(model.loading ? "loading..." : model.lastCheck ?? "")")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .leading, .trailing,], 5)
                        .gridCellColumns(3)
                }
                Divider()
                    .gridCellUnsizedAxes(.horizontal)
                ForEach(model.ports) { port in
                    GridRow {
                        image(port.status)
                            .gridColumnAlignment(.trailing)
                            .foregroundColor(color(port.status))
                        Text("\(port.name)")
                            .gridColumnAlignment(.leading)
                            .foregroundColor(color(port.status))
                        Text("\(port.version)")
                            .gridColumnAlignment(.trailing)
                            .foregroundColor(color(port.status))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .task { await model.load() }
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
