import XCTest
@testable import MasaqHUDCore

final class FormattingTests: XCTestCase {

    var engine: ConfigEngine!

    override func setUp() {
        super.setUp()
        engine = ConfigEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - formatBytes Tests

    func testFormatBytes_zero() {
        XCTAssertEqual(engine.formatBytes(0), "0 B")
    }

    func testFormatBytes_bytes() {
        XCTAssertEqual(engine.formatBytes(500), "500 B")
        XCTAssertEqual(engine.formatBytes(1023), "1023 B")
    }

    func testFormatBytes_kilobytes() {
        XCTAssertEqual(engine.formatBytes(1024), "1.0 KB")
        XCTAssertEqual(engine.formatBytes(1536), "1.5 KB")
        XCTAssertEqual(engine.formatBytes(1024 * 100), "100.0 KB")
    }

    func testFormatBytes_megabytes() {
        XCTAssertEqual(engine.formatBytes(1024 * 1024), "1.0 MB")
        XCTAssertEqual(engine.formatBytes(1024 * 1024 * 500), "500.0 MB")
    }

    func testFormatBytes_gigabytes() {
        XCTAssertEqual(engine.formatBytes(Double(1024 * 1024 * 1024)), "1.00 GB")
        XCTAssertEqual(engine.formatBytes(Double(1024 * 1024 * 1024) * 2.5), "2.50 GB")
    }

    func testFormatBytes_boundaryValues() {
        // Just under KB boundary
        XCTAssertEqual(engine.formatBytes(1023), "1023 B")
        // Exactly KB boundary
        XCTAssertEqual(engine.formatBytes(1024), "1.0 KB")
        // Just under MB boundary
        XCTAssertEqual(engine.formatBytes(1024 * 1024 - 1), "1024.0 KB")
        // Exactly MB boundary
        XCTAssertEqual(engine.formatBytes(1024 * 1024), "1.0 MB")
    }

    // MARK: - formatUptime Tests

    func testFormatUptime_zero() {
        XCTAssertEqual(engine.formatUptime(0), "0m")
    }

    func testFormatUptime_minutesOnly() {
        XCTAssertEqual(engine.formatUptime(60), "1m")
        XCTAssertEqual(engine.formatUptime(300), "5m")
        XCTAssertEqual(engine.formatUptime(59), "0m")
    }

    func testFormatUptime_hoursAndMinutes() {
        XCTAssertEqual(engine.formatUptime(3600), "1h 0m")
        XCTAssertEqual(engine.formatUptime(3660), "1h 1m")
        XCTAssertEqual(engine.formatUptime(7200 + 1800), "2h 30m")
    }

    func testFormatUptime_daysHoursMinutes() {
        XCTAssertEqual(engine.formatUptime(86400), "1d 0h 0m")
        XCTAssertEqual(engine.formatUptime(86400 + 3600 + 60), "1d 1h 1m")
        XCTAssertEqual(engine.formatUptime(86400 * 7 + 3600 * 12), "7d 12h 0m")
    }

    func testFormatUptime_largeValues() {
        // 30 days
        XCTAssertEqual(engine.formatUptime(86400 * 30), "30d 0h 0m")
        // 100 days, 5 hours, 30 minutes
        XCTAssertEqual(engine.formatUptime(86400 * 100 + 3600 * 5 + 60 * 30), "100d 5h 30m")
    }
}
