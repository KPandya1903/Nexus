import SwiftUI
import MapKit
import FirebaseFirestore

let neighborhoodCoordinates: [String: CLLocationCoordinate2D] = [
    "Hoboken":    CLLocationCoordinate2D(latitude: 40.7440, longitude: -74.0324),
    "Jersey City": CLLocationCoordinate2D(latitude: 40.7178, longitude: -74.0431),
    "Union City": CLLocationCoordinate2D(latitude: 40.7662, longitude: -74.0263),
    "Weehawken":  CLLocationCoordinate2D(latitude: 40.7684, longitude: -74.0210),
    "Edgewater":  CLLocationCoordinate2D(latitude: 40.8220, longitude: -74.0140),
    "Bergen":     CLLocationCoordinate2D(latitude: 40.7300, longitude: -74.1100),
    "Bayonne":    CLLocationCoordinate2D(latitude: 40.6690, longitude: -74.1140),
]

func mapNeighborhoodColor(_ neighborhood: String) -> Color {
    switch neighborhood {
    case "Hoboken":    return Color(hex: "#A32638")
    case "Jersey City": return Color(hex: "#1a6b9a")
    case "Union City": return Color(hex: "#6b3fa0")
    case "Weehawken":  return Color(hex: "#2D6A4F")
    case "Edgewater":  return Color(hex: "#c47c1a")
    case "Bergen":     return Color(hex: "#4a4a7a")
    case "Bayonne":    return Color(hex: "#7a3b2e")
    default:           return Color(hex: "#A32638")
    }
}

struct ActiveStudent: Identifiable {
    let id: String
    let name: String
    let building: CampusBuilding
    let courseCode: String
    let room: String
    let avatarColor: Color
    var initials: String {
        name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
    }
}

struct ActiveEvent: Identifiable {
    let id: String
    let event: CampusEvent
    let building: CampusBuilding
}

struct MapView: View {
    @State private var ghostMode = false
    @State private var searchText = ""
    @State private var activeStudents: [ActiveStudent] = []
    @State private var selectedStudent: ActiveStudent? = nil
    @State private var highlightedStudentID: String? = nil
    @State private var mapMode: MapMode = .people
    @State private var selectedEvent: ActiveEvent? = nil
    @State private var mapHousingListings: [HousingRequest] = []
    @State private var selectedHousingListing: HousingRequest? = nil

    enum MapMode { case people, events, housing }

