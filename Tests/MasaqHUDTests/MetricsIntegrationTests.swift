import XCTest
@testable import MasaqHUDCore

/// Integration tests for metrics collection.
/// These tests verify that metrics return valid data from the actual system.
/// Some values may vary based on the machine running the tests.
final class MetricsIntegrationTests: XCTestCase {

    // MARK: - CPU Metrics Tests

    func testCPUMetrics_getUsage_returnsValidRange() {
        let cpu = CPUMetrics()

        // First call initializes baseline
        _ = cpu.getUsage()

        // Small delay to allow CPU activity
        usleep(100_000)  // 100ms

        // Second call returns actual usage
        let usage = cpu.getUsage()

        XCTAssertGreaterThanOrEqual(usage, 0, "CPU usage should not be negative")
        XCTAssertLessThanOrEqual(usage, 100, "CPU usage should not exceed 100%")
    }

    func testCPUMetrics_getCoreCount_returnsPositive() {
        let cpu = CPUMetrics()
        let coreCount = cpu.getCoreCount()

        XCTAssertGreaterThan(coreCount, 0, "Should have at least one CPU core")
    }

    func testCPUMetrics_getPerCoreUsage_returnsAllCores() {
        let cpu = CPUMetrics()

        // First call initializes baseline
        _ = cpu.getPerCoreUsage()

        usleep(100_000)  // 100ms

        let cores = cpu.getPerCoreUsage()

        XCTAssertGreaterThan(cores.count, 0, "Should have at least one core")

        for core in cores {
            XCTAssertGreaterThanOrEqual(core.usage, 0, "Core \(core.core) usage should not be negative")
            XCTAssertLessThanOrEqual(core.usage, 100, "Core \(core.core) usage should not exceed 100%")
            XCTAssertGreaterThanOrEqual(core.core, 0, "Core index should not be negative")
        }
    }

    func testCPUMetrics_getLoadAverages_returnsValidValues() {
        let cpu = CPUMetrics()
        let loadAvg = cpu.getLoadAverages()

        // Load averages can be any non-negative number (can exceed number of cores under load)
        XCTAssertGreaterThanOrEqual(loadAvg.load1, 0, "1-minute load should not be negative")
        XCTAssertGreaterThanOrEqual(loadAvg.load5, 0, "5-minute load should not be negative")
        XCTAssertGreaterThanOrEqual(loadAvg.load15, 0, "15-minute load should not be negative")
    }

    func testCPUMetrics_getFrequencyMHz_returnsNonNegative() {
        let cpu = CPUMetrics()
        let freq = cpu.getFrequencyMHz()

        // Frequency may be 0 on some systems (especially Apple Silicon)
        XCTAssertGreaterThanOrEqual(freq, 0, "CPU frequency should not be negative")
    }

    // MARK: - Memory Metrics Tests

    func testMemoryMetrics_getUsage_returnsPositiveValues() {
        let memory = MemoryMetrics()
        let usage = memory.getUsage()

        XCTAssertGreaterThan(usage.total, 0, "Total memory should be positive")
        XCTAssertGreaterThanOrEqual(usage.used, 0, "Used memory should not be negative")
        XCTAssertLessThanOrEqual(usage.used, usage.total, "Used memory should not exceed total")
        XCTAssertGreaterThanOrEqual(usage.percentage, 0, "Memory percentage should not be negative")
        XCTAssertLessThanOrEqual(usage.percentage, 100, "Memory percentage should not exceed 100%")
    }

    func testMemoryMetrics_getUsage_swapValues() {
        let memory = MemoryMetrics()
        let usage = memory.getUsage()

        // Swap may or may not be configured
        XCTAssertGreaterThanOrEqual(usage.swapTotal, 0, "Swap total should not be negative")
        XCTAssertGreaterThanOrEqual(usage.swapUsed, 0, "Swap used should not be negative")

        if usage.swapTotal > 0 {
            XCTAssertLessThanOrEqual(usage.swapUsed, usage.swapTotal, "Swap used should not exceed total")
            XCTAssertGreaterThanOrEqual(usage.swapPercentage, 0, "Swap percentage should not be negative")
            XCTAssertLessThanOrEqual(usage.swapPercentage, 100, "Swap percentage should not exceed 100%")
        }
    }

