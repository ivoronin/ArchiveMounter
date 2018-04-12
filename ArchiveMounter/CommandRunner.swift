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

    /**
     Constructor
     - Parameters:
        - path: Path to executable file
        - arguments: Arguments
     */
    public init(path: String, arguments: [String] = []) {
        self.path = path
        self.arguments = arguments
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

        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw RuntimeError(message: "Command failed to run", description: error.localizedDescription)
        }

        process.waitUntilExit()

        output = readPipe(pipe: outputPipe)
        error = readPipe(pipe: errorPipe)
        status = process.terminationStatus
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
