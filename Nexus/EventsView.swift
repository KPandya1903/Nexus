import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine
import PhotosUI

// MARK: - EventComment Model

struct EventComment: Identifiable {
    var id: String
    var eventID: String
    var authorName: String   // "Anonymous" or real name
    var isAnonymous: Bool
    var text: String
    var rating: Int          // 1–5 stars
    var createdAt: Date
    var userID: String
    var imageData: [String] = []  // base64-encoded JPEG strings, 0–3 images
}

// MARK: - EventsView (Main)

struct EventsView: View {
    @EnvironmentObject var authState: AuthStateManager

    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var selectedEvent: CampusEvent? = nil

    private let categories = ["All", "Social", "Workshop", "Fitness", "Cultural", "Networking", "Competition"]

    var filteredEvents: [CampusEvent] {
        sampleEvents
            .filter { event in
                let matchesCategory = selectedCategory == "All" || event.category == selectedCategory
                let query = searchText.lowercased()
                let matchesSearch = query.isEmpty ||
                    event.eventName.lowercased().contains(query) ||
                    event.clubName.lowercased().contains(query) ||
                    event.location.lowercased().contains(query) ||
                    event.category.lowercased().contains(query)
                return matchesCategory && matchesSearch
            }
            .sorted { lhs, rhs in lhs.date < rhs.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nexusSurface.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                CategoryChip(
                                    label: cat,
                                    isSelected: selectedCategory == cat
                                ) {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        selectedCategory = cat
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color.nexusSurface)

                    Divider()

                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.nexusSecondary)
                            .font(.system(size: 16))
                        TextField("Search events, clubs, or locations...", text: $searchText)
                            .font(.system(size: 16))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.nexusSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    if filteredEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 52))
                                .foregroundColor(Color.stevensRed.opacity(0.3))
                            Text("No events found")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.nexusSecondary)
                            Text("Try a different category or search term.")
                                .font(.system(size: 14))
                                .foregroundColor(.nexusSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredEvents) { event in
                                    EventCard(event: event) {
                                        selectedEvent = event
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NexusTopBar()
                }
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
                    .environmentObject(authState)
            }
        }
    }
}

// MARK: - CategoryChip

private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? Color.stevensRed
                        : Color.white
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.outlineVariant, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EventCard

struct EventCard: View {
    let event: CampusEvent
    let onTap: () -> Void

