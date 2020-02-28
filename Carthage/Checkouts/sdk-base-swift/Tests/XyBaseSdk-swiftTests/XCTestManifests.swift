import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(sdk_base_swiftTests.allTests),
    ]
}
#endif
