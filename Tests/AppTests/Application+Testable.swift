import Vapor
@testable import App

extension Application {
    static func testable(env: Environment = .testing)throws -> Application {
        var services = Services.default()
        var environment = env
        var configuration = Config.default()
        
        try configure(&configuration, &environment, &services)
        let app = try Application(config: configuration, environment: environment, services: services)
        
        try App.boot(app)
        return app
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