    private var categoryColor: Color { Color(hex: event.colorHex) }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Date badge
                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Text(monthAbbrev)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 54, height: 64)
                .background(Color.stevensRed)
                .cornerRadius(12)

                // Details
                VStack(alignment: .leading, spacing: 5) {
                    Text(event.eventName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(event.clubName)
                        .font(.system(size: 12))
                        .foregroundColor(.nexusSecondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.nexusSecondary)
                        Text("\(event.formattedTime) · \(event.durationText)")
                            .font(.system(size: 12))
                            .foregroundColor(.nexusSecondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                            .foregroundColor(.nexusSecondary)
                        Text(event.location)
                            .font(.system(size: 12))
                            .foregroundColor(.nexusSecondary)
                            .lineLimit(1)
                    }

                    // Bottom row: category + spots + reg badge
                    HStack(spacing: 6) {
                        Text(event.category)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor)
                            .cornerRadius(6)

                        Text(spotsPillText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(spotsColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(spotsColor.opacity(0.12))
                            .cornerRadius(6)

                        if event.registrationRequired {
                            Text("Reg. Required")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "#c47c1a"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#fff3cd"))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: event.date) else { return "--" }
        let out = DateFormatter()
        out.dateFormat = "d"
        return out.string(from: date)
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: event.date) else { return "---" }
        let out = DateFormatter()
        out.dateFormat = "MMM"
        return out.string(from: date).uppercased()
    }

    private var spotsPillText: String {
        if event.spotsAvailable >= 1000 {
            return "\(event.spotsAvailable / 1000)k+ spots"
        }
        return "\(event.spotsAvailable) spots"
    }

    private var spotsColor: Color {
        if event.spotsAvailable < 10  { return .red }
        if event.spotsAvailable < 50  { return Color(hex: "#c47c1a") }
        return Color(hex: "#2D6A4F")
    }
}

// MARK: - EventDetailView

struct EventDetailView: View {
    @EnvironmentObject var authState: AuthStateManager
    @Environment(\.dismiss) private var dismiss
    let event: CampusEvent

    @State private var comments: [EventComment] = []
    @State private var isLoadingComments = true
    @State private var showAddReview = false
    @State private var listener: ListenerRegistration? = nil
    @State private var isRegistered = false
    @State private var loadError: String? = nil

    private var categoryColor: Color { Color(hex: event.colorHex) }

    // MARK: - Rating Summary

    private var averageRating: Double {
        guard !comments.isEmpty else { return 0 }
        let total = comments.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(comments.count)
    }

    private func starCount(for star: Int) -> Int {
        comments.filter { $0.rating == star }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Hero Header
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: categoryIcon(event.category))
                                .font(.system(size: 90))
                                .foregroundColor(.white.opacity(0.12))
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.category.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)

                            Text(event.eventName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(3)

                            Text(event.clubName)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(16)
                    }

                    VStack(alignment: .leading, spacing: 16) {

                        // MARK: Details Card
                        VStack(alignment: .leading, spacing: 0) {
                            detailRow(
                                icon: "calendar",
                                label: "Date",
                                value: event.formattedDate
                            )
                            Divider().padding(.leading, 44)
                            detailRow(
                                icon: "clock",
                                label: "Time",
                                value: event.formattedTime
                            )
                            Divider().padding(.leading, 44)
                            detailRow(
                                icon: "hourglass",
                                label: "Duration",
                                value: event.durationText
                            )
                            Divider().padding(.leading, 44)
                            detailRow(
                                icon: "mappin.and.ellipse",
                                label: "Location",
                                value: event.location
                            )
                            Divider().padding(.leading, 44)

                            // Spots row with color
                            HStack(spacing: 12) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 15))
                                    .foregroundColor(.stevensRed)
                                    .frame(width: 24)
                                Text("Spots")
                                    .font(.system(size: 14))
                                    .foregroundColor(.nexusSecondary)
                                Spacer()
                                Text("\(event.spotsAvailable) available")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(spotsTextColor(event.spotsAvailable))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                            if event.registrationRequired {
                                Divider().padding(.leading, 44)
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: "#c47c1a"))
                                        .frame(width: 24)
                                    Text("Registration Required")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "#c47c1a"))
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About This Event")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.nexusSecondary)
                            Text(event.description)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

                        // Register + Notify button
                        Button(action: toggleRegistration) {
                            HStack {
                                Spacer()
                                Image(systemName: isRegistered ? "bell.fill" : "bell")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isRegistered ? .white : .white)
                                Text(isRegistered ? "Registered — Reminders Set" : "Register & Get Notified")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(isRegistered ? Color(hex: "#2D6A4F") : Color.stevensRed)
                            .cornerRadius(14)
                        }
                        if !event.link.isEmpty, let url = URL(string: event.link) {
                            Link(destination: url) {
                                HStack {
                                    Spacer()
                                    Text("View Event Page")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.stevensRed)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.stevensRed)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(Color.stevensRed.opacity(0.08))
                                .cornerRadius(14)
                            }
                        }

                        // MARK: Rating Summary Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Ratings & Reviews")
                                .font(.system(size: 16, weight: .bold))

                            HStack(alignment: .center, spacing: 20) {
                                // Big average
                                VStack(spacing: 4) {
                                    Text(averageRating > 0 ? String(format: "%.1f", averageRating) : "—")
                                        .font(.system(size: 44, weight: .black))
                                        .foregroundColor(.primary)
                                    StarRow(rating: Int(averageRating.rounded()), size: 14)
                                    Text("\(comments.count) review\(comments.count == 1 ? "" : "s")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.nexusSecondary)
                                }

                                // Bar breakdown
                                VStack(spacing: 4) {
                                    ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                                        HStack(spacing: 6) {
                                            Text("\(star)")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.nexusSecondary)
                                                .frame(width: 10, alignment: .trailing)
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(Color(hex: "#c47c1a"))
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule().fill(Color.surfaceContainer)
                                                    Capsule()
                                                        .fill(Color.stevensRed)
                                                        .frame(width: barWidth(star: star, totalWidth: geo.size.width))
                                                }
                                            }
                                            .frame(height: 6)
                                            Text("\(starCount(for: star))")
                                                .font(.system(size: 11))
                                                .foregroundColor(.nexusSecondary)
                                                .frame(width: 18, alignment: .leading)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

                        // MARK: Reviews Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reviews")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                Button(action: { showAddReview = true }) {
                                    Label("Write a Review", systemImage: "pencil")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.stevensRed)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color.stevensRed.opacity(0.08))
                                        .cornerRadius(10)
                                }
                            }

                            if let err = loadError {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Couldn't load reviews")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.stevensRed)
                                    Text(err)
                                        .font(.system(size: 12))
                                        .foregroundColor(.nexusSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.stevensRed.opacity(0.08))
                                .cornerRadius(10)
                            } else if isLoadingComments {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.stevensRed)
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            } else if comments.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 36))
                                        .foregroundColor(Color.nexusSecondary.opacity(0.4))
                                    Text("No reviews yet. Be the first!")
                                        .font(.system(size: 15))
                                        .foregroundColor(.nexusSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(comments) { comment in
                                        CommentCard(comment: comment)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                    }
                    .padding(16)
                }
            }
            .background(Color.nexusSurface.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddReview) {
                AddReviewSheet(eventID: event.id) {
                    // Force a fresh fetch as a safety net (the snapshot listener
                    // should also fire automatically when the new doc lands)
                    listener?.remove()
                    loadComments()
                }
                    .environmentObject(authState)
            }
        }
        .onAppear { loadComments() }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Registration

    private func toggleRegistration() {
        isRegistered.toggle()
        if isRegistered {
            NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleEventReminders(for: event)
        } else {
            NotificationManager.shared.cancelReminders(for: event.id)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.stevensRed)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.nexusSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func spotsTextColor(_ spots: Int) -> Color {
        if spots < 10  { return .red }
        if spots < 50  { return Color(hex: "#c47c1a") }
        return Color(hex: "#2D6A4F")
    }

    private func barWidth(star: Int, totalWidth: CGFloat) -> CGFloat {
        guard !comments.isEmpty else { return 0 }
        let proportion = Double(starCount(for: star)) / Double(comments.count)
        return CGFloat(proportion) * totalWidth
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Social":       return "person.3.fill"
        case "Workshop":     return "wrench.and.screwdriver.fill"
        case "Fitness":      return "figure.run"
        case "Cultural":     return "music.note"
        case "Networking":   return "network"
        case "Competition":  return "trophy.fill"
        default:             return "calendar"
        }
    }

    // MARK: - Firestore

    private func loadComments() {
        isLoadingComments = true
        loadError = nil
        listener = Firestore.firestore()
            .collection("eventComments")
            .whereField("eventID", isEqualTo: event.id)
            .addSnapshotListener { snapshot, err in
                if let err = err {
                    DispatchQueue.main.async {
                        self.loadError = err.localizedDescription
                        self.isLoadingComments = false
                    }
                    return
                }
                let parsed: [EventComment] = (snapshot?.documents ?? []).compactMap { doc in
                    let d = doc.data()
                    guard
                        let eventID  = d["eventID"]    as? String,
                        let author   = d["authorName"] as? String,
                        let text     = d["text"]       as? String,
                        let rating   = d["rating"]     as? Int,
                        let uid      = d["userID"]     as? String,
                        let ts       = d["createdAt"]  as? Timestamp
                    else { return nil }

                    return EventComment(
                        id: doc.documentID,
                        eventID: eventID,
                        authorName: author,
                        isAnonymous: d["isAnonymous"] as? Bool ?? false,
                        text: text,
                        rating: rating,
                        createdAt: ts.dateValue(),
                        userID: uid,
                        imageData: d["imageData"] as? [String] ?? []
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
                DispatchQueue.main.async {
                    self.comments = parsed
                    self.isLoadingComments = false
                }
            }
    }
}

// MARK: - StarRow

private struct StarRow: View {
    let rating: Int
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index <= rating ? Color.stevensRed : Color.nexusSecondary.opacity(0.4))
            }
        }
    }
}

