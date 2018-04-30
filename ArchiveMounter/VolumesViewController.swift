import Cocoa

public class VolumesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet private var volumesTableView: NSTableView!

    /** Mounted volume list */
    private var mountedVolumes: [Volume] = []

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
            guard url.lastPathComponent == "_ArchiveMounter" else { // FIXME
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
            mountedVolumes.append(Volume(name: volumeName, mountPoint: url.path, deviceName: deviceName))
        }

        /* Update view */
        volumesTableView.reloadData()
    }

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

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return mountedVolumes.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let ident: NSUserInterfaceItemIdentifier = tableColumn?.identifier else {
            return nil
        }
        let volume: Volume = mountedVolumes[row]
        // swiftlint:disable:next force_cast
        let cell: NSTableCellView = tableView.makeView(withIdentifier: ident, owner: self) as! NSTableCellView
        switch ident.rawValue {
        case "volumeName":
            cell.textField?.stringValue = volume.name
        case "deviceName":
            cell.textField?.stringValue = volume.deviceName
        default:
            break
        }

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
        guard index != -1 else {
            return
        }
        let volume: Volume = mountedVolumes[index]
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: volume.mountPoint)
    }

}
