import AppKit

/**
 Various static helper functions for interacting with an operating system
 */
public class System {
    /**
     Shows system file selection dialog
     - Returns: Path to selected file
     */
    public class func selectFile() -> String? {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.title = "Choose an archive"
        panel.prompt = "Mount"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = MounterFactory.allowedFileTypes
        return panel.runModal() == .OK ? panel.urls.first?.path : nil
    }

    /**
     Check if specified file exists
     - Parameters:
        - atPath: path to file
     */
    public class func fileExists(atPath: String) -> Bool {
        return FileManager.default.fileExists(atPath: atPath)
    }

    /**
     Show spicified folder in Finder window
     - Parameters:
        - atPath: path to directory to show
     */
    public class func openFinder(atPath: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: atPath)
    }

    /**
     Opens specified URL in browser
     - Parameters:
       - atUrl: url to open in browser
     */
    public class func openBrowser(atUrl: String) {
        if let url: URL = URL(string: atUrl) {
            NSWorkspace.shared.open(url)
        }
    }

    /**
     Creates temporary subdirectory in `$TMPDIR`
     - Throws: `RuntimeError` on `createDirectory()` failure
     - Note: Generated UUID is used as a subdirectory name
     */
    public class func createTemporaryDirectory() throws -> String {
        let uuid: String = UUID().uuidString
        let url: URL = FileManager.default.temporaryDirectory.appendingPathComponent(uuid)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw RuntimeError(message: "Failed to create temporary directory",
                               description: error.localizedDescription)
        }
        return url.path
    }
}
