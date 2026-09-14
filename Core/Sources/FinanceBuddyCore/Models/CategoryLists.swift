import Foundation

public struct CategoryLists: Codable, Sendable {
  public var income: [Category]
  public var expense: [Category]
  public init(income: [Category], expense: [Category]) {
    self.income = income
    self.expense = expense
  }
  public var all: [Category] { income + expense }
}
