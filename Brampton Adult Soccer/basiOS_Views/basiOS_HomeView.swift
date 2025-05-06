//
//  basiOS_HomeView.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import SwiftUI

// Hex Color Extension (put this outside the struct)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct basiOS_HomeView: View {
    @State private var basiOS_userData: basiOS_User?
    @Binding var basiOS_isAuthenticated: Bool
    @State private var showDrawer = false
    @State private var selectedView: NavigationDestination = .dashboard
    @State private var basiOS_matchData: basiOS_MatchData?
    @State private var basiOS_lastRefreshTime: Date?
    @State private var basiOS_isRefreshing = false
    @State private var basiOS_errorMessage: String?
    
    // MARK: - NEW: Add selected match state for popup
    @State private var selectedMatch: basiOS_Match? = nil
    // MARK: - END NEW
    
    enum NavigationDestination {
        case dashboard
        case profile
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color.clear
                        .basiOS_SlateGradient()

                    // Directly add the switch statement here
                    switch selectedView {
                    case .dashboard:
                        AnyView(
                            DashboardContentView(
                                userData: $basiOS_userData,
                                matchData: $basiOS_matchData,
                                isLoading: basiOS_isRefreshing,
                                errorMessage: $basiOS_errorMessage,
                                selectedMatch: $selectedMatch
                            )
                        )
                    case .profile:
                        AnyView(
                            basiOS_ProfileView(
                                basiOS_isAuthenticated: $basiOS_isAuthenticated,
                                basiOS_userData: $basiOS_userData
                            )
                        )
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                showDrawer.toggle()
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            basiOS_NavigationDrawer(
                isOpen: $showDrawer,
                selectedView: $selectedView,
                basiOS_isAuthenticated: $basiOS_isAuthenticated
            )
        }
        .sheet(item: $selectedMatch) { match in
            MatchDetailPopup(match: match)
        }
        .task {
            await basiOS_loadUserData()
            await basiOS_refreshMatchData()
        }
        .onChange(of: selectedView) { newValue in
            if newValue == .dashboard {
                Task {
                    await basiOS_refreshMatchData()
                }
            }
        }
    }
    
    // MARK: - Dashboard Content View
    private struct DashboardContentView: View {
        @Binding var userData: basiOS_User?
        @Binding var matchData: basiOS_MatchData?
        let isLoading: Bool
        @Binding var errorMessage: String?
        @Binding var selectedMatch: basiOS_Match?
        
        var body: some View {
            VStack(spacing: 20) {
                if let user = userData {
                    VStack(spacing: 10) {
                        Text("Welcome, \(user.firstName ?? user.displayName)\(user.lastName != nil ? " \(user.lastName!)" : "")")
                            .font(.callout)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.bottom, 10)
                            .padding(.trailing, 10)
                        
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
                            ScrollView {
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
                                                        .foregroundColor(.black)
                                                        .frame(maxWidth: .infinity)
                                                    Text("\(match.home_team.name) vs \(match.away_team.name)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.black)
                                                        .frame(maxWidth: .infinity)
                                                    Text(match.venue.title)
                                                        .font(.caption)
                                                        .foregroundColor(.black.opacity(0.8))
                                                        .frame(maxWidth: .infinity)
                                                }
                                                .padding(8)
                                                .background(Color.white.opacity(0.5))
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
                    }
                    .padding(.top, 20)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    // MARK: - Match Detail Popup View
    private struct MatchDetailPopup: View {
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Match Details")
                            .font(.title2.bold())
                            .padding(.bottom, 8)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "tshirt.fill")
                                    .foregroundColor(Color(hex: match.home_team.jersey_color))
                                    .overlay(
                                        Image(systemName: "tshirt")
                                            .foregroundColor(.white.opacity(0.4))
                                    )
                                Text(match.home_team.name)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("vs")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            
                            HStack(spacing: 4) {
                                Text(match.away_team.name)
                                Image(systemName: "tshirt.fill")
                                    .foregroundColor(Color(hex: match.away_team.jersey_color))
                                    .overlay(
                                        Image(systemName: "tshirt")
                                            .foregroundColor(.white.opacity(0.4))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        
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
                                        Text(match.venue.title)
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
    
    // MARK: - Network Methods
    private func basiOS_loadUserData() async {
        guard let userData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_userData"),
              let user = try? JSONDecoder().decode(basiOS_User.self, from: userData) else {
            basiOS_logout()
            return
        }
        
        DispatchQueue.main.async {
            self.basiOS_userData = user
        }
    }
    
    private func basiOS_logout() {
        basiOS_KeychainHelper.basiOS_delete(key: "basiOS_sessionToken")
        DispatchQueue.main.async {
            withAnimation {
                basiOS_isAuthenticated = false
            }
        }
    }
    
    private func basiOS_refreshMatchData() async {
        guard !basiOS_isRefreshing else { return }
        
        basiOS_isRefreshing = true
        basiOS_errorMessage = nil
        
        defer { basiOS_isRefreshing = false }
        
        guard let userData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_userData"),
              let user = try? JSONDecoder().decode(basiOS_User.self, from: userData),
              let savedLoginData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_savedLogin"),
              let savedLogin = String(data: savedLoginData, encoding: .utf8),
              let savedPasswordData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_password"),
              let savedPassword = String(data: savedPasswordData, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.basiOS_errorMessage = "Session expired - please login again"
                self.basiOS_logout()
            }
            return
        }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                basiOS_WPMatchData.basiOS_fetchMatchData(
                    userID: user.id,
                    login: savedLogin,
                    password: savedPassword
                ) { result in
                    continuation.resume(with: result)
                }
            }
            
            DispatchQueue.main.async {
                self.basiOS_matchData = result.data
                self.basiOS_lastRefreshTime = Date()
            }
        } catch {
            DispatchQueue.main.async {
                self.basiOS_errorMessage = "Failed to load matches: \(error.localizedDescription)"
            }
        }
    }
}
