import Foundation

public enum CodexExecutableResolver {
    public static func resolve(
        pathEnvironment: String = ProcessInfo.processInfo.environment["PATH"] ?? "",
        isExecutable: (String) -> Bool = FileManager.default.isExecutableFile(atPath:)
    ) -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let bundledCandidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "\(home)/Applications/ChatGPT.app/Contents/Resources/codex"
        ]
        let pathCandidates = pathEnvironment
            .split(separator: ":")
            .map { "\($0)/codex" }

        return (bundledCandidates + pathCandidates)
            .first(where: isExecutable)
            .map(URL.init(fileURLWithPath:))
    }
}
