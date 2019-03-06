import FluentMySQL

enum Direction: String, CaseIterable, MySQLEnumType {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
    case northEast = "NE"
    case northWest = "NW"
    case southEast = "SE"
    case southWest = "SW"
}
