import JSON
import Vapor
import Fluent
import FluentMySQL

protocol AddressRepository: ServiceType {
    func create(address: AddressContent) -> EventLoopFuture<AddressContent>
    func find(address id: Address.ID) -> EventLoopFuture<AddressContent?>
    func update(address id: Address.ID, with content: AddressContent) -> EventLoopFuture<AddressContent?>
    func delete(address id: Address.ID) -> EventLoopFuture<Void>
}

final class MySQLAddressRepository: AddressRepository {
    typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<MySQLDatabase>>
    
    let pool: ConnectionPool
    
    init(pool: ConnectionPool) {
        self.pool = pool
    }
    
    static func makeService(for container: Container) throws -> MySQLAddressRepository {
        return try MySQLAddressRepository(pool: container.connectionPool(to: .mysql))
    }
    
    func create(address content: AddressContent) -> EventLoopFuture<AddressContent> {
        let address = Address(
            buildingName: content.buildingName,
            typeIdentifier: content.typeIdentifier,
            type: content.type,
            municipality: content.municipality,
            city: content.city,
            district: content.district,
            postalArea: content.postalArea,
            country: content.country
        )
        
        let street = { (id: Address.ID) -> Street in
            return Street(
                number: content.street?.number,
                numberSuffix: content.street?.numberSuffix,
                name: content.street?.name,
                type: content.street?.type,
                direction: content.street?.direction,
                address: id
            )
        }
        
        return self.pool.withConnection { conn -> EventLoopFuture<AddressContent> in
            return conn.transaction(on: .mysql) { transaction -> EventLoopFuture<(Address, Street)> in
                let savedAddress = address.save(on: transaction)
                let savedStreet = savedAddress.map { try street($0.requireID()) }.save(on: transaction)
                
                return savedAddress.and(savedStreet)
            }.map { saved in
                var response = content
                response.id = saved.0.id
                response.street?.id = saved.1.id
                
                return response
            }
        }
    }
    
    func find(address id: Int) -> EventLoopFuture<AddressContent?> {
        let result = self.pool.withConnection { conn -> EventLoopFuture<(Address, Street)?> in
            let q = Address.query(on: conn).join(\Street.address, to: \Address.id).filter(\.id == id).alsoDecode(Street.self)
            return q.first()
        }
        
        return result.map { result in
            guard let (address, street) = result else { return nil }
            
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
    
    func update(address id: Address.ID, with content: AddressContent) -> EventLoopFuture<AddressContent?> {
        let updated = self.pool.withConnection { conn -> EventLoopFuture<Address.ID> in
            return conn.transaction(on: .mysql) { transaction in
                
                let addressJSON = try JSONCoder.encode(content)
                let address = Address.query(on: transaction).filter(\.id == id).update(data: addressJSON)
                
                let streetJSON = try addressJSON.element(at: ["street"])
                let street: Future<Void>
                if streetJSON == .null {
                    street = conn.future()
                } else {
                    street = Street.query(on: transaction).filter(\.address == id).update(data: streetJSON)
                }
                
                return address.and(street).transform(to: id)
            }
        }
        
        return updated.flatMap(self.find(address:))
    }
    
    func delete(address id: Address.ID) -> EventLoopFuture<Void> {
        return self.pool.withConnection { conn in
            return conn.transaction(on: .mysql) { transaction in
                let address = Address.query(on: transaction).filter(\.id == id).delete()
                let street = Street.query(on: transaction).filter(\.address == id).delete()
                
                return address.and(street).transform(to: ())
            }
        }
    }
}
