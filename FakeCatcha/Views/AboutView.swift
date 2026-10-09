import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("FakeCatcha photographs a banknote and runs a set of on-device checks using Apple's Vision and Core Image frameworks. Nothing leaves your phone.")
                }

                Section("Checks") {
                    ForEach(CheckKind.allCases) { kind in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(kind.title).font(.headline)
                            Text(kind.explanation)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Check by hand (RBA)") {
                    manual("hand.raised", "Feel", "Polymer feels smooth and slightly waxy. Raised print can be felt on the portrait and large numerals.")
                    manual("eye", "Look", "Check the clear window: it should be an integral part of the note, not a sticker, and the features inside it should be crisp.")
                    manual("arrow.triangle.2.circlepath", "Tilt", "On next-generation notes the bird in the window flaps its wings and the number changes direction as you tilt.")
                    manual("rectangle.on.rectangle", "Compare", "Compare with a note you know is genuine.")
                }

                Section("Notes per denomination") {
                    ForEach(Denomination.allCases) { denomination in
                        HStack {
                            Circle()
                                .fill(denomination.displayColor)
                                .frame(width: 14, height: 14)
                            Text(denomination.label).font(.headline)
                            Spacer()
                            Text("\(Int(denomination.widthMM)) × \(Int(Denomination.heightMM)) mm · \(denomination.colourName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    DisclaimerView()
                        .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("How it works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func manual(_ symbol: String, _ title: String, _ text: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol).foregroundStyle(.tint)
        }
    }
}

#Preview {
    AboutView()
}
