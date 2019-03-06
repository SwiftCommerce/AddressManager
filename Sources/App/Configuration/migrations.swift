import Fluent

func migrations(config: inout MigrationConfig)throws {
    config.add(migration: Street.self, database: .mysql)
    config.add(migration: Address.self, database: .mysql)
}
