//
//  basiOS_HomeView.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import SwiftUI

struct SelectedMatchInfo: Identifiable {
    let match: basiOS_Match
    let teamID: Int
    let onAttendanceUpdate: () -> Void
    var id: Int { match.match_id }
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
    @State private var selectedMatchInfo: SelectedMatchInfo? = nil

    enum NavigationDestination {
        case dashboard
        case profile
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    basiOS_Toolbar(
                        showDrawer: $showDrawer,
                        showGreeting: selectedView == .dashboard,
                        greetingText: greetingText()
                    )

                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedView {
                            case .dashboard:
                                DashboardContentView(
                                    userData: $basiOS_userData,
                                    matchData: $basiOS_matchData,
                                    isLoading: basiOS_isRefreshing,
                                    errorMessage: $basiOS_errorMessage,
                                    onMatchSelect: { match, teamID in
                                        DispatchQueue.main.async {
                                            self.selectedMatchInfo = SelectedMatchInfo(
                                                match: match,
                                                teamID: teamID,
                                                onAttendanceUpdate: {
                                                    Task {
                                                        await basiOS_refreshMatchData()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                )
                            case .profile:
                                basiOS_ProfileView(
                                    basiOS_isAuthenticated: $basiOS_isAuthenticated,
                                    basiOS_userData: $basiOS_userData
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .background(
                    Color.clear
                        .basiOS_SlateGradient()
                        .edgesIgnoringSafeArea(.all)
                )
                .onAppear {
                    configureTransparentNavigationBar()
                }
            }

            basiOS_NavigationDrawer(
                isOpen: $showDrawer,
                selectedView: $selectedView,
                basiOS_isAuthenticated: $basiOS_isAuthenticated
            )
        }
        .sheet(item: $selectedMatchInfo, onDismiss: {
            selectedMatchInfo = nil
        }) { info in
            MatchDetailPopup(
                match: info.match,
                teamID: info.teamID,
                onAttendanceUpdate: info.onAttendanceUpdate
            )
        }
        .task {
            await basiOS_loadUserData()
            await basiOS_refreshMatchData()
        }
        .onChange(of: selectedView) {
            if selectedView == .dashboard {
                Task {
                    await basiOS_refreshMatchData()
                }
            }
        }
    }

    private func greetingText() -> String? {
        if let user = basiOS_userData {
            return "Welcome, \(user.firstName ?? user.displayName)\(user.lastName != nil ? " \(user.lastName!)" : "")"
        }
        return nil
    }

    private func configureTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

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
