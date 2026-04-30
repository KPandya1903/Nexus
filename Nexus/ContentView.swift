import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Map", systemImage: selectedTab == 0 ? "map.fill" : "map")
                }
                .tag(0)

            ResearchView()
                .tabItem {
                    Label("Research", systemImage: "flask")
                }
                .tag(1)

            HousingView()
                .tabItem {
                    Label("Housing", systemImage: selectedTab == 2 ? "building.2.fill" : "building.2")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .accentColor(.stevensRed)
    }
}

#Preview {
    ContentView()
}
