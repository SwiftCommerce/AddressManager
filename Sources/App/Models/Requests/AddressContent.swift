import Vapor

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
    
    func urlEncoded(separator: String = "+")throws -> String {
        let street = [
            self.street?.number.map(String.init),
            self.buildingName,
            self.street?.numberSuffix,
            self.street?.name,
            self.street?.type,
            self.street?.direction?.rawValue
        ].compactMap { $0 }.joined(separator: separator)
        
        let query = [
            street,
            self.type,
            self.typeIdentifier,
            self.municipality,
            self.city,
            self.district,
            self.postalArea,
            self.country
        ].compactMap { $0 }.joined(separator: separator)
        
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest, reason: "Could not percent-encode URL query string: `\(query)`")
        }
        
        return encoded
    }
}
