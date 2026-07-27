///  HistoricalDataInfoView.swift
import SwiftUI

struct HistoricalDataInfoView: View {
	@Environment(\.dismiss) var dismiss // Allows us to close the sheet
	
	var body: some View {
		NavigationView {
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					
					Image(systemName: "exclamationmark.triangle.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 50, height: 50)
						.foregroundColor(.orange)
						.padding(.bottom, 10)
					
					Text("The 2015 Matrix Revision")
						.font(.title2)
						.fontWeight(.bold)
					
					Text("On October 4, 2015, the Powerball game underwent a major rule change. Prior to this date, only white balls numbered 1-59 were used in drawings. After the revision, the pool was expanded to include numbers 1-69.")
						.font(.body)
					
					Text("How It Skews the Data")
						.font(.title2)
						.fontWeight(.bold)
					
					Text("Statistically, including pre-2015 data will skew the frequency results. Because numbers 1 through 59 have been in the drawing drum for decades longer than numbers 60 through 69, the lower numbers will naturally appear to be drawn much more often, giving a false impression of their probability in today's game.")
						.font(.body)
					
					Text("The Red Powerball")
						.font(.title2)
						.fontWeight(.bold)
					
					Text("Additionally, the red Powerball pool decreased from 35 to 26. If you include all-time historical data, your frequency charts will include numbers 27-35 for the Powerball, even though those numbers can no longer be drawn today.")
						.font(.body)
					
					Spacer()
				}
				.padding()
			}
			.navigationTitle("Historical Data Info")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}
			}
		}
	}
}

#Preview {
	HistoricalDataInfoView()
}
