import Foundation

/** Command Runner class */
public class CommandRunner {
    /** Path to executable file */
    private let path: String
    /** Arguments array */
    private let arguments: [String]

    /** stdout */
    public var output: String?
    /** sderr */
    public var error: String?
    /** exis status */
    public var status: Int32?
    /** shell special characters */
    private let shellQuoteRegEx: NSRegularExpression

    /**
     Constructor
     - Parameters:
        - path: Path to executable file
        - arguments: Arguments
     */
    public init(path: String, arguments: [String] = []) {
        self.path = path
        self.arguments = arguments
        // The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition, 2.2 Quoting
        // swiftlint:disable:next force_try
        self.shellQuoteRegEx = try! NSRegularExpression(pattern: "[|&;<>()$`\\\"'\\s\\t\\n*?\\[$~=%]", options: [])
    }

    /**
     Executes command
     - Throws: `RuntimeError` on execution failure
     - Note: Stores command stdout, stderr and exit status in `output`, `error` and `status` respectively
     */
    public func execute() throws {
        let outputPipe: Pipe = Pipe()
        let errorPipe: Pipe = Pipe()
        let process: Process = Process()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        if #available(OSX 10.14, *) {
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            do {
                try process.run()
            } catch {
                throw RuntimeError(message: "Command failed to run", description: error.localizedDescription)
            }
        } else {
            /* launch() throws runtime exceptions on exec() error, it's better to run /bin/sh instead */
            process.launchPath = "/bin/sh"
            let command: String = ([path] + arguments).map(shellQuote).joined(separator: " ")
            print(command)
            process.arguments = ["-c", command]
            process.launch()
        }

        process.waitUntilExit()

        output = readPipe(pipe: outputPipe)
        error = readPipe(pipe: errorPipe)
        status = process.terminationStatus
    }

    /**
     Escapes special characters in string
     - Parameters:
        - string: Input string
     - Returns: Escaped string
     */
    private func shellQuote(string: String) -> String {
        let range: NSRange = NSRange(location: 0, length: string.count)
        return shellQuoteRegEx.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "\\\\$0")
    }

    /**
     Reads all data from pipe
     - Parameters:
        - pipe: Pipe to read data from
     - Returns: Data from pipe or empty string if pipe is empty
     */
    private func readPipe(pipe: Pipe) -> String {
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
