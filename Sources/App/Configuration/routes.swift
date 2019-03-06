import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    router.get(any, "addresses", "health") { request in
        return "All good!"
    }
}
