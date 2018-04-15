import AppKit

@NSApplicationMain
public class AppDelegate: NSObject, NSApplicationDelegate {
    /** Handles `applicationDidFinishLaunching` event */
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        /* Check if FUSE for macOS installation is present */
        let manager: FileManager = FileManager.default
        guard manager.fileExists(atPath: "/Library/Filesystems/osxfuse.fs/Contents/Resources/mount_osxfuse") else {
            let alert: NSAlert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "FUSE for macOS is not installed"
            alert.informativeText = "Please download and install the latest version. " +
                                    "Do you want to open FUSE for macOS home page?"
            alert.addButton(withTitle: "Open")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                if let url: URL = URL(string: "https://osxfuse.github.io/") {
                    NSWorkspace.shared.open(url)
                }
            }
            return NSApp.stop(nil)
        }
    }

    /** Handles `openFile` event, fired before `applicationDidFinishLaunching` */
    public func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        NotificationCenter.default.post(name: Notification.Name("openFile"),
                                        object: nil,
                                        userInfo: ["filePath": filename])
        return true
    }
}
