import SwiftUI
import PhotosUI

/// Wrapper so a captured or picked image can drive navigation.
struct ScanInput: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage

    static func == (lhs: ScanInput, rhs: ScanInput) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ContentView: View {
    @State private var showScanner = false
    @State private var showAbout = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var scanInput: ScanInput?
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan with camera", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    if let loadError {
                        Text(loadError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    TipsView()
                    DisclaimerView()
                }
                .padding()
            }
            .navigationTitle("FakeCatcha")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("How it works")
                }
            }
            .navigationDestination(item: $scanInput) { input in
                AnalysisView(image: input.image)
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView { image in
                    showScanner = false
                    scanInput = ScanInput(image: image)
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPickedImage(newItem) }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "banknote")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Screen Australian banknotes")
                .font(.title2.weight(.semibold))
            Text("Checks $5, $10, $20, $50 and $100 polymer notes for common signs of counterfeiting – all on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    @MainActor
    private func loadPickedImage(_ item: PhotosPickerItem) async {
        loadError = nil
        defer { pickerItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                loadError = "Couldn't load that photo."
                return
            }
            scanInput = ScanInput(image: image)
        } catch {
            loadError = "Couldn't load that photo: \(error.localizedDescription)"
        }
    }
}

struct TipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("For the best scan")
                .font(.headline)
            tip("square.dashed", "Lay the note flat on a plain background that contrasts with its colour.")
            tip("sun.max", "Use even, white light and avoid glare on the clear window.")
            tip("arrow.left.and.right.square", "Fill most of the frame, with all four corners visible.")
            tip("arrow.triangle.2.circlepath", "Scan both sides – the serial number is only on one side.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.tint)
        }
    }
}

#Preview {
    ContentView()
}
