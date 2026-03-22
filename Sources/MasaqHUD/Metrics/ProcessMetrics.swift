import Foundation
import Darwin

struct ProcessInfoData {
    let pid: Int32
    let name: String
    let cpuPercent: Double
    let memoryMB: Double
}

struct ProcessCounts {
    let total: Int
    let running: Int
}

final class ProcessMetrics {
    private var previousCPUTimes: [Int32: (user: UInt64, system: UInt64, timestamp: TimeInterval)] = [:]

    /// Combined method that fetches top processes and process counts from a single sysctl call.
    func getTopProcessesAndCounts(
        byCPU cpuCount: Int = 5,
        byMemory memCount: Int = 5
    ) -> (cpu: [ProcessInfoData], memory: [ProcessInfoData], counts: ProcessCounts) {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: Int = 0

        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else {
            return ([], [], ProcessCounts(total: 0, running: 0))
        }

        let count = size / MemoryLayout<kinfo_proc>.stride
        var procList = [kinfo_proc](repeating: kinfo_proc(), count: count)

        guard sysctl(&mib, 4, &procList, &size, nil, 0) == 0 else {
            return ([], [], ProcessCounts(total: 0, running: 0))
        }

        let actualCount = size / MemoryLayout<kinfo_proc>.stride
        let currentTime = Date().timeIntervalSince1970

        var processes: [ProcessInfoData] = []
        var runningCount = 0

        for i in 0..<actualCount {
            let proc = procList[i]
            let pid = proc.kp_proc.p_pid

            // Count running processes (SRUN = 2)
            if proc.kp_proc.p_stat == 2 {
                runningCount += 1
            }

            if pid <= 0 { continue }

            var nameBuffer = [CChar](repeating: 0, count: 256)
            let nameLen = proc_name(pid, &nameBuffer, 256)
            var name = nameLen > 0 ? String(cString: nameBuffer) : ""

            if name.isEmpty {
                name = withUnsafePointer(to: proc.kp_proc.p_comm) { ptr in
                    ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) { cstr in
                        String(cString: cstr)
                    }
                }
            }

            if name.isEmpty || name == "kernel_task" { continue }

            let hasLetter = name.unicodeScalars.contains { CharacterSet.letters.contains($0) }
            if !hasLetter { continue }

            var taskInfo = proc_taskinfo()
            let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)

            var memoryMB = 0.0
            var cpuPercent = 0.0

            if result == taskInfoSize {
                memoryMB = Double(taskInfo.pti_resident_size) / (1024 * 1024)

                let userTime = taskInfo.pti_total_user
                let systemTime = taskInfo.pti_total_system

                if let previous = previousCPUTimes[pid] {
                    let timeDelta = currentTime - previous.timestamp
                    if timeDelta > 0 {
                        let userDelta = userTime - previous.user
                        let systemDelta = systemTime - previous.system
                        let totalCPUTime = Double(userDelta + systemDelta) / 1_000_000_000
                        cpuPercent = (totalCPUTime / timeDelta) * 100
                    }
                }

                previousCPUTimes[pid] = (user: userTime, system: systemTime, timestamp: currentTime)
            }

            processes.append(ProcessInfoData(pid: pid, name: name, cpuPercent: cpuPercent, memoryMB: memoryMB))
        }

        // Clean up stale entries
        let currentPIDs = Set(processes.map { $0.pid })
        previousCPUTimes = previousCPUTimes.filter { currentPIDs.contains($0.key) }

        let topCPU = processes
            .sorted { $0.cpuPercent > $1.cpuPercent }
            .prefix(cpuCount)

        let topMemory = processes
            .sorted { $0.memoryMB > $1.memoryMB }
            .prefix(memCount)

        let counts = ProcessCounts(total: actualCount, running: runningCount)
        return (cpu: Array(topCPU), memory: Array(topMemory), counts: counts)
    }

    /// Convenience wrapper for backward compatibility (used by warm-up loop)
    func getTopProcesses(byCPU cpuCount: Int = 5, byMemory memCount: Int = 5) -> (cpu: [ProcessInfoData], memory: [ProcessInfoData]) {
        let result = getTopProcessesAndCounts(byCPU: cpuCount, byMemory: memCount)
        return (cpu: result.cpu, memory: result.memory)
    }

    func getProcessCounts() -> ProcessCounts {
        let result = getTopProcessesAndCounts(byCPU: 0, byMemory: 0)
        return result.counts
    }
}
