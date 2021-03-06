@testable import App
import XCTest
import Vapor

final class AddressControllerTests: XCTestCase {
    
    // MARK: - Configuration
    var app: Application!
    var id: Address.ID?
    
    var addressID: String {
        guard let id = self.id else {
            fatalError("Unexpectedly found `nil` when trying to unwrap `.id` property of type `Address.ID?`")
        }
        return String(describing: id)
    }
    
    override func setUp() {
        super.setUp()
        
        self.app = try! Application.testable()
    }
    
    override func tearDown() {
        try! self.app.syncShutdownGracefully()
        
        super.tearDown()
    }
    
    // MARK: - Tests
    func testEndpoints()throws {
        try self.create()
        try self.read()
        try self.update()
        try self.delete()
        try self.validate()
        try self.parse()
    }
    
    func create()throws {
        caseStart()
        defer { caseComplete() }
        
        let body = try JSONEncoder().encode(AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: "Cupertino",
            district: "California",
            postalArea: "95014",
            country: nil,
            street: StreetContent(
                id: nil,
                number: 1,
                numberSuffix: nil,
                name: "Apple Park",
                type: "Way",
                direction: nil
            )
        ))
        let http = self.request(.POST, body: body)
        
        let address = try self.app.response(for: http, as: AddressContent.self)
        self.id = address.id
        
        XCTAssertNotNil(address.id)
        XCTAssertNotNil(address.street?.id)
        
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.district, "California")
        XCTAssertEqual(address.postalArea, "95014")
        
        XCTAssertEqual(address.street?.type, "Way")
        XCTAssertEqual(address.street?.name, "Apple Park")
        XCTAssertEqual(address.street?.number, 1)
    }
    
    func read()throws {
        caseStart()
        defer { caseComplete() }
        
        let http = self.request(.GET, self.addressID)
        let address = try self.app.response(for: http, as: AddressContent.self)
        
        XCTAssertNotNil(address.id)
        XCTAssertNotNil(address.street?.id)
        
        XCTAssertNil(address.country)
        XCTAssertNil(address.buildingName)
        XCTAssertNil(address.street?.numberSuffix)
        
        XCTAssertEqual(address.id, self.id)
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.district, "California")
        XCTAssertEqual(address.postalArea, "95014")
        XCTAssertEqual(address.street?.type, "Way")
        XCTAssertEqual(address.street?.name, "Apple Park")
        XCTAssertEqual(address.street?.number, 1)
    }
    
    func update()throws {
        caseStart()
        defer { caseComplete() }
        
        let body = try JSONEncoder().encode(AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: nil,
            district: nil,
            postalArea: nil,
            country: "United States",
            street: nil
        ))
        let http = self.request(.PATCH, self.addressID, body: body)
        let address = try self.app.response(for: http, as: AddressContent.self)
        
        XCTAssertNotNil(address.id)
        XCTAssertNotNil(address.street?.id)
        
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.district, "California")
        XCTAssertEqual(address.postalArea, "95014")
        XCTAssertEqual(address.country, "United States")
        
        XCTAssertEqual(address.street?.type, "Way")
        XCTAssertEqual(address.street?.name, "Apple Park")
        XCTAssertEqual(address.street?.number, 1)
    }
    
    func delete()throws {
        caseStart()
        defer { caseComplete() }
        
        let http = self.request(.DELETE, self.addressID)
        let status = try self.app.response(for: http).http.status
        
        XCTAssertEqual(status, .noContent)
    }
    
    func validate()throws {
        caseStart()
        defer { caseComplete() }
        
        let appleCampus = try JSONEncoder().encode(AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: "Cupertino",
            district: "California",
            postalArea: "95014",
            country: nil,
            street: StreetContent(
                id: nil,
                number: 1,
                numberSuffix: nil,
                name: "Apple Park",
                type: "Way",
                direction: nil
            )
        ))
        let campusRequest = self.request(.POST, "validate", body: appleCampus)
        let campusStatus = try self.app.response(for: campusRequest).http.status
        XCTAssertEqual(campusStatus, .ok)
        
        
        let infiniteLoop = try JSONEncoder().encode(AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: "Cupertino",
            district: "California",
            postalArea: "95014",
            country: nil,
            street: StreetContent(
                id: nil,
                number: nil,
                numberSuffix: nil,
                name: "Infinite",
                type: "Loop",
                direction: nil
            )
        ))
        let loopRequest = self.request(.POST, "validate", body: infiniteLoop)
        let loopStatus = try self.app.response(for: loopRequest).http.status
        XCTAssertEqual(loopStatus, .badRequest)
        
        let kansas = try JSONEncoder().encode(AddressContent(
            id: nil,
            buildingName: nil,
            typeIdentifier: nil,
            type: nil,
            municipality: nil,
            city: nil,
            district: "Kansas",
            postalArea: nil,
            country: "United States",
            street: nil
        ))
        let kansasRequest = self.request(.POST, "validate", body: kansas)
        let kansasStatus = try self.app.response(for: kansasRequest).http.status
        XCTAssertEqual(kansasStatus, .failedDependency)
    }
    
    func parse() throws {
        caseStart()
        defer { caseComplete() }
        
        let data = try JSONEncoder().encode(
            AddressData(country: "United States", data: "39 1/2 Washington Sq S, New York, NY 10012")
        )
        let request = self.request(.POST, "parse", body: data)
        let parsed = try self.app.response(for: request, as: AddressContent.self)
        
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
    
    // MARK: - Helpers
    func request(_ method: HTTPMethod, _ resource: String? = nil, body: LosslessHTTPBodyRepresentable? = nil) -> HTTPRequest {
        var request = HTTPRequest(method: method, url: "/v1/addresses/" + (resource ?? ""), body: body ?? HTTPBody())
        if body != nil {
            request.headers.replaceOrAdd(name: .contentType, value: MediaType.json.serialize())
        }
        
        return request
    }
}
