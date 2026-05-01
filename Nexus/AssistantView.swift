import SwiftUI

// MARK: - Hardcoded Q&A

struct AssistantQA: Identifiable {
    let id: Int
    let question: String
    let answer: String
}

let assistantQuestions: [AssistantQA] = [
    AssistantQA(
        id: 1,
        question: "What is The Stevens Nexus?",
        answer: "The Stevens Nexus is your campus OS — three pillars in one app:\n\n• Academic Discovery — AI-matched professors and seminar spotlights.\n• Social Presence — see friends on a 3D campus map and discover events.\n• Housing Trust — verify off-campus rentals, find roommates, and get AI lease analysis."
    ),
    AssistantQA(
        id: 2,
        question: "How do I find a research professor?",
        answer: "Open the Research tab → describe your interest in the AI Assistant box → tap the arrow.\n\nNexus matches you against Stevens faculty using research interests and publications. Tap any professor card to see their full profile, then tap \"Draft Outreach Email\" to generate a personalized cold email."
    ),
    AssistantQA(
        id: 3,
        question: "How does the Lease Verifier work?",
        answer: "Housing tab → \"Lease Verifier\" red banner at the top.\n\n1. Toggle context (F-1 visa, first U.S. lease).\n2. Upload your lease PDF.\n3. Tap \"Analyze My Lease\".\n\nYou get a Consent Clarity Score, a money map of all costs, red flags grounded in NJ statutes, and ready-to-send negotiation messages."
    ),
    AssistantQA(
        id: 4,
        question: "How does the housing bounty system work?",
        answer: "Can't visit a place in person? Post a verification request:\n\n1. Housing tab → tap the red + button.\n2. Add the address, listing URL, and a $10–$30 bounty.\n3. A Stevens student near that area claims it, visits within 48 hours, submits photos + a walk-through video link.\n4. You review — if satisfied, the bounty releases. If they miss the deadline, the bounty refunds and they're banned."
    ),
    AssistantQA(
        id: 5,
        question: "How do I find a roommate?",
        answer: "Housing tab → Roommates sub-tab.\n\nBrowse Stevens students looking for housemates filtered by budget, neighborhood, move-in date, and lifestyle (clean, night owl, social, pet-friendly, etc.). Tap + to post your own profile so others can find you."
    ),
    AssistantQA(
        id: 6,
        question: "What is Ghost Mode?",
        answer: "Ghost Mode hides your live location from the campus map so friends can't see where you are.\n\nToggle it on the Profile tab. Your dot disappears from everyone's map until you turn it off — but you can still see friends who are visible."
    ),
    AssistantQA(
        id: 7,
        question: "How do I see today's events?",
        answer: "Events tab — filter by category (Social, Workshop, Fitness, Cultural, Networking, Competition).\n\nTap any event to see full details, peer reviews, and a star rating breakdown. Hit \"Register & Get Notified\" and you'll get a reminder 1 day and 1 hour before the event."
    ),
    AssistantQA(
        id: 8,
        question: "How do I leave a review on an event?",
        answer: "Events tab → tap any event → scroll to Reviews → \"Write a Review\".\n\nGive 1–5 stars, write your thoughts, and choose to post with your name or anonymously. Your review appears live for everyone immediately."
    ),
    AssistantQA(
        id: 9,
        question: "What can the campus map show me?",
        answer: "Map tab — toggle between three modes at the top:\n\n• People — see friends on campus right now (filtered by class schedule)\n• Events — colored calendar pins at every venue hosting an event today\n• Housing — verified rental listings across Hoboken, Jersey City, and nearby neighborhoods\n\nUse the search bar to highlight a specific person, building, or event."
    ),
    AssistantQA(
        id: 10,
        question: "Is my data private?",
        answer: "Yes. Your schedule, friends list, and location are visible only to friends you've accepted. Ghost Mode hides your dot entirely.\n\nReviews can be posted anonymously. Lease analysis happens server-side and is not shared with landlords. Roommate profiles are visible to other authenticated Stevens students only."
    ),
]

// MARK: - Chat Models

struct ChatBubble: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - Floating Assistant Bubble

