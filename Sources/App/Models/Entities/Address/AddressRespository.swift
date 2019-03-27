import JSON
import Vapor
import FluentMySQL

protocol AddressRepository: ServiceType {
    func create(address: AddressContent) -> EventLoopFuture<AddressContent>
    func find(address id: Address.ID) -> EventLoopFuture<AddressContent?>
    func update(address id: Address.ID, with content: JSON) -> EventLoopFuture<AddressContent?>
    func delete(address id: Address.ID) -> EventLoopFuture<Void>
}

final class MySQLAddressRepository: AddressRepository {
    typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<MySQLDatabase>>
    
    let pool: ConnectionPool
    let validator: AddressValidator?
    
    init(pool: ConnectionPool, validator: AddressValidator?) {
        self.pool = pool
        self.validator = validator
    }
    
    static func makeService(for container: Container) throws -> MySQLAddressRepository {
        return MySQLAddressRepository(
            pool: try container.connectionPool(to: .mysql),
            validator: try? container.make()
        )
    }
    
    private func validate(_ address: AddressContent, on worker: Worker) -> Future<Void> {
        return self.validator?.validate(address: address) ?? worker.future()
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
                
                return savedAddress.and(savedStreet).flatMap { saved in
                    return self.validate(content, on: transaction).transform(to: saved)
                }
            }.map { saved in
                var response = content
                
                response.id = saved.0.id
                response.street = response.street ?? StreetContent(
                    id: nil,
                    number: nil,
                    numberSuffix: nil,
                    name: nil,
                    type: nil,
                    direction: nil
                )
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
    
    func update(address id: Address.ID, with content: JSON) -> EventLoopFuture<AddressContent?> {
        return self.pool.withConnection { conn -> EventLoopFuture<AddressContent?> in
            return conn.transaction(on: .mysql, level: .uncommitted) { transaction in
                guard content.isObject else {
                    throw Abort(.badRequest, reason: "JSON body must be an object")
                }
                
                let street =
                    content.street.object.map { Street.query(on: transaction).filter(\.address == id).update(data: $0) } ??
                    conn.future()

                let address =  { () -> EventLoopFuture<Void> in
                    var object = content
                    object.remove(["street"])
                    
                    return object == [:] ? conn.future() : Address.query(on: transaction).filter(\.id == id).update(data: object)
                }()
                
                let verifiedResult = address.and(street).catchMap { error in
                    if let mysql = error as? MySQLError, mysql.identifier == "server (1054)" {
                        let property = mysql.reason.split(separator: "'")[1]
                        throw Abort(.badRequest, reason: "Attempted to set non-existant model property `\(property)`")
                    }
                    throw error
                }
                
                return verifiedResult.transform(to: id).flatMap(self.find(address:)).flatMap { content in
                    guard let content = content else {
                        return transaction.future(nil)
                    }
                    return self.validate(content, on: transaction).transform(to: content)
                }
            }
        }
    }
    
    func delete(address id: Address.ID) -> EventLoopFuture<Void> {
        return self.pool.withConnection { conn in
            return conn.transaction(on: .mysql) { transaction in
                let street = Street.query(on: transaction).filter(\.address == id).delete()
                let address = Address.query(on: transaction).filter(\.id == id).delete()
                
                return address.and(street).transform(to: ())
            }
        }
    }
}
