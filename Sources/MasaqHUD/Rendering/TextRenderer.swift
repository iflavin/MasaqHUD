import AppKit
import CoreText

enum FontWeight: String {
    case ultraLight = "ultralight"
    case thin = "thin"
    case light = "light"
    case regular = "regular"
    case medium = "medium"
    case semibold = "semibold"
    case bold = "bold"
    case heavy = "heavy"
    case black = "black"

    var nsFontWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

final class TextRenderer {
    // Font cache to avoid repeated allocations
    private var fontCache: [FontCacheKey: NSFont] = [:]

    private struct FontCacheKey: Hashable {
        let fontName: String?
        let fontSize: CGFloat
        let weight: FontWeight
        let italic: Bool
    }

    private func getFont(fontName: String?, fontSize: CGFloat, weight: FontWeight, italic: Bool) -> NSFont {
        let key = FontCacheKey(fontName: fontName, fontSize: fontSize, weight: weight, italic: italic)

        if let cached = fontCache[key] {
            return cached
        }

        var font: NSFont

        if let customFontName = fontName {
            let weightSuffix = weight == .regular ? "" : " \(weight.rawValue.capitalized)"
            if let customFont = NSFont(name: customFontName + weightSuffix, size: fontSize) {
                font = customFont
            } else if let customFont = NSFont(name: customFontName, size: fontSize) {
                font = customFont
            } else {
                font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight.nsFontWeight)
            }
        } else {
            let sfMonoName = "SF Mono"
            let weightSuffix: String
            switch weight {
            case .ultraLight, .thin, .light: weightSuffix = " Light"
            case .regular: weightSuffix = ""
            case .medium: weightSuffix = " Medium"
            case .semibold: weightSuffix = " Semibold"
            case .bold: weightSuffix = " Bold"
            case .heavy, .black: weightSuffix = " Heavy"
            }

            if let sfMono = NSFont(name: sfMonoName + weightSuffix, size: fontSize) {
                font = sfMono
            } else {
                font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight.nsFontWeight)
            }
        }

        if italic {
            let descriptor = font.fontDescriptor.withSymbolicTraits(.italic)
            font = NSFont(descriptor: descriptor, size: fontSize) ?? font
        }

        fontCache[key] = font
        return font
    }

    func drawText(
        context: CGContext,
        text: String,
        x: CGFloat,
        y: CGFloat,
        fontSize: CGFloat,
        color: NSColor,
        fontName: String? = nil,
        weight: FontWeight = .regular,
        italic: Bool = false,
        opacity: CGFloat = 1.0,
        shadow: NSShadow? = nil,
        alignment: String = "left"
    ) {
        // Use autoreleasepool to ensure immediate cleanup of temporary objects
        autoreleasepool {
            let font = getFont(fontName: fontName, fontSize: fontSize, weight: weight, italic: italic)

            let finalColor = opacity < 1.0 ? color.withAlphaComponent(color.alphaComponent * opacity) : color

            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: finalColor
            ]

            if let shadow = shadow {
                attributes[.shadow] = shadow
            }

            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributedString)

            // Calculate text width for alignment
            var adjustedX = x
            if alignment == "center" || alignment == "right" {
                let bounds = CTLineGetBoundsWithOptions(line, [])
                let textWidth = bounds.width
                if alignment == "center" {
                    adjustedX = x - textWidth / 2
                } else {  // right
                    adjustedX = x - textWidth
                }
            }

            context.saveGState()
            context.textPosition = CGPoint(x: adjustedX, y: y)
            CTLineDraw(line, context)
            context.restoreGState()
        }
    }
}
