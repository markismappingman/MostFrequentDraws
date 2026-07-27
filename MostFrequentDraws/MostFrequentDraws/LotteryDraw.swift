/// LotteryDraw.swift

import Foundation
import GRDB

/// Database record mapping to lottery draw tables.
struct LotteryDraw: Codable, FetchableRecord, PersistableRecord, Identifiable {
	var playID: Int64?
	var drawDate: Date
	var firstNum: Int
	var secondNum: Int
	var thirdNum: Int
	var fourthNum: Int
	var fifthNum: Int
	var powerBall: Int
	
	// Conformance for SwiftUI's Identifiable protocol
	var id: Int64? { playID }
	
	static var databaseTableName: String { "lottery-numbers-powerball" }
	
	enum CodingKeys: String, CodingKey, ColumnExpression {
		case playID
		case drawDate
		case firstNum
		case secondNum
		case thirdNum
		case fourthNum
		case fifthNum
		case powerBall
	}
}

/// Structure representing computed number frequency occurrences.
struct NumberFrequency: Identifiable, Hashable {
	var id: Int { number }
	let number: Int
	let count: Int
}

/// Model representing user-created or randomly generated saved bet slips.
struct UserSavedCombination: Codable, FetchableRecord, PersistableRecord, Identifiable {
	var id: Int64?
	var title: String
	var firstNum: Int
	var secondNum: Int
	var thirdNum: Int
	var fourthNum: Int
	var fifthNum: Int
	var powerBall: Int
	var dateCreated: Date
	
	static var databaseTableName: String { "user_saved_draws" }
	
	var sortedMainNumbers: [Int] {
		[firstNum, secondNum, thirdNum, fourthNum, fifthNum].sorted()
	}
}
