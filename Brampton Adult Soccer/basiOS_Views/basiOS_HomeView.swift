//
//  basiOS_HomeView.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import SwiftUI

struct basiOS_HomeView: View {
    @State private var basiOS_userData: basiOS_User?
    @Binding var basiOS_isAuthenticated: Bool
    @State private var showDrawer = false
    @State private var selectedView: NavigationDestination = .dashboard
    @State private var basiOS_matchData: basiOS_MatchData?
    @State private var basiOS_lastRefreshTime: Date?
    @State private var basiOS_isRefreshing = false
    @State private var basiOS_errorMessage: String?
    @State private var selectedMatch: basiOS_Match? = nil // Popup match state

    enum NavigationDestination {
        case dashboard
        case profile
    }

    var body: some View {
        ZStack {
            // Main navigation stack
            NavigationStack {
                VStack(spacing: 0) {
                    // Toolbar at the top
                    toolbarView()
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedView {
                            case .dashboard:
                                DashboardContentView(
                                    userData: $basiOS_userData,
                                    matchData: $basiOS_matchData,
                                    isLoading: basiOS_isRefreshing,
                                    errorMessage: $basiOS_errorMessage,
                                    selectedMatch: $selectedMatch
                                )
                            case .profile:
                                basiOS_ProfileView(
                                    basiOS_isAuthenticated: $basiOS_isAuthenticated,
                                    basiOS_userData: $basiOS_userData
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16) // Space below the toolbar
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .background(
                    Color.clear
                        .basiOS_SlateGradient()
                        .edgesIgnoringSafeArea(.all) // Full-screen gradient
                )
                .onAppear {
                    configureTransparentNavigationBar()
                }
            }

            // Navigation drawer overlay
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

    // MARK: - Toolbar View
    @ViewBuilder
    private func toolbarView() -> some View {
        HStack {
            // Left: Drawer toggle button
            Button(action: {
                withAnimation {
                    showDrawer.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Spacer()

            // Center: Greeting text (dashboard only)
            if selectedView == .dashboard, let greeting = greetingText() {
                Text(greeting)
                    .font(.callout)
                    .foregroundColor(.white)
            }

            Spacer()

            // Right: Notification button
//            Button(action: {
//                // Placeholder for notification functionality
//            }) {
//                Image(systemName: "bell")
//                    .font(.title2)
//                    .foregroundColor(.white)
//            }
        }
        .padding()
        .background(Color.black.opacity(0.7)) // Semi-transparent background
    }

    // MARK: - Helper Methods
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
        // Clear Keychain data
        basiOS_KeychainHelper.basiOS_delete(key: "basiOS_sessionToken")
        basiOS_KeychainHelper.basiOS_delete(key: "basiOS_userID")
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userID")
        UserDefaults.standard.synchronize()
        // Clear cookies if using web-based APIs
        if let cookieStorage = HTTPCookieStorage.shared.cookies {
            for cookie in cookieStorage {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
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
