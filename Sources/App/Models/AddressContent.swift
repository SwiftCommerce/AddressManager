import Vapor
import Fluent

struct AddressContent: Content, Parameter {
    var buildingName: String?
    var typeIdentifier: String?
    var type: String?
    var municipality: String?
    var city: String?
    var district: String?
    var postalArea: String?
    var country: String?
    var street: Street
    
    static func find(_ id: Address.ID, on conn: DatabaseConnectable) -> Future<AddressContent> {
        let query = Address.query(on: conn).join(\Address.id, to: \Street.address).filter(\.id == id).alsoDecode(Street.self)
        
        return query.first().map { data in
            guard let (address, street) = data else {
                throw Abort(.notFound)
            }
            
            return AddressContent(
                buildingName: address.buildingName,
                typeIdentifier: address.typeIdentifier,
                type: address.type,
                municipality: address.municipality,
                city: address.city,
                district: address.district,
                postalArea: address.postalArea,
                country: address.country,
                street: street
            )
        }
    }
    
    static func resolveParameter(_ parameter: String, on container: Container) throws -> EventLoopFuture<AddressContent> {
        guard let id = Address.ID(parameter) else {
            throw Abort(.badRequest, reason: "Address parameter must be convertible to an Int")
        }
        
        return container.withPooledConnection(to: .mysql) { connection in
            return AddressContent.find(id, on: connection)
        }
    }
}
