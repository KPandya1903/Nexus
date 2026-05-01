import Foundation

// MARK: - CampusEvent Model

struct CampusEvent: Identifiable {
    let id: String
    let eventName: String
    let clubName: String
    let category: String      // "Social", "Workshop", "Fitness", "Cultural", "Networking", "Competition"
    let description: String
    let eventType: String
    let date: String          // "2026-05-02"
    let time: String          // "18:00"
    let durationMinutes: Int
    let location: String
    let spotsAvailable: Int
    let registrationRequired: Bool
    let link: String
    var colorHex: String      // derived from category

    // MARK: - Computed Helpers

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: self.date) else { return self.date }
        let out = DateFormatter()
        out.dateFormat = "EEE, MMM d"
        return out.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: self.time) else { return self.time }
        let out = DateFormatter()
        out.dateFormat = "h:mm a"
        return out.string(from: date)
    }

    var durationText: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours == 0 {
            return "\(minutes) min"
        } else if minutes == 0 {
            return "\(hours) hr\(hours > 1 ? "s" : "")"
        } else {
            return "\(hours) hr \(minutes) min"
        }
    }
}

// MARK: - Category Color Helper

func categoryColor(_ category: String) -> String {
    switch category {
    case "Social":       return "#1a6b9a"
    case "Workshop":     return "#A32638"
    case "Fitness":      return "#2D6A4F"
    case "Cultural":     return "#6b3fa0"
    case "Networking":   return "#c47c1a"
    case "Competition":  return "#4a4a7a"
    default:             return "#A32638"
    }
}

// MARK: - Seed Data

