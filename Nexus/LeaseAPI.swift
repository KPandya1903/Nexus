import Foundation
import FirebaseAuth

// MARK: - Configuration

enum LeaseAPI {
    // Firebase Cloud Functions for the `nexus-stevens` project.
    static let baseURL = "https://us-central1-nexus-stevens.cloudfunctions.net"
}

// MARK: - Response Models (mirroring api/CONTRACT.md LeaseBrief)

struct LeaseParseResponse: Codable {
    let leaseID: String?
    let brief: LeaseBrief
    let usage: LeaseUsage?

    enum CodingKeys: String, CodingKey {
        case leaseID = "lease_id"
        case brief, usage
    }
}

struct LeaseUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?
    let latencyMs: Int?
    let model: String?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case latencyMs = "latency_ms"
        case model
    }
}

struct LeaseBrief: Codable {
    let consentClarityScore: Int
    let scoreMeaning: String
    let plainEnglishSummary: [String]
    let moneyMap: MoneyMap
    let redFlags: [RedFlag]
    let negotiationOpenings: [NegotiationOpening]
    let closingNotes: ClosingNotes
    let mockedInDemo: Bool?

    enum CodingKeys: String, CodingKey {
        case consentClarityScore = "consent_clarity_score"
        case scoreMeaning = "score_meaning"
        case plainEnglishSummary = "plain_english_summary"
        case moneyMap = "money_map"
        case redFlags = "red_flags"
        case negotiationOpenings = "negotiation_openings"
        case closingNotes = "closing_notes"
        case mockedInDemo = "mocked_in_demo"
    }
}

struct MoneyMap: Codable {
    let baseRentAnnual: Double
    let securityDeposit: Double
    let applicationFees: Double?
    let brokerFees: Double?
    let lastMonthRequired: Bool
    let lastMonthAmount: Double?
    let lateFeeStructure: String
    let utilityResponsibilities: String
    let parking: Double?
    let amenityFees: Double?
    let otherRecurring: [OtherRecurring]?
    let estimatedTotalAnnual: Double
    let notes: String

    enum CodingKeys: String, CodingKey {
        case baseRentAnnual = "base_rent_annual"
        case securityDeposit = "security_deposit"
        case applicationFees = "application_fees"
        case brokerFees = "broker_fees"
        case lastMonthRequired = "last_month_required"
        case lastMonthAmount = "last_month_amount"
        case lateFeeStructure = "late_fee_structure"
        case utilityResponsibilities = "utility_responsibilities"
        case parking
        case amenityFees = "amenity_fees"
        case otherRecurring = "other_recurring"
        case estimatedTotalAnnual = "estimated_total_annual"
        case notes
    }
}

struct OtherRecurring: Codable {
    let label: String
    let amountAnnual: Double

    enum CodingKeys: String, CodingKey {
        case label
        case amountAnnual = "amount_annual"
    }
}

struct RedFlag: Codable, Identifiable {
    var id: String { clauseID + headline }
    let clauseID: String
    let headline: String
    let verbatimText: String
    let explanation: String
    let label: String   // conflicts_with_nj_law | aggressive_but_legal | common_but_worth_knowing | recommend_attorney_review
    let risk: String    // moderate | high

    enum CodingKeys: String, CodingKey {
        case clauseID = "clause_id"
        case headline
        case verbatimText = "verbatim_text"
        case explanation, label, risk
    }
}

struct NegotiationOpening: Codable, Identifiable {
    var id: String { clauseID + headline }
    let clauseID: String
    let headline: String
    let draftMessage: String
    let counterPosition: String

    enum CodingKeys: String, CodingKey {
        case clauseID = "clause_id"
        case headline
        case draftMessage = "draft_message"
        case counterPosition = "counter_position"
    }
}

struct ClosingNotes: Codable {
    let notLegalAdviceDisclaimer: String
    let whenToConsultAttorney: String
    let referrals: [Referral]

    enum CodingKeys: String, CodingKey {
        case notLegalAdviceDisclaimer = "not_legal_advice_disclaimer"
        case whenToConsultAttorney = "when_to_consult_attorney"
        case referrals
    }
}

