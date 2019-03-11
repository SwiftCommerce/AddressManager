import Vapor
import JSON

// MARK: - Protocol

protocol AddressValidator: ServiceType {
    func validate(address: AddressContent) -> EventLoopFuture<Void>
}

extension AddressValidator {
    func validate(address: AddressContent) -> EventLoopFuture<AddressContent> {
        return self.validate(address: address).transform(to: address)
    }
}

// MARK: - Implementation

final class GoogleMapsAddressValiadtor: AddressValidator {
    static func makeService(for container: Container) throws -> GoogleMapsAddressValiadtor {
        guard let key = Environment.get("GOOGLE_MAPS_API_KEY") else {
            throw Abort(.internalServerError, reason: "Missing `GOOGLE_MAPS_API_KEY` environment variable")
        }
        return try GoogleMapsAddressValiadtor(client: container.make(), key: key)
    }
    
    let client: Client
    let key: String
    
    init(client: Client, key: String) {
        self.client = client
        self.key = key
    }
    
    private func urlCode(for content: AddressContent)throws -> String {
        let street = [
            content.street?.number.map(String.init),
            content.buildingName,
            content.street?.numberSuffix,
            content.street?.name,
            content.street?.type,
            content.street?.direction?.rawValue
        ].compactMap { $0 }.joined(separator: "+")
        
        let query = [
            street,
            content.type,
            content.typeIdentifier,
            content.municipality,
            content.city,
            content.district,
            content.postalArea,
            content.country
        ].compactMap { $0 }.joined(separator: "+")
        
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest, reason: "Could not percent-encode URL query string: `\(query)`")
        }
        
        return encoded
    }
    
    func validate(address: AddressContent) -> EventLoopFuture<Void> {
        let url: String
        do {
            url = try "https://maps.googleapis.com/maps/api/geocode/json?address=\(self.urlCode(for: address))&key=\(self.key)"
        } catch let error {
            return self.client.container.future(error: error)
        }
        
        return self.client.get(url).map { response in
            
            // The error that will be thrown if validation fails.
            // We wrap it in a closure so it only gets initialized if we need it.
            let error = {
                return Abort(
                    .badRequest,
                    reason: "Unable to validate given address information",
                    identifier: "VALIDATION_FAILED"
                )
            }
            
            // Assert we got a valid response back.
            guard
                response.http.status == .ok,
                let data = response.http.body.data
            else {
                throw error()
            }
            let json = try JSONDecoder().decode(JSON.self, from: data)
            
            // Assert the geocoding resulted in actual locations
            guard case let .string(status)? = json["status"], status == "OK" else {
                throw error()
            }
            
            // Assert the address was percise and correct enough that:
            // 1. There is only one possible location it could be.
            // 2. The location is precise and not a generic region.
            guard
                case let .array(results)? = json["results"],
                results.count == 1,
                case let .object(geo)? = results.first?["geometry"],
                case let .string(locationType)? = geo["location_type"],
                LocationType(rawValue: locationType) != .approximate
            else {
                throw error()
            }
            
            // Validation succeeded. Return `Void` for success.
            return ()
        }
    }
}

extension GoogleMapsAddressValiadtor {
    enum LocationType: String {
        case rooftop = "ROOFTOP"
        case interpolation = "RANGE_INTERPOLATED"
        case geomatricCenter = "GEOMETRIC_CENTER"
        case approximate = "APPROXIMATE"
        
        var acurracy: Int {
            switch self {
            case .rooftop: return 0
            case .interpolation: return 1
            case .geomatricCenter: return 2
            case .approximate: return 3
            }
        }
    }
}
