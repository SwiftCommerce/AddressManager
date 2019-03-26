@testable import App
import XCTest
import Vapor

final class SmartyStreetAddressParserTests: XCTestCase {
    var parser: SmartyStreetAddressParser!
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        self.app = try! Application.testable()
        self.parser = try! SmartyStreetAddressParser.makeService(for: self.app)
    }
    
    override func tearDown() {
        self.parser = nil
        try! self.app.syncShutdownGracefully()
        
        super.tearDown()
    }
    
    func testStandard() throws {
        let data = AddressData(country: "United States", data: "39 1/2 Washington Sq S, New York, NY 10012")
        let parsed = try self.parser.parse(data).wait()
        
        XCTAssertEqual(parsed.country, "United States")
        XCTAssertEqual(parsed.postalArea, "10012")
        XCTAssertEqual(parsed.district, "NY")
        XCTAssertEqual(parsed.city, "New York")
        XCTAssertEqual(parsed.street?.number, 39)
        XCTAssertEqual(parsed.street?.numberSuffix, "1/2")
        XCTAssertEqual(parsed.street?.name, "Washington")
        XCTAssertEqual(parsed.street?.type, "Sq")
        XCTAssertEqual(parsed.street?.direction, .south)
    }
    
    func testPOBox() throws {
        let data = AddressData(country: "United States", data: "P.O. Box 313 Copper Center, Alaska, 99573")
        let parsed = try self.parser.parse(data).wait()
        
        XCTAssertEqual(parsed.country, "United States")
        XCTAssertEqual(parsed.postalArea, "99573")
        XCTAssertEqual(parsed.district, "AK")
        XCTAssertEqual(parsed.city, "Copper Center")
        XCTAssertEqual(parsed.type, "PO Box")
        XCTAssertEqual(parsed.typeIdentifier, "313")
    }
    
    func testApartment() throws {
        let data = AddressData(country: "United States", data: "255 SW 3rd Ave Apt #273 Deerfield Beach, Florida, 33441")
        let parsed = try self.parser.parse(data).wait()
        
        XCTAssertEqual(parsed.country, "United States")
        XCTAssertEqual(parsed.postalArea, "33441")
        XCTAssertEqual(parsed.district, "FL")
        XCTAssertEqual(parsed.city, "Deerfield Beach")
        XCTAssertEqual(parsed.type, "Apt")
        XCTAssertEqual(parsed.typeIdentifier, "273")
    }
    
    func testInternational() throws {
        guard (Environment.get("ADDRESS_SUPPORT_INTERNATIONAL").flatMap(Bool.init) ?? false) else {
            print("International tests will not run unless `ADDRESS_SUPPORT_INTERNATIONAL` env var is set")
            return
        }
        
        let data = AddressData(country: "Germany", data: "Mayfarthstraße 4, 60314 Frankfurt am Main, Germany")
        let parsed = try self.parser.parse(data).wait()
        
        XCTAssertEqual(parsed.country, "Germany")
        XCTAssertEqual(parsed.postalArea, "60314")
        XCTAssertEqual(parsed.district, "Hessen")
        XCTAssertEqual(parsed.city, "Frankfurt am Main")
        XCTAssertEqual(parsed.street?.number, 4)
    }
}