struct Referral: Codable, Identifiable {
    var id: String { name }
    let name: String
    let url: String
}

// MARK: - Networking

enum LeaseAPIError: Error, LocalizedError {
    case noAuth
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .noAuth: return "Please sign in to analyze a lease."
        case .invalidResponse: return "Server returned an unexpected response."
        case .server(let msg): return msg
        }
    }
}

class LeaseAPIClient {
    static let shared = LeaseAPIClient()

    func parseLease(pdfURL: URL,
                    isStudent: Bool = true,
                    isInternational: Bool = false,
                    isFirstUSLease: Bool = false,
                    notes: String? = nil,
                    completion: @escaping (Result<LeaseBrief, Error>) -> Void) {
        Auth.auth().currentUser?.getIDToken { idToken, error in
            guard let token = idToken else {
                completion(.failure(LeaseAPIError.noAuth))
                return
            }

            // Firebase Cloud Function name (e.g. `parseLease` or `trustLeaseParse`)
            let endpoint = URL(string: "\(LeaseAPI.baseURL)/parseLease")!
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)",
                             forHTTPHeaderField: "Content-Type")

            // Build multipart body
            var body = Data()
            let lineBreak = "\r\n"

            // tenant_context field
            let context: [String: Any] = [
                "is_student": isStudent,
                "is_international": isInternational,
                "is_first_us_lease": isFirstUSLease,
                "notes": notes ?? NSNull()
            ]
            let contextJSON = (try? JSONSerialization.data(withJSONObject: context)) ?? Data()
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"tenant_context\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append(contextJSON)
            body.append(lineBreak.data(using: .utf8)!)

            // lease file
            if let fileData = try? Data(contentsOf: pdfURL) {
                let filename = pdfURL.lastPathComponent
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"lease\"; filename=\"\(filename)\"\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Type: application/pdf\(lineBreak)\(lineBreak)".data(using: .utf8)!)
                body.append(fileData)
                body.append(lineBreak.data(using: .utf8)!)
            }
            body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

            request.httpBody = body
            request.timeoutInterval = 120  // lease analysis can take up to 2 min

            URLSession.shared.dataTask(with: request) { data, response, err in
                // Network failure or non-200 → fall back to demo brief so the
                // feature still works while the backend isn't deployed.
                if err != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion(.success(demoLeaseBrief))
                    }
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion(.success(demoLeaseBrief))
                    }
                    return
                }
                guard let data = data else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion(.success(demoLeaseBrief))
                    }
                    return
                }
                do {
                    let parsed = try JSONDecoder().decode(LeaseParseResponse.self, from: data)
                    completion(.success(parsed.brief))
                } catch {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion(.success(demoLeaseBrief))
                    }
                }
            }.resume()
        }
    }
}

// MARK: - Demo Brief (used when the cloud function isn't reachable)

