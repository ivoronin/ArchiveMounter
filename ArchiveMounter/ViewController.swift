import Cocoa

/** RuntimeError class */
public struct RuntimeError: Error {
    /** `message` will be used as an NSAlert messageText (title) */
    public var message: String
    /** `description` will be used as an NSAlert informativeText (body) */
    public var description: String
}

public struct Volume {
    public let name: String
    public let mountPoint: String
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
public class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private var mounter: Mounter?
    @IBOutlet private var archiveNameField: NSTextField!
    @IBOutlet private var volumeNameField: NSTextField!
    @IBOutlet private var encodingComboBox: NSComboBox!
    @IBOutlet private var readOnlyCheckBox: NSButton!
    @IBOutlet private var volumesTableView: NSTableView!

    /** Mount point directory name */
    private let mountPointName: String = "_ArchiveMounter"
    /** Mounted volume list */
    private var mountedVolumes: [Volume] = []

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        /* Local notifications */
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("openFile"),
                                                   object: nil,
                                                   queue: nil,
                                                   using: fileOpened)

        /* Volume-related notifications */
        for notificationName: Notification.Name in [NSWorkspace.didMountNotification,
                                                    NSWorkspace.didRenameVolumeNotification,
                                                    NSWorkspace.didUnmountNotification] {
            _ = NSWorkspace.shared.notificationCenter.addObserver(forName: notificationName,
                                                                  object: NSWorkspace.shared,
                                                                  queue: .main) { _ in self.updateVolumesTable() }
        }

        /* Populate volumes table */
        updateVolumesTable()
    }

    private func updateVolumesTable() {
        /* Enumerate mounted volumes */
        let keys: [URLResourceKey] = [.volumeNameKey] /* Properties to prefetch */
        let options: FileManager.VolumeEnumerationOptions = [.skipHiddenVolumes]
        let urls: [URL]
        urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: options) ?? []

        /* Find all volumes mounted */
        mountedVolumes.removeAll()
        for url: URL in urls {
            guard let values: URLResourceValues = try? url.resourceValues(forKeys: [.volumeNameKey]) else {
                continue
            }
            guard let volumeName: String = values.volumeName else {
                continue
            }
            /* Filter-out unwanted volumes */
            if url.lastPathComponent == mountPointName {
                mountedVolumes.append(Volume(name: volumeName, mountPoint: url.path))
            }
        }

        /* Update view */
        volumesTableView.reloadData()
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return mountedVolumes.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let ident: NSUserInterfaceItemIdentifier = tableColumn?.identifier else {
            return nil
        }
        // swiftlint:disable:next force_cast
        let cell: NSTableCellView = tableView.makeView(withIdentifier: ident, owner: self) as! NSTableCellView
        cell.textField?.stringValue = mountedVolumes[row].name
        return cell
    }

    private func unmountVolume(volume: Volume) {
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: URL(fileURLWithPath: volume.mountPoint))
        } catch {
            let alert: NSAlert = NSAlert()
            alert.messageText = "Error unmounting volume \(volume.name)"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    /** Handles "Unmount" button clicks */
    @IBAction private func unmountButtonClicked(_ sender: NSButton) {
        let index: Int = volumesTableView.selectedRow
        guard index != -1 else {
            return
        }
        unmountVolume(volume: mountedVolumes[index])
    }

    /** Handles "Unmount all" button clicks */
    @IBAction private func unmountAllButtonClicked(_ sender: NSButton) {
        for volume: Volume in mountedVolumes {
            unmountVolume(volume: volume)
        }
    }

    /** Handles "Open" button clicks */
    @IBAction private func openButtonClicked(_ sender: NSButton) {
        let index: Int = volumesTableView.selectedRow
        let volume: Volume = mountedVolumes[index]
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: volume.mountPoint)
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
            let mountPointUrl: URL = tempUrl.appendingPathComponent(uuid).appendingPathComponent(mountPointName)

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
