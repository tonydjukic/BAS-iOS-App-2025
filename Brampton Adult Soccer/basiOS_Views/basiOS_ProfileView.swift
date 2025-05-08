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
    @State private var profileData: ProfileData? = nil
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = basiOS_userData {
                    VStack(spacing: 10) {
                        // Duplicate Account Banner
                        if let profileData = profileData, profileData.user_is_dupe == 1 {
                            Text("This account is a duplicate and has been retired, please use your \(profileData.alt_email ?? "") account instead.")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(8)
                        }

                        // User Name
                        Text("\(user.firstName ?? user.displayName)\(user.lastName != nil ? " \(user.lastName!)" : "")")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(10)

                        // Profile Photo or Fallback
                        if let profileData = profileData, !profileData.profile_photo.isEmpty {
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

                                // Pending Approval Banner (Full Width)
                                if profileData.pp_approved == 0 {
                                    Text("Pending Approval")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red.opacity(0.8))
                                        .zIndex(1)
                                }
                            }
                        } else {
                            // Fallback if no profile photo
                            ZStack {
                                // Dark Slate Gradient Background
                                Rectangle()
                                    .basiOS_DarkSlateGradient()
                                    .frame(height: 350)
                                    .cornerRadius(0)

                                // Gender-based Icon
                                if profileData?.gender.lowercased() == "male" {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 250))
                                        .foregroundColor(.white)
                                } else if profileData?.gender.lowercased() == "female" {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 250))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 250))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .border(Color.black, width: 1)
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
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal)
        }
        .onAppear {
            Task {
                await fetchProfileData()
            }
        }
    }

    // MARK: - Profile Details View
    @ViewBuilder
    private func profileDetailsView(profileData: ProfileData) -> some View {
        VStack(spacing: 20) {
            // Row 1: Birthdate/Age (Left) and Gender/Registered On (Right)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birthdate")
                        .font(.headline)
                    Text("\(profileData.dobM) \(profileData.dobD), \(profileData.dobY)")
                        .font(.subheadline)
                    
                    if let age = calculateAge(birthYear: profileData.dobY, birthMonth: profileData.dobM, birthDay: profileData.dobD) {
                        Text("Age")
                            .font(.headline)
                        Text("\(age)")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Gender")
                        .font(.headline)
                    Text(profileData.gender)
                        .font(.subheadline)
                    
                    Text("Registered On")
                        .font(.headline)
                    Text(profileData.date_registered)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Row 2: Email (Full Width)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                Text(profileData.uEmail)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Row 3: Phone 1 (Left) and Phone 2 (Right)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone 1")
                        .font(.headline)
                    Text(profileData.uPhone1)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Phone 2")
                        .font(.headline)
                    Text(profileData.uPhone2.isEmpty ? "N/A" : profileData.uPhone2)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Row 4: Address (Full Width)
            VStack(alignment: .leading, spacing: 4) {
                Text("Address")
                    .font(.headline)
                Text(profileData.uAddress)
                    .font(.subheadline)
                Text("\(profileData.uCity), \(profileData.uProvince)")
                    .font(.subheadline)
                Text(profileData.uPostal)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Row 5: Team History (Full Width, Center)
            VStack(spacing: 8) {
                Text("Team History")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ForEach(profileData.team_history, id: \.id) { team in
                    VStack(spacing: 4) {
                        Link(destination: URL(string: team.teamurl)!) {
                            Text(team.teamname)
                                .font(.body)
                                .foregroundColor(Color(red: 0.8, green: 0.33, blue: 0.0)) // Burnt orange color
                        }
                        Text("(\(team.session_name))")
                            .font(.footnote)
                            .foregroundColor(.black)
                            .opacity(0.9)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Methods
    private func calculateAge(birthYear: String, birthMonth: String, birthDay: String) -> Int? {
        guard let year = Int(birthYear),
              let month = monthNumber(from: birthMonth),
              let day = Int(birthDay) else {
            return nil
        }

        let calendar = Calendar.current
        let birthDateComponents = DateComponents(year: year, month: month, day: day)
        guard let birthDate = calendar.date(from: birthDateComponents) else {
            return nil
        }

        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }

    private func monthNumber(from monthName: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.monthSymbols.firstIndex(of: monthName)?.advanced(by: 1)
    }

    // MARK: - Fetch Profile Data
    private func fetchProfileData() async {
        guard let user = basiOS_userData else {
            errorMessage = "User data is not available."
            return
        }

        isLoading = true
        errorMessage = nil

        let apiURL = URL(string: "https://bramptonsoccer.com/wp-json/baslms/v1/user-demographics?user_id=\(user.id)")!

        guard let savedLoginData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_savedLogin"),
              let savedLogin = String(data: savedLoginData, encoding: .utf8),
              let savedPasswordData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_password"),
              let savedPassword = String(data: savedPasswordData, encoding: .utf8) else {
            errorMessage = "Session expired - please login again."
            basiOS_logout()
            return
        }

        let credentials = ["login": savedLogin, "password": savedPassword]

        do {
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)

            let (data, response) = try await URLSession.shared.data(for: request)

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
    let user_is_dupe: Int
    let alt_email: String?
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
