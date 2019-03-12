#if !os(macOS)
import XCTest

XCTMain([
    testCase(AddressControllerTests.allTests),
    testCase(MySQLAddressRepositoryTests.allTests),
    testCase(MySQLDatabaseIsolationLevelTests.allTests)
])

#endif
