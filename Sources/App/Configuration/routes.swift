import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, _ container: Container) throws {
    router.get(any, "addresses", "health") { request in
        return "All good!"
    }
    
    let addresses = try AddressController(
        repository: container.make(),
        validator: container.make(),
        parser: container.make()
    )
    try router.register(collection: addresses)
}
