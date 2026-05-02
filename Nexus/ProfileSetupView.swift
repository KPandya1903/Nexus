import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// File-scope option arrays — reused by EditProfileSheet
let gradOptions = ["Fall 2025", "Spring 2026", "Fall 2026", "Spring 2027", "Fall 2027", "Spring 2028"]
let yearOptions = ["Freshman", "Sophomore", "Junior", "Senior", "Graduate"]
let majorOptions = ["Computer Science", "Software Engineering", "Electrical Engineering", "Mechanical Engineering", "Biomedical Engineering", "Civil Engineering", "Business", "Other"]

struct ProfileSetupView: View {
    @EnvironmentObject var authState: AuthStateManager
    @State private var fullName = ""
    @State private var major = ""
    @State private var gradSemester = "Spring 2026"
    @State private var github = ""
    @State private var about = ""
    @State private var selectedYear: String = "Junior"
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 8) {
                        Circle()
                            .fill(LinearGradient(colors: [.stevensRed, .primaryContainer],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(initials)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        Text("Set Up Your Profile")
                            .font(.system(size: 22, weight: .bold))
                        Text("Help your peers know you better")
                            .font(.system(size: 14))
                            .foregroundColor(.nexusSecondary)
                    }
                    .padding(.top, 16)

                    // Form sections
                    VStack(spacing: 16) {

                        // Basic Info
                        FormSection(title: "Basic Info") {
                            FormField(icon: "person", placeholder: "Full Name", text: $fullName)

                            Divider().padding(.leading, 40)

                            HStack {
                                Image(systemName: "graduationcap")
                                    .foregroundColor(.nexusSecondary)
                                    .frame(width: 20)
                                Picker("Major", selection: $major) {
                                    Text("Select Major").tag("")
                                    ForEach(majorOptions, id: \.self) { m in
                                        Text(m).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.stevensRed)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)

                            Divider().padding(.leading, 40)

                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.nexusSecondary)
                                    .frame(width: 20)
                                Picker("Year", selection: $selectedYear) {
                                    ForEach(yearOptions, id: \.self) { y in
                                        Text(y).tag(y)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.stevensRed)

                                Divider().frame(height: 20)

                                Picker("Graduation", selection: $gradSemester) {
                                    ForEach(gradOptions, id: \.self) { s in
                                        Text(s).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.stevensRed)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }

                        // About
                        FormSection(title: "About You") {
                            HStack(alignment: .top) {
                                Image(systemName: "text.quote")
                                    .foregroundColor(.nexusSecondary)
                                    .frame(width: 20)
                                    .padding(.top, 4)
                                TextField("Tell your peers about yourself, your interests, projects...", text: $about, axis: .vertical)
                                    .lineLimit(3...6)
                            }
                            .padding(14)
                        }

                        // GitHub
                        FormSection(title: "Links") {
                            FormField(icon: "chevron.left.forwardslash.chevron.right", placeholder: "GitHub username (e.g. jhanvi07)", text: $github)
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }

                    // Save Button
                    Button(action: saveProfile) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save & Enter Nexus")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(fullName.isEmpty || major.isEmpty ? Color.gray : Color.stevensRed)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading || fullName.isEmpty || major.isEmpty)
                    .padding(.bottom, 30)
                }
                .padding(16)
            }
            .background(Color.nexusSurface)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var initials: String {
        fullName.split(separator: " ").compactMap { $0.first }.map { String($0) }.prefix(2).joined()
    }

    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else { return }
        isLoading = true

        let data: [String: Any] = [
            "uid": uid,
            "email": email,
            "fullName": fullName,
            "major": major,
            "year": selectedYear,
            "gradSemester": gradSemester,
            "github": github,
            "about": about,
            "ghostMode": false,
            "walletBalance": 20.0,
            "friends": [],
            "profileComplete": true,
            "createdAt": Timestamp()
        ]

        Firestore.firestore().collection("users").document(uid).setData(data) { error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                authState.profileComplete = true
            }
        }
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.nexusSecondary)
                .padding(.leading, 4)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.nexusSecondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding(14)
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthStateManager())
}
