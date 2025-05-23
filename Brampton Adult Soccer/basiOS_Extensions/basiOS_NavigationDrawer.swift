//
//  basiOS_NavigationDrawer.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-01.
//

import SwiftUI

struct basiOS_NavigationDrawer: View {
    @Binding var isOpen: Bool
    @Binding var selectedView: basiOS_HomeView.NavigationDestination
    @Binding var basiOS_isAuthenticated: Bool
    let width: CGFloat = UIScreen.main.bounds.width * 0.8

    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background
            if isOpen {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isOpen = false
                        }
                    }
            }

            // Drawer content
            HStack(spacing: 0) {
                ZStack {
                    Color.clear
                        .basiOS_DarkSlateGradient()

                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        Divider()
                            .background(Color.white.opacity(0.5))
                            .padding(.top, 25)
                            .padding(.horizontal, 25)

                        // Navigation Items
                        VStack(alignment: .leading, spacing: 20) {
                            NavigationItem(
                                icon: "soccerball.inverse",
                                label: "Dashboard",
                                isActive: selectedView == .dashboard,
                                action: {
                                    selectedView = .dashboard
                                    withAnimation { isOpen = false }
                                }
                            )

                            NavigationItem(
                                icon: "person.crop.circle",
                                label: "Player Profile",
                                isActive: selectedView == .profile,
                                action: {
                                    selectedView = .profile
                                    withAnimation { isOpen = false }
                                }
                            )
                        }
                        .padding(25)

                        Spacer()

                        // Logout Button
                        VStack {
                            Divider()
                                .background(Color.white.opacity(0.5))

                            NavigationItem(
                                icon: "rectangle.portrait.and.arrow.right",
                                label: "Log Out",
                                isActive: false,
                                action: basiOS_logout
                            )
                            .padding(25)
                            // App Version
                            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text("Version \(appVersion)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.leading, 0)
                            }
                        }
                    }
                }
                .frame(width: width)
                .offset(x: isOpen ? 0 : -width)
                .animation(.easeInOut(duration: 0.3), value: isOpen)

                Spacer()
            }
        }
    }

    private func basiOS_logout() {
        basiOS_KeychainHelper.basiOS_delete(key: "basiOS_sessionToken")
        basiOS_KeychainHelper.basiOS_delete(key: "basiOS_userID")

        DispatchQueue.main.async {
            withAnimation {
                basiOS_isAuthenticated = false
            }
        }
    }
}

private struct NavigationItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? Color(red: 1.0, green: 0.75, blue: 0.35) : .white)
                    .frame(width: 30)

                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isActive ? Color(red: 1.0, green: 0.75, blue: 0.35) : .white)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(isActive ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Toolbar for Navigation
struct basiOS_Toolbar: View {
    @Binding var showDrawer: Bool
    var showGreeting: Bool
    var greetingText: String? // Optional greeting text

    var body: some View {
        ZStack {
            // Apply Dark Slate Gradient to the entire toolbar background
            Color.clear
                .basiOS_DarkSlateGradient()
                .edgesIgnoringSafeArea(.top)

            HStack {
                // Drawer Button (Leading)
                Button {
                    withAnimation {
                        showDrawer.toggle()
                    }
                } label: {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Spacer()

                // Greeting Text (Center)
                if showGreeting, let greetingText = greetingText {
                    Text(greetingText)
                        .font(.callout)
                        .foregroundColor(.white)
                }

                Spacer()

                // Notification Bell (Trailing - Placeholder)
                // Uncomment and add functionality when needed
//                Button {
//                    // Add functionality for the notification bell
//                } label: {
//                    Image(systemName: "bell")
//                        .font(.title2)
//                        .foregroundColor(.white)
//                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 44) // Standard toolbar height
    }
}
