/// ContentView.swift

import SwiftUI

struct ContentView: View {
	@StateObject private var viewModel = LotteryViewModel()
	
	// Automatically saves the toggle state to the device
	@AppStorage("includePre2015Data") private var includePre2015Data = false
	
	// Tracks whether the user has accepted the terms of use on first launch
	@AppStorage("hasAcceptedTerms") private var hasAcceptedTerms: Bool = false
	
	// Controls when the info sheet pops up
	@State private var showingInfoSheet = false
	
	var body: some View {
		Group {
			if viewModel.isInitialLoading {
				InitialLoadingView(statusMessage: viewModel.statusMessage)
			} else {
				VStack(spacing: 0) {
					// Toggle and Info button at the top
					HStack {
						Toggle("Include Pre-2015 Data", isOn: $includePre2015Data)
							.onChange(of: includePre2015Data) { _, newValue in
								viewModel.calculateFrequencies(includePre2015: newValue)
							}
						
						Button(action: {
							showingInfoSheet = true
						}) {
							Image(systemName: "info.circle")
								.foregroundColor(.blue)
								.font(.title3)
						}
					}
					.padding()
					
					// Main Tab View
					TabView {
						MostFrequentView(viewModel: viewModel)
							.tabItem {
								Label("Frequencies", systemImage: "chart.bar.fill")
							}
						
						RandomGeneratorView(viewModel: viewModel)
							.tabItem {
								Label("Generator", systemImage: "dice.fill")
							}
						
						CustomEntryView(viewModel: viewModel)
							.tabItem {
								Label("Custom Pick", systemImage: "square.and.pencil")
							}
						
						SavedDrawsView(viewModel: viewModel)
							.tabItem {
								Label("Saved Slips", systemImage: "tray.full.fill")
							}
					}
					.tint(.blue)
				}
				.sheet(isPresented: $showingInfoSheet) {
					HistoricalDataInfoView()
				}
				.fullScreenCover(isPresented: Binding(
					get: { !hasAcceptedTerms },
					set: { hasAcceptedTerms = !$0 }
				)) {
					TermsOfUseView(hasAcceptedTerms: $hasAcceptedTerms)
				}
			}
		}
	}
}

// MARK: - Initial Database Loading View
struct InitialLoadingView: View {
	let statusMessage: String
	
	var body: some View {
		VStack(spacing: 28) {
			Spacer()
			
			// App Brand Graphic
			HStack(spacing: 8) {
				LotteryBallView(number: 7, isSpecialBall: false)
				LotteryBallView(number: 14, isSpecialBall: false)
				LotteryBallView(number: 21, isSpecialBall: false)
				LotteryBallView(number: 28, isSpecialBall: true, useRedColor: true)
			}
			.scaleEffect(1.15)
			
			VStack(spacing: 8) {
				Text("Most Frequent Draws")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundColor(.primary)
				
				Text("Lottery Stats & Frequency")
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			// Loading Spinner & Status Text
			VStack(spacing: 16) {
				ProgressView()
					.controlSize(.large)
					.tint(.blue)
				
				Text(statusMessage)
					.font(.callout)
					.fontWeight(.medium)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal)
			}
			.padding(.bottom, 60)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(UIColor.systemBackground))
	}
}

// MARK: - Custom Ping-Pong Ball Graphic View Component
struct LotteryBallView: View {
	let number: Int?
	let isSpecialBall: Bool
	var useRedColor: Bool = true
	
