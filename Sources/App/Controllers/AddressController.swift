import Vapor
import FluentMySQL

final class AddressController: RouteCollection {
    typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<MySQLDatabase>>
    
    let pool: ConnectionPool
    
    init(pool: ConnectionPool) {
        self.pool = pool
    }
    
    func boot(router: Router) throws {
        let addresses = router.grouped(any, "addresses")
        
        addresses.post(AddressContent.self, use: create)
        addresses.get(AddressContent.parameter, use: read)
        addresses.patch(AddressContent.self, at: Address.ID.parameter, use: update)
        addresses.delete(Address.ID.parameter, use: delete)
    }
    
    func create(_ request: Request, content: AddressContent)throws -> Future<AddressContent> {
        return self.pool.withConnection(content.save)
    }
    
    func read(_ request: Request)throws -> Future<AddressContent> {
        return try request.parameters.next(AddressContent.self)
    }
    
    func update(_ request: Request, content: AddressContent)throws -> Future<AddressContent> {
        let id = try request.parameters.next(Address.ID.self)
        return self.pool.withConnection { conn in content.update(id, on: conn) }
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        let id = try request.parameters.next(Address.ID.self)
        return self.pool.withConnection { conn in
            let street = Street.query(on: conn).filter(\.id == id).delete()
            let address = Address.query(on: conn).filter(\.id == id).delete()
            
            return map(address, street) { _, _ in return HTTPStatus.noContent }
        }
    }
}
