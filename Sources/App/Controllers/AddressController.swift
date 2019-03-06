import Vapor
import FluentMySQL

final class AddressController: RouteCollection {
    let connection: MySQLConnection
    
    init(connection: MySQLConnection) {
        self.connection = connection
    }
    
    func boot(router: Router) throws {
        let addresses = router.grouped(any, "addresses")
        
        addresses.post(AddressContent.self, use: create)
        addresses.get(AddressContent.parameter, use: read)
        addresses.patch(AddressContent.self, at: Address.ID.parameter, use: update)
        addresses.delete(Address.ID.parameter, use: delete)
    }
    
    func create(_ request: Request, content: AddressContent)throws -> Future<AddressContent> {
        return content.save(on: self.connection)
    }
    
    func read(_ request: Request)throws -> Future<AddressContent> {
        return try request.parameters.next(AddressContent.self)
    }
    
    func update(_ request: Request, content: AddressContent)throws -> Future<AddressContent> {
        let id = try request.parameters.next(Address.ID.self)
        return content.update(id, on: self.connection)
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        let id = try request.parameters.next(Address.ID.self)
        let street = Street.query(on: self.connection).filter(\.id == id).delete()
        let address = Address.query(on: self.connection).filter(\.id == id).delete()
        
        return map(address, street) { _, _ in return HTTPStatus.noContent }
    }
}
