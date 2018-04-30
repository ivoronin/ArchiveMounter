import Cocoa

public class VolumesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    /** Volume structure */
    public struct Volume {
        /** Volume name */
        public let name: String
        /** Mount point URL */
        public let mountPoint: URL
        /** Path to device (archive file) */
        public let deviceName: String
    }
    /** Mounted volume list */
    private var mountedVolumes: [Volume] = []

    @IBOutlet private var volumesTableView: NSTableView!

    override public func viewDidLoad() {
        super.viewDidLoad()
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

    /** Enumerates mounted volumes and populates view */
    private func updateVolumesTable() {
        /* Enumerate mounted volumes */
        let keys: [URLResourceKey] = [.volumeNameKey] /* Properties to prefetch */
        let options: FileManager.VolumeEnumerationOptions = [.skipHiddenVolumes]
        let urls: [URL]
        urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: options) ?? []

        /* Find all volumes mounted */
        mountedVolumes.removeAll()
        for url: URL in urls {
            /* Filter-out unwanted volumes */
            guard url.lastPathComponent == Constants.mountPointName else {
                continue
            }
            guard let values: URLResourceValues = try? url.resourceValues(forKeys: [.volumeNameKey]) else {
                NSLog("Error obtaining resource values for URL \"%@\"", url.path)
                continue
            }
            guard let volumeName: String = values.volumeName else {
                NSLog("\"volumeName\" is not present in resource values of URL \"%@\"", url.path)
                continue
            }
            guard let deviceName: String = getDeviceName(of: url.path) else {
                NSLog("Error obtaining device name of URL \"%@\"", url.path)
                continue
            }
            mountedVolumes.append(Volume(name: volumeName, mountPoint: url, deviceName: deviceName))
        }

        /* Update view */
        volumesTableView.reloadData()
    }

    /**
     Uses statfs() to get device name
     - Parameters:
        - path: Path to file or directory
     - Returns: Device name or nil
     */
    private func getDeviceName(of path: String) -> String? {
        /* Get "device" name */
        let buf: UnsafeMutablePointer<statfs> = UnsafeMutablePointer<statfs>.allocate(capacity: 1)
        defer { buf.deinitialize(count: 1) }
        if statfs(path.cString(using: .utf8), buf) != 0 {
            NSLog("statfs \"%@\" error, errno=%i", path, errno)
            return nil
        }
        return withUnsafePointer(to: &buf.pointee.f_mntfromname) { ptr -> String in
            return ptr.withMemoryRebound(to: Int8.self,
                                         capacity: Int(MNAMELEN)) { (str: UnsafePointer<Int8>) in
                                            return String(cString: str)
            }
        }
    }

    /** Returns number of volumes */
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return mountedVolumes.count
    }

    /** Returns table cell views */
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier: NSUserInterfaceItemIdentifier = tableColumn?.identifier else {
            return nil
        }
        let volume: Volume = mountedVolumes[row]
        // swiftlint:disable:next force_cast
        let cell: NSTableCellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        switch identifier.rawValue {
        case "volumeName":
            cell.textField?.stringValue = volume.name
        case "deviceName":
            cell.textField?.stringValue = volume.deviceName
        default:
            break
        }

        return cell
    }

    /** Unmounts single volume */
    private func unmountVolume(volume: Volume) {
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: volume.mountPoint)
        } catch {
            let alert: NSAlert = NSAlert()
            alert.messageText = "Error unmounting volume \(volume.name)"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func openVolume(volume: Volume) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: volume.mountPoint.path)
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
        guard index != -1 else {
            return
        }
        openVolume(volume: mountedVolumes[index])
    }

    @IBAction private func tableDoubleClicked(_ sender: NSTableView) {
        let index: Int = sender.clickedRow
        openVolume(volume: mountedVolumes[index])
    }

}
