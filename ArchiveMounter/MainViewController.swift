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
    @IBOutlet private var archivePathField: NSTextField!
    @IBOutlet private var volumeNameField: NSTextField!
    @IBOutlet private var encodingComboBox: NSComboBox!
    @IBOutlet private var readOnlyCheckBox: NSButton!

    /**
     Updates archivePath field
     - Parameters:
        - fileName: File name
     */
    public func openFile(fileUrl: URL) {
        archivePathField.stringValue = fileUrl.path
        archivePathField.toolTip = fileUrl.path
        volumeNameField.placeholderString = fileUrl.deletingPathExtension().lastPathComponent
    }

    /** Handles "Browse" button clicks */
    @IBAction private func browseButtonClicked(_ sender: NSButton) {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowedFileTypes = MountHelperFactory.allowedFileTypes
        if panel.runModal() == .OK {
            if let fileUrl: URL = panel.urls.first {
                openFile(fileUrl: fileUrl)
            }
        }
    }

    /** Handles "Mount" button clicks */
    @IBAction private func mountButtonClicked(_ sender: NSButton) {
        do {
            guard !archivePathField.stringValue.isEmpty else {
                throw RuntimeError(message: "Invalid input", description: "Please select an archive to mount")
            }
            let archivePath: URL = URL(fileURLWithPath: archivePathField.stringValue)

            let volumeName: String
            if volumeNameField.stringValue.isEmpty {
                guard let defaultName: String = volumeNameField.placeholderString else {
                    throw RuntimeError(message: "Unexpected error", description: "Cannot get default volume name")
                }
                if defaultName.isEmpty {
                    throw RuntimeError(message: "Unexpected error", description: "Default volume name is empty")
                }
                volumeName = defaultName
            } else {
                volumeName = volumeNameField.stringValue
            }

            var mountPoint: URL
            if #available(OSX 10.12, *) {
                mountPoint = FileManager.default.temporaryDirectory
            } else {
                mountPoint = URL(fileURLWithPath: NSTemporaryDirectory())
            }
            mountPoint.appendPathComponent(UUID().uuidString)
            mountPoint.appendPathComponent(Constants.mountPointName)

            let encoding: String? = encodingComboBox.stringValue.isEmpty ? nil : encodingComboBox.stringValue
            let readOnly: Bool = readOnlyCheckBox.state == .on

            try Mounter.mount(archivePath: archivePath,
                              mountPoint: mountPoint,
                              encoding: encoding,
                              volumeName: volumeName,
                              readOnly: readOnly)

            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: mountPoint.path)
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
