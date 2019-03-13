import Vapor

final class OptionsController: RouteCollection {
    init() {}
    
    func boot(router: Router) throws {
        let paths: [[PathComponent]: [HTTPMethod]] = Dictionary(grouping: router.routes) { route -> [PathComponent] in
            if route.path.count > 1 {
                return Array(route.path[1...])
            } else {
                return []
            }
        }.reduce(into: [:]) { result, components in
            result[components.key] = components.value.compactMap { route in
                guard case let .constant(method)? = route.path.first else {
                    return nil
                }
                
                return HTTPMethod(rawValue: method)
            }
        }
        
        paths.filter { !$0.value.contains(.OPTIONS) }.forEach { option in
            let (path, methods) = option
            router.on(.OPTIONS, at: path) { request -> Response in
                let response = request.response()
                response.http.headers.add(name: .allow, value: methods.map { $0.rawValue }.joined(separator: ", "))
                return response
            }
        }
    }
}

extension PathComponent: Hashable {
    public static func ==(lhs: PathComponent, rhs: PathComponent) -> Bool {
        switch (lhs, rhs) {
        case let (.constant(first), .constant(second)): return first == second
        case let (.parameter(first), .parameter(second)): return first == second
        case (.anything, .anything): return true
        case (.catchall, .catchall): return true
        default: return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .constant(component): hasher.combine("0\(component)")
        case let .parameter(component): hasher.combine("1\(component)")
        case .anything: hasher.combine(2)
        case .catchall: hasher.combine(3)
        }
    }
}

extension HTTPMethod: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "GET": self = .GET
        case "PUT": self = .PUT
        case "ACL": self = .ACL
        case "HEAD": self = .HEAD
        case "POST": self = .POST
        case "COPY": self = .COPY
        case "LOCK": self = .LOCK
        case "MOVE": self = .MOVE
        case "BIND": self = .BIND
        case "LINK": self = .LINK
        case "PATCH": self = .PATCH
        case "TRACE": self = .TRACE
        case "MKCOL": self = .MKCOL
        case "MERGE": self = .MERGE
        case "PURGE": self = .PURGE
        case "NOTIFY": self = .NOTIFY
        case "SEARCH": self = .SEARCH
        case "UNLOCK": self = .UNLOCK
        case "REBIND": self = .REBIND
        case "UNBIND": self = .UNBIND
        case "REPORT": self = .REPORT
        case "DELETE": self = .DELETE
        case "UNLINK": self = .UNLINK
        case "CONNECT": self = .CONNECT
        case "MSEARCH": self = .MSEARCH
        case "OPTIONS": self = .OPTIONS
        case "PROPFIND": self = .PROPFIND
        case "CHECKOUT": self = .CHECKOUT
        case "PROPPATCH": self = .PROPPATCH
        case "SUBSCRIBE": self = .SUBSCRIBE
        case "MKCALENDAR": self = .MKCALENDAR
        case "MKACTIVITY": self = .MKACTIVITY
        case "UNSUBSCRIBE": self = .UNSUBSCRIBE
        default: self = .RAW(value: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .GET: return "GET"
        case .PUT: return "PUT"
        case .ACL: return "ACL"
        case .HEAD: return "HEAD"
        case .POST: return "POST"
        case .COPY: return "COPY"
        case .LOCK: return "LOCK"
        case .MOVE: return "MOVE"
        case .BIND: return "BIND"
        case .LINK: return "LINK"
        case .PATCH: return "PATCH"
        case .TRACE: return "TRACE"
        case .MKCOL: return "MKCOL"
        case .MERGE: return "MERGE"
        case .PURGE: return "PURGE"
        case .NOTIFY: return "NOTIFY"
        case .SEARCH: return "SEARCH"
        case .UNLOCK: return "UNLOCK"
        case .REBIND: return "REBIND"
        case .UNBIND: return "UNBIND"
        case .REPORT: return "REPORT"
        case .DELETE: return "DELETE"
        case .UNLINK: return "UNLINK"
        case .CONNECT: return "CONNECT"
        case .MSEARCH: return "MSEARCH"
        case .OPTIONS: return "OPTIONS"
        case .PROPFIND: return "PROPFIND"
        case .CHECKOUT: return "CHECKOUT"
        case .PROPPATCH: return "PROPPATCH"
        case .SUBSCRIBE: return "SUBSCRIBE"
        case .MKCALENDAR: return "MKCALENDAR"
        case .MKACTIVITY: return "MKACTIVITY"
        case .UNSUBSCRIBE: return "UNSUBSCRIBE"
        case let .RAW(value: method): return method
        }
    }
}
