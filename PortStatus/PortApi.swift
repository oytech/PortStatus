import Foundation

protocol PortApiProtocol {
    func fetchPortVersions(names: [String]) async throws -> [String: String]
}

struct GetPortResponse: Decodable {
    var name: String
    var version: String
}

enum HttpError: Error {
    case error(code: Int)
}

class PortHttpApi: PortApiProtocol {

    func fetchPortVersion(name: String) async throws -> String {
        //try await Task.sleep(nanoseconds: 2_000_000_000)
        //TODO: escape name?
        let url = URL(string: "https://ports.macports.org/api/v1/ports/\(name)/")!

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw HttpError.error(code: httpResponse.statusCode)
        }

        let port = try JSONDecoder().decode(GetPortResponse.self, from: data)

        return port.version
    }

    func fetchPortVersions(names: [String]) async throws -> [String: String] {
        try await withThrowingTaskGroup(
            of: (String, String).self,
            returning: [String: String].self
        ) { taskGroup in
            for name in names {
                taskGroup.addTask { try await (name, self.fetchPortVersion(name: name)) }
            }

            var versions: [String: String] = [:]
            while let data = try await taskGroup.next() {
                versions[data.0] = data.1
            }

            return versions
        }
    }
}
