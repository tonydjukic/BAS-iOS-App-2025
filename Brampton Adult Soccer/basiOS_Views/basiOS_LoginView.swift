//
//  basiOS_LoginView.swift
//  Brampton Adult Soccer
//
//  Created by Tony Djukic on 2025-04-30.
//

import SwiftUI

struct basiOS_LoginView: View {
    @Binding var basiOS_isAuthenticated: Bool
    @State private var basiOS_login = ""
    @State private var basiOS_password = ""
    @State private var basiOS_isLoading = false
    @State private var basiOS_errorMessage: String?
    @State private var basiOS_showError = false
    
    var body: some View {
        ZStack {
            Color.clear
                .basiOS_GreenGradient()
            
            VStack(spacing: 30) {
                Image("BASLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 60)
                
                VStack(spacing: 25) {
                    VStack(spacing: 20) {
                        TextField("Username or Email", text: $basiOS_login)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        SecureField("Password", text: $basiOS_password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 25)
                    
                    Button(action: basiOS_handleLogin) {
                        if basiOS_isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("LOG IN")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(GradientButtonStyle())
                    .disabled(basiOS_isLoading || basiOS_login.isEmpty || basiOS_password.isEmpty)
                    .padding(.horizontal, 25)
                    
                    if let basiOS_errorMessage = basiOS_errorMessage, basiOS_showError {
                        Text(basiOS_errorMessage)
                            .foregroundColor(Color(red: 1, green: 0.85, blue: 0.85))
                            .font(.system(size: 14))
                            .transition(.opacity)
                            .padding(.top, 5)
                    }
                }
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.12))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
                )
                .padding(.horizontal, 25)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            basiOS_loadSavedCredentials()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func basiOS_loadSavedCredentials() {
        if let savedLoginData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_savedLogin"),
           let savedLogin = String(data: savedLoginData, encoding: .utf8) {
            basiOS_login = savedLogin
        }
        
        if let savedPasswordData = basiOS_KeychainHelper.basiOS_load(key: "basiOS_password"),
           let savedPassword = String(data: savedPasswordData, encoding: .utf8) {
            basiOS_password = savedPassword
        }
    }
    
    private func basiOS_handleLogin() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        basiOS_errorMessage = nil
        basiOS_showError = false
        basiOS_isLoading = true
        
        basiOS_WPAuth.basiOS_authenticate(
            login: basiOS_login.trimmingCharacters(in: .whitespaces),
            password: basiOS_password
        ) { result in
            DispatchQueue.main.async {
                basiOS_isLoading = false
                
                switch result {
                case .success(let response):
                    self.basiOS_handleLoginSuccess(response: response)
                case .failure(let error):
                    // Inspect error for HTTP 429 (too many attempts)
                    if let urlError = error as? URLError, let response = urlError.userInfo["response"] as? HTTPURLResponse {
                        if response.statusCode == 429 {
                            basiOS_errorMessage = "Too many login attempts. Please try again later."
                        } else {
                            basiOS_errorMessage = error.localizedDescription
                        }
                    } else {
                        basiOS_errorMessage = error.localizedDescription
                    }
                    basiOS_showError = true
                }
            }
        }
    }
    
    private func basiOS_handleLoginSuccess(response: basiOS_AuthResponse) {
        _ = basiOS_KeychainHelper.basiOS_save(
            key: "basiOS_sessionToken",
            data: response.data.sessionToken.data(using: .utf8)!
        )
        
        _ = basiOS_KeychainHelper.basiOS_save(
            key: "basiOS_userData",
            data: try! JSONEncoder().encode(response.data.user)
        )
        
        _ = basiOS_KeychainHelper.basiOS_save(
            key: "basiOS_savedLogin",
            data: basiOS_login.data(using: .utf8)!
        )
        
        _ = basiOS_KeychainHelper.basiOS_save(
            key: "basiOS_password",
            data: basiOS_password.data(using: .utf8)!
        )
        
        DispatchQueue.main.async {
            basiOS_isAuthenticated = true
        }
    }
    
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
    
    struct GradientButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1, green: 0.5, blue: 0),
                            Color(red: 0.9, green: 0.4, blue: 0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}
