import XCTest
import AppKit
@testable import MasaqHUDCore

/// Regression tests for numeric config parsing.
///
/// JSValue.toDouble() returns NaN for missing or non-numeric JS properties.
/// A NaN fontSize stored in a widget config poisoned TextRenderer's font cache
/// (NaN never compares equal to itself, so every lookup missed and every draw
/// inserted a new entry), producing unbounded memory growth.
final class ConfigEngineParsingTests: XCTestCase {

    var engine: ConfigEngine!
    var configFileURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        engine = ConfigEngine()
        configFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("masaqhud-parsing-test-\(UUID().uuidString).js")
    }

    override func tearDownWithError() throws {
        if let configFileURL {
            try? FileManager.default.removeItem(at: configFileURL)
        }
        engine = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    private func loadConfig(script: String) throws -> HUDConfig {
        try script.write(to: configFileURL, atomically: true, encoding: .utf8)
        guard let config = engine.loadConfig(from: configFileURL.path) else {
            throw XCTSkip("Config failed to load: \(script)")
        }
        return config
    }

    private func firstTextWidget(in config: HUDConfig) -> TextWidgetConfig? {
        for widget in config.widgets {
            if case .text(let textConfig) = widget {
                return textConfig
            }
        }
        return nil
    }

    private func firstBarWidget(in config: HUDConfig) -> BarWidgetConfig? {
        for widget in config.widgets {
            if case .bar(let barConfig) = widget {
                return barConfig
            }
        }
        return nil
    }

    // MARK: - fontSize Parsing (memory leak regression)

    func testTextWidgetWithoutFontSize_parsesAsNil() throws {
        let config = try loadConfig(script: """
            masaqhud.widget({ type: "text", text: "hello" });
        """)

        let widget = try XCTUnwrap(firstTextWidget(in: config))
        XCTAssertNil(widget.fontSize, "Missing fontSize must parse as nil, not NaN")
    }

    func testTextWidgetWithNaNFontSize_parsesAsNil() throws {
        let config = try loadConfig(script: """
            masaqhud.widget({ type: "text", text: "hello", fontSize: 0 / 0 });
        """)

        let widget = try XCTUnwrap(firstTextWidget(in: config))
        XCTAssertNil(widget.fontSize, "NaN fontSize must parse as nil")
    }

    func testTextWidgetWithInfiniteFontSize_parsesAsNil() throws {
        let config = try loadConfig(script: """
            masaqhud.widget({ type: "text", text: "hello", fontSize: Infinity });
        """)

        let widget = try XCTUnwrap(firstTextWidget(in: config))
        XCTAssertNil(widget.fontSize, "Infinite fontSize must parse as nil")
    }

    func testTextWidgetWithExplicitFontSize_isPreserved() throws {
        let config = try loadConfig(script: """
            masaqhud.widget({ type: "text", text: "hello", fontSize: 14 });
        """)

        let widget = try XCTUnwrap(firstTextWidget(in: config))
        XCTAssertEqual(widget.fontSize, 14)
    }

    // MARK: - Default Fallbacks for Missing Numeric Properties

    func testBarWidgetWithoutDimensions_usesDocumentedDefaults() throws {
        let config = try loadConfig(script: """
            masaqhud.widget({ type: "bar", source: "cpu.usage" });
        """)

        let widget = try XCTUnwrap(firstBarWidget(in: config))
        XCTAssertEqual(widget.width, 100)
        XCTAssertEqual(widget.height, 10)
    }

    func testTextWidgetWithoutPosition_defaultsToZero() throws {
        let config = try loadConfig(script: """
            masaqhud.widget({ type: "text", text: "hello", position: { x: 30 } });
        """)

        let widget = try XCTUnwrap(firstTextWidget(in: config))
        XCTAssertEqual(widget.position.x, 30)
        XCTAssertEqual(widget.position.y, 0, "Missing coordinate must default to 0, not NaN")
    }

    func testGlobalConfigWithNaNValues_keepsDefaults() throws {
        let config = try loadConfig(script: """
            masaqhud.config({ fontSize: 0 / 0, updateInterval: 0 / 0 });
        """)

        XCTAssertEqual(config.fontSize, 12, "NaN global fontSize must keep the default")
        XCTAssertEqual(config.updateInterval, 1.0, "NaN updateInterval must keep the default")
    }

    // MARK: - Font Cache Bounds

    func testFontCache_doesNotGrowWhenDrawingWithNaNSize() throws {
        let renderer = TextRenderer()
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 10,
            height: 10,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))

        for _ in 0..<10 {
            renderer.drawText(
                context: context,
                text: "hello",
                x: 0,
                y: 0,
                fontSize: .nan,
                color: .white
            )
        }

        XCTAssertEqual(
            renderer.fontCacheEntryCount, 1,
            "Repeated draws with a non-finite size must reuse a single cache entry"
        )
    }

    // MARK: - Validator Rejection of Non-Finite Values

    func testValidator_rejectsNonFiniteValues() {
        var config = HUDConfig()
        config.fontSize = .nan
        config.updateInterval = .infinity
        config.widgets = [
            .text(TextWidgetConfig(
                text: "hello",
                position: .zero,
                color: nil,
                fontSize: .nan,
                fontName: nil,
                weight: nil,
                italic: false,
                opacity: nil,
                shadow: nil,
                alignment: nil,
                maxWidth: nil,
                condition: nil
            ))
        ]

        let errors = ConfigValidator().validate(config)
        let errorPaths = errors.filter { $0.severity == .error }.map { $0.path }

        XCTAssertTrue(errorPaths.contains("fontSize"), "NaN global fontSize must be an error")
        XCTAssertTrue(errorPaths.contains("updateInterval"), "Non-finite updateInterval must be an error")
        XCTAssertTrue(errorPaths.contains("widgets[0].fontSize"), "NaN widget fontSize must be an error")
    }
}
