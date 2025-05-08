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

    var status: PortStatus {
        return latestVersion.map {$0 == version ? PortStatus.latest : PortStatus.outdated } ?? PortStatus.unknown
    }

}

protocol PortServiceProtocol {
    func loadLocalPorts() throws -> [Port]
}

enum ShellError: Error {
    case nonZeroStatusCode(statusCode: Int)
}

class ShellPortService: PortServiceProtocol {

    func executeShellCommand(command: String) throws -> String {
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
        //TODO: make async?
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw ShellError.nonZeroStatusCode(statusCode: Int(process.terminationStatus))
        }

        return String(data: data, encoding: .utf8)!
    }

    func loadLocalPorts() throws -> [Port] {
        let versionRegex = /[0-9][0-9a-z-]*(\.[0-9a-z-]+){0,4}/
        var ports: [Port] = []

        let output = try executeShellCommand(command: "port version")
        if let matches = try versionRegex.firstMatch(in: output) {
            let version = String(matches.0)
            ports.append(Port(name: "macports", version: version))
        }

        let installed = try executeShellCommand(command: "port installed requested and active")
        for line in installed.lines {
            let parts = line.split(separator: " ")
            if parts.count > 2 {
                let name = String(parts[0])
                if let matches = try versionRegex.firstMatch(in: String(parts[1])) {
                    let version = String(matches.0)
                    ports.append(Port(name: name, version: version))
                }
            }
        }

        return ports
    }

}
