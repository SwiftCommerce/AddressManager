import Vapor
import FluentMySQL

final class AddressController: RouteCollection {
    let repository: AddressRepository
    let validator: AddressValidator
    
    init(repository: AddressRepository, validator: AddressValidator) {
        self.repository = repository
        self.validator = validator
    }
    
    func boot(router: Router) throws {
        let addresses = router.grouped(any, "addresses")
        
        addresses.post(AddressContent.self, use: create)
        addresses.get(Address.parameter, use: read)
        addresses.patch(AddressContent.self, at: Address.parameter, use: update)
        addresses.delete(Address.parameter, use: delete)
    }
    
    func create(_ request: Request, content: AddressContent)throws -> Future<AddressContent> {
        return self.repository.create(address: content)
    }
    
    func read(_ request: Request)throws -> Future<AddressContent> {
        return try self.repository.find(address: request.addressID()).unwrap(or: Abort(.notFound))
    }
    
    func update(_ request: Request, content: AddressContent)throws -> Future<AddressContent> {
        return try self.repository.update(address: request.addressID(), with: content).unwrap(or: Abort(.notFound))
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return try self.repository.delete(address: request.addressID()).transform(to: .noContent)
    }
}

extension Request {
    fileprivate func addressID()throws -> Address.ID {
        guard let raw = self.parameters.rawValues(for: Address.self).first, let id = Address.ID(raw) else {
            throw Abort(.badRequest, reason: "`:address` URL request parameter must be convertible to `int`")
        }
        
        return id
    }
}
