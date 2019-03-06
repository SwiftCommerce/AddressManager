import FluentMySQL

func databases(config: inout DatabasesConfig, env: Environment)throws {
    let mysqlConfig = MySQLDatabaseConfig(
        hostname: Environment.get("DATABASE_HOSTNAME") ?? "localhost",
        port: Int(Environment.get("DATABASE_POST") ?? "3306") ?? 3306,
        username: Environment.get("DATABASE_USER") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_DB") ?? "address_manager",
        transport: env.isRelease ? .cleartext : .unverifiedTLS
    )
    let mysql = MySQLDatabase(config: mysqlConfig)
    config.add(database: mysql, as: .mysql)
}
