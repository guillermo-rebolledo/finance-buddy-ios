import Foundation

/// A Mexico City calendar date. Date is used only as a UTC bridge for system controls.
public struct CalendarDate: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
  public let year: Int
  public let month: Int
  public let day: Int
  public static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.locale = Locale(identifier: "en_US_POSIX")
    return calendar
  }
  public init(_ value: String) throws {
    let parts = value.split(separator: "-", omittingEmptySubsequences: false)
    guard value.utf8.count == 10, parts.count == 3,
      parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
      value.allSatisfy({ $0 == "-" || ($0 >= "0" && $0 <= "9") }),
      let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]), (1...9999).contains(y),
      let date = Self.calendar.date(from: DateComponents(year: y, month: m, day: d)),
      Self.calendar.dateComponents([.year, .month, .day], from: date)
        == DateComponents(year: y, month: m, day: d)
    else { throw ValueError.invalidDate }
    year = y
    month = m
    day = d
  }
  public init(utcDate: Date) {
    let c = Self.calendar.dateComponents([.year, .month, .day], from: utcDate)
    year = c.year!
    month = c.month!
    day = c.day!
  }
  public var utcDate: Date {
    Self.calendar.date(from: DateComponents(year: year, month: month, day: day))!
  }
  public var description: String { String(format: "%04d-%02d-%02d", year, month, day) }
  public func adding(days: Int) -> Self {
    Self(utcDate: Self.calendar.date(byAdding: .day, value: days, to: utcDate)!)
  }
  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.description < rhs.description }
  public func formatted(_ format: String = "EEEE, MMMM d, yyyy") -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Self.calendar
    formatter.timeZone = Self.calendar.timeZone
    formatter.dateFormat = format
    return formatter.string(from: utcDate)
  }
  public init(from decoder: any Decoder) throws {
    try self.init(decoder.singleValueContainer().decode(String.self))
  }
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    try c.encode(description)
  }
}
