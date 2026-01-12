import XCTest
@testable import MasaqHUDCore

final class ConfigValidatorTests: XCTestCase {

    var validator: ConfigValidator!

    override func setUp() {
        super.setUp()
        validator = ConfigValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - Color Validation Tests

    func testValidateColor_validHex6() {
        XCTAssertNil(validator.validateColor("#FFFFFF", at: "test"))
        XCTAssertNil(validator.validateColor("#000000", at: "test"))
        XCTAssertNil(validator.validateColor("#abcdef", at: "test"))
        XCTAssertNil(validator.validateColor("#ABCDEF", at: "test"))
        XCTAssertNil(validator.validateColor("#123456", at: "test"))
    }

    func testValidateColor_validHex3() {
        XCTAssertNil(validator.validateColor("#FFF", at: "test"))
        XCTAssertNil(validator.validateColor("#000", at: "test"))
        XCTAssertNil(validator.validateColor("#abc", at: "test"))
        XCTAssertNil(validator.validateColor("#ABC", at: "test"))
    }

    func testValidateColor_validHex8_withAlpha() {
        XCTAssertNil(validator.validateColor("#FFFFFFFF", at: "test"))
        XCTAssertNil(validator.validateColor("#00000080", at: "test"))
        XCTAssertNil(validator.validateColor("#12345678", at: "test"))
    }

    func testValidateColor_validHex4_withAlpha() {
        XCTAssertNil(validator.validateColor("#FFFF", at: "test"))
        XCTAssertNil(validator.validateColor("#0008", at: "test"))
        XCTAssertNil(validator.validateColor("#1234", at: "test"))
    }

    func testValidateColor_invalidHex_wrongLength() {
        XCTAssertNotNil(validator.validateColor("#FF", at: "test"))
        XCTAssertNotNil(validator.validateColor("#FFFFF", at: "test"))
        XCTAssertNotNil(validator.validateColor("#FFFFFFF", at: "test"))
        XCTAssertNotNil(validator.validateColor("#F", at: "test"))
    }

    func testValidateColor_invalidHex_badCharacters() {
        XCTAssertNotNil(validator.validateColor("#GGG", at: "test"))
        XCTAssertNotNil(validator.validateColor("#ZZZZZZ", at: "test"))
        XCTAssertNotNil(validator.validateColor("#12345G", at: "test"))
        XCTAssertNotNil(validator.validateColor("#GHIJKL", at: "test"))
    }

    func testValidateColor_errorPath() {
        let error = validator.validateColor("#GGG", at: "widgets[0].color")
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.path, "widgets[0].color")
    }

