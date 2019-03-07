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
    
    init(address: Address, street: Street?) {
        self.id = address.id
        self.buildingName = address.buildingName
        self.typeIdentifier = address.typeIdentifier
        self.type = address.type
        self.municipality = address.municipality
        self.city = address.city
        self.district = address.district
        self.postalArea = address.postalArea
        self.country = address.country
        
        if let st = street {
            self.street = StreetContent(
                id: st.id,
                number: st.number,
                numberSuffix: st.numberSuffix,
                name: st.name,
                type: st.type,
                direction: st.direction
            )
        } else {
            self.street = nil
        }
    }
}
