import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showPrivacyNotice = true   // show on every launch

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
        .sheet(isPresented: $showPrivacyNotice) {
            PrivacyNoticeSheet { showPrivacyNotice = false }
                .interactiveDismissDisabled(true)
        }
    }
}

// MARK: - Privacy Notice (shown on first launch)

struct PrivacyNoticeSheet: View {
    let onAccept: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // ConsenTerra attribution at the top
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(Color(hex: "#2D6A4F"))
                        .font(.system(size: 12))
                    Text("Hopefully written by ")
                        .font(.system(size: 11))
                        .foregroundColor(.nexusSecondary) +
                    Text("ConsenTerra")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.stevensRed) +
                    Text(" — our sponsor")
                        .font(.system(size: 11))
                        .foregroundColor(.nexusSecondary)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.stevensRed, .primaryContainer],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Your Privacy at Stevens Nexus")
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Before we start, here's exactly what we do — and don't — with your data.")
                        .font(.system(size: 14))
                        .foregroundColor(.nexusSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 0) {
                    privacyRow(
                        icon: "eye.slash.fill",
                        title: "Ghost Mode is one tap",
                        body: "Hide your live location from friends instantly. Your dot disappears for everyone."
                    )
                    Divider().padding(.leading, 60)
                    privacyRow(
                        icon: "person.crop.circle.badge.questionmark",
                        title: "Anonymous reviews & interest",
                        body: "Post event reviews and show interest in housing without revealing your identity."
                    )
                    Divider().padding(.leading, 60)
                    privacyRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Lease analysis stays private",
                        body: "Your lease PDFs are processed for the brief and never shared with landlords or third parties."
                    )
                    Divider().padding(.leading, 60)
                    privacyRow(
                        icon: "graduationcap.fill",
                        title: "Stevens-only network",
                        body: "Only authenticated @stevens.edu accounts can see profiles, listings, and reviews."
                    )
                    Divider().padding(.leading, 60)
                    privacyRow(
                        icon: "chart.bar.xaxis",
                        title: "No tracking, no analytics SDKs",
                        body: "We don't ship Mixpanel, Segment, or Firebase Analytics. Your taps are not telemetry."
                    )
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                .padding(.horizontal, 16)

                Text("By tapping Continue you confirm you've read this notice. You can re-read it any time from Profile → Privacy.")
                    .font(.system(size: 11))
                    .foregroundColor(.nexusSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onAccept) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.stevensRed)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color.nexusSurface.ignoresSafeArea())
    }

    @ViewBuilder
    private func privacyRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.stevensRed)
                .frame(width: 36, height: 36)
                .background(Color.stevensRed.opacity(0.08))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(body).font(.system(size: 13)).foregroundColor(.nexusSecondary)
            }
            Spacer()
        }
        .padding(14)
    }
}

#Preview {
    ContentView()
}
