import XCTest
@testable import MasaqHUDCore

final class VariableExpansionTests: XCTestCase {

    var engine: ConfigEngine!

    override func setUp() {
        super.setUp()
        engine = ConfigEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createMockMetrics(
        cpuUsage: Double = 0,
        memoryPercent: Double = 0,
        batteryStatus: String = "N/A",
        batteryPercent: Int = 0
    ) -> DisplayMetrics {
        var metrics = DisplayMetrics()
        metrics.cpuUsage = cpuUsage
        metrics.memoryUsage = MemoryUsage(
            used: memoryPercent * 0.16,  // Assuming 16GB total
            total: 16.0,
            percentage: memoryPercent,
            swapUsed: 0,
            swapTotal: 2,
            swapPercentage: 0
        )
        metrics.batteryInfo = BatteryInfo(
            percent: batteryPercent,
            status: batteryStatus,
            timeRemaining: "N/A",
            powerDraw: 0,
            isPresent: true,
            cycleCount: 100,
            health: 95
        )
        return metrics
    }

    // MARK: - Variable Expansion Tests

    func testExpandVariables_noVariables() {
        let metrics = createMockMetrics()

        XCTAssertEqual(
            engine.expandVariables(in: "Hello World", metrics: metrics),
            "Hello World"
        )
        XCTAssertEqual(
            engine.expandVariables(in: "", metrics: metrics),
            ""
        )
    }

    func testExpandVariables_singleVariable() {
        let metrics = createMockMetrics(cpuUsage: 45.5)

        let result = engine.expandVariables(in: "CPU: ${cpu.usage}%", metrics: metrics)
        XCTAssertEqual(result, "CPU: 45.5%")
    }

    func testExpandVariables_cpuUsage() {
        let metrics = createMockMetrics(cpuUsage: 75.3)

        let result = engine.expandVariables(in: "${cpu.usage}", metrics: metrics)
        XCTAssertEqual(result, "75.3")
    }

    func testExpandVariables_memoryPercent() {
        let metrics = createMockMetrics(memoryPercent: 50.0)

        let result = engine.expandVariables(in: "${memory.percent}", metrics: metrics)
        XCTAssertEqual(result, "50")
    }

    func testExpandVariables_multipleVariables() {
        let metrics = createMockMetrics(cpuUsage: 50.0, memoryPercent: 75.0)

        let result = engine.expandVariables(in: "CPU ${cpu.usage}% | RAM ${memory.percent}%", metrics: metrics)
        XCTAssertTrue(result.contains("50.0"), "Should contain CPU usage")
        XCTAssertTrue(result.contains("75"), "Should contain memory percent")
    }

    func testExpandVariables_unknownVariable() {
        let metrics = createMockMetrics()

        let result = engine.expandVariables(in: "${nonexistent.var}", metrics: metrics)
        XCTAssertEqual(result, "${nonexistent.var}", "Unknown variables should be preserved")
    }

    func testExpandVariables_mixedKnownAndUnknown() {
        let metrics = createMockMetrics(cpuUsage: 25.0)

        let result = engine.expandVariables(in: "CPU: ${cpu.usage}% | ${unknown.var}", metrics: metrics)
        XCTAssertTrue(result.contains("25.0"), "Known variable should be expanded")
        XCTAssertTrue(result.contains("${unknown.var}"), "Unknown variable should be preserved")
    }

    func testExpandVariables_batteryStatus() {
        let metrics = createMockMetrics(batteryStatus: "Charging", batteryPercent: 80)

        let result = engine.expandVariables(in: "${battery.status} ${battery.percent}%", metrics: metrics)
        XCTAssertTrue(result.contains("Charging"), "Battery status should be expanded")
        XCTAssertTrue(result.contains("80"), "Battery percent should be expanded")
    }

    func testExpandVariables_noSubstitutionNeeded() {
        let metrics = createMockMetrics()

        // Text without ${ should be returned as-is
        let result = engine.expandVariables(in: "No variables here", metrics: metrics)
        XCTAssertEqual(result, "No variables here")
    }

    // MARK: - Condition Evaluation Tests

    func testEvaluateCondition_nilCondition() {
        let metrics = createMockMetrics()

        XCTAssertTrue(
            engine.evaluateCondition(nil, metrics: metrics),
            "Nil condition should return true"
        )
    }

    func testEvaluateCondition_emptyCondition() {
        let metrics = createMockMetrics()

        XCTAssertTrue(
            engine.evaluateCondition("", metrics: metrics),
            "Empty condition should return true"
        )
    }

    func testEvaluateCondition_simpleGreaterThan_true() {
        let metrics = createMockMetrics(cpuUsage: 75.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage > 50", metrics: metrics),
            "75 > 50 should be true"
        )
    }

    func testEvaluateCondition_simpleGreaterThan_false() {
        let metrics = createMockMetrics(cpuUsage: 25.0)

        XCTAssertFalse(
            engine.evaluateCondition("cpu.usage > 50", metrics: metrics),
            "25 > 50 should be false"
        )
    }

    func testEvaluateCondition_simpleLessThan_true() {
        let metrics = createMockMetrics(cpuUsage: 25.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage < 50", metrics: metrics),
            "25 < 50 should be true"
        )
    }

    func testEvaluateCondition_simpleLessThan_false() {
        let metrics = createMockMetrics(cpuUsage: 75.0)

        XCTAssertFalse(
            engine.evaluateCondition("cpu.usage < 50", metrics: metrics),
            "75 < 50 should be false"
        )
    }

    func testEvaluateCondition_greaterThanOrEqual_boundary() {
        let metrics = createMockMetrics(cpuUsage: 75.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage >= 75", metrics: metrics),
            "75 >= 75 should be true"
        )
    }

    func testEvaluateCondition_lessThanOrEqual_boundary() {
        let metrics = createMockMetrics(cpuUsage: 75.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage <= 75", metrics: metrics),
            "75 <= 75 should be true"
        )
    }

    func testEvaluateCondition_compoundCondition_andTrue() {
        let metrics = createMockMetrics(cpuUsage: 75.0, memoryPercent: 40.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage > 50 && memory.percent < 80", metrics: metrics),
            "Both conditions true should return true"
        )
    }

    func testEvaluateCondition_compoundCondition_andFalse() {
        let metrics = createMockMetrics(cpuUsage: 75.0, memoryPercent: 90.0)

        XCTAssertFalse(
            engine.evaluateCondition("cpu.usage > 50 && memory.percent < 80", metrics: metrics),
            "One condition false should return false"
        )
    }

    func testEvaluateCondition_compoundCondition_orTrue() {
        let metrics = createMockMetrics(cpuUsage: 25.0, memoryPercent: 90.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage > 50 || memory.percent > 80", metrics: metrics),
            "One condition true should return true for OR"
        )
    }

    func testEvaluateCondition_compoundCondition_orFalse() {
        let metrics = createMockMetrics(cpuUsage: 25.0, memoryPercent: 40.0)

        XCTAssertFalse(
            engine.evaluateCondition("cpu.usage > 50 || memory.percent > 80", metrics: metrics),
            "Both conditions false should return false for OR"
        )
    }

    func testEvaluateCondition_stringComparison_equal() {
        let metrics = createMockMetrics(batteryStatus: "Charging")

        XCTAssertTrue(
            engine.evaluateCondition("battery.status === 'Charging'", metrics: metrics),
            "String equality should work"
        )
    }

    func testEvaluateCondition_stringComparison_notEqual() {
        let metrics = createMockMetrics(batteryStatus: "Charging")

        XCTAssertFalse(
            engine.evaluateCondition("battery.status === 'Discharging'", metrics: metrics),
            "String inequality should work"
        )
    }

    func testEvaluateCondition_stringNotEquals() {
        let metrics = createMockMetrics(batteryStatus: "Charging")

        XCTAssertTrue(
            engine.evaluateCondition("battery.status !== 'Discharging'", metrics: metrics),
            "String not-equals should work"
        )
    }

    func testEvaluateCondition_invalidSyntax_defaultsToTrue() {
        let metrics = createMockMetrics()

        // Invalid JavaScript syntax should default to true (render the widget)
        XCTAssertTrue(
            engine.evaluateCondition("invalid(((syntax", metrics: metrics),
            "Invalid syntax should default to true"
        )
    }

    func testEvaluateCondition_complexExpression() {
        let metrics = createMockMetrics(
            cpuUsage: 75.0,
            memoryPercent: 60.0,
            batteryStatus: "Discharging",
            batteryPercent: 15
        )

        // Low battery warning: battery < 20% AND discharging
        XCTAssertTrue(
            engine.evaluateCondition(
                "battery.percent < 20 && battery.status === 'Discharging'",
                metrics: metrics
            ),
            "Complex battery warning condition should work"
        )
    }

    func testEvaluateCondition_equality() {
        let metrics = createMockMetrics(cpuUsage: 50.0)

        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage === 50", metrics: metrics),
            "Strict equality should work"
        )
        XCTAssertTrue(
            engine.evaluateCondition("cpu.usage == 50", metrics: metrics),
            "Loose equality should work"
        )
    }
}
