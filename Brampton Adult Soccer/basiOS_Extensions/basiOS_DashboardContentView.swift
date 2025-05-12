//
//  DashboardContentView.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-07.
//

import SwiftUI

struct DashboardContentView: View {
    @Binding var userData: basiOS_User?
    @Binding var matchData: basiOS_MatchData?
    let isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var selectedMatch: basiOS_Match?

    var body: some View {
        VStack(spacing: 20) {
            Text("Your Upcoming Matches")
                .font(.title)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 15)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.85))
                    .font(.system(size: 14))
            } else if let matchData = matchData {
                VStack(spacing: 15) {
                    ForEach(matchData.team_data, id: \.team_id) { team in
                        VStack(alignment: .leading) {
                            Text(team.team_name)
                                .font(.headline)
                                .foregroundColor(.black)

                            ForEach(team.matches, id: \.match_id) { match in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(match.match_date) at \(match.match_time)")
                                        .font(.caption)
                                        .foregroundColor( match.is_suspended ? Color.white : Color.black)
                                        .frame(maxWidth: .infinity)
                                    Text("\(match.home_team.name) vs \(match.away_team.name)")
                                        .font(.subheadline)
                                        .foregroundColor( match.is_suspended ? Color.white : Color.black)
                                        .strikethrough( match.is_suspended ? true : false )
                                        .frame(maxWidth: .infinity)
                                    Text(match.venue.title)
                                        .font(.caption)
                                        .foregroundColor( match.is_suspended ? Color.white.opacity(0.8) : Color.black.opacity(0.8) )
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(8)
                                .background(match.is_suspended ? Color.black.opacity(0.5) : Color.white.opacity(0.5)) // Updated background color
                                .cornerRadius(6)
                                .overlay(
                                    HStack {
                                        Color(hex: match.home_team.jersey_color)
                                            .frame(width: 20)
                                        Spacer()
                                    }
                                    .cornerRadius(6)
                                )
                                .overlay(
                                    HStack {
                                        Spacer()
                                        Color(hex: match.away_team.jersey_color)
                                            .frame(width: 20)
                                    }
                                    .cornerRadius(6)
                                )
                                .padding(.vertical, 5)
                                .onTapGesture {
                                    selectedMatch = match
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
