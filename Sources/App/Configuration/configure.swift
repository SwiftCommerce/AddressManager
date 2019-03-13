import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentMySQLProvider())
    
    // Register routes to the router
    services.register(Router.self) { container -> EngineRouter in
        let router = EngineRouter.default()
        try routes(router, container)
        return router
    }
    
    // Register middleware
    var middlewares = MiddlewareConfig()
    middlewares.use(CORSMiddleware())
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)

    // Register the configured databases to the database config.
    var databasesConfig = DatabasesConfig()
    try databases(config: &databasesConfig, env: env)
    services.register(databasesConfig)

    // Configure migrations
    var migrationsConfig = MigrationConfig()
    try migrations(config: &migrationsConfig)
    services.register(migrationsConfig)
    
    // Add repository models to services
    setupRepositories(services: &services, config: &config)
    
    // Regiaster the address validation service used by the `AddressController`.
    services.register(AddressValidator.self, factory: GoogleMapsAddressValiadtor.makeService)
}
