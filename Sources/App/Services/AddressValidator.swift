import Service

// MARK: - Protocol

protocol AddressValidator: ServiceType {
    func validate(address: AddressContent) -> EventLoopFuture<Void>
}

extension AddressValidator {
    func validate(address: AddressContent) -> EventLoopFuture<AddressContent> {
        return self.validate(address: address).transform(to: address)
    }
}

// MARK: - Implementation

final class EmptyAddressValidator: AddressValidator {
    static func makeService(for container: Container) throws -> EmptyAddressValidator {
        return EmptyAddressValidator(worker: container)
    }
    
    let worker: Worker
    
    init(worker: Worker) {
        self.worker = worker
    }
    
    func validate(address: AddressContent) -> EventLoopFuture<Void> {
        return self.worker.future()
    }
}