    // MARK: - Disk Metrics Tests

    func testDiskMetrics_getUsage_returnsValidUsage() {
        let disk = DiskMetrics()
        let usage = disk.getUsage()

        XCTAssertGreaterThan(usage.totalGB, 0, "Total disk should be positive")
        XCTAssertGreaterThanOrEqual(usage.usedGB, 0, "Used disk should not be negative")
        XCTAssertGreaterThanOrEqual(usage.freeGB, 0, "Free disk should not be negative")
        XCTAssertGreaterThanOrEqual(usage.percentage, 0, "Disk percentage should not be negative")
        XCTAssertLessThanOrEqual(usage.percentage, 100, "Disk percentage should not exceed 100%")

        // Used + free should approximately equal total (may not be exact due to reserved space)
        let calculatedTotal = usage.usedGB + usage.freeGB
        XCTAssertGreaterThan(calculatedTotal, 0, "Calculated total should be positive")
    }

    func testDiskMetrics_getUsage_hasFilesystemType() {
        let disk = DiskMetrics()
        let usage = disk.getUsage()

        XCTAssertFalse(usage.fsType.isEmpty, "Filesystem type should not be empty")
        XCTAssertNotEqual(usage.fsType, "N/A", "Filesystem type should be available")
    }

    func testDiskMetrics_getUsage_ioRatesNonNegative() {
        let disk = DiskMetrics()

        // First call initializes baseline
        _ = disk.getUsage()

        usleep(100_000)  // 100ms

        let usage = disk.getUsage()

        XCTAssertGreaterThanOrEqual(usage.readBytesPerSec, 0, "Read rate should not be negative")
        XCTAssertGreaterThanOrEqual(usage.writeBytesPerSec, 0, "Write rate should not be negative")
    }

    // MARK: - Network Metrics Tests

    func testNetworkMetrics_getUsage_returnsValidIP() {
        let network = NetworkMetrics()
        let usage = network.getUsage()

        // Local IP should be present (may be "N/A" if no network interface)
        XCTAssertFalse(usage.localIP.isEmpty, "Local IP should not be empty")
    }

    func testNetworkMetrics_getUsage_bytesNonNegative() {
        let network = NetworkMetrics()
        let usage = network.getUsage()

        XCTAssertGreaterThanOrEqual(usage.bytesIn, 0, "Bytes in should not be negative")
        XCTAssertGreaterThanOrEqual(usage.bytesOut, 0, "Bytes out should not be negative")
    }

    func testNetworkMetrics_getUsage_ratesNonNegative() {
        let network = NetworkMetrics()

        // First call initializes baseline
        _ = network.getUsage()

        usleep(100_000)  // 100ms

        let usage = network.getUsage()

        XCTAssertGreaterThanOrEqual(usage.bytesInPerSec, 0, "Download rate should not be negative")
        XCTAssertGreaterThanOrEqual(usage.bytesOutPerSec, 0, "Upload rate should not be negative")
    }

    func testNetworkMetrics_getUsage_publicIPDisabledByDefault() {
        let network = NetworkMetrics()
        let usage = network.getUsage()

        XCTAssertEqual(usage.publicIP, "Disabled", "Public IP should be disabled by default")
    }

    func testNetworkMetrics_getWiFiInfo_returnsValidData() {
        let network = NetworkMetrics()
        let wifi = network.getWiFiInfo()

        // SSID may be "N/A" if not connected to WiFi
        XCTAssertFalse(wifi.ssid.isEmpty, "SSID should not be empty")

        // Signal strength should be in valid range
        XCTAssertGreaterThanOrEqual(wifi.signalStrength, 0, "Signal strength should not be negative")
        XCTAssertLessThanOrEqual(wifi.signalStrength, 100, "Signal strength should not exceed 100")
    }

    // MARK: - Process Metrics Tests

