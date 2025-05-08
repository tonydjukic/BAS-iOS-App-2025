//
//  basiOS_ProfileView.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-01.
//

import SwiftUI

struct basiOS_ProfileView: View {
    @Binding var basiOS_isAuthenticated: Bool
    @Binding var basiOS_userData: basiOS_User?
    @State private var showDrawer = false
    @State private var profileData: ProfileData? = nil
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = basiOS_userData {
                        VStack(spacing: 10) {
                            // User Name
                            Text("\(user.firstName ?? user.displayName)\(user.lastName != nil ? " \(user.lastName!)" : "")")
                                .font(.title)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .padding(10)

                            // Profile Photo
                            if let profileData = profileData {
                                ZStack(alignment: .top) {
                                    AsyncImage(url: URL(string: profileData.profile_photo)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .border(Color.black, width: 1)

                                    // Pending Approval Banner
                                    if profileData.pp_approved == 0 {
                                        Text("Pending Approval")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.red.opacity(0.8))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            }

                            // Profile Details
                            if let profileData = profileData {
                                profileDetailsView(profileData: profileData)
                            } else if isLoading {
                                ProgressView("Loading profile data...")
                            } else if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top) // Align content to the top
                .padding(.horizontal)
            }

            // Navigation Drawer
            if showDrawer {
                basiOS_NavigationDrawer(
                    isOpen: $showDrawer,
                    selectedView: .constant(.profile),
                    basiOS_isAuthenticated: $basiOS_isAuthenticated
                )
            }
        }
        .onAppear {
            Task {
                await basiOS_loadUserData()
                await fetchProfileData()
            }
        }
    }

    // MARK: - Profile Details View
    @ViewBuilder
    private func profileDetailsView(profileData: ProfileData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            profileDetailSection(heading: "Birthdate", value: "\(profileData.dobM) \(profileData.dobD), \(profileData.dobY)")

            if let age = calculateAge(birthYear: profileData.dobY, birthMonth: profileData.dobM, birthDay: profileData.dobD) {
                profileDetailSection(heading: "Age", value: "\(age)")
            }

            profileDetailSection(heading: "Gender", value: profileData.gender)
            profileDetailSection(heading: "Registered On", value: profileData.date_registered)

            // Team History
            VStack(alignment: .leading, spacing: 8) {
                Text("Team History")
                    .font(.headline)
                ForEach(profileData.team_history, id: \.id) { team in
                    Link("\(team.teamname) (\(team.session_name))", destination: URL(string: team.teamurl)!)
                }
            }

            profileDetailSection(heading: "Email", value: profileData.uEmail)
            profileDetailSection(heading: "Phone", value: profileData.uPhone1)
            profileDetailSection(heading: "Alt. Phone", value: profileData.uPhone2.isEmpty ? "N/A" : profileData.uPhone2)

            // Address
            VStack(alignment: .leading, spacing: 4) {
                Text("Address")
                    .font(.headline)
                Text(profileData.uAddress)
                Text("\(profileData.uCity), \(profileData.uProvince)")
                Text(profileData.uPostal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Methods
    private func profileDetailSection(heading: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(heading)
                .font(.headline)
            Text(value)
        }
    }

    private func calculateAge(birthYear: String, birthMonth: String, birthDay: String) -> Int? {
        guard let year = Int(birthYear), let month = monthNumber(from: birthMonth), let day = Int(birthDay) else {
            return nil
        }

        let calendar = Calendar.current
        let birthDate = DateComponents(year: year, month: month, day: day).date
        let ageComponents = calendar.dateComponents([.year], from: birthDate ?? Date(), to: Date())
        return ageComponents.year
    }

    private func monthNumber(from monthName: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.monthSymbols.firstIndex(of: monthName).map { $0 + 1 }
    }

    // MARK: - Fetch Profile Data
    private func fetchProfileData() async {
        guard let user = basiOS_userData else {
            errorMessage = "User data is not available."
            return
        }

        isLoading = true
        errorMessage = nil

        let apiURL = URL(string: "https://bramptonsoccer.com/get_profile_data.php?user_id=\(user.id)")!

        do {
            let (data, response) = try await URLSession.shared.data(from: apiURL)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to fetch profile data. Please try again."
                return
            }

            let decodedResponse = try JSONDecoder().decode(ProfileAPIResponse.self, from: data)

            if decodedResponse.success {
                DispatchQueue.main.async {
                    self.profileData = decodedResponse.data
                }
            } else {
                errorMessage = "Error: Unable to fetch profile data."
            }
        } catch {
            errorMessage = "Failed to load profile data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load User Data
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
}

// MARK: - Models
struct ProfileAPIResponse: Codable {
    let success: Bool
    let data: ProfileData?
}

struct ProfileData: Codable {
    let profile_photo: String
    let pp_approved: Int
    let dobY: String
    let dobM: String
    let dobD: String
    let gender: String
    let date_registered: String
    let uEmail: String
    let uPhone1: String
    let uPhone2: String
    let uAddress: String
    let uCity: String
    let uProvince: String
    let uPostal: String
    let team_history: [Team]
}

struct Team: Codable {
    let id: Int
    let teamname: String
    let teamurl: String
    let session_name: String
}
