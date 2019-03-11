import MySQL

extension MySQLDatabase {
    enum IsolationLevel: String {
        case repeatable = "REPEATABLE READ"
        case committed = "READ COMMITTED"
        case uncommitted = "READ UNCOMMITTED"
        case serializable = "SERIALIZABLE"
        
        static let `default`: IsolationLevel = .repeatable
        static let sessionColumn: String = "@@session.transaction_isolation"
        
        static func parse(_ level: String) -> IsolationLevel? {
            switch level {
            case "REPEATABLE-READ": return .repeatable
            case "READ-COMMITTED": return .committed
            case "READ-UNCOMMITTED": return .uncommitted
            case "SERIALIZABLE": return .serializable
            default: return nil
            }
        }
        
        static func current(from conn: MySQLConnection) -> EventLoopFuture<MySQLDatabase.IsolationLevel> {
            let sessionColumn = MySQLDatabase.IsolationLevel.sessionColumn
            return conn.simpleQuery("SELECT " + sessionColumn).map { data in
                let raw = data.first?[.init(name: sessionColumn)]?.string()
                
                guard let string = raw, let level = MySQLDatabase.IsolationLevel.parse(string) else {
                    throw MySQLError(
                        identifier: "unknowIsolationLevel",
                        reason: "Received unknown MySQL isolation level `\(raw ?? "NULL")` from database"
                    )
                }
                
                return level
            }
        }
        
        var query: String {
            return "SET GLOBAL TRANSACTION ISOLATION LEVEL " + self.rawValue
        }
    }
}

extension DatabaseConnectable {
    func transaction<T>(
        on db: DatabaseIdentifier<MySQLDatabase>,
        level: MySQLDatabase.IsolationLevel,
        _ closure: @escaping (MySQLConnection)throws -> Future<T>
    ) -> Future<T>
    {
        return databaseConnection(to: db).flatMap { conn in
            return MySQLDatabase.IsolationLevel.current(from: conn).flatMap { sessionLevel in
                return conn.simpleQuery(level.query).transform(to: sessionLevel)
            }.flatMap { sessionLevel in
                return conn.simpleQuery("START TRANSACTION").transform(to: sessionLevel)
            }.flatMap { sessionLevel in
                return try closure(conn).flatMap { result in
                    return conn.simpleQuery("COMMIT").transform(to: result)
                }.flatMap { result in
                    return conn.simpleQuery(sessionLevel.query).transform(to: result)
                }.catchFlatMap { error in
                    return conn.simpleQuery("ROLLBACK").flatMap { _ in
                        return conn.simpleQuery(sessionLevel.query)
                    }.map { _ in
                        throw error
                    }
                }
            }
        }
    }
}
