import CoreLocation
import SwiftUI

// MARK: - Real Stevens Campus Buildings
struct CampusBuilding {
    let name: String
    let shortName: String
    let coordinate: CLLocationCoordinate2D
    let category: BuildingCategory

    enum BuildingCategory {
        case academic, residential, administrative, athletic
    }
}

let stevensBuildings: [String: CampusBuilding] = [
    "Babbio":       CampusBuilding(name: "Babbio Center", shortName: "Babbio",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74487, longitude: -74.02651),
                        category: .academic),
    "Edwin":        CampusBuilding(name: "Edwin A. Stevens Hall", shortName: "Edwin Hall",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74556, longitude: -74.02583),
                        category: .academic),
    "Burchard":     CampusBuilding(name: "Burchard Building", shortName: "Burchard",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74523, longitude: -74.02620),
                        category: .academic),
    "Gianforte":    CampusBuilding(name: "Gianforte Family Hall", shortName: "Gianforte",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74535, longitude: -74.02680),
                        category: .academic),
    "Gateway":      CampusBuilding(name: "Gateway Academic Center", shortName: "Gateway",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74655, longitude: -74.02678),
                        category: .academic),
    "McLean":       CampusBuilding(name: "McLean Hall", shortName: "McLean",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74502, longitude: -74.02598),
                        category: .academic),
    "Kidde":        CampusBuilding(name: "Kidde Hall", shortName: "Kidde",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74515, longitude: -74.02635),
                        category: .academic),
    "ABS":          CampusBuilding(name: "ABS Engineering Center", shortName: "ABS",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74498, longitude: -74.02572),
                        category: .academic),
    "Library":      CampusBuilding(name: "Samuel C. Williams Library", shortName: "Library",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74578, longitude: -74.02748),
                        category: .academic),
    "Howe":         CampusBuilding(name: "Wesley J. Howe Center", shortName: "Howe",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74558, longitude: -74.02720),
                        category: .administrative),
    "UCC":          CampusBuilding(name: "University Center Complex", shortName: "UCC",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74532, longitude: -74.02718),
                        category: .administrative),
    "Palmer":       CampusBuilding(name: "Palmer Hall", shortName: "Palmer",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74598, longitude: -74.02748),
                        category: .residential),
    "Humphreys":    CampusBuilding(name: "Humphreys Hall", shortName: "Humphreys",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74612, longitude: -74.02718),
                        category: .residential),
    "Jonas":        CampusBuilding(name: "Jonas Hall", shortName: "Jonas",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74625, longitude: -74.02745),
                        category: .residential),
    "CastlePoint":  CampusBuilding(name: "Castle Point Hall", shortName: "Castle Point",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74688, longitude: -74.02718),
                        category: .residential),
    "Wellness":     CampusBuilding(name: "Student Wellness Center", shortName: "Wellness",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74622, longitude: -74.02692),
                        category: .administrative),
    "Rocco":        CampusBuilding(name: "Rocco Technology Center", shortName: "Rocco",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74510, longitude: -74.02608),
                        category: .academic),
    "Schaefer":     CampusBuilding(name: "Schaefer Athletic Center", shortName: "Schaefer",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74568, longitude: -74.02788),
                        category: .athletic),
    "Carnegie":     CampusBuilding(name: "Carnegie Laboratory", shortName: "Carnegie",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74542, longitude: -74.02560),
                        category: .academic),
    "Walker":       CampusBuilding(name: "Walker Gymnasium", shortName: "Walker Gym",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74580, longitude: -74.02810),
                        category: .athletic),
    "DeBaun":       CampusBuilding(name: "DeBaun Auditorium", shortName: "DeBaun",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74560, longitude: -74.02640),
                        category: .academic),
    "Pierce":       CampusBuilding(name: "Pierce Dining Hall", shortName: "Pierce",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74610, longitude: -74.02760),
                        category: .administrative),
    "Peirce":       CampusBuilding(name: "Peirce Hall", shortName: "Peirce",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74530, longitude: -74.02550),
                        category: .academic),
    "LoreEl":       CampusBuilding(name: "Lore-El Center", shortName: "Lore-El",
                        coordinate: CLLocationCoordinate2D(latitude: 40.74595, longitude: -74.02700),
                        category: .administrative),
]

