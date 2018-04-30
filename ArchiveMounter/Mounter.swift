import Foundation

/** Mounter */
public class Mounter {
    /** Mounts archive file */
    static public func mount(archivePath: URL,
                             mountPoint: URL,
                             encoding: String?,
                             volumeName: String,
                             readOnly: Bool) throws {
        let helper: MountHelper = try MountHelperFactory.getHelper(fileType: archivePath.pathExtension)
        var options: [String] = ["volname=\(volumeName)", "fsname=\(archivePath.path)"]
        if let encoding: String = encoding {
            options.append(contentsOf: ["modules=iconv", "from_code=\(encoding)", "to_code=utf-8"])
        }
        if readOnly {
            options.append("rdonly")
        }

        do {
            try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw RuntimeError(message: "Failed to create mount point",
                               description: error.localizedDescription)
        }

        try helper.mount(archivePath: archivePath.path, mountPoint: mountPoint.path, mountOptions: options)
    }
}
