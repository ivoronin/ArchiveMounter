import Cocoa

/** Mount flags */
public struct MountFlags: OptionSet {
    public let rawValue: Int

    /** Mount read-only */
    static public let rdonly: MountFlags = MountFlags(rawValue: 1 << 0)
    /** Disallow ._ and .DS_Store files */
    static public let noappledouble: MountFlags = MountFlags(rawValue: 1 << 1)
    /** Make file system as local */
    static public let local: MountFlags = MountFlags(rawValue: 1 << 2)

    /** public initializer */
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/** Mounter */
public class Mounter {
    /** Path name to acrhive file */
    public let filePath: String
    /** Base name of archive file */
    public let fileName: String
    /** Extension of acrhive file */
    public let fileType: String
    /** Volume name to use */
    public var volumeName: String
    /** File name encoding */
    public var encoding: String?
    /** Mount flags, see `MountFlags` */
    public var mountFlags: MountFlags = [.rdonly]

    /**
     - Returns: Mounter instance or `nil` if FUSE for macOS installation is not detected
     - Parameters:
        - filePath: Path to archive file
     */
    public init(filePath: String) {
        self.filePath = filePath
        let fileURL: URL = URL(fileURLWithPath: filePath)
        self.fileName = fileURL.lastPathComponent
        self.fileType = fileURL.pathExtension
        self.volumeName = fileURL.deletingPathExtension().lastPathComponent
    }

    /** Mounts archive file */
    public func mount() throws {
        let mounter: MountHelper = try MountHelperFactory.getHelper(fileType: fileType)
        let mountPoint: String = try createTemporaryDirectory()

        var options: [String] = ["volname=\(volumeName)", "fsname=\(filePath)"]
        if let encoding: String = encoding {
            options.append(contentsOf: ["modules=iconv", "from_code=\(encoding)", "to_code=utf-8"])
        }
        if mountFlags.contains(.local) {
            options.append("local")
        }
        if mountFlags.contains(.rdonly) {
            options.append("ro")
        }
        if mountFlags.contains(.noappledouble) {
            options.append("noappledouble")
        }

        try mounter.mount(filePath: filePath, mountPoint: mountPoint, mountOptions: options)

        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: mountPoint)
    }

    /**
     Creates temporary subdirectory in `$TMPDIR`
     - Throws: `RuntimeError` on `createDirectory()` failure
     - Note: Generated UUID is used as a subdirectory name
     */
    private func createTemporaryDirectory() throws -> String {
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