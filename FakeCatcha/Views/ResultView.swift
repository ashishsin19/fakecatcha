import SwiftUI

struct ResultView: View {
    let report: AnalysisReport

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VerdictCard(report: report)

                if let noteImage = report.noteImage {
                    Image(uiImage: noteImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.3)))
                        .accessibilityLabel("Flattened image of the scanned note")
                }

                summaryGrid

                VStack(alignment: .leading, spacing: 0) {
                    Text("Checks")
                        .font(.headline)
                        .padding(.bottom, 8)
                    ForEach(report.checks) { check in
                        CheckRowView(check: check)
                        if check.id != report.checks.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                DisclaimerView()
            }
            .padding()
        }
    }

    private var summaryGrid: some View {
        HStack(spacing: 12) {
            infoTile(title: "Denomination",
                     value: report.denomination?.label ?? "Unknown",
                     color: report.denomination?.displayColor ?? .gray)
            infoTile(title: "Serial",
                     value: report.serialNumber?.formatted ?? "Not read",
                     color: .indigo)
        }
    }

    private func infoTile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct VerdictCard: View {
    let report: AnalysisReport

    var body: some View {
        let verdict = report.verdict
        HStack(spacing: 16) {
            ScoreRing(score: report.score, color: verdict.color)
                .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 6) {
                Label(verdict.title, systemImage: verdict.symbolName)
                    .font(.headline)
                    .foregroundStyle(verdict.color)
                Text(verdict.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(verdict.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ScoreRing: View {
    let score: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(score, 100))) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title2.weight(.bold).monospacedDigit())
                Text("score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence score \(score) out of 100")
    }
}

struct CheckRowView: View {
    let check: CheckResult
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 6) {
                if !check.detail.isEmpty {
                    Text(check.detail)
                }
                Text(check.kind.explanation)
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: check.status.symbolName)
                    .foregroundStyle(check.status.color)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(check.kind.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(check.status.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(check.status.color)
                    }
                    Text(check.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
    }
}
