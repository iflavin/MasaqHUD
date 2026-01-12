import Foundation

final class MetricsProvider {
    let cpuMetrics: CPUMetrics
    let memoryMetrics: MemoryMetrics
    let networkMetrics: NetworkMetrics
    let diskMetrics: DiskMetrics
    let dateTimeMetrics: DateTimeMetrics
    let gpuMetrics: GPUMetrics
    let smcReader: SMCReader
    let processMetrics: ProcessMetrics
    let batteryMetrics: BatteryMetrics
    let audioMetrics: AudioMetrics
    let bluetoothMetrics: BluetoothMetrics

    init() {
        cpuMetrics = CPUMetrics()
        memoryMetrics = MemoryMetrics()
        networkMetrics = NetworkMetrics()
        diskMetrics = DiskMetrics()
        dateTimeMetrics = DateTimeMetrics()
        smcReader = SMCReader()
        gpuMetrics = GPUMetrics(smcReader: smcReader)
        processMetrics = ProcessMetrics()
        batteryMetrics = BatteryMetrics()
        audioMetrics = AudioMetrics()
        bluetoothMetrics = BluetoothMetrics()
    }
}