    var searchResults: [ActiveStudent] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return activeStudents.filter {
            $0.name.lowercased().contains(q) ||
            $0.building.name.lowercased().contains(q) ||
            $0.building.shortName.lowercased().contains(q) ||
            $0.courseCode.lowercased().contains(q)
        }
    }
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7455, longitude: -74.0270),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            // 3D Map
            Map(position: $position) {
                if mapMode == .people {
                    ForEach(activeStudents) { student in
                        let isMatch = !searchText.isEmpty && searchResults.contains(where: { $0.id == student.id })
                        let isDimmed = !searchText.isEmpty && !isMatch
                        Annotation(student.building.shortName,
                                   coordinate: student.building.coordinate) {
                            StudentMarkerView(student: student,
                                              isSelected: selectedStudent?.id == student.id,
                                              isHighlighted: isMatch,
                                              isDimmed: isDimmed)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedStudent = selectedStudent?.id == student.id ? nil : student
                                        selectedEvent = nil
                                    }
                                }
                        }
                    }
                } else if mapMode == .events {
                    ForEach(activeEventsOnMap) { ae in
                        Annotation(ae.building.shortName, coordinate: ae.building.coordinate) {
                            EventMarkerView(activeEvent: ae, isSelected: selectedEvent?.id == ae.id)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedEvent = selectedEvent?.id == ae.id ? nil : ae
                                        selectedStudent = nil
                                    }
                                }
                        }
                    }
                } else if mapMode == .housing {
                    ForEach(mapHousingListings) { listing in
                        if let coord = sampleListingCoordinates[listing.id] ?? neighborhoodCoordinates[listing.neighborhood] {
                            Annotation(listing.neighborhood, coordinate: coord) {
                                HousingMarkerView(listing: listing, isSelected: selectedHousingListing?.id == listing.id)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedHousingListing = selectedHousingListing?.id == listing.id ? nil : listing
                                            selectedStudent = nil
                                            selectedEvent = nil
                                        }
                                    }
                            }
                        }
                    }
                }
                if !ghostMode {
                    UserAnnotation()
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Top bar + search
            VStack(spacing: 0) {
                NexusTopBar()

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.nexusSecondary)
                    TextField("Search buildings or friends...", text: $searchText)
                        .font(.system(size: 16))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.nexusSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Search result pills
                if !searchResults.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(searchResults) { student in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedStudent = student
                                        position = .region(MKCoordinateRegion(
                                            center: student.building.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                                        ))
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(student.avatarColor)
                                            .frame(width: 22, height: 22)
                                            .overlay(
                                                Text(student.initials)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(student.name.components(separatedBy: " ").first ?? "")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text(student.building.shortName)
                                                .font(.system(size: 11))
                                                .foregroundColor(.nexusSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(.regularMaterial)
                                    .cornerRadius(999)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 4)
                }

                // People / Events / Housing toggle
                HStack(spacing: 0) {
                    Button(action: { withAnimation(.spring()) { mapMode = .people; selectedEvent = nil; selectedHousingListing = nil } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill").font(.system(size: 12))
                            Text("People").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(mapMode == .people ? .white : .nexusSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(mapMode == .people ? Color.stevensRed : Color.clear)
                        .cornerRadius(999)
                    }
                    Button(action: { withAnimation(.spring()) { mapMode = .events; selectedStudent = nil; selectedHousingListing = nil } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar").font(.system(size: 12))
                            Text("Events").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(mapMode == .events ? .white : .nexusSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(mapMode == .events ? Color.stevensRed : Color.clear)
                        .cornerRadius(999)
                    }
                    Button(action: { withAnimation(.spring()) { mapMode = .housing; selectedStudent = nil; selectedEvent = nil } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill").font(.system(size: 12))
                            Text("Housing").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(mapMode == .housing ? .white : .nexusSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(mapMode == .housing ? Color.stevensRed : Color.clear)
                        .cornerRadius(999)
                    }
                }
                .padding(4)
                .background(.regularMaterial)
                .cornerRadius(999)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Map Controls
            VStack(spacing: 8) {
                MapControlButton(icon: "plus") {
                    zoom(in: true)
                }
                MapControlButton(icon: "minus") {
                    zoom(in: false)
                }
                MapControlButton(icon: "location.fill") {
                    centerOnCampus()
                }
                MapControlButton(icon: "square.3.layers.3d") {}
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 140)
            .padding(.trailing, 16)

            // Bottom stack: student card + ghost mode
            VStack(spacing: 10) {
                Spacer()

                // Selected student popup
                if let student = selectedStudent {
                    StudentInfoCard(student: student) {
                        selectedStudent = nil
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Selected event popup
                if let ae = selectedEvent {
                    EventInfoCard(activeEvent: ae) { selectedEvent = nil }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Selected housing popup
                if let listing = selectedHousingListing {
                    HousingMapCard(listing: listing) { selectedHousingListing = nil }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Online now pill + ghost toggle
                HStack(spacing: 12) {
                    if mapMode == .people && !ghostMode && !activeStudents.isEmpty {
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("\(activeStudents.count) on campus")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .cornerRadius(999)
                    }
                    if mapMode == .events {
                        HStack(spacing: 6) {
                            Circle().fill(Color.stevensRed).frame(width: 8, height: 8)
                            Text("\(activeEventsOnMap.count) events today")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .cornerRadius(999)
                    }
                    if mapMode == .housing {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill").font(.system(size: 10)).foregroundColor(.stevensRed)
                            Text("\(mapHousingListings.count) listings nearby")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.regularMaterial).cornerRadius(999)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 90)
        }
        .onAppear {
            loadActiveStudents()
            LocationManager.shared.requestPermission()
            loadHousingListings()
        }
    }

    var activeEventsOnMap: [ActiveEvent] {
        return sampleEvents.compactMap { event in
            guard let key = buildingKeyForEventLocation(event.location),
                  let building = stevensBuildings[key] else { return nil }
            return ActiveEvent(id: event.id, event: event, building: building)
        }
    }

    func loadActiveStudents() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let hour = calendar.component(.hour, from: Date())
        let dayMap = [2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri"]
        let today = dayMap[weekday] ?? ""

        var active: [ActiveStudent] = []
        for student in seedStudents {
            if let buildingKey = currentBuildingKey(for: student),
               let building = stevensBuildings[buildingKey],
               let slot = student.schedule.first(where: {
                   $0.day == today && hour >= $0.startHour && hour < $0.endHour
               }) {
                active.append(ActiveStudent(
                    id: student.uid,
                    name: student.name,
                    building: building,
                    courseCode: slot.courseCode,
                    room: slot.room,
                    avatarColor: Color(hex: student.avatarColor)
                ))
            }
        }

        // For demo: show all students if none are in class right now
        if active.isEmpty {
            let demoSlots: [(SeedStudent, String)] = [
                (seedStudents[0], "Babbio"),
                (seedStudents[1], "Gateway"),
                (seedStudents[3], "Gianforte"),
                (seedStudents[6], "Edwin"),
                (seedStudents[8], "Library"),
                (seedStudents[9], "UCC"),
            ]
            for (student, buildingKey) in demoSlots {
                if let building = stevensBuildings[buildingKey] {
                    let slot = student.schedule.first!
                    active.append(ActiveStudent(
                        id: student.uid,
                        name: student.name,
                        building: building,
                        courseCode: slot.courseCode,
                        room: slot.room,
                        avatarColor: Color(hex: student.avatarColor)
                    ))
                }
            }
        }

        activeStudents = active
    }

    func zoom(in zoomIn: Bool) {
        let factor: Double = zoomIn ? 0.5 : 2.0
        let currentSpan = MKCoordinateSpan(latitudeDelta: 0.008 * factor, longitudeDelta: 0.008 * factor)
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7455, longitude: -74.0270),
            span: currentSpan
        ))
    }

    func centerOnCampus() {
        let center = LocationManager.shared.userLocation ?? CLLocationCoordinate2D(latitude: 40.7455, longitude: -74.0270)
        position = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        ))
    }

    func loadHousingListings() {
        // Always seed with demo listings so the map has data even before Firestore writes
        self.mapHousingListings = sampleHousingListings

        Firestore.firestore().collection("housingRequests")
            .whereField("status", in: ["open", "claimed"])
            .limit(to: 20)
            .getDocuments { snapshot, _ in
                let docs = snapshot?.documents ?? []
                let live: [HousingRequest] = docs.compactMap { doc in
                    let d = doc.data()
                    guard let listerID = d["listerID"] as? String,
                          let address = d["address"] as? String,
                          let neighborhood = d["neighborhood"] as? String,
                          let bountyAmount = d["bountyAmount"] as? Double,
                          let status = d["status"] as? String,
                          let createdTS = d["createdAt"] as? Timestamp,
                          let deadlineTS = d["deadlineAt"] as? Timestamp
                    else { return nil }
                    return HousingRequest(
                        id: doc.documentID,
                        listerID: listerID,
                        listerName: d["listerName"] as? String ?? "",
                        address: address,
                        neighborhood: neighborhood,
                        listingURL: d["listingURL"] as? String ?? "",
                        bountyAmount: bountyAmount,
                        status: status,
                        verifierID: d["verifierID"] as? String,
                        verifierName: d["verifierName"] as? String,
                        videoLink: d["videoLink"] as? String,
                        photoNote: d["photoNote"] as? String,
                        createdAt: createdTS.dateValue(),
                        deadlineAt: deadlineTS.dateValue(),
                        satisfactionConfirmed: d["satisfactionConfirmed"] as? Bool ?? false,
                        beds: d["beds"] as? String ?? "1 Bed",
                        baths: d["baths"] as? String ?? "1 Bath",
                        monthlyRent: d["monthlyRent"] as? String ?? ""
                    )
                }
                if !live.isEmpty {
                    DispatchQueue.main.async {
                        self.mapHousingListings = sampleHousingListings + live
                    }
                }
            }
    }
}

// Sample housing listings for the map — Hoboken-heavy since most students live there
let sampleHousingListings: [HousingRequest] = [
    HousingRequest(
        id: "sample-hob-1", listerID: "demo", listerName: "Sarah K.",
        address: "12th & Garden St, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 15, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "2 Bed", baths: "1 Bath", monthlyRent: "$2,400/mo"
    ),
    HousingRequest(
        id: "sample-hob-2", listerID: "demo", listerName: "Daniel M.",
        address: "Bloomfield St & 4th, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 20, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$2,150/mo"
    ),
    HousingRequest(
        id: "sample-hob-3", listerID: "demo", listerName: "Emily R.",
        address: "Washington St & 8th, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 10, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "Studio", baths: "1 Bath", monthlyRent: "$1,800/mo"
    ),
    HousingRequest(
        id: "sample-hob-4", listerID: "demo", listerName: "Raj P.",
        address: "Hudson St & 5th, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 25, status: "claimed",
        verifierID: "v1", verifierName: "Tyler B.", videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(36*3600),
        satisfactionConfirmed: false,
        beds: "3 Bed", baths: "2 Bath", monthlyRent: "$3,500/mo"
    ),
    HousingRequest(
        id: "sample-hob-5", listerID: "demo", listerName: "Sofia L.",
        address: "Park Ave & 11th, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 15, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "2 Bed", baths: "2 Bath", monthlyRent: "$2,700/mo"
    ),
    HousingRequest(
        id: "sample-hob-6", listerID: "demo", listerName: "Aisha J.",
        address: "Adams St & 6th, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 20, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$1,950/mo"
    ),
    HousingRequest(
        id: "sample-hob-7", listerID: "demo", listerName: "Marcus C.",
        address: "Garden St & 14th, Hoboken", neighborhood: "Hoboken",
        listingURL: "", bountyAmount: 10, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "2 Bed", baths: "1 Bath", monthlyRent: "$2,500/mo"
    ),
    HousingRequest(
        id: "sample-jc-1", listerID: "demo", listerName: "Marcus T.",
        address: "Grove St & Newark Ave, Jersey City", neighborhood: "Jersey City",
        listingURL: "", bountyAmount: 20, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$1,950/mo"
    ),
    HousingRequest(
        id: "sample-uc-1", listerID: "demo", listerName: "Priya S.",
        address: "32nd St, Union City", neighborhood: "Union City",
        listingURL: "", bountyAmount: 10, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "Studio", baths: "1 Bath", monthlyRent: "$1,500/mo"
    ),
    HousingRequest(
        id: "sample-wee-1", listerID: "demo", listerName: "Jake W.",
        address: "Boulevard East, Weehawken", neighborhood: "Weehawken",
        listingURL: "", bountyAmount: 25, status: "claimed",
        verifierID: "v2", verifierName: "Nadia R.", videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(36*3600),
        satisfactionConfirmed: false,
        beds: "2 Bed", baths: "2 Bath", monthlyRent: "$2,800/mo"
    ),
    HousingRequest(
        id: "sample-edge-1", listerID: "demo", listerName: "Tyler B.",
        address: "River Rd, Edgewater", neighborhood: "Edgewater",
        listingURL: "", bountyAmount: 30, status: "open",
        verifierID: nil, verifierName: nil, videoLink: nil, photoNote: nil,
        createdAt: Date(), deadlineAt: Date().addingTimeInterval(48*3600),
        satisfactionConfirmed: false,
        beds: "1 Bed", baths: "1 Bath", monthlyRent: "$2,100/mo"
    ),
]

// Per-listing coordinate overrides so multiple Hoboken pins don't stack
let sampleListingCoordinates: [String: CLLocationCoordinate2D] = [
    "sample-hob-1": CLLocationCoordinate2D(latitude: 40.7505, longitude: -74.0345),
    "sample-hob-2": CLLocationCoordinate2D(latitude: 40.7390, longitude: -74.0335),
    "sample-hob-3": CLLocationCoordinate2D(latitude: 40.7448, longitude: -74.0290),
    "sample-hob-4": CLLocationCoordinate2D(latitude: 40.7405, longitude: -74.0285),
    "sample-hob-5": CLLocationCoordinate2D(latitude: 40.7480, longitude: -74.0315),
    "sample-hob-6": CLLocationCoordinate2D(latitude: 40.7420, longitude: -74.0360),
    "sample-hob-7": CLLocationCoordinate2D(latitude: 40.7530, longitude: -74.0300),
]

struct StudentMarkerView: View {
    let student: ActiveStudent
    let isSelected: Bool
    var isHighlighted: Bool = false
    var isDimmed: Bool = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected || isHighlighted {
                    Circle()
                        .stroke(isHighlighted ? Color.yellow : student.avatarColor, lineWidth: isHighlighted ? 3 : 2)
                        .scaleEffect(pulse ? 1.6 : 1.0)
                        .opacity(pulse ? 0 : 0.9)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
                }

                Circle()
                    .fill(student.avatarColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(student.initials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(Circle().stroke(isHighlighted ? Color.yellow : Color.white, lineWidth: isHighlighted ? 3 : 2))
                    .shadow(color: student.avatarColor.opacity(0.4), radius: isHighlighted ? 8 : 4, y: 2)
                    .scaleEffect(isSelected || isHighlighted ? 1.2 : 1.0)
                    .opacity(isDimmed ? 0.3 : 1.0)
            }
            .frame(width: 44, height: 44)

            Text(student.name.components(separatedBy: " ").first ?? "")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.stevensRed)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white)
                .cornerRadius(999)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .opacity(isDimmed ? 0.3 : 1.0)
        }
        .onAppear { pulse = true }
    }
}

struct StudentInfoCard: View {
    let student: ActiveStudent
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(student.avatarColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(student.initials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(student.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(student.building.name)
                    .font(.system(size: 13))
                    .foregroundColor(.nexusSecondary)
                HStack(spacing: 4) {
                    Image(systemName: "book")
                        .font(.system(size: 11))
                    Text("\(student.courseCode) · Room \(student.room)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.stevensRed)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.nexusSecondary)
                    .font(.system(size: 20))
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

struct MapControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.stevensRed)
                .frame(width: 44, height: 44)
                .background(.regularMaterial)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}

struct EventMarkerView: View {
    let activeEvent: ActiveEvent
    let isSelected: Bool
    @State private var pulse = false

    var color: Color { Color(hex: activeEvent.event.colorHex) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .scaleEffect(pulse ? 1.6 : 1.0)
                        .opacity(pulse ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
                }
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
            }
            .frame(width: 44, height: 44)

            Text(activeEvent.event.eventName.components(separatedBy: "—").first?.trimmingCharacters(in: .whitespaces) ?? activeEvent.event.eventName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white)
                .cornerRadius(999)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .frame(maxWidth: 80)
        }
        .onAppear { pulse = true }
    }
}

struct EventInfoCard: View {
    let activeEvent: ActiveEvent
    let onDismiss: () -> Void

    enum RegStatus {
        case passed, openWithLink, closedNoLink, notRequired
    }

    var status: RegStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let eventDate = formatter.date(from: activeEvent.event.date),
           Calendar.current.startOfDay(for: eventDate) < Calendar.current.startOfDay(for: Date()) {
            return .passed
        }
        if !activeEvent.event.registrationRequired { return .notRequired }
        if activeEvent.event.link.isEmpty { return .closedNoLink }
        return .openWithLink
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: activeEvent.event.colorHex))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(activeEvent.event.eventName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                    Text(activeEvent.event.clubName)
                        .font(.system(size: 12))
                        .foregroundColor(.nexusSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(activeEvent.event.formattedTime) · \(activeEvent.building.shortName)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: activeEvent.event.colorHex))
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.nexusSecondary)
                        .font(.system(size: 20))
                }
            }

            // Registration status row
            switch status {
            case .openWithLink:
                if let url = URL(string: activeEvent.event.link) {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            Circle().fill(Color(hex: "#2D6A4F")).frame(width: 8, height: 8)
                            Text("Registration Open")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#2D6A4F"))
                            Spacer()
                            Text("Register Now")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, 12)
                        .padding(.trailing, 8)
                        .background(
                            HStack(spacing: 0) {
                                Color(hex: "#d8f3dc")
                                Color.stevensRed.frame(width: 130)
                            }
                        )
                        .cornerRadius(10)
                    }
                }
            case .notRequired:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#2D6A4F"))
                        .font(.system(size: 13))
                    Text("No Registration Needed — Just Show Up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D6A4F"))
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#d8f3dc"))
                .cornerRadius(10)
            case .closedNoLink:
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.stevensRed)
                        .font(.system(size: 12))
                    Text("Registration Closed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.stevensRed)
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.stevensRed.opacity(0.1))
                .cornerRadius(10)
            case .passed:
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.xmark.fill")
                        .foregroundColor(.nexusSecondary)
                        .font(.system(size: 13))
                    Text("Event has passed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.nexusSecondary)
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

struct HousingMarkerView: View {
    let listing: HousingRequest
    let isSelected: Bool
    @State private var pulse = false

    var color: Color { mapNeighborhoodColor(listing.neighborhood) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle().stroke(color, lineWidth: 2)
                        .scaleEffect(pulse ? 1.6 : 1.0).opacity(pulse ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
                }
                Circle().fill(color).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "building.2.fill").font(.system(size: 16, weight: .bold)).foregroundColor(.white))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
            }
            .frame(width: 44, height: 44)

            if !listing.monthlyRent.isEmpty {
                Text(listing.monthlyRent)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(color)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.white).cornerRadius(999)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }
        }
        .onAppear { pulse = true }
    }
}

struct HousingMapCard: View {
    let listing: HousingRequest
    let onDismiss: () -> Void

    var color: Color { mapNeighborhoodColor(listing.neighborhood) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(listing.neighborhood)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(999)
                Spacer()
                Text("🎯 $\(Int(listing.bountyAmount)) bounty")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.25)).cornerRadius(999)
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.nexusSecondary).font(.system(size: 18))
                }
            }

            Text(listing.address).font(.system(size: 15, weight: .semibold))

            HStack(spacing: 12) {
                Label(listing.monthlyRent, systemImage: "dollarsign.circle").font(.system(size: 12)).foregroundColor(.stevensRed)
                Label(listing.beds, systemImage: "bed.double").font(.system(size: 12)).foregroundColor(.nexusSecondary)
                Label(listing.baths, systemImage: "shower").font(.system(size: 12)).foregroundColor(.nexusSecondary)
            }

            Text("Status: \(listing.status.capitalized)")
                .font(.system(size: 11)).foregroundColor(.nexusSecondary)
        }
        .padding(14)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

#Preview {
    MapView()
}
