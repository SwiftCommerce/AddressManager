import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, _ container: Container) throws {
    router.get(any, "addresses", "health") { request in
        return "All good!"
    }
    
    try router.register(collection: AddressController(repository: container.make()))
}
