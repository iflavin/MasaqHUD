import Foundation

struct DateTimeInfo {
    let formatted: String
    let date: String
    let time: String
    let weekday: String
}

final class DateTimeMetrics {
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let weekdayFormatter: DateFormatter
    private let fullFormatter: DateFormatter

    // Default formats
    private let defaultDateFormat = "yyyy-MM-dd"
    private let defaultTimeFormat = "HH:mm:ss"
    private let defaultFullFormat = "EEEE, MMM d, yyyy HH:mm:ss"

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = defaultDateFormat

        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = defaultTimeFormat

        weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"

        fullFormatter = DateFormatter()
        fullFormatter.dateFormat = defaultFullFormat
    }

    /// Set custom formats using strftime-style patterns.
    /// Pass nil for any format to use defaults.
    func setFormats(date: String?, time: String?, datetime: String?) {
        if let dateFormat = date {
            dateFormatter.dateFormat = convertStrftimeToDateFormat(dateFormat)
        } else {
            dateFormatter.dateFormat = defaultDateFormat
        }

        if let timeFormat = time {
            timeFormatter.dateFormat = convertStrftimeToDateFormat(timeFormat)
        } else {
            timeFormatter.dateFormat = defaultTimeFormat
        }

        if let datetimeFormat = datetime {
            fullFormatter.dateFormat = convertStrftimeToDateFormat(datetimeFormat)
        } else {
            fullFormatter.dateFormat = defaultFullFormat
        }
    }

    /// Convert strftime patterns to DateFormatter patterns
    func convertStrftimeToDateFormat(_ strftime: String) -> String {
        var result = strftime

        // Order matters: replace longer patterns first to avoid partial matches
        let mappings: [(String, String)] = [
            ("%%", "\u{0000}"),  // Temporary placeholder for literal %
            ("%Y", "yyyy"),     // 4-digit year
            ("%y", "yy"),       // 2-digit year
            ("%m", "MM"),       // Month 01-12
            ("%d", "dd"),       // Day 01-31
            ("%e", "d"),        // Day 1-31 (space-padded in strftime, no padding here)
            ("%H", "HH"),       // Hour 00-23
            ("%I", "hh"),       // Hour 01-12
            ("%M", "mm"),       // Minute 00-59
            ("%S", "ss"),       // Second 00-59
            ("%p", "a"),        // AM/PM
            ("%P", "a"),        // am/pm (lowercase, DateFormatter uses locale)
            ("%A", "EEEE"),     // Full weekday name
            ("%a", "EEE"),      // Abbreviated weekday
            ("%B", "MMMM"),     // Full month name
            ("%b", "MMM"),      // Abbreviated month
            ("%h", "MMM"),      // Same as %b
            ("%j", "DDD"),      // Day of year
            ("%w", "c"),        // Weekday number (0-6)
            ("%u", "c"),        // Weekday number (1-7)
            ("%W", "ww"),       // Week of year
            ("%Z", "zzz"),      // Timezone name
            ("%z", "xxxx"),     // Timezone offset
            ("%n", "\n"),       // Newline
            ("%t", "\t"),       // Tab
        ]

        for (strftimeFmt, dateFmt) in mappings {
            result = result.replacingOccurrences(of: strftimeFmt, with: dateFmt)
        }

        // Restore literal percent signs
        result = result.replacingOccurrences(of: "\u{0000}", with: "%")

        return result
    }

    func getInfo() -> DateTimeInfo {
        let now = Date()

        return DateTimeInfo(
            formatted: fullFormatter.string(from: now),
            date: dateFormatter.string(from: now),
            time: timeFormatter.string(from: now),
            weekday: weekdayFormatter.string(from: now)
        )
    }
}
