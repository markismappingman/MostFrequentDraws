///  DatabaseManager.swift

import Foundation
import GRDB

final class DatabaseManager {
	static let shared = DatabaseManager()
	private var dbQueue: DatabaseQueue!
	
	private init() {
		setupDatabase()
	}
	
	private func setupDatabase() {
		do {
			let fileManager = FileManager.default
			let folder = try fileManager.url(
				for: .documentDirectory,
				in: .userDomainMask,
				appropriateFor: nil,
				create: true
			)
			let dbURL = folder.appendingPathComponent("LotteryDraw.sqlite")
			
			var config = Configuration()
			config.qos = .userInitiated
			
			dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
			try createDefaultTables()
		} catch {
			fatalError("Failed to initialize SQLite database: \(error)")
		}
	}
	
	private func createDefaultTables() throws {
		try dbQueue.write { db in
			try db.execute(sql: """
    CREATE TABLE IF NOT EXISTS "lottery-numbers-powerball" (
    "playID" INTEGER PRIMARY KEY AUTOINCREMENT,
    "drawDate" DATETIME NOT NULL UNIQUE,
    "firstNum" INTEGER NOT NULL,
    "secondNum" INTEGER NOT NULL,
    "thirdNum" INTEGER NOT NULL,
    "fourthNum" INTEGER NOT NULL,
    "fifthNum" INTEGER NOT NULL,
    "powerBall" INTEGER NOT NULL
    );
    """)
			
			try db.execute(sql: """
    CREATE TABLE IF NOT EXISTS "user_saved_draws" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "title" TEXT NOT NULL,
    "firstNum" INTEGER NOT NULL,
    "secondNum" INTEGER NOT NULL,
    "thirdNum" INTEGER NOT NULL,
    "fourthNum" INTEGER NOT NULL,
    "fifthNum" INTEGER NOT NULL,
    "powerBall" INTEGER NOT NULL,
    "dateCreated" DATETIME NOT NULL
    );
    """)
		}
	}
	
	/// Generic method to add new game tables dynamic code-behind extension
	func createTable(named tableName: String) throws {
		try dbQueue.write { db in
			let sql = """
    CREATE TABLE IF NOT EXISTS "\(tableName)" (
    "playID" INTEGER PRIMARY KEY AUTOINCREMENT,
    "drawDate" DATETIME NOT NULL UNIQUE,
    "firstNum" INTEGER NOT NULL,
    "secondNum" INTEGER NOT NULL,
    "thirdNum" INTEGER NOT NULL,
    "fourthNum" INTEGER NOT NULL,
    "fifthNum" INTEGER NOT NULL,
    "powerBall" INTEGER NOT NULL
    );
    """
			try db.execute(sql: sql)
		}
	}
	
	func mostRecentDrawDate(in tableName: String) throws -> Date? {
		try dbQueue.read { db in
			let sql = "SELECT MAX(drawDate) FROM \"\(tableName)\""
			return try Date.fetchOne(db, sql: sql)
		}
	}
	
	func insertDraws(_ draws: [LotteryDraw], into tableName: String) throws {
		try dbQueue.write { db in
			for draw in draws {
				let sql = """
    INSERT OR IGNORE INTO "\(tableName)" 
    (drawDate, firstNum, secondNum, thirdNum, fourthNum, fifthNum, powerBall)
    VALUES (?, ?, ?, ?, ?, ?, ?);
    """
				try db.execute(
					sql: sql,
					arguments: [draw.drawDate, draw.firstNum, draw.secondNum, draw.thirdNum, draw.fourthNum, draw.fifthNum, draw.powerBall]
				)
			}
		}
	}
	
	/// Fetches top N most frequent main ball values across all 5 main columns combined
	func fetchTopMainBallFrequencies(in tableName: String, includePre2015: Bool, limit: Int = 5) throws -> [NumberFrequency] {
		try dbQueue.read { db in
			var dateFilter = ""
			var arguments: StatementArguments = []
			
			// Apply strict 2015 Matrix rules if the user has the toggle turned OFF
			if !includePre2015 {
				dateFilter = "WHERE \"drawDate\" >= ?"
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd"
				if let matrixDate = dateFormatter.date(from: "2015-10-04") {
					arguments = [matrixDate]
				}
			}
			
			// We use a CTE (WITH FilteredDraws AS...) to filter the dates BEFORE we run the UNION ALL
			let sql = """
    WITH FilteredDraws AS (
    SELECT * FROM "\(tableName)" \(dateFilter)
    )
    SELECT number_value AS number, COUNT(*) AS count
    FROM (
    SELECT "firstNum" AS number_value FROM FilteredDraws
    UNION ALL
    SELECT "secondNum" AS number_value FROM FilteredDraws
    UNION ALL
    SELECT "thirdNum" AS number_value FROM FilteredDraws
    UNION ALL
    SELECT "fourthNum" AS number_value FROM FilteredDraws
    UNION ALL
    SELECT "fifthNum" AS number_value FROM FilteredDraws
    )
    GROUP BY number_value
    ORDER BY count DESC, number ASC
    LIMIT \(limit);
    """
			let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
			return rows.map { row in
				NumberFrequency(number: row["number"], count: row["count"])
			}
		}
	}
	
	/// Fetches top N most frequent special ball (Powerball) values
	func fetchTopSpecialBallFrequencies(in tableName: String, includePre2015: Bool, limit: Int = 1) throws -> [NumberFrequency] {
		try dbQueue.read { db in
			var sql = """
    SELECT "powerBall" AS number, COUNT(*) AS count
    FROM "\(tableName)"
    """
			
			var arguments: StatementArguments = []
			
			// Apply strict 2015 Matrix rules if the user has the toggle turned OFF
			if !includePre2015 {
				sql += "\n WHERE \"drawDate\" >= ?"
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd"
				if let matrixDate = dateFormatter.date(from: "2015-10-04") {
					arguments = [matrixDate]
				}
			}
			
			sql += """
    \n GROUP BY "powerBall"
    ORDER BY count DESC, number ASC
    LIMIT \(limit);
    """
			
			let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
			return rows.map { row in
				NumberFrequency(number: row["number"], count: row["count"])
			}
		}
	}
	
	func saveUserCombination(_ combination: UserSavedCombination) throws {
		try dbQueue.write { db in
			// Make this var when adding new lottery draw games
			// var mutableCombo = combination
			let mutableCombo = combination
			try mutableCombo.insert(db)
		}
	}
	
	func fetchSavedCombinations() throws -> [UserSavedCombination] {
		try dbQueue.read { db in
			try UserSavedCombination.order(Column("dateCreated").desc).fetchAll(db)
		}
	}
	
	func deleteSavedCombination(id: Int64) throws {
		try dbQueue.write { db in
			_ = try UserSavedCombination.filter(Column("id") == id).deleteAll(db)
		}
	}
}
