#if !os(macOS)
import XCTest

XCTMain([
    testCase(MySQLAddressRepositoryTests.allTests)
])

#endif
