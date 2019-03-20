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
    
    func encodedStreet(separator: String = "+")throws -> String? {
        guard let street = self.street else {
            return nil
        }
        
        let components = [
            self.buildingName,
            street.number.map(String.init),
            street.numberSuffix,
            street.name,
            street.type,
            street.direction?.rawValue
        ].compactMap { $0 }.joined(separator: separator)
        
        guard let encoded = components.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest, reason: "Could not percent-encode URL query string: `\(street)`")
        }
        
        return encoded
    }
    
    func urlEncoded(separator: String = "+")throws -> String {
        let query = [
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
        
        if let street = try self.encodedStreet() {
            return street + separator + encoded
        } else {
            return encoded
        }
    }
}