// MARK: - CommentCard

private struct CommentCard: View {
    let comment: EventComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(comment.isAnonymous ? Color.nexusSecondary.opacity(0.25) : Color.stevensRed.opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(comment.isAnonymous ? "?" : String(comment.authorName.prefix(1)).uppercased())
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(comment.isAnonymous ? .nexusSecondary : .stevensRed)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(relativeTime(comment.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.nexusSecondary)
                }
                StarRow(rating: comment.rating, size: 12)
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Photos (if any)
                if !comment.imageData.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(comment.imageData.enumerated()), id: \.offset) { _, b64 in
                                if let data = Data(base64Encoded: b64),
                                   let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .background(Color.nexusSurface)
        .cornerRadius(12)
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

// MARK: - AddReviewSheet

struct AddReviewSheet: View {
    @EnvironmentObject var authState: AuthStateManager
    let eventID: String
    var onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedRating: Int = 0
    @State private var reviewText: String = ""
    @State private var isAnonymous: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showValidationError: Bool = false
    @State private var submitError: String? = nil

    // Photo upload state
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var pickedImages: [UIImage] = []   // up to 3

    private var fullName: String {
        authState.userProfile["fullName"] as? String ?? "You"
    }

    private var displayName: String {
        isAnonymous ? "Anonymous" : fullName
    }

    private var isValid: Bool {
        selectedRating > 0 && !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Star rating picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Rating")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    withAnimation(.spring(response: 0.25)) {
                                        selectedRating = star
                                    }
                                }) {
                                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                        .font(.system(size: 34))
                                        .foregroundColor(star <= selectedRating ? Color(hex: "#c47c1a") : Color.nexusSecondary.opacity(0.35))
                                        .scaleEffect(star == selectedRating ? 1.15 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Comment TextEditor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Review")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                        ZStack(alignment: .topLeading) {
                            if reviewText.isEmpty {
                                Text("Share your experience...")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(EdgeInsets(top: 14, leading: 10, bottom: 0, trailing: 10))
                            }
                            TextEditor(text: $reviewText)
                                .font(.system(size: 15))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(Color.nexusSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.outlineVariant, lineWidth: 1)
                        )
                    }

