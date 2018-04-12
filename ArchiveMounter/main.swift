import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var fileName: String?

    /**
     Handles `applicationDidFinishLaunching` event
     */
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        /* use `fileName` set by `openFile` event handler or ask user to select a file using system dialog */
        if let fileName: String = fileName ?? System.selectFile() {
            Controller()?.mount(fileName: fileName)
        }
        NSApp.terminate(nil)
    }

    /**
     Handles `openFile` event, fired before `applicationDidFinishLaunching`
     */
    public func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        self.fileName = filename
        return true
    }
}

NSApplication.shared.delegate = AppDelegate()
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
