import SwiftUI

enum RBA {
    static let counterfeitDetectionURL = URL(string: "https://banknotes.rba.gov.au/counterfeit-detection/")!
}

struct DisclaimerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Screening aid only", systemImage: "exclamationmark.shield")
                .font(.headline)
            Text("FakeCatcha uses on-device image heuristics. It cannot certify that a banknote is genuine or counterfeit, and it can be wrong in both directions. Always check the security features yourself: feel the polymer, look at the clear window, and tilt the note. If you suspect a counterfeit, follow the Reserve Bank of Australia's guidance and contact your local police.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Link(destination: RBA.counterfeitDetectionURL) {
                Label("RBA counterfeit detection guide", systemImage: "arrow.up.right.square")
            }
            .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    DisclaimerView().padding()
}
