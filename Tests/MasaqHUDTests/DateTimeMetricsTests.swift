import XCTest
@testable import MasaqHUDCore

final class DateTimeMetricsTests: XCTestCase {

    var dateTimeMetrics: DateTimeMetrics!

    override func setUp() {
        super.setUp()
        dateTimeMetrics = DateTimeMetrics()
    }

    override func tearDown() {
        dateTimeMetrics = nil
        super.tearDown()
    }

    // MARK: - strftime Conversion Tests

    func testConvert_datePatterns() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%Y-%m-%d"), "yyyy-MM-dd")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%y/%m/%d"), "yy/MM/dd")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%d.%m.%Y"), "dd.MM.yyyy")
    }

    func testConvert_timePatterns() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%H:%M:%S"), "HH:mm:ss")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%I:%M %p"), "hh:mm a")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%H:%M"), "HH:mm")
    }

    func testConvert_weekdayPatterns() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%A"), "EEEE")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%a"), "EEE")
    }

    func testConvert_monthPatterns() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%B"), "MMMM")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%b"), "MMM")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%h"), "MMM")
    }

    func testConvert_weekdayMonth() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%A, %B %d"), "EEEE, MMMM dd")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%a %b %d"), "EEE MMM dd")
    }

    func testConvert_escapedPercent() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%%"), "%")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("100%% complete"), "100% complete")
    }

    func testConvert_mixedPatterns() {
        XCTAssertEqual(
            dateTimeMetrics.convertStrftimeToDateFormat("%Y-%m-%d %H:%M:%S"),
            "yyyy-MM-dd HH:mm:ss"
        )
        XCTAssertEqual(
            dateTimeMetrics.convertStrftimeToDateFormat("%A, %B %d, %Y at %I:%M %p"),
            "EEEE, MMMM dd, yyyy at hh:mm a"
        )
    }

    func testConvert_specialCharacters() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%n"), "\n")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%t"), "\t")
    }

    func testConvert_timezones() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%Z"), "zzz")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%z"), "xxxx")
    }

    func testConvert_dayOfYear() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%j"), "DDD")
    }

    func testConvert_weekNumber() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%W"), "ww")
    }

    func testConvert_ampm() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%p"), "a")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("%P"), "a")
    }

    func testConvert_noPatterns() {
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat("plain text"), "plain text")
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat(""), "")
    }

    func testConvert_complexFormat() {
        // A complex real-world example
        let input = "%A, %B %d, %Y %I:%M:%S %p %Z"
        let expected = "EEEE, MMMM dd, yyyy hh:mm:ss a zzz"
        XCTAssertEqual(dateTimeMetrics.convertStrftimeToDateFormat(input), expected)
    }

    // MARK: - getInfo Tests

    func testGetInfo_returnsNonEmptyStrings() {
        let info = dateTimeMetrics.getInfo()

        XCTAssertFalse(info.time.isEmpty, "Time should not be empty")
        XCTAssertFalse(info.date.isEmpty, "Date should not be empty")
        XCTAssertFalse(info.weekday.isEmpty, "Weekday should not be empty")
        XCTAssertFalse(info.formatted.isEmpty, "Formatted should not be empty")
    }

    func testGetInfo_weekdayIsValidDayName() {
        let info = dateTimeMetrics.getInfo()

        let validWeekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        XCTAssertTrue(
            validWeekdays.contains(info.weekday),
            "Weekday '\(info.weekday)' should be a valid day name"
        )
    }

    func testSetFormats_customDateFormat() {
        dateTimeMetrics.setFormats(date: "%d/%m/%Y", time: nil, datetime: nil)
        let info = dateTimeMetrics.getInfo()

        // Date should be in dd/MM/yyyy format
        let dateRegex = try! NSRegularExpression(pattern: "^\\d{2}/\\d{2}/\\d{4}$")
        let range = NSRange(info.date.startIndex..., in: info.date)
        XCTAssertNotNil(dateRegex.firstMatch(in: info.date, range: range), "Date should match dd/MM/yyyy format")
    }

    func testSetFormats_customTimeFormat() {
        dateTimeMetrics.setFormats(date: nil, time: "%I:%M %p", datetime: nil)
        let info = dateTimeMetrics.getInfo()

        // Time should contain AM or PM
        XCTAssertTrue(
            info.time.contains("AM") || info.time.contains("PM"),
            "Time with 12-hour format should contain AM or PM"
        )
    }
}
