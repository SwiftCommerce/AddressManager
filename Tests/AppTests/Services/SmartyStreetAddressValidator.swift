@testable import App
import XCTest
import Vapor

final class SmartyStreetAddressValidatorTests: XCTestCase {
    var validator: SmartyStreetAddressValidator!
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        self.app = try! Application.testable()
        self.validator = try! SmartyStreetAddressValidator.makeService(for: self.app)
    }
    
    override func tearDown() {
        self.validator = nil
        try! self.app.syncShutdownGracefully()
        
        super.tearDown()
    }
    
    func testBuildingAddress()throws {
        let address = AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: "Cupertino",
            district: "California",
            postalArea: "95014",
            country: "United States",
            street: StreetContent(
                id: nil,
                number: 1,
                numberSuffix: nil,
                name: "Apple Park",
                type: "Way",
                direction: nil
            )
        )
        
        try XCTAssertNoThrow(self.validator.validate(address: address).wait())
    }
    
    func testStreetAddress()throws {
        let address = AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: "Cupertino",
            district: "California",
            postalArea: "95014",
            country: "United States",
            street: StreetContent(
                id: nil,
                number: nil,
                numberSuffix: nil,
                name: "Apple Park",
                type: "Way",
                direction: nil
            )
        )
        
        try XCTAssertThrowsError(self.validator.validate(address: address).wait())
    }
    
    func testState()throws {
        let address = AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: "Cupertino",
            district: "California",
            postalArea: nil,
            country: "United States",
            street: nil
        )
        
        try XCTAssertThrowsError(self.validator.validate(address: address).wait())
    }
    
    func testNonExistant()throws {
        let address = AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: "Middle",
            city: "Nowhere",
            district: "Kansas",
            postalArea: "68660",
            country: "United States",
            street: StreetContent(
                id: nil,
                number: 5748,
                numberSuffix: nil,
                name: "Faerie",
                type: "Dr.",
                direction: .northWest
            )
        )
        
        try XCTAssertThrowsError(self.validator.validate(address: address).wait())
    }
}
