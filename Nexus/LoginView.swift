import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.nexusSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.stevensRed, Color.primaryContainer],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("N")
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .stevensRed.opacity(0.3), radius: 12, y: 6)

                    Text("The Stevens Nexus")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.stevensRed)
                        .tracking(-0.5)

                    Text("Your campus. Connected.")
                        .font(.system(size: 15))
                        .foregroundColor(.nexusSecondary)
                }
                .padding(.top, 80)
                .padding(.bottom, 40)

                // Form
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.nexusSecondary)
                                .frame(width: 20)
                            TextField("stevens.edu email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.nexusSecondary)
                                .frame(width: 20)
                            SecureField("Password", text: $password)
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: handleAuth) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.stevensRed)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

                    Button(action: { isSignUp.toggle(); errorMessage = "" }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "New to Nexus?")
                                .foregroundColor(.nexusSecondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(.stevensRed)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Stevens Institute of Technology")
                    .font(.system(size: 12))
                    .foregroundColor(.nexusSecondary.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
    }

    func handleAuth() {
        guard email.hasSuffix("@stevens.edu") || email.hasSuffix("@gmail.com") else {
            errorMessage = "Please use your @stevens.edu email"
            return
        }

        isLoading = true
        errorMessage = ""

        if isSignUp {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
