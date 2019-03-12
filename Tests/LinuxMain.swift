#if !os(macOS)
import XCTest

XCTMain([
    testCase(AddressControllerTests.allTests),
    testCase(MySQLAddressRepositoryTests.allTests),
    testCase(GoogleMapsAddressValidatorTests.allTests),
    testCase(MySQLDatabaseIsolationLevelTests.allTests)
])

#endif
