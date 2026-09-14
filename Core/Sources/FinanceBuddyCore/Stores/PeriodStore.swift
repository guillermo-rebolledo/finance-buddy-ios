import Foundation
import Observation

@MainActor @Observable public final class PeriodStore {
  public private(set) var selection = PeriodSelection()
  public private(set) var revision = 0
  public private(set) var summary: Summary?
  public private(set) var trends: Trends?
  public private(set) var loading: Bool
  public private(set) var error: String?
  public private(set) var failedSelection: PeriodSelection?
  private var sequence = 0
  private var loadedRevision = 0
  private let client: any APIClient
  public init(client: any APIClient, summary: Summary? = nil, trends: Trends? = nil) {
    self.client = client
    self.summary = summary
    self.trends = trends
    loading = summary == nil
  }
  /// True while nothing matching the selection is on screen: the first load or a period switch.
  /// Background refreshes of the same period keep showing the loaded figures.
  public var showsPlaceholder: Bool { loading && (summary == nil || loadedRevision != revision) }
  public func select(_ selection: PeriodSelection) {
    self.selection = selection
    revision += 1
    sequence += 1
    loading = true
  }
  public func previous() {
    if let summary { select(.init(kind: selection.kind, date: summary.start.adding(days: -1))) }
  }
  public func next() {
    if let summary { select(.init(kind: selection.kind, date: summary.end.adding(days: 1))) }
  }
  public func current() { select(.init(kind: selection.kind)) }
  public func refresh(dashboard: Bool = false) async {
    sequence += 1
    let requestSequence = sequence
    let requestRevision = revision
    let requested = selection
    loading = true
    do {
      let nextSummary: Summary
      let nextTrends: Trends?
      if dashboard {
        async let summaryReply = client.summary(requested)
        async let trendsReply = client.trends(requested)
        let pair = try await (summaryReply, trendsReply)
        guard pair.0.kind == pair.1.kind, pair.0.date == pair.1.date,
          pair.0.end == pair.1.end, pair.1.points.last?.start == pair.0.start
        else { throw ClientError.invalidResponse }
        nextSummary = pair.0
        nextTrends = pair.1
      } else {
        nextSummary = try await client.summary(requested)
        nextTrends = nil
      }
      guard requestSequence == sequence else { return }
      summary = nextSummary
      trends = nextTrends
      loadedRevision = requestRevision
      error = nil
      failedSelection = nil
      loading = false
    } catch {
      guard requestSequence == sequence else { return }
      failedSelection = requested
      self.error = error.localizedDescription
      loading = false
    }
  }
  public var failureMessage: String? {
    guard let failedSelection else { return nil }
    if let summary {
      return
        "We could not load \(failedSelection.requestDescription). The figures below still describe \(summary.title)."
    }
    return "We could not load \(failedSelection.requestDescription)."
  }
}
