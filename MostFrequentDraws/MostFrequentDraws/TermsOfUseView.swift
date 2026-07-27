/// TermsOfUseView.swift

import SwiftUI

struct TermsOfUseView: View {
	@Binding var hasAcceptedTerms: Bool
	
	var body: some View {
		VStack(spacing: 0) {
			// MARK: - Top Header
			VStack(spacing: 8) {
				Image(systemName: "checkmark.shield.fill")
					.font(.system(size: 52))
					.foregroundColor(.blue)
				
				Text("Terms of Use & Disclaimer")
					.font(.title2)
					.fontWeight(.bold)
					.multilineTextAlignment(.center)
				
				Text("Most Frequent Draws")
					.font(.subheadline)
					.fontWeight(.medium)
					.foregroundColor(.secondary)
			}
			.padding(.top, 24)
			.padding(.bottom, 16)
			.padding(.horizontal)
			
			Divider()
			
			// MARK: - Scrollable Content
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					
					// Mandatory Disclaimer Box (Guideline 5.3)
					VStack(alignment: .leading, spacing: 12) {
						Label("Mandatory Legal Disclaimers", systemImage: "exclamationmark.triangle.fill")
							.font(.headline)
							.foregroundColor(.orange)
						
						Text("• Entertainment & Informational Purposes Only: Most Frequent Draws is an independent statistical tool designed strictly for tracking historical numbers and entertainment. The app does not sell lottery tickets, process wagers, or facilitate real-money gambling of any kind.")
							.font(.subheadline)
							.foregroundColor(.primary)
						
						Text("• No Guarantee of Winning: Past frequency data, historical statistics, calculations, and random number generators do not guarantee future winning draws or financial outcomes.")
							.font(.subheadline)
							.foregroundColor(.primary)
						
						Text("• Non-Affiliation Disclaimer: Most Frequent Draws is not affiliated with, endorsed by, or connected to Powerball®, the Multi-State Lottery Association (MUSL), or any official state lottery authority.")
							.font(.subheadline)
							.foregroundColor(.primary)
					}
					.padding()
					.background(Color(UIColor.secondarySystemBackground))
					.cornerRadius(12)
					
					// Section 1: Acceptance of Terms
					VStack(alignment: .leading, spacing: 6) {
						Text("1. Acceptance of Terms")
							.font(.headline)
						
						Text("By downloading, accessing, or using the \"Most Frequent Draws\" application (the \"App\"), you agree to be bound by these Terms of Use. If you do not agree to these terms, you must not use the App.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					
					// Section 2: User Responsibility
					VStack(alignment: .leading, spacing: 6) {
						Text("2. User Responsibility")
							.font(.headline)
						
						Text("All lottery purchasing decisions are made solely by you, and you assume all associated financial risks. Always verify official winning numbers directly with state or national lottery providers.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					
					// Section 3: Intellectual Property
					VStack(alignment: .leading, spacing: 6) {
						Text("3. Intellectual Property Rights")
							.font(.headline)
						
						Text("All original content, visual assets (including custom lottery ball graphics), and functionality are owned by the developer and protected by applicable copyright laws. You may not reproduce or redistribute original content without express permission.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					
					// Section 4: Acceptable Use
					VStack(alignment: .leading, spacing: 6) {
						Text("4. Acceptable Use and Prohibited Behaviors")
							.font(.headline)
						
						Text("You agree to use the App only for lawful purposes. You are strictly prohibited from:")
							.font(.subheadline)
							.foregroundColor(.secondary)
						
						VStack(alignment: .leading, spacing: 4) {
							Text("• Using the App to facilitate illegal gambling.")
							Text("• Reverse engineering, decompiling, or extracting source code.")
							Text("• Interfering with or disrupting the functionality of the App.")
						}
						.font(.subheadline)
						.foregroundColor(.secondary)
						.padding(.leading, 8)
					}
					
					// Section 5: Disclaimer of Warranties
					VStack(alignment: .leading, spacing: 6) {
						Text("5. Disclaimer of Warranties")
							.font(.headline)
						
						Text("The App is provided on an \"AS IS\" and \"AS AVAILABLE\" basis. The developer makes no warranties, express or implied, regarding data accuracy, completeness, or reliability. We do not guarantee uninterrupted access.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					
					// Section 6: Limitation of Liability
					VStack(alignment: .leading, spacing: 6) {
						Text("6. Limitation of Liability")
							.font(.headline)
						
						Text("In no event shall the developer be liable for direct, indirect, incidental, or consequential damages—including financial losses or purchasing decisions—arising from your use of the App.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					
					// Section 7: Changes to Terms
					VStack(alignment: .leading, spacing: 6) {
						Text("7. Modifications")
							.font(.headline)
						
						Text("We reserve the right to modify these Terms of Use at any time. Continued use of the App following any modifications constitutes acceptance of the updated terms.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
					
					// Section 8: Contact Information
					VStack(alignment: .leading, spacing: 6) {
						Text("8. Contact Information")
							.font(.headline)
						
						Text("If you have any questions regarding these Terms, please contact support via the official support link provided on our App Store product page.")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}
				}
				.padding()
			}
			
			Divider()
			
			// MARK: - Action Button
			VStack {
				Button(action: {
					hasAcceptedTerms = true
				}) {
					Text("I Agree & Continue")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding()
						.background(Color.blue)
						.cornerRadius(12)
				}
			}
			.padding(.horizontal, 20)
			.padding(.top, 12)
			.padding(.bottom, 20)
			.background(Color(UIColor.systemBackground))
		}
		.interactiveDismissDisabled(true) // Prevents user from swiping down to dismiss without agreeing
	}
}
