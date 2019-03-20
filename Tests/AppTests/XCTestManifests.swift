import XCTest

extension AddressControllerTests {
    static let __allTests = [
        ("testEndpoints", testEndpoints),
    ]
}

extension AppTests {
    static let __allTests = [
        ("testUniverseWorks", testUniverseWorks),
    ]
}

extension MySQLAddressRepositoryTests {
    static let __allTests = [
        ("testOperations", testOperations),
    ]
}

extension MySQLDatabaseIsolationLevelTests {
    static let __allTests = [
        ("testCases", testCases),
        ("testCurrent", testCurrent),
        ("testIsolatedTransaction", testIsolatedTransaction),
        ("testParse", testParse),
        ("testQuery", testQuery),
    ]
}

extension SmartyStreetAddressValidatorTests {
    static let __allTests = [
        ("testBuildingAddress", testBuildingAddress),
        ("testNonExistant", testNonExistant),
        ("testState", testState),
        ("testStreetAddress", testStreetAddress),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AddressControllerTests.__allTests),
        testCase(AppTests.__allTests),
        testCase(MySQLAddressRepositoryTests.__allTests),
        testCase(MySQLDatabaseIsolationLevelTests.__allTests),
        testCase(SmartyStreetAddressValidatorTests.__allTests),
    ]
}
#endif
