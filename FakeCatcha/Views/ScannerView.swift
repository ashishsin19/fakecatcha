import SwiftUI

struct ScannerView: View {
    var onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var camera = CameraService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.status {
            case .running, .unknown:
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                NoteGuideOverlay()
                    .allowsHitTesting(false)
            case .denied:
                message(title: "Camera access needed",
                        text: "Allow camera access in Settings to scan notes, or choose a photo instead.",
                        showSettings: true)
            case .unavailable:
                message(title: "Camera unavailable",
                        text: "This device's camera couldn't be started. Choose a photo from your library instead.",
                        showSettings: false)
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Close")
                    Spacer()
                }
                .padding()

                Spacer()

                if camera.status == .running {
                    Text("Fit the whole note inside the frame")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.5), in: Capsule())

                    Button {
                        Task {
                            if let image = await camera.capturePhoto() {
                                onCapture(image)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle().fill(.white).frame(width: 66, height: 66)
                            Circle().stroke(.white, lineWidth: 4).frame(width: 78, height: 78)
                            if camera.isCapturing {
                                ProgressView().tint(.black)
                            }
                        }
                    }
                    .disabled(camera.isCapturing)
                    .accessibilityLabel("Capture note")
                    .padding(.vertical, 24)
                }
            }
        }
        .task {
            await camera.start()
        }
        .onDisappear {
            camera.stop()
        }
    }

    private func message(title: String, text: String, showSettings: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.largeTitle)
            Text(title).font(.headline)
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            if showSettings, let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") { openURL(url) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .foregroundStyle(.white)
        .padding(32)
    }
}

/// Banknote-shaped guide frame (portrait, matching a phone held upright).
struct NoteGuideOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.62, proxy.size.height * 0.62 / Denomination.twenty.aspectRatio)
            let height = width * Denomination.twenty.aspectRatio
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [12, 8]))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: width, height: height)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}
