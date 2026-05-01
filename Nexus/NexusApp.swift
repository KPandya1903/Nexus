import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

@main
struct NexusApp: App {
    @StateObject private var authState = AuthStateManager()

    init() {
        FirebaseApp.configure()
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isLoggedIn && authState.profileComplete {
                    ContentView()
                        .environmentObject(authState)
                } else if authState.isLoggedIn && !authState.profileComplete {
                    ProfileSetupView()
                        .environmentObject(authState)
                } else {
                    LoginView()
                        .environmentObject(authState)
                }
            }
        }
    }
}

class AuthStateManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var profileComplete = false
    @Published var currentUser: User?
    @Published var userProfile: [String: Any] = [:]

    init() {
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = user != nil
                if let uid = user?.uid {
                    self.fetchProfile(uid: uid)
                } else {
                    self.profileComplete = false
                    self.userProfile = [:]
                }
            }
        }
    }

    func fetchProfile(uid: String) {
        Firestore.firestore().collection("users").document(uid).getDocument { doc, _ in
            DispatchQueue.main.async {
                if let data = doc?.data(), doc?.exists == true {
                    self.userProfile = data
                    self.profileComplete = data["profileComplete"] as? Bool ?? false
                } else {
                    self.profileComplete = false
                }
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        isLoggedIn = false
        profileComplete = false
        userProfile = [:]
    }
}
