import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
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

                EventsView()
                    .tabItem {
                        Label("Events", systemImage: selectedTab == 3 ? "calendar.badge.plus" : "calendar")
                    }
                    .tag(3)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                    }
                    .tag(4)
            }
            .accentColor(.stevensRed)

            // Global AI assistant — bottom-right normally, bottom-left on Housing
            // (Housing has its own + button in the bottom-right)
            VStack {
                Spacer()
                HStack {
                    if selectedTab == 2 {
                        AssistantFloatingButton()
                        Spacer()
                    } else {
                        Spacer()
                        AssistantFloatingButton()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 70)
            }
        }
    }
}

#Preview {
    ContentView()
}
