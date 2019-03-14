@testable import App
import XCTest
import Vapor

final class OptionsControllerTests: XCTestCase {
    func testRouteGeneration()throws {
        let router = EngineRouter(caseInsensitive: false)
        
        router.get("one", use: handler)
        router.post("one", use: handler)
        router.delete("one", use: handler)
        
        router.patch("one", "two", Param.parameter, use: handler)
        router.put("one", "two", Param.parameter, use: handler)
        router.post("one", "two", Param.parameter, use: handler)
        router.on(.HEAD, at: "one", "two", Param.parameter, use: handler)
        
        router.get("three", "one", "four", use: handler)
        router.post("three", "one", "four", use: handler)
        router.on(.OPTIONS, at: "three", "one", "four", use: handler)
        
        try OptionsController().boot(router: router)
        
        XCTAssertEqual(
            router.routes.count { $0.path == ["OPTIONS", "one"].convertToPathComponents() },
            1
        )
        XCTAssertEqual(
            router.routes.count { $0.path == ["OPTIONS", "one", "two", Param.parameter].convertToPathComponents() },
            1
        )
        XCTAssertEqual(
            router.routes.count { $0.path == ["OPTIONS", "three", "one", "four"].convertToPathComponents() },
            1
        )
    }
    
    func handler(_ request: Request) -> Response {
        return request.response()
    }
}

struct Param: Parameter {
    static func resolveParameter(_ parameter: String, on container: Container) throws -> String {
        return parameter
    }
}
