import Foundation

/** Filesystem stats structure */
public struct FSStats {
    public let fsTypeName: String
    public let deviceName: String
}

/**
 Converts (Int8...) to String
 - Parameters:
    - field: (Int8...)
    - length: Tuple length
 - Returns: String
 */
private func bytesTupleToString<T, I: BinaryInteger>(field: T, length: I) -> String {
    var buf: T = field
    return withUnsafePointer(to: &buf) { pointer -> String in
        pointer.withMemoryRebound(
            to: CChar.self,
            capacity: Int(length)
        ) { (cString: UnsafePointer<CChar>) -> String in
            String(cString: cString)
        }
    }
}

/**
 Uses statfs() to get device name
 - Parameters:
    - path: Path to file or directory
 - Returns: FSStats structure or nil
 */
public func getFSStats(of path: String) -> FSStats? {
    /* Get "device" name */
    let buf: UnsafeMutablePointer<statfs> = UnsafeMutablePointer<statfs>.allocate(capacity: 1)
    defer { buf.deinitialize(count: 1) }
    if statfs(path.cString(using: .utf8), buf) != 0 {
        NSLog("statfs \"%@\" error, errno=%i", path, errno)
        return nil
    }
    return FSStats(
        fsTypeName: bytesTupleToString(field: buf.pointee.f_fstypename, length: MFSNAMELEN),
        deviceName: bytesTupleToString(field: buf.pointee.f_mntfromname, length: MNAMELEN)
    )
}
