@testable import App
import JSON
import Vapor
import XCTest

public final class MySQLAddressRepositoryTests: XCTestCase {
    
    var addressID: Address.ID? = nil
    var app: Application! = nil
    
    var pool: MySQLAddressRepository.ConnectionPool! = nil
    var validator: AddressValidator? = nil
    
    var addresses: MySQLAddressRepository {
        return MySQLAddressRepository(pool: self.pool, validator: self.validator)
    }
    
    public override func setUp() {
        super.setUp()
        
        self.app = try! Application.testable()
        self.pool = try! self.app.connectionPool(to: .mysql)
        self.validator = try? self.app.make(AddressValidator.self)
    }
    
    public override func tearDown() {
        self.pool = nil
        try! self.app.syncShutdownGracefully()
        
        super.tearDown()
    }
    
    func testOperations()throws {
        try self.create()
        try self.read()
        try self.update()
        try self.delete()
    }
    
    func create()throws {
        caseStart()
        defer { caseComplete() }
        
        let content = AddressContent(
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
                name: "Infinite",
                type: "Loop",
                direction: nil
            )
        )
        
        let created = try self.addresses.create(address: content).wait()
        self.addressID = created.id
        
        XCTAssertNotNil(created.id)
        XCTAssertNotNil(created.street?.id)
    }
    
    func read()throws {
        caseStart()
        defer { caseComplete() }
        
        guard let id = self.addressID else {
            throw Abort(.internalServerError)
        }
        
        guard let address = try self.addresses.find(address: id).wait() else {
            XCTFail("Did not find `Address` model with ID `\(id)`")
            return
        }
        
        XCTAssertEqual(address.id, id)
        XCTAssertNotNil(address.street?.id)
        
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.district, "California")
        XCTAssertEqual(address.postalArea, "95014")
        XCTAssertEqual(address.country, "United States")
        
        XCTAssertEqual(address.street?.name, "Infinite")
        XCTAssertEqual(address.street?.type, "Loop")
    }
    
    func update()throws {
        caseStart()
        defer { caseComplete() }
        
        guard let id = self.addressID else {
            throw Abort(.internalServerError)
        }
        
        let update = JSON.object(["buildingName": .string("Apple Campus")])
        guard let address = try self.addresses.update(address: id, with: update).wait() else {
            XCTFail("Did not find `Address` model with ID `\(id)`")
            return
        }
        
        XCTAssertEqual(address.id, id)
        XCTAssertNotNil(address.street?.id)
        
        XCTAssertEqual(address.buildingName, "Apple Campus")
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.district, "California")
        XCTAssertEqual(address.postalArea, "95014")
        XCTAssertEqual(address.country, "United States")
        
        XCTAssertEqual(address.street?.name, "Infinite")
        XCTAssertEqual(address.street?.type, "Loop")
        
        
        let revert = JSON.object(["buildingName": .null])
        guard let revertedAddress = try self.addresses.update(address: id, with: revert).wait() else {
            XCTFail("Did not find `Address` model with ID `\(id)`")
            return
        }
        
        XCTAssertNil(revertedAddress.buildingName)
    }
    
    func delete()throws {
        caseStart()
        defer { caseComplete() }
        
        guard let id = self.addressID else {
            throw Abort(.internalServerError)
        }
        
        try XCTAssertNoThrow(self.addresses.delete(address: id).wait())
    }
    
    public static let allTests = [
        ("testOperations", testOperations)
    ]
}
