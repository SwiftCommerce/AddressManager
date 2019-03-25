import Vapor
import JSON

// MARK: - Protocol

struct AddressData: Content {
    let country: String
    let data: String
}

protocol AddressParser: ServiceType {
    func parse(_ data: AddressData) -> EventLoopFuture<AddressContent>
}

// MARK: - Implementation

final class SmartyStreetAddressParser: AddressParser {
    static func makeService(for container: Container) throws -> SmartyStreetAddressParser {
        guard
            let token = Environment.get("SMARTY_STREET_API_TOKEN"),
            let id = Environment.get("SMARTY_STREET_API_ID")
            else {
                throw Abort(.internalServerError, reason: "Missing `SMARTY_STREET_API_TOKEN` or `SMARTY_STREET_API_ID` env var")
        }
        
        return try SmartyStreetAddressParser(client: container.make(), token: token, id: id)
    }
    
    let supportInternational: Bool
    let client: Client
    
    private let internationalAPI: String
    private let unitedStatesAPI: String
    
    init(client: Client, token: String, id: String) {
        self.supportInternational = Environment.get("ADDRESS_SUPPORT_INTERNATIONAL").flatMap(Bool.init) ?? false
        self.client = client
        
        self.internationalAPI = "https://international-street.api.smartystreets.com/verify?auth-id=\(id)&auth-token=\(token)"
        self.unitedStatesAPI = "https://us-extract.api.smartystreets.com?auth-id=\(id)&auth-token=\(token)&html=false"
    }
    
    func parse(_ data: AddressData) -> EventLoopFuture<AddressContent> {
        if ["united states", "us", "usa", "united states of america"].contains(data.country.lowercased()) {
            return self.unitedStates(data.data)
        } else {
            guard self.supportInternational else {
                let error = Abort(
                    .badRequest,
                    reason: "The service was not registered to handle international addresses",
                    suggestedFixes: [
                        "Set the `ADDRESS_SUPPORT_INTERNATIONAL` environment variable to `true`",
                        "Make sure you have signed up for the SmartyStreet International Address API"
                    ]
                )
                return self.client.container.future(error: error)
            }
            
            return self.international(data.data, forCountry: data.country)
        }
    }
    
    private func unitedStates(_ string: String) -> EventLoopFuture<AddressContent> {
        let request = Request(http: HTTPRequest(method: .POST, url: self.unitedStatesAPI), using: self.client.container)
        do {
            try request.content.encode(string, as: .plainText)
        } catch let error {
            return self.client.container.future(error: error)
        }
        
        return self.client.send(request).map { response in
            let status = response.http.status
            guard status == .ok else {
                let message: String
                switch status {
                case .badRequest:
                    message =
                        "A GET request lacked a street field, or the request body of a POST request contained malformed " +
                        "JSON. (example: submitting an integer value in the ZIP Code field when a string is expected)"
                case .unauthorized:
                    message = "The credentials were provided incorrectly or did not match any existing, active credentials."
                case .paymentRequired:
                    message =
                        "There is no active subscription for the account associated with the credentials " +
                        "submitted with the request."
                case .payloadTooLarge:
                    message = "The request body was larger than 64 Kilobytes."
                case .tooManyRequests:
                    message =
                        "When using public \"website key\" authentication, we restrict the number of requests coming from " +
                        "a given source over too short of a time. If you use \"website key\" authentication, you can " +
                        "avoid this error by adding your IP address as an authorized host for the website key in question."
                default: message = "Got unexpected status code `\(status)` from SmartyStreet API"
                }
                throw Abort(.failedDependency, reason: "(API \(status)) \(message)")
            }
            
            guard let json = try response.http.body.data.map(JSON.init(data:)) else {
                throw Abort(.failedDependency, reason: "Received invalid data from service dependency")
            }
            guard json.meta.address_count.int == 1 else {
                throw Abort(
                    .badRequest,
                    reason: "Found more or less than 1 address in parsed results. Unable to disambiguate results."
                )
            }
            guard let address = json.addresses.0.api_output.optional else {
                throw Abort(.badRequest, reason: "Unable to parse given address information.")
            }
            
            let secondaryData = { () -> SecondaryAddressData in
                var data = SecondaryAddressData(
                    streetNumber: .null,
                    streetName: .null,
                    type: .null,
                    typeIdentifier: .null,
                    buildingName: .null
                )
                
                // According to the USPS, `P.O. Box` is a street name.
                // We are storing `P.O. Box` information in the address `type` and `typeIdentifier`.
                switch address.components.street_name {
                case .string("PO Box"):
                    data.type = address.components.street_name
                    data.typeIdentifier = address.components.primary_number
                default:
                    data.streetName = address.components.street_name
                    data.streetNumber = address.components.primary_number
                }
                
                switch address.components.secondary_designator {
                case .string("Bldg"):
                    data.buildingName = address.components.secondary_number
                default:
                    data.type = address.components.secondary_designator
                    data.typeIdentifier = address.components.secondary_number
                }
                
                return data
            }()
            
            let number = address.components.primary_number.string.map(self.streetNumber)
            return AddressContent(
                id: nil,
                buildingName: secondaryData.buildingName.string,
                typeIdentifier: secondaryData.typeIdentifier.string,
                type: secondaryData.type.string,
                municipality: address.components.urbanization.string,
                city: address.components.city_name.string ?? address.components.default_city_name.string,
                district: address.components.state_abbreviation.string,
                postalArea: address.components.zipcode.string,
                country: "United States",
                street: StreetContent(
                    id: nil,
                    number: number?.number,
                    numberSuffix: number?.suffix,
                    name: secondaryData.streetName.string,
                    type: address.components.street_suffix.string,
                    direction: address.components.street_predirection.string.flatMap(Direction.init(rawValue:))
                )
            )
        }
    }
    
