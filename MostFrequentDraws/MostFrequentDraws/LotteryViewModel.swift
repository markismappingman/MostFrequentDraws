/// LotteryViewModel.swift

import Foundation
import Combine

@MainActor
final class LotteryViewModel: ObservableObject {
	
	// MARK: - Published Properties (UI State)
	
	@Published var topMainFrequencies: [NumberFrequency] = []
	@Published var topPowerballFrequency: NumberFrequency? = nil
	
	@Published var generatedMainNumbers: [Int] = []
	@Published var generatedPowerball: Int? = nil
	
	@Published var savedCombinations: [UserSavedCombination] = []
	@Published var isSyncing: Bool = false
	@Published var isInitialLoading: Bool = true
	@Published var statusMessage: String = "Initializing database..."
	
	let activeTable = "lottery-numbers-powerball"
	
	// MARK: - Initialization
	
	init() {
		Task {
			await performInitialSetup()
		}
	}
	
	// MARK: - Initial Startup & Seeding
	
	private func performInitialSetup() async {
		isInitialLoading = true
		statusMessage = "Checking database..."
		
		do {
			// Fetch most recent date off the main thread with explicit await
			let lastDate = try await Task.detached(priority: .userInitiated) {
				try await DatabaseManager.shared.mostRecentDrawDate(in: self.activeTable)
			}.value
			
			if lastDate == nil {
				statusMessage = "Downloading historical draw data..."
			} else {
				statusMessage = "Checking for new draws..."
			}
			
			// Download network data via API
			let newDraws = try await LotteryAPIService.shared.fetchPowerballDraws(since: lastDate)
			
			if !newDraws.isEmpty {
				statusMessage = "Populating database records..."
				try await Task.detached(priority: .userInitiated) {
					try await DatabaseManager.shared.insertDraws(newDraws, into: self.activeTable)
				}.value
			}
			
			statusMessage = "Calculating frequency statistics..."
			await refreshDataAsync()
			statusMessage = "Database up to date."
			
		} catch {
			statusMessage = "Notice: \(error.localizedDescription)"
			await refreshDataAsync()
		}
		
		// Brief delay for a smooth presentation transition
		try? await Task.sleep(nanoseconds: 500_000_000)
		isInitialLoading = false
	}
	
	// MARK: - Draw Schedule & Next Draw Date Logic
	
	/// Calculates and formats the next Powerball draw date (Mondays, Wednesdays, and Saturdays at 10:59 PM ET)
	var nextDrawDateString: String {
		let calendar = Calendar.current
		let now = Date()
		let drawDays = [2, 4, 7] // Sunday = 1, Monday = 2, Wednesday = 4, Saturday = 7
		
		for dayOffset in 0...7 {
			guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
			let weekday = calendar.component(.weekday, from: checkDate)
			
			if drawDays.contains(weekday) {
				if dayOffset == 0 {
					var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
					components.hour = 22
					components.minute = 59
					if let drawTimeToday = calendar.date(from: components), now > drawTimeToday {
						continue
					}
				}
				
				let formatter = DateFormatter()
				formatter.dateFormat = "EEEE, MMMM d, yyyy"
				return formatter.string(from: checkDate)
			}
		}
		return "Date Unavailable"
	}
	
	// MARK: - Toggle & Frequency Logic
	
	func calculateFrequencies(includePre2015: Bool) {
		Task {
			await calculateFrequenciesAsync(includePre2015: includePre2015)
		}
	}
	
