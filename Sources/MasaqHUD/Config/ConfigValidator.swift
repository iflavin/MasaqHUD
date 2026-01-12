import Foundation
import AppKit

struct ValidationError {
    let path: String
    let message: String
    let severity: Severity

    enum Severity {
        case error    // Config cannot be used
        case warning  // Config works but may behave unexpectedly
    }
}

struct ConfigValidator {
    private static let validWidgetTypes = ["text", "graph", "bar", "hr", "gauge", "image"]
    private static let validAlignments = ["left", "center", "right"]
    private static let validWeights = ["regular", "medium", "semibold", "bold", "heavy", "black", "light", "thin", "ultralight"]

    func validate(_ config: HUDConfig) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Validate global settings
        errors.append(contentsOf: validateGlobalSettings(config))

        // Validate each widget
        for (index, widget) in config.widgets.enumerated() {
            errors.append(contentsOf: validateWidget(widget, at: index))
        }

        return errors
    }

    private func validateGlobalSettings(_ config: HUDConfig) -> [ValidationError] {
        var errors: [ValidationError] = []

        // updateInterval
        if config.updateInterval <= 0 {
            errors.append(ValidationError(
                path: "updateInterval",
                message: "Must be greater than 0",
                severity: .error
            ))
        } else if config.updateInterval < 0.1 {
            errors.append(ValidationError(
                path: "updateInterval",
                message: "Very fast update interval (<0.1s) may cause high CPU usage",
                severity: .warning
            ))
        } else if config.updateInterval > 60 {
            errors.append(ValidationError(
                path: "updateInterval",
                message: "Update interval >60s may make metrics appear stale",
                severity: .warning
            ))
        }

        // fontSize
        if config.fontSize <= 0 {
            errors.append(ValidationError(
                path: "fontSize",
                message: "Must be greater than 0",
                severity: .error
            ))
        }

        // Global color
        if let colorError = validateColor(config.color, at: "color") {
            errors.append(colorError)
        }

        // Font availability
        if !isFontAvailable(config.font) {
            errors.append(ValidationError(
                path: "font",
                message: "Font '\(config.font)' not found on system, will use fallback",
                severity: .warning
            ))
        }

        return errors
    }

    private func validateWidget(_ widget: WidgetConfig, at index: Int) -> [ValidationError] {
        let prefix = "widgets[\(index)]"

        switch widget {
        case .text(let config):
            return validateTextWidget(config, prefix: prefix)
        case .graph(let config):
            return validateGraphWidget(config, prefix: prefix)
        case .bar(let config):
            return validateBarWidget(config, prefix: prefix)
        case .hr(let config):
            return validateHRWidget(config, prefix: prefix)
        case .gauge(let config):
            return validateGaugeWidget(config, prefix: prefix)
        case .image(let config):
            return validateImageWidget(config, prefix: prefix)
        }
    }

    private func validateTextWidget(_ config: TextWidgetConfig, prefix: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Text content
        if config.text.isEmpty {
            errors.append(ValidationError(
                path: "\(prefix).text",
                message: "Text content is empty",
                severity: .warning
            ))
        }

        // Color
        if let color = config.color, let error = validateColor(color, at: "\(prefix).color") {
            errors.append(error)
        }

        // Font size
        if let fontSize = config.fontSize, fontSize <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).fontSize",
                message: "Must be greater than 0",
                severity: .error
            ))
        }

        // Font availability
        if let fontName = config.fontName, !isFontAvailable(fontName) {
            errors.append(ValidationError(
                path: "\(prefix).font",
                message: "Font '\(fontName)' not found on system",
                severity: .warning
            ))
        }

        // Weight
        if let weight = config.weight?.lowercased(),
           !Self.validWeights.contains(weight) {
            errors.append(ValidationError(
                path: "\(prefix).weight",
                message: "Invalid weight '\(weight)'. Valid: \(Self.validWeights.joined(separator: ", "))",
                severity: .warning
            ))
        }

        // Alignment
        if let alignment = config.alignment?.lowercased(),
           !Self.validAlignments.contains(alignment) {
            errors.append(ValidationError(
                path: "\(prefix).align",
                message: "Invalid alignment '\(alignment)'. Valid: left, center, right",
                severity: .warning
            ))
        }

        // Opacity
        if let opacity = config.opacity, (opacity < 0 || opacity > 1) {
            errors.append(ValidationError(
                path: "\(prefix).opacity",
                message: "Opacity must be between 0 and 1",
                severity: .error
            ))
        }

        // Shadow color
        if let shadow = config.shadow, let error = validateColor(shadow.color, at: "\(prefix).shadow.color") {
            errors.append(error)
        }

        return errors
    }

    private func validateGraphWidget(_ config: GraphWidgetConfig, prefix: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Source
        if config.source.isEmpty {
            errors.append(ValidationError(
                path: "\(prefix).source",
                message: "Source variable is required",
                severity: .error
            ))
        }

        // Size
        if config.size.width <= 0 || config.size.height <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).size",
                message: "Width and height must be greater than 0",
                severity: .error
            ))
        }

        // Color
        if let color = config.color, let error = validateColor(color, at: "\(prefix).color") {
            errors.append(error)
        }

        return errors
    }

    private func validateBarWidget(_ config: BarWidgetConfig, prefix: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Source
        if config.source.isEmpty {
            errors.append(ValidationError(
                path: "\(prefix).source",
                message: "Source variable is required",
                severity: .error
            ))
        }

        // Dimensions
        if config.width <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).width",
                message: "Width must be greater than 0",
                severity: .error
            ))
        }

        if config.height <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).height",
                message: "Height must be greater than 0",
                severity: .error
            ))
        }

        // Colors
        if let color = config.color, let error = validateColor(color, at: "\(prefix).color") {
            errors.append(error)
        }

        if let bgColor = config.backgroundColor, let error = validateColor(bgColor, at: "\(prefix).backgroundColor") {
            errors.append(error)
        }

        return errors
    }

    private func validateHRWidget(_ config: HRWidgetConfig, prefix: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Width
        if config.width <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).width",
                message: "Width must be greater than 0",
                severity: .error
            ))
        }

        // Color
        if let color = config.color, let error = validateColor(color, at: "\(prefix).color") {
            errors.append(error)
        }

        return errors
    }

    private func validateGaugeWidget(_ config: GaugeWidgetConfig, prefix: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Source
        if config.source.isEmpty {
            errors.append(ValidationError(
                path: "\(prefix).source",
                message: "Source variable is required",
                severity: .error
            ))
        }

        // Radius
        if config.radius <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).radius",
                message: "Radius must be greater than 0",
                severity: .error
            ))
        }

        // Thickness
        if config.thickness <= 0 {
            errors.append(ValidationError(
                path: "\(prefix).thickness",
                message: "Thickness must be greater than 0",
                severity: .error
            ))
        }

        if config.thickness > config.radius {
            errors.append(ValidationError(
                path: "\(prefix).thickness",
                message: "Thickness should not exceed radius",
                severity: .warning
            ))
        }

        // Colors
        if let color = config.color, let error = validateColor(color, at: "\(prefix).color") {
            errors.append(error)
        }

        if let bgColor = config.backgroundColor, let error = validateColor(bgColor, at: "\(prefix).backgroundColor") {
            errors.append(error)
        }

        return errors
    }

    private func validateImageWidget(_ config: ImageWidgetConfig, prefix: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Path
        if config.path.isEmpty {
            errors.append(ValidationError(
                path: "\(prefix).path",
                message: "Image path is required",
                severity: .error
            ))
        } else if !config.path.hasPrefix("sf:") {
            // Check if file exists (only for non-SF Symbol paths)
            let expandedPath = (config.path as NSString).expandingTildeInPath
            if !FileManager.default.fileExists(atPath: expandedPath) {
                errors.append(ValidationError(
                    path: "\(prefix).path",
                    message: "Image file not found: \(config.path)",
                    severity: .warning
                ))
            }
        }

        // Size
        if let size = config.size {
            if size.width <= 0 || size.height <= 0 {
                errors.append(ValidationError(
                    path: "\(prefix).size",
                    message: "Width and height must be greater than 0",
                    severity: .error
                ))
            }
        }

        return errors
    }

    // MARK: - Helpers

    func validateColor(_ color: String, at path: String) -> ValidationError? {
        // Check hex format
        if color.hasPrefix("#") {
            let hex = String(color.dropFirst())
            let validLengths = [3, 4, 6, 8]  // RGB, RGBA, RRGGBB, RRGGBBAA

            if !validLengths.contains(hex.count) {
                return ValidationError(
                    path: path,
                    message: "Invalid hex color format. Use #RGB, #RGBA, #RRGGBB, or #RRGGBBAA",
                    severity: .error
                )
            }

            let validChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
            if hex.unicodeScalars.contains(where: { !validChars.contains($0) }) {
                return ValidationError(
                    path: path,
                    message: "Hex color contains invalid characters",
                    severity: .error
                )
            }
        }
        // Named colors would be validated at runtime

        return nil
    }

    // System fonts that are valid but not detectable via NSFontManager
    private static let systemFontNames = [
        "SF Mono", "SF Pro", "SF Pro Text", "SF Pro Display", "SF Pro Rounded",
        "SF Compact", "SF Compact Text", "SF Compact Display", "SF Compact Rounded",
        "New York", "New York Small", "New York Medium", "New York Large"
    ]

    private func isFontAvailable(_ fontName: String) -> Bool {
        // Skip empty or placeholder values
        if fontName.isEmpty || fontName == "undefined" {
            return true
        }

        // Known system fonts that work but aren't detectable via normal APIs
        if Self.systemFontNames.contains(fontName) {
            return true
        }

        // Check if the font family exists
        let availableFamilies = NSFontManager.shared.availableFontFamilies
        if availableFamilies.contains(fontName) {
            return true
        }

        // Check individual font names
        let availableFonts = NSFontManager.shared.availableFonts
        if availableFonts.contains(fontName) {
            return true
        }

        // Try to actually create the font
        if NSFont(name: fontName, size: 12) != nil {
            return true
        }

        return false
    }
}
