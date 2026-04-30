import SwiftUI

struct NexusTopBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.stevensRed, Color.primaryContainer],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text("N")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                    )

                Text("The Stevens Nexus")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.stevensRed)
                    .tracking(-0.5)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell")
                    .foregroundColor(.stevensRed)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}
