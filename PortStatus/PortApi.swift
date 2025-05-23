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
        precondition(!name.isEmpty)
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
            of: (String, String)?.self,
            returning: [String: String].self
        ) { taskGroup in
            for name in names {
                taskGroup.addTask {
                    do {
                        return try await (name, self.fetchPortVersion(name: name))
                    } catch HttpError.error(code: 404) {
                        // do not fail if some port not found
                        return nil
                    } catch let error {
                        throw error
                    }
                }
            }

            var versions: [String: String] = [:]
            for try await data in taskGroup.compactMap({ $0 }) {
                versions[data.0] = data.1
            }

            return versions
        }
    }
}
