import Vapor

protocol AddressValidator: ServiceType {
    func validate(address: AddressContent) -> EventLoopFuture<Void>
}

extension AddressValidator {
    func validate(address: AddressContent) -> EventLoopFuture<AddressContent> {
        return self.validate(address: address).transform(to: address)
    }
}
