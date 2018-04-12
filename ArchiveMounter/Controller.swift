import Cocoa

/** RuntimeError class */
public struct RuntimeError: Error {
    /** `message` will be used as an NSAlert messageText (title) */
    public var message: String
    /** `description` will be used as an NSAlert informativeText (body) */
    public var description: String
}

/**
 Main application controller
 */
public class Controller {
    /**
     Failable constructor
     - Returns: Controller instance or `nil` if FUSE for macOS installation is not detected
     */
    public init?() {
        guard System.fileExists(atPath: "/Library/Filesystems/osxfuse.fs/Contents/Resources/mount_osxfuse") else {
            let alert: NSAlert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "FUSE for macOS is not installed"
            alert.informativeText = "Please download and install the latest version. " +
                                    "Do you want to open FUSE for macOS home page?"
            alert.addButton(withTitle: "Open")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                System.openBrowser(atUrl: "https://osxfuse.github.io/")
            }
            return nil
        }
    }

    /**
     Mounts specified archive file
     - Parameters:
        - fileName: Path to archive file
     */
    public func mount(fileName: String) {
        do {
            let fileURL: URL = URL(fileURLWithPath: fileName)
            let fileExt: String = fileURL.pathExtension
            let volumeName: String = fileURL.deletingPathExtension().lastPathComponent
            let mountPoint: String = try System.createTemporaryDirectory()

            let mounter: Mounter = try MounterFactory.getMounter(fileExt: fileExt)
            try mounter.mount(fileName: fileName, mountPoint: mountPoint, volumeName: volumeName)

            System.openFinder(atPath: mountPoint)
        } catch {
            let alert: NSAlert = NSAlert()
            alert.alertStyle = .critical
            if let error: RuntimeError = error as? RuntimeError {
                alert.messageText = error.message
                alert.informativeText = error.description
            } else {
                let error: NSError = error as NSError
                alert.messageText = error.localizedDescription
                if let informativeText: String = error.localizedRecoverySuggestion {
                    alert.informativeText = informativeText
                }
            }
            alert.runModal()
        }
    }
}
