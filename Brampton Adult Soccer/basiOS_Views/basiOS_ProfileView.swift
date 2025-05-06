//
//  basiOS_PlayerProfile.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-05-01.
//

import SwiftUI

struct basiOS_ProfileView: View {
    @Binding var basiOS_isAuthenticated: Bool
    @Binding var basiOS_userData: basiOS_User?
    @State private var showDrawer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = basiOS_userData {
                    VStack(spacing: 10) {
                        Text("\(user.firstName ?? user.displayName)\(user.lastName != nil ? " \(user.lastName!)" : "")")
                            .font(.title)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(10)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top) // Ensures content is aligned to the top
        }
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
}
