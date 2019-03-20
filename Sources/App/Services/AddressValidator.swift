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

final class SmartyStreetAddressValidator: AddressValidator {
    static func makeService(for container: Container) throws -> SmartyStreetAddressValidator {
        guard
            let token = Environment.get("SMARTY_STREET_API_TOKEN"),
            let id = Environment.get("SMARTY_STREET_API_ID")
        else {
            throw Abort(.internalServerError, reason: "Missing `SMARTY_STREET_API_TOKEN` or `SMARTY_STREET_API_ID` env var")
        }
        
        return try SmartyStreetAddressValidator(client: container.make(), token: token, id: id)
    }
    
    let supportInternational: Bool
    let client: Client
    
    private let internationalAPI: String
    private let unitedStatesAPI: String
    
    init(client: Client, token: String, id: String) {
        self.supportInternational = Environment.get("ADDRESS_SUPPORT_INTERNATIONAL").flatMap(Bool.init) ?? false
        self.client = client
        
        self.internationalAPI = "https://international-street.api.smartystreets.com/verify?auth-id=\(id)&auth-token=\(token)"
        self.unitedStatesAPI = "https://us-street.api.smartystreets.com/street-address?auth-id=\(id)&auth-token=\(token)"
    }
    
    func validate(address: AddressContent) -> EventLoopFuture<Void> {
        if
            ["united states", "us", "usa", "united states of america"].contains(address.country?.lowercased()) ||
            address.country == nil
        {
            return self.unitedStates(address: address)
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
            
            return self.international(address: address)
        }
    }
    
    private func unitedStates(address: AddressContent) -> EventLoopFuture<Void> {
        let query: String
        do {
            let address2 = { () -> String? in
                let address = [address.type, address.typeIdentifier].compactMap { $0 }.joined(separator: "+")
                return address == "" ? nil : address
            }
            let parameters: [String: String?] = try [
                "street": address.encodedStreet(separator: " "),
                "secondary": address2(),
                "city": address.city,
                "state": address.district,
                "zipcode": address.postalArea,
                "match": "strict"
            ]
            query = parameters.reduce(into: []) { query, parameter in
                if let value = parameter.value {
                    query.append("\(parameter.key)=\(value)")
                }
            }.joined(separator: "&")
        } catch let error {
            return self.client.container.future(error: error)
        }
        
        return self.client.get(self.unitedStatesAPI + (query == "" ? "" : "?" + query)).map { response in
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
                    message = "The maximum size for a request body to this API is 32K (32,768 bytes)."
                case .tooManyRequests:
                    message =
                        "When using public \"website key\" authentication, we restrict the number of requests coming from " +
                        "a given source over too short of a time. If you use \"website key\" authentication, you can " +
                        "avoid this error by adding your IP address as an authorized host for the website key in question."
                default: message = "Got unexpected status code `\(status)` from SmartyStreet API"
                }
                throw Abort(.failedDependency, reason: "\(status): \(message)")
            }
            
            /// Verify the response wasn't an empty array.
            // We do this by making sure the response body doesn't consist of a
            // single opening bracket and single closing bracket.
            guard let data = response.http.body.data, data != Data([91, 93]) else {
                throw Abort(.badRequest, reason: "Unable to validate given address")
            }
            
            // Make sure the verification status of the response is `Verified`.
            guard
                case let .array(address) = try JSON(data: data),
                case let .object(analysis)? = try address.first?.element(at: ["analysis"]),
                analysis["dpv_match_code"] == .string("Y")
            else {
                throw Abort(.badRequest, reason: "Unable to validate given address")
            }
        }
    }
    
    private func international(address: AddressContent) -> EventLoopFuture<Void> {
        let query: String
        do {
            let address2 = { () -> String? in
                let address = [address.type, address.typeIdentifier].compactMap { $0 }.joined(separator: "+")
                return address == "" ? nil : address
            }
            let locality = { () -> String? in
                let locality = [address.municipality, address.city].compactMap { $0 }.joined(separator: "+")
                return locality == "" ? nil : locality
            }
            let parameters: [String: String?] = try [
                "address1": address.encodedString(),
                "address2": address2(),
                "country": address.country,
                "locality": locality(),
                "administrative_area": address.district,
                "postal_code": address.postalArea
            ]
            query = parameters.reduce(into: "") { query, parameter in
                if let value = parameter.value {
                    query.append("&\(parameter.key)=\(value)")
                }
            }
        } catch let error {
            return self.client.container.future(error: error)
        }
        
        return self.client.get(self.internationalAPI + (query == "" ? "" : "?" + query)).map { response in
            
            // Make sure we get a valid response back from SmartyStreet.
            let status = response.http.status
            guard status == .ok else {
                let message: String
                switch status {
                case .unauthorized:
                    message = "The credentials were provided incorrectly or did not match any existing, active credentials."
                case .paymentRequired:
                    message =
                        "There is no active subscription for the account associated with the " +
                        "credentials submitted with the request."
                case .forbidden:
                    message =
                        "Because the international service is currently in a limited release phase, only approved accounts " +
                        "may access the service. Please contact us for your account to be granted access."
                case .badRequest:
                    message = "Inputs from the request could not be interpreted."
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
                default:
                    message = "Got unexpected status code `\(status)` from SmartyStreet API"
                }
                
                throw Abort(.failedDependency, reason: "\(status): \(message)")
            }
            
            // Verify the response wasn't an empty array.
            // We do this by making sure the response body doesn't consist of a
            // single opening bracket and single closing bracket.
            guard let data = response.http.body.data, data != Data([91, 93]) else {
                throw Abort(.badRequest, reason: "Unable to validate given address")
            }
            
            // Make sure the verification status of the response is `Verified`.
            guard
                case let .array(address) = try JSON(data: data),
                case let .object(analysis)? = try address.first?.element(at: ["analysis"]),
                analysis["verification_status"] == .string("Verified")
            else {
                throw Abort(.badRequest, reason: "Unable to validate given address")
            }
        }
    }
}