	var body: some View {
		ZStack {
			Circle()
				.fill(
					isSpecialBall
					? AnyShapeStyle(
						LinearGradient(
							colors: useRedColor ? [.red, .pink] : [.blue, .cyan],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					: AnyShapeStyle(
						LinearGradient(
							colors: [.white, Color(white: 0.92)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				)
				.shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 3)
				.overlay(
					Circle()
						.stroke(isSpecialBall ? (useRedColor ? Color.red : Color.blue) : Color.gray.opacity(0.4), lineWidth: 1.5)
				)
			
			if let number = number {
				Text("\(number)")
					.font(.system(size: 20, weight: .bold, design: .rounded))
					.foregroundColor(isSpecialBall ? .white : .black)
			} else {
				Text("--")
					.font(.system(size: 18, weight: .semibold))
					.foregroundColor(isSpecialBall ? .white : .gray)
			}
		}
		.frame(width: 52, height: 52)
	}
}

// MARK: - Tab 1: Frequencies View
struct MostFrequentView: View {
	@ObservedObject var viewModel: LotteryViewModel
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					if viewModel.isSyncing {
						ProgressView(viewModel.statusMessage)
							.padding()
					} else {
						Text(viewModel.statusMessage)
							.font(.caption)
							.foregroundColor(.secondary)
					}
					
					// Top 5 Main Numbers Card
					VStack(alignment: .leading, spacing: 16) {
						Text("Top 5 Main Numbers Combined")
							.font(.headline)
						
						HStack(spacing: 12) {
							ForEach(0..<5, id: \.self) { index in
								VStack {
									if index < viewModel.topMainFrequencies.count {
										LotteryBallView(number: viewModel.topMainFrequencies[index].number, isSpecialBall: false)
										Text("\(viewModel.topMainFrequencies[index].count)x")
											.font(.caption2)
											.foregroundColor(.secondary)
									} else {
										LotteryBallView(number: nil, isSpecialBall: false)
									}
								}
							}
						}
						.frame(maxWidth: .infinity)
					}
					.padding()
					.background(Color(UIColor.secondarySystemBackground))
					.cornerRadius(12)
					
					// Top Powerball Card
					VStack(alignment: .leading, spacing: 16) {
						Text("Top Powerball Number")
							.font(.headline)
						
						HStack {
							Spacer()
							VStack {
								if let pb = viewModel.topPowerballFrequency {
									LotteryBallView(number: pb.number, isSpecialBall: true, useRedColor: true)
									Text("\(pb.count)x")
										.font(.caption2)
										.foregroundColor(.secondary)
								} else {
									LotteryBallView(number: nil, isSpecialBall: true, useRedColor: true)
								}
							}
							Spacer()
						}
					}
					.padding()
					.background(Color(UIColor.secondarySystemBackground))
					.cornerRadius(12)
					
					// Next Powerball Draw Date Banner
					VStack(spacing: 8) {
						HStack(spacing: 6) {
							Image(systemName: "calendar.badge.clock")
								.foregroundColor(.red)
							Text("Next Powerball Draw")
								.font(.subheadline)
								.fontWeight(.semibold)
								.foregroundColor(.secondary)
						}
						
						Text(viewModel.nextDrawDateString)
							.font(.title3)
							.fontWeight(.bold)
							.foregroundColor(.red)
					}
					.padding(.vertical, 14)
					.padding(.horizontal, 20)
					.frame(maxWidth: .infinity)
					.background(
						RoundedRectangle(cornerRadius: 12)
							.fill(Color.red.opacity(0.08))
					)
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(Color.red.opacity(0.2), lineWidth: 1)
					)
				}
				.padding()
			}
			
			.navigationTitle("Most Frequent Draws")
			.toolbar {
				Button {
					viewModel.syncWithAPI()
				} label: {
					Image(systemName: "arrow.clockwise")
				}
			}
		}
	}
}

// MARK: - Tab 2: Generator View
struct RandomGeneratorView: View {
	@ObservedObject var viewModel: LotteryViewModel
	@State private var comboTitle: String = ""
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 30) {
				Text("Ascending Random Selection")
					.font(.subheadline)
					.foregroundColor(.secondary)
				
				HStack(spacing: 10) {
					ForEach(0..<5, id: \.self) { idx in
						if idx < viewModel.generatedMainNumbers.count {
							LotteryBallView(number: viewModel.generatedMainNumbers[idx], isSpecialBall: false)
						} else {
							LotteryBallView(number: nil, isSpecialBall: false)
						}
					}
					LotteryBallView(number: viewModel.generatedPowerball, isSpecialBall: true, useRedColor: true)
				}
				
				Button(action: { viewModel.generateRandomCombination() }) {
					Label("Generate Numbers", systemImage: "dice")
						.font(.title3.weight(.bold))
						.frame(maxWidth: .infinity)
						.padding()
						.background(Color.blue)
						.foregroundColor(.white)
						.cornerRadius(10)
				}
				
				if !viewModel.generatedMainNumbers.isEmpty {
					VStack(spacing: 12) {
						TextField("Label (e.g., Quick Pick)", text: $comboTitle)
							.textFieldStyle(.roundedBorder)
						
						Button(action: {
							viewModel.saveGeneratedCombination(title: comboTitle.isEmpty ? "Quick Pick" : comboTitle)
							comboTitle = ""
						}) {
							Label("Save Combination", systemImage: "square.and.arrow.down")
								.frame(maxWidth: .infinity)
								.padding()
								.background(Color.green)
								.foregroundColor(.white)
								.cornerRadius(10)
						}
					}
				}
				Spacer()
			}
			.padding()
			.navigationTitle("RNG Tool")
		}
	}
}

