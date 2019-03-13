#if !os(macOS)
import XCTest

XCTMain([
    
    // Controllers
    testCase(OptionsControllerTests.allCases),
    testCase(AddressControllerTests.allTests),
    
    // Models
    testCase(MySQLAddressRepositoryTests.allTests),
    
    // Services
    testCase(GoogleMapsAddressValidatorTests.allTests),
    
    // Utilities
    testCase(MySQLDatabaseIsolationLevelTests.allTests)
])

#endif
