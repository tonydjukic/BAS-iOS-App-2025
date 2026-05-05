//
//  MatchDetailPopup.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-07.
//

import SwiftUI

@MainActor
class AttendanceViewModel: ObservableObject {
    @Published var attendanceStatus: String
    @Published var isUpdating: Bool = false

    init(initialStatus: String) {
        self.attendanceStatus = initialStatus
    }
}

struct MatchDetailPopup: View {
    let match: basiOS_Match
    let teamID: Int
    let onAttendanceUpdate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AttendanceViewModel

    init(match: basiOS_Match, teamID: Int, onAttendanceUpdate: @escaping () -> Void) {
        self.match = match
        self.teamID = teamID
        self.onAttendanceUpdate = onAttendanceUpdate
        _viewModel = StateObject(wrappedValue: AttendanceViewModel(initialStatus: match.user_attending))
    }

    private func formatMatchDate(_ dateString: String) -> String {
        guard dateString != "TBD" else { return "TBD" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        return outputFormatter.string(from: date)
    }

    private var yesButtonColor: Color {
        switch viewModel.attendanceStatus {
        case "true":  return Color(red: 0.18, green: 0.65, blue: 0.18)
        default:      return Color(red: 0.3, green: 0.3, blue: 0.4)
        }
    }

    private var noButtonColor: Color {
        switch viewModel.attendanceStatus {
        case "false": return Color(red: 0.72, green: 0.18, blue: 0.12)
        default:      return Color(red: 0.3, green: 0.3, blue: 0.4)
        }
    }

    private func setAttendance(status: String?) {
        guard !viewModel.isUpdating else { return }

        viewModel.isUpdating = true
        viewModel.attendanceStatus = status ?? "not_set"

        guard let savedLoginData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_savedLogin"),
              let savedLogin = String(data: savedLoginData, encoding: .utf8),
              let savedPasswordData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_password"),
              let savedPassword = String(data: savedPasswordData, encoding: .utf8) else {
            viewModel.isUpdating = false
            return
        }

        var apiStatus: String? = nil
        if status == "true"  { apiStatus = "yes" }
        if status == "false" { apiStatus = "no" }

        basiOS_WPAttendance.basiOS_setAttendance(
            login: savedLogin,
            password: savedPassword,
            teamID: teamID,
            matchID: match.match_id,
            status: apiStatus
        ) { result in
            DispatchQueue.main.async {
                viewModel.isUpdating = false
                switch result {
                case .success(let response):
                    print("Attendance success: \(response.data.status)")
                    onAttendanceUpdate()
                case .failure(let error):
                    viewModel.attendanceStatus = match.user_attending
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                            .frame(maxWidth: .infinity)
                            
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
                            .frame(maxWidth: .infinity)
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

                        // MARK: - Attendance
                        VStack(spacing: 12) {
                            Text("Attendance")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 16)

                            HStack(spacing: 12) {
                                Button {
                                    setAttendance(status: "true")
                                } label: {
                                    Text("YES")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(yesButtonColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(viewModel.isUpdating)

                                Button {
                                    setAttendance(status: "false")
                                } label: {
                                    Text("NO")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(noButtonColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(viewModel.isUpdating)
                            }

                            Button {
                                setAttendance(status: nil)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise.circle")
                                    Text("clear")
                                }
                                .font(.subheadline)
                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.35))
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                            }
                            .disabled(viewModel.isUpdating)
                        }
                    }
                    .padding()
                }
                .padding()
                .padding(.top, 44)
            }

            // Close button pinned to top-right
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(basiOS_DarkSlateGradient().ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
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