// MARK: - Tab 3: Custom Entry View
struct CustomEntryView: View {
	@ObservedObject var viewModel: LotteryViewModel
	
	@State private var mode = 0
	@State private var mainInputs: [String] = Array(repeating: "", count: 5)
	@State private var powerballInput: String = ""
	@State private var titleInput: String = ""
	@State private var alertMessage: String = ""
	@State private var showAlert: Bool = false
	
	var body: some View {
		NavigationStack {
			Form {
				Section("Selection Mode") {
					Picker("Mode", selection: $mode) {
						Text("Define All").tag(0)
						Text("Mains + Auto PB").tag(1)
						Text("Auto Mains + PB").tag(2)
					}
					.pickerStyle(.segmented)
				}
				
				Section("Main Numbers (1 - 69)") {
					if mode == 2 {
						Text("Main numbers will be automatically generated").foregroundColor(.secondary)
					} else {
						HStack {
							ForEach(0..<5, id: \.self) { i in
								TextField("#\(i+1)", text: $mainInputs[i])
									.keyboardType(.numberPad)
									.multilineTextAlignment(.center)
									.textFieldStyle(.roundedBorder)
							}
						}
					}
				}
				
				Section("Powerball (1 - 26)") {
					if mode == 1 {
						Text("Powerball will be automatically generated").foregroundColor(.secondary)
					} else {
						TextField("PB Number", text: $powerballInput)
							.keyboardType(.numberPad)
							.textFieldStyle(.roundedBorder)
					}
				}
				
				Section("Metadata") {
					TextField("Slip Title (Optional)", text: $titleInput)
				}
				
				Button("Process and Save Set") {
					processCustomEntry()
				}
				.frame(maxWidth: .infinity, alignment: .center)
				.font(.headline)
				.foregroundColor(.blue)
			}
			.navigationTitle("Custom Entry")
			.alert("Entry Status", isPresented: $showAlert) {
				Button("OK", role: .cancel) {}
			} message: {
				Text(alertMessage)
			}
		}
	}
	
	private func processCustomEntry() {
		var finalMains: [Int] = []
		var finalPB: Int? = nil
		
		if mode == 0 || mode == 1 {
			let parsed = mainInputs.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
			guard parsed.count == 5, Set(parsed).count == 5, parsed.allSatisfy({ $0 >= 1 && $0 <= 69 }) else {
				alertMessage = "Please enter 5 unique valid main numbers (1-69)."
				showAlert = true
				return
			}
			finalMains = parsed
		} else {
			var set = Set<Int>()
			while set.count < 5 { set.insert(Int.random(in: 1...69)) }
			finalMains = Array(set)
		}
		
		if mode == 0 || mode == 2 {
			guard let pb = Int(powerballInput.trimmingCharacters(in: .whitespaces)), pb >= 1 && pb <= 26 else {
				alertMessage = "Please enter a valid Powerball number (1-26)."
				showAlert = true
				return
			}
			finalPB = pb
		} else {
			finalPB = Int.random(in: 1...26)
		}
		
		if let pb = finalPB {
			let success = viewModel.saveCustomCombination(mains: finalMains, powerball: pb, title: titleInput)
			if success {
				alertMessage = "Combination saved successfully!"
				mainInputs = Array(repeating: "", count: 5)
				powerballInput = ""
				titleInput = ""
			} else {
				alertMessage = "Failed to save combination to database."
			}
			showAlert = true
		}
	}
}

// MARK: - Tab 4: Saved Slips View
struct SavedDrawsView: View {
	@ObservedObject var viewModel: LotteryViewModel
	
	var body: some View {
		NavigationStack {
			List {
				ForEach(viewModel.savedCombinations) { combo in
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text(combo.title)
								.font(.headline)
							Spacer()
							Text(combo.dateCreated.formatted(date: .numeric, time: .omitted))
								.font(.caption)
								.foregroundColor(.secondary)
						}
						
						HStack(spacing: 8) {
							ForEach(combo.sortedMainNumbers, id: \.self) { num in
								Text("\(num)")
									.font(.system(size: 14, weight: .bold))
									.frame(width: 30, height: 30)
									.background(Color.gray.opacity(0.2))
									.clipShape(Circle())
							}
							
							Text("\(combo.powerBall)")
								.font(.system(size: 14, weight: .bold))
								.foregroundColor(.white)
								.frame(width: 30, height: 30)
								.background(Color.red)
								.clipShape(Circle())
						}
					}
					.padding(.vertical, 4)
				}
				.onDelete(perform: viewModel.deleteSavedCombination)
			}
			.navigationTitle("Saved Combinations")
		}
	}
}
