import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Pushbullet_SwiftTests.allTests),
    ]
}
#endif
