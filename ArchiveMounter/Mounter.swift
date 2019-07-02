import Foundation

/** Mounter */
public enum Mounter {
    /** Mounts archive file */
    public static func mount(
        archivePath: URL,
        mountPoint: URL,
        encoding: String?,
        volumeName: String,
        readOnly: Bool
        ) throws {
        let helper: MountHelper = try MountHelperFactory.getHelper(fileType: archivePath.pathExtension)
        var options: [String] = ["volname=\(sanitise(volumeName))", "fsname=\(sanitise(archivePath.path))"]
        if let encoding: String = encoding {
            options.append(contentsOf: ["modules=iconv", "from_code=\(sanitise(encoding))", "to_code=utf-8"])
        }
        if readOnly {
            options.append("rdonly")
        }

        do {
            try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw RuntimeError(
                message: "Failed to create mount point",
                description: error.localizedDescription
            )
        }

        try helper.mount(archivePath: archivePath.path, mountPoint: mountPoint.path, mountOptions: options)
    }

    /* Looks like FUSE is unable to handle comma in options */
    private static func sanitise(_ option: String) -> String {
        return option.replacingOccurrences(of: ",", with: "_")
    }
}