// Maps event location strings to building keys
func buildingKeyForEventLocation(_ location: String) -> String? {
    let loc = location.lowercased()
    if loc.contains("babbio")    { return "Babbio" }
    if loc.contains("gateway")   { return "Gateway" }
    if loc.contains("carnegie")  { return "Carnegie" }
    if loc.contains("ucc")       { return "UCC" }
    if loc.contains("debaun") || loc.contains("de baun") { return "DeBaun" }
    if loc.contains("burchard")  { return "Burchard" }
    if loc.contains("walker")    { return "Walker" }
    if loc.contains("schaefer")  { return "Schaefer" }
    if loc.contains("pierce dining") { return "Pierce" }
    if loc.contains("peirce")    { return "Peirce" }
    if loc.contains("library") || loc.contains("williams") { return "Library" }
    if loc.contains("castle point lawn") || loc.contains("castle point lookout") { return "CastlePoint" }
    if loc.contains("lore-el") || loc.contains("lore el") { return "LoreEl" }
    if loc.contains("eas")       { return "Edwin" }
    if loc.contains("howe")      { return "Howe" }
    if loc.contains("kidde")     { return "Kidde" }
    if loc.contains("mclean")    { return "McLean" }
    return nil
}

// MARK: - Schedule Slot
struct ScheduleSlot {
    let day: String       // "Mon", "Tue", "Wed", "Thu", "Fri"
    let startHour: Int    // 24h format
    let endHour: Int
    let courseCode: String
    let buildingKey: String
    let room: String
}

// MARK: - Seed Students
struct SeedStudent {
    let uid: String
    let name: String
    let email: String
    let major: String
    let year: String
    let gradSemester: String
    let github: String
    let about: String
    let schedule: [ScheduleSlot]
    let avatarColor: String
}

