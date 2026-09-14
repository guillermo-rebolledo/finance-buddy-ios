import Foundation

public struct Money: Codable, Hashable, Sendable {
  public let value: Decimal
  public init(_ value: Decimal) { self.value = value }
  public init(string: String) throws {
    guard string.range(of: #"^-?[0-9]+(?:\.[0-9]{1,2})?$"#, options: .regularExpression) != nil,
      string.filter({ $0.isNumber }).count <= 38,
      let decimal = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")),
      !decimal.isNaN
    else { throw ValueError.invalidMoney }
    value = decimal
  }
  public var wire: String {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.numberStyle = .decimal
    f.usesGroupingSeparator = false
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    return f.string(from: NSDecimalNumber(decimal: value))!
  }
  public func formatted(showPlus: Bool = false) -> String {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.numberStyle = .decimal
    f.usesGroupingSeparator = true
    f.groupingSize = 3
    f.groupingSeparator = ","
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    let magnitude = value < 0 ? -value : value
    return
      "\(value < 0 ? "-" : showPlus && value > 0 ? "+" : "")MXN \(f.string(from: NSDecimalNumber(decimal: magnitude))!)"
  }
  public func signed(for kind: MovementKind) -> Self { Self(kind == .refund ? -value : value) }
  public init(from decoder: any Decoder) throws {
    try self.init(string: decoder.singleValueContainer().decode(String.self))
  }
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    try c.encode(wire)
  }
  public static let zero = Money(0)
}