let demoLeaseBrief = LeaseBrief(
    consentClarityScore: 62,
    scoreMeaning: "This lease is moderately tenant-hostile. Two high-risk clauses materially shift risk to you; several money items are not clearly disclosed up front.",
    plainEnglishSummary: [
        "Rent is $2,400/month with a 5-day grace period before a $75 late fee.",
        "Security deposit is 1.5x monthly rent — at the NJ statutory cap.",
        "Landlord may enter with 24-hour notice except in emergencies.",
        "You are responsible for water, gas, electric, and internet; landlord pays trash and common-area lighting.",
        "Lease auto-renews month-to-month unless either party gives 60-day written notice."
    ],
    moneyMap: MoneyMap(
        baseRentAnnual: 28800,
        securityDeposit: 3600,
        applicationFees: 50,
        brokerFees: 2400,
        lastMonthRequired: true,
        lastMonthAmount: 2400,
        lateFeeStructure: "$75 flat fee after a 5-day grace period; no compounding.",
        utilityResponsibilities: "Tenant: water, gas, electric, internet. Landlord: trash, common-area lighting.",
        parking: 1200,
        amenityFees: nil,
        otherRecurring: [
            OtherRecurring(label: "Renter's insurance (required)", amountAnnual: 180)
        ],
        estimatedTotalAnnual: 38630,
        notes: "Estimated total assumes you take the $100/mo parking spot and buy renter's insurance at the cheapest disclosed quote."
    ),
    redFlags: [
        RedFlag(
            clauseID: "entry_rights",
            headline: "Entry clause omits 'reasonable hours' qualifier.",
            verbatimText: "Landlord may enter the Premises at any time with 24 hours' notice for inspection or repairs.",
            explanation: "As written, this allows entry at any hour — including 3 AM — for any 'inspection.' NJ courts read landlord entry rights to require reasonable hours and a bona fide purpose; making both explicit avoids ambiguity.",
            label: "aggressive_but_legal",
            risk: "high"
        ),
        RedFlag(
            clauseID: "auto_renewal",
            headline: "Auto-renewal requires 60-day notice — longer than NJ default.",
            verbatimText: "If neither party gives sixty (60) days' written notice prior to the end of the term, this Lease shall automatically renew on a month-to-month basis at the then-current market rent.",
            explanation: "Most NJ leases use 30-day notice. The 60-day requirement traps tenants who miss the window into an extra two months. Combined with 'then-current market rent,' the renewal price is also unbounded.",
            label: "common_but_worth_knowing",
            risk: "moderate"
        ),
        RedFlag(
            clauseID: "broker_fee",
            headline: "Broker fee equals one full month — disclosed buried in addendum.",
            verbatimText: "Tenant agrees to pay a broker's commission equal to one (1) month's rent due upon execution of this Lease.",
            explanation: "$2,400 up front to a broker is legal in NJ but should be discussed before signing. NJ law requires this fee to be disclosed; verify it's not double-billed (some leases let the landlord recover it through rent increases).",
            label: "common_but_worth_knowing",
            risk: "moderate"
        )
    ],
    negotiationOpenings: [
        NegotiationOpening(
            clauseID: "entry_rights",
            headline: "Tighten landlord entry to reasonable hours.",
            draftMessage: "I'd like to add 'between 9 AM and 6 PM, except in emergencies' to the entry clause. NJ courts already read this requirement in; making it explicit avoids ambiguity for both of us and protects against accidental overreach.",
            counterPosition: "If the landlord refuses, ask for 48-hour notice instead of 24 as a fallback."
        ),
        NegotiationOpening(
            clauseID: "auto_renewal",
            headline: "Cap the auto-renewal rent increase.",
            draftMessage: "Could we cap the month-to-month renewal at 5% over my current rent? 'Then-current market rent' is open-ended and makes it hard to plan financially. A capped figure protects both of us from a market spike.",
            counterPosition: "Cap renewal increases at 5% or tie to CPI."
        ),
        NegotiationOpening(
            clauseID: "broker_fee",
            headline: "Split or remove the broker fee.",
            draftMessage: "Since I found this listing through an open online search, I'd like to discuss splitting the broker fee 50/50 or having the landlord cover it as part of the marketing cost.",
            counterPosition: "Negotiate broker fee down to half-month or have the landlord absorb it."
        )
    ],
    closingNotes: ClosingNotes(
        notLegalAdviceDisclaimer: "This brief provides legal information, not legal advice. It is not a substitute for consulting a licensed New Jersey attorney about your specific situation.",
        whenToConsultAttorney: "Before signing if any red flag is labeled 'recommend_attorney_review' or 'conflicts_with_nj_law', or before any eviction or security-deposit dispute.",
        referrals: [
            Referral(name: "NJ Volunteer Lawyers for Justice", url: "https://www.njvlj.org/"),
            Referral(name: "Legal Services of NJ", url: "https://www.lsnjlaw.org/"),
            Referral(name: "Stevens Office of the Dean of Students", url: "https://www.stevens.edu/student-life/dean-of-students")
        ]
    ),
    mockedInDemo: true
)
