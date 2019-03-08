import Vapor
@testable import App

extension Application {
    static func testable(
        env: Environment = .testing,
        config: Config = Config.default(),
        services: Services = Services.default()
    )throws -> Application {
        var services = services
        var environment = env
        var configuration = config
        
        try configure(&configuration, &environment, &services)
        let app = try Application(config: configuration, environment: environment, services: services)
        
        try App.boot(app)
        return app
    }
    
    func response(for http: HTTPRequest)throws -> Response {
        let responder = try self.make(Responder.self)
        let request = Request(http: http, using: self)
        
        return try responder.respond(to: request).wait()
    }
    
    func response<D>(for http: HTTPRequest, as decodable: D)throws -> D where D: Decodable {
        return try self.response(for: http).content.decode(D.self).wait()
    }
}

func caseStart(_ file: String = #file, _ function: String = #function) {
    let suite = file.split(separator: "/").last?.split(separator: ".").first.map(String.init) ?? "<null>"
    print("Test Case '-[AppTests.\(suite) \(function)]' started")
}

func caseComplete(_ file: String = #file, _ function: String = #function) {
    let suite = file.split(separator: "/").last?.split(separator: ".").first.map(String.init) ?? "<null>"
    print("Test Case '-[AppTests.\(suite) \(function)]' complete")
}
