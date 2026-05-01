import Foundation
import Combine
import FirebaseFirestore

// MARK: - Models
struct FacultyProfile: Identifiable {
    let id: String
    let name: String
    let department: String
    let email: String
    let photoURL: String
    let researchInterests: String
    let bio: String
    let rank: String
    let profileURL: String

    var matchReason: String = ""
    var matchScore: Double = 0.0

    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.department = data["department"] as? String ?? data["department_label"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.photoURL = data["photo_url"] as? String ?? ""
        self.researchInterests = data["research_interests"] as? String ?? ""
        self.bio = data["bio"] as? String ?? ""
        self.rank = data["rank"] as? String ?? "Professor"
        self.profileURL = data["profile_url"] as? String ?? ""
    }
}

// MARK: - FirebaseManager
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()

    @Published var faculty: [FacultyProfile] = []
    @Published var isLoadingFaculty = false

    // MARK: - Faculty
    func fetchFaculty() {
        guard faculty.isEmpty else { return }
        isLoadingFaculty = true

        db.collection("faculty").limit(to: 50).getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoadingFaculty = false
                guard let docs = snapshot?.documents, error == nil else { return }
                self?.faculty = docs.map { FacultyProfile(id: $0.documentID, data: $0.data()) }
            }
        }
    }

    func searchFaculty(query: String) -> [FacultyProfile] {
        guard !query.isEmpty else { return Array(faculty.prefix(3)) }
        let keywords = query.lowercased().components(separatedBy: " ")

        return faculty
            .map { prof -> FacultyProfile in
                var p = prof
                let text = "\(prof.researchInterests) \(prof.bio) \(prof.department)".lowercased()
                let score = keywords.filter { text.contains($0) }.count
                p.matchScore = Double(score)
                p.matchReason = score > 0
                    ? "Matches your interest in \(query) through their research in \(prof.researchInterests.components(separatedBy: ",").first ?? prof.department)."
                    : "General alignment with your interests."
                return p
            }
            .filter { $0.matchScore > 0 }
            .sorted { $0.matchScore > $1.matchScore }
            .prefix(3)
            .map { $0 }
    }

}