    private func international(_ string: String, forCountry country: String) -> EventLoopFuture<AddressContent> {
        let url = "\(self.internationalAPI)&freeform=\(string)&country=\(country)"
        
        return self.client.get(url).map { response -> AddressContent in
            let status = response.http.status
            guard status == .ok else {
                let message: String
                switch status {
                case .badRequest:
                    message = "Inputs from the request could not be interpreted."
                case .unauthorized:
                    message = "The credentials were provided incorrectly or did not match any existing, active credentials."
                case .paymentRequired:
                    message =
                        "There is no active subscription for the account associated with the credentials " +
                        "submitted with the request."
                case .forbidden:
                    message =
                        "Because the international service is currently in a limited release phase, only approved " +
                        "accounts may access the service. Please contact us for your account to be granted access."
                case .unprocessableEntity:
                    message = "A GET request lacked required fields."
                case .tooManyRequests:
                    message =
                        "Too many requests with exactly the same input values were submitted within too short a period. " +
                        "This status code conveys that the input was not processed in order to prevent runaway charges " +
                        "caused by such conditions as a misbehaving (infinite) loop sending the same record over and " +
                        "over to the API. You're welcome."
                case .gatewayTimeout:
                    message =
                        "Our own upstream data provider did not respond in a timely fashion and the request failed. " +
                        "A serious, yet rare occurrence indeed."
                default: message = "Got unexpected status code `\(status)` from SmartyStreet API"
                }
                
                throw Abort(.failedDependency, reason: "(API \(status)) \(message)")
            }
            
            guard let json = try response.http.body.data.map(JSON.init(data:)) else {
                throw Abort(.failedDependency, reason: "Received invalid data from service dependency")
            }
            guard json.array?.count == 1 else {
                throw Abort(
                    .badRequest,
                    reason: "Found more or less than 1 address in parsed results. Unable to disambiguate results."
                )
            }
            guard let address = json.array?.first?.components else {
                throw Abort(.badRequest, reason: "Unable to parse given address information.")
            }
            
            let typeIdentifier =
                address.building_name.string ??
                address.sub_building_number.string ??
                address.sub_building_name.string ??
                address.post_box_number.string
            let type =
                address.building_leading_type.string ??
                address.building_trailing_type.string ??
                address.sub_building_type.string ??
                address.post_box_type.string
            
            let number = address.premise_number.string.map(self.streetNumber)
            return AddressContent(
                id: nil,
                buildingName: address.building.string,
                typeIdentifier: typeIdentifier,
                type: type,
                municipality: address.dependent_locality_name.string,
                city: address.locality.string,
                district: address.administrative_area.string,
                postalArea: address.postal_code.string,
                country: country,
                street: StreetContent(
                    id: nil,
                    number: number?.number,
                    numberSuffix: number?.suffix,
                    name: address.thoroughfare_name.string,
                    type: address.thoroughfare_type.string ?? address.thoroughfare_trailing_type.string,
                    direction:
                        (address.thoroughfare_predirection.string ??
                        address.thoroughfare_postdirection.string).flatMap(Direction.init(rawValue:))
                )
            )
        }
    }
    
    private func streetNumber(_ number: String) -> (number: Int?, suffix: String?) {
        let elements = number.split(separator: " ").map(String.init)
        return (elements.first.flatMap(Int.init), elements.last)
    }
    
    struct SecondaryAddressData {
        var streetNumber: JSON
        var streetName: JSON
        var type: JSON
        var typeIdentifier: JSON
        var buildingName: JSON
    }
}
