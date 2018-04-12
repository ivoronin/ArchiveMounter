import Foundation

/**
 Abstract Mounter Class
  - Attention: This class should not be used directly
 */
public class Mounter {
    /** Name of mount helper utility bundled with app in Contents/Executables */
    internal var helperName: String = ""
    /** Absolute path to mount helper utility */
    internal var helperPath: String {
        get { // swiftlint:disable:this implicit_getter
            return Bundle.main.bundleURL /* URL("/Applications/Archive Mounter.app") */
                .appendingPathComponent("Contents")
                .appendingPathComponent("Executables")
                .appendingPathComponent(helperName).path
        }
    }
    /** Additional mount options */
    internal var additionalOptions: [String] = []

    required public init() {
    }

    /**
     Mounts specified archive file using mount helper utility
     - Parameters:
        - fileName: Path to archive file
        - mountPoint: Path to mount point directory
        - volumeName: Volume name to show in Finder
     */
    public func mount(fileName: String, mountPoint: String, volumeName: String) throws {
        var options: [String] = ["local", "ro", "volname=\(volumeName)"]
        if !additionalOptions.isEmpty {
            options.append(contentsOf: additionalOptions)
        }
        let arguments: [String] = ["-o", options.joined(separator: ","), fileName, mountPoint]

        let command: CommandRunner = CommandRunner(path: helperPath, arguments: arguments)
        try command.execute()
        if command.status != 0 {
            throw RuntimeError(message: "Unable to mount archive", description: command.error ?? "")
        }
    }
}

public class MounterFactory {
    /** File extensions to mounter type mapping */
    private static let mounters: [String: Mounter.Type]  = [
        "zip": ZipMounter.self,
        "rar": RarMounter.self
    ]
    /** Supported archive file extensions */
    public static let allowedFileTypes: [String] = Array(Set(mounters.keys))

    /**
     Returns Mounter instance
     - Parameters:
        - fileExt: Acrhive file extension
     - Returns: Mounter instance
     - Throws: `RuntimeError` if no mounter is found for `fileExt`
     */
    public static func getMounter(fileExt: String) throws -> Mounter {
        guard let mounter: Mounter.Type = MounterFactory.mounters[fileExt.lowercased()] else {
            throw RuntimeError(message: "Unsupported file type",
                               description: "Cannot open \"\(fileExt)\" archives")
        }
        return mounter.init()
    }
}

/** ZIP archive mounter class */
public class ZipMounter: Mounter {
    required public init() {
        super.init()
        self.helperName = "fuse-zip"
        self.additionalOptions = ["modules=iconv", "from_code=cp866", "to_code=utf-8"]
    }
}

/** RAR archive mounter class */
public class RarMounter: Mounter {
    required public init() {
        super.init()
        self.helperName = "rar2fs"
    }
}
