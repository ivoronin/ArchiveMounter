import Foundation

/**
 Abstract MountHelper Class
  - Attention: This class should not be used directly
 */
public class MountHelper {
    /** Name of mount helper utility bundled with app in Contents/Executables */
    internal var helperName: String {
        preconditionFailure("Must be overridden")
    }
    /** Absolute path to mount helper utility */
    internal var helperPath: String {
        get { // swiftlint:disable:this implicit_getter
            return Bundle.main.bundleURL /* URL("/Applications/Archive Mounter.app") */
                .appendingPathComponent("Contents")
                .appendingPathComponent("Executables")
                .appendingPathComponent(helperName).path
        }
    }

    /** required initializer */
    required public init() {
    }

    /**
     Mounts specified archive file using mount helper utility
     - Parameters:
        - filePath: Path to archive file
        - mountPoint: Path to mount point directory
        - mountOptions: Mount options
     */
    public func mount(filePath: String, mountPoint: String, mountOptions: [String]) throws {
        let optionsString: String = mountOptions.joined(separator: ",")
        let arguments: [String] = ["-o", optionsString, filePath, mountPoint]

        let command: CommandRunner = CommandRunner(path: helperPath, arguments: arguments)
        try command.execute()
        if command.status != 0 {
            throw RuntimeError(message: "Unable to mount archive", description: command.error ?? "")
        }
    }
}

public class MountHelperFactory {
    /** File type to helper type mapping */
    private static let fileTypeHelpers: [String: MountHelper.Type]  = [
        "zip": ZipMountHelper.self,
        "rar": RarMountHelper.self
    ]
    /** Supported archive file types */
    public static let allowedFileTypes: [String] = Array(Set(fileTypeHelpers.keys))

    /**
     Returns MountHelper instance
     - Parameters:
        - fileType: Acrhive file extension
     - Returns: MountHelper instance
     - Throws: `RuntimeError` if no helper is found for `fileType`
     */
    public static func getHelper(fileType: String) throws -> MountHelper {
        guard let helper: MountHelper.Type = MountHelperFactory.fileTypeHelpers[fileType.lowercased()] else {
            throw RuntimeError(message: "Unsupported file type",
                               description: "Cannot open \"\(fileType)\" archives")
        }
        return helper.init()
    }
}

/** ZIP archive helper class */
public class ZipMountHelper: MountHelper {
    override internal var helperName: String {
        return "fuse-zip"
    }
}

/** RAR archive helper class */
public class RarMountHelper: MountHelper {
    override internal var helperName: String {
        return "rar2fs"
    }
}
