import SwiftUI
import PassKit

// MARK: - Add Funds Sheet

struct AddFundsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentBalance: Double

    @State private var selectedAmount: Double = 25
    @State private var selectedMethod: PaymentMethod = .card
    @State private var processing = false
    @State private var success = false

    // Card form fields (international-friendly — works without Apple Pay / US bank)
    @State private var cardholderName: String = ""
    @State private var cardNumber: String = ""
    @State private var cardExpiry: String = ""
    @State private var cardCVV: String = ""

    let amounts: [Double] = [10, 25, 50, 100]

    enum PaymentMethod: String, CaseIterable, Identifiable {
        case card = "Credit / Debit Card"
        case applePay = "Apple Pay"
        case bank = "Bank Transfer"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .applePay: return "apple.logo"
            case .card:     return "creditcard.fill"
            case .bank:     return "building.columns.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .card:     return "Visa, Mastercard, Amex, RuPay — works internationally"
            case .applePay: return "Quick checkout (US accounts)"
            case .bank:     return "ACH transfer (US accounts only)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if success {
                    successView
                } else {
                    composerView
                }
            }
            .background(Color.nexusSurface)
            .navigationTitle(success ? "Payment Confirmed" : "Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(success ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    private var composerView: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Current balance
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT BALANCE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(1)
                Text(String(format: "$%.2f", currentBalance))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(colors: [.stevensRed, .primaryContainer],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .shadow(color: .stevensRed.opacity(0.3), radius: 8, y: 4)

            // Amount selector
            VStack(alignment: .leading, spacing: 10) {
                Text("AMOUNT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.nexusSecondary)
                    .tracking(1)

                HStack(spacing: 10) {
                    ForEach(amounts, id: \.self) { amt in
                        Button(action: { selectedAmount = amt }) {
                            VStack(spacing: 2) {
                                Text(String(format: "$%.0f", amt))
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedAmount == amt ? Color.stevensRed : Color.white)
                            .foregroundColor(selectedAmount == amt ? .white : .stevensRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.stevensRed.opacity(0.3), lineWidth: selectedAmount == amt ? 0 : 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
            }

            // Payment method
            VStack(alignment: .leading, spacing: 10) {
                Text("PAYMENT METHOD")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.nexusSecondary)
                    .tracking(1)

                VStack(spacing: 0) {
                    ForEach(PaymentMethod.allCases) { method in
                        Button(action: { selectedMethod = method }) {
                            HStack(spacing: 12) {
                                Image(systemName: method.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.stevensRed)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(method.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(method.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundColor(.nexusSecondary)
                                }
                                Spacer()
                                if selectedMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.stevensRed)
                                }
                            }
                            .padding(14)
                        }
                        if method != PaymentMethod.allCases.last {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }

            // Card details form (only when Card method selected)
            if selectedMethod == .card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("CARD DETAILS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.nexusSecondary)
                            .tracking(1)
                        Spacer()
                        HStack(spacing: 4) {
                            cardLogoTag("VISA", color: Color(hex: "#1a1f71"))
                            cardLogoTag("MC", color: Color(hex: "#eb001b"))
                            cardLogoTag("AMEX", color: Color(hex: "#2e77bb"))
                        }
                    }

                    VStack(spacing: 0) {
                        cardField(label: "Cardholder Name", text: $cardholderName, placeholder: "Name on card")
                        Divider()
                        cardField(label: "Card Number", text: $cardNumber, placeholder: "1234 5678 9012 3456", keyboard: .numberPad)
                        Divider()
                        HStack(spacing: 0) {
                            cardField(label: "MM/YY", text: $cardExpiry, placeholder: "08/28", keyboard: .numberPad)
                            Divider().frame(height: 50)
                            cardField(label: "CVV", text: $cardCVV, placeholder: "123", keyboard: .numberPad)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
            }

            // Pay button
            if selectedMethod == .applePay {
                applePayButton
            } else {
                Button(action: processPayment) {
                    HStack {
                        if processing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "lock.fill")
                            Text(String(format: "Pay $%.2f", selectedAmount))
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.stevensRed)
                    .cornerRadius(14)
                }
                .disabled(processing)
            }

            // Disclaimer
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.nexusSecondary)
                Text("Demo mode — no real charge will be made.")
                    .font(.system(size: 11))
                    .foregroundColor(.nexusSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
        .padding(16)
    }

    private var applePayButton: some View {
        Button(action: processPayment) {
            HStack(spacing: 8) {
                if processing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Pay")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black)
            .cornerRadius(14)
        }
        .disabled(processing)
    }

    private var successView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 40)

            ZStack {
                Circle().fill(Color(hex: "#d8f3dc")).frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color(hex: "#2D6A4F"))
            }

            Text(String(format: "$%.2f Added", selectedAmount))
                .font(.system(size: 24, weight: .bold))

            Text("Funds are now available in your Nexus Wallet.")
                .font(.system(size: 14))
                .foregroundColor(.nexusSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                summaryRow(label: "Amount", value: String(format: "$%.2f", selectedAmount))
                summaryRow(label: "Method", value: selectedMethod.rawValue)
                summaryRow(label: "New Balance", value: String(format: "$%.2f", currentBalance + selectedAmount), isBold: true)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.stevensRed)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .padding(16)
    }

    @ViewBuilder
    private func summaryRow(label: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.nexusSecondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: isBold ? .bold : .medium))
                .foregroundColor(isBold ? .stevensRed : .primary)
        }
    }

    @ViewBuilder
    private func cardField(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.nexusSecondary)
                .tracking(0.5)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .keyboardType(keyboard)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func cardLogoTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(3)
    }

    private func processPayment() {
        processing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            processing = false
            withAnimation(.spring()) { success = true }
        }
    }
}
