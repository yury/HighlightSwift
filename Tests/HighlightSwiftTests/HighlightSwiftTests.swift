import XCTest
@testable import HighlightSwift

final class HighlightSwiftTests: XCTestCase {
    func testExample()  async throws {
      let res = try! Highlight.text("test")
      assert(!res.text.string.hasSuffix("\n"))
    }
}
