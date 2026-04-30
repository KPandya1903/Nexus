import SwiftUI
import MapKit

struct FriendMarker: Identifiable {
    let id = UUID()
    let name: String
    let building: String
    let coordinate: CLLocationCoordinate2D
    let initials: String
    let color: Color
}

struct MapView: View {
    @State private var ghostMode = false
    @State private var searchText = ""
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7453, longitude: -74.0279),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    )

    let friends: [FriendMarker] = [
        FriendMarker(name: "Priya", building: "Babbio Center",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7458, longitude: -74.0299),
                     initials: "P", color: .orange),
        FriendMarker(name: "Carlos", building: "Gateway North",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7445, longitude: -74.0265),
                     initials: "C", color: .blue),
        FriendMarker(name: "Mike", building: "Palmer Hall",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7435, longitude: -74.0278),
                     initials: "M", color: .purple),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(position: $position) {
                if !ghostMode {
                    ForEach(friends) { friend in
                        Annotation(friend.building, coordinate: friend.coordinate) {
                            FriendAnnotationView(friend: friend)
                        }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Top bar
            VStack(spacing: 0) {
                NexusTopBar()

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.nexusSecondary)
                    TextField("Search buildings or friends...", text: $searchText)
                        .font(.system(size: 16))
                    Image(systemName: "mic")
                        .foregroundColor(.nexusSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Map controls (right side)
            VStack(spacing: 8) {
                ForEach([("plus", {}), ("minus", {}), ("location.fill", {}), ("square.3.layers.3d", {})], id: \.0) { icon, action in
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 140)
            .padding(.trailing, 16)

            // Ghost mode toggle
            HStack(spacing: 12) {
                Text("Ghost Mode")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.nexusSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Toggle("", isOn: $ghostMode)
                    .labelsHidden()
                    .tint(.stevensRed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .cornerRadius(999)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 90)
        }
    }
}

struct FriendAnnotationView: View {
    let friend: FriendMarker
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.stevensRed, lineWidth: 2)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)

                Circle()
                    .fill(friend.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(friend.initials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            .frame(width: 44, height: 44)

            Text(friend.building)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.stevensRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(999)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
        .onAppear { pulse = true }
    }
}

#Preview {
    MapView()
}
