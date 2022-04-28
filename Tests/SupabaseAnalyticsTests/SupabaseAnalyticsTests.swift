import Supabase
import XCTest

@testable import SupabaseAnalytics

final class SupabaseAnalyticsTests: XCTestCase {
  func testExample() {
    SupabaseAnalytics.initialize(
      client: SupabaseClient(
        supabaseURL: URL(string: "http://localhost")!,
        supabaseKey: "abcdef"
      )
    )

    SupabaseAnalytics.logEvent(name: "test_run", params: ["test-name": #function])
  }
}
