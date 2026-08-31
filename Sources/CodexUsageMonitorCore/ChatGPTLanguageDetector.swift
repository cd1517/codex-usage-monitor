import Darwin
import Foundation

public enum ChatGPTLanguageDetector {
    public static func detect() -> String? {
        chatGPTLocaleIdentifier(from: runningRendererArguments())
    }

    private static func runningRendererArguments() -> [[String]] {
        let estimatedCount = max(Int(proc_listallpids(nil, 0)), 256)
        var processIDs = [pid_t](repeating: 0, count: estimatedCount * 2)
        let count = proc_listallpids(
            &processIDs,
            Int32(processIDs.count * MemoryLayout<pid_t>.stride)
        )
        guard count > 0 else {
            return []
        }

        return processIDs.prefix(Int(count)).compactMap { processID in
            var pathBuffer = [CChar](repeating: 0, count: 4096)
            guard proc_pidpath(processID, &pathBuffer, UInt32(pathBuffer.count)) > 0 else {
                return nil
            }
            let executablePath = String(cString: pathBuffer)
            guard executablePath.contains("/ChatGPT.app/Contents/Frameworks/"),
                  executablePath.hasSuffix("/Codex (Renderer)") else {
                return nil
            }
            return processArguments(processID: processID)
        }
    }

    private static func processArguments(processID: pid_t) -> [String]? {
        var query = [Int32(CTL_KERN), Int32(KERN_PROCARGS2), processID]
        var size = 0
        guard sysctl(&query, UInt32(query.count), nil, &size, nil, 0) == 0,
              size > MemoryLayout<Int32>.size else {
            return nil
        }

        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&query, UInt32(query.count), &buffer, &size, nil, 0) == 0 else {
            return nil
        }
        return parseProcessArguments(Data(buffer.prefix(size)))
    }
}

func chatGPTLocaleIdentifier(from processArguments: [[String]]) -> String? {
    processArguments
        .first(where: { $0.contains("--type=renderer") })?
        .first(where: { $0.hasPrefix("--lang=") })?
        .dropFirst("--lang=".count)
        .nonEmptyString
}

func parseProcessArguments(_ data: Data) -> [String] {
    guard data.count >= MemoryLayout<Int32>.size else {
        return []
    }

    var argumentCount: Int32 = 0
    _ = withUnsafeMutableBytes(of: &argumentCount) { destination in
        data.copyBytes(to: destination, from: 0..<MemoryLayout<Int32>.size)
    }
    guard argumentCount > 0 else {
        return []
    }

    let bytes = [UInt8](data)
    var index = MemoryLayout<Int32>.size
    while index < bytes.count, bytes[index] != 0 {
        index += 1
    }
    while index < bytes.count, bytes[index] == 0 {
        index += 1
    }

    var arguments: [String] = []
    while index < bytes.count, arguments.count < Int(argumentCount) {
        let start = index
        while index < bytes.count, bytes[index] != 0 {
            index += 1
        }
        if start < index {
            arguments.append(String(decoding: bytes[start..<index], as: UTF8.self))
        }
        while index < bytes.count, bytes[index] == 0 {
            index += 1
        }
    }
    return arguments
}

private extension Substring {
    var nonEmptyString: String? {
        isEmpty ? nil : String(self)
    }
}
