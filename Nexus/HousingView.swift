import SwiftUI

enum ListingStatus {
    case pendingVerification, verified, justRented
}

struct HousingListing: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let price: String
    let beds: String
    let baths: String
    let sqft: String?
    let rating: Double?
    let status: ListingStatus
    let colorHex: String
}

struct HousingView: View {
    let listings = [
        HousingListing(name: "The Shipyard Apartments", address: "2nd St & Hudson St, Hoboken",
                       price: "$2,450/mo", beds: "2 Bed", baths: "1 Bath", sqft: "850 sqft",
                       rating: 4.8, status: .pendingVerification, colorHex: "#8B6914"),
        HousingListing(name: "Castle Point Studio", address: "800 Castle Point Terrace",
                       price: "$1,800/mo", beds: "Studio", baths: "1 Bath", sqft: nil,
                       rating: 4.5, status: .verified, colorHex: "#2D6A4F"),
        HousingListing(name: "Monroe Street Lofts", address: "312 Monroe Street",
                       price: "$2,100/mo", beds: "1 Bed", baths: "1 Bath", sqft: "700 sqft",
                       rating: nil, status: .justRented, colorHex: "#555555"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Verifier Banner
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .offset(x: 20, y: -20)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("OPPORTUNITY")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(1)

                            Text("Become a Verifier")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("Help your peers find safe housing. Earn $10 for every property you physically verify on campus.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))

                            Button(action: {}) {
                                Text("Join the Program")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.stevensRed)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .cornerRadius(999)
                            }
                        }
                        .padding(20)
                    }
                    .background(Color.primaryContainer)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                    // Available Listings Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Available Listings")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Found 24 properties near Castle Point")
                                .font(.system(size: 13))
                                .foregroundColor(.nexusSecondary)
                        }
                        Spacer()
                        Button("See All") {}
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.stevensRed)
                    }

                    // Listing Cards
                    ForEach(listings) { listing in
                        ListingCard(listing: listing)
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(Color.nexusSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NexusTopBar()
                }
            }
        }
    }
}

struct ListingCard: View {
    let listing: HousingListing
    @State private var tapped = false

    var isUnavailable: Bool { listing.status == .justRented }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(hex: listing.colorHex), Color(hex: listing.colorHex).opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.3))
                    )

                HStack {
                    StatusBadge(status: listing.status)
                    Spacer()
                    if let price = Optional(listing.price) {
                        Text(price)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.stevensRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.regularMaterial)
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }

            // Details
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(listing.name)
                        .font(.system(size: 16, weight: .bold))
                        .strikethrough(isUnavailable)
                        .foregroundColor(isUnavailable ? .gray : .primary)
                    Spacer()
                    if let rating = listing.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star")
                                .font(.system(size: 14))
                                .foregroundColor(.stevensRed)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 13))
                                .foregroundColor(.stevensRed)
                        }
                    }
                }

                Text(listing.address)
                    .font(.system(size: 15))
                    .foregroundColor(.nexusSecondary)

                Divider()

                HStack(spacing: 20) {
                    Label(listing.beds, systemImage: "bed.double")
                    Label(listing.baths, systemImage: "shower")
                    if let sqft = listing.sqft {
                        Label(sqft, systemImage: "square")
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(.nexusSecondary)

                // Action Button
                switch listing.status {
                case .pendingVerification:
                    Button(action: {}) {
                        Label("Verify for $10 Bounty", systemImage: "checkmark.shield")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.stevensRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.surfaceContainerLow)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.stevensRed.opacity(0.3)))
                            .cornerRadius(10)
                    }
                case .verified:
                    Button(action: {}) {
                        Text("View Details")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.stevensRed)
                            .cornerRadius(10)
                    }
                case .justRented:
                    Text("Currently Unavailable")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        .opacity(isUnavailable ? 0.7 : 1.0)
        .saturation(isUnavailable ? 0.4 : 1.0)
        .clipped()
    }
}

struct StatusBadge: View {
    let status: ListingStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(bgColor.opacity(0.9))
        .cornerRadius(8)
    }

    var icon: String {
        switch status {
        case .pendingVerification: return "hourglass"
        case .verified: return "checkmark.seal.fill"
        case .justRented: return "clock.arrow.circlepath"
        }
    }

    var label: String {
        switch status {
        case .pendingVerification: return "Pending Verification"
        case .verified: return "Verified by Nexus"
        case .justRented: return "Just Rented"
        }
    }

    var textColor: Color {
        switch status {
        case .pendingVerification: return .nexusSecondary
        case .verified: return Color(hex: "#2D6A4F")
        case .justRented: return .nexusSecondary
        }
    }

    var bgColor: Color {
        switch status {
        case .pendingVerification: return .white
        case .verified: return Color(hex: "#d8f3dc")
        case .justRented: return .white
        }
    }
}

#Preview {
    HousingView()
}