                    // Anonymous toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isAnonymous) {
                            Text("Post anonymously")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .tint(.stevensRed)

                        Text("Posting as: \(displayName)")
                            .font(.system(size: 13))
                            .foregroundColor(.nexusSecondary)
                    }
                    .padding(14)
                    .background(Color.nexusSurface)
                    .cornerRadius(12)

                    // Photos
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Photos")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text("\(pickedImages.count)/3")
                                .font(.system(size: 12))
                                .foregroundColor(.nexusSecondary)
                        }
                        Text("Optional — show others what the event looked like.")
                            .font(.system(size: 12))
                            .foregroundColor(.nexusSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(pickedImages.enumerated()), id: \.offset) { idx, img in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(10)
                                        Button(action: { removeImage(at: idx) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                                .font(.system(size: 18))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                                if pickedImages.count < 3 {
                                    PhotosPicker(
                                        selection: $pickerItems,
                                        maxSelectionCount: 3 - pickedImages.count,
                                        matching: .images
                                    ) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 22, weight: .bold))
                                            Text("Add")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .foregroundColor(.stevensRed)
                                        .frame(width: 80, height: 80)
                                        .background(Color.stevensRed.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Color.stevensRed.opacity(0.3),
                                                              style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                        )
                                        .cornerRadius(10)
                                    }
                                    .onChange(of: pickerItems) { _, newItems in
                                        loadImages(from: newItems)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.nexusSurface)
                    .cornerRadius(12)

                    // Validation error
                    if showValidationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Please select a rating and write a review.")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }

                    // Submit error
                    if let err = submitError {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                                Text("Couldn't submit").font(.system(size: 13, weight: .semibold)).foregroundColor(.red)
                            }
                            Text(err).font(.system(size: 12)).foregroundColor(.nexusSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(8)
                    }

                    // Submit button
                    Button(action: submitReview) {
                        ZStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Submit Review")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(isValid ? Color.stevensRed : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                    }
                    .disabled(isSubmitting)
                }
                .padding(20)
            }
            .background(Color.nexusSurface.ignoresSafeArea())
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.stevensRed)
                }
            }
        }
    }

    // MARK: - Submit

    private func submitReview() {
        guard isValid else {
            showValidationError = true
            return
        }
        guard let uid = authState.currentUser?.uid else {
            submitError = "Not signed in. Please sign out and back in."
            return
        }
        showValidationError = false
        submitError = nil
        isSubmitting = true

        // Encode images as base64 JPEG strings (compressed to fit Firestore's 1MB doc limit)
        let imageStrings: [String] = pickedImages.compactMap { img in
            let resized = img.resizedToMaxDimension(800)
            return resized.jpegData(compressionQuality: 0.5)?.base64EncodedString()
        }

        let data: [String: Any] = [
            "eventID":     eventID,
            "authorName":  isAnonymous ? "Anonymous" : fullName,
            "isAnonymous": isAnonymous,
            "text":        reviewText.trimmingCharacters(in: .whitespacesAndNewlines),
            "rating":      selectedRating,
            "createdAt":   Timestamp(),
            "userID":      uid,
            "imageData":   imageStrings
        ]

        Firestore.firestore()
            .collection("eventComments")
            .addDocument(data: data) { error in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if let error = error {
                        submitError = error.localizedDescription
                    } else {
                        onSubmitted()
                        dismiss()
                    }
                }
            }
    }

    // MARK: - Photo helpers

    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var loaded: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    loaded.append(img)
                }
            }
            await MainActor.run {
                let remaining = max(0, 3 - pickedImages.count)
                pickedImages.append(contentsOf: loaded.prefix(remaining))
                pickerItems.removeAll()
            }
        }
    }

    private func removeImage(at index: Int) {
        guard pickedImages.indices.contains(index) else { return }
        pickedImages.remove(at: index)
    }
}

// MARK: - UIImage resize helper

extension UIImage {
    func resizedToMaxDimension(_ maxDimension: CGFloat) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let scale = maxDimension / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Preview

#Preview {
    EventsView()
        .environmentObject(AuthStateManager())
}