let sampleEvents: [CampusEvent] = [
    CampusEvent(
        id: "evt1",
        eventName: "End-of-Semester Hack Night",
        clubName: "Stevens Computer Science Club",
        category: "Social",
        description: "Pizza, energy drinks, and three-hour build sprints. Bring a project or pair up on the table prompt.",
        eventType: "In-Person",
        date: "2026-04-30",
        time: "19:00",
        durationMinutes: 180,
        location: "Gateway North 103",
        spotsAvailable: 60,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/cs-club/hack-night",
        colorHex: categoryColor("Social")
    ),
    CampusEvent(
        id: "evt2",
        eventName: "South Asian Cultural Night — Mehfil",
        clubName: "South Asian Student Association",
        category: "Cultural",
        description: "End-of-semester cultural showcase featuring Bollywood dance, classical music, qawwali, and Indian street food.",
        eventType: "In-Person",
        date: "2026-05-02",
        time: "18:00",
        durationMinutes: 240,
        location: "DeBaun Auditorium",
        spotsAvailable: 350,
        registrationRequired: true,
        link: "https://stevens.campusgroups.com/sasa/mehfil-2026",
        colorHex: categoryColor("Cultural")
    ),
    CampusEvent(
        id: "evt3",
        eventName: "Robotics Showcase — Capstone Project Demos",
        clubName: "Stevens Robotics Club",
        category: "Workshop",
        description: "Senior capstone teams demo their final robotics projects. Refreshments provided.",
        eventType: "In-Person",
        date: "2026-05-02",
        time: "14:00",
        durationMinutes: 120,
        location: "Carnegie Lab 207",
        spotsAvailable: 100,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/robotics/capstone-showcase",
        colorHex: categoryColor("Workshop")
    ),
    CampusEvent(
        id: "evt4",
        eventName: "Career Fair — Spring Tech & Engineering",
        clubName: "University / Graduate Life",
        category: "Networking",
        description: "Stevens Spring Career Fair. 60+ employers attending including Bloomberg, JPMorgan, BAE Systems, L3Harris, and ADP.",
        eventType: "In-Person",
        date: "2026-05-05",
        time: "11:00",
        durationMinutes: 240,
        location: "Walker Gymnasium",
        spotsAvailable: 1500,
        registrationRequired: true,
        link: "https://stevens.campusgroups.com/career-center/spring-fair",
        colorHex: categoryColor("Networking")
    ),
    CampusEvent(
        id: "evt5",
        eventName: "Stress-Free Sunday — Therapy Dogs Visit",
        clubName: "Counseling and Psychological Services",
        category: "Social",
        description: "Certified therapy dogs in the UCC for de-stressing before finals week. CAPS staff available.",
        eventType: "In-Person",
        date: "2026-05-03",
        time: "13:00",
        durationMinutes: 180,
        location: "UCC Lobby",
        spotsAvailable: 200,
        registrationRequired: false,
        link: "",
        colorHex: categoryColor("Social")
    ),
    CampusEvent(
        id: "evt6",
        eventName: "AI Paper Reading Group — Constitutional AI",
        clubName: "S.py: The Graduate AI Club",
        category: "Workshop",
        description: "Weekly paper reading. This week: Anthropic's Constitutional AI paper and trade-offs vs RLHF.",
        eventType: "In-Person",
        date: "2026-05-04",
        time: "18:00",
        durationMinutes: 90,
        location: "Carnegie Lab 315",
        spotsAvailable: 25,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/spy-ai/cai-paper",
        colorHex: categoryColor("Workshop")
    ),
    CampusEvent(
        id: "evt7",
        eventName: "Friday Iftar & Community Dinner",
        clubName: "Muslim Student Association",
        category: "Cultural",
        description: "Open community iftar to close out the semester. Food provided; bring friends.",
        eventType: "In-Person",
        date: "2026-05-01",
        time: "19:30",
        durationMinutes: 120,
        location: "UCC Tech Flex Room",
        spotsAvailable: 100,
        registrationRequired: true,
        link: "https://stevens.campusgroups.com/msa/iftar-may1",
        colorHex: categoryColor("Cultural")
    ),
    CampusEvent(
        id: "evt8",
        eventName: "Saturday Morning Long Run — Hudson River Path",
        clubName: "Stevens Running Club",
        category: "Fitness",
        description: "8-mile out-and-back along the Hudson River Walkway. Two pace groups: 8:30/mi and 10:00/mi.",
        eventType: "In-Person",
        date: "2026-05-02",
        time: "08:00",
        durationMinutes: 90,
        location: "Castle Point Lawn",
        spotsAvailable: 40,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/running-club/saturday-long-run",
        colorHex: categoryColor("Fitness")
    ),
    CampusEvent(
        id: "evt9",
        eventName: "DeBaun Spring Concert — Stevens A Cappella",
        clubName: "Stevens A Cappella",
        category: "Cultural",
        description: "Annual end-of-semester concert with pop covers, jazz standards, and senior tribute.",
        eventType: "In-Person",
        date: "2026-05-08",
        time: "20:00",
        durationMinutes: 90,
        location: "DeBaun Auditorium",
        spotsAvailable: 400,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/a-cappella/spring-concert",
        colorHex: categoryColor("Cultural")
    ),
    CampusEvent(
        id: "evt10",
        eventName: "Trivia Night — Engineering Lore Edition",
        clubName: "Stevens Trivia Club",
        category: "Competition",
        description: "Five rounds of trivia: famous engineers, NJ history, Stevens campus lore, internet pop culture. Teams of 4. Winner gets $50 dining gift card.",
        eventType: "In-Person",
        date: "2026-05-09",
        time: "19:00",
        durationMinutes: 120,
        location: "Pierce Dining Hall",
        spotsAvailable: 80,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/trivia/eng-lore",
        colorHex: categoryColor("Competition")
    ),
    CampusEvent(
        id: "evt11",
        eventName: "Cyber Defense CTF Practice — Web Exploitation",
        clubName: "Stevens Cyber Defense Team",
        category: "Workshop",
        description: "Weekly CTF practice. This week: SQL injection and SSRF. Newcomers paired with veterans.",
        eventType: "In-Person",
        date: "2026-05-04",
        time: "19:00",
        durationMinutes: 120,
        location: "EAS 322",
        spotsAvailable: 30,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/cyber-defense/ctf-web",
        colorHex: categoryColor("Workshop")
    ),
    CampusEvent(
        id: "evt12",
        eventName: "Pre-Finals Study Jam — All Night Edition",
        clubName: "University / Graduate Life",
        category: "Social",
        description: "Library stays open until 3am with free coffee, snacks, and drop-in TA tutoring for Calc III, Probability, Algorithms.",
        eventType: "In-Person",
        date: "2026-05-12",
        time: "20:00",
        durationMinutes: 420,
        location: "Samuel C. Williams Library",
        spotsAvailable: 300,
        registrationRequired: false,
        link: "",
        colorHex: categoryColor("Social")
    ),
]

