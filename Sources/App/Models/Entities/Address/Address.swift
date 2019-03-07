import FluentMySQL

// https://stackoverflow.com/questions/1159756/how-should-international-geographical-addresses-be-stored-in-a-relational-databa/1160031#1160031
final class Address {
    static let name = "addresses"
    
    var id: Int?
    
    var buildingName: String?
    var typeIdentifier: String?
    var type: String?
    var municipality: String?
    var city: String?
    var district: String?
    var postalArea: String?
    var country: String?
    
    init(
        buildingName: String?,
        typeIdentifier: String?,
        type: String?,
        municipality: String?,
        city: String?,
        district: String?,
        postalArea: String?,
        country: String?
    ) {
        self.id = nil
        
        self.buildingName = buildingName
        self.typeIdentifier = typeIdentifier
        self.type = type
        self.municipality = municipality
        self.city = city
        self.district = district
        self.postalArea = postalArea
        self.country = country
    }
}

extension Address: Migration { }
extension Address: MySQLModel { }
