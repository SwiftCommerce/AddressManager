import Vapor
import Fluent

struct StreetContent: Content {
    var id: Int?
    var number: Int?
    var numberSuffix: String?
    var name: String?
    var type: String?
    var direction: Direction?
}
