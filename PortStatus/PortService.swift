import Foundation

extension StringProtocol {
    var lines: [SubSequence] { split(whereSeparator: \.isNewline) }
}

enum PortStatus {
    case latest, outdated, unknown
}

struct Port: Identifiable  {
    var name: String
    var version: String
    var latestVersion: String?

    var id: String {
         return "\(name)@\(version)"
    }

    // FIXME: handle case when installed version could be newer?
    var status: PortStatus {
        return latestVersion.map {$0 == version ? PortStatus.latest : PortStatus.outdated } ?? PortStatus.unknown
    }

}

protocol PortServiceProtocol {
    func loadLocalPorts() async throws -> [Port]
}

enum ShellError: Error {
    case nonZeroStatusCode(statusCode: Int)
}

extension Process {
    func waitUntilExitAsync() async {
        await withCheckedContinuation { c in
            self.terminationHandler = { _ in
                c.resume()
            }
        }
    }
}

class ShellPortService: PortServiceProtocol {

    func execShellCommand(command: String) async throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.standardInput = nil
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // add --login to get full $PATH (does not work in sandbox)
        process.arguments = ["--login", "-c", command]

        // if zsh executable does no exist then throws error
        // if zsh does not found command then status != 0
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        await process.waitUntilExitAsync()
        if process.terminationStatus != 0 {
            throw ShellError.nonZeroStatusCode(statusCode: Int(process.terminationStatus))
        }

        return String(data: data, encoding: .utf8)!
    }

    func loadLocalPorts() async throws -> [Port] {
        let nameRegex = /[a-zA-Z0-9-.]+/
        let versionRegex = /[0-9][0-9a-z-]*(\.[0-9a-z-]+){0,4}/
        var ports: [Port] = []

        async let checkVersion = execShellCommand(command: "port version")
        async let checkInstalled = execShellCommand(command: "port installed requested and active")
        let (version, installed) = try await (checkVersion, checkInstalled)

        if let match = version.firstMatch(of: versionRegex) {
            ports.append(Port(name: "macports", version: String(match.0)))
        }

        for line in installed.lines {
            let parts = line.split(separator: " ")
            if parts.count > 2 {
                let namePart = parts[0]
                let versionPart = parts[1]

                if let _ = namePart.wholeMatch(of: nameRegex), let match = versionPart.firstMatch(of: versionRegex) {
                    ports.append(Port(name: String(namePart), version: String(match.0)))
                }
            }
        }

        return ports
    }

}
