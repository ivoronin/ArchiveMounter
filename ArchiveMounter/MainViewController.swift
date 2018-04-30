import Cocoa

/** RuntimeError class */
public struct RuntimeError: Error {
    /** `message` will be used as an NSAlert messageText (title) */
    public var message: String
    /** `description` will be used as an NSAlert informativeText (body) */
    public var description: String
}

/** Main window controller */
public class WindowController: NSWindowController, NSWindowDelegate {
    /** Terminate application when window is closed by user */
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.stop(nil)
        return true
    }
}

/** Main view controller */
public class MainViewController: NSViewController {
    private var mounter: Mounter?
    @IBOutlet private var archiveNameField: NSTextField!
    @IBOutlet private var volumeNameField: NSTextField!
    @IBOutlet private var encodingComboBox: NSComboBox!
    @IBOutlet private var readOnlyCheckBox: NSButton!

    override public func viewDidLoad() {
        super.viewDidLoad()
        /* Watch for "openFile" notifications */
        let center: NotificationCenter = NotificationCenter.default
        _ = center.addObserver(forName: Notification.Name("openFile"), object: nil, queue: nil, using: fileOpened)
    }

    /**
     Handles "openFile" notifications
     - Parameters:
        - notification: `Notification` object
     */
    private func fileOpened(notification: Notification) {
        if let filePath: String = notification.userInfo?["filePath"] as? String {
            /* Build mount point path */
            let tempUrl: URL
            if #available(OSX 10.12, *) {
                tempUrl = FileManager.default.temporaryDirectory
            } else {
                tempUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            }
            let uuid: String = UUID().uuidString
            let mountPointUrl: URL = tempUrl
                .appendingPathComponent(uuid)
                .appendingPathComponent(Constants.mountPointName)

            mounter = Mounter(filePath: filePath, mountPoint: mountPointUrl.path)
            if let mounter: Mounter = mounter {
                /* Update view with current values */
                archiveNameField.stringValue = mounter.fileName
                archiveNameField.toolTip = mounter.filePath
                volumeNameField.stringValue = mounter.volumeName
                encodingComboBox.stringValue = mounter.encoding ?? ""
                readOnlyCheckBox.state = mounter.mountFlags.contains(.rdonly) ? .on : .off
            }
        }
    }

    /** Handles "Browse" button clicks */
    @IBAction private func browseButtonClicked(_ sender: NSButton) {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowedFileTypes = MountHelperFactory.allowedFileTypes
        if panel.runModal() == .OK {
            if let filePath: String = panel.urls.first?.path {
                let center: NotificationCenter = NotificationCenter.default
                center.post(name: NSNotification.Name("openFile"), object: nil, userInfo: ["filePath": filePath])
            }
        }
    }

    /** Handles "Mount" button clicks */
    @IBAction private func mountButtonClicked(_ sender: NSButton) {
        do {
            guard let mounter: Mounter = mounter else {
                throw RuntimeError(message: "Invalid input", description: "Please select an archive to mount")
            }
            guard !volumeNameField.stringValue.isEmpty else {
                throw RuntimeError(message: "Invalid input", description: "Volume name can't be empty")
            }

            mounter.volumeName = volumeNameField.stringValue
            mounter.encoding = encodingComboBox.stringValue.isEmpty ? nil : encodingComboBox.stringValue
            if readOnlyCheckBox.state == .on {
                mounter.mountFlags.insert(.rdonly)
            } else {
                mounter.mountFlags.remove(.rdonly)
            }

            let mountPoint: String = try mounter.mount()
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: mountPoint)
            NSApp.stop(nil)
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
