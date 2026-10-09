import SwiftUI

struct AnalysisView: View {
    let image: UIImage

    @State private var report: AnalysisReport?

    var body: some View {
        Group {
            if let report {
                ResultView(report: report)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Analysing note…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if report == nil {
                report = await NoteAnalyzer().analyze(image)
            }
        }
    }
}