    func testValidateColor_errorSeverity() {
        let error = validator.validateColor("#GGG", at: "test")
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.severity, .error)
    }

    // MARK: - Full Config Validation Tests

    func testValidateConfig_validConfig() {
        var config = HUDConfig()
        config.updateInterval = 1.0
        config.fontSize = 12
        config.widgets = [.text(TextWidgetConfig(
            text: "Hello",
            position: .zero,
            color: "#FFFFFF",
            fontSize: nil,
            fontName: nil,
            weight: nil,
            italic: false,
            opacity: nil,
            shadow: nil,
            alignment: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        let criticalErrors = errors.filter { $0.severity == .error }
        XCTAssertTrue(criticalErrors.isEmpty, "Valid config should have no critical errors")
    }

    func testValidateConfig_invalidUpdateInterval_zero() {
        var config = HUDConfig()
        config.updateInterval = 0

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path == "updateInterval" && $0.severity == .error },
            "Zero update interval should produce error"
        )
    }

    func testValidateConfig_invalidUpdateInterval_negative() {
        var config = HUDConfig()
        config.updateInterval = -1

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path == "updateInterval" && $0.severity == .error },
            "Negative update interval should produce error"
        )
    }

    func testValidateConfig_warningForFastInterval() {
        var config = HUDConfig()
        config.updateInterval = 0.05

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path == "updateInterval" && $0.severity == .warning },
            "Very fast update interval should produce warning"
        )
    }

    func testValidateConfig_warningForSlowInterval() {
        var config = HUDConfig()
        config.updateInterval = 120

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path == "updateInterval" && $0.severity == .warning },
            "Very slow update interval should produce warning"
        )
    }

    func testValidateConfig_invalidFontSize() {
        var config = HUDConfig()
        config.fontSize = 0

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path == "fontSize" && $0.severity == .error },
            "Zero font size should produce error"
        )
    }

    // MARK: - Widget Validation Tests

    func testValidateConfig_barWidgetMissingSource() {
        var config = HUDConfig()
        config.widgets = [.bar(BarWidgetConfig(
            source: "",
            position: .zero,
            width: 100,
            height: 10,
            color: nil,
            backgroundColor: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("source") && $0.severity == .error },
            "Bar widget without source should produce error"
        )
    }

    func testValidateConfig_barWidgetInvalidDimensions() {
        var config = HUDConfig()
        config.widgets = [.bar(BarWidgetConfig(
            source: "cpu.usage",
            position: .zero,
            width: 0,
            height: -5,
            color: nil,
            backgroundColor: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("width") && $0.severity == .error },
            "Zero width should produce error"
        )
        XCTAssertTrue(
            errors.contains { $0.path.contains("height") && $0.severity == .error },
            "Negative height should produce error"
        )
    }

    func testValidateConfig_gaugeWidgetMissingSource() {
        var config = HUDConfig()
        config.widgets = [.gauge(GaugeWidgetConfig(
            source: "",
            position: .zero,
            radius: 40,
            thickness: 8,
            color: nil,
            backgroundColor: nil,
            startAngle: 135,
            endAngle: 405,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("source") && $0.severity == .error },
            "Gauge widget without source should produce error"
        )
    }

    func testValidateConfig_gaugeThicknessExceedsRadius() {
        var config = HUDConfig()
        config.widgets = [.gauge(GaugeWidgetConfig(
            source: "cpu.usage",
            position: .zero,
            radius: 30,
            thickness: 50,
            color: nil,
            backgroundColor: nil,
            startAngle: 135,
            endAngle: 405,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("thickness") && $0.severity == .warning },
            "Thickness exceeding radius should produce warning"
        )
    }

    func testValidateConfig_textWidgetInvalidAlignment() {
        var config = HUDConfig()
        config.widgets = [.text(TextWidgetConfig(
            text: "Test",
            position: .zero,
            color: nil,
            fontSize: nil,
            fontName: nil,
            weight: nil,
            italic: false,
            opacity: nil,
            shadow: nil,
            alignment: "middle",
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("align") },
            "Invalid alignment should produce error or warning"
        )
    }

    func testValidateConfig_textWidgetValidAlignments() {
        for alignment in ["left", "center", "right"] {
            var config = HUDConfig()
            config.widgets = [.text(TextWidgetConfig(
                text: "Test",
                position: .zero,
                color: nil,
                fontSize: nil,
                fontName: nil,
                weight: nil,
                italic: false,
                opacity: nil,
                shadow: nil,
                alignment: alignment,
                condition: nil
            ))]

            let errors = validator.validate(config)
            XCTAssertFalse(
                errors.contains { $0.path.contains("align") },
                "'\(alignment)' should be a valid alignment"
            )
        }
    }

    func testValidateConfig_textWidgetInvalidWeight() {
        var config = HUDConfig()
        config.widgets = [.text(TextWidgetConfig(
            text: "Test",
            position: .zero,
            color: nil,
            fontSize: nil,
            fontName: nil,
            weight: "extra-bold",
            italic: false,
            opacity: nil,
            shadow: nil,
            alignment: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("weight") },
            "Invalid weight should produce warning"
        )
    }

    func testValidateConfig_opacityOutOfRange_high() {
        var config = HUDConfig()
        config.widgets = [.text(TextWidgetConfig(
            text: "Test",
            position: .zero,
            color: nil,
            fontSize: nil,
            fontName: nil,
            weight: nil,
            italic: false,
            opacity: 1.5,
            shadow: nil,
            alignment: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("opacity") && $0.severity == .error },
            "Opacity > 1 should produce error"
        )
    }

    func testValidateConfig_opacityOutOfRange_negative() {
        var config = HUDConfig()
        config.widgets = [.text(TextWidgetConfig(
            text: "Test",
            position: .zero,
            color: nil,
            fontSize: nil,
            fontName: nil,
            weight: nil,
            italic: false,
            opacity: -0.5,
            shadow: nil,
            alignment: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("opacity") && $0.severity == .error },
            "Negative opacity should produce error"
        )
    }

    func testValidateConfig_opacityValidRange() {
        for opacity in [0.0, 0.5, 1.0] {
            var config = HUDConfig()
            config.widgets = [.text(TextWidgetConfig(
                text: "Test",
                position: .zero,
                color: nil,
                fontSize: nil,
                fontName: nil,
                weight: nil,
                italic: false,
                opacity: opacity,
                shadow: nil,
                alignment: nil,
                condition: nil
            ))]

            let errors = validator.validate(config)
            XCTAssertFalse(
                errors.contains { $0.path.contains("opacity") && $0.severity == .error },
                "Opacity \(opacity) should be valid"
            )
        }
    }

    func testValidateConfig_graphWidgetMissingSource() {
        var config = HUDConfig()
        config.widgets = [.graph(GraphWidgetConfig(
            source: "",
            position: .zero,
            size: CGSize(width: 200, height: 50),
            color: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("source") && $0.severity == .error },
            "Graph widget without source should produce error"
        )
    }

    func testValidateConfig_graphWidgetInvalidSize() {
        var config = HUDConfig()
        config.widgets = [.graph(GraphWidgetConfig(
            source: "cpu.usage",
            position: .zero,
            size: CGSize(width: 0, height: -10),
            color: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("size") && $0.severity == .error },
            "Invalid graph size should produce error"
        )
    }

    func testValidateConfig_hrWidgetInvalidWidth() {
        var config = HUDConfig()
        config.widgets = [.hr(HRWidgetConfig(
            position: .zero,
            width: 0,
            color: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("width") && $0.severity == .error },
            "HR widget with zero width should produce error"
        )
    }

    func testValidateConfig_imageWidgetMissingPath() {
        var config = HUDConfig()
        config.widgets = [.image(ImageWidgetConfig(
            path: "",
            position: .zero,
            size: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("path") && $0.severity == .error },
            "Image widget without path should produce error"
        )
    }

    func testValidateConfig_emptyTextWarning() {
        var config = HUDConfig()
        config.widgets = [.text(TextWidgetConfig(
            text: "",
            position: .zero,
            color: nil,
            fontSize: nil,
            fontName: nil,
            weight: nil,
            italic: false,
            opacity: nil,
            shadow: nil,
            alignment: nil,
            condition: nil
        ))]

        let errors = validator.validate(config)
        XCTAssertTrue(
            errors.contains { $0.path.contains("text") && $0.severity == .warning },
            "Empty text should produce warning"
        )
    }
}