    func testProcessMetrics_getTopProcesses_returnsProcesses() {
        let process = ProcessMetrics()

        // First call initializes CPU time tracking
        _ = process.getTopProcesses()

        usleep(100_000)  // 100ms

        let (cpuProcs, memProcs) = process.getTopProcesses()

        // Should return some processes
        XCTAssertGreaterThan(cpuProcs.count, 0, "Should have at least one process by CPU")
        XCTAssertGreaterThan(memProcs.count, 0, "Should have at least one process by memory")

        // Process data should be valid
        for proc in cpuProcs {
            XCTAssertFalse(proc.name.isEmpty, "Process name should not be empty")
            XCTAssertGreaterThan(proc.pid, 0, "PID should be positive")
            XCTAssertGreaterThanOrEqual(proc.cpuPercent, 0, "CPU percent should not be negative")
        }

        for proc in memProcs {
            XCTAssertFalse(proc.name.isEmpty, "Process name should not be empty")
            XCTAssertGreaterThan(proc.pid, 0, "PID should be positive")
            XCTAssertGreaterThanOrEqual(proc.memoryMB, 0, "Memory MB should not be negative")
        }
    }

    func testProcessMetrics_getProcessCounts_returnsValidCounts() {
        let process = ProcessMetrics()
        let counts = process.getProcessCounts()

        XCTAssertGreaterThan(counts.total, 0, "Should have at least one process")
        XCTAssertGreaterThanOrEqual(counts.running, 0, "Running count should not be negative")
        XCTAssertLessThanOrEqual(counts.running, counts.total, "Running should not exceed total")
    }

    // MARK: - DateTime Metrics Tests

    func testDateTimeMetrics_getInfo_returnsFormattedStrings() {
        let datetime = DateTimeMetrics()
        let info = datetime.getInfo()

        XCTAssertFalse(info.time.isEmpty, "Time should not be empty")
        XCTAssertFalse(info.date.isEmpty, "Date should not be empty")
        XCTAssertFalse(info.weekday.isEmpty, "Weekday should not be empty")
        XCTAssertFalse(info.formatted.isEmpty, "Formatted datetime should not be empty")
    }

    // MARK: - Audio Metrics Tests

    func testAudioMetrics_getInfo_returnsValidVolume() {
        let audio = AudioMetrics()
        let info = audio.getInfo()

        // Volume should be 0-100
        XCTAssertGreaterThanOrEqual(info.volume, 0, "Volume should not be negative")
        XCTAssertLessThanOrEqual(info.volume, 100, "Volume should not exceed 100")

        // Device name may be "Unknown" if no audio device
        XCTAssertFalse(info.deviceName.isEmpty, "Device name should not be empty")
    }

    // MARK: - Bluetooth Metrics Tests

    func testBluetoothMetrics_getInfo_doesNotCrash() {
        let bluetooth = BluetoothMetrics()
        let info = bluetooth.getInfo()

        // Connected count should be non-negative
        XCTAssertGreaterThanOrEqual(info.connectedCount, 0, "Connected count should not be negative")

        // Devices array count should match connected count
        XCTAssertEqual(
            info.devices.count,
            info.connectedCount,
            "Devices array count should match connected count"
        )

        // Verify device data if any devices connected
        for device in info.devices {
            XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
            XCTAssertTrue(device.isConnected, "Listed devices should be connected")
        }
    }

    // MARK: - Battery Metrics Tests

    func testBatteryMetrics_getInfo_returnsValidData() {
        let battery = BatteryMetrics()
        let info = battery.getInfo()

        // On desktops without battery, isPresent will be false
        if info.isPresent {
            XCTAssertGreaterThanOrEqual(info.percent, 0, "Battery percent should not be negative")
            XCTAssertLessThanOrEqual(info.percent, 100, "Battery percent should not exceed 100")

            let validStatuses = ["Charging", "Discharging", "Full", "Not Charging", "N/A"]
            XCTAssertTrue(
                validStatuses.contains(info.status),
                "Status '\(info.status)' should be a valid status"
            )

            XCTAssertGreaterThanOrEqual(info.cycleCount, 0, "Cycle count should not be negative")
            XCTAssertGreaterThanOrEqual(info.health, 0, "Health should not be negative")
            XCTAssertLessThanOrEqual(info.health, 100, "Health should not exceed 100")
        } else {
            // No battery - verify sensible defaults
            XCTAssertEqual(info.percent, 0, "No battery should have 0 percent")
        }
    }
}