let seedStudents: [SeedStudent] = [
    SeedStudent(
        uid: "seed_001", name: "Priya Patel", email: "ppatel@stevens.edu",
        major: "Computer Science", year: "Junior", gradSemester: "Spring 2026",
        github: "priyapatel", about: "ML enthusiast, hackathon lover 🚀",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 10, endHour: 11, courseCode: "CS-546", buildingKey: "Babbio", room: "210"),
            ScheduleSlot(day: "Mon", startHour: 14, endHour: 15, courseCode: "CS-554", buildingKey: "Burchard", room: "118"),
            ScheduleSlot(day: "Tue", startHour: 9, endHour: 10, courseCode: "MA-232", buildingKey: "McLean", room: "101"),
            ScheduleSlot(day: "Wed", startHour: 10, endHour: 11, courseCode: "CS-546", buildingKey: "Babbio", room: "210"),
            ScheduleSlot(day: "Wed", startHour: 13, endHour: 14, courseCode: "CS-554", buildingKey: "Burchard", room: "118"),
            ScheduleSlot(day: "Thu", startHour: 9, endHour: 10, courseCode: "MA-232", buildingKey: "McLean", room: "101"),
            ScheduleSlot(day: "Fri", startHour: 11, endHour: 12, courseCode: "CS-522", buildingKey: "Gateway", room: "301"),
        ],
        avatarColor: "#E91E63"
    ),
    SeedStudent(
        uid: "seed_002", name: "Carlos Rivera", email: "crivera@stevens.edu",
        major: "Software Engineering", year: "Senior", gradSemester: "Fall 2025",
        github: "carlosdev", about: "Full-stack dev, coffee addict ☕",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 9, endHour: 10, courseCode: "CS-555", buildingKey: "Gianforte", room: "102"),
            ScheduleSlot(day: "Mon", startHour: 15, endHour: 16, courseCode: "CS-590", buildingKey: "Babbio", room: "104"),
            ScheduleSlot(day: "Tue", startHour: 11, endHour: 12, courseCode: "CS-545", buildingKey: "Burchard", room: "220"),
            ScheduleSlot(day: "Wed", startHour: 9, endHour: 10, courseCode: "CS-555", buildingKey: "Gianforte", room: "102"),
            ScheduleSlot(day: "Thu", startHour: 11, endHour: 12, courseCode: "CS-545", buildingKey: "Burchard", room: "220"),
            ScheduleSlot(day: "Fri", startHour: 10, endHour: 11, courseCode: "CS-590", buildingKey: "Babbio", room: "104"),
        ],
        avatarColor: "#2196F3"
    ),
    SeedStudent(
        uid: "seed_003", name: "Aisha Johnson", email: "ajohnson@stevens.edu",
        major: "Electrical Engineering", year: "Sophomore", gradSemester: "Spring 2027",
        github: "aishaj", about: "Circuit queen, robotics team captain 🤖",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 8, endHour: 9, courseCode: "EE-201", buildingKey: "McLean", room: "202"),
            ScheduleSlot(day: "Tue", startHour: 14, endHour: 15, courseCode: "EE-202", buildingKey: "Burchard", room: "304"),
            ScheduleSlot(day: "Wed", startHour: 8, endHour: 9, courseCode: "EE-201", buildingKey: "McLean", room: "202"),
            ScheduleSlot(day: "Thu", startHour: 14, endHour: 15, courseCode: "EE-202", buildingKey: "Burchard", room: "304"),
            ScheduleSlot(day: "Fri", startHour: 13, endHour: 14, courseCode: "MA-221", buildingKey: "Edwin", room: "115"),
        ],
        avatarColor: "#9C27B0"
    ),
    SeedStudent(
        uid: "seed_004", name: "Marcus Chen", email: "mchen@stevens.edu",
        major: "Computer Science", year: "Graduate", gradSemester: "Spring 2026",
        github: "marcuschen", about: "PhD candidate, NLP research 📚",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 16, endHour: 17, courseCode: "CS-810", buildingKey: "Gateway", room: "201"),
            ScheduleSlot(day: "Tue", startHour: 10, endHour: 11, courseCode: "CS-800", buildingKey: "Gianforte", room: "301"),
            ScheduleSlot(day: "Wed", startHour: 16, endHour: 17, courseCode: "CS-810", buildingKey: "Gateway", room: "201"),
            ScheduleSlot(day: "Thu", startHour: 10, endHour: 11, courseCode: "CS-800", buildingKey: "Gianforte", room: "301"),
            ScheduleSlot(day: "Fri", startHour: 9, endHour: 10, courseCode: "CS-855", buildingKey: "Library", room: "Study"),
        ],
        avatarColor: "#FF5722"
    ),
    SeedStudent(
        uid: "seed_005", name: "Sofia Martinez", email: "smartinez@stevens.edu",
        major: "Biomedical Engineering", year: "Junior", gradSemester: "Fall 2026",
        github: "sofiamed", about: "Pre-med + engineering = ? 🔬",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 11, endHour: 12, courseCode: "BME-310", buildingKey: "Burchard", room: "102"),
            ScheduleSlot(day: "Tue", startHour: 13, endHour: 14, courseCode: "CH-281", buildingKey: "McLean", room: "305"),
            ScheduleSlot(day: "Wed", startHour: 11, endHour: 12, courseCode: "BME-310", buildingKey: "Burchard", room: "102"),
            ScheduleSlot(day: "Thu", startHour: 13, endHour: 14, courseCode: "CH-281", buildingKey: "McLean", room: "305"),
            ScheduleSlot(day: "Fri", startHour: 14, endHour: 15, courseCode: "BME-401", buildingKey: "ABS", room: "202"),
        ],
        avatarColor: "#4CAF50"
    ),
    SeedStudent(
        uid: "seed_006", name: "Jake Williams", email: "jwilliams@stevens.edu",
        major: "Mechanical Engineering", year: "Senior", gradSemester: "Spring 2026",
        github: "jakewill", about: "CAD wizard, F1 fan 🏎️",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 13, endHour: 14, courseCode: "ME-345", buildingKey: "Kidde", room: "101"),
            ScheduleSlot(day: "Tue", startHour: 15, endHour: 16, courseCode: "ME-400", buildingKey: "ABS", room: "301"),
            ScheduleSlot(day: "Wed", startHour: 13, endHour: 14, courseCode: "ME-345", buildingKey: "Kidde", room: "101"),
            ScheduleSlot(day: "Thu", startHour: 15, endHour: 16, courseCode: "ME-400", buildingKey: "ABS", room: "301"),
            ScheduleSlot(day: "Fri", startHour: 10, endHour: 11, courseCode: "ME-480", buildingKey: "Rocco", room: "204"),
        ],
        avatarColor: "#FF9800"
    ),
    SeedStudent(
        uid: "seed_007", name: "Nadia Rahman", email: "nrahman@stevens.edu",
        major: "Computer Science", year: "Freshman", gradSemester: "Spring 2028",
        github: "nadiar", about: "New to Stevens, loving it so far! 🦅",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 9, endHour: 10, courseCode: "CS-115", buildingKey: "Burchard", room: "118"),
            ScheduleSlot(day: "Mon", startHour: 12, endHour: 13, courseCode: "MA-121", buildingKey: "Edwin", room: "101"),
            ScheduleSlot(day: "Tue", startHour: 10, endHour: 11, courseCode: "PEP-112", buildingKey: "Burchard", room: "220"),
            ScheduleSlot(day: "Wed", startHour: 9, endHour: 10, courseCode: "CS-115", buildingKey: "Burchard", room: "118"),
            ScheduleSlot(day: "Wed", startHour: 12, endHour: 13, courseCode: "MA-121", buildingKey: "Edwin", room: "101"),
            ScheduleSlot(day: "Thu", startHour: 10, endHour: 11, courseCode: "PEP-112", buildingKey: "Burchard", room: "220"),
            ScheduleSlot(day: "Fri", startHour: 11, endHour: 12, courseCode: "CAL-103", buildingKey: "Howe", room: "308"),
        ],
        avatarColor: "#00BCD4"
    ),
    SeedStudent(
        uid: "seed_008", name: "Tyler Brooks", email: "tbrooks@stevens.edu",
        major: "Business", year: "Junior", gradSemester: "Fall 2026",
        github: "tylerb", about: "Aspiring VC, pitch deck pro 💼",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 14, endHour: 15, courseCode: "BUS-340", buildingKey: "Howe", room: "110"),
            ScheduleSlot(day: "Tue", startHour: 12, endHour: 13, courseCode: "BUS-320", buildingKey: "Howe", room: "205"),
            ScheduleSlot(day: "Wed", startHour: 14, endHour: 15, courseCode: "BUS-340", buildingKey: "Howe", room: "110"),
            ScheduleSlot(day: "Thu", startHour: 12, endHour: 13, courseCode: "BUS-320", buildingKey: "Howe", room: "205"),
            ScheduleSlot(day: "Fri", startHour: 15, endHour: 16, courseCode: "BUS-450", buildingKey: "UCC", room: "101"),
        ],
        avatarColor: "#795548"
    ),
    SeedStudent(
        uid: "seed_009", name: "Emma Liu", email: "eliu@stevens.edu",
        major: "Computer Science", year: "Senior", gradSemester: "Spring 2026",
        github: "emmaliu", about: "iOS dev, open source contributor 🍎",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 10, endHour: 11, courseCode: "CS-492", buildingKey: "Gateway", room: "102"),
            ScheduleSlot(day: "Tue", startHour: 14, endHour: 15, courseCode: "CS-496", buildingKey: "Gianforte", room: "201"),
            ScheduleSlot(day: "Wed", startHour: 10, endHour: 11, courseCode: "CS-492", buildingKey: "Gateway", room: "102"),
            ScheduleSlot(day: "Thu", startHour: 14, endHour: 15, courseCode: "CS-496", buildingKey: "Gianforte", room: "201"),
            ScheduleSlot(day: "Fri", startHour: 12, endHour: 13, courseCode: "CS-499", buildingKey: "Babbio", room: "308"),
        ],
        avatarColor: "#F06292"
    ),
    SeedStudent(
        uid: "seed_010", name: "Raj Gupta", email: "rgupta@stevens.edu",
        major: "Software Engineering", year: "Graduate", gradSemester: "Fall 2025",
        github: "rajgupta", about: "DevOps engineer in the making 🛠️",
        schedule: [
            ScheduleSlot(day: "Mon", startHour: 17, endHour: 18, courseCode: "CS-570", buildingKey: "Babbio", room: "104"),
            ScheduleSlot(day: "Tue", startHour: 18, endHour: 19, courseCode: "CS-550", buildingKey: "Gateway", room: "304"),
            ScheduleSlot(day: "Wed", startHour: 17, endHour: 18, courseCode: "CS-570", buildingKey: "Babbio", room: "104"),
            ScheduleSlot(day: "Thu", startHour: 18, endHour: 19, courseCode: "CS-550", buildingKey: "Gateway", room: "304"),
        ],
        avatarColor: "#607D8B"
    ),
]

// MARK: - Current Location Helper
func currentBuildingKey(for student: SeedStudent) -> String? {
    let calendar = Calendar.current
    let now = Date()
    let weekday = calendar.component(.weekday, from: now)
    let hour = calendar.component(.hour, from: now)

    let dayMap = [2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri"]
    guard let today = dayMap[weekday] else { return nil }

    return student.schedule.first(where: {
        $0.day == today && hour >= $0.startHour && hour < $0.endHour
    })?.buildingKey
}
