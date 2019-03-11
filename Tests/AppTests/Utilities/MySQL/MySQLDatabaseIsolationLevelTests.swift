@testable import App
import XCTest
import Vapor
import MySQL

final class MySQLDatabaseIsolationLevelTests: XCTestCase {
    typealias IsolationLevel = MySQLDatabase.IsolationLevel
    
    func testCases() {
        XCTAssertEqual(IsolationLevel.repeatable.rawValue, "REPEATABLE READ")
        XCTAssertEqual(IsolationLevel.committed.rawValue, "READ COMMITTED")
        XCTAssertEqual(IsolationLevel.uncommitted.rawValue, "READ UNCOMMITTED")
        XCTAssertEqual(IsolationLevel.serializable.rawValue, "SERIALIZABLE")
        XCTAssertEqual(IsolationLevel.default, .repeatable)
    }
    
    func testQuery() {
        XCTAssertEqual(
            IsolationLevel.repeatable.query,
            "SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ"
        )
        XCTAssertEqual(
            IsolationLevel.committed.query,
            "SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED"
        )
        XCTAssertEqual(
            IsolationLevel.uncommitted.query,
            "SET GLOBAL TRANSACTION ISOLATION LEVEL READ UNCOMMITTED"
        )
        XCTAssertEqual(
            IsolationLevel.serializable.query,
            "SET GLOBAL TRANSACTION ISOLATION LEVEL SERIALIZABLE"
        )
    }
    
    func testParse() {
        XCTAssertEqual(IsolationLevel.parse("REPEATABLE-READ"), .repeatable)
        XCTAssertEqual(IsolationLevel.parse("REPEATABLE READ"), .repeatable)
        XCTAssertEqual(IsolationLevel.parse("READ-COMMITTED"), .committed)
        XCTAssertEqual(IsolationLevel.parse("READ COMMITTED"), .committed)
        XCTAssertEqual(IsolationLevel.parse("READ-UNCOMMITTED"), .uncommitted)
        XCTAssertEqual(IsolationLevel.parse("READ UNCOMMITTED"), .uncommitted)
        XCTAssertEqual(IsolationLevel.parse("SERIALIZABLE"), .serializable)
        
        XCTAssertNil(IsolationLevel.parse("REPEATABLE"))
        XCTAssertNil(IsolationLevel.parse("COMMITTED"))
        XCTAssertNil(IsolationLevel.parse("UNCOMMITTED"))
    }
    
    func testCurrent()throws {
        let app = try Application.testable()
        let pool = try app.connectionPool(to: .mysql)
        let connection = try pool.requestConnection().wait()
        defer { pool.releaseConnection(connection) }
        
        try XCTAssertNoThrow(IsolationLevel.current(from: connection).wait())
    }
    
    func testIsolatedTransaction()throws {
        let app = try Application.testable()
        let pool = try app.connectionPool(to: .mysql)
        let connection = try pool.requestConnection().wait()
        defer { pool.releaseConnection(connection) }
        
        let level = try IsolationLevel.current(from: connection).wait()
        let transactionLevel: IsolationLevel
        switch level {
        case .repeatable: transactionLevel = .committed
        case .committed: transactionLevel = .uncommitted
        case .uncommitted: transactionLevel = .serializable
        case .serializable: transactionLevel = .repeatable
        }
        
        let usedLevel = try connection.transaction(on: .mysql, level: transactionLevel) { transaction in
            return IsolationLevel.current(from: transaction)
        }.wait()
        
        XCTAssertEqual(usedLevel, transactionLevel)
        try XCTAssertEqual(IsolationLevel.current(from: connection).wait(), level)
    }
    
    static let allTests = [
        ("testCases", testCases),
        ("testQuery", testQuery),
        ("testParse", testParse),
        ("testCurrent", testCurrent),
        ("testIsolatedTransaction", testIsolatedTransaction)
    ]
}
