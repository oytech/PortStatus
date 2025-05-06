import SwiftUI

@Observable class PortsModel {
    private let service: PortServiceProtocol
    var ports: [Port]

    init(ports: [Port]) {
        self.ports = ports
        self.service = ShellPortService()
    }

    func load() {
        do {
            ports = try service.loadLocalPorts()
        } catch {
            //TODO: handle errors
            ports = []
        }
    }
}

struct PortListView: View {
    @State var model = PortsModel(ports: [])

    var body: some View {
        VStack {
            List(model.ports) { port in
                HStack {
                    Text("\(port.name)")
                    Text("\(port.version)")
                        .background(port.isLatest ? .green : .red)
                }
            }
            .listStyle(.plain)
            .task { model.load() }
        }
        .padding()
    }
}

#Preview {
    let model = PortsModel(ports: [
        Port(name: "openjdk24", version: "24.0.1", isLatest: false),
        Port(name: "python312", version: "3.12.10", isLatest: true)
    ])
    PortListView(model: model)
}