private let _unusedExtraEvents: [CampusEvent] = [
    CampusEvent(
        id: "evt13",
        eventName: "Spring Carnival — Last Day of Classes",
        clubName: "University / Graduate Life",
        category: "Social",
        description: "Annual end-of-classes carnival. Food trucks, live music from student bands, lawn games, free swag.",
        eventType: "In-Person",
        date: "2026-05-23",
        time: "13:00",
        durationMinutes: 360,
        location: "Castle Point Lawn",
        spotsAvailable: 2000,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/grad-life/spring-carnival",
        colorHex: categoryColor("Social")
    ),
    CampusEvent(
        id: "evt14",
        eventName: "SWiCS End-of-Semester Brunch",
        clubName: "Stevens Women in Computer Science",
        category: "Networking",
        description: "Brunch with seniors who landed full-time CS roles. Informal Q&A on interview prep and salary negotiation.",
        eventType: "In-Person",
        date: "2026-05-07",
        time: "11:00",
        durationMinutes: 120,
        location: "Pierce Dining Hall — Private Room",
        spotsAvailable: 40,
        registrationRequired: true,
        link: "https://stevens.campusgroups.com/swics/spring-brunch",
        colorHex: categoryColor("Networking")
    ),
    CampusEvent(
        id: "evt15",
        eventName: "Asian Heritage Month — Closing Cultural Festival",
        clubName: "Society of Asian Scientists and Engineers",
        category: "Cultural",
        description: "Closing festival for AAPI Heritage Month. Food from Chinese, Korean, Japanese, Vietnamese, Filipino, and Indian student associations.",
        eventType: "In-Person",
        date: "2026-05-15",
        time: "17:00",
        durationMinutes: 240,
        location: "Castle Point Lawn",
        spotsAvailable: 500,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/sase/heritage-festival",
        colorHex: categoryColor("Cultural")
    ),
    CampusEvent(
        id: "evt16",
        eventName: "Wednesday Powerlifting Open Lift",
        clubName: "Stevens Powerlifting",
        category: "Fitness",
        description: "Open gym for squat/bench/deadlift practice. Veteran lifters spot newcomers. Form check available.",
        eventType: "In-Person",
        date: "2026-05-06",
        time: "17:00",
        durationMinutes: 120,
        location: "Schaefer Athletic Center — Weight Room",
        spotsAvailable: 20,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/powerlifting/open-lift",
        colorHex: categoryColor("Fitness")
    ),
    CampusEvent(
        id: "evt17",
        eventName: "Graduate Mixer — May Edition",
        clubName: "University / Graduate Life",
        category: "Networking",
        description: "Monthly mixer for all graduate students. Light food, drinks, networking with students from other programs.",
        eventType: "In-Person",
        date: "2026-05-01",
        time: "18:00",
        durationMinutes: 120,
        location: "Babbio Center Lobby",
        spotsAvailable: 200,
        registrationRequired: true,
        link: "https://stevens.campusgroups.com/grad-life/may-mixer",
        colorHex: categoryColor("Networking")
    ),
    CampusEvent(
        id: "evt18",
        eventName: "Akshaya Tritiya Pooja & Lunch",
        clubName: "Hindu YUVA",
        category: "Cultural",
        description: "Brief pooja followed by traditional South Indian meal. Open to all faiths and backgrounds.",
        eventType: "In-Person",
        date: "2026-05-09",
        time: "12:00",
        durationMinutes: 180,
        location: "UCC Tech Flex Room",
        spotsAvailable: 120,
        registrationRequired: true,
        link: "https://stevens.campusgroups.com/hindu-yuva/akshaya-tritiya",
        colorHex: categoryColor("Cultural")
    ),
    CampusEvent(
        id: "evt19",
        eventName: "Stevens Society of AI — Final Project Demos",
        clubName: "Stevens Society of Artificial Intelligence",
        category: "Workshop",
        description: "Members demo end-of-semester AI projects. Audience picks the winner.",
        eventType: "In-Person",
        date: "2026-05-13",
        time: "18:00",
        durationMinutes: 120,
        location: "Carnegie Lab 207",
        spotsAvailable: 80,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/ssai/spring-demos",
        colorHex: categoryColor("Workshop")
    ),
    CampusEvent(
        id: "evt20",
        eventName: "Year-End Latin Night",
        clubName: "Latin American Association",
        category: "Cultural",
        description: "Salsa, bachata, reggaeton. Beginner dance lesson at 7pm followed by open dancing. Empanadas and arepas.",
        eventType: "In-Person",
        date: "2026-05-22",
        time: "19:00",
        durationMinutes: 240,
        location: "UCC Tech Flex Room",
        spotsAvailable: 200,
        registrationRequired: false,
        link: "https://stevens.campusgroups.com/laa/year-end-latin",
        colorHex: categoryColor("Cultural")
    )
]
