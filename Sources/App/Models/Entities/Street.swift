import FluentMySQL

final class Street {
    static let entity = "streets"
    
    var id: Int?
    let address: Address.ID
    
    var number: Int?
    var numberSuffix: String?
    var name: String?
    var type: String?
    var direction: Direction?
    
    init(number: Int?, numberSuffix: String?, name: String?, type: String?, direction: Direction?, address: Address.ID) {
        self.id = nil
        self.address = address
        
        self.number = number
        self.numberSuffix = numberSuffix
        self.name = name
        self.type = type
        self.direction = direction
    }
}

extension Street: Migration {
    static func prepare(on conn: MySQLDatabase.Connection) -> Future<Void> {
        return Database.create(Street.self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.address, to: \Address.id)
        }
    }
}
extension Street: MySQLModel { }
