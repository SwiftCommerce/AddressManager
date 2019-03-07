import Vapor
import Fluent

struct AddressContent: Content, Parameter {
    var id: Int?
    var buildingName: String?
    var typeIdentifier: String?
    var type: String?
    var municipality: String?
    var city: String?
    var district: String?
    var postalArea: String?
    var country: String?
    var street: StreetContent?
    
    func save(on conn: DatabaseConnectable) -> EventLoopFuture<AddressContent> {
        let address = Address(
            buildingName: self.buildingName,
            typeIdentifier: self.typeIdentifier,
            type: self.type,
            municipality: self.municipality,
            city: self.city,
            district: self.district,
            postalArea: self.postalArea,
            country: self.country
        )
        
        let street = { (address: Int) -> Street in
            return Street(
                number: self.street?.number,
                numberSuffix: self.street?.numberSuffix,
                name: self.street?.name,
                type: self.street?.type,
                direction: self.street?.direction,
                address: address
            )
        }
        
        return address.save(on: conn).flatMap { try street($0.requireID()).save(on: conn) }.transform(to: self)
    }
    
    func update(_ id: Address.ID, on conn: DatabaseConnectable) -> EventLoopFuture<AddressContent> {
        let address = Address.query(on: conn).filter(\.id == id).update(data: self)
        let street = Street.query(on: conn).filter(\.address == id).update(data: self.street)
        
        return flatMap(address, street) { _, _ in
            return AddressContent.find(id, on: conn)
        }
    }
    
    static func find(_ id: Address.ID, on conn: DatabaseConnectable) -> EventLoopFuture<AddressContent> {
        let query = Address.query(on: conn).join(\Address.id, to: \Street.address).filter(\.id == id).alsoDecode(Street.self)
        
        return query.first().map { data in
            guard let (address, street) = data else {
                throw Abort(.notFound)
            }
            
            return AddressContent(
                id: address.id,
                buildingName: address.buildingName,
                typeIdentifier: address.typeIdentifier,
                type: address.type,
                municipality: address.municipality,
                city: address.city,
                district: address.district,
                postalArea: address.postalArea,
                country: address.country,
                street: StreetContent(
                    id: street.id,
                    number: street.number,
                    numberSuffix: street.numberSuffix,
                    name: street.name,
                    type: street.type,
                    direction: street.direction
                )
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
