///  LotteryAPIService.swift

import Foundation

enum NetworkError: Error {
	case invalidURL
	case invalidResponse
	case decodingError
}

final class LotteryAPIService {
	static let shared = LotteryAPIService()
	private init() {}
	
	private let powerballEndpoint = "https://data.ny.gov/resource/d6yy-54nr.json"
	
	func fetchPowerballDraws(since lastDate: Date? = nil) async throws -> [LotteryDraw] {
		var urlComponents = URLComponents(string: powerballEndpoint)
		var queryItems = [
			URLQueryItem(name: "$order", value: "draw_date DESC"),
			URLQueryItem(name: "$limit", value: "5000")
		]
		
		if let lastDate = lastDate {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
			let dateString = formatter.string(from: lastDate)
			queryItems.append(URLQueryItem(name: "$where", value: "draw_date > '\(dateString)'"))
		}
		
		urlComponents?.queryItems = queryItems
		guard let url = urlComponents?.url else { throw NetworkError.invalidURL }
		
		let (data, response) = try await URLSession.shared.data(from: url)
		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			throw NetworkError.invalidResponse
		}
		
		let decoder = JSONDecoder()
		let rawDTOs = try decoder.decode([SocrataPowerballDTO].self, from: data)
		return parseDTOs(rawDTOs)
	}
	
	private func parseDTOs(_ dtos: [SocrataPowerballDTO]) -> [LotteryDraw] {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
		
		return dtos.compactMap { dto in
			guard let drawDate = dateFormatter.date(from: dto.drawDate) else { return nil }
			let components = dto.winningNumbers.components(separatedBy: " ")
			guard components.count >= 6 else { return nil }
			
			let integers = components.compactMap { Int($0) }
			guard integers.count >= 6 else { return nil }
			
			return LotteryDraw(
				playID: nil,
				drawDate: drawDate,
				firstNum: integers[0],
				secondNum: integers[1],
				thirdNum: integers[2],
				fourthNum: integers[3],
				fifthNum: integers[4],
				powerBall: integers[5]
			)
		}
	}
}

private struct SocrataPowerballDTO: Decodable {
	let drawDate: String
	let winningNumbers: String
	
	enum CodingKeys: String, CodingKey {
		case drawDate = "draw_date"
		case winningNumbers = "winning_numbers"
	}
}
