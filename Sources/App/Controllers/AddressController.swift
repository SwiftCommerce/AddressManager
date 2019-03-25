import Vapor
import Fluent
import JSONKit

final class AddressController: RouteCollection {
    let repository: AddressRepository
    let validator: AddressValidator
    let parser: AddressParser
    
    init(repository: AddressRepository, validator: AddressValidator, parser: AddressParser) {
        self.repository = repository
        self.validator = validator
        self.parser = parser
    }
    
    func boot(router: Router) throws {
        let addresses = router.grouped(any, "addresses")
        
        // CRUD
        addresses.post(AddressContent.self, use: create)
        addresses.get(Address.parameter, use: read)
        addresses.patch(JSON.self, at: Address.parameter, use: update)
        addresses.delete(Address.parameter, use: delete)
        
        // Helpers
        addresses.post(AddressContent.self, at: "validate", use: validate)
        addresses.post(AddressData.self, at: "parse", use: parse)
    }
    
    
    func create(_ request: Request, content: AddressContent)throws -> EventLoopFuture<AddressContent> {
        return self.repository.create(address: content)
    }
    
    func read(_ request: Request)throws -> EventLoopFuture<AddressContent> {
        return try self.repository.find(address: request.addressID()).unwrap(or: Abort(.notFound))
    }
    
    func update(_ request: Request, content: JSON)throws -> EventLoopFuture<AddressContent> {
        return try self.repository.update(address: request.addressID(), with: content).unwrap(or: Abort(.notFound))
    }
    
    func delete(_ request: Request)throws -> EventLoopFuture<HTTPStatus> {
        return try self.repository.delete(address: request.addressID()).transform(to: .noContent)
    }
    
    
    func validate(_ request: Request, content: AddressContent)throws -> EventLoopFuture<HTTPStatus> {
        return self.validator.validate(address: content).transform(to: .ok)
    }
    
    func parse(_ request: Request, content: AddressData)throws -> EventLoopFuture<AddressContent> {
        return self.parser.parse(content)
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
