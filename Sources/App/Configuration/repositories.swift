import Vapor

func setupRepositories(services: inout Services, config: inout Config) {
    services.register(MySQLAddressRepository.self)
    
    preferDatabases(config: &config)
}

private func preferDatabases(config: inout Config) {
    config.prefer(MySQLAddressRepository.self, for: AddressRepository.self)
}