	private func calculateFrequenciesAsync(includePre2015: Bool) async {
		do {
			// Offload heavy SQL queries off the main UI thread with explicit await
			let (mainFreqs, powerballFreqs, saved) = try await Task.detached(priority: .userInitiated) { () -> ([NumberFrequency], [NumberFrequency], [UserSavedCombination]) in
				let mains = try await DatabaseManager.shared.fetchTopMainBallFrequencies(in: self.activeTable, includePre2015: includePre2015, limit: 5)
				let pbs = try await DatabaseManager.shared.fetchTopSpecialBallFrequencies(in: self.activeTable, includePre2015: includePre2015, limit: 1)
				let savedCombos = try await DatabaseManager.shared.fetchSavedCombinations()
				return (mains, pbs, savedCombos)
			}.value
			
			self.topMainFrequencies = mainFreqs
			self.topPowerballFrequency = powerballFreqs.first
			self.savedCombinations = saved
		} catch {
			self.statusMessage = "Database Fetch Error: \(error.localizedDescription)"
		}
	}
	
	func refreshData() {
		Task {
			await refreshDataAsync()
		}
	}
	
	private func refreshDataAsync() async {
		let includePre2015 = UserDefaults.standard.bool(forKey: "includePre2015Data")
		await calculateFrequenciesAsync(includePre2015: includePre2015)
	}
	
	// MARK: - API Synchronization
	
	func syncWithAPI() {
		Task {
			isSyncing = true
			statusMessage = "Synchronizing database..."
			do {
				let lastDate = try await Task.detached(priority: .userInitiated) {
					try await DatabaseManager.shared.mostRecentDrawDate(in: self.activeTable)
				}.value
				let newDraws = try await LotteryAPIService.shared.fetchPowerballDraws(since: lastDate)
				
				if !newDraws.isEmpty {
					try await Task.detached(priority: .userInitiated) {
						try await DatabaseManager.shared.insertDraws(newDraws, into: self.activeTable)
					}.value
					statusMessage = "Synced \(newDraws.count) new draws."
				} else {
					statusMessage = "Database up to date."
				}
				await refreshDataAsync()
			} catch {
				statusMessage = "Sync failed: \(error.localizedDescription)"
			}
			isSyncing = false
		}
	}
	
	// MARK: - Generator Logic
	
	func generateRandomCombination() {
		var set = Set<Int>()
		while set.count < 5 {
			set.insert(Int.random(in: 1...69))
		}
		generatedMainNumbers = set.sorted()
		generatedPowerball = Int.random(in: 1...26)
	}
	
	// MARK: - User Saved Combinations Logic
	
	func saveGeneratedCombination(title: String = "Random Pick") {
		guard generatedMainNumbers.count == 5, let pb = generatedPowerball else { return }
		let combo = UserSavedCombination(
			id: nil,
			title: title,
			firstNum: generatedMainNumbers[0],
			secondNum: generatedMainNumbers[1],
			thirdNum: generatedMainNumbers[2],
			fourthNum: generatedMainNumbers[3],
			fifthNum: generatedMainNumbers[4],
			powerBall: pb,
			dateCreated: Date()
		)
		do {
			try DatabaseManager.shared.saveUserCombination(combo)
			refreshData()
		} catch {
			statusMessage = "Save Failed: \(error.localizedDescription)"
		}
	}
	
	func saveCustomCombination(mains: [Int], powerball: Int, title: String) -> Bool {
		guard mains.count == 5, mains.allSatisfy({ $0 >= 1 && $0 <= 69 }), powerball >= 1 && powerball <= 26 else {
			return false
		}
		let sorted = mains.sorted()
		let combo = UserSavedCombination(
			id: nil,
			title: title.isEmpty ? "Custom Pick" : title,
			firstNum: sorted[0],
			secondNum: sorted[1],
			thirdNum: sorted[2],
			fourthNum: sorted[3],
			fifthNum: sorted[4],
			powerBall: powerball,
			dateCreated: Date()
		)
		do {
			try DatabaseManager.shared.saveUserCombination(combo)
			refreshData()
			return true
		} catch {
			statusMessage = "Custom Save Error: \(error.localizedDescription)"
			return false
		}
	}
	
	func deleteSavedCombination(at offsets: IndexSet) {
		for index in offsets {
			let combo = savedCombinations[index]
			if let id = combo.id {
				try? DatabaseManager.shared.deleteSavedCombination(id: id)
			}
		}
		refreshData()
	}
}
