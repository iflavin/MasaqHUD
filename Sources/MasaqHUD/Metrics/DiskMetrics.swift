import Foundation
import IOKit

struct DiskUsage {
    let totalGB: Double
    let usedGB: Double
    let freeGB: Double
    let percentage: Double
    let readBytesPerSec: Double
    let writeBytesPerSec: Double
    let fsType: String
}

final class DiskMetrics {
    private var previousStats: (read: UInt64, write: UInt64, timestamp: TimeInterval)?

    func getUsage(path: String = "/") -> DiskUsage {
        var stat = statfs()

        guard statfs(path, &stat) == 0 else {
            return DiskUsage(totalGB: 0, usedGB: 0, freeGB: 0, percentage: 0, readBytesPerSec: 0, writeBytesPerSec: 0, fsType: "N/A")
        }

        // Extract filesystem type name
        let fsType = withUnsafePointer(to: &stat.f_fstypename) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }

        let blockSize = UInt64(stat.f_bsize)
        let totalBlocks = UInt64(stat.f_blocks)
        let freeBlocks = UInt64(stat.f_bfree)
        let availableBlocks = UInt64(stat.f_bavail)

        let totalBytes = totalBlocks * blockSize
        let freeBytes = availableBlocks * blockSize
        let usedBytes = totalBytes - (freeBlocks * blockSize)

        let totalGB = Double(totalBytes) / (1024 * 1024 * 1024)
        let freeGB = Double(freeBytes) / (1024 * 1024 * 1024)
        let usedGB = Double(usedBytes) / (1024 * 1024 * 1024)

        let percentage = totalGB > 0 ? (usedGB / totalGB) * 100.0 : 0

        let (readPerSec, writePerSec) = getDiskIOStats()

        return DiskUsage(
            totalGB: totalGB,
            usedGB: usedGB,
            freeGB: freeGB,
            percentage: percentage,
            readBytesPerSec: readPerSec,
            writeBytesPerSec: writePerSec,
            fsType: fsType
        )
    }

    private func getDiskIOStats() -> (read: Double, write: Double) {
        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        let matchingDict = IOServiceMatching("IOBlockStorageDriver")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
            return (0, 0)
        }

        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = props?.takeRetainedValue() as? [String: Any],
                  let stats = dict["Statistics"] as? [String: Any] else {
                continue
            }

            if let bytesRead = stats["Bytes (Read)"] as? UInt64 {
                totalRead += bytesRead
            }
            if let bytesWritten = stats["Bytes (Write)"] as? UInt64 {
                totalWrite += bytesWritten
            }
        }

        let currentTime = Date().timeIntervalSince1970
        var readPerSec: Double = 0
        var writePerSec: Double = 0

        if let previous = previousStats {
            let timeDelta = currentTime - previous.timestamp
            if timeDelta > 0 {
                let readDelta = totalRead > previous.read ? totalRead - previous.read : 0
                let writeDelta = totalWrite > previous.write ? totalWrite - previous.write : 0
                readPerSec = Double(readDelta) / timeDelta
                writePerSec = Double(writeDelta) / timeDelta
            }
        }

        previousStats = (read: totalRead, write: totalWrite, timestamp: currentTime)

        return (read: readPerSec, write: writePerSec)
    }
}
