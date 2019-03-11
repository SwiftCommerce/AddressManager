#if !os(macOS)
import XCTest

XCTMain([
    testCase(MySQLAddressRepositoryTests.allTests),
    testCase(MySQLDatabaseIsolationLevelTests.allTests)
])

#endif
