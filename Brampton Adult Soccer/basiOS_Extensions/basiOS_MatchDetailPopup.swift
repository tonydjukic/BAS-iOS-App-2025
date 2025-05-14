//
//  MatchDetailPopup.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-07.
//

import SwiftUI

struct MatchDetailPopup: View {
    let match: basiOS_Match
    @Environment(\.dismiss) private var dismiss

    private func formatMatchDate(_ dateString: String) -> String {
        guard dateString != "TBD" else { return "TBD" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        return outputFormatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            basiOS_DarkSlateGradient()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Match Details")
                        .font(.title2.bold())
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    
                    if match.is_suspended {
                        Text("You are suspended for this match.")
                            .font(.footnote)
                            .padding(.bottom, 6)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        Text("Speak with your Team Rep.")
                            .font(.footnote)
                            .padding(.bottom, 8)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        HStack(spacing: 4) {
                            Image(systemName: "tshirt.fill")
                                .foregroundColor(Color(hex: match.home_team.jersey_color))
                                .overlay(
                                    Image(systemName: "tshirt")
                                        .foregroundColor(.white.opacity(0.4))
                                )
                                .font(.title2)
                            Text(decodeHTMLEntities(match.home_team.name))
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity,)
                        
                        Text("vs")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(4)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "tshirt.fill")
                                .foregroundColor(Color(hex: match.away_team.jersey_color))
                                .overlay(
                                    Image(systemName: "tshirt")
                                        .foregroundColor(.white.opacity(0.4))
                                )
                                .font(.title2)
                            Text(decodeHTMLEntities(match.away_team.name))
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity,)
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(8)
                    .padding(.bottom, 16)
                    
                    DetailRow(title: "Date:", value: formatMatchDate(match.match_date))
                    DetailRow(title: "Time:", value: match.match_time)
                    
                    if let urlString = match.venue.map_url,
                       let url = URL(string: urlString) {
                        HStack {
                            Text("Venue:")
                                .font(.headline)
                                .frame(width: 100, alignment: .leading)
                                .foregroundColor(.white)
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "map")
                                    Text(decodeHTMLEntities(match.venue.title))
                                }
                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.35))
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Detail Row Helper View
private struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.headline)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.white)
            Text(value)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
        }
    }
}
