/// This value type is used to identify properties that contain
/// a recurrence rule specification.
///
/// See https://tools.ietf.org/html/rfc5545#section-3.3.10
public struct ICalendarRecurrenceRule: ICalendarPropertyEncodable {
    /// The frequency of the recurrence.
    public var frequency: Frequency
    /// At which interval the recurrence repeats (in terms of the frequency).
    /// E.g. 1 means every hour for an hourly rule, ...
    /// The default value is 1.
    public var interval: Int?

    /// The end date/time. Must have the same 'ignoreTime'-value as dtstart.
    public var until: ICalendarDate? {
        willSet { count = nil }
    }
    /// The number of recurrences.
    public var count: Int? {
        willSet { until = nil }
    }

    /// At which seconds of the minute it should occur.
    /// Must be between 0 and 60 (inclusive).
    public var bySeconds: [Int]? {
        didSet { assert(bySeconds?.allSatisfy { (0...60).contains($0) } ?? true, "by-second rules must be between 0 and 60 (inclusive): \(bySeconds ?? [])") }
    }
    /// At which minutes of the hour it should occur.
    /// Must be between 0 and 60 (exclusive).
    public var byMinutes: [Int]? {
        didSet { assert(byMinutes?.allSatisfy { (0..<60).contains($0) } ?? true, "by-hour rules must be between 0 and 60 (exclusive): \(byMinutes ?? [])") }
    }
    /// At which hours of the day it should occur.
    /// Must be between 0 and 24 (exclusive).
    public var byHours: [Int]? {
        didSet { assert(byHours?.allSatisfy { (0..<24).contains($0) } ?? true, "by-hour rules must be between 0 and 24 (exclusive): \(byHours ?? [])") }
    }
    /// At which days (of the week/year) it should occur.
    public var byDays: [Day]?
    /// At which days of the month it should occur. Specifies a COMMA-separated
    /// list of days of the month. Valid values are 1 to 31 or -31 to -1.
    public var byDaysOfMonth: [Int]? {
        didSet { assert(byDaysOfYear?.allSatisfy { (1...31).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 31 or -31 and -1: \(byDaysOfMonth ?? [])") }
    }
    /// At which days of the year it should occur. Specifies a list of days
    /// of the year.  Valid values are 1 to 366 or -366 to -1.
    public var byDaysOfYear: [Int]? {
        didSet { assert(byWeeksOfYear?.allSatisfy { (1...366).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 366 or -366 and -1: \(byDaysOfYear ?? [])") }
    }
    /// At which weeks of the year it should occur. Specificies a list of
    /// ordinals specifying weeks of the year. Valid values are 1 to 53 or -53 to
    /// -1.
    public var byWeeksOfYear: [Int]? {
        didSet { assert(byWeeksOfYear?.allSatisfy { (1...53).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 53 or -53 and -1: \(byWeeksOfYear ?? [])") }
    }
    /// At which months it should occur.
    /// Must be between 1 and 12 (inclusive).
    public var byMonths: [Int]? {
        didSet { assert(byMonths?.allSatisfy { (1...12).contains($0) } ?? true, "by-month-of-year rules must be between 1 and 12: \(byMonths ?? [])") }
    }
    /// Specifies a list of values that corresponds to the nth occurrence within
    /// the set of recurrence instances specified by the rule. By-set-pos
    /// operates on a set of recurrence instances in one interval of the
    /// recurrence rule. For example, in a weekly rule, the interval would be one
    /// week A set of recurrence instances starts at the beginning of the
    /// interval defined by the frequency rule part. Valid values are 1 to 366 or
    /// -366 to -1. It MUST only be used in conjunction with another by-xxx rule
    /// part.
    public var bySetPos: [Int]? {
        didSet { assert(bySetPos?.allSatisfy { (1...366).contains(abs($0)) } ?? true, "by-set-pos rules must be between 1 and 366 or -366 and -1: \(bySetPos ?? [])") }
    }
    /// The day on which the workweek starts.
    /// Monday by default.
    public var startOfWorkweek: DayOfWeek?

    private var properties: [(String, ICalendarEncodable?)] {
        let groupedProperties: [(String, [ICalendarEncodable]?)] = [
            ("FREQ", [frequency]),
            ("INTERVAL", interval.map { [$0] } ?? []),
            ("UNTIL", until.map { [$0] } ?? []),
            ("COUNT", count.map { [$0] } ?? []),
            ("BYSECOND", bySeconds),
            ("BYMINUTE", byMinutes),
            ("BYHOUR", byHours),
            ("BYDAY", byDays),
            ("BYMONTHDAY", byDaysOfMonth),
            ("BYYEARDAY", byDaysOfYear),
            ("BYWEEKNO", byWeeksOfYear),
            ("BYMONTH", byMonths),
            ("BYSETPOS", bySetPos),
            ("WKST", startOfWorkweek.map { [$0] } ?? [])
        ]
        return groupedProperties.flatMap { (key, values) in (values ?? []).map { (key, $0) } }
    }

    public var iCalendarEncoded: String {
        properties.compactMap { (key, value) in value.map { "\(key)=\($0.iCalendarEncoded)" } }.joined(separator: ";")
    }

    public enum Frequency: String, ICalendarEncodable {
        case secondly = "SECONDLY"
        case minutely = "MINUTELY"
        case hourly = "HOURLY"
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case monthly = "MONTHLY"
        case yearly = "YEARLY"

        public var iCalendarEncoded: String { rawValue }
    }

    public enum DayOfWeek: String, ICalendarEncodable {
        case monday = "MO"
        case tuesday = "TU"
        case wednesday = "WE"
        case thursday = "TH"
        case friday = "FR"
        case saturday = "SA"
        case sunday = "SU"

        public var iCalendarEncoded: String { rawValue }
    }

    public struct Day: ICalendarEncodable {
        /// The week of the day. May be negative.
        public let weekOfYear: Int?
        /// The day of the week.
        public let dayOfWeek: DayOfWeek

        public var iCalendarEncoded: String { "\(weekOfYear.map(String.init) ?? "")\(dayOfWeek.iCalendarEncoded)" }

        public init(weekOfYear: Int? = nil, dayOfWeek: DayOfWeek) {
            self.weekOfYear = weekOfYear
            self.dayOfWeek = dayOfWeek

            assert(weekOfYear.map { (1...53).contains(abs($0)) } ?? true, "Week-of-year \(weekOfYear.map(String.init) ?? "?") is not between 1 and 53 or -53 and -1 (each inclusive)")
        }
    }

    // TODO: Initializer
}