import Vapor
import Fluent

struct AddressContent: Content {
    var id: Int?
    var buildingName: String?
    var typeIdentifier: String?
    var type: String?
    var municipality: String?
    var city: String?
    var district: String?
    var postalArea: String?
    var country: String?
    var street: StreetContent?
}