struct AssistantFloatingButton: View {
    @State private var showAssistant = false
    @State private var pulse = false

    var body: some View {
        Button(action: { showAssistant = true }) {
            ZStack {
                Circle()
                    .stroke(Color.stevensRed.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0 : 0.7)
                    .frame(width: 52, height: 52)
                    .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)

                Circle()
                    .fill(LinearGradient(
                        colors: [.stevensRed, .primaryContainer],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .stevensRed.opacity(0.4), radius: 8, y: 4)
            }
        }
        .onAppear { pulse = true }
        .sheet(isPresented: $showAssistant) {
            AssistantSheet()
        }
    }
}

// MARK: - Assistant Sheet

struct AssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatBubble] = [
        ChatBubble(text: "Hi! I'm Nexus AI 👋\nAsk me anything or tap a question below.", isUser: false)
    ]
    @State private var typing = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Chat scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { msg in
                                bubble(for: msg)
                                    .id(msg.id)
                            }
                            if typing {
                                HStack {
                                    typingIndicator
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                .background(Color.nexusSurface)

                // Question chips
                VStack(spacing: 0) {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(assistantQuestions) { qa in
                                Button(action: { ask(qa) }) {
                                    Text(qa.question)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.stevensRed)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.stevensRed.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999)
                                                .strokeBorder(Color.stevensRed.opacity(0.25))
                                        )
                                        .cornerRadius(999)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color.white)

                    // Search / Ask bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.nexusSecondary)
                            .font(.system(size: 14))
                        TextField("Ask Nexus AI...", text: $searchText)
                            .font(.system(size: 15))
                            .submitLabel(.send)
                            .onSubmit { submitSearch() }
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.nexusSecondary)
                                    .font(.system(size: 16))
                            }
                        }
                        Button(action: submitSearch) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(searchText.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? Color.gray.opacity(0.4)
                                            : Color.stevensRed)
                                .clipShape(Circle())
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(Divider(), alignment: .top)
                }
            }
            .navigationTitle("Nexus AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.stevensRed)
                            .font(.system(size: 14))
                        Text("Nexus AI")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func bubble(for msg: ChatBubble) -> some View {
        HStack {
            if msg.isUser { Spacer(minLength: 40) }
            Text(msg.text)
                .font(.system(size: 14))
                .foregroundColor(msg.isUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    msg.isUser
                        ? AnyShapeStyle(Color.stevensRed)
                        : AnyShapeStyle(Color.white)
                )
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            if !msg.isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.nexusSecondary)
                    .frame(width: 6, height: 6)
                    .opacity(typingOpacity(i))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(14)
    }

    private func typingOpacity(_ i: Int) -> Double {
        let phase = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1.2)
        let offset = Double(i) * 0.4
        return abs(sin((phase + offset) * .pi))
    }

    private func ask(_ qa: AssistantQA) {
        messages.append(ChatBubble(text: qa.question, isUser: true))
        typing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            typing = false
            messages.append(ChatBubble(text: qa.answer, isUser: false))
        }
    }

    private func submitSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        messages.append(ChatBubble(text: query, isUser: true))
        searchText = ""
        typing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            typing = false
            let lower = query.lowercased()
            let queryWords = Set(lower.split(whereSeparator: { !$0.isLetter }).map(String.init))

            // Score each Q&A by keyword overlap with both question and answer
            let best = assistantQuestions.max(by: { a, b in
                score(words: queryWords, against: a) < score(words: queryWords, against: b)
            })

            if let match = best, score(words: queryWords, against: match) > 0 {
                messages.append(ChatBubble(text: match.answer, isUser: false))
            } else {
                messages.append(ChatBubble(
                    text: "I'm not sure about that yet — try one of the suggested questions below, or rephrase. I know about: research professors, lease analysis, the bounty system, roommates, ghost mode, events, and the campus map.",
                    isUser: false
                ))
            }
        }
    }

    private func score(words: Set<String>, against qa: AssistantQA) -> Int {
        let text = (qa.question + " " + qa.answer).lowercased()
        return words.filter { word in
            word.count >= 3 && text.contains(word)
        }.count
    }
}
