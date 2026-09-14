import Foundation
import Testing

@testable import FinanceBuddyCore

struct ValueTests {
  @Test func moneyStaysExactAndRefundsAreNegative() throws {
    let value = try JSONDecoder().decode(Money.self, from: Data("\"1250.55\"".utf8))
    #expect(value.formatted() == "MXN 1,250.55")
    #expect(Money(-20).formatted() == "-MXN 20.00")
    #expect(Money(20).signed(for: .refund).formatted() == "-MXN 20.00")
    #expect(Money(20).formatted(showPlus: true) == "+MXN 20.00")
    #expect(Money.zero.formatted(showPlus: true) == "MXN 0.00")
    #expect(try String(data: JSONEncoder().encode(value), encoding: .utf8) == "\"1250.55\"")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(Money.self, from: Data("1.25".utf8))
    }
    #expect(throws: (any Error).self) { try Money(string: "1e5") }
  }
  @Test(arguments: [
    ("2026-12-31", "2027-01-01"), ("2026-01-31", "2026-02-01"), ("2024-02-28", "2024-02-29"),
    ("2024-02-29", "2024-03-01"),
  ])
  func dateStepping(pair: (String, String)) throws {
    let start = try CalendarDate(pair.0)
    let end = try CalendarDate(pair.1)
    #expect(start.adding(days: 1) == end)
    #expect(end.adding(days: -1) == start)
  }
  @Test func datesRejectNormalization() throws {
    #expect(throws: (any Error).self) { try CalendarDate("2026-02-29") }
    #expect(throws: (any Error).self) { try CalendarDate("2026-13-01") }
    #expect(throws: (any Error).self) { try CalendarDate("2026-9-01") }
    let date = try JSONDecoder().decode(CalendarDate.self, from: Data("\"2026-09-11\"".utf8))
    #expect(date.formatted() == "Friday, September 11, 2026")
  }
  @Test func refusalsUseCodesAndHandleAuthExceptions() {
    let r = Refusal.map(
      data: Data(#"{"code":"future_code","error":"unavailable"}"#.utf8), status: 503)
    #expect(r.code == .unknown)
    #expect(r.errorDescription == "Something went wrong. Please try again.")
    #expect(
      Refusal.map(data: Data("{}".utf8), status: 401, signIn: true).error == Refusal.signInMessage)
    #expect(Refusal.map(data: Data("null".utf8), status: 503, session: true).code == .unavailable)
    #expect(Refusal.map(data: Data("null".utf8), status: 403, session: true).code == .forbidden)
    for code in RefusalCode.allCases {
      let data = Data(
        "{\"code\":\"\(code.rawValue)\",\"error\":\"arbitrary wording\",\"extra\":true}".utf8)
      #expect(Refusal.map(data: data, status: 400).code == code)
    }
  }
  @Test func summaryDecodesAdditiveFields() throws {
    let data = try JSONEncoder().encode(Fixtures.summary())
    let summary = try JSONDecoder().decode(Summary.self, from: data)
    #expect(summary.expenses.value == 1530)
    #expect(summary.netChange.value == 16470)
  }
}
